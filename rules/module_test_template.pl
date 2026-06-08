% ═══════════════════════════════════════════════════════════════
% module_test_template.pl — Prolog 模块测试模板 v1.0
% AquaFeedFormulator Phase 0 治理基础
%
% 每个新增 Prolog 模块必须实现本模板中的测试谓词。
% 测试约定：
%   - 所有 should_pass 测试必须全部通过
%   - 所有 should_fail 测试必须返回预期失败
%   - 确定性测试：相同输入两次必须给出相同输出
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 测试框架基础工具
% ═══════════════════════════════════════════════════════════════

% assert_pass(+Description, +Goal)
% 断言 Goal 成功，打印结果
assert_pass(Desc, Goal) :-
    ( Goal ->
        write('[PASS] '), write(Desc), nl
    ; write('[FAIL] '), write(Desc), write(' — expected success, got failure'), nl
    ).

% assert_fail(+Description, +Goal)
% 断言 Goal 失败，打印结果
assert_fail(Desc, Goal) :-
    ( \+ Goal ->
        write('[PASS] '), write(Desc), nl
    ; write('[FAIL] '), write(Desc), write(' — expected failure, got success'), nl
    ).

% assert_equal(+Description, +Expected, +Actual)
assert_equal(Desc, Expected, Actual) :-
    ( Expected == Actual ->
        write('[PASS] '), write(Desc), nl
    ; write('[FAIL] '), write(Desc),
      write(' — expected: '), write(Expected),
      write(', got: '), write(Actual), nl
    ).

% ═══════════════════════════════════════════════════════════════
% 必选测试谓词 — 每个模块必须实现
% ═══════════════════════════════════════════════════════════════

% test_output_structure
%   验证模块 output/2 返回结构完整（含 data/warnings/errors/confidence）
%   各模块自行实现

% test_should_pass
%   正常场景 → 必须返回 passed
%   各模块自行实现

% test_should_fail
%   异常场景 → 必须返回 failed + 明确的 errors
%   各模块自行实现

% test_determinism
%   相同输入两次 → 相同输出
%   各模块自行实现

% test_all — 运行全部测试
%   各模块自行实现，按顺序调用上述测试

% ═══════════════════════════════════════════════════════════════
% 通用测试工具
% ═══════════════════════════════════════════════════════════════

% validate_output_structure(+Output)
% 验证输出结构符合 output_contract
validate_output_structure(Output) :-
    % Output 必须是 output{data:_, warnings:_, errors:_, confidence:_, next_actions:_}
    Output = output{data: _, warnings: _, errors: _, confidence: _, next_actions: _}.

% test_determinism_generic(+Desc, +Goal1, +Goal2)
% Goal1 和 Goal2 是同一个谓词的两次不同变量调用
test_determinism_generic(Desc, Goal1, Goal2) :-
    ( Goal1 == Goal2 ->
        write('[PASS] '), write(Desc), write(' — deterministic'), nl
    ; write('[FAIL] '), write(Desc), write(' — non-deterministic!'), nl
    ).

% test_determinism_strict(+Desc, +Goal)
% 严格确定性测试：findall 收集所有解，要求有且仅有一个解
test_determinism_strict(Desc, Goal) :-
    findall(Goal, Goal, Solutions),
    ( Solutions = [_, _|_] ->
        write('[FAIL] '), write(Desc),
        write(' — non-deterministic: multiple solutions'), nl
    ; Solutions = [_] ->
        write('[PASS] '), write(Desc), write(' — deterministic (exactly 1)'), nl
    ; write('[FAIL] '), write(Desc),
        write(' — no solutions found'), nl
    ).

% ═══════════════════════════════════════════════════════════════
% 示例：price_alert_rules 的反例测试模板
% ═══════════════════════════════════════════════════════════════

% --- test_should_pass: 正常价格 ---
test_alert_should_pass :-
    assert_pass('鱼粉涨8%不触发告警',
        price_alert(fish_meal_peru_65, 0.08, ok, _)).

% --- test_should_fail: 价格异常 ---
test_alert_should_fail_urgent :-
    assert_pass('鱼粉涨35%触发 urgent',
        price_alert(fish_meal_peru_65, 0.35, urgent, _)).

% --- test_determinism ---
test_alert_determinism :-
    price_alert(fish_meal_peru_65, 0.35, Level1, Action1),
    price_alert(fish_meal_peru_65, 0.35, Level2, Action2),
    test_determinism_generic('price_alert 确定性',
        Level1-Action1, Level2-Action2).

% --- test_all ---
test_all_price_alert :-
    write('═══ price_alert_rules 测试 ═══'), nl,
    test_alert_should_pass,
    test_alert_should_fail_urgent,
    test_alert_determinism,
    nl.

% ═══════════════════════════════════════════════════════════════
% 验收命令
% ═══════════════════════════════════════════════════════════════
%
%   scryer-prolog -g "consult('rules/module_test_template')" -g "test_all_price_alert" -g halt
%
% 预期输出:
%   ═══ price_alert_rules 测试 ═══
%   [PASS] 鱼粉涨8%不触发告警
%   [PASS] 鱼粉涨35%触发 urgent
%   [PASS] price_alert 确定性 — deterministic
%
% 新模块验收标准:
%   1. test_all 全部 PASS
%   2. 覆盖 should_pass + should_fail
%   3. 通过确定性测试
%   4. 通过 output_structure 验证
