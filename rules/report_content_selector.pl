% ═══════════════════════════════════════════════════════════════
% report_content_selector.pl — M2 报告内容选择器 v1.0.0
% AquaFeedFormulator Phase 1
%
% 职责：根据物种/阶段/配方数据，输出 warning_code 和 suggestion_code
% 核心原则: Prolog 管决策（输出 code），Python 管文案（查表生成中文）
%
% 输入: input(Species, Stage, RecipeItems, NutrientProfile)
% 输出: output(warnings(Codes), suggestions(Codes), Evidence, Confidence, NextActions)
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 顶层入口
% ═══════════════════════════════════════════════════════════════

report_selector_output(Input, Output) :-
    Input = input(Species, Stage, Items, Nutrients),

    % 格式适配：Id-Pct-Cost → item(Id, Pct, Category)
    convert_items_report(Items, StdItems),

    % 收集所有 activated warnings
    findall(W, (
        active_warning(Species, Stage, StdItems, Nutrients, W)
    ), WarningCodes),

    % 收集所有 activated suggestions
    findall(S, (
        active_suggestion(Species, Stage, StdItems, Nutrients, S)
    ), SuggestionCodes),

    % 收集 evidence
    findall(E, (
        member(W, WarningCodes),
        warning_evidence(W, Species, Stage, StdItems, Nutrients, E)
    ), EvidenceList),

    % 置信度
    Confidence = 0.85,

    % NextActions
    ( WarningCodes \= [] ->
        NextActions = ['运行配方合规性校验', '检查报告中是否已包含对应警告章节']
    ; NextActions = []
    ),

    Output = output(
        warnings(WarningCodes),
        suggestions(SuggestionCodes),
        EvidenceList,
        Confidence,
        NextActions
    ).

% ═══════════════════════════════════════════════════════════════
% 通用工具
% ═══════════════════════════════════════════════════════════════

my_length([], 0).
my_length([_|T], N) :- my_length(T, N1), N is N1 + 1.

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

memberchk(X, [X|_]) :- !.
memberchk(X, [_|T]) :- memberchk(X, T).

% 从 Items 列表中查询某原料的占比
item_pct(Id, Items, Pct) :-
    member(item(Id, Pct, _), Items), !.
item_pct(_, _, 0.0).

% 从 Items 列表计算某品类总占比
category_pct(Category, Items, Total) :-
    findall(Pct, member(item(_, Pct, Category), Items), Pcts),
    sum_list(Pcts, Total).

sum_list([], 0).
sum_list([H|T], S) :- sum_list(T, S1), S is S1 + H.

% ═══════════════════════════════════════════════════════════════
% 格式适配：Id-Pct-Cost → item(Id, Pct, Category)
% ═══════════════════════════════════════════════════════════════

convert_items_report([], []).
convert_items_report([Id-Pct-Cost|T], [item(Id, Pct, Category)|RT]) :-
    ingredient(Id, _, Category, _, _, _, _, _, _, _, _),
    convert_items_report(T, RT).

% ═══════════════════════════════════════════════════════════════
% 判定架构: active_warning(+Species, +Stage, +Items, +Nutrients, -Code)
% ═══════════════════════════════════════════════════════════════

% ── 物种特化警告 ──

% 鳗鱼: 鱼油过低影响诱食性
active_warning(japanese_eel, _, Items, _, eel_palability_oil_low) :-
    item_pct(fish_oil, Items, OilPct),
    OilPct < 3.0.

% 鳗鱼: 鱼粉含量偏低（经济型方案）
active_warning(japanese_eel, _, Items, _, eel_low_fishmeal_attractant_risk) :-
    category_pct('animal_protein', Items, AnimalPct),
    AnimalPct < 40,  % 鳗鱼动物蛋白下限
    % 检查鱼粉类具体比例
    item_pct(fish_meal_peru_65, Items, Fm1),
    item_pct(fish_meal_domestic_60, Items, Fm2),
    item_pct(fish_meal_white_68, Items, Fm3),
    TotalFishmeal is Fm1 + Fm2 + Fm3,
    TotalFishmeal < 15.

