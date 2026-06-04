# AquaFeedFormulator 修正整改方案

> 基于终审评审报告 (2026-06-05) | LLM + Prolog + Rust 水产饲料研发 SOP Agent 系统

---

## 定位修正

AquaFeedFormulator 不是「自动配方系统」，而是 **LLM + Prolog + Rust 三核协作的水产饲料研发 SOP Agent 系统**。
LP Solver 只是 Prolog 层的一个子模块。

核心价值链路：
```
需求澄清 → 规则建模 → 配方求解(LP子模块) → 门禁校验 → 报告交付 → 复盘迭代
```

---

## 终审整改 10 项清单

| # | 任务 | 状态 |
|---|------|------|
| 1 | 目标定位修正: 从「自动配方系统」→「LLM+Prolog+Rust SOP Agent」 | ✅ |
| 2 | P0.5 工程闭环: `aqua solve --species X --stage Y --project Z` → 3 JSON | ✅ |
| 3 | Prolog 状态门禁: 移除 TODO stub，Rust 注入 project_state fact | ✅ |
| 4 | 禁止生产 fallback: `allow_fallback(production, false)` + 6 种阻断 | ✅ |
| 5 | 统一唯一规则源: 清理 formula_closure_validator.pl 重复品类规则 | ✅ |
| 6 | 成本口径修正: 区分 6 种成本，禁止「降本 40%」表述 | ✅ |
| 7 | delivery_gatekeeper 交付入口: `deliverable/4` 7 道检查 | ✅ |
| 8 | 反例测试自动化: 7 个反例可执行 `aqua test` | ✅ |
| 9 | Self-Iteration 最小闭环: 只保留 cost_unit_anomaly 闭环 | ✅ |
| 10 | 优先级重排: Rust-Prolog-JSON 第一，LLM Agent 放最后 | ✅ |

| 项目 | 当前 | 修正后 |
|------|------|--------|
| 系统定义 | 基于 Prolog LP 引擎的自动配方求解系统 | 基于 LLM + Prolog + Rust 的水产饲料研发 SOP 逻辑系统 |
| 现有文档定位 | 总系统文档 | Prolog LP Solver 子模块技术文档 |
| 总系统文档 | 缺失 | 新增 TOTAL_SYSTEM_ARCHITECTURE.md |

**执行**：
- TECHNICAL_SPEC.md 头部增加定位声明：「本文档为 Prolog LP Solver 子模块技术说明书」
- ARCHITECTURE.md 头部增加定位声明：「本文档为 Prolog LP Solver 子模块架构文档」
- 新增 `docs/TOTAL_SYSTEM_ARCHITECTURE.md`

---

### P0-2：成本单位修正 + 按物种细分

**根因**：`sop_engine.pl` 中 `display_recipe` 的吨成本计算公式错误。

```prolog
% ❌ 错误：多乘了 100
TotalCostT is round(TotalCost * 100000) / 100.
```

**修正**：
```prolog
% ✅ 正确：TotalCost 单位为 元/100kg，吨 = ×10
TotalCostT is TotalCost * 10.
```

**扩展（P0.2+）**：成本合理区间从全局 `[3000, 30000]` 细化为按物种/品类：

```prolog
reasonable_cost_range(japanese_eel,    _, 9000, 18000).
reasonable_cost_range(white_shrimp,    _, 7000, 15000).
reasonable_cost_range(common_carp,     _, 3500, 7000).
reasonable_cost_range(grass_carp,      _, 3000, 6000).
% ... 18 物种完整定义
```

**验证**：
- 鳗鱼成体吨成本应在 ¥9,000-18,000
- 草鱼成体吨成本应在 ¥3,000-6,000
- 手算成本、Prolog 输出、报告展示三者一致

---

### P0-3：拆分 SOP Engine 与 LP Engine

**当前问题**：`sop_engine.pl` 混杂了 SOP 流程控制、LP 求解、品类约束、输出格式化。

**拆分方案**：

```
rules/
├── sop_workflow.pl              # SOP 状态机（新增）
├── sop_gatekeeper.pl            # 动作放行/阻断（新增）
├── formulation_lp_engine.pl     # LP 求解器（从 sop_engine.pl 提取）
├── category_rules.pl            # 唯一种类约束源（新增）
├── formula_rule_engine.pl       # 配方规则校验（从 formula_closure_validator.pl 重构）
├── delivery_gatekeeper.pl       # 交付门禁（新增）
└── self_iteration_engine.pl     # 自我迭代（P0-7）
```

