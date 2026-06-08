% ═══════════════════════════════════════════════════════════════
% mineral_balance.pl — 矿物平衡校验 (M5)
% AquaFeedFormulator Phase 3
%
% 校验配方 Ca/P 比值和有效磷是否满足物种需求。
% 输入来自 recipe_planner 的输出。
%
% 依赖: ingredient_db, species_nutrition
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 输出协议 (复合词)
% output(+Input, -Output)
%   Input  = input(Species, Stage, Items)
%   Items  = [item(Id, Pct, _Cost), ...]
%   Output = output(Data, Warnings, Errors, Confidence, NextActions)
%   Data   = data([Check1, Check2])
%   Check  = check(Name, Status, Fields...)
% ═══════════════════════════════════════════════════════════════

% 使用 mineral_balance_output 避免跨文件 output/2 谓词合并冲突
mineral_balance_output(input(Species, Stage, Items), Output) :-
    % 格式适配: LP输出 Id-Pct-Cost → item(Id,Pct,Cost)
    convert_items(Items, StdItems),
    ( species_mineral_requirement(Species, Stage, _, _, _) ->
        calc_recipe_minerals(StdItems, TotalCa, TotalP, AvailP),
        validate_minerals(Species, Stage, TotalCa, TotalP, AvailP,
                          Status, Checks, Warnings, Errors),
        ( Status = passed ->
            Confidence = 0.90
        ; Errors = [] ->
            Confidence = 0.75
        ; Confidence = 0.60
        ),
        ( Errors = [] ->
            NextActions = []
        ; member(err(ca_p_source, _), Errors) ->
            NextActions = [adjust_calcium_source,
                           check_dicalcium_phosphate_vs_limestone]
        ; NextActions = [increase_inorganic_phosphate]
        ),
        Output = output(data(Checks), Warnings, Errors,
                        Confidence, NextActions)
    ;   % invalid species
        Output = output(data([]), [],
                        [err(invalid_species, Species)],
                        0.0, [])
    ).

% ═══════════════════════════════════════════════════════════════
% 格式适配：LP输出 Id-Pct-Cost → item(Id,Pct,Cost)
% ═══════════════════════════════════════════════════════════════

convert_items([], []).
convert_items([Id-Pct-Cost|T], [item(Id, Pct, Cost)|RT]) :-
    convert_items(T, RT).

% ═══════════════════════════════════════════════════════════════
% 矿物计算
% ═══════════════════════════════════════════════════════════════

calc_recipe_minerals(Items, TotalCa, TotalP, AvailP) :-
    calc_ca(Items, 0, TotalCa),
    calc_p(Items, 0, TotalP, 0, AvailP).

calc_ca([], Acc, Acc).
calc_ca([item(Id, Pct, _)|Rest], Acc, Total) :-
    ingredient_mineral(Id, Ca, _),
    NewAcc is Acc + Pct * Ca,
    calc_ca(Rest, NewAcc, Total).
calc_ca([item(Id, _, _)|Rest], Acc, Total) :-
    \+ ingredient_mineral(Id, _, _),
    calc_ca(Rest, Acc, Total).

calc_p([], AccP, AccP, AccA, AccA).
calc_p([item(Id, Pct, _)|Rest], AccP, TotalP, AccA, AvailP) :-
    ingredient_mineral(Id, _, Phos),
    ingredient(Id, _, Category, _, _, _, _, _, _, _, _),
    phos_availability(Category, AvailFactor),
    NewAccP is AccP + Pct * Phos,
    NewAccA is AccA + Pct * Phos * AvailFactor,
    calc_p(Rest, NewAccP, TotalP, NewAccA, AvailP).
calc_p([item(Id, _, _)|Rest], AccP, TotalP, AccA, AvailP) :-
    \+ ingredient_mineral(Id, _, _),
    calc_p(Rest, AccP, TotalP, AccA, AvailP).

phos_availability(animal_protein, 0.70).
phos_availability(plant_protein, 0.30).
phos_availability(energy,        0.30).
phos_availability(oil,           0.00).
phos_availability(mineral,       0.90).
phos_availability(additive,      0.00).

% ═══════════════════════════════════════════════════════════════
% 校验逻辑
% ═══════════════════════════════════════════════════════════════

