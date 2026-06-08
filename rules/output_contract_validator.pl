% ═══════════════════════════════════════════════════════════════
% output_contract_validator.pl — Prolog 输出协议校验器 v1.1
% AquaFeedFormulator Phase 0
%
% 校验任意 Prolog 模块输出的 output/5 结构是否符合统一协议。
% 注意: 使用 compound term 保证 scryer-prolog 兼容。
%
% 统一协议: output(Data, Warnings, Errors, Confidence, NextActions)
%   Data        — 模块专属 compound term（如 alerts(...), warnings(...)）
%   Warnings    — 原子列表
%   Errors      — 原子列表
%   Confidence  — 0.0 到 1.0 之间
%   NextActions — 原子列表
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 顶层校验
% ═══════════════════════════════════════════════════════════════

validate_output(Output, Passed, Issues) :-
    findall(Issue, output_issue(Output, Issue), Issues),
    ( Issues = [] -> Passed = true ; Passed = false ).

validate_output_or_halt(Output) :-
    validate_output(Output, Passed, Issues),
    ( Passed = true ->
        write('[OK] Output contract validated.'), nl
    ; maplist_issues(Issues),
        nl,
        write('[FAIL] Output contract validation FAILED.'), nl,
        halt(1)
    ).

% ═══════════════════════════════════════════════════════════════
% 校验规则 — 全部基于 compound term
% ═══════════════════════════════════════════════════════════════

% 必须是 output/5 term
output_issue(Output, 'NOT_AN_OUTPUT_TERM') :-
    \+ (Output = output(_, _, _, _, _)).

% Data 不能是未绑定变量
output_issue(Output, 'MISSING_DATA') :-
    Output = output(Data, _, _, _, _),
    var(Data).

% Warnings 必须是列表
output_issue(Output, 'WARNINGS_NOT_LIST') :-
    Output = output(_, Warnings, _, _, _),
    \+ is_list_check(Warnings).

% Errors 必须是列表
output_issue(Output, 'ERRORS_NOT_LIST') :-
    Output = output(_, _, Errors, _, _),
    \+ is_list_check(Errors).

% Confidence 必须是 0.0-1.0 之间的数字
output_issue(Output, 'CONFIDENCE_OUT_OF_RANGE') :-
    Output = output(_, _, _, C, _),
    ( var(C) ; C < 0.0 ; C > 1.0 ).

% NextActions 必须是列表
output_issue(Output, 'NEXT_ACTIONS_NOT_LIST') :-
    Output = output(_, _, _, _, Next),
    \+ is_list_check(Next).

% ═══════════════════════════════════════════════════════════════
% 工具
% ═══════════════════════════════════════════════════════════════

is_list_check([]).
is_list_check([_|_]).

write_issue(Issue) :-
    write('  ['), write(Issue), write(']'), nl.

maplist_issues([]).
maplist_issues([H|T]) :-
    write_issue(H),
    maplist_issues(T).

memberchk(X, [X|_]) :- !.
memberchk(X, [_|T]) :- memberchk(X, T).

validate_module_output(ModuleName, Output) :-
    validate_output(Output, Passed, Issues),
    ( Passed = true ->
        write('[PASS] '), write(ModuleName), write(' — output contract valid'), nl
    ; write('[FAIL] '), write(ModuleName), write(' — output contract INVALID'), nl,
      maplist_issues(Issues)
    ).

% ═══════════════════════════════════════════════════════════════
% 测试
% ═══════════════════════════════════════════════════════════════

test_all :-
    write('=== output_contract_validator ==='), nl,
    test_valid_output,
    test_invalid_outputs,
    nl.

test_valid_output :-
    write('--- valid output ---'), nl,
    Valid = output(alerts([], summary(0,0,0,0,0)), [], [], 0.9, []),
    validate_output(Valid, Passed, Issues),
    ( Passed = true ->
        write('[PASS] valid output accepted'), nl
    ; write('[FAIL] valid output rejected: '), write(Issues), nl
    ).

test_invalid_outputs :-
    write('--- invalid outputs ---'), nl,

    % 不是 output/5
    validate_output(foo(1,2), _, I1),
    ( memberchk('NOT_AN_OUTPUT_TERM', I1) ->
        write('[PASS] detected non-output term'), nl
    ; write('[FAIL] missed non-output term'), nl
    ),

    % confidence 越界
    BadConf = output(data, [], [], 1.5, []),
    validate_output(BadConf, _, I2),
    ( memberchk('CONFIDENCE_OUT_OF_RANGE', I2) ->
        write('[PASS] detected confidence out of range'), nl
    ; write('[FAIL] missed confidence range'), nl
    ),

    % warnings 不是列表
    BadWarn = output(data, not_a_list, [], 0.5, []),
    validate_output(BadWarn, _, I3),
    ( memberchk('WARNINGS_NOT_LIST', I3) ->
        write('[PASS] detected warnings not list'), nl
    ; write('[FAIL] missed warnings type'), nl
    ).
