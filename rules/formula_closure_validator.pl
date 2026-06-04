% ============================================================
% formula_closure_validator.pl — 配方闭合校验
% AquaFeedFormulator
%
% 功能:
%   1. 配方百分比闭合校验 (所有原料之和 = 100% ± 容差)
%   2. 品类级用量约束检查 (引用 category_rules.pl — 唯一源)
%
% ★ 品类约束规则统一在 category_rules.pl 定义，本文件只调用。
% ============================================================

% ==== scryper-prolog 兼容: 工具谓词 ====

sum_list([], 0).
sum_list([H|T], Sum) :- sum_list(T, Rest), Sum is H + Rest.

append([], L, L).
append([H|T], L, [H|R]) :- append(T, L, R).

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

% ==========================================
% 1. 配方闭合校验
% ==========================================

% 主入口: 校验整个配方
validate_formula_closure(recipe(Species, Stage, Items, Cost, Protein, Fat, Fiber, Ash),
                         ClosureReport) :-
    % 1.1 计算所有原料百分比之和
    sum_item_percents(Items, TotalPct),
    % 1.2 判断闭合状态
    closure_status(TotalPct, 100.0, Status, Deviation),
    % 1.3 品类约束检查
    check_category_limits(Species, Stage, Items, CategoryViolations),
    % 1.4 合并报告
    (
        Status = ok, CategoryViolations = [] ->
            ClosureReport = closure_report(passed, TotalPct, [], [])
        ;
            % 构建闭合违规(如果有)
            (
                Status = ok ->
                    ClosureViolations = []
                ;
                    ClosureViolations = [closure_violation(Status, TotalPct, Deviation)]
            ),
            append(ClosureViolations, CategoryViolations, AllViolations),
            separate_closure_violations(AllViolations, Criticals, Warnings),
            ClosureReport = closure_report(failed, TotalPct, Criticals, Warnings)
    ).

% 汇总所有 item 的百分比
sum_item_percents([], 0).
sum_item_percents([item(_, _, Pct, _) | Rest], Total) :-
    sum_item_percents(Rest, RestSum),
    Total is RestSum + Pct.

% 闭合状态判定 (容差 ±0.1%)
closure_status(Total, Target, ok, 0) :-
    Diff is Total - Target,
    Diff >= -0.1,
    Diff =< 0.1,
    !.
closure_status(Total, Target, over, Deviation) :-
    Deviation is Total - Target,
    Deviation > 0.1,
    !.
closure_status(Total, Target, under, Deviation) :-
    Deviation is Target - Total,
    Deviation > 0.1.

% 违规项分类
separate_closure_violations([], [], []).
separate_closure_violations([V | Rest], [V | Crits], Warns) :-
    is_critical_closure(V),
    !,
    separate_closure_violations(Rest, Crits, Warns).
separate_closure_violations([V | Rest], Crits, [V | Warns]) :-
    separate_closure_violations(Rest, Crits, Warns).

% 闭合违规为 CRITICAL
is_critical_closure(closure_violation(_, _, _)).
% 品类上限违规(max)为 CRITICAL
is_critical_closure(category_violation(max, _, _, _, _)).
% 品类下限违规(min)为 HIGH (非致命但重要)
is_critical_closure(category_violation(min, _, _, _, _)).

% ==========================================
% 2. 品类级约束检查
% ==========================================

% 主入口: 按物种+阶段检查品类约束
check_category_limits(Species, Stage, Items, Violations) :-
    findall(V, (
        species_category_rule(Species, Stage, Category, LimitType, Limit, Description),
        check_single_category(Category, Items, LimitType, Limit, V, Description)
    ), Violations).

% 检查单个品类
check_single_category(Category, Items, LimitType, Limit,
                      category_violation(LimitType, Category, Actual, Limit, Description),
                      Description) :-
    sum_category_percent(Category, Items, Actual),
    (
        LimitType = max, Actual > Limit + 0.01
        ;
        LimitType = min, Actual < Limit - 0.01
    ).

% ==========================================
% 3. 品类映射 — 引用 category_rules.pl
% ==========================================
%
% 以下谓词在 category_rules.pl 中定义，本文件直接复用：
%   starch_ingredient/1, animal_protein_ingredient/1,
%   plant_protein_ingredient/1, oil_ingredient/1,
%   species_category_rule/6
%
% 品类求和辅助函数
sum_category_percent(starch, Items, Total) :-
    findall(Pct, (
        member(item(Id, _, Pct, _), Items),
        starch_ingredient(Id)
    ), Pcts),
    sum_list(Pcts, Total).

sum_category_percent(animal_protein, Items, Total) :-
    findall(Pct, (
        member(item(Id, _, Pct, _), Items),
        animal_protein_ingredient(Id)
    ), Pcts),
    sum_list(Pcts, Total).

sum_category_percent(plant_protein, Items, Total) :-
    findall(Pct, (
        member(item(Id, _, Pct, _), Items),
        plant_protein_ingredient(Id)
    ), Pcts),
    sum_list(Pcts, Total).

sum_category_percent(oil, Items, Total) :-
    findall(Pct, (
        member(item(Id, _, Pct, _), Items),
        oil_ingredient(Id)
    ), Pcts),
    sum_list(Pcts, Total).

% ==========================================
% 6. 修复建议生成
% ==========================================

% 对不闭合的配方给出修复方向
suggest_closure_fix(over, Deviation, Items, Suggestion) :-
    findall(Item, (
        member(item(Id, Name, Pct, _), Items),
        Pct > Deviation    % 足够大的单项才建议削减
    ), Candidates),
    Suggestion = fix_suggestion(
        '配方总和超标',
        '建议从以下占比较大的原料中各削减部分比例',
        Candidates
    ).

suggest_closure_fix(under, Deviation, Items, Suggestion) :-
    % 缺的比例建议补足到淀粉类或直接加水
    findall(item(Id, Name, _, _), (
        member(item(Id, Name, _, _), Items),
        starch_ingredient(Id)
    ), StarchCandidates),
    Suggestion = fix_suggestion(
        '配方总和不足',
        '建议适当增加淀粉类原料比例, 或补充惰性填充剂(如沸石粉)至100%',
        StarchCandidates
    ).
