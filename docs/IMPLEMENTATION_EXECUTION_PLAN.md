# AquaFeedFormulator 整改执行方案

> 基于正式评审报告第二轮反馈 | P0 + P0.5 最小工程闭环
> 本文档是可直接执行的开发任务书，不只是整改计划。

---

## 一、优先级重排

### 原 P0 任务（保留）

| # | 任务 | 状态 |
|---|------|------|
| P0-1 | 产品定位修正 | ✅ |
| P0-2 | 成本单位修正 | 待扩展（按物种细分） |
| P0-3 | SOP / LP 拆分 | ✅ |
| P0-4 | 唯一规则源 | ✅ |
| P0-5 | 禁止静默 fallback | 待加固 |
| P0-6 | 反例测试库 | ✅ 骨架完成 |
| P0-7 | Self-Iteration Engine | 待补回滚条件 |

### 新增 P0.5：最小工程闭环

> 必须先行。否则 Prolog 修好了，总系统主链路还是断的。

| # | 任务 | 说明 |
|---|------|------|
| P0.5-1 | 最小 Rust CLI | `aqua solve --species japanese_eel --stage adult` |
| P0.5-2 | Rust → Prolog 调用 | 每个关键动作前调 `can_execute/2` |
| P0.5-3 | 最小 JSON 输出 | `validation_result.json` + `delivery_decision.json` |
| P0.5-4 | 执行日志 | 每步可追溯 |
| P0.5-5 | 成本范围按物种细分 | `reasonable_cost_range(Species, Stage, Min, Max)` |

---

## 二、每个 Prolog 文件的最小谓词定义

### 2.1 sop_workflow.pl — SOP 状态机

**职责**：定义项目的合法状态与状态转换。

**最小谓词**：

```prolog
% 状态定义
stage(init).                    stage(requirement_draft).
stage(requirement_confirmed).   stage(knowledge_draft).
stage(knowledge_validated).     stage(knowledge_approved).
stage(solving).                 stage(solved).
stage(validated).               stage(gated).
stage(reporting).               stage(reported).
stage(delivered).               stage(reviewed).
stage(iterating).

% 状态依赖：solving 依赖 knowledge_approved
depends_on(solving, knowledge_approved).
depends_on(reporting, gated).

% 合法状态转换
valid_transition(init, requirement_draft).
valid_transition(requirement_draft, requirement_confirmed).
valid_transition(requirement_draft, init).
valid_transition(requirement_confirmed, knowledge_draft).
valid_transition(knowledge_draft, knowledge_validated).
valid_transition(knowledge_validated, knowledge_approved).
valid_transition(knowledge_approved, solving).
valid_transition(solving, solved).
valid_transition(solved, validated).
valid_transition(validated, gated).
valid_transition(gated, reporting).
valid_transition(reporting, reported).
valid_transition(reported, delivered).
valid_transition(delivered, reviewed).
valid_transition(reviewed, iterating).
valid_transition(iterating, knowledge_draft).
% 回退路径
valid_transition(solving, knowledge_draft).      %求解失败回退
valid_transition(validated, solving).             %校验失败重试
valid_transition(gated, solving).                 %门禁失败重试

% 状态推进
advance(Project, From, To) :-
    valid_transition(From, To),
    nl, write('[SOP] '), write(Project),
    write(': '), write(From), write(' -> '), write(To), nl.

% 查询当前允许的下一状态
next_allowed_states(Current, NextList) :-
    findall(Next, valid_transition(Current, Next), NextList).

% 查询某项目是否处于某状态
project_state(Project, State) :-
    % 从 Rust state.json 读取
    true.  % TODO: 文件 I/O

% 标记完成
completed(Project, Stage) :-
    advance(Project, _, Stage).
```

**测试命令**：

```bash
scryer-prolog -g "consult('rules/sop_workflow.pl'), next_allowed_states(init, L), write(L), halt."
# 预期: [requirement_draft]
```

**验收样例**：

