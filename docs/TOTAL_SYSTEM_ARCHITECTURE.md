# AquaFeedFormulator LLM + Prolog + Rust 总体技术架构

> 版本：v1.0 | 日期：2026-06-05 | 总系统架构

---

## 1. 系统定位

AquaFeedFormulator 是一个基于 **LLM + Prolog + Rust** 三核协作的水产饲料研发 SOP 逻辑系统。

| 层 | 职责 | 权限边界 |
|---|------|---------|
| **LLM** | 需求理解、知识草案生成、结果解释 | 不可裁决，不可直接激活规则 |
| **Prolog** | SOP 主控、逻辑判断、规则验证、交付门禁 | 决定能不能执行 |
| **Rust** | 工程执行、状态管理、工具调用、日志、报告 | 只执行 Prolog 许可的动作 |

**核心原则**：LLM 提供「可能会对」的知识，Prolog 做「绝对不能错」的判断，Rust 做「100% 可靠」的执行。

**子模块说明**：Prolog LP Solver 是 AquaFeedFormulator 的自动配方求解子模块，详见 `docs/TECHNICAL_SPEC.md` 和 `docs/ARCHITECTURE.md`。

---

## 2. 总体架构

```
                         ┌─────────────────────┐
                         │    用户交互层         │
                         │  CLI / Tauri GUI     │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │   LLM 需求抽取层      │
                         │                      │
                         │  RequirementExtractor│
                         │  ClarificationAgent  │
                         │  KnowledgeDraftAgent │
                         │  RuleDraftAgent      │
                         │  ExplanationAgent    │
                         │  ReportNarrativeAgent│
                         │                      │
                         │  所有输出默认 draft   │
                         └──────────┬──────────┘
                                    │ draft
                         ┌──────────▼──────────┐
                         │  Prolog 需求完整性检查 │
                         │  requirement_gatekeeper│
                         │  ├─ 物种存在?         │
                         │  ├─ 阶段存在?         │
                         │  ├─ 预算合理?         │
                         │  └─ 必填字段完整?      │
                         └──────────┬──────────┘
                                    │ confirmed
                         ┌──────────▼──────────┐
                         │  用户确认             │
                         │  requirement_snapshot │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │  LLM 知识库草案生成   │
                         │  knowledge_draft.json │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │  Prolog 规则建模+验证  │
                         │  knowledge_validator │
                         │  rule_status: draft  │
                         │  → validated         │
                         │  → approved          │
                         └──────────┬──────────┘
                                    │ approved
                         ┌──────────▼──────────┐
                         │  Prolog SOP 主控层    │
                         │                      │
                         │  sop_workflow.pl     │  ← 状态机
                         │  sop_gatekeeper.pl   │  ← 动作放行/阻断
                         │                      │
                         │  编排：              │
                         │  1. 加载规则          │
                         │  2. 检查 can_execute  │
                         │  3. 调用 LP Solver   │
                         │  4. 结果校验          │
                         │  5. 交付门禁          │
                         └──────────┬──────────┘
                                    │ execute
            ┌───────────────────────┼───────────────────────┐
            │                       │                       │
    ┌───────▼───────┐     ┌────────▼────────┐     ┌────────▼────────┐
    │ LP Solver     │     │ Rule Engine     │     │ Delivery Gate   │
    │ (子模块)       │     │                 │     │                 │
    │               │     │ category_rules  │     │ delivery_       │
    │ formulation_  │     │ nutrition_rules │     │ gatekeeper.pl   │
    │ lp_engine.pl  │     │ ingredient_rules│     │                 │
    │               │     │ functional_rules│     │ 配方闭合?       │
    │ 约束满足       │     │ compliance_rules│     │ 成本合理?       │
    │ 成本最小       │     │                 │     │ 规则 approved?  │
    │               │     │ 对求解结果进行    │     │ 无合规风险?     │
    │               │     │ 多维度规则校验    │     │                 │
    └───────┬───────┘     └────────┬────────┘     └────────┬────────┘
            │                       │                       │
            └───────────────────────┼───────────────────────┘
                                    │ result
                         ┌──────────▼──────────┐
                         │  Rust 执行层          │
                         │                      │
                         │  RustOrchestrator    │  ← 总编排
                         │  RustStateAgent      │  ← 项目状态
                         │  RustPrologRunner    │  ← Prolog 调用
                         │  RustLLMRunner       │  ← LLM 调用
                         │  RustFileAgent       │  ← 文件 I/O
                         │  RustReportAgent     │  ← 报告生成
                         │  RustAuditAgent      │  ← 日志审计
                         │  RustRecoveryAgent   │  ← 错误恢复
                         │                      │
                         │  每步执行前：         │
                         │  Prolog.can_execute  │
                         │  (Project, Action)   │
                         └──────────┬──────────┘
                                    │ report
                         ┌──────────▼──────────┐
                         │  用户验收             │
                         └──────────┬──────────┘
                                    │
                         ┌──────────▼──────────┐
                         │  Self-Iteration      │
                         │  Engine (Prolog)     │
                         │                      │
                         │  复盘归因 → patch     │
                         │  回归测试 → 确认      │
                         │  规则激活 → 回滚就绪  │
                         └──────────────────────┘
```

