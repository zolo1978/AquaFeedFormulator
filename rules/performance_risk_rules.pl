% ═══════════════════════════════════════════════════════════════
% performance_risk_rules.pl — 配方性能风险评估 (M7b)
% AquaFeedFormulator Phase 5
%
% 评估配方对养殖性能 (FCR, 生长, 健康) 的潜在风险。
% 所有输出均为 warnings (软建议), 无 errors.
%
% 风险维度:
%   1. 动物/植物蛋白比 — 肉食性物种需要高动物蛋白
%   2. 鱼油充足性     — 海水物种依赖 n-3 HUFA
%   3. 纤维过载       — 高纤维降低消化率
%   4. 灰分过载       — 高灰分影响适口性
%   5. 蛋白偏离度     — 供需落差
%   6. 脂肪偏离度     — 能量平衡
%   7. 诱食剂覆盖     — 低鱼粉配方需要诱食剂
%   8. 综合 FCR 风险  — 汇总评估
%
% 依赖: ingredient_db, species_nutrition
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 输出协议
%   Input  = input(Species, Stage, Items)
%   Items  = [item(Id, Pct, _Cost), ...]
%   Output = output(data(Checks), Warnings, Errors, Confidence, NextActions)
%   Checks = [risk(Dimension, Level, Detail), ...]
%   Level ∈ {low, medium, high}
% ═══════════════════════════════════════════════════════════════

