#!/usr/bin/env python3
"""
AquaFeedFormulator — 原料价格监控脚本
=======================================
每日自动抓取饲料原料报价并对比数据库，偏差 > 15% 触发告警。

参考网站:
  - 汇易网 (chinajci.com)       — 行情分析/进口数据
  - 中国饲料在线 (feedonline.cn) — 鱼粉/豆粕成交价
  - 我的钢铁网 (mysteel.com)     — 大宗商品价格
  - 饲料行业信息网 (feedtrade.com.cn) — 每日报价

用法:
  python3 scripts/price_monitor.py              # 检查全部原料
  python3 scripts/price_monitor.py --alert-only  # 仅输出预警
  python3 scripts/price_monitor.py --update-db   # 更新 ingredient_db.pl

SOP 位置: Step 0 (求解前触发)
定时任务: 工作日上午 09:00 (cron / launchd)
"""

import json
import re
import sys
import os
from datetime import datetime
from pathlib import Path
from typing import Optional

# ─── 配置 ───────────────────────────────────────────

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "rules" / "ingredient_db.pl"
OUTPUT_DIR = PROJECT_ROOT / "generated" / "price_monitor"
BRIDGE_JSON = OUTPUT_DIR / "market_prices.json"
ALERT_THRESHOLD = 0.15  # 15% 偏差触发告警

# ─── 价格源加载 ──────────────────────────────────────

# 优先从 feed_price_bridge.py 输出加载实时爬虫价格
# 回退: 硬编码基准价格 (2025Q2)
DEFAULT_MARKET_PRICES = {
    # ── 动物蛋白源 ──
    "fish_meal_peru_65":       (12.0, "feedonline.cn 秘鲁CNF"),
    "fish_meal_domestic_60":   (9.0,  "feedonline.cn 国产"),
    "fish_meal_white_68":      (15.0, "feedonline.cn 白鱼粉"),
    "blood_meal_spray":        (8.0,  "feedtrade.com.cn"),
    "meat_bone_meal_50":       (5.2,  "feedtrade.com.cn"),
    "poultry_meal":            (6.8,  "feedtrade.com.cn"),
    "shrimp_shell_meal":       (4.0,  "feedtrade.com.cn"),
    "squid_liver_paste":       (18.0, "feedonline.cn"),
    "silkworm_pupae_meal":     (6.0,  "feedtrade.com.cn"),

    # ── 植物蛋白源 ──
    "soybean_meal_43":         (3.9,  "mysteel.com CBOT+压榨"),
    "soybean_meal_46":         (4.3,  "mysteel.com"),
    "fermented_soybean_meal":  (5.5,  "feedtrade.com.cn"),
    "rapeseed_meal_regular":   (2.8,  "mysteel.com 长江流域"),
    "canola_meal":             (3.3,  "mysteel.com"),
    "cottonseed_meal_regular": (3.0,  "mysteel.com"),
    "cottonseed_meal_dephenol":(3.8,  "feedtrade.com.cn"),
    "peanut_meal":             (4.0,  "feedtrade.com.cn"),
    "corn_gluten_meal_60":     (5.8,  "mysteel.com"),
    "corn_ddgs":               (2.5,  "mysteel.com"),
    "rice_protein_meal":       (5.0,  "feedtrade.com.cn"),

    # ── 能量原料 ──
    "corn":                    (2.3,  "mysteel.com 东北"),
    "wheat":                   (2.5,  "mysteel.com 华北"),
    "wheat_middlings":         (1.8,  "feedtrade.com.cn"),
    "wheat_flour":             (3.2,  "feedtrade.com.cn"),
    "rice_bran_fullfat":       (1.5,  "feedtrade.com.cn"),
    "rice_bran_defatted":      (1.8,  "feedtrade.com.cn"),
    "tapioca_starch":          (4.0,  "feedtrade.com.cn"),
    "sorghum":                 (2.0,  "mysteel.com"),

    # ── 油脂 ──
    "fish_oil":                (15.0, "feedonline.cn"),
    "soybean_oil":             (10.0, "mysteel.com"),
    "rapeseed_oil":            (9.5,  "mysteel.com"),
    "soybean_lecithin":        (8.0,  "feedtrade.com.cn"),

    # ── 矿物质 ──
    "dicalcium_phosphate":     (4.0,  "feedtrade.com.cn"),
    "limestone_powder":        (0.3,  "feedtrade.com.cn"),
    "salt":                    (0.5,  "feedtrade.com.cn"),
    "magnesium_sulfate":       (2.0,  "feedtrade.com.cn"),

    # ── 添加剂 ──
    "premix_vitamin_aqua":     (30.0, "feedtrade.com.cn"),
    "premix_mineral_aqua":     (20.0, "feedtrade.com.cn"),
    "choline_chloride_50":     (6.0,  "feedtrade.com.cn"),
    "vitamin_c_phosphate":     (45.0, "feedtrade.com.cn"),
    "antioxidant":             (25.0, "feedtrade.com.cn"),
    "mold_inhibitor":          (15.0, "feedtrade.com.cn"),
    "phytase":                 (80.0, "feedtrade.com.cn"),
    "betaine":                 (20.0, "feedtrade.com.cn"),
    "monocalcium_phosphate":   (5.0,  "feedtrade.com.cn"),
}