% 对虾: 水中稳定性不足
active_warning(white_shrimp, _, Items, _, shrimp_water_stability) :-
    item_pct(wheat_flour, Items, FlourPct),
    item_pct(tapioca_starch, Items, TapiocaPct),
    TotalBinder is FlourPct + TapiocaPct,
    TotalBinder < 18.  % 对虾需要足够粘合剂

% 对虾: 胆固醇偏低
active_warning(white_shrimp, _, Items, _, shrimp_cholesterol_low) :-
    item_pct(cholesterol, Items, CholPct),
    CholPct < 0.2.

% 鲤鱼: 能量可能偏高
active_warning(common_carp, _, _Items, Nutrients, carp_energy_excess) :-
    Nutrients = nutrients(_, Fat, _, _, _, _, _),
    Fat > 7.0.

active_warning(grass_carp, _, _Items, Nutrients, carp_energy_excess) :-
    Nutrients = nutrients(_, Fat, _, _, _, _, _),
    Fat > 6.0.

% ── 通用警告（数据驱动）──

% 灰分偏高
active_warning(Species, Stage, _, Nutrients, general_ash_high) :-
    Nutrients = nutrients(_, _, _, Ash, _, _, _),
    species_nutrition(Species, Stage, _, _, _, AshMax),
    Ash > AshMax.

% 赖氨酸缺口（从配方动物蛋白比例间接推定，需绑定物种）
active_warning(Species, Stage, _, Nutrients, general_lysine_gap) :-
    Nutrients = nutrients(Protein, _, _, _, AnimalPct, _, _),
    AnimalPct < 20,
    species_nutrition(Species, Stage, ReqProtein, _, _, _),
    Protein < ReqProtein - 1.5.

% 蛋氨酸缺口（同理）
active_warning(Species, Stage, _, Nutrients, general_methionine_gap) :-
    Nutrients = nutrients(Protein, _, _, _, AnimalPct, _, _),
    AnimalPct < 15,
    species_nutrition(Species, Stage, ReqProtein, _, _, _),
    Protein < ReqProtein - 2.0.

% 粗纤维偏低（仅供参考，severity=info）
active_warning(_, _, _, Nutrients, general_fiber_low) :-
    Nutrients = nutrients(_, _, Fiber, _, _, _, _),
    Fiber < 3.0.

% ═══════════════════════════════════════════════════════════════
% 建议判定
% ═══════════════════════════════════════════════════════════════

% 鲤科鱼类: 高碳水 OK
active_suggestion(common_carp, _, _, _, carp_high_carb_ok).
active_suggestion(grass_carp, _, _, _, carp_high_carb_ok).
active_suggestion(black_carp, _, _, _, carp_high_carb_ok).
active_suggestion(crucian_carp, _, _, _, carp_high_carb_ok).
active_suggestion(tilapia, _, _, _, carp_high_carb_ok).

% 鳗鱼: 蛋白不宜过高
active_suggestion(japanese_eel, _, _Items, Nutrients, eel_high_protein_suggestion) :-
    Nutrients = nutrients(Protein, _, _, _, _, _, _),
    Protein > 48.

% 对虾: 高频投喂建议
active_suggestion(white_shrimp, _, _, _, shrimp_freq_feeding_suggestion).

% 成本在合理区间
active_suggestion(_, _, _, Nutrients, general_cost_suggestion) :-
    Nutrients = nutrients(_, _, _, _, _, _, Cost),
    Cost > 8000, Cost < 12000.

% 植物蛋白比例高时提醒适口性
active_suggestion(_, _, _Items, Nutrients, general_attractant_suggestion) :-
    Nutrients = nutrients(_, _, _, _, AnimalPct, _, _),
    AnimalPct < 35.

% ═══════════════════════════════════════════════════════════════
% Evidence 收集
% ═══════════════════════════════════════════════════════════════

warning_evidence(eel_palability_oil_low, _, _, Items, _, Evidence) :-
    item_pct(fish_oil, Items, OilPct),
    Evidence = evidence(eel_palability_oil_low, fish_oil_pct, OilPct, 3.0).

warning_evidence(eel_low_fishmeal_attractant_risk, _, _, Items, _, Evidence) :-
    item_pct(fish_meal_peru_65, Items, Fm1),
    item_pct(fish_meal_domestic_60, Items, Fm2),
    item_pct(fish_meal_white_68, Items, Fm3),
    TotalFishmeal is Fm1 + Fm2 + Fm3,
    Evidence = evidence(eel_low_fishmeal_attractant_risk, 'total_fishmeal_pct', TotalFishmeal, 15.0).

