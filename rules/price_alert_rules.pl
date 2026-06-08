% ═══════════════════════════════════════════════════════════════
% price_alert_rules.pl — M1 价格预警规则 v1.0.0
% AquaFeedFormulator Phase 1
%
% 职责：根据原料价格偏离度判断告警等级与动作。
% 输入：ingredient_id + deviation（偏离度，小数如 0.18 = 18%）
% 输出：level (ok/normal/high/urgent) + action + should_recompute
%
% 注意：使用 compound terms 而非 dict 语法，确保 scryer-prolog 兼容。
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 告警阈值表 — alert_threshold(+Ingredient, -Threshold)
% Threshold: 偏离度小数（例如 0.10 = 10%）
% ═══════════════════════════════════════════════════════════════

% 动物蛋白 — 核心原料，阈值紧
alert_threshold(fish_meal_peru_65,      0.10).
alert_threshold(fish_meal_domestic_60,  0.12).
alert_threshold(fish_meal_white_68,     0.10).
alert_threshold(blood_meal_spray,       0.12).
alert_threshold(meat_bone_meal_50,      0.12).
alert_threshold(poultry_meal,           0.12).
alert_threshold(squid_liver_paste,      0.15).
alert_threshold(shrimp_shell_meal,      0.15).
alert_threshold(silkworm_pupae_meal,    0.15).

% 植物蛋白 — 阈值略宽
alert_threshold(soybean_meal_43,        0.15).
alert_threshold(soybean_meal_46,        0.15).
alert_threshold(rapeseed_meal,          0.18).
alert_threshold(cottonseed_meal,        0.18).
alert_threshold(peanut_meal,            0.18).
alert_threshold(corn_gluten_meal_60,    0.15).

% 能量原料 — 阈值最宽
alert_threshold(corn,                   0.20).
alert_threshold(wheat_flour,            0.20).
alert_threshold(wheat_bran,            0.25).
alert_threshold(rice_bran,             0.25).

% 油脂
alert_threshold(fish_oil,              0.12).
alert_threshold(soybean_oil,           0.15).
alert_threshold(lecithin,              0.15).

% 矿物质 — 稳定品，阈值宽
alert_threshold(dicalcium_phosphate,   0.20).
alert_threshold(limestone,            0.30).
alert_threshold(salt,                 0.30).

% 添加剂
alert_threshold(premix_vitamin,        0.15).
alert_threshold(premix_mineral,        0.15).
alert_threshold(choline_chloride,      0.15).
alert_threshold(vitamin_c,            0.15).
alert_threshold(monocalcium_phosphate, 0.15).

% 默认阈值（未显式声明的原料）
alert_threshold(_, 0.15).

% ═══════════════════════════════════════════════════════════════
% 核心判定
% price_alert(+Ingredient, +Deviation, -Level, -Action, -ShouldRecompute)
%
% 判定逻辑:
%   deviation > 0.30              → urgent
%   deviation > threshold × 1.5   → high
%   deviation > threshold         → normal
%   otherwise                      → ok
% ═══════════════════════════════════════════════════════════════

price_alert(Ingredient, Deviation, Level, Action, ShouldRecompute) :-
    alert_threshold(Ingredient, Threshold),
    ( Deviation > 0.30 ->
        Level = urgent,
        Action = '立即锁定远期合同 + 触发配方强制重算',
        ShouldRecompute = true
    ; Deviation > Threshold * 1.5 ->
        Level = high,
        Action = '评估替代原料 + 建议调整配方成本模型',
        ShouldRecompute = true
    ; Deviation > Threshold ->
        Level = normal,
        Action = '持续监控，暂不干预',
        ShouldRecompute = false
    ; Level = ok,
        Action = '正常',
        ShouldRecompute = false
    ).

% ═══════════════════════════════════════════════════════════════
% 受影响物种
% ═══════════════════════════════════════════════════════════════

affected_species(Ingredient, Species) :-
    ingredient_category(Ingredient, animal_protein),
    member(Species, [japanese_eel, white_shrimp, common_carp, black_carp,
                     tilapia, grass_carp, sea_bass, yellow_catfish]).
affected_species(Ingredient, Species) :-
    ingredient_category(Ingredient, plant_protein),
    member(Species, [common_carp, tilapia, grass_carp, white_shrimp]).
affected_species(Ingredient, Species) :-
    ingredient_category(Ingredient, lipid),
    member(Species, [japanese_eel, white_shrimp, sea_bass, yellow_catfish]).

% ═══════════════════════════════════════════════════════════════
% ingredient_category(+Ingredient, -Category)
% ═══════════════════════════════════════════════════════════════

ingredient_category(Ingredient, Category) :-
    ingredient(Ingredient, _, Category, _, _, _, _, _, _, _, _, _).

% ═══════════════════════════════════════════════════════════════
% 统一输出协议
% output(+Input, -Output)
%
% Output = output(DataCompound, Warnings, Errors, Confidence, NextActions)
%   DataCompound = alerts(AlertList, Summary)
%     Alert = alert(Id, Dev, Level, Action, Recompute)
%     Summary = summary(Total, Triggered, Urgent, High, Normal)
% ═══════════════════════════════════════════════════════════════

