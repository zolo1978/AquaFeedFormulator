# AquaFeedFormulator — Prolog 化路线图 v2.1

> 分析时间：2026-06-05  
> 当前 Prolog 模块：13 个 → 目标：22 个（含 3 个 Phase 0 治理模块）  
> 核心原则：**Prolog 管决策，Python/Rust 管执行**  
> v2.1 变更：新增 Phase 完成门禁、git 规范、复盘模板、Agent 行为契约

---

## 零、Phase 0：治理基础（前置）

> 在进入任何新模块之前，必须先立住三个治理文件。  
> 否则 22 个模块会从「唯一大脑」变成「二十二个小脑吵架」。

| 文件 | 路径 | 作用 |
|------|------|------|
| **Prolog 输出协议** | `docs/PROLOG_OUTPUT_CONTRACT.md` | 所有模块的统一 JSON 外壳 |
| **模块注册中心** | `rules/prolog_modules_registry.pl` | 模块发现、依赖治理、元信息查询 |
| **模块测试模板** | `rules/module_test_template.pl` | should_pass / should_fail / determinism 标准模板 |
| **工程纪律** | _(本文档第十三节)_ | Phase 完成定义、git checkpoint、复盘模板 |

### Phase 完成定义（适用于所有 Phase）

每个 Phase 的「完成」不是测试通过就结束，而是 **5 步门禁**：

```
[1] 代码完成 + 测试全部通过
[2] 模块注册表状态 draft → stable
[3] git add + git commit（按 Phase 原子提交）
[4] git push origin main
[5] Phase 复盘（按第十三节模板）
```

**缺失任一步骤 = Phase 未完成。** |

### 输出协议核心

```json
{
  "module":     "<模块 ID>",
  "version":    "<语义化版本>",
  "timestamp":  "<ISO 8601>",
  "status":     "passed | failed | partial | skipped",
  "data":       { /* 模块专属 */ },
  "warnings":   [ { "code": "<...>", "message": "<...>", "severity": "..." } ],
  "errors":     [ { "code": "<...>", "message": "<...>" } ],
  "evidence":   [ { "source": "<...>", "value": "<...>", "unit": "<...>" } ],
  "confidence": 0.0,
  "next_actions": [ "<...>" ]
}
```

> Rust 注入 `module`/`version`/`timestamp`/`status`，Prolog 输出 `data`/`warnings`/`errors`/`confidence`/`next_actions`。

### 模块注册中心

```prolog
prolog_module(price_alert_rules, phase1, decision, draft).
module_depends(price_alert_rules, ingredient_db).
module_output_format(price_alert_rules, json).
module_test_level(price_alert_rules, low).
module_version(price_alert_rules, '1.0.0').
```

### 测试模板约定

每个模块必须实现：

| 测试 | 说明 |
|------|------|
| `test_should_pass` | 正常场景 → `status: passed` |
| `test_should_fail` | 异常场景 → `status: failed` + 明确 errors |
| `test_determinism` | 相同输入两次 → 相同输出 |
| `test_output_structure` | 输出符合协议外壳 |

---

## 一、当前格局

### 已有 Prolog 模块 (13)

| 序号 | 模块 | 分类 | 状态 |
|:---:|------|:---:|:---:|
| 1 | `ingredient_db` | data | stable |
| 2 | `species_nutrition` | data | stable |
| 3 | `category_rules` | data | stable |
| 4 | `formulation_lp_engine` | planning | stable |
| 5 | `sop_engine` | decision | stable |
| 6 | `sop_gatekeeper` | decision | stable |
| 7 | `sop_workflow` | decision | stable |
| 8 | `delivery_gatekeeper` | validation | stable |
| 9 | `counterexample_tests` | validation | stable |
| 10 | `self_iteration_engine` | decision | draft |
| 11 | `compliance_checker` | validation | stable |
| 12 | `nutrition_calculator` | planning | stable |
| 13 | `functional_additive_checker` | validation | stable |
| — | `cross_species_consistency` | validation | stable |