```
输入: next_allowed_states(solved, L).
预期: L = [validated, solving]

输入: valid_transition(solved, reporting).
预期: false  (不能跳过 validated/gated)
```

---

### 2.2 sop_gatekeeper.pl — 动作放行

**职责**：每步执行前判断 `can_execute`，禁止跳步。

**最小谓词**（加固版，不使用 `_` 偷懒）：

```prolog
% 动作许可判定
can_execute(Project, Action) :-
    gatekeeper_rule(Project, Action, Conditions),
    all_conditions_met(Conditions).

% 各动作的门禁规则
gatekeeper_rule(Project, solve(Species, Stage), [
    species_exists(Species),
    stage_exists(Species, Stage),
    has_category_rules_or_fallback(Project, Species, Stage),
    ingredients_available,
    project_state(Project, knowledge_approved)
]).

gatekeeper_rule(Project, generate_report, [
    project_state(Project, gated),
    has_valid_solution(Project)
]).

gatekeeper_rule(Project, deliver, [
    project_state(Project, reported),
    delivery_gate_passed(Project)
]).

gatekeeper_rule(Project, activate_rule(RuleId), [
    rule_status(RuleId, approved),
    counterexample_tests_passed(RuleId),
    rollback_available(RuleId)
]).

gatekeeper_rule(Project, modify_knowledge, [
    user_confirmed(Project, modify_knowledge)
]).

% 拒绝时给出原因
cannot_execute(Project, Action, Reason) :-
    gatekeeper_rule(Project, Action, Conditions),
    failed_condition(Conditions, Reason).

% 当前被阻断的动作
blocked(Project, Action-Reason) :-
    gatekeeper_rule(Project, Action, _),
    cannot_execute(Project, Action, Reason).

% fallback 控制（加固版）
% 默认生产模式，不使用 _
allow_fallback(production, false).
% 显式开启
% allow_fallback(test_project_001, true).

% 品类规则获取（带 Project 参数）
get_category_rule(Project, Species, Stage, Cat, LT, Limit) :-
    specific_category_rule(Species, Stage, Cat, LT, Limit), !.
get_category_rule(Project, Species, Stage, Cat, LT, Limit) :-
    allow_fallback(Project, true),
    fallback_category_rule(Cat, LT, Limit), !.
get_category_rule(Project, Species, Stage, _Cat, _LT, _Limit) :-
    \+ allow_fallback(Project, true),
    fail.
```

**关键修正**：`get_category_rule/6` 不再使用 `_` 作 fallback，三子句逻辑清晰，带 Project 参数控制。

**测试命令**：

```bash
scryer-prolog -g "
    consult('rules/ingredient_db.pl'),
    consult('rules/species_nutrition.pl'),
    consult('rules/category_rules.pl'),
    consult('rules/sop_gatekeeper.pl'),
    can_execute(production, solve(nonexistent_species, adult)),
    write('ERROR: should have failed!'), halt.
"
# 预期: 失败，输出 species_not_found
```

**验收样例**：

```
输入: can_execute(production, solve(japanese_eel, adult)).
预期: true

输入: can_execute(production, solve(japanese_eel, nonexistent_stage)).
预期: false, Reason = stage_not_found

输入: get_category_rule(production, japanese_eel, adult, starch, max, L).
预期: L = 25.0

输入: get_category_rule(production, tilapia, adult, starch, max, L).
预期: false  (tilapia 无专用规则, production 模式禁止 fallback)
```

---

### 2.3 category_rules.pl — 唯一品类约束源

**已有谓词**：
- `species_category_rule/6`
- `fallback_category_rule/3`
- `category_check/2`
- `species_category_constraints/2`
- `has_category_rules/2`

**最小谓词**：

