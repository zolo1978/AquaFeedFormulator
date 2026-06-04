% ═══════════════════════════════════════════════════════════════
% delivery_gatekeeper.pl — 交付门禁
% AquaFeedFormulator P0-3
%
% 配方求解完成后，判定是否允许交付。
% 所有检查项必须通过才能 deliver。
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 交付判定
% ═══════════════════════════════════════════════════════════════

% deliverable(+Recipe, +Species, +Stage, -Decision)
% Decision = passed | failed(Reason)

deliverable(Recipe, Species, Stage, Decision) :-
    check_closure(Recipe, C1),
    check_nutrition(Recipe, Species, Stage, C2),
    check_category(Recipe, Species, Stage, C3),
    check_cost_range(Recipe, Species, Stage, C4),
    (  C1 = passed, C2 = passed, C3 = passed, C4 = passed ->
        Decision = passed
    ;  findall(R,
               ( member(R-C, [closure-C1, nutrition-C2, category-C3, cost-C4]),
                 C \= passed
               ),
               Failures),
        Decision = failed(Failures)
    ).

% ═══════════════════════════════════════════════════════════════
% 单项检查
% ═══════════════════════════════════════════════════════════════

% 闭合检查：100% ± 0.1%
check_closure(recipe_sop(Items, _), Result) :-
    sum_pcts(Items, Total),
    AbsDiff is abs(Total - 100.0),
    (  AbsDiff =< 0.1 ->
        Result = passed
    ;  Result = failed(closure, Total)
    ).

% 营养检查
check_nutrition(recipe_sop(Items, _), Species, Stage, Result) :-
    species_nutrition(Species, Stage, TgtPro, TgtFat, MaxFib, MaxAsh),
    calc_recipe_nutrition(Items, ActPro, ActFat, ActFib, ActAsh),
    (  ActPro >= TgtPro, ActFat >= TgtFat,
       ActFib =< MaxFib, ActAsh =< MaxAsh ->
        Result = passed
    ;  Result = failed(nutrition,
               [protein(aim=TgtPro, actual=ActPro),
                fat(aim=TgtFat, actual=ActFat),
                fiber(aim=MaxFib, actual=ActFib),
                ash(aim=MaxAsh, actual=ActAsh)])
    ).

% 品类检查
check_category(recipe_sop(Items, _), Species, Stage, Result) :-
    findall(Cat-LT-Limit,
            species_category_rule(Species, Stage, Cat, LT, Limit, _),
            Rules),
    check_all_category_rules(Items, Rules, Result).

% 成本范围检查（按物种）
check_cost_range(recipe_sop(_, TotalCost), Species, Stage, Result) :-
    CostPerTon is round(TotalCost * 10),
    (  cost_in_range(Species, Stage, CostPerTon) ->
        Result = passed
    ;  Result = failed(cost_unit_anomaly, CostPerTon)
    ).

% ═══════════════════════════════════════════════════════════════
% 工具函数
% ═══════════════════════════════════════════════════════════════

sum_pcts([], 0).
sum_pcts([_-Pct-_|RT], T) :-
    sum_pcts(RT, R), T is R + Pct.

% 计算配方实际营养值（权重平均）
calc_recipe_nutrition(Items, Pro, Fat, Fib, Ash) :-
    wavg_nut(Items, 0, 0, 0, 0, Pro, Fat, Fib, Ash).

wavg_nut([], SP, SF, SFi, SA, Pro, Fat, Fib, Ash) :-
    Pro is SP, Fat is SF, Fib is SFi, Ash is SA.
wavg_nut([Id-Pct-_|RT], SP0, SF0, SFi0, SA0, Pro, Fat, Fib, Ash) :-
    ingredient(Id, _, _, IngPro, IngFat, IngFib, IngAsh, _, _, _, _),
    SP1 is SP0 + Pct * IngPro / 100,
    SF1 is SF0 + Pct * IngFat / 100,
    SFi1 is SFi0 + Pct * IngFib / 100,
    SA1 is SA0 + Pct * IngAsh / 100,
    wavg_nut(RT, SP1, SF1, SFi1, SA1, Pro, Fat, Fib, Ash).

% 逐条检查品类规则
check_all_category_rules(_, [], passed).
check_all_category_rules(Items, [Cat-min-Limit|RT], Result) :-
    cat_sum(Items, Cat, Actual),
    (  Actual >= Limit ->
        check_all_category_rules(Items, RT, Result)
    ;  Result = failed(category_min, Cat, Limit, Actual)
    ).
check_all_category_rules(Items, [Cat-max-Limit|RT], Result) :-
    cat_sum(Items, Cat, Actual),
    (  Actual =< Limit ->
        check_all_category_rules(Items, RT, Result)
    ;  Result = failed(category_max, Cat, Limit, Actual)
    ).

cat_sum(Items, Cat, Total) :-
    findall(Pct,
            ( member(Id-Pct-_, Items),
              category_check(Cat, Id)
            ),
            Pcts),
    sum_list_custom(Pcts, Total).

sum_list_custom([], 0).
sum_list_custom([X|Xs], S) :-
    sum_list_custom(Xs, S0), S is S0 + X.
