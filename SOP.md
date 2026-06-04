# AquaFeedFormulator 操作 SOP

> 最后更新：2026-06-05 | scryer-prolog v0.10 | 终审整改版
>
> Rust 执行 + Prolog 门禁 + JSON 结果 + 日志追溯 + 交付判断。
> LP Solver 是子模块，LLM Agent 是后续。

---

## 系统定位

AquaFeedFormulator 是 **LLM + Prolog + Rust 三核协作的水产饲料研发 SOP Agent 系统**。
**不是单纯的「自动配方求解器」。LP Solver 只是 Prolog 层的一个子模块。**

| 层 | 职责 | 权限 |
|---|------|------|
| LLM | 需求理解、知识草案、结果解释 | 不可裁决，输出默认 draft |
| Prolog | SOP主控、规则验证、交付门禁 | 决定能不能执行 |
| Rust | 工程执行、状态管理、JSON输出 | 每步问 Prolog can_execute |
| LP Solver | 约束满足 + 成本最小求解 | Prolog 子模块 |

---

## 系统概览

```
用户: aqua solve --species japanese_eel --stage adult --project production
        │
        ▼
   Rust CLI: 注入 project_state → 调 scryer-prolog
        │
   ┌────▼────────────────────────────────────┐
   │  Prolog SOP 主控                         │
   │                                          │
   │  1. can_execute(production, solve(...)) │  ← sop_gatekeeper
   │  2. solve_formulation(Species, Stage)   │  ← sop_engine → LP
   │  3. deliverable(Recipe, Spp, Stg, Dec)  │  ← delivery_gatekeeper
   └────┬────────────────────────────────────┘
        │
        ▼
   Rust CLI: validation_result.json
              delivery_decision.json
              execution_log.json
```

**核心命令**：
```bash
# 求解
cargo run -- solve --species japanese_eel --stage adult --project production
# 反例测试
cargo run -- test
# 门禁验证
cargo run -- gate --project production
```
        │                        │                        │
        ├── can_execute/2        ├── lp_solve/6           ├── species_category_rule/6
        ├── allow_fallback/2     ├── 整数缩放策略          ├── fallback_category_rule/3
        └── cost_in_range/1      └── simplex 求解          └── category_check/2
                                 │
                    ┌────────────┼────────────┐
                    ▼            ▼            ▼
          ingredient_db.pl  species_nutrition.pl  delivery_gatekeeper.pl
          (原料数据)          (营养目标)            (交付门禁)
```

**单入口**: `solve_formulation(Species, Stage).` — 端到端配方求解。

---

## v2.0 vs v1.0 变更

| 维度 | v1.0 | v2.0 (P0整改后) |
|------|------|-----------------|
| 品类约束源 | sop_engine.pl 内联 + formula_closure_validator.pl 双副本 | `category_rules.pl` 唯一源 |
| Fallback | 通配规则自动兜底 | `allow_fallback/2` 控制，生产模式禁止 |
| 成本显示 | TotalCost × 1000（bug: 多乘100） | TotalCost × 10（正确） |
| 成本异常检测 | 无 | `cost_in_range/1` [3000, 30000] |
| 交付门禁 | 无 | `delivery_gatekeeper.pl` |
| 反例测试 | 无 | `counterexample_tests.pl` |
| 自我迭代 | 无 | `self_iteration_engine.pl` |
| LP求解 | 内联在 sop_engine.pl | 提取到 `formulation_lp_engine.pl` |
| SOP状态机 | 无 | `sop_workflow.pl` |

---

## 快速开始

```bash
# 单物种端到端配方 (新模块结构)
scryer-prolog -g "
    consult('rules/ingredient_db.pl'),
    consult('rules/species_nutrition.pl'),
    consult('rules/category_rules.pl'),
    consult('rules/sop_gatekeeper.pl'),
    consult('rules/formulation_lp_engine.pl'),
    consult('rules/sop_engine.pl'),
    solve_formulation(japanese_eel, adult),
    halt.
"

# 运行反例测试
scryer-prolog -g "
    consult('rules/ingredient_db.pl'),
    consult('rules/species_nutrition.pl'),
    consult('rules/category_rules.pl'),
    consult('rules/sop_gatekeeper.pl'),
    consult('rules/counterexample_tests.pl'),
    test_all_counterexamples,
    halt.
"

# 批量测试
for sp in japanese_eel white_shrimp common_carp largemouth_bass; do
    scryer-prolog -g "
        consult('rules/ingredient_db.pl'),
        consult('rules/species_nutrition.pl'),
        consult('rules/category_rules.pl'),
        consult('rules/sop_gatekeeper.pl'),
        consult('rules/formulation_lp_engine.pl'),
        consult('rules/sop_engine.pl'),
        solve_formulation($sp, adult), halt.
    "