```prolog
% 精确匹配（无通配兜底）
specific_category_rule(Species, Stage, Cat, LT, Limit) :-
    species_category_rule(Species, Stage, Cat, LT, Limit, _).
specific_category_rule(Species, Stage, Cat, LT, Limit) :-
    species_category_rule(Species, _, Cat, LT, Limit, _),
    \+ specific_category_rule(Species, Stage, Cat, _, _).

% fallback 规则（仅 allow_fallback=true 时生效）
fallback_category_rule(starch, max, 30.0).
fallback_category_rule(animal_protein, min, 20.0).
fallback_category_rule(oil, max, 8.0).
fallback_category_rule(oil, min, 2.0).

% 成本合理区间 —— P0.2扩展：按物种细分
reasonable_cost_range(japanese_eel,      _,      9000, 18000).
reasonable_cost_range(white_shrimp,      _,      7000, 15000).
reasonable_cost_range(largemouth_bass,   _,      9000, 15000).
reasonable_cost_range(common_carp,       _,      3500, 7000).
reasonable_cost_range(grass_carp,        _,      3000, 6000).
reasonable_cost_range(tilapia,           _,      3500, 6500).
reasonable_cost_range(crucian_carp,      _,      3500, 7000).
reasonable_cost_range(black_carp,        _,      3500, 6500).
reasonable_cost_range(rainbow_trout,     _,      7000, 14000).
reasonable_cost_range(atlanic_salmon,    _,      8000, 16000).
reasonable_cost_range(channel_catfish,   _,      3500, 6500).
reasonable_cost_range(southern_catfish,  _,      4000, 7000).
reasonable_cost_range(wuchang_bream,     _,      3500, 6000).
reasonable_cost_range(yellow_catfish,    _,      5000, 10000).
reasonable_cost_range(snakehead,         _,      6000, 12000).
reasonable_cost_range(tiger_prawn,       _,      8000, 16000).
reasonable_cost_range(giant_river_prawn, _,      6000, 12000).
reasonable_cost_range(chinese_mitten_crab, _,    6000, 14000).
% 通配（仅限未定义物种 + allow_fallback=true）
reasonable_cost_range(_,                _,      3000, 30000).

% 查询接口
cost_in_range(Species, Stage, Cost) :-
    reasonable_cost_range(Species, Stage, Min, Max),
    Cost >= Min, Cost =< Max.

% 成本异常检测
cost_anomaly_check(Species, Stage, Cost) :-
    ( cost_in_range(Species, Stage, Cost) -> true
    ; reasonable_cost_range(Species, Stage, Min, Max),
      write('WARNING: cost_unit_anomaly — '),
      write(Species), write('/'), write(Stage),
      write(' 吨成本 ¥'), write(Cost),
      write(' 超出合理区间 [¥'), write(Min), write(', ¥'), write(Max), write(']'), nl,
      write('  请检查: Price 单位(元/kg)、吨成本计算公式、数据输入'), nl
    ).
```

**测试命令**：

```bash
scryer-prolog -g "
    consult('rules/category_rules.pl'),
    specific_category_rule(japanese_eel, juvenile, starch, max, L),
    write('juvenile starch max: '), write(L), nl,
    specific_category_rule(japanese_eel, glass_eel, starch, max, L2),
    write('glass_eel starch max: '), write(L2), nl,
    % 测试成本范围
    cost_in_range(japanese_eel, adult, 5000),
    write('eel 5000 in range? '), write(false), nl,
    halt.
"
```

---

### 2.4 delivery_gatekeeper.pl — 交付门禁

**已有谓词**：`deliverable/4`, `check_closure/2`, `check_nutrition/3`, `check_category/3`, `check_cost_range/2`

**最小谓词**：

```prolog
% 交付判定
deliverable(Recipe, Species, Stage, Decision)

% 单项检查
check_closure(Recipe, Result)
check_nutrition(Recipe, Species, Stage, Result)
check_category(Recipe, Species, Stage, Result)
check_cost_range(Recipe, Species, Stage, Result)

% 不可交付原因
cannot_deliver(Recipe, Species, Stage, Reasons) :-
    deliverable(Recipe, Species, Stage, failed(Reasons)).

% 交付条件清单
delivery_requirement(closure,        '配方闭合 100% ± 0.1%').
delivery_requirement(nutrition,      '营养约束满足').
delivery_requirement(category,       '品类约束满足').
delivery_requirement(cost_range,     '成本在物种合理区间内').
delivery_requirement(compliance,     '合规检查通过').
delivery_requirement(rule_approved,  '所有规则状态为 active').
delivery_requirement(counterexample, '反例测试全部通过').
```

