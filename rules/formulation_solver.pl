% ============================================================
% formulation_solver.pl — 配方约束求解引擎
% AquaFeedFormulator 核心规则模块 3/5
% ============================================================
%
% 求解策略:
%   Phase 1: 加载营养目标 + 原料候选集
%   Phase 2: 生成配比组合 (generate-and-test with branch-and-bound)
%   Phase 3: 约束校验 (营养达标 + 用量范围 + 总和=100)
%   Phase 4: 成本优化 (在可行解中选最低成本)
%
% 核心谓词:
%   solve_recipe(+Species, +Stage, +BudgetYuanPerTon, -Recipe)
%
% Recipe 结构:
%   recipe([
%       ingredient_percent(Id, Name, Percent, CostContribution),
%       ...
%   ], TotalCost, ProteinCalculated, FatCalculated, ...)
% ============================================================

% scryer-prolog 兼容: 手动实现 lists 和基本算术
% 不使用 SWI-Prolog 特有的 library(lists)/library(clpfd)

% sum_list/2: 列表求和
sum_list([], 0).
sum_list([H|T], Sum) :-
    sum_list(T, Rest),
    Sum is H + Rest.

% ==========================================
% Phase 1: 约束生成
% ==========================================

% 求解入口
solve_recipe(Species, Stage, Budget, Recipe) :-
    % Step 1: 加载营养目标
    species_nutrition(Species, Stage, TargetProtein, TargetFat, MaxFiber, MaxAsh),

    % Step 2: 获取可用主料(排除添加剂)
    findall(Id, base_ingredient(Id), BaseIds),

    % Step 3: 添加剂固定用量(不参与优化)
    findall(Id-Pct, (
        additive_ingredient(Id),
        ingredient(Id, _, _, _, _, _, _, _, _, MaxAD, _),
        Pct is MaxAD        % 添加剂按推荐上限固定
    ), FixedAdditives),

    % Step 4: 计算添加剂总占比
    sum_additive_percent(FixedAdditives, AdditiveTotal),

    % Step 5: 主料可分配比例
    BaseRemaining is 100.0 - AdditiveTotal,

    % Step 6: 约束求解
    BudgetFloat is float(Budget),
    findall(
        candidate(Cost, BasePcts),
        (
            % 为每种主料分配比例 (0 到 MaxUsage%)
            assign_percents(BaseIds, BasePcts),
            % 主料总和 = BaseRemaining
            sum_percents(BasePcts, BaseRemaining),
            % 营养达标
            check_protein(BaseIds, BasePcts, TargetProtein, AdditiveTotal),
            check_fat(BaseIds, BasePcts, TargetFat, AdditiveTotal),
            check_fiber_max(BaseIds, BasePcts, MaxFiber, AdditiveTotal),
            check_ash_max(BaseIds, BasePcts, MaxAsh, AdditiveTotal),
            % 成本校验
            compute_cost(BaseIds, BasePcts, BaseCost),
            additive_cost(FixedAdditives, AdditiveCost),
            TotalCost is BaseCost + AdditiveCost,
            TotalCost =< BudgetFloat,
            % 收集结果
            Cost = TotalCost
        ),
        Candidates
    ),

    % Step 7: 选最低成本方案
    (
        Candidates = [] ->
            Recipe = no_solution_found
        ;
            sort_candidates_by_cost(Candidates, Sorted),
            Sorted = [candidate(BestCost, BestPcts) | _],
            build_recipe_output(Species, Stage, BestPcts, FixedAdditives,
                              BestCost, TargetProtein, TargetFat, Recipe)
    ).

% ==========================================
% Phase 2: 配比生成
% ==========================================

% 为主料生成配比 (离散步长 0.5%)
assign_percents([], []).
assign_percents([Id | Rest], [Pct | RestPcts]) :-
    ingredient(Id, _, _, _, _, _, _, _, _, Max, Min),
    % 在 [Min, Max] 范围内以 0.5% 步长尝试
    between_inclusive(Min, Max, 0.5, Pct),
    assign_percents(Rest, RestPcts).

% 辅助: 范围枚举
between_inclusive(Low, High, Step, Val) :-
    Val is Low,
    Val =< High.
between_inclusive(Low, High, Step, Val) :-
    Low1 is Low + Step,
    Low1 =< High,
    between_inclusive(Low1, High, Step, Val).

% ==========================================
% Phase 3: 约束校验
% ==========================================

