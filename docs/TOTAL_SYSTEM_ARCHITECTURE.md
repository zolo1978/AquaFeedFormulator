# AquaFeedFormulator — LLM + Prolog + Rust 水产饲料研发 SOP Agent 系统

> 版本：v2.0 | 日期：2026-06-05 (终审整改) | 总系统架构

---

## 系统定位

AquaFeedFormulator 是一个 **LLM + Prolog + Rust 三核协作的水产饲料研发 SOP Agent 系统**。

**不是单纯的「自动配方求解器」。LP Solver 只是 Prolog 层的一个子模块。**

核心价值链路：
```
需求澄清 → 规则建模 → 配方求解(LP子模块) → 门禁校验 → 报告交付 → 复盘迭代
```

| 层 | 职责 | 权限边界 |
|---|------|---------|
| **LLM** | 需求理解、知识草案生成、结果解释 | 不可裁决，输出默认 draft |
| **Prolog** | SOP主控、逻辑判断、规则验证、交付门禁 | 决定能不能执行 |
| **Rust** | 工程执行、状态管理、工具调用、日志、报告 | 每步问 Prolog can_execute |
| **LP Solver** | 约束满足 + 成本最小化求解 | Prolog 子模块，仅负责求解 |

---

## 总体架构

```
                         ┌─────────────────────┐
                         │    用户 (CLI / GUI)   │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │   LLM 需求抽取层      │
                         │  (draft, 不可裁决)    │
                         └──────────┬──────────┘
                                    │ draft
                         ┌──────────▼──────────┐
                         │  Prolog SOP 主控层    │
                         │                      │
                         │  sop_gatekeeper.pl   │  ← 动作放行/阻断
                         │  sop_workflow.pl     │  ← 状态机
                         │                      │
                         │  编排：              │
                         │  1. can_execute?     │
                         │  2. 调用 LP Solver   │
                         │  3. 结果校验          │
                         │  4. 交付门禁          │
                         └──────────┬──────────┘
                                    │
            ┌───────────────────────┼───────────────────────┐
            │                       │                       │
    ┌───────▼───────┐     ┌────────▼────────┐     ┌────────▼────────┐
    │ LP Solver     │     │ Rule Engine     │     │ Delivery Gate   │
    │ (子模块)       │     │                 │     │                 │
    │               │     │ category_rules  │     │ delivery_       │
    │ formulation_  │     │ nutrition_rules │     │ gatekeeper.pl   │
    │ lp_engine.pl  │     │                 │     │                 │
    └───────────────┘     └─────────────────┘     └─────────────────┘
                                    │
                         ┌──────────▼──────────┐
                         │  Rust 执行层          │
                         │                      │
                         │  管状态 (非 Prolog)   │
                         │  调 Prolog (每次注入) │
                         │  输出 JSON            │
                         │  记录 execution_log   │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │  用户验收 + 复盘迭代   │
                         └──────────────────────┘
```

---

## 三核分工

**LLM 负责创意（不可裁决）**，**Prolog 负责裁判（绝对不能错）**，**Rust 负责执行（100% 可靠）**。

### Prolog 的 6 个核心判断权

1. 需求是否完整？ — `requirement_gatekeeper.pl`
2. 规则是否通过验证？ — `knowledge_validator.pl`
3. 是否允许执行求解？ — `sop_gatekeeper.pl → can_execute/2`
4. 求解结果是否通过规则校验？ — `formula_rule_engine.pl`
5. 是否允许交付？ — `delivery_gatekeeper.pl → deliverable/4`
6. 复盘后生成什么补丁？ — `self_iteration_engine.pl`

### Rust 的职责

- CLI 入口 (`aqua solve --species X --stage Y --project Z`)
- 项目状态持久化（Rust 管状态，Prolog 只判断）
- 每次调用 Prolog 时注入当前 `project_state` fact
- 输出 `validation_result.json` / `delivery_decision.json` / `execution_log.json`
- 全链路执行日志

### 数据流（精简）

```
用户输入 → LLM draft → Prolog can_execute? → LP Solve → delivery_gatekeeper → Rust JSON/日志 → 用户验收
```

---

## 规则生命周期

```
draft → validated → approved → active → archived → deprecated
```

激活条件：Prolog 一致性通过 + 反例回归通过 + 专家确认 + 旧版可回滚。

---

## 文件结构（当前实现）

```
AquaFeedFormulator/
├── rust-core/                        # Rust CLI
│   ├── Cargo.toml
│   └── src/main.rs                   # aqua solve 入口
│
├── rules/                            # Prolog 规则层
│   ├── sop_engine.pl                 # 总入口（引用各子模块）
│   ├── sop_workflow.pl               # SOP 状态机
│   ├── sop_gatekeeper.pl             # can_execute + allow_fallback
│   ├── category_rules.pl             # ★ 唯一种类约束源 + 成本区间
│   ├── formulation_lp_engine.pl      # LP 求解核心（子模块）
│   ├── delivery_gatekeeper.pl        # deliverable/4 交付入口
│   ├── counterexample_tests.pl       # 7 个自动化反例测试
│   ├── self_iteration_engine.pl      # cost_unit_anomaly 最小闭环
│   ├── ingredient_db.pl              # 原料数据库
│   └── species_nutrition.pl          # 物种营养数据库
│
├── schemas/                          # JSON Schema
│   ├── validation_result.schema.json
│   ├── delivery_decision.schema.json
│   └── execution_log.schema.json
│
├── generated/                        # 输出目录
│   ├── validation_result.json
│   ├── delivery_decision.json
│   └── execution_log.json
│
├── docs/
│   ├── TOTAL_SYSTEM_ARCHITECTURE.md   # ★ 本文档
│   ├── TECHNICAL_SPEC.md              # LP Solver 子模块说明书
│   ├── ARCHITECTURE.md                # LP Solver 子模块架构
│   ├── REMEDIATION_PLAN.md            # 整改方案
│   └── IMPLEMENTATION_EXECUTION_PLAN.md
│
└── SOP.md
```

---

## 报告边界声明（强制）

> 当前 LP 解是在当前原料库、当前价格、当前营养与品类约束下的大宗原料成本最小可行解。该结果为数学模型下的可行方案，不构成未经养殖试验验证的最终商业配方建议，不可表述为「降本 40%」等商业承诺。实际生产前应经过小试、中试养殖试验和营养专家确认。

---

*AquaFeedFormulator — Rust 执行 + Prolog 门禁 + JSON 结果 + 日志追溯 + 交付判断。LP Solver 是子模块，LLM Agent 是后续。*