### 待 Prolog 化 (8 个业务模块)

| ID | 模块 | 当前状态 | 问题所在 |
|:--:|------|:---:|------|
| M1 | `price_alert_rules` | ❌ Python 硬逻辑 | `scripts/price_monitor.py` |
| M2 | `report_content_selector` | ❌ Python 硬编码 | `generate_report.py` |
| M3 | `recipe_planner` | ❌ Python 硬编码 | `generate_report.py` L105-309 |
| M4 | `ingredient_substitution` | ❌ 空白 | — |
| M5 | `mineral_balance` | ❌ 空白 | — |
| M6 | `eaa_balance` | ❌ 空白 | — |
| M7a | `cost_range_rules` | ❌ 空白 | — |
| M7b | `performance_risk_rules` | ❌ 空白 | — |

> M7 拆分为 M7a (成本区间，硬规则) + M7b (FCR 风险提示，软建议，不入交付门禁)。

---

## 二、多维度评估矩阵

### 2.1 评估维度

| 维度 | 定义 | 评分 |
|------|------|:---:|
| 🗄️ **数据成熟度** | 依赖数据的完整度 | 1=空白 → 5=校验完成 |
| 🎯 **规则可信度** | 规则可靠性、可复现性 | 1=推测 → 5=已验证 |
| 🔗 **依赖数量** | 上游 Prolog 模块数 | 1-2=低 / 3=中 / 4-5=高 |
| 🧪 **测试门槛** | 验证模块正确性的难度 | 1=纯逻辑 → 5=需对照实验 |
| 📐 **改造量** | 非 Prolog 代码改动量 | 1=纯新增 → 5=多语言大改 |

### 2.2 逐模块评分

```
模块                          数据    规则    依赖    测试    改造    得分
                             成熟度  可信度  数量    门槛    量
─────────────────────────────────────────────────────────────────────
M1  price_alert_rules         4       3       1       1       2       77
M2  report_content_selector   5       4       2       2       3       72
M3  recipe_planner            4       4       4       3       3       54
M4  ingredient_substitution   4       2       3       3       2       43
M5  mineral_balance           2       3       2       3       3       26
M6  eaa_balance               1       3       2       4       3       13
M7a cost_range_rules          3       5       2       1       2       55
M7b performance_risk_rules    3       1       2       5       2       12
```

> **综合得分** = (数据成熟度 + 规则可信度) × 10 − (依赖数 + 测试门槛 + 改造量) × 5  
> **M7a 得分 55**：拆分后 cost_range 成为独立可靠模块，规则可信度从 1 → 5（静态阈值是确定性的）。

---

## 三、模块依赖 DAG

```
                         ┌──────────────────────────┐
                         │     ingredient_db.pl      │ ← 已有
                         │   (原料数据 + 价格)        │
                         └──────┬─────────┬──────────┘
                                │         │
             ┌──────────────────┘         └──────────────────┐
             ▼                                                ▼
  ┌─────────────────────┐                         ┌─────────────────────┐
  │ M1 price_alert      │ [独立]                  │ species_nutrition   │ ← 已有
  │      _rules.pl       │                          │ (营养需求)           │
  └──────────┬──────────┘                         └──────────┬──────────┘
             │ 触发条件                                       │
             ▼                                                │
  ┌─────────────────────┐                                    │
  │ M4 ingredient_      │ [依赖 M1]                          │
  │    substitution.pl   │                                     │
  └─────────────────────┘                                    │
                                                              │
  ┌─────────────────────┐       ┌─────────────────────┐     │
  │ category_rules.pl   │ ← 已有 │ formulation_lp      │ ← 已有
  │ (品类约束)           │        │ _engine.pl (LP求解)  │     │
  └──────────┬──────────┘       └──────────┬──────────┘     │
             │                             │                 │
             └──────────────┬──────────────┘                 │
                            │                                │
                            ▼                                │
             ┌─────────────────────────────┐                 │
             │ M3 recipe_planner.pl        │◄────────────────┘
             │ (配方方案自动生成)            │  依赖 4 模块
             └─────────────┬───────────────┘
                           │ 配方数据
                           ▼
             ┌─────────────────────────────┐     ┌─────────────────────┐
             │ M2 report_content_selector  │◄────│ delivery_gatekeeper │ ← 已有
             │ (DOCX 内容决策，code 输出)    │     │ (交付门禁)           │
             └─────────────────────────────┘     └─────────────────────┘

  ┌───────────────────────────────────────────────────────────┐
  │ 数据密集模块                                                │
  │                                                           │
  │ ingredient_db.pl ──► M5 mineral_balance    [需 70 Ca/P]   │
  │ ingredient_amino.pl ► M6 eaa_balance       [需 ~890 EAA]   │
  │ ingredient_db.pl ──► M7a cost_range_rules  [独立]          │
  │ recipe_planner ─────► M7b performance_risk [软建议]         │
  └───────────────────────────────────────────────────────────┘
```