% 总和校验
sum_percents(Pcts, Target) :-
    sum_list(Pcts, Sum),
    abs(Sum - Target) < 0.01.

% 粗蛋白达标校验
check_protein(BaseIds, BasePcts, TargetProtein, AdditiveTotal) :-
    protein_contribution(BaseIds, BasePcts, ProteinSum),
    % 添加剂蛋白贡献为 0
    CalculatedProtein is (ProteinSum / 100.0),
    CalculatedProtein >= TargetProtein - 0.5.   % 容差 0.5%

protein_contribution([], [], 0.0).
protein_contribution([Id | RestIds], [Pct | RestPcts], Total) :-
    ingredient(Id, _, _, Pro, _, _, _, _, _, _, _),
    protein_contribution(RestIds, RestPcts, RestTotal),
    Total is RestTotal + (Pro * Pct / 100.0).

% 粗脂肪达标校验
check_fat(BaseIds, BasePcts, TargetFat, AdditiveTotal) :-
    fat_contribution(BaseIds, BasePcts, FatSum),
    CalculatedFat is (FatSum / 100.0),
    CalculatedFat >= TargetFat - 0.5.

fat_contribution([], [], 0.0).
fat_contribution([Id | RestIds], [Pct | RestPcts], Total) :-
    ingredient(Id, _, _, _, Fat, _, _, _, _, _, _),
    fat_contribution(RestIds, RestPcts, RestTotal),
    Total is RestTotal + (Fat * Pct / 100.0).

% 粗纤维上限校验
check_fiber_max(BaseIds, BasePcts, MaxFiber, _) :-
    fiber_contribution(BaseIds, BasePcts, FiberSum),
    CalculatedFiber is (FiberSum / 100.0),
    CalculatedFiber =< MaxFiber + 0.5.

fiber_contribution([], [], 0.0).
fiber_contribution([Id | RestIds], [Pct | RestPcts], Total) :-
    ingredient(Id, _, _, _, _, Fib, _, _, _, _, _),
    fiber_contribution(RestIds, RestPcts, RestTotal),
    Total is RestTotal + (Fib * Pct / 100.0).

% 粗灰分上限校验
check_ash_max(BaseIds, BasePcts, MaxAsh, _) :-
    ash_contribution(BaseIds, BasePcts, AshSum),
    CalculatedAsh is (AshSum / 100.0),
    CalculatedAsh =< MaxAsh + 0.5.

ash_contribution([], [], 0.0).
ash_contribution([Id | RestIds], [Pct | RestPcts], Total) :-
    ingredient(Id, _, _, _, _, _, Ash, _, _, _, _),
    ash_contribution(RestIds, RestPcts, RestTotal),
    Total is RestTotal + (Ash * Pct / 100.0).

% ==========================================
% Phase 4: 成本计算与优化
% ==========================================

compute_cost([], [], 0.0).
compute_cost([Id | RestIds], [Pct | RestPcts], TotalCost) :-
    ingredient(Id, _, _, _, _, _, _, _, Price, _, _),
    compute_cost(RestIds, RestPcts, RestCost),
    TotalCost is RestCost + (Price * Pct / 100.0 * 10).  % ×10 转元/吨

% 添加剂固定成本
additive_cost([], 0.0).
additive_cost([_-Pct | Rest], Total) :-
    additive_cost(Rest, RestCost),
    Total is RestCost + (15.0 * Pct / 100.0 * 10).  % 固定均价 ~15 元/kg

% 添加剂总占比
sum_additive_percent([], 0.0).
sum_additive_percent([_-Pct | Rest], Total) :-
    sum_additive_percent(Rest, RestSum),
    Total is RestSum + Pct.

% include/3: 列表过滤 (scryer-prolog 不包含此 SWI 谓词)
include(Goal, [H|T], [H|Filtered]) :-
    call(Goal, H),
    !,
    include(Goal, T, Filtered).
include(Goal, [_|T], Filtered) :-
    include(Goal, T, Filtered).
include(_, [], []).

% 成本排序: 取最低成本在前 (选择排序)
sort_candidates_by_cost([], []).
sort_candidates_by_cost(Candidates, [Best|Rest]) :-
    find_min_cost(Candidates, Best, Remainder),
    sort_candidates_by_cost(Remainder, Rest).

find_min_cost([X], X, []).
find_min_cost([H | T], Min, Rest) :-
    find_min_cost(T, TailMin, TailRest),
    H = candidate(C1, _),
    TailMin = candidate(C2, _),
    ( C1 > C2 ->
        Min = TailMin,
        Rest = [H | TailRest]
    ;
        Min = H,
        Rest = [TailMin | TailRest]
    ).

