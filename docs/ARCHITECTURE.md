# AquaFeedFormulator 技术架构

> **定位声明**：本文档为 AquaFeedFormulator 的 **Prolog LP Solver 子模块**架构文档。
> 总系统架构见 `docs/TOTAL_SYSTEM_ARCHITECTURE.md`。

> 版本：v1.0 | 日期：2026-06-04 | 引擎：Prolog SOP 引擎

---

## 1. 架构总览

```
                          ┌──────────────────────┐
                          │   sop_engine.pl       │
                          │   solve_formulation/2 │  ← 唯一用户入口
                          └──────────┬───────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
        ▼                            ▼                            ▼
┌───────────────┐   ┌──────────────────────────┐   ┌──────────────────────┐
│ ingredient_db │   │    library(simplex)       │   │  species_nutrition   │
│ .pl           │   │    (scryper-prolog LP)    │   │  .pl                 │
│               │   │                          │   │                      │
│ 100+ 原料      │   │ gen_state → constraint   │   │ 18 物种 × N 阶段     │
│ 6 大类        │   │ → minimize → extract     │   │ 营养目标              │
└───────┬───────┘   └────────────┬─────────────┘   └───────────┬──────────┘
        │                        │                             │
        │         ┌──────────────┴──────────────┐              │
        │         │   品类约束 (内置 LP)          │              │
        │         │   animal_protein ≥ 35%       │              │
        │         │   starch ≤ 25%               │              │
        │         │   oil: 3-8%                  │              │
        │         └──────────────┬──────────────┘              │
        │                        │                             │
        └────────────────────────┼─────────────────────────────┘
                                 │
                                 ▼
                      ┌──────────────────────┐
                      │   配方结果 + 闭合校验   │
                      │   ¥ 成本 / 吨          │
                      │   100% ± 0.1%         │
                      └──────────────────────┘
```

**架构原则**：
- **单入口**：`solve_formulation(Species, Stage)` 是唯一对外的 API
- **品类约束进 LP**：不再事后校验，直接作为线性约束参与求解
- **数据与逻辑分离**：`ingredient_db.pl` 和 `species_nutrition.pl` 是纯数据库，`sop_engine.pl` 是纯逻辑
- **所有 Prolog 无外部依赖**：除 `library(simplex)` 外全部自实现

---

## 2. 运行时架构

```
┌─────────────────────────────────────────────────────────────┐
│                     scryper-prolog 运行时                     │
│                                                             │
│  consult('rules/ingredient_db.pl')                          │
│  └─→ 加载 100+ 种原料事实 (ingredient/11)                    │
│                                                             │
│  consult('rules/species_nutrition.pl')                      │
│  └─→ 加载 18 物种 × N 阶段营养需求 (species_nutrition/6)     │
│                                                             │
│  consult('rules/category_rules.pl')                         │
│  └─→ 加载品类约束（唯一源）                                   │
│                                                             │
│  consult('rules/sop_gatekeeper.pl')                         │
│  └─→ 加载门禁与 fallback 控制                                │
│                                                             │
│  consult('rules/formulation_lp_engine.pl')                  │
│  └─→ 加载 LP 求解核心                                       │
│                                                             │
│  consult('rules/sop_engine.pl')                             │
│  └─→ 加载主控逻辑 + 输出格式化                                │
│                                                             │
│  solve_formulation(japanese_eel, adult).                    │
│  └─→ 门禁校验 → 查询营养目标 → 筛选原料 → 构建 LP → simplex 求解 → 输出  │
└─────────────────────────────────────────────────────────────┘
```

无持久化状态。每次调用 `solve_formulation` 是纯计算，结果仅输出到 stdout。

---

## 3. 核心流程时序

```
solve_formulation(Species, Stage)
│
├─ 1. 门禁校验 ────────────────────────────────────
│   can_execute(production, solve(Species, Stage))
│   ├─ species_exists(Species)?
│   ├─ stage_exists(Species, Stage)?
│   ├─ has_category_rules_or_fallback?
│   └─ ingredients_available?
│
├─ 2. 数据获取 ──────────────────────────────────────
│   ├─ 营养目标: TgtPro, TgtFat, MaxFib, MaxAsh
│   ├─ 品类约束: category_constraints_for(Species, Stage)
│   └─ (LP 内部)
│       ├─ 可变原料: ingredient(Cat ≠ additive)
│       ├─ 固定原料: ingredient(Min>0, Min=Max)
│       └─ 固定总量: sum(FixedPct × 10)
│
├─ 3. LP 模型构建 ──────────────────────────────────
│   gen_state(S0)
│   ├─ 总和约束:   ΣIds = 1000 - FixedTotal
│   ├─ 营养约束:   Σ(nut_i × x_i) ≥/< RHS × 1000
│   ├─ 用量边界:   Min×10 ≤ x_i ≤ Max×10
│   └─ 品类约束:   Σ_{i∈category} x_i ≥/< Limit×10
│
├─ 4. LP 求解 ──────────────────────────────────────
│   minimize(Σ(Price×10 × Id), S6, SFinal)
│   ├─ 成功 → extract_results → recipe_sop(Items, TotalCost)
│   └─ 失败 → Solution = infeasible
│
└─ 5. 输出 ─────────────────────────────────────────
    ├─ 营养目标
    ├─ 配方明细 (名称 / % / 成本)
    ├─ 合计 100% ± 0.1%
    ├─ 吨成本 (P0-2 修正: TotalCost × 10)
    └─ 成本异常检测 (3000 ≤ 吨成本 ≤ 30000)
```