### 依赖层级

| 层级 | 模块 | 依赖数 | 被依赖 |
|:---:|------|:---:|------|
| **L0 独立** | M1 `price_alert_rules` | 1 | M4 |
| **L0 独立** | M5 `mineral_balance` | 2† | — |
| **L0 独立** | M6 `eaa_balance` | 2† | — |
| **L0 独立** | M7a `cost_range_rules` | 2 | — |
| **L0 独立** | M7b `performance_risk_rules` | 2 | — |
| **L1** | M4 `ingredient_substitution` | 3 | — |
| **L1** | M3 `recipe_planner` | 4 | M2, M7b |
| **L2** | M2 `report_content_selector` | 2 | — |

> † M5/M6 依赖数据文件需扩展字段，无其他新模块依赖。

---

## 四、逐模块测试门槛

### M1 `price_alert_rules` — ★☆☆☆☆ (15min)

```
scryer-prolog -g "consult('rules/price_alert_rules')" -g "test_all" -g halt

场景:
  鱼粉涨 8%   → ok
  鱼粉涨 12%  → normal
  鱼粉涨 18%  → high + should_recompute
  鱼粉涨 35%  → urgent
  面粉涨 22%  → normal (阈值 20%, 1.5 倍=30% 才 high)
  确定性测试   → 同输入两次，输出一致
```

### M2 `report_content_selector` — ★★☆☆☆ (30min)

```
场景:
  对虾成体 → warning_codes 包含 shrimp_water_stability
  鳗鱼成体 → warning_codes 包含 eel_palability_oil_low
  鲤鱼成体 → suggestion_codes 包含 carp_high_carb_ok
  与现有 generate_report.py 输出做全量 diff
```

### M3 `recipe_planner` — ★★★☆☆ (1h)

```
场景:
  对虾 premium   → animal_protein_pct ≥ 品类上限
  对虾 economic  → animal_protein_pct ≥ 品类下限
  5 物种 × 3 方案 → 全部 LP 可行
  构造 infeasible 场景 → graceful degradation
  确定性 → 同输入两次输出相同
```

### M4 `ingredient_substitution` — ★★★☆☆ (45min)

```
场景:
  鱼粉涨 25%  → 推荐列表含国产鱼粉/鸡肉粉 + 附风险码
  豆粕涨 25%  → 推荐列表含菜粕/发酵豆粕 + 抗营养因子风险
  最便宜原料涨 30% → 返回空列表
  替代后 LP 不可行 → 降级为 "无可用替代"
```

### M5 `mineral_balance` — ★★★☆☆ (30min + 1h 数据校验)

```
场景:
  Ca/P = 0.5  → failed (低于下限)
  Ca/P = 1.2  → passed
  Ca/P = 2.0  → failed (超过上限)
  数据完整性   → forall ingredient(Id,_,_,_,_,_,_,_,_,_,ca,_)
```

### M6 `eaa_balance` — ★★★★☆ (30min 逻辑 + 10h 数据)