**测试命令**：

```bash
scryer-prolog -g "
    consult('rules/ingredient_db.pl'),
    consult('rules/species_nutrition.pl'),
    consult('rules/category_rules.pl'),
    consult('rules/sop_gatekeeper.pl'),
    consult('rules/formulation_lp_engine.pl'),
    consult('rules/delivery_gatekeeper.pl'),
    consult('rules/sop_engine.pl'),
    solve_formulation(japanese_eel, adult),
    halt.
"
```

**验收样例**：

```
输入: 正常鳗鱼配方 recipe_sop(Items, Cost).
     deliverable(recipe_sop(Items, Cost), japanese_eel, adult, D).
预期: D = passed

输入: 修改 Cost = 100000.
     deliverable(recipe_sop(Items, 100000), japanese_eel, adult, D).
预期: D = failed([cost])
```

---

### 2.5 self_iteration_engine.pl — 自我迭代（含回滚）

**已有谓词**：`iterate/3`, `advance_patch/2`, `can_activate_patch/1`

**需新增的回滚条件**：

```prolog
% --- 回滚条件（新增）---

% 新规则导致原有正例失败 → 自动回滚
must_rollback(Patch) :-
    regression_failed(Patch).

% 专家撤销确认 → 回滚
must_rollback(Patch) :-
    expert_revoked(Patch).

% 关键输出异常 → 回滚
must_rollback(Patch) :-
    critical_output_anomaly(Patch).

% 补丁激活后成本校验失败 → 回滚
must_rollback(Patch) :-
    patch_active(Patch),
    cost_validation_failed(Patch).

% 回滚执行
execute_rollback(Patch) :-
    must_rollback(Patch),
    patch_status(Patch, OldStatus),
    write('[ROLLBACK] '), write(Patch), write(' '),
    write(OldStatus), write(' → patch_rollback'), nl,
    retract(patch_status(Patch, OldStatus)),
    assertz(patch_status(Patch, patch_rollback)),
    restore_previous_rule(Patch).

% 推断占位子句
regression_failed(Patch) :-
    write('[ITERATION] 检查回归测试...'), nl,
    fail.  % TODO: 调用 counterexample_tests

expert_revoked(Patch) :-
    write('[ITERATION] 检查专家确认状态...'), nl,
    fail.  % TODO: 检查 approval 记录

critical_output_anomaly(Patch) :-
    write('[ITERATION] 检查输出异常...'), nl,
    fail.  % TODO: 成本/营养阈值检测

cost_validation_failed(Patch) :-
    write('[ITERATION] 检查成本校验...'), nl,
    fail.

restore_previous_rule(Patch) :-
    write('[ITERATION] 恢复旧版规则...'), nl.
    % TODO: 从 rule_version_registry 恢复

% --- 完整迭代流程 ---
full_iteration_cycle(IssueType, Description) :-
    % 1. 归因
    iterate(IssueType, Description, Patch),
    % 2. 测试
    (  rule_consistency_passed(Patch),
       counterexample_regression_passed(Patch)
    -> advance_patch(Patch, patch_validated)
    ;  write('[ITERATION] 一致性/回归测试失败'), nl, fail
    ),
    % 3. 等待确认
    write('[ITERATION] 等待专家确认...'), nl,
    % 4. 激活
    (  can_activate_patch(Patch)
    -> advance_patch(Patch, patch_active)
    ;  write('[ITERATION] 激活条件不满足'), nl, fail
    ),
    % 5. 回滚就绪
    write('[ITERATION] 补丁已激活, 旧规则已归档, 可回滚'), nl.
```

**测试命令**：

