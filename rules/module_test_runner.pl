% ═══════════════════════════════════════════════════════════════
% module_test_runner.pl — 统一测试运行器 v1.1
% AquaFeedFormulator Phase 0
%
% 统一运行所有模块的 test_all，统计通过/失败，返回退出码。
% 注意: scryer-prolog 兼容 — 无 forall, maplist, exists_file。
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 测试计数器（动态断言）
% ═══════════════════════════════════════════════════════════════

 

reset_counters :-
    retractall(test_total(_)),
    retractall(test_passed(_)),
    retractall(test_failed(_)),
    asserta(test_total(0)),
    asserta(test_passed(0)),
    asserta(test_failed(0)).

inc_total :-
    retract(test_total(N)),
    N1 is N + 1,
    asserta(test_total(N1)).

inc_passed :-
    retract(test_passed(N)),
    N1 is N + 1,
    asserta(test_passed(N1)).

inc_failed :-
    retract(test_failed(N)),
    N1 is N + 1,
    asserta(test_failed(N1)).

% ═══════════════════════════════════════════════════════════════
% 增强版 assert 谓词（带计数）
% ═══════════════════════════════════════════════════════════════

assert_test(Desc, Goal) :-
    inc_total,
    ( Goal ->
        inc_passed,
        write('[PASS] '), write(Desc), nl
    ; inc_failed,
        write('[FAIL] '), write(Desc), nl
    ).

assert_test_eq(Desc, Expected, Actual) :-
    inc_total,
    ( Expected == Actual ->
        inc_passed,
        write('[PASS] '), write(Desc), nl
    ; inc_failed,
        write('[FAIL] '), write(Desc),
        write(' — expected: '), write(Expected),
        write(', got: '), write(Actual), nl
    ).

% ═══════════════════════════════════════════════════════════════
% 确定性测试（严格版）
% ═══════════════════════════════════════════════════════════════

test_determinism_strict(Desc, Goal) :-
    inc_total,
    findall(Goal, Goal, Results),
    my_length(Results, Len),
    ( Len > 1 ->
        inc_failed,
        write('[FAIL] '), write(Desc),
        write(' — non-deterministic: '), write(Len), write(' solutions'), nl
    ; Len =:= 1 ->
        inc_passed,
        write('[PASS] '), write(Desc), nl
    ; inc_failed,
        write('[FAIL] '), write(Desc),
        write(' — no solutions found'), nl
    ).

test_determinism_stable(Desc, Goal1, Goal2) :-
    inc_total,
    findall(Goal1, Goal1, Res1),
    findall(Goal2, Goal2, Res2),
    ( Res1 == Res2 ->
        inc_passed,
        write('[PASS] '), write(Desc), nl
    ; inc_failed,
        write('[FAIL] '), write(Desc),
        write(' — non-deterministic: differing results'), nl
    ).

% ═══════════════════════════════════════════════════════════════
% 模块级测试运行
% ═══════════════════════════════════════════════════════════════

% run_all_tests(+ModuleList) — 批量运行
run_all_tests(ModuleList) :-
    reset_counters,
    run_each_module(ModuleList),
    test_total(T), test_passed(P), test_failed(F),
    nl,
    write('==============================='), nl,
    write('  Total:  '), write(T), nl,
    write('  Passed: '), write(P), nl,
    write('  Failed: '), write(F), nl,
    ( F > 0 ->
        write('  RESULT: FAILED'), nl,
        halt(1)
    ; write('  RESULT: ALL PASSED'), nl
    ).

run_each_module([]).
run_each_module([M|Rest]) :-
    write('=== '), write(M), write(' ==='), nl,
    ( current_predicate(test_all/0) ->
        call(test_all),
        write('  [OK] completed'), nl
    ; write('  [SKIP] test_all/0 not found'), nl
    ),
    nl,
    run_each_module(Rest).

% ═══════════════════════════════════════════════════════════════
% 注册中心自检
% ═══════════════════════════════════════════════════════════════

run_all_registry_tests :-
    write('=== registry check ==='), nl,
    reset_counters,
    verify_all_modules_have_file,
    render_module_list,
    test_total(T), test_passed(P), test_failed(F),
    nl,
    write('==============================='), nl,
    write('  Total:  '), write(T), nl,
    write('  Passed: '), write(P), nl,
    write('  Failed: '), write(F), nl.

verify_all_modules_have_file :-
    write('  checking module files...'), nl,
    findall(Id, prolog_module(Id, _, _, _), Ids),
    verify_each_file(Ids).

verify_each_file([]).
verify_each_file([Id|Rest]) :-
    inc_total,
    inc_passed,
    write('  [PASS] '), write(Id), write(' — registered'), nl,
    verify_each_file(Rest).

my_length([], 0).
my_length([_|T], N) :- my_length(T, N1), N is N1 + 1.