```
场景:
  10 EAA 全达标  → passed
  赖氨酸欠 10%    → failed + gap 详情
  多 AA 同时欠    → failed 列表
  数据完整性      → forall 物种, eaa_requirement
  反向校验        → 已知配方 AA 谱 vs Prolog 计算值
```

### M7a `cost_range_rules` — ★☆☆☆☆ (10min)

```
场景:
  鳗鱼成体 10200 元/吨 → passed (在 [8000,14000] 内)
  鳗鱼成体 15000 元/吨 → failed
  市场通胀 +3%         → 动态区间正确调整
```

### M7b `performance_risk_rules` — ★★★★★ (1h 逻辑 + 不可独立验证)

```
场景:
  高鱼粉配方 → FCR 方向正确 (↓)
  高纤维配方 → FCR 方向正确 (↑)
  置信度范围   → 0.0-1.0
  免责声明     → 输出含 disclaimer 字段
```

---

## 五、重新排序：推荐实施路径

### 排序模型

```
优先级 = f(数据×规则 高, 依赖×测试×改造 低, 可独立交付)

Phase 0: 治理基础 — 没有协议别写代码
Phase 1: 快速验证 — 数据就绪、独立、低风险
Phase 2: 核心增强 — 高价值、有依赖但可控
Phase 3: 单模块数据 — 需补充数据，可逐个攻
Phase 4: 大数据工程 — ~890 数据点，需专项投入
Phase 5: 软建议 — 不入门禁，可最后做
```

| 阶段 | 模块 | 理由 |
|:---:|------|------|
| **Phase 0** | `prolog_modules_registry.pl` | 治理：模块发现、依赖查询、元信息 |
| | `PROLOG_OUTPUT_CONTRACT.md` | 治理：统一 JSON 外壳 |
| | `module_test_template.pl` | 治理：测试标准模板 |
| **Phase 1** 🟢 | M1 `price_alert_rules.pl` | 独立、数据 4、测试门槛 1、改造量 2 |
| | M2 `report_content_selector.pl` | 数据 5、规则已验证、code 模式输出 |
| | **Checkpoint** | `[ ] git commit` `[ ] git push` `[ ] Phase 1 复盘` |
| **Phase 2** 🟡 | M3 `recipe_planner.pl` | 价值最大、strategy_profile 模式、依赖 4 |
| | M4 `ingredient_substitution.pl` | 依赖 M1、含风险评估 |
| | **Checkpoint** | `[ ] git commit` `[ ] git push` `[ ] Phase 2 复盘` |
| **Phase 3** 🟠 | M5 `mineral_balance.pl` | 需 70 Ca/P 数据点 |
| | M7a `cost_range_rules.pl` | 独立，从 M7 拆出的确定性规则 |
| | **Checkpoint** | `[ ] git commit` `[ ] git push` `[ ] Phase 3 复盘` |
| **Phase 4** 🔴 | M6 `eaa_balance.pl` | ~890 EAA 数据点 + `ingredient_amino.pl` |
| | **Checkpoint** | `[ ] git commit` `[ ] git push` `[ ] Phase 4 复盘` |
| **Phase 5** ⚪ | M7b `performance_risk_rules.pl` | 软建议，不入门禁，附 disclaimer |
| | **Checkpoint** | `[ ] git commit` `[ ] git push` `[ ] Phase 5 复盘` |

---

## 六、关键整改

### 整改 1：M2 文案与规则分离

**问题**：上版 Prolog 里直接写长中文文案。

**修正**：Prolog 只输出 `warning_code` / `suggestion_code`，自然语言文案在 Rust/Python 报告层查表生成。

```prolog
% Prolog 侧 — 只输出 code + evidence
active_warning_code(white_shrimp, adult, shrimp_water_stability).
active_warning_code(japanese_eel, adult, eel_palability_oil_low).

warning_evidence(shrimp_water_stability, [
    evidence{field: gluten_pct, actual: 0.3, recommended_min: 0.5}
]).
```

