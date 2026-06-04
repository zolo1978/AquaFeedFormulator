% ═══════════════════════════════════════════════════════════════
% AquaFeedFormulator — Prolog LP 配方求解引擎 v2.1
%
% 数学基础:
%   变量域 [0, 1000] (千分比, 1单位=0.1%)
%   总配方量 = 1000 - 固定添加剂(×10)
%   RHS = 目标营养% × 1000
%   因为: 实际营养% = Σ(原料营养% × 千分比) / 1000
%
% 使用: solve_recipe(+Species, +Stage, +IngredientIds, -Recipe)
% ═══════════════════════════════════════════════════════════════

:- use_module(library(simplex)).
:- use_module(library(lists)).

% 基础工具
member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

sum_list([], 0).
sum_list([X|Xs], S) :- sum_list(Xs, S0), S is S0 + X.

% ═══════════════════ 主入口 ═══════════════════

% solve_recipe(+Species, +Stage, +IngredientIds, -Recipe)
% Recipe: [IngredientId-Pct-Cost, ...] | infeasible
solve_recipe(Species, Stage, IngredientIds, Recipe) :-
    % 1. 查询营养目标
    species_nutrition(Species, Stage, TgtPro, TgtFat, MaxFib, MaxAsh),
    % 2. 加载原料数据
    findall(Id-(Pro,Fat,Fib,Ash,Price,Max,Min),
            ingredient_for(Id, Species, Pro, Fat, Fib, Ash, Price, Max, Min),
            AllData),
    % 3. 过滤(仅选定原料)
    filter_ingredients(AllData, IngredientIds, VarData),
    % 4. 固定添加剂
    findall(FixId-FixPct,
            fixed_ingredient(Species, Stage, FixId, FixPct, _),
            FixedList),
    % 5. LP求解
    lp_solve(VarData, FixedList, TgtPro, TgtFat, MaxFib, MaxAsh, Solution),
    % 6. 格式化输出
    format_recipe(Solution, FixedList, Recipe).

% ═══════════════════ LP 求解核心 ═══════════════════

lp_solve(VarData, FixedList, TgtPro, TgtFat, MaxFib, MaxAsh, Solution) :-
    % 提取可变原料ID列表
    extract_ids(VarData, Ids),

    % 固定添加剂总占比(×10)
    sum_fixed_pct(FixedList, 0, FixedTotal),
    VarTotal is 1000 - FixedTotal,  % 可变原料总份额(×10)

    % RHS = 目标% × 1000
    RemPro  is round(TgtPro * 1000),
    RemFat  is round(TgtFat * 1000),
    RemFib  is round(MaxFib * 1000),
    RemAsh  is round(MaxAsh * 1000),

    % 构建约束
    gen_state(S0),

    % (1) 总和
    constraint(Ids = VarTotal, S0, S1),

    % (2) 蛋白 ≥
    nut_terms(VarData, pro, LPro),
    ( LPro = [] -> S2 = S1
    ; constraint(LPro >= RemPro, S1, S2)
    ),

    % (3) 脂肪 ≥
    nut_terms(VarData, fat, LFat),
    ( LFat = [] -> S3 = S2
    ; constraint(LFat >= RemFat, S2, S3)
    ),

    % (4) 纤维 ≤
    nut_terms(VarData, fib, LFib),
    ( LFib = [] -> S4 = S3
    ; constraint(LFib =< RemFib, S3, S4)
    ),

    % (5) 灰分 ≤
    nut_terms(VarData, ash, LAsh),
    ( LAsh = [] -> S5 = S4
    ; constraint(LAsh =< RemAsh, S4, S5)
    ),

    % (6) 用量上下限
    all_bounds(VarData, S5, S6),

    % (7) 目标函数(最小化成本)
    obj_terms(VarData, LObj),
    ( minimize(LObj, S6, SFinal) ->
        extract_results(Ids, SFinal, VarData, Results),
        Solution = solution(Results, FixedList)
    ; Solution = infeasible
    ).

% ═══════════════════ 数据提取 ═══════════════════

extract_ids([], []).
extract_ids([Id-_|RT], [Id|Rest]) :- extract_ids(RT, Rest).

filter_ingredients([], _, []).
filter_ingredients([Id-Data|RT], Ids, [Id-Data|Rest]) :-
    member(Id, Ids), !,
    filter_ingredients(RT, Ids, Rest).
filter_ingredients([_|RT], Ids, Rest) :-
    filter_ingredients(RT, Ids, Rest).

sum_fixed_pct([], T, T).
sum_fixed_pct([_-Pct|RT], Acc, Total) :-
    Pct10 is round(Pct * 10),
    NAcc is Acc + Pct10,
    sum_fixed_pct(RT, NAcc, Total).

% ═══════════════════ 约束构建 ═══════════════════

% nut_terms(+VarData, +Type, -ConstraintList)
% VarData: [Id-(Pro,Fat,Fib,Ash,Price,Max,Min), ...]
nut_terms([], _, []).
nut_terms([Id-(Pro,Fat,Fib,Ash,_,_,_)|RT], Type, Terms) :-
    (   Type = pro -> V = Pro
    ;   Type = fat -> V = Fat
    ;   Type = fib -> V = Fib
    ;   Type = ash -> V = Ash
    ),
    (   V =:= 0 -> nut_terms(RT, Type, Terms)
    ;   Terms = [V*Id|Rest], nut_terms(RT, Type, Rest)
    ).

% all_bounds(+VarData, +S0, -S)
all_bounds([], S, S).
all_bounds([Id-(_,_,_,_,_,Max,Min)|RT], S0, SOut) :-
    Min10 is round(Min * 10),
    Max10 is round(Max * 10),
    ( Min10 > 0 -> constraint([Id] >= Min10, S0, S1) ; S1 = S0 ),
    constraint([Id] =< Max10, S1, S2),
    all_bounds(RT, S2, SOut).

% obj_terms(+VarData, -ObjectiveList)
obj_terms([], []).
obj_terms([Id-(_,_,_,_,Price,_,_)|RT], [Price10*Id|Rest]) :-
    Price10 is round(Price * 10),
    obj_terms(RT, Rest).

% ═══════════════════ 结果提取 ═══════════════════

extract_results(Ids, State, VarData, Results) :-
    extract_each(Ids, State, VarData, Results).

extract_each([], _, _, []).
extract_each([Id|RT], State, VarData, [Id-Pct-Cost|Rest]) :-
    variable_value(State, Id, V10),
    Pct is V10 / 10,
    (   member(Id-(_,_,_,_,Price,_,_), VarData) -> Cost is Pct * Price
    ;   Cost = 0
    ),
    extract_each(RT, State, VarData, Rest).

% ═══════════════════ 格式化 ═══════════════════

format_recipe(infeasible, _, infeasible) :- !.
format_recipe(solution(Results, FixedList), FixedList, Recipe) :-
    % 计算可变原料成本
    sum_costs(Results, 0, VarCost),
    % 计算固定添加剂成本
    sum_fixed_costs(FixedList, VarCost, TotalCost),
    % 构建输出
    Recipe = recipe(Results, FixedList, VarCost, TotalCost).

sum_costs([], T, T).
sum_costs([_-_-C|RT], Acc, Total) :-
    NAcc is Acc + C,
    sum_costs(RT, NAcc, Total).

sum_fixed_costs([], T, T).
sum_fixed_costs([_-Pct|RT], Acc, Total) :-
    % 简化: 固定原料成本按零计(预混料成本另算)
    sum_fixed_costs(RT, Acc, Total).
