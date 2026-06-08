% ═══════════════════════════════════════════════════════════════
% recipe_planner.pl — M3 配方方案自动生成 v1.0.0
% AquaFeedFormulator Phase 2
%
% 职责：给定物种+阶段，按 strategy_profile 自动生成多套配方方案。
% 依赖：species_nutrition, category_rules, formulation_lp_engine, ingredient_db
%
% 输入: input(Species, Stage)
% 输出: output(Plans, Warnings, Errors, Confidence, NextActions)
%   Plans = [plan(Strategy, Status, Items, TotalCost, Profile)]
%   Items = [item(Id, Pct, Cost)]
%   Profile = profile(AnimalProteinMin, FishmealMin, RiskTolerance, CostWeight)
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% Strategy Profiles — 多维策略定义
% strategy_profile(Species, Stage, Strategy, Constraints)
% ═══════════════════════════════════════════════════════════════

% --- 日本鳗鲡 ---
strategy_profile(japanese_eel, adult, premium, [
    animal_protein_min(45),
    fishmeal_min(20),
    attractant_min_count(2),
    risk_tolerance(low),
    cost_weight(0.4)
]).
strategy_profile(japanese_eel, adult, balanced, [
    animal_protein_min(35),
    fishmeal_min(10),
    attractant_min_count(1),
    risk_tolerance(medium),
    cost_weight(0.7)
]).
strategy_profile(japanese_eel, adult, economic, [
    animal_protein_min(28),
    fishmeal_min(5),
    attractant_min_count(0),
    risk_tolerance(high),
    cost_weight(1.0)
]).

% --- 南美白对虾 ---
strategy_profile(white_shrimp, adult, premium, [
    animal_protein_min(35),
    fishmeal_min(15),
    attractant_min_count(2),
    risk_tolerance(low),
    cost_weight(0.4)
]).
strategy_profile(white_shrimp, adult, balanced, [
    animal_protein_min(28),
    fishmeal_min(8),
    attractant_min_count(1),
    risk_tolerance(medium),
    cost_weight(0.7)
]).
strategy_profile(white_shrimp, adult, economic, [
    animal_protein_min(22),
    fishmeal_min(3),
    attractant_min_count(0),
    risk_tolerance(high),
    cost_weight(1.0)
]).

% --- 鲤鱼 ---
strategy_profile(common_carp, adult, premium, [
    animal_protein_min(15),
    fishmeal_min(5),
    attractant_min_count(0),
    risk_tolerance(low),
    cost_weight(0.5)
]).
strategy_profile(common_carp, adult, balanced, [
    animal_protein_min(10),
    fishmeal_min(0),
    attractant_min_count(0),
    risk_tolerance(medium),
    cost_weight(0.8)
]).
strategy_profile(common_carp, adult, economic, [
    animal_protein_min(5),
    fishmeal_min(0),
    attractant_min_count(0),
    risk_tolerance(high),
    cost_weight(1.0)
]).

% --- 草鱼 ---
strategy_profile(grass_carp, adult, premium, [
    animal_protein_min(10),
    fishmeal_min(3),
    attractant_min_count(0),
    risk_tolerance(low),
    cost_weight(0.5)
]).
strategy_profile(grass_carp, adult, balanced, [
    animal_protein_min(6),
    fishmeal_min(0),
    attractant_min_count(0),
    risk_tolerance(medium),
    cost_weight(0.8)
]).
strategy_profile(grass_carp, adult, economic, [
    animal_protein_min(3),
    fishmeal_min(0),
    attractant_min_count(0),
    risk_tolerance(high),
    cost_weight(1.0)
]).

% --- 加州鲈 ---
strategy_profile(largemouth_bass, adult, premium, [
    animal_protein_min(42),
    fishmeal_min(18),
    attractant_min_count(2),
    risk_tolerance(low),
    cost_weight(0.4)
]).
strategy_profile(largemouth_bass, adult, balanced, [
    animal_protein_min(35),
    fishmeal_min(10),
    attractant_min_count(1),
    risk_tolerance(medium),
    cost_weight(0.7)
]).
strategy_profile(largemouth_bass, adult, economic, [
    animal_protein_min(28),
    fishmeal_min(5),
    attractant_min_count(0),
    risk_tolerance(high),
    cost_weight(1.0)
]).

% ═══════════════════════════════════════════════════════════════
% 顶层入口
% ═══════════════════════════════════════════════════════════════

output(Input, Output) :-
    Input = input(Species, Stage),

    % 物种/阶段校验
    (  valid_species_stage(Species, Stage) ->
        generate_recipe_plans(Species, Stage, Output)
    ;  Output = output([], [],
               [err(invalid_species_stage, Species, Stage)],
               0.0, [])
    ).