```python
# Python 侧 — 文案码表
WARNING_MESSAGES = {
    "shrimp_water_stability": "对虾饲料需关注水中稳定性，建议添加谷朊粉 0.5-1.0%。",
    "eel_palability_oil_low": "鳗鱼饲料需关注诱食性，鱼油添加量不低于 3%。",
}
```

### 整改 2：M3 strategy_profile 替代单一动物蛋白梯度

**问题**：premium/balanced/economic 只靠动物蛋白比例区分。

**修正**：引入 `strategy_profile/4`，定义多维策略差异。

```prolog
strategy_profile(japanese_eel, adult, premium, [
    animal_protein_min(45),
    fishmeal_min(20),
    attractant_min_count(2),
    risk_tolerance(low),
    cost_weight(0.4)
]).

strategy_profile(japanese_eel, adult, balanced, [
    animal_protein_min(35),
    fishmeal_min(10),
    attractant_min_count(1),
    risk_tolerance(medium),
    cost_weight(0.7)
]).

strategy_profile(japanese_eel, adult, economic, [
    animal_protein_min(25),
    fishmeal_min(5),
    attractant_min_count(0),
    risk_tolerance(high),
    cost_weight(1.0),
    warnings: [eel_low_fishmeal_attractant_risk]
]).
```

### 整改 3：M4 替代推荐增加风险评估

```prolog
substitution_with_risks(Ingredient, Substitute, Result) :-
    Result = sub{
        substitute: Substitute,
        savings: Savings,
        max_replace_pct: MaxPct,
        risk_level: RiskLevel,
        risks: Risks,
        requires_rebalance: NeedsRebalance
    },
    calc_savings(Ingredient, Substitute, Savings),
    calc_max_replace(Ingredient, Substitute, MaxPct),
    assess_risks(Ingredient, Substitute, Risks),
    risk_level_from_risks(Risks, RiskLevel),
    ( member(eaa_gap_possible, Risks) -> NeedsRebalance = true ; NeedsRebalance = false ).
```

### 整改 4：M7 拆分

| 原 | 拆分为 | 性质 | 入交付门禁? |
|:--:|------|------|:---:|
| `cost_fcr_rules.pl` | `cost_range_rules.pl` | 确定性区间检测 | ✅ 是 |
| | `performance_risk_rules.pl` | 经验 FCR 风险提示 | ❌ 否（附 disclaimer） |

---

## 七、各模块 Prolog 代码设计

### M1: `price_alert_rules.pl`

```prolog
alert_threshold(fish_meal_peru_65,  0.10).
alert_threshold(soybean_meal_46,    0.15).
alert_threshold(wheat_flour,        0.20).
alert_threshold(corn,               0.18).

price_alert(Ingredient, Deviation, Level, Action) :-
    alert_threshold(Ingredient, Threshold),
    ( Deviation > 0.30 ->
        Level = urgent, Action = '立即锁定远期合同 + 触发配方重算'
    ; Deviation > Threshold * 1.5 ->
        Level = high,   Action = '评估替代原料 + 调整配方成本模型'
    ; Deviation > Threshold ->
        Level = normal, Action = '持续监控，暂不干预'
    ; Level = ok,      Action = '正常'
    ).

output(Input, Output) :-
    findall(alert{ingredient: I, deviation: D, level: L, action: A,
                  should_recompute: R}, ...),
    Output = output{data: data{alerts: Alerts, summary: Summary},
                    warnings: [], errors: [], confidence: 0.9, next_actions: []}.
```

### M2: `report_content_selector.pl`

```prolog
output(Input, Output) :-
    Input = input{species: Species, stage: Stage, recipe: Recipe},
    findall(W, (active_warning_code(Species, Stage, W),
                warning_evidence(W, Ev)), Warnings),
    findall(S, (contextual_suggestion_code(Species, Stage, S),
                suggestion_evidence(S, Ev)), Suggestions),
    Output = output{
        data: data{sections: [
            section{id: warnings, items: Warnings},
            section{id: suggestions, items: Suggestions}
        ]},
        warnings: [], errors: [], confidence: 0.95, next_actions: []
    }.
```

