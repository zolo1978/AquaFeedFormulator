# AquaFeedFormulator — 数据充实计划 v1.0

> Phase 0 治理基础 — 数据工程前置  
> M5 (mineral_balance) 和 M6 (eaa_balance) 的数据依赖分析  
> 2026-06-05

---

## 一、数据缺口总览

| 模块 | 需求 | 数据点 | 当前状态 | 预计工时 |
|------|------|:---:|:---:|:---:|
| M5 `mineral_balance` | 35 种原料 × Ca/P | 70 | 0 个 | 3-4h |
| M5 `mineral_balance` | 18 物种 × 磷需求量 | 18 | 0 个 | 1h |
| M6 `eaa_balance` | 35 种原料 × 10 EAA | 350 | 0 个 | 8-12h |
| M6 `eaa_balance` | 18 物种 × ~3 阶段 × 10 EAA | ~540 | 0 个 | 6-8h |
| **合计** | | **~978** | **0** | **18-25h** |

> ⚠️ 这不是开发任务，是数据工程任务。规则代码可以在数据就绪之前写好并自测通过（用 mock 数据），但生产使用必须等数据校验完成。

---

## 二、M5: 钙/磷数据

### 2.1 原料钙磷含量

| 字段 | 类型 | 单位 | 来源 |
|------|------|------|------|
| `calcium` | 原料字段 | g/100g | 《中国饲料成分及营养价值表》(第 34 版) |
| `total_phosphorus` | 原料字段 | g/100g | 同上 |

### 2.2 物种有效磷需求

| 字段 | 类型 | 单位 | 来源 |
|------|------|------|------|
| `available_phosphorus_min` | 营养需求 | % | NRC 2011 + GB/T 水生动物营养需要 |

### 2.3 数据条目清单（部分）

```
原料                    Ca(%)   P(%)    状态      来源
───────────────────────────────────────────────────
fish_meal_peru_65       3.80   2.60    missing   饲料成分表
fish_meal_domestic_60   4.50   2.80    missing   饲料成分表
fish_meal_white_68      5.20   3.20    missing   饲料成分表
soybean_meal_46         0.32   0.65    missing   饲料成分表
soybean_meal_43         0.31   0.62    missing   饲料成分表
rapeseed_meal           0.65   1.02    missing   饲料成分表
corn                    0.02   0.27    missing   饲料成分表
wheat_flour             0.06   0.20    missing   饲料成分表
blood_meal_spray        0.30   0.25    missing   饲料成分表
meat_bone_meal_50       8.50   4.60    missing   饲料成分表
poultry_meal            4.80   2.90    missing   饲料成分表
shrimp_shell_meal      10.20   1.60    missing   饲料成分表
squid_liver_paste       0.15   0.85    missing   饲料成分表
...(35 种)                                 饲料成分表

物种                    有效磷需求(%)    状态      来源
───────────────────────────────────────────────────
japanese_eel 成体       0.60            missing   NRC 2011
white_shrimp  成体      0.80            missing   NRC 2011
common_carp   成体      0.55            missing   NRC 2011
...(18 物种)
```

---

## 三、M6: EAA 数据

### 3.1 原料 EAA 含量

| 字段 | 单位 | 来源 |
|------|------|------|
| `lysine` | g/100g | 《中国饲料成分及营养价值表》(第 34 版) |
| `methionine` | g/100g | 同上 |
| `cysteine` | g/100g | 同上 |
| `threonine` | g/100g | 同上 |
| `tryptophan` | g/100g | 同上（需注意：部分原料缺 Trp 数据） |
| `arginine` | g/100g | 同上 |
| `isoleucine` | g/100g | 同上 |
| `leucine` | g/100g | 同上 |
| `valine` | g/100g | 同上 |
| `histidine` | g/100g | 同上 |

### 3.2 物种 EAA 需求

| 物种 | 阶段 | Lys | Met | Cys | Thr | Trp | Arg | Ile | Leu | Val | His |
|------|------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| japanese_eel | 成体 | 5.8 | 2.0 | 1.0 | 3.2 | 0.5 | 4.0 | 3.0 | 5.0 | 3.5 | 1.5 |
| white_shrimp | 成体 | 5.2 | 2.2 | 1.0 | 3.6 | 0.5 | 5.0 | 3.0 | 5.0 | 3.5 | 1.5 |
| ... | | | | | | | | | | | |

### 3.3 数据条目清单

```
原料                    Lys  Met  Cys  Thr  Trp  Arg  Ile  Leu  Val  His  状态
──────────────────────────────────────────────────────────────────────────────
fish_meal_peru_65       4.8  1.8  0.6  2.5  0.5  3.6  2.5  4.2  2.8  1.2  missing
fish_meal_domestic_60   4.2  1.5  0.5  2.2  0.4  3.2  2.2  3.8  2.5  1.0  missing
soybean_meal_46         2.9  0.6  0.7  1.8  0.6  3.4  2.1  3.5  2.2  1.1  missing
soybean_meal_43         2.7  0.6  0.6  1.7  0.5  3.2  2.0  3.3  2.1  1.0  missing
rapeseed_meal           1.7  0.6  0.7  1.5  0.4  2.2  1.5  2.6  1.8  0.9  missing
corn                    0.24 0.17 0.19 0.29 0.06 0.38 0.28 0.95 0.40 0.23 missing
wheat_flour             0.25 0.16 0.22 0.27 0.12 0.43 0.33 0.68 0.42 0.22 missing
blood_meal_spray        8.5  1.0  1.2  4.0  1.2  4.2  1.0 11.5  8.2  6.0  missing
meat_bone_meal_50       3.2  0.9  0.8  2.0  0.4  4.0  1.5  3.5  2.6  1.5  missing
poultry_meal            3.5  1.0  0.6  2.2  0.5  3.8  2.0  4.0  2.8  1.2  missing
shrimp_shell_meal       2.2  1.0  0.3  1.5  0.3  3.2  1.8  2.8  2.0  1.0  missing
squid_liver_paste       4.0  1.5  0.5  2.2  0.5  3.5  2.2  3.8  2.5  1.2  missing
...(35 种 × 10 EAA)
```

---

## 四、数据状态定义

| 状态 | 含义 | 可进入 Prolog? |
|------|------|:---:|
| `missing` | 未录入 | ❌ |
| `draft` | 已录入，未审核 | ⚠️ 仅用于测试 |
| `verified` | 经专家/来源交叉验证 | ✅ |
| `disputed` | 多来源数值不一致 | ❌ 需标注 confidence |

---

## 五、版本管理

```
ingredient_db.pl
├── version: 1.0
├── fields: pro, fat, fib, ash, price, source
└── next: 1.1 (add Ca, P)

ingredient_amino.pl  (新建)
├── version: 1.0
├── fields: 10 EAA per ingredient
└── source: 中国饲料成分表第34版

species_nutrition.pl
├── version: 1.0
└── next: 1.1 (add EAA requirements, available_P)
```

---

## 六、录入策略建议

1. **优先录入高频原料**：鱼粉、豆粕、玉米、面粉、血粉 → 覆盖核心配方
2. **批量导入**：从 CSV → Prolog term 的脚本（`scripts/csv_to_prolog.py`）
3. **先做 M5**（70 数据点，3-4h），再攻 M6（890 数据点，14-20h）
4. **M6 可分阶段**：先录入鱼粉/豆粕/血粉/玉米/面粉 10 种核心原料 × 10 EAA = 100 数据点，即可跑通 eaa_balance.pl 主逻辑