% ═══════════════════════════════════════════════════════════════
% 配方方案生成
% ═══════════════════════════════════════════════════════════════

generate_recipe_plans(Species, Stage, Output) :-

    % 获取营养需求
    species_nutrition(Species, Stage, TgtPro, TgtFat, MaxFib, MaxAsh),

    % 获取标准品类约束
    species_category_constraints(Species, Stage, StandardCats),

    % 遍历策略
    findall(plan(Strat, Status, Items, Cost, Profile),
            plan_for_strategy(Species, Stage, Strat,
                              TgtPro, TgtFat, MaxFib, MaxAsh,
                              StandardCats,
                              Status, Items, Cost, Profile),
            Plans),

    % 统计
    my_length(Plans, PlanCount),
    count_passed(Plans, PassedCount),
    Confidence is PassedCount / max(PlanCount, 1),

    % 收集警告
    findall(warn(W, Strat),
            ( member(plan(Strat, passed, Items, _, _), Plans),
              attractant_check(Strat, Items, W)
            ), Warnings),

    Output = output(Plans, Warnings, [], Confidence, []).

% ═══════════════════════════════════════════════════════════════
% 按策略生成配方
% ═══════════════════════════════════════════════════════════════

plan_for_strategy(Species, Stage, Strategy,
                  TgtPro, TgtFat, MaxFib, MaxAsh, StandardCats,
                  Status, Items, TotalCost, Profile) :-

    % 查询 strategy profile
    strategy_profile(Species, Stage, Strategy, ProfileRaw),

    % 提取策略约束
    extract_constraints(ProfileRaw, ApMin, FmMin, _, Risk, CW),
    Profile = profile(ApMin, FmMin, Risk, CW),

    % 合并约束：标准品类约束 + 策略覆写
    merge_constraints(StandardCats, ApMin, FmMin, MergedCats),

    % 调用 LP 求解（用 once 防止多解回溯）
    try_lp(TgtPro, TgtFat, MaxFib, MaxAsh, MergedCats,
           Status, Items, TotalCost).

% LP 求解包装 — once 确保单解
try_lp(TgtPro, TgtFat, MaxFib, MaxAsh, MergedCats,
       passed, Items, TotalCost) :-
    once(lp_solve(TgtPro, TgtFat, MaxFib, MaxAsh, MergedCats, Solution)),
    !,
    Solution = recipe_sop(LpItems, RawCost),
    TotalCost is RawCost / 10,
    normalize_items(LpItems, Items).
try_lp(_, _, _, _, _, infeasible, [], 0.0) :- !.

% ═══════════════════════════════════════════════════════════════
% 约束合并
% ═══════════════════════════════════════════════════════════════

merge_constraints(Standard, ApMin, FmMin, Merged) :-
    % 从标准约束中移除 animal_protein-min 和 fishmeal-min
    filter_out_overrides(Standard, Filtered),
    % 添加策略约束
    (  ApMin > 0 ->
        StrategyCats1 = [animal_protein-min-ApMin]
    ;  StrategyCats1 = []
    ),
    (  FmMin > 0 ->
        StrategyCats2 = [fishmeal-min-FmMin|StrategyCats1]
    ;  StrategyCats2 = StrategyCats1
    ),
    append(Filtered, StrategyCats2, Merged).

filter_out_overrides([], []).
filter_out_overrides([animal_protein-min-_|Rest], Filtered) :- !,
    filter_out_overrides(Rest, Filtered).
filter_out_overrides([fishmeal-min-_|Rest], Filtered) :- !,
    filter_out_overrides(Rest, Filtered).
filter_out_overrides([X|Rest], [X|Filtered]) :-
    filter_out_overrides(Rest, Filtered).

% ═══════════════════════════════════════════════════════════════
% 策略约束提取
% ═══════════════════════════════════════════════════════════════

extract_constraints([], 0, 0, 0, medium, 1.0).
extract_constraints([animal_protein_min(V)|Rest], V, Fm, Att, Risk, CW) :- !,
    extract_constraints(Rest, _, Fm, Att, Risk, CW).
extract_constraints([fishmeal_min(V)|Rest], Ap, V, Att, Risk, CW) :- !,
    extract_constraints(Rest, Ap, _, Att, Risk, CW).
extract_constraints([attractant_min_count(V)|Rest], Ap, Fm, V, Risk, CW) :- !,
    extract_constraints(Rest, Ap, Fm, _, Risk, CW).
extract_constraints([risk_tolerance(V)|Rest], Ap, Fm, Att, V, CW) :- !,
    extract_constraints(Rest, Ap, Fm, Att, _, CW).
extract_constraints([cost_weight(V)|Rest], Ap, Fm, Att, Risk, V) :- !,
    extract_constraints(Rest, Ap, Fm, Att, Risk, _).
