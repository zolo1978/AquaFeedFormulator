#!/usr/bin/env python3
"""
feed_price_bridge.py — 爬虫价格 → AquaFeedFormulator 桥接
========================================================
从 feed_cache.json 提取最新市场价格，映射为 Prolog ingredient_db 格式，
输出 market_prices.json 供 price_monitor.py 消费。

数据源:
  - ~/Documents/data/feed/feed_cache.json  (CFO + feedtrade + 100ppi + mysteel 合并)
  - ~/Documents/data/cfo/cfo_cache.json    (CFO 单独)

输出:
  - generated/price_monitor/market_prices.json

用法:
  python3 scripts/feed_price_bridge.py
  python3 scripts/feed_price_bridge.py --update-db   # 同时更新 ingredient_db.pl
"""

import json
import re
import sys
from datetime import datetime, date
from pathlib import Path

# ─── 路径配置 ─────────────────────────────────────────

PROJECT_ROOT = Path(__file__).resolve().parent.parent
FEED_CACHE = Path.home() / "Documents/data/feed/feed_cache.json"
CFO_CACHE = Path.home() / "Documents/data/cfo/cfo_cache.json"
DB_PATH = PROJECT_ROOT / "rules" / "ingredient_db.pl"
OUTPUT_DIR = PROJECT_ROOT / "generated" / "price_monitor"
OUTPUT_JSON = OUTPUT_DIR / "market_prices.json"

# ─── 价格映射表: 爬虫产品名 → (ingredient_id, source_label) ───

PRICE_MAP = {
    # CFO 来源 (feed_cache.json → cfo key)
    "SBM China 43%":             ("soybean_meal_43",           "CFO"),
    "Canola Meal China 36%":     ("canola_meal",               "CFO"),
    "DDGS USA 26/28%":           ("corn_ddgs",                 "CFO"),
    "Fishmeal Peru Super":       ("fish_meal_peru_65",         "CFO"),
    "Fishmeal China 63/150":     ("fish_meal_domestic_60",     "CFO"),
    "MBM Uruguay/Argentina Beef 45%": ("meat_bone_meal_50",    "CFO"),
    "PBM USA 65%":               ("poultry_meal",              "CFO"),
    "DCP China --":              ("dicalcium_phosphate",       "CFO"),

    # feedtrade 氨基酸 — 暂无对应 ingredient_id，未来扩展

    # 100ppi (feed_cache.json → grains key)
    "玉米(产区均价)":             ("corn",                      "100ppi"),
    "豆油(山东均价)":             ("soybean_oil",               "100ppi"),

    # feedtrade (feed_cache.json → wheat key)
    "小麦(产区均价)":             ("wheat",                     "feeddrade"),
}


def load_cache() -> dict:
    """加载 feed_cache.json"""
    if FEED_CACHE.exists():
        with open(FEED_CACHE) as f:
            return json.load(f)
    return {}


def extract_latest_prices(cache: dict) -> dict:
    """
    从缓存提取每个产品的最新价格。
    缓存结构: { source_key: { product_name: { "YYYY-MM-DD": price } } }
    返回: { ingredient_id: (price_yuan_per_ton, date, source_label) }
    """
    prices = {}

    for source, products in cache.items():
        if not isinstance(products, dict):
            continue

        for product_name, date_prices in products.items():
            if not isinstance(date_prices, dict) or not date_prices:
                continue

            # 跳过非价格数据列 (如 "小麦(样本数)")
            if product_name in PRICE_MAP:
                ing_id, src_label = PRICE_MAP[product_name]

                # 取最新日期的价格
                latest_date = max(date_prices.keys())
                price = date_prices[latest_date]

                if price and price > 0:
                    # 单位转换 → 统一为 元/kg
                    # CFO: 元/吨 (÷1000)    grains/PPI: 元/吨 (÷1000)
                    # amino: 元/kg (不变)   wheat: 元/斤 (×2)
                    if source in ("cfo", "grains"):
                        price_per_kg = round(price / 1000, 2)
                    elif source == "wheat":
                        price_per_kg = round(price * 2, 2)
                    else:
                        price_per_kg = round(price, 2)

                    if ing_id not in prices or latest_date > prices[ing_id][1]:
                        prices[ing_id] = (price_per_kg, latest_date, src_label)

    return prices


