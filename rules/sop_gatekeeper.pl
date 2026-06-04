% ═══════════════════════════════════════════════════════════════
% sop_gatekeeper.pl — SOP 门禁
% AquaFeedFormulator P0-3 / P0-5
%
% 职责：
%   1. can_execute/2 — 判定某动作是否允许执行
%   2. allow_fallback/2 — 控制是否允许品类约束 fallback
%   3. 物种/阶段存在性校验
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% Fallback 控制 (P0-5)
% ═══════════════════════════════════════════════════════════════

% 默认：生产模式，禁止 fallback
allow_fallback(_, false).

% 显式开启 fallback（测试/开发模式）
% allow_fallback(test_project, true).

% ═══════════════════════════════════════════════════════════════
% 动作许可判定
% ═══════════════════════════════════════════════════════════════

% can_execute(+Project, +Action) — 判定是否允许执行
%
% Action 类型：
%   solve(Species, Stage)         — 执行配方求解
%   generate_report               — 生成报告
%   deliver                       — 交付配方
%   activate_rule(RuleId)         — 激活规则
%   modify_knowledge              — 修改知识库

% --- solve 许可 ---
can_execute(Project, solve(Species, Stage)) :-
    species_exists(Species),
    stage_exists(Species, Stage),
    has_category_rules_or_fallback(Project, Species, Stage),
    ingredients_available.

% --- generate_report 许可 ---
can_execute(Project, generate_report) :-
    has_valid_solution(Project).

% --- deliver 许可 ---
can_execute(Project, deliver) :-
    has_valid_solution(Project),
    delivery_gate_passed(Project).

% --- activate_rule 许可 ---
can_execute(Project, activate_rule(RuleId)) :-
    rule_status(RuleId, approved),
    counterexample_tests_passed(RuleId),
    rollback_available(RuleId).

% --- modify_knowledge 许可 ---
can_execute(Project, modify_knowledge) :-
    user_confirmed(Project, modify_knowledge).

% ═══════════════════════════════════════════════════════════════
% 校验子句
% ═══════════════════════════════════════════════════════════════

% 物种存在性校验
species_exists(Species) :-
    species_nutrition(Species, _, _, _, _, _), !.
species_exists(Species) :-
    write('ERROR: 未知物种 — '), write(Species), nl, fail.

% 阶段存在性校验
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
    has_category_rules(Species, Stage), !.
has_category_rules_or_fallback(Project, Species, Stage) :-
    allow_fallback(Project, true), !.
has_category_rules_or_fallback(_, Species, Stage) :-
    write('ERROR: 无专用品类规则 — '),
    write(Species), write('/'), write(Stage), nl,
    write('  failed: species_category_rule_missing'), nl,
    write('  生产模式下禁止静默 fallback'), nl,
    fail.

% 原料可用性
ingredients_available :-
    ingredient(_, _, _, _, _, _, _, _, _, _, _), !.
ingredients_available :-
    write('ERROR: 原料库为空'), nl, fail.

% 占位子句（后续完善）
has_valid_solution(_) :- true.  % TODO: 检查执行日志
delivery_gate_passed(_) :- true.  % TODO: 检查交付门禁
rule_status(_, approved) :- true.  % TODO: 检查 rule_version_registry
counterexample_tests_passed(_) :- true.  % TODO: 调用 counterexample_tests
rollback_available(_) :- true.  % TODO: 检查旧版本是否可回滚
user_confirmed(_, _) :- true.  % TODO: 检查用户确认状态

% ═══════════════════════════════════════════════════════════════
% 成本异常检测 (P0-2)
% ═══════════════════════════════════════════════════════════════

% 合理成本区间：3,000 - 30,000 元/吨
reasonable_cost_range(3000, 30000).

cost_in_range(CostPerTon) :-
    reasonable_cost_range(Low, High),
    CostPerTon >= Low,
    CostPerTon =< High.

cost_unit_anomaly(CostPerTon) :-
    \+ cost_in_range(CostPerTon),
    reasonable_cost_range(Low, High),
    write('WARNING: cost_unit_anomaly — 吨成本 ¥'),
    write(CostPerTon),
    write(' 超出合理区间 [¥'), write(Low), write(', ¥'), write(High), write(']'), nl,
    write('  请检查: Price 单位(元/kg)、吨成本计算公式、数据输入'), nl.
