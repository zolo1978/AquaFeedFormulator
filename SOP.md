# AquaFeedFormulator 操作 SOP

> 最后更新：2026-06-04 | scryer-prolog v0.10 | Prolog SOP v1.0

---

## 系统概览

```
                  ┌──────────────────────────┐
                  │  sop_engine.pl (主控)      │
                  │  solve_formulation/2       │
                  └──────┬───────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
  ingredient_db.pl  species_nutrition.pl  formula_closure_validator.pl
  (原料数据)          (营养目标)          (品类约束)
         │               │               │
         └───────────────┼───────────────┘
                         ▼
              formulation_solver_v2.pl (LP核心)
                         │
                         ▼
                  结果输出 + 闭合校验
```

**单入口**: `solve_formulation(Species, Stage).` — 端到端配方求解。

### Prolog SOP 引擎 vs 旧流程

| 维度 | 旧流程 | Prolog SOP v1.0 |
|------|--------|-----------------|
| 流程编排 | 手动 SOP.md + validate.sh | `sop_engine.pl` 单入口 |
| 配方生成 | LLM 生成草案 | LP 线性规划求解 |
| 品类约束 | 事后校验(闭合validator) | **进入 LP 约束** |
| 营养约束 | 事后校验(nutrition_calculator) | **进入 LP 约束** |
| 闭合校验 | 事后校验 | LP 内置 + 输出确认 |
| 交付门禁 | 无 | `solve_formulation` 失败时输出 infeasible |

---

## 快速开始

```bash
# 单物种端到端配方
scryer-prolog -g "
    consult('rules/ingredient_db.pl'),
    consult('rules/species_nutrition.pl'),
    consult('rules/sop_engine.pl'),
    solve_formulation(japanese_eel, adult),
    halt.
"

# 批量测试四个物种
for sp in japanese_eel white_shrimp common_carp largemouth_bass; do
    scryer-prolog -g "
        consult('rules/ingredient_db.pl'),
        consult('rules/species_nutrition.pl'),
        consult('rules/sop_engine.pl'),
        solve_formulation($sp, adult),
        halt.
    "
done
```

---

## 物种/阶段编码

| 物种 | 编码 | 可用阶段 |
|------|------|---------|
| 日本鳗鲡 | `japanese_eel` | elver, juvenile, adult |
| 南美白对虾 | `white_shrimp` | zoea, mysis, postlarva, juvenile, adult |
| 鲤鱼 | `common_carp` | fry, juvenile, adult |
| 加州鲈 | `largemouth_bass` | fry, juvenile, adult |

---

## 品类约束机制

品类约束定义在 `sop_engine.pl` 的 `species_category_rule/5` 中：

```prolog
% 鳗鱼：动物蛋白≥35%（通用），淀粉≤25%
species_category_rule(japanese_eel, _, animal_protein, min, 35.0, _).
species_category_rule(japanese_eel, _, starch, max, 25.0, _).

% 通配规则（兜底）
species_category_rule(_, _, animal_protein, min, 20.0, _).
species_category_rule(_, _, starch, max, 30.0, _).
```

品类映射函数：
- `animal_protein` → `animal_protein_ingredient/1`
- `plant_protein` → `plant_protein_ingredient/1`
- `oil` → `oil_ingredient/1`
- `starch` → `starch_ingredient/1`

---

## 文件结构

| 文件 | 用途 |
|------|------|
| `rules/sop_engine.pl` | **主控** — 端到端 LP 配方求解 |
| `rules/ingredient_db.pl` | 原料数据库（100+种） |
| `rules/species_nutrition.pl` | 物种营养需求 |
| `rules/formulation_solver_v2.pl` | LP 求解器（独立使用） |
| `rules/formula_closure_validator.pl` | 品类约束定义（引入sop_engine使用） |
| `rules/nutrition_calculator.pl` | 营养值计算（手动配方用） |
| `rules/cross_species_consistency.pl` | 物种命名一致性校验 |

---

## 已知限制

1. `format/2` 在 scryper-prolog 不可用 → 使用 `write` + `round` 做精度控制
2. LP 结果含理数（`rdiv`）→ Python 做后处理时需 `float()`
3. 固定原料（添加剂/矿物）需 `ingredient_db.pl` 中定义 `Min > 0` 且 `Min = Max`
4. 品类约束源于 `formula_closure_validator.pl` 定义，当前手动同步到 `sop_engine.pl`