---

## 4. 数据模型

### 4.1 原料事实 (ingredient/11)

```prolog
ingredient(Id, Name, Category, Protein%, Fat%, Fiber%, Ash%, Moisture%, Price, Max%, Min%).
```

| 位置 | 字段 | 类型 | 说明 |
|------|------|------|------|
| 1 | Id | atom | 唯一标识 (如 `fish_meal_peru_65`) |
| 2 | Name | string | 中文名称 |
| 3 | Category | atom | 分类: animal_protein / plant_protein / energy / oil / mineral / additive |
| 4-7 | Pro/Fat/Fib/Ash | number | g/100g 干物质 |
| 8 | Moisture | number | 水分% |
| 9 | Price | number | **元/kg** |
| 10 | Max% | number | 最大用量% |
| 11 | Min% | number | 最小用量% |

### 4.2 营养目标 (species_nutrition/6)

```prolog
species_nutrition(Species, Stage, Protein%, Fat%, FiberMax%, AshMax%).
```

### 4.3 品类约束 (species_category_rule/6) — 唯一源：`category_rules.pl`

```prolog
species_category_rule(Species, Stage, Category, LimitType, Limit%, Description).
```

- `LimitType`: `min` | `max`
- `Category`: `starch` | `animal_protein` | `plant_protein` | `oil`
- **生产模式无通配 fallback**，无专用规则时失败

### 4.4 求解结果 (recipe_sop/2)

```prolog
recipe_sop(Items, TotalCost).
% Items: [Id-Pct-Per100kgCost, ...]
% TotalCost: 元/100kg
% 吨成本 = TotalCost × 10
```

---

## 5. LP 求解器设计

### 5.1 核心 API

```prolog
lp_solve(+TgtPro, +TgtFat, +MaxFib, +MaxAsh, +CatConstraints, -Solution).
% Solution = recipe_sop(Items, TotalCost) | infeasible
```

### 5.2 整数缩放策略

scryper-prolog `library(simplex)` 的已知 bug：系数 `1.0` 简化为整数 `1` 时内部 `rational_numerator_denominator` 解析失败。

**解决方案：全整数缩放**

```
原始域:         x_i ∈ [0, 100]    (百分比)
缩放后:         x_i ∈ [0, 1000]   (千分比)
系数:           Price × 10 → round(Price × 10)
RHS:            Target × 1000 → round(Target × 1000)
固定原料:       Pct × 10 → round(Pct × 10)
```

结果除以 10 还原为百分比。

---

## 6. 模块依赖图

```
sop_engine.pl
├── sop_gatekeeper.pl (can_execute/2, allow_fallback/2)
├── category_rules.pl (species_category_rule/6)
├── formulation_lp_engine.pl (lp_solve/6)
│   └── library(simplex)
├── ingredient_db.pl (ingredient/11)
└── species_nutrition.pl (species_nutrition/6)

formulation_lp_engine.pl
├── library(simplex)
├── ingredient_db.pl
└── category_rules.pl (category_check/2)

delivery_gatekeeper.pl
├── category_rules.pl
├── ingredient_db.pl
└── species_nutrition.pl
```

---

## 7. scryper-prolog 兼容性

| 特性 | 可用 |
|------|------|
| `library(simplex)` | ✅ 整数系数稳定 |
| `sort/2` | ✅ |
| `findall/3` | ✅ |
| `member/2` | ✅ (自定义) |
| `is/2` 算术 | ✅ |
| `->/2 ;/2` (if-then-else) | ✅ |
| `format/2` | ❌ → `write` + `round` |

---

## 8. 扩展路径

### v2.0 (当前)
- 品类约束唯一源
- 成本单位修正
- 反例测试库
- 交付门禁
- Self-Iteration Engine 设计

### v2.1 (规划)
- 氨基酸约束 (赖氨酸/蛋氨酸)
- Ca/P 比约束
- 剩余 13 物种的品类规则补充
- `atlantic_salmon` 拼写修正

### v3.0 (规划)
- RustAgentTeam 实现
- Tauri 桌面 GUI
- JSON 协议完整实现
- LLM 层集成