done
```

---

## 品类约束机制 (P0-4/P0-5)

品类约束 **唯一源**：`rules/category_rules.pl`

**查询接口**：

```prolog
% 获取某物种/阶段的品类约束（严格模式，无 fallback）
species_category_constraints(Species, Stage, Constraints).

% 检查是否有专属规则
has_category_rules(Species, Stage).

% fallback 受 allow_fallback/2 控制
% 生产模式: allow_fallback(_, false).  → 无专用规则时失败
% 测试模式: allow_fallback(test, true). → 使用全局兜底规则
```

**新增品类规则的物种**：日本鳗鲡、南美白对虾、鲤鱼、加州鲈、草鱼（v2.0 新增）

---

## 成本单位 (P0-2+ 按物种细分)

| 字段 | 单位 |
|------|------|
| `ingredient/11` Price | 元/kg |
| LP 目标函数系数 | `round(Price × 10)` |
| 求解器内部 Cost | `Pct × Price` (元/100kg) |
| 吨成本 | `TotalCost × 10` (元/吨) |

**按物种合理区间**：

| 物种 | 合理吨成本 (元/t) |
|------|-------------------|
| 日本鳗鲡 | 9,000 - 18,000 |
| 加州鲈 | 9,000 - 15,000 |
| 南美白对虾 | 7,000 - 15,000 |
| 虹鳟 | 7,000 - 14,000 |
| 鲤鱼/草鱼/鲫鱼 | 3,000 - 7,000 |
| 罗非鱼/鲶鱼 | 3,500 - 7,000 |

完整 18 物种定义见 `rules/category_rules.pl`。

---

## 文件结构 (v2.0)

```
AquaFeedFormulator/
├── rules/
│   ├── sop_engine.pl                 ★ 总入口
│   ├── sop_workflow.pl               ★ SOP 状态机 (新增)
│   ├── sop_gatekeeper.pl             ★ 门禁 + fallback 控制 (新增)
│   ├── formulation_lp_engine.pl      ★ LP 求解核心 (提取)
│   ├── category_rules.pl             ★ 唯一品类约束源 (新增)
│   ├── delivery_gatekeeper.pl        ★ 交付门禁 (新增)
│   ├── counterexample_tests.pl       ★ 反例测试库 (新增)
│   ├── self_iteration_engine.pl      ★ 自我迭代引擎 (新增)
│   ├── ingredient_db.pl              原料数据库（100+ 种）
│   ├── species_nutrition.pl          物种营养需求（18 种）
│   ├── formulation_solver_v2.pl      LP 求解器（独立使用，保留）
│   ├── formula_closure_validator.pl  品类约束规则（改为引用 category_rules.pl）
│   ├── nutrition_calculator.pl       手配配方营养值计算
│   ├── cross_species_consistency.pl  物种命名一致性冒烟
│   ├── functional_additive_checker.pl 功能性添加剂校验
│   └── compliance_checker.pl         法规合规校验
├── docs/
│   ├── TOTAL_SYSTEM_ARCHITECTURE.md  ★ 总系统架构 (新增)
│   ├── REMEDIATION_PLAN.md           ★ 整改方案 (新增)
│   ├── PAPER.md                      LP 方法论
│   └── LP_vs_LLM_comparison.md       LP vs LLM 对比
├── SOP.md                            本文档
└── README.md
```

---

## 交付门禁 (P0-3)

求解完成后，必须通过 `delivery_gatekeeper.pl` 的 4 项检查：

| # | 检查项 | 判定标准 |
|---|-------|---------|
| 1 | 闭合 | 100% ± 0.1% |
| 2 | 营养 | Pro/Fat ≥ 目标, Fib/Ash ≤ 目标 |
| 3 | 品类 | 所有 `species_category_rule` 满足 |
| 4 | 成本 | ¥3,000 ≤ 吨成本 ≤ ¥30,000 |

---

## 报告边界声明（强制）

所有输出报告必须包含：

> 本报告中的配方结果是基于 AquaFeedFormulator 当前约束模型、当前原料数据库、当前市场价格数据和当前规则集生成的可行方案。该结果代表在当前数学模型下的成本最小可行解，不构成未经养殖试验验证的最终商业配方建议。

---

## 已知限制

1. 氨基酸平衡未建模（赖氨酸/蛋氨酸/苏氨酸）
2. Ca/P 比未约束
3. 消化率/可消化能未建模
4. 抗营养因子未建模
5. 预混料成本按零计（实际 ¥20-80/kg）
6. LP 连续解，0.1% 步长天然整数但未显式约束
7. `format/2` 在 scryper-prolog 不可用
8. `atlantic_salmon` 拼写为 `atlanic_salmon`（待修正）
9. 18 物种中仅 5 种有完整品类规则，其余需补充