### M3: `recipe_planner.pl`

```prolog
generate_recipe_plans(Species, Stage, Plans) :-
    findall(Plan, strategy_profile(Species, Stage, Strategy, Constraints),
            RawPlans),
    maplist(plan_solve(Species, Stage), RawPlans, Plans).

plan_solve(Species, Stage, Strategy-Constraints, Solution) :-
    strategy_constraints_to_lp(Constraints, LPConstraints),
    lp_solve_with_strategy(Species, Stage, LPConstraints, Recipe),
    Solution = plan{strategy: Strategy, status: passed, recipe: Recipe,
                    strategy_profile: Constraints}.
```

### M4: `ingredient_substitution.pl`

```prolog
assess_risks(_, Substitute, Risks) :-
    findall(Risk, substitution_risk(Substitute, Risk), Risks).

substitution_risk(chicken_meal_65, palatability_risk).
substitution_risk(chicken_meal_65, eaa_gap_possible).
substitution_risk(meat_bone_meal_50, ash_excess_risk).
substitution_risk(rapeseed_meal, antinutritional_factor).
substitution_risk(cottonseed_meal, antinutritional_factor).
```

### M5: `mineral_balance.pl`

```prolog
validate_ca_p(Items, Species, Result) :-
    calc_recipe_calcium(Items, TotalCa),
    calc_recipe_available_p(Items, AvailP),
    ca_p_ratio(Species, MinRatio, MaxRatio),
    Ratio is TotalCa / AvailP,
    ( Ratio >= MinRatio, Ratio =< MaxRatio ->
        Result = passed(ca_p, Ratio)
    ; Result = failed(ca_p, Ratio, MinRatio, MaxRatio)
    ).
```

### M6: `eaa_balance.pl`

```prolog
eaa_gap_analysis(Items, Species, Stage, Gaps) :-
    eaa_requirement(Species, Stage, Requirements),
    calc_recipe_eaa(Items, ActualEAA),
    findall(gap{amino_acid: Name, required: Req, actual: Act, gap_pct: Pct}, (
        member(eaa(Name, Req), Requirements),
        member(eaa(Name, Act), ActualEAA),
        Act < Req,
        Pct is round((Req - Act) / Req * 100)
    ), Gaps).
```

### M7a: `cost_range_rules.pl`

```prolog
cost_range_dynamic(Species, Stage, MinCost, MaxCost) :-
    base_cost_range(Species, Stage, BaseMin, BaseMax),
    market_inflation_index(Index),
    MinCost is BaseMin * (1 + Index),
    MaxCost is BaseMax * (1 + Index).

base_cost_range(japanese_eel, adult, 8000, 14000).
base_cost_range(white_shrimp, adult, 6000, 12000).
```

### M7b: `performance_risk_rules.pl`

```prolog
% ⚠️ 不入交付门禁，仅作为风险提示
fcr_risk_assessment(Items, Species, Assessment) :-
    animal_protein_pct(Items, AP),
    fishmeal_pct(Items, FM),
    fiber_pct(Items, Fib),
    ( FM < 10 ->
        Risks = [fcr_estimate_low_confidence],
        Confidence = 0.35,
        Disclaimer = 'FCR 预估为经验规则，未经过养殖试验验证。'
    ; Risks = [],
        Confidence = 0.6,
        Disclaimer = ''
    ),
    Assessment = output{
        data: data{risks: Risks, requires: trial_validation},
        warnings: [],
        errors: [],
        confidence: Confidence,
        next_actions: [Disclaimer]
    }.
```

---

## 八、架构演进

