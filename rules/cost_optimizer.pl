% ============================================================
% cost_optimizer.pl — 配方成本优化器
% AquaFeedFormulator 核心规则模块 5/5
% ============================================================
%
% 功能:
%   1. 原料替换建议 (缺货/涨价时自动推荐替代)
%   2. 多方案对比生成 (最低成本 vs 最佳营养 vs 平衡方案)
%   3. 灵敏度分析 (某原料价格变化对总成本的影响)
%   4. 季节性价格调整策略
%
% 谓词:
%   suggest_substitute(+MissingIngredient, -Alternatives)
%   multi_scenario_solve(+Species, +Stage, +Budget, -Scenarios)
%   price_sensitivity(+Recipe, +Ingredient, +DeltaPercent, -CostImpact)
%
% 兼容性: scryer-prolog v0.10
%   - sum_list/2: 手动实现 (非 ISO 内建)
%   - predsort/3 替换为手动插入排序 (SWI 专有)
% ============================================================

% ==== scryer-prolog 兼容: 工具谓词 ====

sum_list([], 0).
sum_list([H|T], Sum) :- sum_list(T, Rest), Sum is H + Rest.

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

% 替代品按价格差排序 (predsort 替代)
sort_alternatives_by_price(Unsorted, Sorted) :-
    insertion_sort_alt(Unsorted, Sorted).

insertion_sort_alt([], []).
insertion_sort_alt([X|Xs], Sorted) :-
    insertion_sort_alt(Xs, Rest),
    insert_alt(X, Rest, Sorted).

insert_alt(X, [], [X]).
insert_alt(alt(A,B,C,D1,E), [alt(_,_,_,D2,_)|Ys], [alt(A,B,C,D1,E)|Ys]) :-
    D1 =< D2,
    !.
insert_alt(X, [Y|Ys], [Y|Rest]) :-
    insert_alt(X, Ys, Rest).

% ==========================================
% 1. 原料替换规则
% ==========================================

% 替换规则: substitute(Original, Substitute, MaxSubRatio, Notes)
% MaxSubRatio: 替代品最多替代原品的比例

% 鱼粉替换
substitute(fish_meal_peru_65, fish_meal_domestic_60, 1.0,
    '国产鱼粉蛋白略低(60% vs 65%)，需略微增加用量以维持蛋白水平').
substitute(fish_meal_peru_65, poultry_meal, 0.5,
    '鸡肉粉可部分替代鱼粉, 但需补充赖氨酸和蛋氨酸').
substitute(fish_meal_peru_65, fermented_soybean_meal, 0.3,
    '发酵豆粕可少量替代鱼粉, 配合氨基酸补充效果更佳').
substitute(fish_meal_domestic_60, poultry_meal, 0.5,
    '鸡肉粉蛋白水平相近, 但消化率略低').

% 豆粕替换
substitute(soybean_meal_43, soybean_meal_46, 1.0,
    '高蛋白豆粕直接替换, 按蛋白折算比例: 43/46 = 0.935').
substitute(soybean_meal_43, fermented_soybean_meal, 0.8,
    '发酵豆粕抗营养因子更低, 适口性更好').
substitute(soybean_meal_43, rapeseed_meal_regular, 0.4,
    '菜粕蛋白较低且含硫苷, 替代比例不宜超过40%').
substitute(soybean_meal_43, peanut_meal, 0.6,
    '花生粕蛋白较高但赖氨酸低, 注意氨基酸平衡').

% 菜粕替换
substitute(rapeseed_meal_regular, canola_meal, 1.0,
    '双低菜粕硫苷含量低, 可完全替代普通菜粕, 且用量上限更高').
substitute(rapeseed_meal_regular, cottonseed_meal_regular, 0.7,
    '棉粕需注意游离棉酚, 替代上限70%').

% 棉粕替换
substitute(cottonseed_meal_regular, cottonseed_meal_dephenol, 1.0,
    '脱酚棉粕更安全, 可完全替代').
substitute(cottonseed_meal_regular, soybean_meal_43, 0.8,
    '豆粕替代棉粕, 成本上升但安全性更好').

% 能量原料替换
substitute(corn, wheat, 1.0,
    '小麦与玉米能量接近, 当玉米价格高于小麦时可替换').
substitute(corn, sorghum, 0.8,
    '高粱可部分替代玉米, 但单宁含量需注意').
substitute(wheat, corn, 1.0,
    '玉米替代小麦, 能量略低但成本更低').
substitute(wheat_flour, tapioca_starch, 0.5,
    '木薯淀粉粘合性好, 虾料中可部分替代面粉').

% 油类替换
substitute(fish_oil, soybean_oil, 0.5,
    '豆油替代鱼油, omega-3含量降低, 需评估对水产品质的影响').
substitute(fish_oil, rapeseed_oil, 0.5,
    '菜籽油替代鱼油, 脂肪酸组成不同').

% ==========================================
% 2. 原料替换建议
% ==========================================

% 查找替代品
suggest_substitute(MissingId, Alternatives) :-
    findall(
        alt(SubId, SubName, MaxRatio, PriceDiff, Notes),
        (
            substitute(MissingId, SubId, MaxRatio, Notes),
            ingredient(SubId, SubName, _, _, _, _, _, _, Price, _, _),
            ingredient(MissingId, _, _, _, _, _, _, _, OrigPrice, _, _),
            PriceDiff is Price - OrigPrice
        ),
        Unsorted
    ),
    insertion_sort_alt(Unsorted, Alternatives).

% ==========================================
% 3. 多方案对比生成
% ==========================================

