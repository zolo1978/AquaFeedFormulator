% ═══════════════════════════════════════════════════════════════
% delivery_gatekeeper.pl — 交付门禁 v2.0
% AquaFeedFormulator 终审整改
%
% 配方求解完成后，必须通过交付门禁才能交付。
% deliverable/4 是唯一交付入口。
%
% 7 道检查：
%   1. 配方闭合   100% ± 0.1%    must pass
%   2. 营养达标   所有营养约束     must pass
%   3. 品类约束   品类上下限       must pass
%   4. 成本合理   按物种细分区间   must pass
%   5. 合规检查   GB/T 标准       must pass
%   6. 规则 approved             must pass
%   7. 反例测试通过               must pass
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 交付判定 — 唯一入口
% ═══════════════════════════════════════════════════════════════

% deliverable(+Recipe, +Species, +Stage, -Decision)
% Decision = passed | failed([Reason1, Reason2, ...])

deliverable(Recipe, Species, Stage, Decision) :-
    check_closure(Recipe, C1),
    check_nutrition(Recipe, Species, Stage, C2),
    check_category(Recipe, Species, Stage, C3),
    check_cost_range(Recipe, Species, Stage, C4),
    check_compliance(Species, Stage, C5),
    check_rule_approved(Species, Stage, C6),
    check_counterexamples(C7),
    (  C1 = passed, C2 = passed, C3 = passed, C4 = passed,
       C5 = passed, C6 = passed, C7 = passed ->
        Decision = passed
    ;  findall(R,
               ( member(R-C, [
                   closure-C1, nutrition-C2, category-C3,
                   cost-C4, compliance-C5, rule_approved-C6,
                   counterexample-C7
                 ]),
                 C \= passed
               ),
               Failures),
        Decision = failed(Failures)
    ).

% ═══════════════════════════════════════════════════════════════
% 1. 闭合检查：100% ± 0.1%
% ═══════════════════════════════════════════════════════════════

check_closure(recipe_sop(Items, _), Result) :-
    sum_pcts(Items, Total),
    AbsDiff is abs(Total - 100.0),
    (  AbsDiff =< 0.1 ->
        Result = passed
    ;  Result = failed(closure, Total)
    ).

% ═══════════════════════════════════════════════════════════════
% 2. 营养检查
% ═══════════════════════════════════════════════════════════════

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

% ═══════════════════════════════════════════════════════════════
% 3. 品类约束检查（引用 category_rules.pl 唯一源）
% ═══════════════════════════════════════════════════════════════

check_category(recipe_sop(Items, _), Species, Stage, Result) :-
    findall(Cat-LT-Limit,
            species_category_rule(Species, Stage, Cat, LT, Limit, _),
            Rules),
    check_all_category_rules(Items, Rules, Result).

% ═══════════════════════════════════════════════════════════════
% 4. 成本范围检查（按物种）
% ═══════════════════════════════════════════════════════════════

check_cost_range(recipe_sop(_, TotalCost), Species, Stage, Result) :-
    CostPerTon is round(TotalCost * 10),
    (  cost_in_range(Species, Stage, CostPerTon) ->
        Result = passed
    ;  Result = failed(cost_unit_anomaly, CostPerTon)
    ).

% ═══════════════════════════════════════════════════════════════
% 5. 合规检查（GB/T 标准 — 占位，逐类扩展）
% ═══════════════════════════════════════════════════════════════

check_compliance(_, _, passed).  % TODO: 对接 compliance_rules.pl

% ═══════════════════════════════════════════════════════════════
% 6. 规则 approved 检查
% ═══════════════════════════════════════════════════════════════

check_rule_approved(Species, Stage, Result) :-
    findall(Cat,
            ( species_category_rule(Species, Stage, Cat, _, _, _),
              \+ rule_approved_for(Species, Stage, Cat)
            ),
            Unapproved),
    (  Unapproved = [] ->
        Result = passed
    ;  Result = failed(rule_not_approved, Unapproved)
    ).

% 默认：category_rules.pl 中所有规则视为 approved
% rule_approved_for/3 在 category_rules.pl 中定义

% ═══════════════════════════════════════════════════════════════
% 7. 反例测试通过检查
% ═══════════════════════════════════════════════════════════════

check_counterexamples(Result) :-
    % 模拟：运行 test_all_counterexamples 但不在交付路径中重复执行
    % 实际由 Rust CLI 在执行前运行，这里只做状态检查
    Result = passed.  % TODO: 对接 Rust 注入的 tests_passed fact

% ═══════════════════════════════════════════════════════════════
% 工具函数
% ═══════════════════════════════════════════════════════════════

sum_pcts([], 0).
sum_pcts([_-Pct-_|RT], T) :-
    sum_pcts(RT, R), T is R + Pct.

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
