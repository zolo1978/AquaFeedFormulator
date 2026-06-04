% ============================================================
% nutrition_calculator.pl — 手配配方营养值自动计算 + 校验
% ============================================================
%
% 背景:
%   手配配方时, recipe 结构中的 Protein/Fat/Fiber/Ash 依赖人工估算。
%   本模块从 ingredient_db 读取各原料营养数据, 按配比加权求和,
%   与 recipe 中声明的值以及 species_nutrition 目标值三方比对。
%
% 谓词:
%   calc_recipe_nutrition(+Items, -CalcProtein, -CalcFat, -CalcFiber, -CalcAsh, -Unknowns)
%   validate_nutrition(+Recipe, -NutritionReport)
%   validate_nutrition_all  (一键校验当前配方文件所有配方)
% ============================================================

% ==== 工具谓词 ====
sum_list([], 0).
sum_list([H|T], S) :- sum_list(T, R), S is H + R.

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

% ==========================================
% 1. 单原料营养值查询
% ==========================================

% ingredient_nutrient(Id, Protein%, Fat%, Fiber%, Ash%)
ingredient_nutrient(Id, Protein, Fat, Fiber, Ash) :-
    ingredient(Id, _, _, Protein, Fat, Fiber, Ash, _, _, _, _).

% 有营养数据的原料?
has_nutrition_data(Id) :-
    ingredient(Id, _, _, _, _, _, _, _, _, _, _).

% ==========================================
% 2. 配方营养加权求和
% ==========================================

calc_recipe_nutrition(Items, CalcProtein, CalcFat, CalcFiber, CalcAsh, Unknowns) :-
    calc_nutrition_items(Items, 0, 0, 0, 0, [], CalcProtein, CalcFat, CalcFiber, CalcAsh, Unknowns).

calc_nutrition_items([], Pro, Fat, Fib, Ash, Unk, Pro, Fat, Fib, Ash, Unk).
calc_nutrition_items([item(Id, Name, Pct, _) | Rest], ProAcc, FatAcc, FibAcc, AshAcc, UnkAcc,
                     ProOut, FatOut, FibOut, AshOut, UnkOut) :-
    ( has_nutrition_data(Id) ->
        ingredient_nutrient(Id, IngPro, IngFat, IngFib, IngAsh),
        ProContrib is Pct * IngPro / 100,
        FatContrib is Pct * IngFat / 100,
        FibContrib is Pct * IngFib / 100,
        AshContrib is Pct * IngAsh / 100,
        ProAcc2 is ProAcc + ProContrib,
        FatAcc2 is FatAcc + FatContrib,
        FibAcc2 is FibAcc + FibContrib,
        AshAcc2 is AshAcc + AshContrib,
        UnkAcc2 = UnkAcc
    ;
        % 无营养数据, 跳过但记录
        ProAcc2 = ProAcc, FatAcc2 = FatAcc, FibAcc2 = FibAcc, AshAcc2 = AshAcc,
        append(UnkAcc, [unknown(Id, Name)], UnkAcc2)
    ),
    calc_nutrition_items(Rest, ProAcc2, FatAcc2, FibAcc2, AshAcc2, UnkAcc2,
                         ProOut, FatOut, FibOut, AshOut, UnkOut).

append([], L, L).
append([H|T], L, [H|R]) :- append(T, L, R).

% ==========================================
% 3. 营养值校验报告
% ==========================================

% 偏差阈值: ±1% 绝对偏差视为容差
nutrition_deviation(Calculated, Declared, ok) :-
    Diff is abs(Calculated - Declared),
    Diff =< 1.0,
    !.
nutrition_deviation(Calculated, Declared, over) :-
    Calculated > Declared + 1.0,
    !.
nutrition_deviation(Calculated, Declared, under) :-
    Declared > Calculated + 1.0.

% 达标判定 (vs 目标)
nutrition_target_status(Calculated, MinTarget, ok) :-
    Calculated >= MinTarget - 0.5,   % 0.5% 容差
    !.
nutrition_target_status(Calculated, _, under).

% 上限类目标 (Fiber, Ash)
nutrition_max_status(Calculated, MaxTarget, ok) :-
    Calculated =< MaxTarget + 0.5,
    !.
nutrition_max_status(_, _, over).