output(Input, Output) :-
    Input = input(IngredientItems),
    findall(alert(Id, Dev, Level, Action, Recompute), (
        member(item(Id, Dev), IngredientItems),
        price_alert(Id, Dev, Level, Action, Recompute)
    ), AlertList),

    count_by_level(AlertList, urgent, Urg),
    count_by_level(AlertList, high, Hi),
    count_by_level(AlertList, normal, No),
    my_length(AlertList, Total),
    Triggered is Urg + Hi + No,

    % 编译 warnings
    findall(warning('price_alert_triggered', Sev, Msg), (
        member(alert(Id, Dev, L, _, _), AlertList),
        alert_severity(L, Sev),
        format_message(Id, L, Dev, Msg)
    ), Warnings),

    % next_actions
    ( memberchk(alert(_, _, _, _, true), AlertList) ->
        NextActions = ['建议运行配方重算或替代原料评估']
    ; NextActions = []
    ),

    Output = output(
        alerts(AlertList, summary(Total, Triggered, Urg, Hi, No)),
        Warnings,
        [],
        0.9,
        NextActions
    ).

alert_severity(urgent, high).
alert_severity(high,   medium).

format_message(Id, urgent, Dev, Msg) :-
    atom_concat('urgent price alert on ', Id, Tmp),
    atom_concat(Tmp, ' (', Tmp2),
    number_chars(Dev, Chars),
    atom_chars(DevAtom, Chars),
    atom_concat(Tmp2, DevAtom, Tmp3),
    atom_concat(Tmp3, ')', Msg).
format_message(Id, high, Dev, Msg) :-
    atom_concat('high price alert on ', Id, Tmp),
    atom_concat(Tmp, ' (', Tmp2),
    number_chars(Dev, Chars),
    atom_chars(DevAtom, Chars),
    atom_concat(Tmp2, DevAtom, Tmp3),
    atom_concat(Tmp3, ')', Msg).

% ═══════════════════════════════════════════════════════════════
% 工具
% ═══════════════════════════════════════════════════════════════

count_by_level([], _, 0).
count_by_level([alert(_, _, L, _, _)|T], L, C) :-
    count_by_level(T, L, C1),
    C is C1 + 1.
count_by_level([alert(_, _, L1, _, _)|T], L2, C) :-
    L1 \= L2,
    count_by_level(T, L2, C).

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

memberchk(X, [X|_]) :- !.
memberchk(X, [_|T]) :- memberchk(X, T).

my_length([], 0).
my_length([_|T], N) :- my_length(T, N1), N is N1 + 1.

% ═══════════════════════════════════════════════════════════════
% 测试 — test_all
% ═══════════════════════════════════════════════════════════════

test_all :-
    write('=== M1 price_alert_rules ==='), nl,
    test_should_pass,
    test_should_fail,
    test_determinism,
    test_output_structure,
    nl.

% --- test_should_pass: 正常价格 ---
test_should_pass :-
    write('--- should_pass ---'), nl,
    price_alert(fish_meal_peru_65, 0.08, L1, _, R1),
    memberchk(L1, [ok, normal]),
    R1 = false,
    write('[PASS] fish_meal_peru_65 +8% -> '), write(L1), nl,

    price_alert(soybean_meal_46, 0.10, L2, _, R2),
    memberchk(L2, [ok, normal]),
    R2 = false,
    write('[PASS] soybean_meal_46 +10% -> '), write(L2), nl,

    price_alert(corn, 0.15, L3, _, R3),
    memberchk(L3, [ok, normal]),
    R3 = false,
    write('[PASS] corn +15% -> '), write(L3), nl.

% --- test_should_fail: 价格异常 ---
test_should_fail :-
    write('--- should_fail ---'), nl,

    price_alert(fish_meal_peru_65, 0.12, normal, _, false),
    write('[PASS] fish_meal +12% -> normal'), nl,

    price_alert(fish_meal_peru_65, 0.18, high, _, true),
    write('[PASS] fish_meal +18% -> high + recompute'), nl,

    price_alert(fish_meal_peru_65, 0.35, urgent, _, true),
    write('[PASS] fish_meal +35% -> urgent'), nl,

    price_alert(wheat_flour, 0.22, normal, _, false),
    write('[PASS] wheat_flour +22% -> normal'), nl,

    price_alert(wheat_flour, 0.32, urgent, _, true),
    write('[PASS] wheat_flour +32% -> urgent'), nl.

% --- test_determinism: 确定性 ---
test_determinism :-
    write('--- determinism ---'), nl,
    price_alert(fish_meal_peru_65, 0.35, L1, A1, R1),
    price_alert(fish_meal_peru_65, 0.35, L2, A2, R2),
    ( L1 = L2, A1 = A2, R1 = R2 ->
        write('[PASS] deterministic'), nl
    ; write('[FAIL] non-deterministic!'), nl
    ).

% --- test_output_structure: 输出协议 ---
test_output_structure :-
    write('--- output_structure ---'), nl,
    MockInput = input([item(fish_meal_peru_65, 0.08),
                        item(fish_meal_peru_65, 0.35),
                        item(wheat_flour, 0.05)]),
    output(MockInput, Out),
    Out = output(
        alerts(AlertList, summary(Total, Triggered, Urg, Hi, No)),
        _, _, Confidence, _),
    write('[PASS] structure valid'), nl,
    write('  alerts='), my_length(AlertList, AC), write(AC),
    write(' total='), write(Total),
    write(' triggered='), write(Triggered),
    write(' confidence='), write(Confidence), nl.
