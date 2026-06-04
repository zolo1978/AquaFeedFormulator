% ═══════════════════════════════════════════════════════════════
% formulation_lp_engine.pl — LP 求解核心
% AquaFeedFormulator P0-3
%
% 从 sop_engine.pl 提取的纯 LP 求解逻辑。
% 不包含 SOP 流程控制、不包含输出格式化。
% ═══════════════════════════════════════════════════════════════

:- use_module(library(simplex)).

% ==== 基础工具 ====
member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

sum_list([], 0).
sum_list([X|Xs], S) :- sum_list(Xs, S0), S is S0 + X.

append([], L, L).
append([H|T], L, [H|R]) :- append(T, L, R).

% ═══════════════════════════════════════════════════════════════
% 数据适配层
% ═══════════════════════════════════════════════════════════════

% 可变原料：非添加剂的 base ingredient
variable_ingredient(Id, Pro, Fat, Fib, Ash, Price, Max, Min) :-
    ingredient(Id, _, Cat, Pro, Fat, Fib, Ash, _, Price, Max, Min),
    Cat \= additive.

% 固定原料：Min > 0 且 Min = Max 的添加剂或矿物质
fixed_ingredient(Id, Min, Price) :-
    ingredient(Id, _, additive, _, _, _, _, _, Price, Max, Min),
    Min > 0, Min =:= Max.

fixed_ingredient(Id, Min, Price) :-
    ingredient(Id, _, mineral, _, _, _, _, _, Price, Max, Min),
    Min > 0, Min =:= Max.

% ═══════════════════════════════════════════════════════════════
% 主求解入口
% ═══════════════════════════════════════════════════════════════

% lp_solve(+TgtPro, +TgtFat, +MaxFib, +MaxAsh, +CatConstraints, -Solution)
% Solution = recipe_sop(Items, TotalCost) | infeasible

lp_solve(TgtPro, TgtFat, MaxFib, MaxAsh, CatConstraints, Solution) :-
    % 收集可变原料
    findall(Id-Pro-Fat-Fib-Ash-Price-Max-Min,
            variable_ingredient(Id, Pro, Fat, Fib, Ash, Price, Max, Min),
            AllVar),
    % 收集固定原料
    findall(Id-Pct-Price,
            ( fixed_ingredient(Id, Pct, Price) ),
            FixedData),
    % 固定总量
    sum_fixed_pct(FixedData, 0, FixedTotal),
    VarTotal10 is 1000 - FixedTotal,
    % RHS
    RPro10  is round(TgtPro * 1000),
    RFat10  is round(TgtFat * 1000),
    RFib10  is round(MaxFib * 1000),
    RAsh10  is round(MaxAsh * 1000),
    % 约束构建
    gen_state(S0),
    extract_ids(AllVar, Ids),
    constraint(Ids = VarTotal10, S0, S1),
    nut_constraint(AllVar, pro, RPro10, >=, S1, S2),
    nut_constraint(AllVar, fat, RFat10, >=, S2, S3),
    nut_constraint(AllVar, fib, RFib10, =<, S3, S4),
    nut_constraint(AllVar, ash, RAsh10, =<, S4, S5),
    all_bounds(AllVar, S5, S6),
    cat_constraints(AllVar, CatConstraints, S6, S7),
    % 目标函数
    findall(Cost10*Id,
            ( member(Id-_-_-_-_-Price-_-_, AllVar),
              Cost10 is round(Price * 10)
            ),
            Obj),
    % 求解
    (  minimize(Obj, S7, SFinal) ->
        extract_results(Ids, SFinal, AllVar, FixedData, Solution)
    ;  Solution = infeasible
    ).

% ═══════════════════════════════════════════════════════════════
% 约束构建
% ═══════════════════════════════════════════════════════════════

sum_fixed_pct([], T, T).
sum_fixed_pct([_-Pct-_|RT], Acc, T) :-
    Pct10 is round(Pct * 10),
    NAcc is Acc + Pct10,
    sum_fixed_pct(RT, NAcc, T).