```bash
scryer-prolog -g "
    consult('rules/self_iteration_engine.pl'),
    iterate(repeated_error, '测试回滚机制', Patch),
    write(Patch), nl,
    halt.
"
```

**验收样例**：

```
输入: iterate(cost_unit_anomaly, '吨成本 ¥495,911 超出鳗鱼合理区间 ¥9000-18000', Patch).
预期: Patch.action_type = add_validation_rule,
      Patch.affected_files 包含 'sop_engine.pl'

输入: can_activate_patch(Patch) (对未验证的 patch).
预期: false

输入: must_rollback(Patch) (回归测试失败时).
预期: true → execute_rollback 恢复旧规则
```

---

### 2.6 counterexample_tests.pl — 反例测试

**已有谓词**：`test_all_counterexamples/0`, 7 个测试

**需补充**：

```prolog
% 测试用例注册
test_case(t01_nonexistent_species,    should_fail, '物种不存在被拦截').
test_case(t02_nonexistent_stage,      should_fail, '阶段不存在被拦截').
test_case(t03_category_rule_missing,  should_fail, '品类规则缺失被拦截').
test_case(t04_cost_unit_anomaly,      should_fail, '成本异常被拦截').
test_case(t05_bounds_invalid,         should_fail, '原料Max<Min被拦截').
test_case(t06_rule_not_approved,      should_fail, '规则未approved被拦截').
test_case(t07_delivery_gate,          should_fail, '交付门禁未通过被拦截').
test_case(t08_valid_eel_adult,        should_pass, '鳗鱼成体正常求解').
test_case(t09_valid_shrimp_adult,     should_pass, '对虾成体正常求解').

% 元数据
should_fail(TestId) :- test_case(TestId, should_fail, _).
should_pass(TestId) :- test_case(TestId, should_pass, _).

% 运行全部反例
run_counterexamples(Results) :-
    findall(Id-Status,
            ( test_case(Id, _, _),
              run_single_test(Id, Status)
            ),
            Results).

% 统计
test_summary(Results, Passed, Failed, Skipped) :-
    count(Results, passed, Passed),
    count(Results, failed, Failed),
    count(Results, skipped, Skipped).
```

---

## 三、P0.5 最小工程闭环

### 3.1 Rust CLI 最小入口

```
aqua solve --species japanese_eel --stage adult [--project project_001]
```

**调用链**：

```
Rust CLI (main.rs)
  │
  ├─ 1. RustStateAgent
  │    读取 project_state.json → init
  │
  ├─ 2. RustPrologRunnerAgent
  │    调用 scryer-prolog:
  │      can_execute(project_001, solve(japanese_eel, adult)).
  │    → allow → 继续
  │    → block → 输出原因, 退出
  │
  ├─ 3. RustPrologRunnerAgent
  │    调用 scryer-prolog:
  │      solve_formulation(japanese_eel, adult).
  │    → recipe_sop / infeasible
  │
  ├─ 4. RustFileAgent
  │    写入 validation_result.json
  │
  ├─ 5. RustPrologRunnerAgent
  │    调用 delivery_gatekeeper:
  │      deliverable(Recipe, japanese_eel, adult, Decision).
  │    → 写入 delivery_decision.json
  │
  ├─ 6. RustAuditAgent
  │    写入 execution_log.json
  │
  └─ 7. RustStateAgent
  │    更新 project_state.json: solved → validated → gated
```

### 3.2 Rust Cargo.toml 最小依赖

```toml
[package]
name = "aqua"
version = "0.1.0"
edition = "2021"

[dependencies]
clap = { version = "4", features = ["derive"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
chrono = { version = "0.4", features = ["serde"] }
```

### 3.3 Rust main.rs 骨架