% 生成 3 个对比方案
% - minimize_cost: 只追求最低成本 (tight budget)
% - maximize_nutrition: 追求最佳营养 (loose constraint)
% - balanced: 平衡方案 (default)
multi_scenario_solve(Species, Stage, Budget, Scenarios) :-
    % 场景 1: 最低成本模式
    EconomicBudget is Budget,
    solve_recipe_heuristic(Species, Stage, EconomicBudget, RecipeEcon),

    % 场景 2: 最佳营养模式 (预算放宽 20%)
    PremiumBudget is Budget * 1.2,
    solve_recipe_heuristic(Species, Stage, PremiumBudget, RecipePrem),

    % 场景 3: 平衡模式 (预算放宽 10%)
    BalancedBudget is Budget * 1.1,
    solve_recipe_heuristic(Species, Stage, BalancedBudget, RecipeBal),

    Scenarios = scenarios(RecipeEcon, RecipePrem, RecipeBal).

% ==========================================
% 4. 灵敏度分析
% ==========================================

% 分析某原料价格变化对总成本的影响
price_sensitivity(Recipe, TargetId, DeltaPercent, ImpactReport) :-
    Recipe = recipe(Species, Stage, Items, BaseCost, _, _, _, _),

    % 找到该原料
    member(item(TargetId, TargetName, TargetPct, TargetCost), Items),
    !,

    % 计算新成本
    ingredient(TargetId, _, _, _, _, _, _, _, BasePrice, _, _),
    NewPrice is BasePrice * (1 + DeltaPercent / 100),
    NewIngredientCost is NewPrice * TargetPct / 100.0 * 10,
    OldIngredientCost is BasePrice * TargetPct / 100.0 * 10,

    % 影响计算
    AbsoluteChange is NewIngredientCost - OldIngredientCost,
    NewTotalCost is BaseCost + AbsoluteChange,
    PercentChange is (NewTotalCost - BaseCost) / BaseCost * 100,

    ImpactReport = sensitivity_report(
        ingredient(TargetId, TargetName, TargetPct),
        BasePrice, NewPrice,
        OldIngredientCost, NewIngredientCost,
        BaseCost, NewTotalCost,
        PercentChange
    ).

price_sensitivity(_, _, _, sensitivity_report(not_found, 0, 0, 0, 0, 0, 0, 0)).

% ==========================================
% 5. 季节性调整建议
% ==========================================

% 季节影响规则
% season_adjustment(Season, Species, AdjustmentType, AdjustmentValue)

% 夏季: 水温高 → 降低蛋白 (减少代谢热), 增加油脂 (能量密度)
season_adjustment(summer, _, protein, -2).    % 蛋白降低 2%
season_adjustment(summer, _, fat, 1).         % 脂肪增加 1%
season_adjustment(summer, _, vitamin_c, 50).  % 维生素C 增加 50mg/kg (抗热应激)

% 冬季: 水温低 → 可降低蛋白, 但越冬前需提高能量
season_adjustment(winter, _, protein, -1).
season_adjustment(winter, _, fat, 2).

% 春季: 恢复期 → 提高蛋白 + 维生素
season_adjustment(spring, _, protein, 2).
season_adjustment(spring, _, fat, 1).
season_adjustment(spring, _, vitamin_c, 30).

% 秋季: 育肥期 → 高能量
season_adjustment(autumn, _, protein, 1).
season_adjustment(autumn, _, fat, 2).

% 获取季节调整后的营养目标
adjusted_nutrition(Species, Stage, Season, AdjProtein, AdjFat, Fiber, Ash) :-
    species_nutrition(Species, Stage, Protein, Fat, Fiber, Ash),
    findall(Padj, season_adjustment(Season, _, protein, Padj), PAdjusts),
    sum_list(PAdjusts, PSum),
    AdjProtein is Protein + PSum,
    findall(Fadj, season_adjustment(Season, _, fat, Fadj), FAdjusts),
    sum_list(FAdjusts, FSum),
    AdjFat is Fat + FSum.

% ==========================================
% 6. 原料价格趋势与建议
% ==========================================

% 原料价格区间 (低价/正常/高价)
price_zone(Price, LowThreshold, HighThreshold, Zone) :-
    (
        Price =< LowThreshold -> Zone = cheap
        ; Price >= HighThreshold -> Zone = expensive
        ; Zone = normal
    ).

% 基于价格区间给出策略建议
buy_strategy(fish_meal_peru_65, cheap,
    '鱼粉价格低位, 建议适当增加库存, 可提高配方中鱼粉占比3-5%').
buy_strategy(fish_meal_peru_65, expensive,
    '鱼粉价格高位, 建议用鸡肉粉或发酵豆粕替代部分鱼粉, 降低配方鱼粉占比5-10%').
buy_strategy(soybean_meal_43, cheap,
    '豆粕低位, 可适当增加植物蛋白占比, 降低鱼粉依赖').
buy_strategy(soybean_meal_43, expensive,
    '豆粕高位, 建议增加菜粕/棉粕/DDGS用量, 配合氨基酸补充').
buy_strategy(corn, expensive,
    '玉米价格高, 建议用小麦替代, 当前小麦/玉米比价有利').
buy_strategy(corn, cheap,
    '玉米低价, 能量原料以玉米为主, 可降低小麦用量').

% 综合采购建议
get_procurement_advice(AdviceList) :-
    findall(advice(Id, Name, Strategy), (
        ingredient(Id, Name, _, _, _, _, _, _, Price, _, _),
        price_zone(Price, 2.0, 6.0, Zone),
        Zone \= normal,
        buy_strategy(Id, Zone, Strategy)
    ), AdviceList).