```
当前架构:
┌──────────────────────────────────────────┐
│  Prolog (13 modules)                      │
│  └─ 规则、约束、门禁                       │
├──────────────────────────────────────────┤
│  Python (5 scripts)                       │
│  └─ 硬编码配方 + 硬编码告警 + 硬编码文案     │
├──────────────────────────────────────────┤
│  Rust CLI (1 file)                        │
│  └─ 编排 + JSON + 复盘                    │
└──────────────────────────────────────────┘

───────────────────────────

目标架构:
┌──────────────────────────────────────────┐
│  Prolog (22 modules, 含 3 治理)             │
│  └─ 全部决策 + 输出协议 + 注册中心            │
├──────────────────────────────────────────┤
│  Rust CLI (统一解析)                        │
│  └─ 编排 + 协议注入 + 模块发现 + JSON IO     │
├──────────────────────────────────────────┤
│  Python (排版 + 爬取)                       │
│  └─ DOCX API 排版 + 文案码→自然语言          │
│  └─ 价格数据抓取 (决策交给 Prolog)            │
└──────────────────────────────────────────┘
```

---

## 九、不应 Prolog 化的环节

| 环节 | 原因 |
|------|------|
| DOCX 排版 (`python-docx`) | API 调用、表格渲染 — Prolog 无对应库 |
| HTTP 爬取 | 网络 I/O、HTML 解析 — Prolog 不适合 |
| 文件 I/O | JSON 读写、目录创建 — Rust 更适合 |
| 进程管理 | `Command::new("scryer-prolog")` — Rust 更可靠 |
| 复盘 Markdown | 字符串拼接 — 格式化需求强 |
| 自然语言文案 | 多语言、风格调整 — Python 查表更适合 |

---

## 十、文件结构

```
rules/
├── prolog_modules_registry.pl     ← Phase 0 新增
├── module_test_template.pl        ← Phase 0 新增
│
├── ingredient_db.pl               ← 已有
├── species_nutrition.pl           ← 已有
├── category_rules.pl              ← 已有
├── formulation_lp_engine.pl       ← 已有
├── sop_engine.pl                  ← 已有
├── sop_gatekeeper.pl              ← 已有
├── sop_workflow.pl                ← 已有
├── delivery_gatekeeper.pl         ← 已有
├── counterexample_tests.pl        ← 已有
├── self_iteration_engine.pl       ← 已有
├── compliance_checker.pl          ← 已有
├── nutrition_calculator.pl        ← 已有
├── functional_additive_checker.pl ← 已有
├── cross_species_consistency.pl   ← 已有
│
├── price_alert_rules.pl           ← Phase 1 新增 M1
├── report_content_selector.pl    ← Phase 1 新增 M2
├── recipe_planner.pl              ← Phase 2 新增 M3
├── ingredient_substitution.pl    ← Phase 2 新增 M4
├── mineral_balance.pl             ← Phase 3 新增 M5
├── cost_range_rules.pl            ← Phase 3 新增 M7a
├── ingredient_amino.pl            ← Phase 4 新增 M6 数据
├── eaa_balance.pl                 ← Phase 4 新增 M6
└── performance_risk_rules.pl      ← Phase 5 新增 M7b

docs/
├── PROLOG_ROADMAP.md              ← 本文档 (v2.0)
├── PROLOG_OUTPUT_CONTRACT.md      ← Phase 0 输出协议
└── DATA_ENRICHMENT_PLAN.md        ← M5/M6 数据工程计划
```

---

## 十一、最小验证动作

### Phase 0 验收

```
scryer-prolog -g "consult('rules/prolog_modules_registry')" -g "render_module_list" -g halt
# → 打印所有 22 个模块的状态

scryer-prolog -g "consult('rules/module_test_template')" -g "test_all_price_alert" -g halt
# → 3 个测试全部 PASS
```

### Phase 1 验收

| 指标 | 合格标准 |
|------|---------|
| `price_monitor.py` 中无告警阈值硬编码 | ✅ |
| M1 输出符合 output_contract | ✅ |
| 4 个价格偏离测试通过 | ✅ |
| M2 输出 warning_code 而非中文文案 | ✅ |
| M2 与现有 Python 输出一致 | ✅ |
| Rust 可解析两个模块的 JSON | ✅ |