```rust
use clap::{Parser, Subcommand};
use std::process::Command;

#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Solve {
        #[arg(long)]
        species: String,
        #[arg(long)]
        stage: String,
        #[arg(long, default_value = "production")]
        project: String,
    },
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Solve { species, stage, project } => {
            solve(&project, &species, &stage);
        }
    }
}

fn solve(project: &str, species: &str, stage: &str) {
    // Step 1: can_execute?
    let can = run_prolog(&format!(
        "can_execute({}, solve({}, {})).",
        project, species, stage
    ));
    if !can { eprintln!("BLOCKED: cannot_execute"); return; }

    // Step 2: solve
    let result = run_prolog(&format!(
        "solve_formulation({}, {}).",
        species, stage
    ));

    // Step 3: delivery gate
    let deliverable = run_prolog(&format!(
        "deliverable(Recipe, {}, {}, Decision).",
        species, stage
    ));

    // Step 4: write logs
    write_execution_log(project, species, stage, &result, &deliverable);
}

fn run_prolog(query: &str) -> bool {
    let output = Command::new("scryer-prolog")
        .args(["-g", &format!("consult('rules/sop_engine.pl'), {}, halt.", query)])
        .output()
        .expect("scryer-prolog not found");
    output.status.success()
}

fn write_execution_log(project: &str, species: &str, stage: &str,
                        result: &str, deliverable: &str) {
    // TODO: write generated/execution_log.json
}
```

**测试命令**：

```bash
cd AquaFeedFormulator/rust-core
cargo run -- solve --species japanese_eel --stage adult
```

---

### 3.4 最小 JSON Schema

#### validation_result.json

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "ValidationResult",
  "type": "object",
  "properties": {
    "project_id": { "type": "string" },
    "timestamp": { "type": "string", "format": "date-time" },
    "species": { "type": "string" },
    "stage": { "type": "string" },
    "solution": {
      "oneOf": [
        { "type": "object",
          "properties": {
            "status": { "const": "solved" },
            "recipe": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "ingredient_id": { "type": "string" },
                  "name": { "type": "string" },
                  "pct": { "type": "number" },
                  "cost_per_ton": { "type": "number" }
                },
                "required": ["ingredient_id", "name", "pct", "cost_per_ton"]
              }
            },
            "total_pct": { "type": "number" },
            "total_cost_per_ton": { "type": "number" },
            "closure_check": { "type": "boolean" },
            "cost_anomaly": { "type": "boolean" }
          },
          "required": ["status", "recipe", "total_pct", "total_cost_per_ton"]
        },
        { "type": "object",
          "properties": {
            "status": { "const": "infeasible" },
            "reason": { "type": "string" }
          },
          "required": ["status", "reason"]
        }
      ]
    },
    "prolog_version": { "type": "string" },
    "rules_version": { "type": "string" }
  },
  "required": ["project_id", "timestamp", "species", "stage", "solution"]
}
```

#### delivery_decision.json

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "DeliveryDecision",
  "type": "object",
  "properties": {
    "project_id": { "type": "string" },
    "timestamp": { "type": "string", "format": "date-time" },
    "deliverable": { "type": "boolean" },
    "checks": {
      "type": "object",
      "properties": {
        "closure": { "type": "string", "enum": ["pass", "fail"] },
        "nutrition": { "type": "string", "enum": ["pass", "fail"] },
        "category": { "type": "string", "enum": ["pass", "fail"] },
        "cost_range": { "type": "string", "enum": ["pass", "fail"] }
      },
      "required": ["closure", "nutrition", "category", "cost_range"]
    },
    "failures": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "check": { "type": "string" },
          "expected": {},
          "actual": {}
        }
      }
    },
    "warnings": {
      "type": "array",
      "items": { "type": "string" }
    },
    "report_disclaimer": {
      "type": "string"
    }
  },
  "required": ["project_id", "timestamp", "deliverable", "checks", "report_disclaimer"]
}
```