---

## 3. 三核分工

### 3.1 LLM 层 — 创意、理解、草案

```
LLM 能做：
  ✅ 理解用户自然语言需求
  ✅ 抽取结构化需求字段
  ✅ 生成澄清问题供用户确认
  ✅ 从资料中萃取知识草案
  ✅ 生成 Prolog 规则草案
  ✅ 解释求解失败原因
  ✅ 生成配方报告叙述

LLM 不能做：
  ❌ 直接判定配方合格/不合格
  ❌ 直接激活规则
  ❌ 绕过 Prolog 交付门禁
  ❌ 运行求解器
```

### 3.2 Prolog 层 — 裁判、规则、门禁

```
Prolog 的 6 个核心判断权：

  1. 需求是否完整？
     requirement_gatekeeper.pl

  2. 知识/规则是否通过验证？
     knowledge_validator.pl

  3. 是否允许执行求解？
     sop_gatekeeper.pl → can_execute/2

  4. 求解结果是否通过规则校验？
     formula_rule_engine.pl

  5. 是否允许交付？
     delivery_gatekeeper.pl

  6. 复盘后生成什么补丁？
     self_iteration_engine.pl
```

### 3.3 Rust 层 — 执行、可靠、审计

```
Rust 的职责：
  - CLI/API 入口
  - 项目状态持久化
  - 调用 scryer-prolog
  - 调用 LLM API
  - 文件系统操作
  - JSON 序列化/反序列化
  - 执行日志完整记录
  - 错误恢复与回滚
  - DOCX/PDF 报告生成

Rust 的约束：
  - 任何关键动作前，调用 Prolog 的 can_execute
  - 被 Prolog 拒绝的动作，记录日志但不执行
  - 所有执行路径可回溯
```

---

## 4. 数据流

```
1. 用户输入
   ↓
2. LLM: requirement draft → requirement_snapshot.json
   ↓
3. Prolog: 检查完整性 → 缺失则生成澄清问题
   ↓
4. 用户确认 → requirement_snapshot.json (confirmed)
   ↓
5. LLM: knowledge_draft.json / rule_draft.pl
   ↓
6. Prolog: 验证草案 → rule_status: validated | rejected
   ↓
7. 专家确认 → rule_status: approved
   ↓
8. Prolog SOP: can_execute → yes
   ↓
9. Prolog LP: solve → recipe_sop
   ↓
10. Prolog: 规则校验 → pass
   ↓
11. Prolog: 交付门禁 → deliverable
   ↓
12. Rust: 生成报告 → DOCX/PDF
   ↓
13. 用户验收
   ↓
14. Self-Iteration: 复盘 → patch_draft
```

---

## 5. Agent 团队定义

### 5.1 PrologAgentTeam (规则层)

| Agent | 文件 | 职责 |
|-------|------|------|
| SOP 主控 | `sop_engine.pl` | 总入口，路由到各子模块 |
| SOP 状态机 | `sop_workflow.pl` | 定义合法状态转换 |
| SOP 门禁 | `sop_gatekeeper.pl` | can_execute/2 判定 |
| 需求门禁 | `requirement_gatekeeper.pl` | 需求完整性校验 |
| 知识验证 | `knowledge_validator.pl` | 规则草案验证 |
| LP 求解器 | `formulation_lp_engine.pl` | 约束满足 + 成本优化 |
| 品类规则 | `category_rules.pl` | 唯一种类约束源 |
| 配方规则 | `formula_rule_engine.pl` | 多维度配方校验 |
| 功能规则 | `functional_rules.pl` | 功能性添加剂需求 |
| 合规规则 | `compliance_rules.pl` | GB/T 标准校验 |
| 交付门禁 | `delivery_gatekeeper.pl` | 交付判定 |
| 反例测试 | `counterexample_tests.pl` | 回归测试 |
| 自我迭代 | `self_iteration_engine.pl` | 复盘 → 补丁生成 |
| 规则版本 | `rule_version_registry.pl` | 规则版本管理 |