% ==========================================
% 结果构建
% ==========================================

build_recipe_output(Species, Stage, BasePcts, FixedAdditives, TotalCost,
                    TargetProtein, TargetFat,
                    recipe(Species, Stage, Items, TotalCost,
                           CalcProtein, CalcFat, CalcFiber, CalcAsh)) :-
    % 获取主料 ID 列表
    findall(Id, base_ingredient(Id), BaseIds),

    % 构建主料条目
    build_ingredient_items(BaseIds, BasePcts, BaseItems),

    % 构建添加剂条目
    build_additive_items(FixedAdditives, AdditiveItems),

    % 合并
    append(BaseItems, AdditiveItems, AllItems),

    % 只保留 > 0 的条目
    include(nonzero_percent, AllItems, Items),

    % 计算实际营养值
    calc_nutrition(BaseIds, BasePcts, CalcProtein, CalcFat, CalcFiber, CalcAsh).

nonzero_percent(item(_, _, Pct, _)) :- Pct > 0.

build_ingredient_items([], [], []).
build_ingredient_items([Id | RIds], [Pct | RPcts], [Item | RItems]) :-
    ingredient(Id, Name, _, _, _, _, _, _, Price, _, _),
    Pct > 0,
    CostContrib is Price * Pct / 100.0 * 10,
    Item = item(Id, Name, Pct, CostContrib),
    build_ingredient_items(RIds, RPcts, RItems).
build_ingredient_items([_ | RIds], [_ | RPcts], RItems) :-
    build_ingredient_items(RIds, RPcts, RItems).

build_additive_items([], []).
build_additive_items([Id-Pct | RAdd], [Item | RItems]) :-
    ingredient(Id, Name, _, _, _, _, _, _, Price, _, _),
    CostContrib is Price * Pct / 100.0 * 10,
    Item = item(Id, Name, Pct, CostContrib),
    build_additive_items(RAdd, RItems).

calc_nutrition(BaseIds, BasePcts, Protein, Fat, Fiber, Ash) :-
    protein_contribution(BaseIds, BasePcts, ProteinRaw),
    fat_contribution(BaseIds, BasePcts, FatRaw),
    fiber_contribution(BaseIds, BasePcts, FiberRaw),
    ash_contribution(BaseIds, BasePcts, AshRaw),
    Protein is ProteinRaw / 100.0,
    Fat is FatRaw / 100.0,
    Fiber is FiberRaw / 100.0,
    Ash is AshRaw / 100.0.

% ==========================================
% 启发式求解 (快速模式)
% ==========================================
%
% 全量回溯在 30+ 种原料 × 0.5% 步长时搜索空间巨大。
% 启发式模式: 只对核心原料(鱼粉/豆粕等)进行回溯，
% 其余用量按经验固定或按比例分配。

% 快速求解入口 (推荐用于交互式场景)
solve_recipe_heuristic(Species, Stage, Budget, Recipe) :-
    species_nutrition(Species, Stage, TargetProtein, TargetFat, MaxFiber, MaxAsh),

    % 核心可变原料 (只有这几个参与搜索)
    CoreIngredients = [
        fish_meal_peru_65,
        fish_meal_domestic_60,
        soybean_meal_43,
        soybean_meal_46,
        rapeseed_meal_regular,
        cottonseed_meal_regular,
        corn_gluten_meal_60,
        corn_ddgs,
        wheat_middlings,
        wheat_flour,
        corn,
        wheat,
        rice_bran_fullfat,
        rice_bran_defatted
    ],

    % 固定用量原料 (不参与搜索)
    FixedIngredients = [
        dicalcium_phosphate-2.0,
        monocalcium_phosphate-1.5,
        limestone_powder-1.0,
        salt-0.3,
        premix_vitamin_aqua-1.0,
        premix_mineral_aqua-1.0,
        choline_chloride_50-0.3,
        vitamin_c_phosphate-0.05,
        antioxidant-0.03,
        mold_inhibitor-0.1,
        phytase-0.02
    ],

    % 油脂单独处理: 根据目标脂肪需求动态分配
    sum_fixed_percent(FixedIngredients, FixedTotal),
    OilBudget is min(5, max(2, TargetFat * 0.6)),  % 油脂占目标脂肪的 60%, 2-5%
    RemainingForBase is 100.0 - FixedTotal - OilBudget,

    BudgetFloat is float(Budget),
    findall(
        candidate(Cost, BasePcts, OilPct),
        (
            assign_heuristic_percents(CoreIngredients, BasePcts),
            sum_percents(BasePcts, RemainingForBase),
            between_inclusive(2.0, 5.0, 0.5, OilPct),
            check_protein_heuristic(CoreIngredients, BasePcts, OilPct, TargetProtein),
            check_fat_heuristic(CoreIngredients, BasePcts, OilPct, TargetFat),
            check_fiber_max(CoreIngredients, BasePcts, MaxFiber, 0),
            compute_cost(CoreIngredients, BasePcts, BaseCost),
            OilCost is 12.0 * OilPct / 100.0 * 10,
            FixedCost is 10.0 * FixedTotal / 100.0 * 10,
            TotalCost is BaseCost + OilCost + FixedCost,
            TotalCost =< BudgetFloat
        ),
        Candidates
    ),

    (
        Candidates = [] ->
            Recipe = no_heuristic_solution_found
        ;
            sort_candidates_by_cost(Candidates, Sorted),
            Sorted = [candidate(BestCost, BestPcts, BestOilPct) | _],
            build_heuristic_output(Species, Stage, BestPcts, BestOilPct,
                                 FixedIngredients, BestCost,
                                 TargetProtein, TargetFat, Recipe)
    ).