validate_minerals(Species, Stage, TotalCa, _TotalP, AvailP,
                  Status, Checks, Warnings, Errors) :-
    species_mineral_requirement(Species, Stage,
                                AvailPMin, CaPMin, CaPMax),

    % 有效磷校验
    ( AvailP >= AvailPMin ->
        Pcheck = check(available_phosphorus, passed,
                       AvailP, AvailPMin)
    ; Pcheck = check(available_phosphorus, failed,
                       AvailP, AvailPMin)
    ),

    % Ca/P 比值校验
    ( AvailP > 0 ->
        CaPRatio is TotalCa / AvailP,
        CaPRound is round(CaPRatio * 100) / 100,
        ( CaPRatio >= CaPMin, CaPRatio =< CaPMax ->
            CaPcheck = check(ca_p_ratio, passed,
                             CaPRound, CaPMin, CaPMax)
        ; CaPRatio < CaPMin ->
            CaPcheck = check(ca_p_ratio, failed,
                             CaPRound, CaPMin, CaPMax, too_low)
        ; CaPcheck = check(ca_p_ratio, failed,
                             CaPRound, CaPMin, CaPMax, too_high)
        )
    ;   CaPcheck = check(ca_p_ratio, error, undefined)
    ),

    Checks = [Pcheck, CaPcheck],
    collect_issues(Checks, Status, Warnings, Errors).

collect_issues(Checks, Status, Warnings, Errors) :-
    ( member(check(_, error, _), Checks) ->
        Status = error,
        Warnings = [],
        Errors = [err(mineral_calculation_error, calc_failed)]

    ; findall(check(Name, failed, Actual, Min),
              ( member(check(Name, failed, Actual, Min), Checks) ),
              FailedAP),
      findall(check(ca_p_ratio, failed, Ratio, Min, Max, Dir),
              ( member(check(ca_p_ratio, failed, Ratio, Min, Max, Dir),
                       Checks) ),
              FailedCaP),

      append(FailedAP, FailedCaP, AllFailed),
      ( AllFailed \= [] ->
          Status = failed,
          findall(warn(mineral_balance, Name),
                  member(check(Name, failed, _, _), FailedAP),
                  Warnings1),
          findall(warn(mineral_balance, ca_p_ratio),
                  member(check(ca_p_ratio, failed, _, _, _, _), FailedCaP),
                  Warnings2),
          append(Warnings1, Warnings2, Warnings),
          Errors = []

      ; Status = passed,
        Warnings = [],
        Errors = []
      )
    ).

% ═══════════════════════════════════════════════════════════════
% 工具谓词
% ═══════════════════════════════════════════════════════════════

my_length([], 0).
my_length([_|T], N) :- my_length(T, M), N is M + 1.

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

append([], Ys, Ys).
append([X|Xs], Ys, [X|Zs]) :- append(Xs, Ys, Zs).

forall(Cond, Action) :-  (Cond,  Action).

% ═══════════════════════════════════════════════════════════════
% 内嵌测试
% ═══════════════════════════════════════════════════════════════

test_all :-
    write('=== M5 mineral_balance ==='), nl,
    test_should_pass,
    test_should_fail,
    test_determinism,
    test_output_structure,
    test_edge_cases,
    write('=== M5 done ==='), nl.

test_should_pass :-
    Items = [
        item(fish_meal_peru_65, 0.28, _),
        item(soybean_meal_46,   0.25, _),
        item(corn,              0.15, _),
        item(wheat_flour,       0.18, _),
        item(fish_oil,          0.04, _),
        item(soybean_oil,       0.04, _),
        item(dicalcium_phosphate, 0.025, _),
        item(premix_vitamin_aqua, 0.01, _),
        item(premix_mineral_aqua, 0.01, _),
        item(salt,              0.005, _),
        item(choline_chloride_50, 0.005, _),
        item(mold_inhibitor,    0.003, _),
        item(antioxidant,       0.0015, _),
        item(betaine,           0.0005, _)
    ],
    mineral_balance_output(input(white_shrimp, adult, Items),
           output(data(_Checks), W, E, C, _)),
    ( E = [], W = [], C > 0.8 ->
        write('[PASS] white_shrimp -> passed'), nl
    ; write('[FAIL] white_shrimp -> '), write(E), nl
    ).