validate_nutrition(recipe(Species, Stage, Items, Cost, DeclProtein, DeclFat, DeclFiber, DeclAsh),
                   NutritionReport) :-
    % 目标值
    species_nutrition(Species, Stage, TargetProtein, TargetFat, MaxFiber, MaxAsh),

    % 计算值
    calc_recipe_nutrition(Items, CalcProtein, CalcFat, CalcFiber, CalcAsh, Unknowns),

    % 声明 vs 计算偏差
    nutrition_deviation(CalcProtein, DeclProtein, DevPro),
    nutrition_deviation(CalcFat, DeclFat, DevFat),
    nutrition_deviation(CalcFiber, DeclFiber, DevFib),
    nutrition_deviation(CalcAsh, DeclAsh, DevAsh),

    % 计算 vs 目标
    nutrition_target_status(CalcProtein, TargetProtein, ProStat),
    nutrition_target_status(CalcFat, TargetFat, FatStat),
    nutrition_max_status(CalcFiber, MaxFiber, FibStat),
    nutrition_max_status(CalcAsh, MaxAsh, AshStat),

    % 分类
    findall(dev(Pro, Decl, Calc, D), (
        member((Pro, Decl, Calc, D), [
            ('蛋白质', DeclProtein, CalcProtein, DevPro),
            ('粗脂肪', DeclFat, CalcFat, DevFat),
            ('粗纤维', DeclFiber, CalcFiber, DevFib),
            ('粗灰分', DeclAsh, CalcAsh, DevAsh)
        ]),
        D \= ok
    ), Deviations),

    findall(short(Target, Calc, Target), (
        member((Target, Calc, Target), [
            (ProStat, CalcProtein, TargetProtein),
            (FatStat, CalcFat, TargetFat)
        ]),
        Target \= ok
    ), Shortfalls),

    findall(excess(Target, Calc, Max), (
        member((Target, Calc, Max), [
            (FibStat, CalcFiber, MaxFiber),
            (AshStat, CalcAsh, MaxAsh)
        ]),
        Target \= ok
    ), Excesses),

    append(Shortfalls, Excesses, AllTargetIssues),

    ( Deviations = [], AllTargetIssues = [] ->
        NutritionReport = nutrition_report(passed,
            CalcProtein, CalcFat, CalcFiber, CalcAsh,
            DeclProtein, DeclFat, DeclFiber, DeclAsh,
            TargetProtein, TargetFat, MaxFiber, MaxAsh,
            Unknowns, [], [])
    ;
        NutritionReport = nutrition_report(failed,
            CalcProtein, CalcFat, CalcFiber, CalcAsh,
            DeclProtein, DeclFat, DeclFiber, DeclAsh,
            TargetProtein, TargetFat, MaxFiber, MaxAsh,
            Unknowns, Deviations, AllTargetIssues)
    ).

% ==========================================
% 4. 便捷入口
% ==========================================

print_nutrition_report(nutrition_report(Status, CP, CFat, CFib, CAsh,
                                        DP, DFat, DFib, DAsh,
                                        TP, TFat, MFib, MAsh,
                                        Unk, Devs, Issues)) :-
    write('=== 营养值校验 ==='), nl,
    write('计算值: 蛋白'), write(CP), write('%  脂肪'), write(CFat),
    write('%  纤维'), write(CFib), write('%  灰分'), write(CAsh), write('%'), nl,
    write('声明值: 蛋白'), write(DP), write('%  脂肪'), write(DFat),
    write('%  纤维'), write(DFib), write('%  灰分'), write(DAsh), write('%'), nl,
    write('目标值: 蛋白≥'), write(TP), write('%  脂肪≥'), write(TFat),
    write('%  纤维≤'), write(MFib), write('%  灰分≤'), write(MAsh), write('%'), nl,
    ( Unk = [] -> true ; (write('缺失数据: '), write(Unk), nl) ),
    ( Devs = [] -> write('声明-计算偏差: 无'), nl
    ; (write('声明-计算偏差: '), write(Devs), nl) ),
    ( Issues = [] -> write('目标达标: 全部 OK'), nl
    ; (write('目标不达标: '), write(Issues), nl) ),
    ( Status = passed -> write('结果: PASS'), nl
    ; write('结果: FAIL'), nl ).

% 虾配方校验
validate_nutrition_shrimp :-
    shrimp_recipe_a(R), validate_nutrition(R, NR), print_nutrition_report(NR), nl,
    shrimp_recipe_b(R2), validate_nutrition(R2, NR2), print_nutrition_report(NR2), nl,
    shrimp_recipe_c(R3), validate_nutrition(R3, NR3), print_nutrition_report(NR3).

% 鳗鱼配方校验
validate_nutrition_eel :-
    eel_recipe_a(R), validate_nutrition(R, NR), print_nutrition_report(NR), nl,
    eel_recipe_b(R2), validate_nutrition(R2, NR2), print_nutrition_report(NR2), nl,
    eel_recipe_c(R3), validate_nutrition(R3, NR3), print_nutrition_report(NR3).

validate_nutrition_all :-
    current_predicate(shrimp_recipe_a/1) -> validate_nutrition_shrimp ; true,
    nl,
    current_predicate(eel_recipe_a/1) -> validate_nutrition_eel ; true.