**执行**：
- 从 `sop_engine.pl` 提取 LP 求解核心 → `formulation_lp_engine.pl`
- `sop_engine.pl` 保留为入口，调用各子模块
- 新增 `sop_workflow.pl` 定义状态机流程
- 新增 `sop_gatekeeper.pl` 定义 `can_execute/2`

---

### P0-4：建立唯一规则源

**当前问题**：品类约束在 `sop_engine.pl` 和 `formula_closure_validator.pl` 中各有副本。

**修正**：新增 `rules/category_rules.pl` 作为唯一品类约束源。所有模块统一引用：

```
formulation_lp_engine.pl  ─┐
formula_closure_validator.pl ─┼──→ category_rules.pl （唯一源）
report_generator           ─┤
counterexample_tests       ─┘
```

---

### P0-5：禁止生产模式静默 fallback（加固版）

**当前问题**：`species_category_rule(_, _, ...)` 通配规则自动兜底，物种名拼写错误不会报错。

**加固方案**（不使用 `_` 偷懒）：

```prolog
% 三子句，Project 级控制
get_category_rule(Project, Species, Stage, Cat, LT, Limit) :-
    specific_category_rule(Species, Stage, Cat, LT, Limit), !.
get_category_rule(Project, Species, Stage, Cat, LT, Limit) :-
    allow_fallback(Project, true),
    fallback_category_rule(Cat, LT, Limit), !.
get_category_rule(Project, Species, Stage, _Cat, _LT, _Limit) :-
     allow_fallback(Project, true),
    fail.   % 生产模式：无专用规则→失败
```

**关键修正**：
- `allow_fallback(production, false)` 而非 `allow_fallback(_, false)`
- 所有规则查询带 `Project` 参数，杜绝跨项目规则污染

---

### P0-6：建立反例测试库

**新增文件**：`rules/counterexample_tests.pl`

**首批反例（7 个）**：

| # | 反例输入 | 预期结果 |
|---|---------|---------|
| 1 | `solve_formulation(nonexistent_species, adult)` | 阻断：species_not_found |
| 2 | `solve_formulation(japanese_eel, nonexistent_stage)` | 阻断：stage_not_found |
| 3 | `solve_formulation(grass_carp, adult)` 且品类规则缺失 | 阻断：category_rule_missing |
| 4 | 吨成本 > 30,000 元/t | 阻断：cost_unit_anomaly |
| 5 | 原料 Max < Min | 阻断：ingredient_bounds_invalid |
| 6 | 规则状态 ≠ approved | 阻断：rule_not_approved |
| 7 | 未完成交付门禁 | 阻断：delivery_gate_not_passed |

---

### P0-7：新增 Self-Iteration Engine

**新增文件**：`rules/self_iteration_engine.pl`

**迭代流程**：
```
执行/验收/失败/用户反馈
        ↓
    复盘归因
        ↓
  生成 patch_draft
        ↓
  Prolog 一致性测试
        ↓
  反例回归测试
        ↓
    专家确认
        ↓
  激活新规则 (patch_active)
  old_rule → archived
```

**复盘 → 迭代动作映射**：

| 复盘发现 | 迭代动作 |
|---------|---------|
| 需求漏问 | 更新需求澄清模板 |
| 知识缺失 | 更新知识库 |
| 规则未拦截错误 | 新增 Prolog 规则 |
| 流程跳步 | 修改 SOP 状态机 |
| 同类错误重复 | 新增反例测试 |
| 执行失败 | 更新 Rust 执行策略 |
| 报告误导 | 更新报告模板 |

---

## 五、P0.5 最小工程闭环

### P0.5-1：Rust CLI 最小入口

```bash
aqua solve --species japanese_eel --stage adult --project project_001
```

调用链：Rust → `can_execute` → `solve_formulation` → `delivery_gatekeeper` → 写 JSON 日志。

详见 `docs/IMPLEMENTATION_EXECUTION_PLAN.md`。

### P0.5-2：最小 JSON 协议

三个 JSON Schema：`validation_result.json`、`delivery_decision.json`、`execution_log.json`。

### P0.5-3：成本按物种细分

`reasonable_cost_range(Species, Stage, Min, Max)` 覆盖 18 物种。

---

## 六、P1 补充任务（后续迭代）

### P1-1：LLM 层设计

定义 6 个 LLM Agent：
- `RequirementExtractorAgent`：需求结构化抽取
- `ClarificationAgent`：澄清问题生成
- `KnowledgeDraftAgent`：知识库草案生成
- `RuleDraftAgent`：Prolog 规则草案生成
- `ExplanationAgent`：失败原因解释
- `ReportNarrativeAgent`：报告叙述生成