assign_heuristic_percents([], []).
assign_heuristic_percents([Id | Rest], [Pct | RPcts]) :-
    ingredient(Id, _, _, _, _, _, _, _, _, Max, _),
    between_inclusive(0, Max, 1.0, Pct),   % 1% 步长, 更快
    assign_heuristic_percents(Rest, RPcts).

sum_fixed_percent([], 0.0).
sum_fixed_percent([_-Pct | Rest], Total) :-
    sum_fixed_percent(Rest, RestSum),
    Total is RestSum + Pct.

check_protein_heuristic(BaseIds, BasePcts, OilPct, Target) :-
    protein_contribution(BaseIds, BasePcts, ProSum),
    Calc is ProSum / 100.0,
    Calc >= Target - 0.5.

check_fat_heuristic(BaseIds, BasePcts, OilPct, Target) :-
    fat_contribution(BaseIds, BasePcts, FatSum),
    OilContrib is 99.5 * OilPct / 100.0,
    Calc is (FatSum / 100.0) + OilContrib,
    Calc >= Target - 0.5.

build_heuristic_output(Species, Stage, BasePcts, OilPct, FixedIngredients, TotalCost,
                       TargetProtein, TargetFat, Recipe) :-
    % 核心原料
    CoreIngredients = [
        fish_meal_peru_65,
        fish_meal_domestic_60,
        soybean_meal_43,
        soybean_meal_46,
        rapeseed_meal_regular,
        cottonseed_meal_regular,
        corn_gluten_meal_60,
        corn_ddgs,
        wheat_middlings,
        wheat_flour,
        corn,
        wheat,
        rice_bran_fullfat,
        rice_bran_defatted
    ],
    build_ingredient_items(CoreIngredients, BasePcts, CoreItems),

    % 油脂条目
    (
        OilPct > 0 ->
            OilCost is 12.0 * OilPct / 100.0 * 10,
            OilItem = item(fish_oil_soybean_blend, '鱼油/豆油混合物', OilPct, OilCost),
            OilItems = [OilItem]
        ;
            OilItems = []
    ),

    % 固定添加剂条目
    build_fixed_items(FixedIngredients, FixedItems),

    % 合并
    append(CoreItems, OilItems, TempItems),
    append(TempItems, FixedItems, AllItems),
    include(nonzero_percent, AllItems, Items),

    calc_nutrition(CoreIngredients, BasePcts, CalcProtein, CalcFat, CalcFiber, CalcAsh),
    OilFatContrib is 99.5 * OilPct / 100.0,
    FinalFat is CalcFat + OilFatContrib,

    Recipe = recipe(Species, Stage, Items, TotalCost,
                    CalcProtein, FinalFat, CalcFiber, CalcAsh).

build_fixed_items([], []).
build_fixed_items([Id-Pct | Rest], [Item | RItems]) :-
    ingredient(Id, Name, _, _, _, _, _, _, Price, _, _),
    CostContrib is Price * Pct / 100.0 * 10,
    Item = item(Id, Name, Pct, CostContrib),
    build_fixed_items(Rest, RItems).