warning_evidence(shrimp_water_stability, _, _, Items, _, Evidence) :-
    item_pct(wheat_flour, Items, FlourPct),
    item_pct(tapioca_starch, Items, TapiocaPct),
    TotalBinder is FlourPct + TapiocaPct,
    Evidence = evidence(shrimp_water_stability, 'total_binder_pct', TotalBinder, 18.0).

warning_evidence(shrimp_cholesterol_low, _, _, Items, _, Evidence) :-
    item_pct(cholesterol, Items, CholPct),
    Evidence = evidence(shrimp_cholesterol_low, cholesterol_pct, CholPct, 0.2).

warning_evidence(carp_energy_excess, _, _, _, Nutrients, Evidence) :-
    Nutrients = nutrients(_, Fat, _, _, _, _, _),
    Evidence = evidence(carp_energy_excess, fat_pct, Fat, 7.0).

warning_evidence(general_ash_high, Species, Stage, _, Nutrients, Evidence) :-
    Nutrients = nutrients(_, _, _, Ash, _, _, _),
    species_nutrition(Species, Stage, _, _, _, AshMax),
    Evidence = evidence(general_ash_high, ash_pct, Ash, AshMax).

warning_evidence(general_lysine_gap, _, _, _, Nutrients, Evidence) :-
    Nutrients = nutrients(_Protein, _, _, _, AnimalPct, _, _),
    Evidence = evidence(general_lysine_gap, 'animal_protein_pct', AnimalPct, 20).

warning_evidence(general_methionine_gap, _, _, _, Nutrients, Evidence) :-
    Nutrients = nutrients(_Protein, _, _, _, AnimalPct, _, _),
    Evidence = evidence(general_methionine_gap, 'animal_protein_pct', AnimalPct, 15).

warning_evidence(general_fiber_low, _, _, _, Nutrients, Evidence) :-
    Nutrients = nutrients(_, _, Fiber, _, _, _, _),
    Evidence = evidence(general_fiber_low, fiber_pct, Fiber, 3.0).

% ═══════════════════════════════════════════════════════════════
% 测试 — test_all
% ═══════════════════════════════════════════════════════════════

test_all :-
    write('=== M2 report_content_selector ==='), nl,
    test_should_pass,
    test_should_fail,
    test_determinism,
    test_output_structure,
    nl.

% ── should_pass: 理想配方不应产生严重警告 ──
test_should_pass :-
    write('--- should_pass ---'), nl,

    % 白对虾理想配方: 高鱼粉 + 充足粘合剂 + 胆固醇
    IdealShrimp = input(white_shrimp, adult,
        [item(fish_meal_peru_65, 20.0, 'animal_protein'),
         item(fish_meal_domestic_60, 10.0, 'animal_protein'),
         item(wheat_flour, 18.0, 'starch'),
         item(tapioca_starch, 3.0, 'starch'),
         item(fish_oil, 2.5, oil),
         item(cholesterol, 0.3, 'additive')],
        nutrients(37.5, 7.5, 3.5, 12.0, 30.0, 18.0, 9600)),
    report_selector_output(IdealShrimp, Out1),
    Out1 = output(warnings(W1), _, _, _, _),

    % 理想配方不应触发 shrimp_water_stability (binder=21 > 18)
    \+ memberchk(shrimp_water_stability, W1),
    write('[PASS] ideal shrimp: no water_stability warning'), nl,

    % 也不应触发 cholesterol_low (0.3 > 0.2)
    \+ memberchk(shrimp_cholesterol_low, W1),
    write('[PASS] ideal shrimp: no cholesterol warning'), nl,

    % 鲤鱼配方: 应触发 carp_high_carb_ok 但不触发 energy_excess
    IdealCarp = input(common_carp, adult,
        [item(soybean_meal_46, 25.0, 'plant_protein'),
         item(wheat_flour, 20.0, 'starch')],
        nutrients(30.0, 5.0, 6.0, 10.0, 10.0, 25.0, 4000)),
    report_selector_output(IdealCarp, Out2),
    Out2 = output(_, suggestions(S2), _, _, _),
    memberchk(carp_high_carb_ok, S2),
    write('[PASS] carp: carp_high_carb_ok suggested'), nl.