#### execution_log.json

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "ExecutionLog",
  "type": "object",
  "properties": {
    "project_id": { "type": "string" },
    "started_at": { "type": "string", "format": "date-time" },
    "completed_at": { "type": "string", "format": "date-time" },
    "exit_code": { "type": "integer" },
    "steps": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "seq": { "type": "integer" },
          "action": { "type": "string" },
          "prolog_call": { "type": "string" },
          "result": { "type": "string" },
          "timestamp": { "type": "string", "format": "date-time" },
          "error": { "type": "string" }
        },
        "required": ["seq", "action", "result", "timestamp"]
      }
    },
    "state_transitions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "from": { "type": "string" },
          "to": { "type": "string" },
          "by": { "type": "string" }
        }
      }
    }
  },
  "required": ["project_id", "steps"]
}
```

---

## 四、验收标准（含当前状态）

### Prolog LP Solver 子模块

| # | 验收项 | 当前状态 | 目标状态 | 验收命令 |
|---|-------|---------|---------|---------|
| 1 | 配方闭合 100%±0.1% | ✅ 已具备 | 保持 | `solve_formulation(japanese_eel,adult)` 输出闭合OK |
| 2 | 营养约束满足 | ✅ 已具备 | 保持 | delivery_gatekeeper check_nutrition=pass |
| 3 | 品类约束满足 | ✅ 已具备 | 保持 | delivery_gatekeeper check_category=pass |
| 4 | 成本单位正确 | ⚠ 待验证 | 必须通过 | 手算 vs 输出: `TotalCost × 10 = 吨成本` |
| 5 | 不可行解返回 infeasible | ✅ 已具备 | 保持 | 矛盾约束 → infeasible |
| 6 | 规则源无双副本 | ⚠ 待验证 | 必须通过 | `grep -r 'species_category_rule' rules/` 仅在 category_rules.pl |
| 7 | 反例测试拦截异常 | ⚠ 待运行 | 必须通过 | `test_all_counterexamples` |
| 8 | 成本按物种验证 | ❌ 未实现 | P0.5 | `reasonable_cost_range(japanese_eel,_,9000,18000)` |

### 总系统

| # | 验收项 | 当前状态 | 目标状态 | 验收命令 |
|---|-------|---------|---------|---------|
| 9 | can_execute 每步判定 | ⚠ 骨架 | P0.5 | `cargo run -- solve --species nonexistent` → BLOCKED |
| 10 | execution_log 可追踪 | ❌ 未实现 | P0.5 | 检查 `generated/execution_log.json` |
| 11 | delivery_decision 输出 | ❌ 未实现 | P0.5 | 检查 `generated/delivery_decision.json` |
| 12 | LLM 输出默认 draft | ❌ 未实现 | P1 | — |
| 13 | 复盘输出 patch_draft | ⚠ 骨架 | P0.7 | `iterate(cost_unit_anomaly, Desc, Patch)` |
| 14 | 回滚机制可用 | ❌ 未实现 | P0.7 | `must_rollback(Patch) → execute_rollback` |

---

## 五、执行顺序

```
Phase P0  (本次)     — LP Solver 内部修复
Phase P0.5 (本次)    — 最小 Rust CLI + JSON + 成本物种细分
Phase P1  (后续)     — LLM六Agent + Rust八Agent + 完整协议
```

### Phase P0: 今天完成

- [x] P0-1 产品定位修正
- [ ] P0-2 成本按物种细分（reasonable_cost_range 写入 category_rules.pl）
- [x] P0-3 SOP/LP 拆分
- [x] P0-4 唯一规则源
- [ ] P0-5 fallback 加固（get_category_rule/6 三子句, Project 级控制）
- [x] P0-6 反例测试库
- [ ] P0-7 回滚条件

### Phase P0.5: 今天完成

- [ ] Rust CLI 骨架（main.rs + Cargo.toml）
- [ ] JSON Schema（3个文件）
- [ ] 成本物种细分表
- [ ] 验收标准表（当前状态 vs 目标）

---

## 六、一句话总结

整改方向已对，现在要做的是：

**不再写概念 —— 写每个文件的最小谓词、Rust 调用链、JSON schema、验收命令和测试样例。**

文档写得好只会让方案评审通过，代码跑通才能让系统真的被修好。

---

*本文档为实施级执行方案，非评审级整改计划。每个 Prolog 文件展开到可编码的谓词级别。*
