% ═══════════════════════════════════════════════════════════════
% sop_gatekeeper.pl — SOP 门禁 v3.0
% AquaFeedFormulator 终审整改
%
% 职责：
%   1. can_execute/2 — 判定某动作是否允许执行
%   2. allow_fallback/2 — 控制是否允许品类约束 fallback
%   3. 物种/阶段存在性校验
%
% 核心原则：Rust 管状态，Prolog 管判断。
%   每次调用 Prolog 前，Rust 注入 project_state/2 fact。
%   Prolog 只做判定，不自己维护状态。
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% Fallback 控制
% ═══════════════════════════════════════════════════════════════

% 生产模式 — 绝对禁止 fallback
allow_fallback(production, false).

% 品类规则获取：三子句，带 Project 参数
%   Clause 1: 精确匹配 → 直接返回
%   Clause 2: allow_fallback=true → 使用兜底规则
%   Clause 3: allow_fallback=false → fail（生产模式阻断）
get_category_rule(Project, Species, Stage, Cat, LT, Limit) :-
    specific_category_rule(Species, Stage, Cat, LT, Limit), !.
get_category_rule(Project, Species, Stage, Cat, LT, Limit) :-
    allow_fallback(Project, true),
    fallback_category_rule(Cat, LT, Limit), !.
get_category_rule(Project, Species, Stage, _Cat, _LT, _Limit) :-
    allow_fallback(Project, false),
    write('ERROR: 无专用品类规则 — '),
    write(Species), write('/'), write(Stage), nl,
    write('  failed: species_category_rule_missing'), nl,
    write('  项目 '), write(Project), write(' 处于生产模式, 禁止静默 fallback'), nl,
    fail.

% ═══════════════════════════════════════════════════════════════
% 动作许可判定
% ═══════════════════════════════════════════════════════════════

% can_execute(+Project, +Action)
%
% Action 类型：
%   solve(Species, Stage)         — 执行配方求解
%   generate_report               — 生成报告
%   deliver                       — 交付配方
%   activate_rule(RuleId)         — 激活规则
%   modify_knowledge              — 修改知识库

% --- solve 许可 ---
% 生产模式必须通过全部校验
can_execute(Project, solve(Species, Stage)) :-
    species_exists(Species),
    stage_exists(Species, Stage),
    has_category_rules_or_fallback(Project, Species, Stage),
    ingredients_available.

% --- generate_report 许可 ---
can_execute(Project, generate_report) :-
    project_state(Project, State),
    (  State = solved ; State = validated ; State = gated ),
    has_valid_solution(Project).

% --- deliver 许可 ---
can_execute(Project, deliver) :-
    project_state(Project, State),
    (  State = gated ; State = validated ),
    has_valid_solution(Project),
    delivery_gate_passed(Project).

% --- activate_rule 许可 ---
can_execute(Project, activate_rule(RuleId)) :-
    project_state(Project, _),
    rule_status(RuleId, approved),
    counterexample_tests_passed(RuleId),
    rollback_available(RuleId).

% --- modify_knowledge 许可 ---
can_execute(Project, modify_knowledge) :-
    project_state(Project, State),
    State \= production,   % 生产模式下禁止直接修改知识库
    user_confirmed(Project, modify_knowledge).

% ═══════════════════════════════════════════════════════════════
% 校验子句
% ═══════════════════════════════════════════════════════════════

% 物种存在性校验 — 确切存在才通过
species_exists(Species) :-
    species_nutrition(Species, _, _, _, _, _), !.
species_exists(Species) :-
    write('ERROR: 未知物种 — '), write(Species), nl, fail.

% 阶段存在性校验 — 确切存在才通过
stage_exists(Species, Stage) :-
    species_nutrition(Species, Stage, _, _, _, _), !.
stage_exists(Species, Stage) :-
    write('ERROR: 物种 '), write(Species),
    write(' 无阶段 '), write(Stage), nl,
    write('  可用阶段: '),
    findall(S, species_nutrition(Species, S, _, _, _, _), Stages),
    write(Stages), nl, fail.

% 品类规则检查（含 fallback 控制）
has_category_rules_or_fallback(Project, Species, Stage) :-
    catch(get_category_rule(Project, Species, Stage, _, _, _), _, fail).

% 成本范围检查（按物种）
cost_in_range(Species, Stage, Cost) :-
    reasonable_cost_range(Species, Stage, Min, Max),
    Cost >= Min, Cost =< Max.

% 原料可用性
ingredients_available :-
    ingredient(_, _, _, _, _, _, _, _, _, _, _), !.
ingredients_available :-
    write('ERROR: 原料库为空'), nl, fail.

% ── 以下子句不再使用占位 TODO ──────────────────────────

% has_valid_solution: Rust injects has_solution/1 fact
has_valid_solution(Project) :-
    has_solution(Project), !.
has_valid_solution(Project) :-
    write('ERROR: 项目 '), write(Project), write(' 无有效求解结果'), nl, fail.

% delivery_gate_passed: Rust injects gate_passed/1 fact
delivery_gate_passed(Project) :-
    gate_passed(Project), !.
delivery_gate_passed(Project) :-
    write('ERROR: 项目 '), write(Project), write(' 交付门禁未通过'), nl, fail.

% rule_status: Rust injects rule_status/2 fact
rule_status(RuleId, Status) :-
    rule_status_fact(RuleId, Status), !.
rule_status(RuleId, _) :-
    write('ERROR: 规则 '), write(RuleId), write(' 状态未知'), nl, fail.

% counterexample_tests_passed: Rust injects tests_passed/1 fact
counterexample_tests_passed(RuleId) :-
    tests_passed(RuleId), !.
counterexample_tests_passed(RuleId) :-
    write('ERROR: 反例测试未通过: '), write(RuleId), nl, fail.

% rollback_available: Rust injects rollback_available/1 fact
rollback_available(RuleId) :-
    rollback_available_fact(RuleId), !.
rollback_available(RuleId) :-
    write('ERROR: 无可回滚版本: '), write(RuleId), nl, fail.

% user_confirmed: Rust injects user_confirmed/2 fact
user_confirmed(Project, Action) :-
    user_confirmed_fact(Project, Action), !.
user_confirmed(Project, Action) :-
    write('ERROR: 用户未确认 '), write(Action), write(' 于项目 '), write(Project), nl, fail.

% ═══════════════════════════════════════════════════════════════
% 成本异常检测 (P0-2+ 按物种细分)
% ═══════════════════════════════════════════════════════════════

cost_unit_anomaly(Species, Stage, CostPerTon) :-
    \+ cost_in_range(Species, Stage, CostPerTon),
    reasonable_cost_range(Species, Stage, Low, High),
    write('WARNING: cost_unit_anomaly — '),
    write(Species), write('/'), write(Stage),
    write(' 吨成本 ¥'), write(CostPerTon),
    write(' 超出合理区间 [¥'), write(Low), write(', ¥'), write(High), write(']'), nl,
    write('  请检查: Price 单位(元/kg)、吨成本计算公式、数据输入'), nl.
