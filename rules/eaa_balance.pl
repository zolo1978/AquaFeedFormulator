% ═══════════════════════════════════════════════════════════════
% eaa_balance.pl — 必需氨基酸平衡校验 (M6)
% AquaFeedFormulator Phase 4
%
% 校验配方中 11 项 EAA 是否满足物种需求。
% 输入来自 recipe_planner 的输出。
%
% 依赖: ingredient_amino, species_nutrition
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 输出协议
%   Input  = input(Species, Stage, Items)
%   Items  = [item(Id, Pct, _Cost), ...]
%   Output = output(data(Checks), Warnings, Errors, Confidence, NextActions)
%   Checks = [check(AA_Name, Status, Actual, Required, PctMet), ...]
%   Status ∈ {met, borderline, deficient}
% ═══════════════════════════════════════════════════════════════

eaa_balance_output(input(Species, Stage, Items), Output) :-
    % 格式适配: LP输出 Id-Pct-Cost → item(Id,Pct,Cost)
    convert_items(Items, StdItems),
    ( species_amino_requirement(Species, Stage, _, _, _, _, _, _, _, _, _, _, _) ->
        calc_all_amino(StdItems, Lys, Met, MetCys, Thr, Trp,
                       Arg, Ile, Leu, Val, His, Phe),
        eval_amino(Species, Stage,
                   Lys, Met, MetCys, Thr, Trp,
                   Arg, Ile, Leu, Val, His, Phe,
                   Status, Checks, Warnings, Errors, Confidence),
        ( Errors = [] ->
            ( Status = met ->
                NextActions = []
            ; NextActions = [check_amino_supplement,
                             review_protein_sources,
                             consider_crystalline_amino_acids]
            )
        ; NextActions = []
        ),
        Output = output(data(Checks), Warnings, Errors,
                        Confidence, NextActions)
    ;   Output = output(data([]), [],
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
% 氨基酸累计计算
% ═══════════════════════════════════════════════════════════════

calc_all_amino(Items, Lys, Met, MetCys, Thr, Trp,
               Arg, Ile, Leu, Val, His, Phe) :-
    sum_aa(Items, 1, 0, Lys),
    sum_aa(Items, 2, 0, Met),
    sum_aa(Items, 3, 0, MetCys),
    sum_aa(Items, 4, 0, Thr),
    sum_aa(Items, 5, 0, Trp),
    sum_aa(Items, 6, 0, Arg),
    sum_aa(Items, 7, 0, Ile),
    sum_aa(Items, 8, 0, Leu),
    sum_aa(Items, 9, 0, Val),
    sum_aa(Items, 10, 0, His),
    sum_aa(Items, 11, 0, Phe).

% sum_aa(Items, AA_Position, Accumulator, Result)
% AA positions: 1=Lys 2=Met 3=MetCys 4=Thr 5=Trp 6=Arg 7=Ile 8=Leu 9=Val 10=His 11=Phe
sum_aa([], _, Acc, Acc).
sum_aa([item(Id, Pct, _)|Rest], Pos, Acc, Result) :-
    get_aa_value(Id, Pos, AAVal),
    NewAcc is Acc + Pct * AAVal,
    sum_aa(Rest, Pos, NewAcc, Result).

% 从 ingredient_amino 获取第 Pos 个氨基酸值
% 无数据的原料 (油脂/矿物/添加剂) 返回 0
get_aa_value(Id, Pos, Val) :-
    ingredient_amino(Id, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11),
    !,
    nth_aa(Pos, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, Val).
get_aa_value(_, _, 0.0).   % 非蛋白原料默认 AA=0

nth_aa(1,  V, _, _, _, _, _, _, _, _, _, _, V).
nth_aa(2,  _, V, _, _, _, _, _, _, _, _, _, V).
nth_aa(3,  _, _, V, _, _, _, _, _, _, _, _, V).
nth_aa(4,  _, _, _, V, _, _, _, _, _, _, _, V).
nth_aa(5,  _, _, _, _, V, _, _, _, _, _, _, V).
nth_aa(6,  _, _, _, _, _, V, _, _, _, _, _, V).
nth_aa(7,  _, _, _, _, _, _, V, _, _, _, _, V).
nth_aa(8,  _, _, _, _, _, _, _, V, _, _, _, V).
nth_aa(9,  _, _, _, _, _, _, _, _, V, _, _, V).
nth_aa(10, _, _, _, _, _, _, _, _, _, V, _, V).
nth_aa(11, _, _, _, _, _, _, _, _, _, _, V, V).

% ═══════════════════════════════════════════════════════════════
% 校验逻辑
% ═══════════════════════════════════════════════════════════════

eval_amino(Species, Stage,
           Lys, Met, MetCys, Thr, Trp,
           Arg, Ile, Leu, Val, His, Phe,
           Status, Checks, Warnings, Errors, Confidence) :-
    species_amino_requirement(Species, Stage,
                              RLys, RMet, RMetCys, RThr, RTrp,
                              RArg, RIle, RLeu, RVal, RHis, RPhe),

    chk(lys,     Lys,     RLys,     CLys),
    chk(met,     Met,     RMet,     CMet),
    chk(met_cys, MetCys,  RMetCys,  CMC),
    chk(thr,     Thr,     RThr,     CThr),
    chk(trp,     Trp,     RTrp,     CTrp),
    chk(arg,     Arg,     RArg,     CArg),
    chk(ile,     Ile,     RIle,     CIle),
    chk(leu,     Leu,     RLeu,     CLeu),
    chk(val,     Val,     RVal,     CVal),
    chk(his,     His,     RHis,     CHis),
    chk(phe,     Phe,     RPhe,     CPhe),

    Checks = [CLys, CMet, CMC, CThr, CTrp,
              CArg, CIle, CLeu, CVal, CHis, CPhe],

    assess(Checks, Status, Warnings, Errors, Confidence).

% 单项 AA 检查 : met(>=100%) / borderline(90-99%) / deficient(<90%)
chk(Name, Actual, Req, check(Name, Status, Actual, Req, PctMet)) :-
    ( Req > 0 ->
        PctMetRaw is Actual / Req * 100,
        PctMet is round(PctMetRaw),
        ( Actual >= Req ->
            Status = met
        ; Actual >= Req * 0.9 ->
            Status = borderline
        ; Status = deficient
        )
    ; Status = met,
      PctMet = 100
    ).

% 综合评估
assess(Checks, Status, Warnings, Errors, Confidence) :-
    cnt(Checks, deficient, DefCount),
    cnt(Checks, borderline, BorderCount),
    ( DefCount > 0 ->
        Status = deficient,
        collect_warnings(Checks, deficient, DefW),
        collect_warnings(Checks, borderline, BordW),
        my_append(DefW, BordW, Warnings),
        Errors = [],
        Confidence = 0.40
    ; BorderCount > 0 ->
        Status = borderline,
        collect_warnings(Checks, borderline, Warnings),
        Errors = [],
        Confidence = 0.70
    ; Status = met,
      Warnings = [],
      Errors = [],
      Confidence = 0.90
    ).

% 统计某状态项数
cnt([], _, 0).
cnt([check(_, S, _, _, _)|T], S, N) :-
    !, cnt(T, S, M), N is M + 1.
cnt([_|T], S, N) :-
    cnt(T, S, N).

% 收集某种状态的 warnings
collect_warnings([], _, []).
collect_warnings([check(Nm, St, _, _, _)|T], St, [warn(eaa, Nm, St)|Rest]) :-
    !, collect_warnings(T, St, Rest).
collect_warnings([_|T], St, Rest) :-
    collect_warnings(T, St, Rest).

% ═══════════════════════════════════════════════════════════════
% 工具谓词 (scryer-prolog 兼容)
% ═══════════════════════════════════════════════════════════════

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

my_append([], Ys, Ys).
my_append([X|Xs], Ys, [X|Zs]) :- my_append(Xs, Ys, Zs).

my_length([], 0).
my_length([_|T], N) :- my_length(T, M), N is M + 1.

% ═══════════════════════════════════════════════════════════════
% 内嵌测试
% ═══════════════════════════════════════════════════════════════

test_all :-
    write('=== M6 eaa_balance ==='), nl,
    test_should_pass,
    test_should_borderline,
    test_should_deficient,
    test_invalid_species,
    test_output_structure,
    test_determinism,
    test_edge_no_amino_ingredients,
    write('=== M6 done ==='), nl.

% --- 鳗鱼成体配方 (高鱼粉, 全部 EAA 应 met) ---
test_should_pass :-
    Items = [
        item(fish_meal_peru_65,       0.45, _),
        item(blood_meal_spray,        0.05, _),
        item(soybean_meal_46,         0.12, _),
        item(corn,                    0.08, _),
        item(wheat_flour,             0.15, _),
        item(fish_oil,                0.04, _),
        item(soybean_oil,             0.04, _),
        item(dicalcium_phosphate,     0.025, _),
        item(limestone_powder,        0.005, _),
        item(premix_vitamin_aqua,     0.01, _),
        item(premix_mineral_aqua,     0.01, _),
        item(salt,                    0.005, _),
        item(choline_chloride_50,     0.005, _),
        item(mold_inhibitor,          0.003, _),
        item(antioxidant,             0.0015, _),
        item(betaine,                 0.0005, _)
    ],
    eaa_balance_output(input(japanese_eel, adult, Items),
           output(data(Checks), W, E, C, _)),
    ( E = [], W = [], C > 0.8 ->
        write('[PASS] japanese_eel high-fishmeal -> met'), nl
    ; write('[FAIL] japanese_eel -> W='), write(W),
      write(' E='), write(E), write(' C='), write(C), nl
    ),
    % 验证至少 10 个 EAA met (Lys 可能 borderline)
    cnt_met(Checks, MetCount),
    ( MetCount >= 10 ->
        write('[PASS] >=10 EAA met: '), write(MetCount), nl
    ; write('[WARN] only '), write(MetCount), write(' EAA met'), nl
    ).

% --- 高豆粕配方 (Met 应 borderline/deficient) ---
test_should_borderline :-
    Items = [
        item(fish_meal_domestic_60,   0.10, _),
        item(soybean_meal_46,         0.40, _),
        item(corn,                    0.10, _),
        item(wheat_flour,             0.15, _),
        item(rice_bran_fullfat,       0.08, _),
        item(fish_oil,                0.04, _),
        item(soybean_oil,             0.04, _),
        item(dicalcium_phosphate,     0.03, _),
        item(limestone_powder,        0.01, _),
        item(premix_vitamin_aqua,     0.01, _),
        item(premix_mineral_aqua,     0.01, _),
        item(salt,                    0.005, _),
        item(choline_chloride_50,     0.005, _),
        item(betaine,                 0.001, _)
    ],
    eaa_balance_output(input(common_carp, adult, Items),
           output(data(_Checks), W, E, _C, _NA)),
    ( E = [] ->
        ( W \= [] ->
            write('[PASS] high-soy common_carp -> borderline'), nl
        ; write('[WARN] high-soy common_carp -> no warnings'), nl
        )
    ; write('[FAIL] high-soy common_carp -> error: '), write(E), nl
    ).

% --- 纯植物蛋白配方 (多数 EAA 应 deficient) ---
test_should_deficient :-
    Items = [
        item(soybean_meal_46,         0.35, _),
        item(rapeseed_meal_regular,   0.10, _),
        item(cottonseed_meal_regular, 0.08, _),
        item(peanut_meal,             0.05, _),
        item(corn,                    0.12, _),
        item(wheat_flour,             0.15, _),
        item(rice_bran_fullfat,       0.05, _),
        item(soybean_oil,             0.03, _),
        item(dicalcium_phosphate,     0.025, _),
        item(limestone_powder,        0.015, _),
        item(premix_vitamin_aqua,     0.01, _),
        item(premix_mineral_aqua,     0.01, _),
        item(salt,                    0.005, _),
        item(choline_chloride_50,     0.005, _)
    ],
    eaa_balance_output(input(largemouth_bass, adult, Items),
           output(data(_Checks), W, E, C, _NA)),
    ( E = [] ->
        ( C < 0.7 ->
            write('[PASS] plant-only largemouth_bass -> deficient (conf='),
            write(C), write(')'), nl
        ; write('[WARN] expected low confidence, got '), write(C), nl
        )
    ; write('[FAIL] plant-only -> error: '), write(E), nl
    ).

% --- 无效物种 ---
test_invalid_species :-
    eaa_balance_output(input(nonexistent_fish, adult, [item(corn, 1.0, _)]),
           output(data([]), _W, [err(invalid_species, X)], 0.0, [])),
    X = nonexistent_fish,
    write('[PASS] invalid species -> graceful error'), nl.

% --- 输出结构 ---
test_output_structure :-
    Items = [
        item(fish_meal_peru_65,  0.30, _),
        item(soybean_meal_46,    0.30, _),
        item(corn,               0.15, _),
        item(wheat_flour,        0.12, _),
        item(fish_oil,           0.04, _),
        item(soybean_oil,        0.03, _),
        item(dicalcium_phosphate, 0.02, _),
        item(limestone_powder,   0.01, _),
        item(premix_vitamin_aqua, 0.01, _),
        item(premix_mineral_aqua, 0.01, _),
        item(salt,               0.005, _)
    ],
    eaa_balance_output(input(grass_carp, adult, Items),
           output(data(Checks), _W, _E, Confidence, _NA)),
    my_length(Checks, 11),
    ( number(Confidence), Confidence >= 0.0, Confidence =< 1.0 ->
        write('[PASS] output structure valid: 11 checks'), nl
    ; write('[FAIL] output structure invalid'), nl
    ).

% --- 确定性 ---
test_determinism :-
    Items = [
        item(fish_meal_peru_65,  0.25, _),
        item(soybean_meal_46,    0.30, _),
        item(corn,               0.15, _),
        item(wheat_flour,        0.15, _),
        item(fish_oil,           0.04, _),
        item(soybean_oil,        0.04, _),
        item(dicalcium_phosphate, 0.025, _),
        item(limestone_powder,   0.005, _),
        item(premix_vitamin_aqua, 0.01, _),
        item(premix_mineral_aqua, 0.01, _)
    ],
    eaa_balance_output(input(white_shrimp, adult, Items), Out1),
    eaa_balance_output(input(white_shrimp, adult, Items), Out2),
    ( Out1 = Out2 ->
        write('[PASS] determinism - identical outputs'), nl
    ; write('[FAIL] determinism - outputs differ'), nl
    ).

% --- 纯非蛋白原料 (油脂+矿物+添加剂) ---
test_edge_no_amino_ingredients :-
    Items = [
        item(fish_oil,              0.40, _),
        item(soybean_oil,           0.30, _),
        item(dicalcium_phosphate,   0.15, _),
        item(limestone_powder,      0.10, _),
        item(premix_vitamin_aqua,   0.02, _),
        item(premix_mineral_aqua,   0.02, _),
        item(salt,                  0.01, _)
    ],
    eaa_balance_output(input(common_carp, adult, Items),
           output(data(_Checks), W, E, C, _NA)),
    ( E = [] ->
        ( C < 0.5 ->
            write('[PASS] no-protein recipe -> deficient'), nl
        ; write('[WARN] no-protein recipe -> unexpected confidence: '),
          write(C), nl
        )
    ; write('[FAIL] no-protein recipe -> error: '), write(E), nl
    ).

% 辅助: 统计 met 状态的检查项
cnt_met([], 0).
cnt_met([check(_, met, _, _, _)|T], N) :-
    !, cnt_met(T, M), N is M + 1.
cnt_met([_|T], N) :-
    cnt_met(T, N).

eaa_check(S, St, Items, Out) :- once(eaa_balance_output(input(S, St, Items), Out)).