extract_ids([], []).
extract_ids([Id-_-_-_-_-_-_-_|RT], [Id|R]) :- extract_ids(RT, R).

nut_constraint(VarData, Type, RHS, Op, S0, S1) :-
    findall(V*Id,
            ( member(Id-_-_-_-_-_-_-_, VarData),
              nut_val(Id, VarData, Type, V),
              V =\= 0
            ),
            Terms),
    nc_apply(Terms, RHS, Op, S0, S1).

nc_apply([], _, _, S, S).
nc_apply(Terms, RHS, >=, S0, S1) :-
    constraint(Terms >= RHS, S0, S1).
nc_apply(Terms, RHS, =<, S0, S1) :-
    constraint(Terms =< RHS, S0, S1).

nut_val(Id, VarData, Type, Val) :-
    member(Id-Pro-Fat-Fib-Ash-_-_-_, VarData),
    nut_val_sel(Type, Pro, Fat, Fib, Ash, Val).

nut_val_sel(pro, Pro, _, _, _, Pro).
nut_val_sel(fat, _, Fat, _, _, Fat).
nut_val_sel(fib, _, _, Fib, _, Fib).
nut_val_sel(ash, _, _, _, Ash, Ash).

all_bounds([], S, S).
all_bounds([Id-_-_-_-_-_-Max-Min|RT], S0, SOut) :-
    Min10 is round(Min * 10),
    Max10 is round(Max * 10),
    (  Min10 > 0 -> constraint([Id] >= Min10, S0, S1) ; S1 = S0 ),
    constraint([Id] =< Max10, S1, S2),
    all_bounds(RT, S2, SOut).

cat_constraints(_, [], S, S).
cat_constraints(Var, [Cat-max-Limit|RT], S0, SOut) :-
    Limit10 is round(Limit * 10),
    cat_terms(Cat, Var, Terms),
    (  Terms = [] -> S1 = S0
    ;  constraint(Terms =< Limit10, S0, S1)
    ),
    cat_constraints(Var, RT, S1, SOut).
cat_constraints(Var, [Cat-min-Limit|RT], S0, SOut) :-
    Limit10 is round(Limit * 10),
    cat_terms(Cat, Var, Terms),
    (  Terms = [] -> S1 = S0
    ;  constraint(Terms >= Limit10, S0, S1)
    ),
    cat_constraints(Var, RT, S1, SOut).

cat_terms(Cat, VarData, Terms) :-
    findall(1*Id,
            ( member(Id-_-_-_-_-_-_-_, VarData),
              category_check(Cat, Id)
            ),
            Terms).

% ═══════════════════════════════════════════════════════════════
% 结果提取
% ═══════════════════════════════════════════════════════════════

extract_results(Ids, State, VarData, FixedData,
        recipe_sop(Items, TotalCost)) :-
    findall(Id-Pct-Cost,
            ( member(Id, Ids),
              variable_value(State, Id, V10),
              V10 > 0,
              Pct is V10 / 10,
              member(Id-_-_-_-_-Price-_-_, VarData),
              Cost is Pct * Price
            ),
            VarItems),
    findall(Id-Pct-Cost,
            ( member(Id-Pct-Cost, FixedData), Pct > 0 ),
            FixedItems),
    sum_costs(VarItems, FixedItems, TotalCost),
    append(VarItems, FixedItems, Items).

sum_costs(VarItems, FixedItems, Total) :-
    sum_vc(VarItems, 0, VC),
    sum_fc(FixedItems, VC, Total).

sum_vc([], T, T).
sum_vc([_-_-C|RT], Acc, T) :-
    NAcc is Acc + C,
    sum_vc(RT, NAcc, T).

sum_fc([], T, T).
sum_fc([_-Pct-Price|RT], Acc, T) :-
    NAcc is Acc + Pct * Price,
    sum_fc(RT, NAcc, T).