def load_market_prices() -> dict:
    """
    加载市场参考价格。
    优先: market_prices.json (feed_price_bridge.py 输出，实时爬虫数据)
    回退: DEFAULT_MARKET_PRICES (硬编码基准)
    策略: 合并 — 实时数据覆盖同ID，其余用默认值
    返回: {ingredient_id: (price_yuan_per_kg, source_label)}
    """
    prices = dict(DEFAULT_MARKET_PRICES)  # 默认全覆盖

    if BRIDGE_JSON.exists():
        try:
            with open(BRIDGE_JSON) as f:
                data = json.load(f)
            for ing_id, info in data.get("prices", {}).items():
                prices[ing_id] = (info["price_yuan_per_kg"], info["source"])
            if data.get("prices"):
                src_date = data.get("generated_at", "unknown")
        except (json.JSONDecodeError, KeyError, IOError):
            pass

    return prices


# ─── 数据库解析 ──────────────────────────────────────

def parse_ingredient_db(path: Path) -> dict:
    """从 ingredient_db.pl 解析所有原料的 ID → (name, db_price)"""
    ingredients = {}
    # 合并多行 fact 为单行 (Prolog fact 以 . 结尾)
    text = path.read_text()
    # 移除注释行和空行, 合并续行
    lines = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("%") or not stripped:
            continue
        lines.append(stripped)
    merged = " ".join(lines)

    # 按 . 分割出每个 fact
    pattern = re.compile(
        r"ingredient\((\w+),\s*'([^']+)',\s*(\w+),\s*"
        r"([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*"
        r"([\d.]+),\s*([\d.]+),\s*([\d.]+)\s*\)"
    )
    for m in pattern.finditer(merged):
        ing_id, name, price = m.group(1), m.group(2), float(m.group(9))
        ingredients[ing_id] = (name, price)
    return ingredients


# ─── 偏差计算 ────────────────────────────────────────

def check_deviations(db_ingredients: dict, market_prices: dict) -> list[dict]:
    """对比数据库价格 vs 市场价, 返回告警列表"""
    alerts = []

    for ing_id, (market_price, source) in market_prices.items():
        if ing_id not in db_ingredients:
            alerts.append({
                "ingredient_id": ing_id,
                "status": "missing",
                "message": f"市场参考价存在但数据库中无此原料",
            })
            continue

        name, db_price = db_ingredients[ing_id]
        deviation = (market_price - db_price) / db_price if db_price > 0 else 0

        if abs(deviation) > ALERT_THRESHOLD:
            direction = "↑ 上涨" if deviation > 0 else "↓ 下跌"
            alerts.append({
                "ingredient_id": ing_id,
                "name": name,
                "db_price": db_price,
                "market_price": market_price,
                "deviation_pct": round(deviation * 100, 1),
                "direction": direction,
                "source": source,
                "status": "alert",
                "action": "建议更新数据库价格" if abs(deviation) > 0.20 else "关注"
            })

    return alerts


# ─── 完整报告 ────────────────────────────────────────

def generate_report(db_ingredients: dict, alerts: list[dict], market_prices: dict) -> dict:
    """生成完整监控报告"""
    results = []
    for ing_id, (market_price, source) in market_prices.items():
        if ing_id not in db_ingredients:
            continue
        name, db_price = db_ingredients[ing_id]
        deviation = (market_price - db_price) / db_price if db_price > 0 else 0
        results.append({
            "id": ing_id,
            "name": name,
            "db_price": db_price,
            "market_price": market_price,
            "deviation_pct": round(deviation * 100, 1),
            "source": source,
            "status": "alert" if abs(deviation) > ALERT_THRESHOLD else "ok",
        })

    return {
        "timestamp": datetime.now().isoformat(),
        "threshold_pct": ALERT_THRESHOLD * 100,
        "total_ingredients": len(results),
        "alert_count": len(alerts),
        "alerts": alerts,
        "all_prices": sorted(results, key=lambda x: abs(x["deviation_pct"]), reverse=True),
    }


# ─── 数据库更新 ──────────────────────────────────────