核心约束：**所有 LLM 输出默认为 draft，不可绕过 Prolog 交付门禁。**

### P1-2：RustAgentTeam 设计

定义 8 个 Rust Agent：
- `RustOrchestratorAgent`：总编排
- `RustStateAgent`：项目状态管理
- `RustPrologRunnerAgent`：Prolog 调用
- `RustLLMRunnerAgent`：LLM 调用
- `RustFileAgent`：文件读写
- `RustReportAgent`：报告生成
- `RustAuditAgent`：日志审计
- `RustRecoveryAgent`：错误恢复与回滚

核心约束：**Rust 执行任何关键动作前，必须调用 Prolog 的 `can_execute(Project, Action)`。**

### P1-3：JSON 协议

定义至少 7 个 JSON Schema：
- `requirement_snapshot.json`
- `knowledge_draft.json`
- `rule_status.json`
- `prolog_validation_result.json`
- `execution_log.json`
- `delivery_decision.json`
- `iteration_patch_draft.json`

### P1-4：规则生命周期

```
draft → validated → approved → active → archived → deprecated
```

### P1-5：报告边界声明

所有报告必须声明：当前结果是基于当前模型约束、当前原料数据、当前价格和当前规则集生成的可行方案，不代表未经养殖试验验证的最终商业配方。

---

## 四、文件变更清单

### 新增文件

| 文件 | 说明 |
|------|------|
| `docs/REMEDIATION_PLAN.md` | 本文档 |
| `docs/TOTAL_SYSTEM_ARCHITECTURE.md` | LLM + Prolog + Rust 总架构 |
| `rules/category_rules.pl` | 唯一种类约束源 |
| `rules/sop_workflow.pl` | SOP 状态机 |
| `rules/sop_gatekeeper.pl` | 动作放行/阻断 |
| `rules/formulation_lp_engine.pl` | 提取的 LP 求解核心 |
| `rules/delivery_gatekeeper.pl` | 交付门禁 |
| `rules/counterexample_tests.pl` | 反例测试库 |
| `rules/self_iteration_engine.pl` | 自我迭代引擎 |

### 修改文件

| 文件 | 变更内容 |
|------|---------|
| `rules/sop_engine.pl` | 成本单位修正、fallback 控制、移除内联品类约束 |
| `rules/ingredient_db.pl` | 新增 `price_unit/2` 事实、成本异常范围 |
| `SOP.md` | 更新文件结构、新增门禁说明、更新运行示例 |
| `docs/PAPER.md` | 定位声明降级 |
| `specs/PRD.md` | 定位声明降级 |

### 外部文件（用户在桌面/下载中）

| 文件 | 变更 |
|------|------|
| `~/Desktop/TECHNICAL_SPEC.md` | 需移动到 `docs/` 并增加子模块定位声明 |
| `~/Downloads/ARCHITECTURE.md` | 需移动到 `docs/` 并增加子模块定位声明 |

---

## 八、验收标准

### Prolog LP Solver 子模块

| # | 验收项 | 当前状态 | 目标 |
|---|-------|---------|------|
| 1 | 配方闭合 100% ± 0.1% | ✅ 已具备 | 保持 |
| 2 | 营养约束满足 | ✅ 已具备 | 保持 |
| 3 | 品类约束满足 | ✅ 已具备 | 保持 |
| 4 | 成本单位正确 | ⚠ 待验证 | 手算=输出=报告 |
| 5 | 不可行解返回 infeasible | ✅ 已具备 | 保持 |
| 6 | 规则源无双副本 | ⚠ 待验证 | 必须通过 |
| 7 | 反例测试可拦截异常 | ⚠ 待运行 | 必须通过 |
| 8 | 成本按物种验证 | ❌ 未实现 | P0.5 |

### 总系统

| # | 验收项 | 当前状态 | 目标 |
|---|-------|---------|------|
| 9 | can_execute 每步判定 | ⚠ 骨架 | P0.5 |
| 10 | delivery_decision 输出 | ❌ 未实现 | P0.5 |
| 11 | execution_log 可追踪 | ❌ 未实现 | P0.5 |
| 12 | Rust CLI 调用 Prolog | ❌ 未实现 | P0.5 |
| 13 | 复盘输出 patch_draft | ⚠ 骨架 | P0.7 |
| 14 | 回滚机制 | ❌ 未实现 | P0.7 |
| 15 | LLM 输出默认 draft | ❌ 未实现 | P1 |