### 5.2 LLM Agents (草案层)

| Agent | 职责 |
|-------|------|
| RequirementExtractorAgent | 自然语言 → 结构化需求 |
| ClarificationAgent | 缺失/歧义 → 澄清问题 |
| KnowledgeDraftAgent | 资料 → 知识草案 |
| RuleDraftAgent | 知识草案 → Prolog 规则草案 |
| ExplanationAgent | 失败 → 可读解释 |
| ReportNarrativeAgent | 数据 → 报告叙述 |

### 5.3 RustAgentTeam (执行层)

| Agent | 职责 |
|-------|------|
| RustOrchestratorAgent | 总编排，顺序调用 |
| RustStateAgent | 项目状态 CRUD |
| RustPrologRunnerAgent | scryer-prolog CLI 调用 |
| RustLLMRunnerAgent | LLM API 调用 |
| RustFileAgent | JSON/PL/MD 文件 I/O |
| RustReportAgent | DOCX/PDF 报告生成 |
| RustAuditAgent | 全链路日志 |
| RustRecoveryAgent | 错误恢复 + 规则回滚 |

---

## 6. 规则生命周期

```
draft ─── LLM 生成，未经任何验证
  │
  ▼
validated ─── Prolog 一致性检查通过
  │
  ▼
approved ─── 专家/用户确认
  │
  ▼
active ─── 生产中生效
  │
  ▼
archived ─── 被新版本替代
  │
  ▼
deprecated ─── 彻底废弃
```

**激活条件**：
1. Prolog 规则一致性测试通过
2. 反例回归测试通过
3. 专家或用户确认
4. 旧版本可回滚

---

## 7. 项目状态模型

```
init → requirement_draft → requirement_confirmed
     → knowledge_draft → knowledge_validated → knowledge_approved
     → solving → solved
     → validated → gated
     → reporting → reported
     → delivered
     → reviewed → iterating
```

每次状态变更由 Rust 调用 Prolog 的 `can_execute` 判定。

---

## 8. JSON 协议

### 8.1 requirement_snapshot.json

```json
{
  "project_id": "PROJ-2026-001",
  "species": "japanese_eel",
  "stage": "adult",
  "budget_per_ton": 8000,
  "constraints": ["no_antibiotics", "sustainable_only"],
  "status": "draft",
  "missing_fields": ["target_weight_gain"],
  "clarification_questions": ["目标增重率?"]
}
```

### 8.2 knowledge_draft.json

```json
{
  "project_id": "PROJ-2026-001",
  "source": "llm",
  "status": "draft",
  "new_ingredients": [],
  "new_rules": [],
  "confidence_scores": {}
}
```

### 8.3 rule_status.json

```json
{
  "rule_id": "RUL-2026-001",
  "file": "category_rules.pl",
  "status": "approved",
  "approved_by": "expert_zhang",
  "approved_at": "2026-06-05T10:00:00Z",
  "previous_version": "RUL-2025-012"
}
```

### 8.4 execution_log.json

```json
{
  "project_id": "PROJ-2026-001",
  "steps": [
    {"step": 1, "action": "requirement_check", "result": "pass", "timestamp": "..."},
    {"step": 2, "action": "can_execute:solve", "result": "allow", "timestamp": "..."},
    {"step": 3, "action": "lp_solve", "result": "recipe_sop", "timestamp": "..."}
  ]
}
```

### 8.5 delivery_decision.json

```json
{
  "project_id": "PROJ-2026-001",
  "deliverable": true,
  "checks": {
    "closure": "pass",
    "nutrition": "pass",
    "category": "pass",
    "cost_unit": "pass",
    "compliance": "pass"
  },
  "warnings": ["氨基酸未建模", "养殖试验未完成"]
}
```

### 8.6 iteration_patch_draft.json

```json
{
  "patch_id": "PATCH-2026-001",
  "trigger": "鳗鱼成体 cost_unit_anomaly 触发",
  "root_cause": "display_recipe 吨成本公式错误",
  "action_type": "rule_fix",
  "affected_files": ["sop_engine.pl"],
  "new_counterexamples": ["cost_unit_anomaly_test"],
  "status": "patch_draft"
}
```

---

## 9. 交付门禁检查表