% ── should_fail: 问题配方必须产生对应 warning ──
test_should_fail :-
    write('--- should_fail ---'), nl,

    % 对虾配方: 低粘合剂 → shrimp_water_stability
    BadBinder = input(white_shrimp, adult,
        [item(fish_meal_peru_65, 15.0, 'animal_protein'),
         item(wheat_flour, 10.0, 'starch')],
        nutrients(35.0, 6.0, 4.0, 12.0, 15.0, 10.0, 8000)),
    report_selector_output(BadBinder, Out1),
    Out1 = output(warnings(W1), _, _, _, _),
    memberchk(shrimp_water_stability, W1),
    write('[PASS] bad binder: shrimp_water_stability triggered'), nl,

    % 对虾配方: 无胆固醇 → shrimp_cholesterol_low
    BadChol = input(white_shrimp, adult,
        [item(fish_meal_peru_65, 15.0, 'animal_protein'),
         item(wheat_flour, 18.0, 'starch'),
         item(tapioca_starch, 3.0, 'starch')],
        nutrients(35.0, 6.0, 4.0, 12.0, 15.0, 18.0, 8000)),
    report_selector_output(BadChol, Out2),
    Out2 = output(warnings(W2), _, _, _, _),
    memberchk(shrimp_cholesterol_low, W2),
    write('[PASS] bad cholesterol: shrimp_cholesterol_low triggered'), nl,

    % 鳗鱼配方: 低鱼粉 + 低鱼油 → eel 系列 warning
    BadEel = input(japanese_eel, adult,
        [item(fish_meal_peru_65, 10.0, 'animal_protein'),
         item(fish_oil, 1.5, oil)],
        nutrients(40.0, 6.0, 3.0, 12.0, 10.0, 20.0, 10000)),
    report_selector_output(BadEel, Out3),
    Out3 = output(warnings(W3), _, _, _, _),
    memberchk(eel_palability_oil_low, W3),
    memberchk(eel_low_fishmeal_attractant_risk, W3),
    write('[PASS] bad eel: eel_palability + low_fishmeal triggered'), nl,

    % 鲤鱼配方: 高油脂
    BadCarp = input(common_carp, adult,
        [item(soybean_meal_46, 20.0, 'plant_protein'),
         item(fish_oil, 5.0, oil)],
        nutrients(28.0, 8.0, 5.0, 10.0, 5.0, 20.0, 5000)),
    report_selector_output(BadCarp, Out4),
    Out4 = output(warnings(W4), _, _, _, _),
    memberchk(carp_energy_excess, W4),
    write('[PASS] bad carp: carp_energy_excess triggered'), nl.

% ── determinism ──
test_determinism :-
    write('--- determinism ---'), nl,

    Input = input(white_shrimp, adult,
        [item(fish_meal_peru_65, 15.0, 'animal_protein'),
         item(wheat_flour, 10.0, 'starch')],
        nutrients(35.0, 6.0, 4.0, 12.0, 15.0, 10.0, 8000)),
    report_selector_output(Input, Out1),
    report_selector_output(Input, Out2),
    ( Out1 == Out2 ->
        write('[PASS] deterministic'), nl
    ; write('[FAIL] non-deterministic!'), nl
    ).

% ── output_structure ──
test_output_structure :-
    write('--- output_structure ---'), nl,

    Input = input(white_shrimp, adult,
        [item(fish_meal_peru_65, 15.0, 'animal_protein'),
         item(wheat_flour, 10.0, 'starch')],
        nutrients(35.0, 6.0, 4.0, 12.0, 15.0, 10.0, 8000)),
    report_selector_output(Input, Out),
    Out = output(warnings(W), suggestions(S), Ev, Confidence, Next),

    write('[PASS] structure valid'), nl,
    write('  warnings='), write(W), nl,
    write('  suggestions='), write(S), nl,
    my_length(Ev, EvLen), write('  evidence_count='), write(EvLen), nl,
    write('  confidence='), write(Confidence), nl,
    write('  next_actions='), write(Next), nl.

report_check(S, St, Items, Nuts, Out) :- once(report_selector_output(input(S, St, Items, Nuts), Out)).
