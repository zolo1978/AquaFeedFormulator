# AquaFeedFormulator 逻辑链 SOP 复盘

> 复盘日期：2026-06-04 | 引擎：scryper-prolog v0.10 | 输出：虾 + 鳗鱼各 3 方案

---

## 总览：一条配方的完整流水线

```
┌──────────────┐    ┌───────────────┐    ┌──────────────┐    ┌────────────┐
│ 1. 配方设计   │ → │ 2. Prolog 校验 │ → │ 3. DOCX 输出  │ → │ 4. 交付     │
│ 手配 / 手算   │    │ 闭合+品类+功能  │    │ Python 脚本   │    │ 桌面 .docx  │
└──────────────┘    └───────────────┘    └──────────────┘    └────────────┘
```

## 第一步：配方设计（手配流程）

### 1.1 为什么不用自动求解器

`formulation_solver.pl` 采用 generate-and-test 穷举策略。实际尝试结论：

| 维度 | 数值 | 说明 |
|------|------|------|
| 可选主料 | ~14 种 | 来自 `base_ingredient/1` |
| 步长 | 1% | 商业配方最小精度 |
| 搜索空间 | ≈ 50^14 | 组合爆炸, 不可行 |
| 实际耗时 | >10 分钟无解 | 虾/鳗鱼均放弃自动求解 |

**教训**：饲料配方本质是 NP-hard 组合优化，纯 Prolog 穷举不可行。工业可行路径是混合整数规划 (MILP) 或遗传算法，当前 Prolog 引擎不适合做求解器。

### 1.2 手配标准操作

**Step 0 — 确定目标**
- 查 `species_nutrition.pl` 获取 Protein / Fat / Fiber / Ash 目标
- 查 `formula_closure_validator.pl` 查品类约束（淀粉上限、动物蛋白下限、油脂范围）

**Step 1 — 选料**
- 动物蛋白源：鱼粉 (Peru/Domestic)、鸡肉粉、血粉、鱿鱼膏
- 植物蛋白源：豆粕、发酵豆粕、棉粕、玉米蛋白粉
- 淀粉/粘合：面粉、木薯淀粉、脱脂米糠
- 油脂：鱼油、磷脂油
- 添加剂：磷酸氢钙、预混料、胆碱、VC、甜菜碱、抗氧化剂、防霉剂、食盐

**Step 2 — 分配合计**
1. 先分配大料（鱼粉 + 豆粕 + 面粉类 ≈ 70-80%），粗略估算粗蛋白
2. 补充中小料（玉米蛋白粉、米糠、淀粉类 ≈ 10-15%）
3. 固定微型料（添加剂 ≈ 3-5%）
4. 调整至总和 = 100.00%

**Step 3 — 写入 Prolog 配方文件**
```prolog
eel_recipe_a(recipe(japanese_eel, juvenile,
    [item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 35.0, 0),
     item(fish_meal_domestic_60, '国产鱼粉(60%)', 15.0, 0),
     ...
    ], Cost, Protein, Fat, Fiber, Ash)).
```

⚠ **关键**：Species 参数必须与 `species_category_rule/6` 和 `species_functional_requirement/4` 中使用的物种名一致，否则品类约束和功能检查静默跳过（见第四步缺陷记录）。

---

## 第二步：Prolog 校验管道

### 2.1 校验三件套

执行命令：
```bash
scryper-prolog ingredient_db.pl species_nutrition.pl \
    formula_closure_validator.pl functional_additive_checker.pl \
    compliance_checker.pl \
    shrimp_recipes.pl \
    -g "validate_all_shrimp" -g halt
```

| 模块 | 文件 | 检查内容 |
|------|------|---------|
| 闭合校验 | `formula_closure_validator.pl` | 总和=100% ± 0.1%, 品类约束 |
| 功能完整性 | `functional_additive_checker.pl` | 4 大功能组覆盖 |
| 合规检查 | `compliance_checker.pl` | 禁用物质、添加剂用量 |

### 2.2 闭合校验逻辑

```
validate_formula_closure/2
  ├── sum_item_percents → TotalPct
  ├── closure_status (容差 ±0.1%)
  │     ├── ok:      Diff ∈ [-0.1, 0.1]
  │     ├── over:    Diff > 0.1
  │     └── under:   Diff < -0.1
  ├── check_category_limits
  │     ├── species_category_rule(Species, Stage, Category, LimitType, Limit, Desc)
  │     └── 逐个品类求和比对 (starch / animal_protein / oil / phosphorus)
  └── → closure_report(passed/failed, TotalPct, Criticals, Warnings)
```

### 2.3 功能完整性逻辑

```
check_functional_completeness/4
  ├── 4 个功能组: attractant / liver_protection / gut_health / water_stability
  ├── 每种功能组有 primary / secondary / auxiliary 三级成员
  ├── 按物种×阶段获取 Required 最低覆盖数
  │     ├── species_functional_requirement(Species, Stage, Group, N)
  │     └── 无匹配 → 通用水产默认 (attractant≥1, liver≥1, water_stability≥1)
  └── → functional_report(passed/failed, Passed, Missing, Weak)
```

### 2.4 scryper-prolog v0.10 兼容性

Prolog 规则文件不使用 SWI-Prolog 特有谓词，每个文件头部手动实现：
```prolog
sum_list([], 0).
sum_list([H|T], Sum) :- sum_list(T, Rest), Sum is H + Rest.

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

% 禁止: format/3, predsort/3, length/2, maplist/2, findall/4
```

⚠ 多文件加载时注意 `discontiguous` 警告——多个文件定义的 `sum_list/2` 会被 scryer 视为不连续谓词，需用 `:- discontiguous sum_list/2.` 声明（目前以 warning 忽略）。

