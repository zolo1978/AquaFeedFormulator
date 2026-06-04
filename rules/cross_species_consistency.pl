% ============================================================
% cross_species_consistency.pl — 跨文件物种命名一致性冒烟测试
% v2 — 简化版, 避免自定义 sort/unique 引入的 bug
% ============================================================

% ==== 交叉一致性: nutrition vs validators ====
run_consistency_test :-
    write('=== 物种命名一致性冒烟 ==='), nl,

    % 从 species_nutrition.pl 提取
    findall(S, species_nutrition(S, _, _, _, _, _), NutRaw),

    % 从 formula_closure_validator.pl 提取
    findall(S, species_category_rule(S, _, _, _, _, _), CloRaw),

    % 从 functional_additive_checker.pl 提取
    findall(S, species_functional_requirement(S, _, _, _), FunRaw),

    % 检查关键物种是否在三者中都出现
    write('--- 关键物种覆盖检查 ---'), nl,
    check_species('japanese_eel', NutRaw, CloRaw, FunRaw),
    check_species('white_shrimp', NutRaw, CloRaw, FunRaw),
    nl,

    % 统计覆盖率
    write('--- 覆盖率统计 ---'), nl,
    count_distinct(NutRaw, NutCount, NutSet),
    count_distinct(CloRaw, CloCount, CloSet),
    count_distinct(FunRaw, FunCount, FunSet),
    write('species_nutrition: '), write(NutCount), write(' 物种'), nl,
    write('closure_validator: '), write(CloCount), write(' 物种'), nl,
    write('func_checker     : '), write(FunCount), write(' 物种'), nl, nl,

    % nutrition 中有但 validator 中没有的
    write('--- Nutrition 独有 (无品类/功能规则) ---'), nl,
    list_not_in(NutSet, CloSet, NoClosure),
    list_not_in(NutSet, FunSet, NoFunc),
    ( NoClosure = [] -> write('品类规则: 全覆盖'), nl ; (write('缺品类: '), write(NoClosure), nl) ),
    ( NoFunc    = [] -> write('功能规则: 全覆盖'), nl ; (write('缺功能: '), write(NoFunc), nl) ),
    nl,

    % 判定: 关键物种 (japanese_eel, white_shrimp) 必须全覆盖
    %        其余物种使用通用水产 fallback, 属正常行为
    ( member(japanese_eel, NoClosure) -> write('FAIL: japanese_eel 无品类规则!'), nl
    ; member(japanese_eel, NoFunc)    -> write('FAIL: japanese_eel 无功能规则!'), nl
    ; member(white_shrimp, NoClosure) -> write('FAIL: white_shrimp 无品类规则!'), nl
    ; member(white_shrimp, NoFunc)    -> write('FAIL: white_shrimp 无功能规则!'), nl
    ; len_simple(NoClosure, N),
      write('PASS (关键物种全覆盖, 其余 '), write(N),
      write(' 种使用通用 fallback)'), nl
    ).

% ==========================================
% 辅助: 简化版集合操作
% ==========================================

% member/2
member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

% 去重计数 (用累积器)
count_distinct(Raw, Count, Set) :-
    dedup(Raw, [], Set),
    len_simple(Set, Count).

dedup([], Acc, Acc).
dedup([H|T], Acc, Set) :-
    member(H, Acc),
    !,
    dedup(T, Acc, Set).
dedup([H|T], Acc, Set) :-
    dedup(T, [H|Acc], Set).

len_simple([], 0).
len_simple([_|T], N) :- len_simple(T, N0), N is N0 + 1.

% A 不在 B 中的元素
list_not_in([], _, []).
list_not_in([H|T], B, [H|R]) :-
    \+ member(H, B),
    !,
    list_not_in(T, B, R).
list_not_in([_|T], B, R) :-
    list_not_in(T, B, R).

% 检查单个物种是否在三个列表中都存在
check_species(Sp, Nut, Clo, Func) :-
    (member(Sp, Nut)  -> N=ok ; N=missing),
    (member(Sp, Clo)  -> C=ok ; C=missing),
    (member(Sp, Func) -> F=ok ; F=missing),
    ( N=ok, C=ok, F=ok ->
        write('  '), write(Sp), write(': OK'), nl
    ;
        write('  '), write(Sp), write(': FAIL '), write([N,C,F]), nl
    ).

% ==========================================
% 一键入口
% ==========================================
run_smoke :- run_consistency_test.
