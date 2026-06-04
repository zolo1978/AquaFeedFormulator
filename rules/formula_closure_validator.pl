% ============================================================
% formula_closure_validator.pl — 配方闭合校验 + 品类约束
% AquaFeedFormulator 核心规则模块 6/9
% ============================================================
%
% 功能:
%   1. 配方百分比闭合校验 (所有原料之和 = 100% ± 容差)
%   2. 品类级用量上限校验 (淀粉类总和、动物蛋白下限等)
%   3. 向 compliance_checker 输出 ClosureReport
%
% 背景:
%   ChatGPT 评审发现 AquaFeedFormulator v2 三个方案均不闭合:
%   方案 A: 100.20%  |  方案 B: 97.40%  |  方案 C: 95.40%
%   根因: formulation_solver.pl 只校验主料总和,未校验全配方闭合
%
% 谓词:
%   validate_formula_closure(+Recipe, -ClosureReport)
%   check_category_limits(+Species, +Stage, +Items, -CategoryViolations)
%
% 兼容性: scryper-prolog v0.10
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
% 3. 品类定义与规则
% ==========================================

% ==== 品类: 淀粉类 (包括所有含高淀粉的原料) ====
starch_ingredient(tapioca_starch).
starch_ingredient(wheat_flour).
starch_ingredient(wheat).
starch_ingredient(corn).
starch_ingredient(sorghum).
starch_ingredient(wheat_middlings).

% ==== 品类: 动物蛋白 ====
animal_protein_ingredient(Id) :-
    ingredient(Id, _, animal_protein, _, _, _, _, _, _, _, _).

% ==== 品类: 植物蛋白 ====
plant_protein_ingredient(Id) :-
    ingredient(Id, _, plant_protein, _, _, _, _, _, _, _, _).

% ==== 品类: 油脂类 ====
oil_ingredient(Id) :-
    ingredient(Id, _, oil, _, _, _, _, _, _, _, _).

% ==== 品类: 磷源 ====
phosphorus_ingredient(dicalcium_phosphate).
phosphorus_ingredient(monocalcium_phosphate).

% ==========================================
% 4. 物种×阶段 品类约束规则
% ==========================================

% ---- 鳗鱼 (eel) ----
%
% 鳗鱼是典型肉食性鱼类, 对:
% - 淀粉耐受性低 (消化系统对碳水化合物利用差)
% - 动物蛋白需求高
% - 诱食性要求高

% 鳗鱼通用约束 (所有阶段)
species_category_rule(japanese_eel, _, starch, max, 25.0,
    '淀粉类总和超过25%: 鳗鱼对碳水化合物消化差, 高淀粉导致摄食率下降/FCR恶化/粪便散').

species_category_rule(japanese_eel, _, animal_protein, min, 35.0,
    '动物蛋白占比低于35%: 鳗鱼为肉食性, 动物蛋白不足影响生长和成活率').

species_category_rule(japanese_eel, _, oil, max, 8.0,
    '油脂总和超过8%: 高脂增加肝胆负担, 且可能氧化酸败').

species_category_rule(japanese_eel, _, oil, min, 3.0,
    '油脂总和低于3%: 鳗鱼饲料需足够能量密度, 脂肪不足影响蛋白效率').

% 白仔鳗/玻璃鳗阶段 (开口期)
species_category_rule(japanese_eel, glass_eel, starch, max, 18.0,
    '白仔鳗淀粉应≤18%: 开口期消化系统发育不全, 高淀粉更敏感').

species_category_rule(japanese_eel, glass_eel, animal_protein, min, 45.0,
    '白仔鳗动物蛋白应≥45%: 开口期需高质量蛋白源保障成活率').

% 黑仔鳗/幼鳗阶段
species_category_rule(japanese_eel, juvenile, starch, max, 22.0,
    '幼鳗淀粉应≤22%: 消化系统仍对高淀粉敏感').

species_category_rule(japanese_eel, juvenile, animal_protein, min, 40.0,
    '幼鳗动物蛋白应≥40%: 快速生长期需充足动物蛋白').

% 养成鳗阶段
species_category_rule(japanese_eel, grower, starch, max, 28.0,
    '养成鳗淀粉应≤28%: 可适度增加碳水化合物, 但超过30%风险高(FCR可能从1.4升至1.8)').

species_category_rule(japanese_eel, grower, animal_protein, min, 30.0,
    '养成鳗动物蛋白应≥30%: 后期可适度增加植物蛋白替代').

% ---- 虾类 (white_shrimp) ----
species_category_rule(white_shrimp, _, starch, max, 20.0,
    '虾料淀粉应≤20%: 虾对淀粉消化能力有限').

species_category_rule(white_shrimp, _, animal_protein, min, 25.0,
    '虾料动物蛋白应≥25%').

% ---- 通用 (其他水产) ----
species_category_rule(_, _, starch, max, 30.0,
    '淀粉总和超过30%: 大部分水产动物碳水化合物利用有限, 注意FCR风险').

species_category_rule(_, _, animal_protein, min, 20.0,
    '动物蛋白占比低于20%: 多数经济水产动物需要一定量动物蛋白').

% ==========================================
% 5. 品类求和辅助函数
% ==========================================

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

sum_category_percent(phosphorus, Items, TotalP) :-
    % 磷源贡献的总磷百分比
    findall(PContrib, (
        member(item(Id, _, Pct, _), Items),
        phosphorus_ingredient(Id),
        (
            Id == dicalcium_phosphate -> PContrib is Pct * 0.18
            ; Id == monocalcium_phosphate -> PContrib is Pct * 0.22
            ; PContrib = 0
        )
    ), PContribs),
    sum_list(PContribs, TotalP).

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