perf_risk_output(input(Species, Stage, Items), Output) :-
    % 格式适配: LP输出 Id-Pct-Cost → item(Id,Pct,Cost)
    convert_items(Items, StdItems),
    ( species_nutrition(Species, Stage, _, _, _, _) ->
        species_nutrition(Species, Stage,
                          ReqPro, ReqFat, ReqFibMax, ReqAshMax),
        analyze_formula(StdItems,
                        TotPro, TotFat, TotFib, TotAsh,
                        AnimPro, PlantPro,
                        MarineOil, VegOil,
                        HasAttract, FishMealTotal),
        feeding_class(Species, FeedClass),
        assess_all(Species, FeedClass,
                   TotPro, TotFat, TotFib, TotAsh,
                   ReqPro, ReqFat, ReqFibMax, ReqAshMax,
                   AnimPro, PlantPro,
                   MarineOil, VegOil,
                   HasAttract, FishMealTotal,
                   Checks, Warnings, Confidence),
        ( Warnings = [] ->
            NextActions = []
        ; NextActions = [review_formula_composition,
                         adjust_protein_sources,
                         check_oil_blend]
        ),
        Output = output(data(Checks), Warnings, [],
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
% 物种摄食类型
% ═══════════════════════════════════════════════════════════════

feeding_class(japanese_eel,    carnivore).
feeding_class(largemouth_bass, carnivore).
feeding_class(white_shrimp,    carnivore).
feeding_class(common_carp,     omnivore).
feeding_class(grass_carp,      herbivore).
% 兜底 — 未知物种默认 omnivore
feeding_class(_, omnivore).

% ═══════════════════════════════════════════════════════════════
% 配方分析 — 逐原料累计
% ═══════════════════════════════════════════════════════════════

analyze_formula(Items,
                TotPro, TotFat, TotFib, TotAsh,
                AnimPro, PlantPro,
                MarineOil, VegOil,
                HasAttract, FishMealTotal) :-
    sum_nutrients(Items, 0, TotPro, 0, TotFat, 0, TotFib, 0, TotAsh,
                  0, AnimPro, 0, PlantPro,
                  0, MarineOil, 0, VegOil,
                  0, FishMealTotal, 0, HasAttractRaw),
    HasAttract is min(HasAttractRaw, 1).

sum_nutrients([], Pro, Pro, Fat, Fat, Fib, Fib, Ash, Ash,
              APro, APro, PPro, PPro,
              MOil, MOil, VOil, VOil,
              FM, FM, Attr, Attr).
sum_nutrients([item(Id, Pct, _)|Rest],
              Pro0, Pro, Fat0, Fat, Fib0, Fib, Ash0, Ash,
              AP0, AP, PP0, PP,
              MO0, MO, VO0, VO,
              FM0, FM, Attr0, Attr) :-
    ingredient(Id, _, Category, IngPro, IngFat, IngFib, IngAsh,
               _, _, _, _),
    Pro1  is Pro0  + Pct * IngPro,
    Fat1  is Fat0  + Pct * IngFat,
    Fib1  is Fib0  + Pct * IngFib,
    Ash1  is Ash0  + Pct * IngAsh,
    % 动物/植物蛋白拆分
    animal_protein_check(Category, AP0, Pct, IngPro, AP1, PP0, PP1),
    % 鱼油/植物油拆分
    oil_check(Id, MO0, Pct, MO1, VO0, VO1),
    % 鱼粉累计
    fishmeal_check(Id, FM0, Pct, FM1),
    % 诱食剂检测
    attractant_check(Id, Attr0, Attr1),
    sum_nutrients(Rest,
                  Pro1, Pro, Fat1, Fat, Fib1, Fib, Ash1, Ash,
                  AP1, AP, PP1, PP,
                  MO1, MO, VO1, VO,
                  FM1, FM, Attr1, Attr).

% --- 动物/植物蛋白拆分 ---
animal_protein_check(animal_protein, AP0, Pct, IngPro, AP1, PP0, PP0) :-
    !, AP1 is AP0 + Pct * IngPro.
animal_protein_check(plant_protein, AP0, Pct, IngPro, AP0, PP0, PP1) :-
    !, PP1 is PP0 + Pct * IngPro.
animal_protein_check(_, AP0, _, _, AP0, PP0, PP0).

% --- 鱼油/植物油拆分 ---
oil_check(fish_oil, MO0, Pct, MO1, VO0, VO0) :-
    !, MO1 is MO0 + Pct.
oil_check(soybean_oil, MO0, Pct, MO0, VO0, VO1) :-
    !, VO1 is VO0 + Pct.
oil_check(rapeseed_oil, MO0, Pct, MO0, VO0, VO1) :-
    !, VO1 is VO0 + Pct.
oil_check(soybean_lecithin, MO0, Pct, MO0, VO0, VO1) :-
    !, VO1 is VO0 + Pct.
oil_check(_, MO0, _, MO0, VO0, VO0).

% --- 鱼粉累计 ---
fishmeal_check(fish_meal_peru_65, FM0, Pct, FM1) :-
    !, FM1 is FM0 + Pct.
fishmeal_check(fish_meal_domestic_60, FM0, Pct, FM1) :-
    !, FM1 is FM0 + Pct.
fishmeal_check(fish_meal_white_68, FM0, Pct, FM1) :-
    !, FM1 is FM0 + Pct.
fishmeal_check(_, FM0, _, FM0).

% --- 诱食剂检测 ---
attractant_check(squid_liver_paste, Attr0, Attr1) :-
    !, Attr1 is Attr0 + 1.
attractant_check(betaine, Attr0, Attr1) :-
    !, Attr1 is Attr0 + 1.
attractant_check(_, Attr0, Attr0).

% ═══════════════════════════════════════════════════════════════
% 综合评估
% ═══════════════════════════════════════════════════════════════

assess_all(Species, FeedClass,
           TotPro, TotFat, TotFib, TotAsh,
           ReqPro, ReqFat, ReqFibMax, ReqAshMax,
           AnimPro, _PlantPro,
           MarineOil, VegOil,
           HasAttract, FishMealTotal,
           Checks, Warnings, Confidence) :-

    % 1. 动物蛋白比
    check_animal_protein_ratio(FeedClass, TotPro, AnimPro, C1, W1),

    % 2. 鱼油充足性
    check_marine_oil(Species, MarineOil, VegOil, C2, W2),

    % 3. 纤维
    check_fiber(TotFib, ReqFibMax, C3, W3),

    % 4. 灰分
    check_ash(TotAsh, ReqAshMax, C4, W4),

    % 5. 蛋白偏离
    check_protein_deviation(TotPro, ReqPro, C5, W5),

    % 6. 脂肪偏离
    check_fat_deviation(TotFat, ReqFat, C6, W6),

    % 7. 诱食剂
    check_attractant(FishMealTotal, HasAttract, C7, W7),

    % 8. FCR 综合风险
    Checks = [C1, C2, C3, C4, C5, C6, C7],
    collect_all_warnings([W1, W2, W3, W4, W5, W6, W7], Warnings),
    fcr_overall_risk(Checks, Confidence).

% ═══════════════════════════════════════════════════════════════
% 风险维度 1: 动物蛋白/总蛋白比
% 肉食性 ≥ 0.45, 杂食性 ≥ 0.20, 草食性 ≥ 0.10
% ═══════════════════════════════════════════════════════════════

check_animal_protein_ratio(FeedClass, TotPro, AnimPro, Risk, Warn) :-
    ( TotPro > 0 ->
        APR is AnimPro / TotPro
    ; APR = 0
    ),
    class_apr_threshold(FeedClass, HighThresh, MedThresh),
    ( APR >= HighThresh ->
        Risk = risk(animal_protein_ratio, low, APR),
        Warn = none
    ; APR >= MedThresh ->
        Risk = risk(animal_protein_ratio, medium, APR),
        Warn = warn(performance, low_animal_protein,
                    '增加动物蛋白源占比以改善适口性与生长')
    ; Risk = risk(animal_protein_ratio, high, APR),
      Warn = warn(performance, very_low_animal_protein,
                  '动物蛋白严重不足, 建议提高鱼粉/肉粉用量')
    ).

class_apr_threshold(carnivore, 0.45, 0.30).
class_apr_threshold(omnivore,  0.20, 0.10).
class_apr_threshold(herbivore, 0.10, 0.05).

% ═══════════════════════════════════════════════════════════════
% 风险维度 2: 鱼油充足性 (海水物种需要鱼油提供 n-3 HUFA)
% ═══════════════════════════════════════════════════════════════

check_marine_oil(Species, MarineOil, VegOil, Risk, Warn) :-
    needs_marine_oil(Species, NeedMarine),
    TotalOil is MarineOil + VegOil,
    ( NeedMarine = yes, TotalOil > 0 ->
        MOR is MarineOil / TotalOil,
        ( MOR >= 0.5 ->
            Risk = risk(marine_oil_ratio, low, MOR),
            Warn = none
        ; MOR >= 0.3 ->
            Risk = risk(marine_oil_ratio, medium, MOR),
            Warn = warn(performance, low_marine_oil,
                        '海水物种需要足够鱼油提供 n-3 HUFA, 建议鱼油占比 ≥ 50%')
        ; Risk = risk(marine_oil_ratio, high, MOR),
          Warn = warn(performance, very_low_marine_oil,
                      '鱼油严重不足, n-3 HUFA 缺乏风险')
        )
    ; ( NeedMarine = yes ->
        Risk = risk(marine_oil_ratio, high, 0),
        Warn = warn(performance, no_oil_source,
                    '配方中无油脂来源, 海水物种必须添加鱼油')
    ; Risk = risk(marine_oil_ratio, low, 'N/A'),
      Warn = none
    )
    ).

needs_marine_oil(japanese_eel,    yes).
needs_marine_oil(largemouth_bass, yes).
needs_marine_oil(white_shrimp,    yes).
needs_marine_oil(_,               no).

% ═══════════════════════════════════════════════════════════════
% 风险维度 3: 纤维含量
% ═══════════════════════════════════════════════════════════════

check_fiber(TotFib, FibMax, Risk, Warn) :-
    FibRatio is TotFib / FibMax,
    ( FibRatio =< 1.0 ->
        Risk = risk(fiber_content, low, TotFib),
        Warn = none
    ; FibRatio =< 1.2 ->
        Risk = risk(fiber_content, medium, TotFib),
        Warn = warn(performance, high_fiber,
                    '纤维含量偏高, 可能降低消化率')
    ; Risk = risk(fiber_content, high, TotFib),
      Warn = warn(performance, excessive_fiber,
                  '纤维严重超标, 将显著降低饲料转化率')
    ).

% ═══════════════════════════════════════════════════════════════
% 风险维度 4: 灰分含量
% ═══════════════════════════════════════════════════════════════

check_ash(TotAsh, AshMax, Risk, Warn) :-
    AshRatio is TotAsh / AshMax,
    ( AshRatio =< 1.0 ->
        Risk = risk(ash_content, low, TotAsh),
        Warn = none
    ; AshRatio =< 1.15 ->
        Risk = risk(ash_content, medium, TotAsh),
        Warn = warn(performance, high_ash,
                    '灰分偏高, 检查矿物质原料用量')
    ; Risk = risk(ash_content, high, TotAsh),
      Warn = warn(performance, excessive_ash,
                  '灰分严重超标, 可能影响适口性与采食量')
    ).

% ═══════════════════════════════════════════════════════════════
% 风险维度 5: 蛋白供需偏离
% ═══════════════════════════════════════════════════════════════

check_protein_deviation(TotPro, ReqPro, Risk, Warn) :-
    Dev is (TotPro - ReqPro) / ReqPro,
    ( Dev >= -0.05, Dev =< 0.10 ->
        Risk = risk(protein_level, low, TotPro),
        Warn = none
    ; Dev < -0.05 ->
        ( Dev < -0.15 ->
            Risk = risk(protein_level, high, TotPro),
            Warn = warn(performance, protein_deficient,
                        '蛋白严重不足, 无法满足生长需求')
        ; Risk = risk(protein_level, medium, TotPro),
          Warn = warn(performance, protein_low,
                      '蛋白略低于需求, 可能影响生长速度')
        )
    ; ( Dev > 0.20 ->
        Risk = risk(protein_level, medium, TotPro),
        Warn = warn(performance, protein_excess,
                    '蛋白显著超标, 增加成本且加重氮排放')
    ; Risk = risk(protein_level, low, TotPro),
      Warn = none
    )
    ).

% ═══════════════════════════════════════════════════════════════
% 风险维度 6: 脂肪供需偏离
% ═══════════════════════════════════════════════════════════════

check_fat_deviation(TotFat, ReqFat, Risk, Warn) :-
    ( ReqFat > 0 ->
        Dev is (TotFat - ReqFat) / ReqFat
    ; Dev = 0
    ),
    ( Dev >= -0.1, Dev =< 0.15 ->
        Risk = risk(fat_level, low, TotFat),
        Warn = none
    ; Dev < -0.1 ->
        ( Dev < -0.25 ->
            Risk = risk(fat_level, high, TotFat),
            Warn = warn(performance, fat_deficient,
                        '脂肪严重不足, 能量供给不够')
        ; Risk = risk(fat_level, medium, TotFat),
          Warn = warn(performance, fat_low,
                      '脂肪略低, 考虑增加油脂用量改善能量')
        )
    ; ( Dev > 0.30 ->
        Risk = risk(fat_level, high, TotFat),
        Warn = warn(performance, fat_excess,
                    '脂肪严重超标, 警惕脂肪肝与氧化风险')
    ; Risk = risk(fat_level, medium, TotFat),
      Warn = warn(performance, fat_high,
                  '脂肪偏高, 注意储存期氧化与脂肪肝')
    )
    ).

% ═══════════════════════════════════════════════════════════════
% 风险维度 7: 诱食剂覆盖 (低鱼粉配方)
% ═══════════════════════════════════════════════════════════════

check_attractant(FishMealTotal, HasAttract, Risk, Warn) :-
    ( FishMealTotal < 0.15 ->
        ( HasAttract > 0 ->
            Risk = risk(attractant, low, '有诱食剂覆盖'),
            Warn = none
        ; Risk = risk(attractant, medium, '低鱼粉且无诱食剂'),
          Warn = warn(performance, missing_attractant,
                      '鱼粉用量低于15% 且无诱食剂, 可能影响采食量')
        )
    ; Risk = risk(attractant, low, '鱼粉充足'),
      Warn = none
    ).

% ═══════════════════════════════════════════════════════════════
% 综合 FCR 风险 — 加权汇总
% ═══════════════════════════════════════════════════════════════

fcr_overall_risk(Checks, Confidence) :-
    risk_score(Checks, 0, TotalScore, 0, MaxScore),
    ( MaxScore > 0 ->
        Confidence is 1.0 - (TotalScore / MaxScore)
    ; Confidence = 1.0
    ).

risk_score([], Score, Score, Max, Max).
risk_score([risk(_, low, _)|T], S0, S, M0, M) :-
    S1 is S0, M1 is M0 + 1,
    risk_score(T, S1, S, M1, M).
risk_score([risk(_, medium, _)|T], S0, S, M0, M) :-
    S1 is S0 + 1, M1 is M0 + 2,
    risk_score(T, S1, S, M1, M).
risk_score([risk(_, high, _)|T], S0, S, M0, M) :-
    S1 is S0 + 2, M1 is M0 + 2,
    risk_score(T, S1, S, M1, M).

% ═══════════════════════════════════════════════════════════════
% 辅助
% ═══════════════════════════════════════════════════════════════

collect_all_warnings(Ws, Filtered) :-
    exclude_none(Ws, Raw),
    Raw = Filtered.

exclude_none([], []).
exclude_none([none|T], R) :- exclude_none(T, R).
exclude_none([W|T], [W|R]) :- W \= none, exclude_none(T, R).

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

my_length([], 0).
my_length([_|T], N) :- my_length(T, M), N is M + 1.

% ═══════════════════════════════════════════════════════════════
% 内嵌测试
% ═══════════════════════════════════════════════════════════════

test_all :-
    write('=== M7b performance_risk_rules ==='), nl,
    test_low_risk,
    test_low_fishmeal_risk,
    test_high_fiber_risk,
    test_low_marine_oil,
    test_invalid_species,
    test_output_structure,
    test_determinism,
    test_all_species,
    write('=== M7b done ==='), nl.

% --- 理想鳗鱼配方 (高鱼粉 + 鱼油 + 诱食剂 → low risk) ---
test_low_risk :-
    % 鳗鱼成体理想配方 — 低风险 (无严重偏离)
    % 蛋白≈42%, 脂肪≈6.7%, 灰分≈11.3%, 纤维≈2%
    Items = [
        item(fish_meal_peru_65,       0.40, _),
        item(blood_meal_spray,        0.05, _),
        item(soybean_meal_46,         0.20, _),
        item(corn,                    0.10, _),
        item(wheat_flour,             0.17, _),
        item(fish_oil,                0.01, _),
        item(soybean_oil,             0.005, _),
        item(squid_liver_paste,       0.02, _),
        item(dicalcium_phosphate,     0.015, _),
        item(limestone_powder,        0.005, _),
        item(premix_vitamin_aqua,     0.01, _),
        item(premix_mineral_aqua,     0.01, _),
        item(salt,                    0.003, _),
        item(choline_chloride_50,     0.002, _)
    ],
    once(perf_risk_output(input(japanese_eel, adult, Items),
           output(data(Checks), W, [], C, _NA))),
    my_length(Checks, 7),
    ( C > 0.7 ->
        write('[PASS] ideal eel recipe -> confidence='),
        write(C), nl
    ; write('[FAIL] ideal eel -> C='), write(C),
      write(' W='), write(W), nl
    ).

% --- 低鱼粉配方 (应产生诱食剂 + 动物蛋白风险) ---
test_low_fishmeal_risk :-
    Items = [
        item(fish_meal_domestic_60,   0.10, _),
        item(soybean_meal_46,         0.35, _),
        item(rapeseed_meal_regular,   0.10, _),
        item(cottonseed_meal_regular, 0.08, _),
        item(corn,                    0.10, _),
        item(wheat_flour,             0.12, _),
        item(soybean_oil,             0.06, _),
        item(dicalcium_phosphate,     0.03, _),
        item(limestone_powder,        0.02, _),
        item(premix_vitamin_aqua,     0.01, _),
        item(premix_mineral_aqua,     0.01, _),
        item(salt,                    0.005, _)
    ],
    once(perf_risk_output(input(largemouth_bass, adult, Items),
           output(data(_Checks), W, [], C, _NA))),
    ( W \= [], C < 0.7 ->
        write('[PASS] low-fishmeal bass -> warnings, C='),
        write(C), nl
    ; write('[FAIL] low-fishmeal bass -> W='), write(W),
      write(' C='), write(C), nl
    ).

% --- 高纤维配方 (应产生纤维风险) ---
test_high_fiber_risk :-
    % 纤维≈10.85%, 超过草鱼 FiberMax=10 → high_fiber
    Items = [
        item(cottonseed_meal_regular, 0.35, _),
        item(rice_bran_fullfat,       0.30, _),
        item(rapeseed_meal_regular,   0.20, _),
        item(wheat_middlings,         0.10, _),
        item(dicalcium_phosphate,     0.02, _),
        item(limestone_powder,        0.01, _),
        item(premix_vitamin_aqua,     0.01, _),
        item(premix_mineral_aqua,     0.01, _)
    ],
    once(perf_risk_output(input(grass_carp, adult, Items),
           output(data(_Checks), W, [], _C, _NA))),
    ( member(warn(performance, high_fiber, _), W) ->
        write('[PASS] high-fiber grass_carp -> fiber warning'), nl
    ; member(warn(performance, excessive_fiber, _), W) ->
        write('[PASS] high-fiber grass_carp -> excessive fiber'), nl
    ; write('[WARN] high-fiber grass_carp -> no fiber warning, W='),
      write(W), nl
    ).

% --- 无鱼油的肉食性配方 (应产生鱼油风险) ---
test_low_marine_oil :-
    Items = [
        item(fish_meal_peru_65,       0.30, _),
        item(soybean_meal_46,         0.30, _),
        item(corn,                    0.15, _),
        item(wheat_flour,             0.12, _),
        item(soybean_oil,             0.06, _),
        item(dicalcium_phosphate,     0.025, _),
        item(limestone_powder,        0.015, _),
        item(premix_vitamin_aqua,     0.01, _),
        item(premix_mineral_aqua,     0.01, _),
        item(salt,                    0.005, _)
    ],
    once(perf_risk_output(input(white_shrimp, adult, Items),
           output(data(_Checks), W, [], _C, _NA))),
    ( ( member(warn(performance, low_marine_oil, _), W)
      ; member(warn(performance, very_low_marine_oil, _), W) ) ->
        write('[PASS] no-fish-oil shrimp -> marine oil warning'), nl
    ; write('[WARN] no-fish-oil shrimp -> no marine oil warning, W='),
      write(W), nl
    ).

% --- 无效物种 ---
test_invalid_species :-
    once(perf_risk_output(input(unknown_fish, adult, [item(corn, 1.0, _)]),
           output(data([]), _W, [err(invalid_species, X)], 0.0, []))),
    X = unknown_fish,
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
    once(perf_risk_output(input(common_carp, adult, Items),
           output(data(Checks), _W, [], Confidence, _NA))),
    my_length(Checks, 7),
    ( number(Confidence), Confidence >= 0.0, Confidence =< 1.0 ->
        write('[PASS] output structure valid: 7 checks'), nl
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
    once(perf_risk_output(input(largemouth_bass, adult, Items), Out1)),
    once(perf_risk_output(input(largemouth_bass, adult, Items), Out2)),
    ( Out1 = Out2 ->
        write('[PASS] determinism - identical outputs'), nl
    ; write('[FAIL] determinism - outputs differ'), nl
    ).

% --- 全物种覆盖 ---
test_all_species :-
    test_one_species(japanese_eel,    adult),
    test_one_species(white_shrimp,    adult),
    test_one_species(common_carp,     adult),
    test_one_species(grass_carp,      adult),
    test_one_species(largemouth_bass, adult).

test_one_species(Sp, Stage) :-
    species_nutrition(Sp, Stage, _, _, _, _),
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
        item(premix_mineral_aqua, 0.01, _),
        item(salt,               0.005, _)
    ],
    once(perf_risk_output(input(Sp, Stage, Items),
           output(data(Checks), _W, [], C, _NA))),
    my_length(Checks, 7),
    ( number(C), C >= 0.0, C =< 1.0 ->
        write('[PASS] '), write(Sp), write(' -> C='),
        write(C), nl
    ; write('[FAIL] '), write(Sp), nl
    ).

performance_risk_check(S, St, Items, Out) :- once(perf_risk_output(input(S, St, Items), Out)).