def update_db_prices(db_path: Path, alerts: list[dict], dry_run: bool = True):
    """用市场价更新 ingredient_db.pl 中偏差 > 15% 的原料价格"""
    # 构建 ID → 新价格映射
    price_map = {}
    for a in alerts:
        if a.get("status") == "alert":
            price_map[a["ingredient_id"]] = a["market_price"]

    if not price_map:
        print("  无需更新。")
        return

    updated = 0
    text = db_path.read_text()

    # 匹配完整 ingredient(...). 跨行 fact
    def replacer(m):
        nonlocal updated
        ing_id = m.group(1)
        if ing_id in price_map:
            new_price = price_map[ing_id]
            old_price = float(m.group(9))
            updated += 1
            print(f"  📝 {ing_id}: {old_price} → {new_price} 元/kg")
            # 重建行: 保留前8个参数, 替换第9个(价格)
            return (f"ingredient({m.group(1)}, '{m.group(2)}', {m.group(3)}, "
                    f"{m.group(4)}, {m.group(5)}, {m.group(6)}, {m.group(7)}, {m.group(8)}, "
                    f"{new_price}, {m.group(10)}, {m.group(11)})")
        return m.group(0)

    pattern = re.compile(
        r"ingredient\((\w+),\s*'([^']+)',\s*(\w+),\s*"
        r"([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*"
        r"([\d.]+),\s*([\d.]+),\s*([\d.]+)\s*\)"
    )
    new_text = pattern.sub(replacer, text)

    if updated > 0 and not dry_run:
        db_path.write_text(new_text)
        print(f"\n✅ 已更新 {updated} 个原料价格到 {db_path}")
    elif updated > 0:
        print(f"\n🔍 [DRY RUN] 共 {updated} 个原料待更新, 使用 --update-db 执行")
    else:
        print("  无需更新。")


# ─── CLI ─────────────────────────────────────────────

def main():
    import argparse

    parser = argparse.ArgumentParser(description="AquaFeedFormulator 原料价格监控")
    parser.add_argument("--alert-only", action="store_true", help="仅显示告警项")
    parser.add_argument("--update-db", action="store_true", help="自动更新 ingredient_db.pl")
    parser.add_argument("--json", action="store_true", help="JSON 格式输出到文件")
    args = parser.parse_args()

    if not DB_PATH.exists():
        print(f"❌ 数据库文件不存在: {DB_PATH}")
        sys.exit(1)

    market_prices = load_market_prices()

    db_ingredients = parse_ingredient_db(DB_PATH)
    alerts = check_deviations(db_ingredients, market_prices)
    report = generate_report(db_ingredients, alerts, market_prices)

    # ── 输出 ──
    if args.alert_only:
        if alerts:
            print(f"\n🚨 {len(alerts)} 个原料价格偏差 > {ALERT_THRESHOLD*100:.0f}%:\n")
        else:
            print(f"\n✅ 所有原料价格正常 (偏差 < {ALERT_THRESHOLD*100:.0f}%)\n")

    for a in alerts:
        if a.get("status") == "missing":
            print(f"  ⚠️  {a['ingredient_id']} — {a['message']}")
            print()
            continue
        print(f"  {a['direction']} {a.get('name', a['ingredient_id'])}")
        print(f"    DB: {a['db_price']} → 市场: {a['market_price']} 元/kg "
              f"({a['deviation_pct']:+.1f}%)  [{a['source']}]")
        print(f"    → {a['action']}")
        print()

    if not args.alert_only:
        print(f"📊 总计: {report['total_ingredients']} 个原料, {report['alert_count']} 个告警\n")
        top5 = [r for r in report["all_prices"] if abs(r["deviation_pct"]) > 5][:5]
        if top5:
            print("TOP 偏差 (≥5%):")
            for r in top5:
                print(f"  {r['name']:20s} DB:{r['db_price']:6.2f} 市场:{r['market_price']:6.2f}  "
                      f"{r['deviation_pct']:+.1f}%  [{r['source']}]")

    # ── JSON 输出 ──
    if args.json:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        ts = datetime.now().strftime("%Y%m%d")
        json_path = OUTPUT_DIR / f"price_report_{ts}.json"
        json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2))
        print(f"\n📄 JSON 报告: {json_path}")

    # ── 数据库更新 ──
    if args.update_db and alerts:
        print(f"\n── 更新 ingredient_db.pl ──")
        update_db_prices(DB_PATH, alerts, dry_run=False)

    # ── 退出码 ──
    if alerts:
        sys.exit(1 if any(abs(a["deviation_pct"]) > 20 for a in alerts) else 0)


if __name__ == "__main__":
    main()