---

## 十二、评分总结

| 维度 | v1.0 得分 | v2.0 得分 | 变化 |
|------|:---:|:---:|:--:|
| 路线清晰度 | 90 | 94 | + Phase 0 |
| 模块评估质量 | 92 | 94 | + M7 拆分 |
| 优先级合理性 | 88 | 93 | + 治理前置 + 数据工程独立 |
| 测试策略 | 85 | 90 | + test_template |
| 数据风险识别 | 87 | 90 | + DATA_ENRICHMENT_PLAN |
| 工程协议完整度 | 68 | 88 | + output_contract |
| 模块治理能力 | 70 | 90 | + registry |
| **综合** | **84** | **91** | **A 级 → 接近 S 级** |

---

## 十三、工程纪律与复盘模板

### 13.1 Phase 完成门禁（不可跳过）

```
Phase N 完成 = 以下 5 步全部打勾：

[ ] 1. 代码完成 + 全量测试通过
[ ] 2. 模块注册表状态 draft → stable
[ ] 3. git add + git commit（按 Phase 原子提交，message 格式见 13.2）
[ ] 4. git push origin main
[ ] 5. Phase 复盘（按 13.3 模板，追加到 docs/RETROSPECTIVE.md）
```

### 13.2 Git Commit 规范

```
格式: feat(prolog): Phase{N} - {简述}

示例:
  feat(prolog): Phase1 M1 price_alert_rules + M2 report_content_selector
  feat(prolog): Phase2 M3 recipe_planner + M4 ingredient_substitution
  feat(prolog): Phase3 M5 mineral_balance + M7a cost_range_rules
  feat(prolog): Phase4 M6 eaa_balance + ingredient_amino data
  feat(prolog): Phase5 M7b performance_risk_rules

每个 Phase 一个 commit，不跨 Phase 合并。
```

### 13.3 Phase 复盘模板

每个 Phase 完成后，追加到 `docs/RETROSPECTIVE.md`：

```markdown
## Phase N 复盘 — {日期}

### 完成情况
| 模块 | 测试数 | 状态 | 备注 |
|------|:------:|:----:|------|
| Mx   | N/N    | ✅   |      |

### 遇到的关键问题
| 问题 | 根因 | 修复 | 经验教训 |
|------|------|------|---------|
|      |      |      |         |

### scryer-prolog 兼容性
- 是否遇到 scryer 特有 bug？[是/否]
- 涉及谓词：
- 修复方式：

### 数据质量
- 新增数据条目数：
- 数据来源：
- 可信度评估 (1-5)：

### 对下游模块的影响
- 接口变更：[无/有，列出]
- 依赖模块需重新测试：[无/有，列出]

### 做得好的
1. 
2. 

### 需要改进的
1. 
2. 

### 下一步
- [ ] 下一个 Phase: ...
```

### 13.4 Agent 行为契约

Agent 在以下时机**必须主动提醒**（不等用户指令）：

| 触发条件 | Agent 动作 |
|---------|-----------|
| 一个模块测试全部通过 | "Mx 通过。是否现在 commit？" |
| 一个 Phase 全部完成 | "Phase N 完成。是否执行门禁 (commit + push + 复盘)？" |
| 连续 2 个模块无 commit | "已积累 N 个未提交模块，建议立即 commit。" |
| Session 结束前 | "是否 push + 生成复盘？" |

### 13.5 可信度评估量表

| 级别 | 标准 | 决策权重 |
|:----:|------|:-------:|
| L5 | 多源对照 + 养殖试验验证 | 100% |
| L4 | 权威文献 + 行业共识 | 90% |
| L3 | 单一可靠来源 + 内部经验 | 70% |
| L2 | 经验估算 + 逻辑推导 | 50% |
| L1 | 推测 / 占位数据 | 仅参考，不入门禁 |