---

## 第三步：DOCX 报告生成

### 3.1 生成器结构

Python 脚本 (`generate_xxx_report.py`) 使用 `python-docx` 库：

```python
# 报告结构（5 部分）
# 封面 → 品种需求 → 配方详情(3方案) → 方案对比表 → Prolog校验结果 → 使用建议
```

| 部分 | 内容 |
|------|------|
| 封面 | 品种中英文名 + 日期 + 引擎版本 |
| §1 营养需求 | 引用 species_nutrition.pl 数据 + 品类约束摘要 |
| §2 配方详情 | 每方案含策略说明 + 完整配方表(序号/原料/比例/累计/功能) + 吨成本 |
| §3 方案对比 | 统一对比表: 成本/蛋白/鱼粉总量/动物蛋白/淀粉/油脂 |
| §4 校验结果 | 闭合/淀粉/动物蛋白/油脂/功能组逐项 ✅/⚠ |
| §5 使用建议 | 每方案个性化建议 + 通用注意事项 |

### 3.2 输出路径

统一输出至 `/Users/weifengchen/Desktop/`，文件命名 `{中文品种名}{阶段}饲料配方报告.docx`。

---

## 第四步：已发现缺陷与教训

### 缺陷 1：物种命名不一致 **【已修复】**

| 文件 | 物种命名 |
|------|---------|
| `species_nutrition.pl` | `white_shrimp` |
| `formula_closure_validator.pl` | ~~shrimp~~ → `white_shrimp` ✅ |
| `functional_additive_checker.pl` | ~~shrimp~~ → `white_shrimp` ✅ |

**影响**：品类约束检查中 `species_category_rule(shrimp, _, ...)` 匹配不到配方的 `white_shrimp`，静默回退到通用水产规则（淀粉 ≤30% 而非虾料实际的 ≤20%）。

**根因**：三个文件由不同 Agent 独立编写，无编译时命名一致性检查。

### 缺陷 2：鳗鱼命名不一致 **【未修复】**

| 文件 | 物种命名 |
|------|---------|
| `species_nutrition.pl` | `japanese_eel` |
| `formula_closure_validator.pl` | `eel` |
| `functional_additive_checker.pl` | `eel` |

**影响**：鳗鱼配方传入 `japanese_eel`，品类约束回退到通用规则（淀粉 ≤30% / 动物蛋白 ≥20%），而非鳗鱼幼鳗专用规则（淀粉 ≤22% / 动物蛋白 ≥40%）。功能检查同样回退到通用默认。

**当前缓解**：本次鳗鱼配方即使按通用规则也能通过，因为设计时已手动确保合规。但严格说是校验静默缺失——如果未来有边缘方案 (如淀粉 25% / 动物蛋白 35%)，会漏报。

**修复方案**：统一为 `japanese_eel`，与 `species_nutrition.pl` 保持一致。

### 缺陷 3：自动求解器不可用 **【已知，无计划修复】**

`formulation_solver.pl` 的穷举搜索（14 种原料 × 1% 步长）在实际配方任务上不可行。此为架构级问题，需引入 MILP 或启发式算法才能解决。

### 缺陷 4：无法独立计算粗蛋白等营养值 **【已知】**

手配配方时，Protein / Fat / Fiber / Ash 字段靠人工估算而非 Prolog 计算。`formulation_solver.pl` 虽保留了 `adjusted_nutrition` 计算逻辑，但只在穷举搜索路径中触发，手配模式未接入。

---

## 第五步：完整文件清单

```
AquaFeedFormulator/rules/
├── ingredient_db.pl              # 原料数据库 (成分/价格/品类)
├── species_nutrition.pl          # 物种×阶段 营养需求
├── formulation_solver.pl         # 自动求解器 (穷举, 不可用)
├── compliance_checker.pl         # 合规校验 (禁用物质/添加剂)
├── ingredient_standards.pl       # 原料标准
├── formula_closure_validator.pl  # 闭合校验 + 品类约束 ★
├── functional_additive_checker.pl # 功能完整性检查 ★
├── formula_examples.pl           # 示例配方 (旧)
├── closure_validator_test.pl     # 闭合校验测试用例
├── shrimp_closure_test.pl        # 虾配方测试 (含不闭合案例)
├── shrimp_recipes.pl             # 虾正式配方 (A/B/C 3方案) ★
├── eel_recipes.pl                # 鳗鱼正式配方 (A/B/C 3方案) ★
generate_shrimp_report.py         # 虾 DOCX 生成器
generate_eel_report.py            # 鳗鱼 DOCX 生成器
```

★ 标记为核心交付物或核心校验模块。

---

## 第六步：推荐改进路线

| 优先级 | 改进项 | 工作量 |
|--------|--------|--------|
| P0 | 修复 `eel` → `japanese_eel` 命名一致性 | 5 分钟 (编辑 2 个文件) |
| P1 | 增加物种命名一致性冒烟测试 (交叉比对 3 个文件的物种 atom) | 30 分钟 |
| P1 | 手配配方自动计算 Protein/Fat/Fiber/Ash (脱离 solver 独立运行) | 2 小时 |
| P2 | 替换穷举求解器为 MILP (Python ortools/pulp) | 1-2 天 |
| P3 | DOCX 生成器泛化 (每种新物种无需重写 Python 脚本) | 1 天 |

---

## 总结

**当前系统能做什么**：
- 接收手配配方 → Prolog 校验闭合/品类/功能 → 生成专业 DOCX 报告

**当前系统不能做什么**：
- 自动求解配方（穷举不可行，无 MILP/启发式替代）
- 手配时自动计算营养值（需人工估算 Protein/Fat 等）
- 跨文件物种命名一致性保障（silent fallback 风险）