def format_output(prices: dict) -> dict:
    """格式化输出为 market_prices.json"""
    result = {
        "generated_at": datetime.now().isoformat(),
        "source_files": [
            str(FEED_CACHE),
            str(CFO_CACHE),
        ],
        "total_mapped": len(prices),
        "prices": {},
    }

    for ing_id, (price, date_str, source) in sorted(prices.items()):
        result["prices"][ing_id] = {
            "price_yuan_per_kg": price,
            "price_yuan_per_ton": round(price * 1000),
            "date": date_str,
            "source": source,
        }

    return result


def update_ingredient_db(prices: dict, dry_run: bool = False) -> int:
    """用市场价更新 ingredient_db.pl 中的原料价格"""
    if not DB_PATH.exists():
        print(f"  ❌ 数据库不存在: {DB_PATH}")
        return 0

    text = DB_PATH.read_text()
    updated = 0

    def replacer(m):
        nonlocal updated
        ing_id = m.group(1)
        if ing_id in prices:
            new_price = prices[ing_id][0]  # 元/kg
            old_price = float(m.group(9))
            if abs(new_price - old_price) > 0.01:
                updated += 1
                print(f"  📝 {m.group(2)}: {old_price} → {new_price} 元/kg")
                return (
                    f"ingredient({m.group(1)}, '{m.group(2)}', {m.group(3)}, "
                    f"{m.group(4)}, {m.group(5)}, {m.group(6)}, {m.group(7)}, {m.group(8)}, "
                    f"{new_price}, {m.group(10)}, {m.group(11)})"
                )
        return m.group(0)

    pattern = re.compile(
        r"ingredient\((\w+),\s*'([^']+)',\s*(\w+),\s*"
        r"([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*"
        r"([\d.]+),\s*([\d.]+),\s*([\d.]+)\s*\)"
    )
    new_text = pattern.sub(replacer, text)

    if updated > 0 and not dry_run:
        DB_PATH.write_text(new_text)
        print(f"\n  ✅ 已更新 {updated} 个原料价格到 {DB_PATH}")
    elif updated > 0:
        print(f"\n  🔍 [DRY RUN] {updated} 个原料待更新")

    return updated


def main():
    import argparse
    parser = argparse.ArgumentParser(description="爬虫价格桥接 → AquaFeedFormulator")
    parser.add_argument("--update-db", action="store_true", help="更新 ingredient_db.pl")
    parser.add_argument("--dry-run", action="store_true", help="预览更新不写入")
    args = parser.parse_args()

    print("=== feed_price_bridge: 爬虫 → Formulator 喂价 ===\n")

    # 1. 加载缓存
    cache = load_cache()
    sources = [k for k in cache if isinstance(cache[k], dict)]
    print(f"[1/3] 加载缓存: {len(sources)} 个来源 ({', '.join(sources)})")

    # 2. 提取并映射价格
    prices = extract_latest_prices(cache)
    print(f"[2/3] 映射价格: {len(prices)} 个品种")

    if not prices:
        print("  ⚠️ 未找到可映射的价格数据")
        sys.exit(1)

    for ing_id, (price, date_str, src) in sorted(prices.items()):
        print(f"  {ing_id:30s}  {price:>8.2f} 元/kg  ({date_str})  [{src}]")

    # 3. 输出 JSON
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output = format_output(prices)
    with open(OUTPUT_JSON, "w") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    print(f"\n[3/3] ✅ market_prices.json → {OUTPUT_JSON}")

    # 4. 更新 ingredient_db.pl
    if args.update_db:
        print("\n── 更新 ingredient_db.pl ──")
        updated = update_ingredient_db(prices, dry_run=args.dry_run)
        if updated == 0:
            print("  价格无变动，无需更新。")

    print("\n完成。")


if __name__ == "__main__":
    main()