extract_constraints([_|Rest], Ap, Fm, Att, Risk, CW) :-
    extract_constraints(Rest, Ap, Fm, Att, Risk, CW).

% ═══════════════════════════════════════════════════════════════
% 结果规整化
% ═══════════════════════════════════════════════════════════════

normalize_items(LpItems, Items) :-
    findall(item(Id, Pct, Cost),
            ( member(Id-Pct-Cost, LpItems), Pct > 0 ),
            Items).

% ═══════════════════════════════════════════════════════════════
% 后处理 — 诱食剂检查
% ═══════════════════════════════════════════════════════════════

attractant_ingredient(fish_oil).
attractant_ingredient(squid_liver_paste).
attractant_ingredient(betaine).

attractant_check(Strategy, Items, Warning) :-
    strategy_profile(Species, Stage, Strategy, ProfileRaw),
    extract_constraints(ProfileRaw, _, _, AttMin, _, _),
    AttMin > 0,
    findall(A, (member(item(A, Pct, _), Items),
                Pct > 0,
                attractant_ingredient(A)),
            Attractants),
    my_length(Attractants, AttCount),
    AttCount < AttMin,
    atom_concat(Strategy, '_', P1),
    atom_concat(P1, 'attractant_below_min', Code),
    Warning = warn(Code, AttCount, AttMin).

% ═══════════════════════════════════════════════════════════════
% 工具
% ═══════════════════════════════════════════════════════════════

count_passed([], 0).
count_passed([plan(_, passed, _, _, _)|Rest], N) :-
    count_passed(Rest, N1), N is N1 + 1.
count_passed([_|Rest], N) :-
    count_passed(Rest, N).

my_length([], 0).
my_length([_|T], N) :- my_length(T, N1), N is N1 + 1.

max(X, Y, X) :- X >= Y, !.
max(_, Y, Y).

% ═══════════════════════════════════════════════════════════════
% 自测试
% ═══════════════════════════════════════════════════════════════

test_all :-
    write('=== M3 recipe_planner ==='), nl,
    test_should_pass,
    test_invalid_species,
    test_determinism,
    test_output_structure,
    write('=== M3 done ==='), nl.

test_should_pass :-
    write('--- should_pass ---'), nl,

    % 日本鳗鲡成体 → 3 策略
    test_case(japanese_eel, adult, 3, 'japanese_eel_adult'),

    % 南美白对虾成体 → 3 策略
    test_case(white_shrimp, adult, 3, 'white_shrimp_adult'),

    % 鲤鱼成体 → 3 策略
    test_case(common_carp, adult, 3, 'common_carp_adult'),

    % 草鱼成体 → 3 策略
    test_case(grass_carp, adult, 3, 'grass_carp_adult'),

    % 加州鲈成体 → 3 策略
    test_case(largemouth_bass, adult, 3, 'largemouth_bass_adult'),

    nl.

test_case(Species, Stage, ExpectedCount, Label) :-
    output(input(Species, Stage), Out),
    Out = output(Plans, _, _, _, _),
    my_length(Plans, Count),
    (  Count =:= ExpectedCount ->
        write('[PASS] '), write(Label), write(' → '),
        write(Count), write(' plans'), nl,
        print_plan_summary(Plans)
    ;  write('[FAIL] '), write(Label), write(' expected '),
       write(ExpectedCount), write(' plans, got '), write(Count), nl
    ).

print_plan_summary([]).
print_plan_summary([plan(Strat, Status, _, Cost, _)|Rest]) :-
    write('       '), write(Strat), write(': '), write(Status),
    write(' @ ¥'), write(Cost), nl,
    print_plan_summary(Rest).

test_invalid_species :-
    write('--- invalid_species ---'), nl,
    output(input(nonexistent, adult), Out),
    Out = output([], _, [err(invalid_species_stage, _, _)], _, _),
    write('[PASS] invalid_species → graceful error'), nl, nl.

test_determinism :-
    write('--- determinism ---'), nl,
    output(input(japanese_eel, adult), Out1),
    output(input(japanese_eel, adult), Out2),
    (  Out1 = Out2 ->
        write('[PASS] determinism — identical outputs'), nl
    ;  write('[FAIL] determinism — outputs differ'), nl
    ), nl.

test_output_structure :-
    write('--- output_structure ---'), nl,
    output(input(japanese_eel, adult), Out),
    Out = output(Plans, Warnings, Errors, Confidence, NextActions),
    write('  plans='), my_length(Plans, PC), write(PC), nl,
    write('  warnings='), my_length(Warnings, WC), write(WC), nl,
    write('  errors='), my_length(Errors, EC), write(EC), nl,
    write('  confidence='), write(Confidence), nl,
    write('  next_actions='), my_length(NextActions, NC), write(NC), nl,
    write('[PASS] structure valid'), nl, nl.