| # | 检查项 | 判定 |
|---|-------|------|
| 1 | 配方闭合 100% ± 0.1% | must pass |
| 2 | 所有营养约束满足 | must pass |
| 3 | 所有品类约束满足 | must pass |
| 4 | 成本在合理区间 [3000, 30000] | must pass |
| 5 | 所有规则状态 = active | must pass |
| 6 | 反例测试全部通过 | must pass |
| 7 | 合规检查通过 | must pass |
| 8 | 用户已确认 requirement_snapshot | must pass |
| 9 | 执行日志完整 | should pass |
| 10 | 氨基酸平衡（v1.1） | optional |

---

## 10. Self-Iteration Engine

### 10.1 定义

Self-Iteration Engine 在每次执行、验收、失败或用户反馈后，将问题归因转化为可测试补丁，并通过 Prolog 反例测试、专家确认和版本管理，使知识库、规则库、SOP、执行策略与报告模板持续进化。

### 10.2 迭代流程

```
Review → Diagnose → Patch → Test → Approve → Activate → Rollback-ready
```

### 10.3 复盘 → 迭代动作

| 复盘问题 | 迭代动作 |
|---------|---------|
| 需求漏问 | 更新需求澄清模板 |
| 知识缺失 | 更新知识库 |
| 规则未拦截错误 | 新增 Prolog 规则 |
| 流程跳步 | 修改 SOP 状态机 |
| 同类错误重复 | 新增反例测试 |
| 执行失败 | 更新 Rust 执行策略 |
| 报告误导 | 更新报告模板 |
| 需人工判断 | 标记 expert_review_required |

### 10.4 补丁生命周期

```
patch_draft → patch_validated → patch_approved → patch_active
                                                    │
                                          old_rule → archived
```

### 10.5 激活条件

1. Prolog 规则一致性测试通过
2. 反例回归测试通过
3. 专家或用户确认
4. 旧版本可回滚

---

## 11. 文件结构（目标）

```
AquaFeedFormulator/
├── rust-core/                  # RustAgentTeam (后续)
│   └── ...
│
├── rules/                      # PrologAgentTeam
│   ├── sop_engine.pl           # 总入口
│   ├── sop_workflow.pl         # SOP 状态机
│   ├── sop_gatekeeper.pl       # 动作放行/阻断
│   ├── requirement_gatekeeper.pl
│   ├── knowledge_validator.pl
│   ├── category_rules.pl       # ★ 唯一种类约束源
│   ├── nutrition_rules.pl
│   ├── ingredient_rules.pl
│   ├── formulation_lp_engine.pl  # LP 求解核心
│   ├── formula_rule_engine.pl
│   ├── functional_rules.pl
│   ├── compliance_rules.pl
│   ├── delivery_gatekeeper.pl
│   ├── counterexample_tests.pl
│   ├── self_iteration_engine.pl
│   ├── rule_version_registry.pl
│   ├── ingredient_db.pl        # 原料数据库
│   └── species_nutrition.pl    # 物种营养数据库
│
├── data/
│   ├── source_registry.json
│   └── formula_cases/
│
├── generated/
│   ├── requirement_snapshot.json
│   ├── knowledge_draft.json
│   ├── rule_patch_draft.json
│   ├── validation_result.json
│   ├── execution_log.json
│   └── reports/
│
├── docs/
│   ├── TOTAL_SYSTEM_ARCHITECTURE.md  ★ 本文档
│   ├── TECHNICAL_SPEC.md             # LP Solver 子模块说明书
│   ├── ARCHITECTURE.md               # LP Solver 子模块架构
│   ├── REMEDIATION_PLAN.md           # 整改方案
│   ├── PAPER.md                      # LP 方法论
│   └── LP_vs_LLM_comparison.md
│
├── specs/
│   └── PRD.md
│
├── SOP.md
├── SOP-复盘.md
└── README.md
```

---

## 12. 报告边界声明（强制）

> **所有输出报告必须包含以下声明**：
>
> 本报告中的配方结果是基于 AquaFeedFormulator 当前约束模型、当前原料数据库、当前市场价格数据和当前规则集生成的可行方案。该结果代表在当前数学模型下的成本最小可行解，不构成未经养殖试验验证的最终商业配方建议。实际生产前，应经过小试、中试养殖试验和营养专家确认。

---

*AquaFeedFormulator — LLM 负责创意，Prolog 负责裁判，Rust 负责执行，Self-Iteration Engine 负责进化。*