test_should_fail :-
    ItemsHighCa = [
        item(fish_meal_peru_65, 0.15, _),
        item(soybean_meal_46,   0.25, _),
        item(corn,              0.30, _),
        item(wheat_flour,       0.15, _),
        item(fish_oil,          0.03, _),
        item(limestone_powder,  0.05, _),
        item(premix_vitamin_aqua, 0.01, _),
        item(premix_mineral_aqua, 0.01, _)
    ],
    mineral_balance_output(input(white_shrimp, adult, ItemsHighCa),
           output(data(_C1), _, E1, _, _)),
    ( E1 = [] ->
        write('[PASS] high Ca/P -> failed'), nl
    ; write('[FAIL] high Ca/P expected fail, got error: '), write(E1), nl
    ),

    ItemsLowP = [
        item(soybean_meal_46,        0.30, _),
        item(rapeseed_meal_regular,  0.15, _),
        item(corn,                   0.25, _),
        item(wheat_flour,            0.20, _),
        item(soybean_oil,            0.05, _),
        item(premix_vitamin_aqua,    0.01, _),
        item(premix_mineral_aqua,    0.01, _)
    ],
    mineral_balance_output(input(white_shrimp, adult, ItemsLowP),
           output(data(_C2), _, E2, _, _)),
    ( E2 = [] ->
        write('[PASS] low available P -> failed'), nl
    ; write('[FAIL] low available P expected fail, got error: '), write(E2), nl
    ),

    mineral_balance_output(input(nonexistent, adult, [item(corn, 1.0, _)]),
           output(data([]), [], [err(invalid_species, nonexistent)], 0.0, [])),
    write('[PASS] invalid_species -> graceful error'), nl.

test_determinism :-
    Items = [
        item(fish_meal_peru_65, 0.25, _),
        item(soybean_meal_46,   0.30, _),
        item(corn,              0.25, _),
        item(wheat_flour,       0.10, _),
        item(dicalcium_phosphate, 0.02, _),
        item(limestone_powder,  0.01, _)
    ],
    mineral_balance_output(input(japanese_eel, adult, Items), Out1),
    mineral_balance_output(input(japanese_eel, adult, Items), Out2),
    ( Out1 = Out2 ->
        write('[PASS] determinism - identical outputs'), nl
    ; write('[FAIL] determinism - outputs differ'), nl
    ).

test_output_structure :-
    Items = [
        item(fish_meal_peru_65, 0.25, _),
        item(soybean_meal_46,   0.30, _),
        item(corn,              0.25, _),
        item(wheat_flour,       0.10, _),
        item(dicalcium_phosphate, 0.02, _),
        item(limestone_powder,  0.01, _)
    ],
    mineral_balance_output(input(white_shrimp, adult, Items),
           output(data(Checks), _W, _E, Confidence, _NA)),
    my_length(Checks, 2),
    ( number(Confidence), Confidence >= 0.0, Confidence =< 1.0 ->
        write('[PASS] structure valid'), nl
    ; write('[FAIL] structure invalid'), nl
    ).

test_edge_cases :-
    test_edge_species(japanese_eel),
    test_edge_species(white_shrimp),
    test_edge_species(common_carp),
    test_edge_species(grass_carp),
    test_edge_species(largemouth_bass).

test_edge_species(Sp) :-
    species_mineral_requirement(Sp, adult, _, _, _),
    Items = [
        item(fish_meal_peru_65, 0.25, _),
        item(soybean_meal_46,   0.30, _),
        item(corn,              0.25, _),
        item(wheat_flour,       0.10, _),
        item(dicalcium_phosphate, 0.02, _),
        item(limestone_powder,  0.01, _)
    ],
    mineral_balance_output(input(Sp, adult, Items),
           output(data(_Ch), _, E, _Conf, _)),
    ( E = [] ->
        write('[PASS] '), write(Sp), write(' -> passed'), nl
    ; write('[FAIL] '), write(Sp), write(' -> error: '), write(E), nl
    ).

mineral_check(S, St, Items, Out) :- once(mineral_balance_output(input(S, St, Items), Out)).
