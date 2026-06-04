% ═══════════════════════════════════════════════════════════════
% AquaFeedFormulator — Prolog SOP 引擎 v1.0
% 端到端配方求解: solve_formulation(Species, Stage).
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

ingredient_for(Id, _, Pro, Fat, Fib, Ash, Price, Max, Min) :-
    ingredient(Id, _, _, Pro, Fat, Fib, Ash, _, Price, Max, Min).

fixed_ingredient(_, _, Id, Min, Price) :-
    ingredient(Id, _, additive, _, _, _, _, _, Price, Max, Min),
    Min > 0,
    Min =:= Max.

fixed_ingredient(_, _, Id, Min, Price) :-
    ingredient(Id, _, mineral, _, _, _, _, _, Price, Max, Min),
    Min > 0,
    Min =:= Max.

% ═══════════════════════════════════════════════════════════════
% 品类映射
% ═══════════════════════════════════════════════════════════════

starch_ingredient(tapioca_starch).
starch_ingredient(wheat_flour).
starch_ingredient(wheat).
starch_ingredient(corn).
starch_ingredient(sorghum).
starch_ingredient(wheat_middlings).

animal_protein_ingredient(Id) :-
    ingredient(Id, _, animal_protein, _, _, _, _, _, _, _, _).

plant_protein_ingredient(Id) :-
    ingredient(Id, _, plant_protein, _, _, _, _, _, _, _, _).

oil_ingredient(Id) :-
    ingredient(Id, _, oil, _, _, _, _, _, _, _, _).

category_check(starch, Id)         :- starch_ingredient(Id).
category_check(animal_protein, Id) :- animal_protein_ingredient(Id).
category_check(plant_protein, Id)  :- plant_protein_ingredient(Id).
category_check(oil, Id)            :- oil_ingredient(Id).

% ═══════════════════════════════════════════════════════════════
% 品类约束 (合并自 formula_closure_validator.pl)
% ═══════════════════════════════════════════════════════════════

species_category_rule(japanese_eel, _, starch, max, 25.0, _).
species_category_rule(japanese_eel, _, animal_protein, min, 35.0, _).
species_category_rule(japanese_eel, _, oil, max, 8.0, _).
species_category_rule(japanese_eel, _, oil, min, 3.0, _).
species_category_rule(japanese_eel, glass_eel, starch, max, 18.0, _).
species_category_rule(japanese_eel, glass_eel, animal_protein, min, 45.0, _).
species_category_rule(japanese_eel, juvenile, starch, max, 22.0, _).
species_category_rule(japanese_eel, juvenile, animal_protein, min, 40.0, _).
species_category_rule(japanese_eel, grower, starch, max, 28.0, _).
species_category_rule(japanese_eel, grower, animal_protein, min, 30.0, _).

species_category_rule(white_shrimp, _, starch, max, 20.0, _).
species_category_rule(white_shrimp, _, animal_protein, min, 25.0, _).

species_category_rule(_, _, starch, max, 30.0, _).
species_category_rule(_, _, animal_protein, min, 20.0, _).

% ═══════════════════════════════════════════════════════════════
% 物种/阶段名称
% ═══════════════════════════════════════════════════════════════

species_name(japanese_eel, '日本鳗鲡').
species_name(white_shrimp, '南美白对虾').
species_name(common_carp, '鲤鱼').
species_name(grass_carp, '草鱼').
species_name(crucian_carp, '鲫鱼').
species_name(black_carp, '青鱼').
species_name(wuchang_bream, '团头鲂').
species_name(channel_catfish, '斑点叉尾鮰').
species_name(southern_catfish, '南方大口鲶').
species_name(tilapia, '罗非鱼').
species_name(rainbow_trout, '虹鳟').
species_name(atlanic_salmon, '大西洋鲑').
species_name(tiger_prawn, '斑节对虾').
species_name(giant_river_prawn, '罗氏沼虾').
species_name(chinese_mitten_crab, '中华绒螯蟹').
species_name(yellow_catfish, '黄颡鱼').
species_name(largemouth_bass, '加州鲈').
species_name(snakehead, '乌鳢').
species_name(_, '未知物种').

stage_name(fry, '鱼苗').
stage_name(juvenile, '幼体').
stage_name(adult, '成体').
stage_name(broodstock, '亲本').
stage_name(elver, '鳗苗').
stage_name(glass_eel, '白仔鳗').
stage_name(grower, '养成期').
stage_name(zoea, '蚤状幼体').
stage_name(mysis, '糠虾期').
stage_name(postlarva, '仔虾期').
stage_name(megalopa, '大眼幼体').
stage_name(fattening, '育肥期').
stage_name(_, '未知阶段').

% ═══════════════════════════════════════════════════════════════
% 主入口: solve_formulation(+Species, +Stage)
% ═══════════════════════════════════════════════════════════════

solve_formulation(Species, Stage) :-
    % 校验
    (  species_nutrition(Species, Stage, _, _, _, _) -> true
    ;  write('ERROR: 未知物种/阶段: '), write(Species), write('/'), write(Stage), nl, fail
    ),
    % 营养目标
    species_nutrition(Species, Stage, TgtPro, TgtFat, MaxFib, MaxAsh),
    % 品类约束
    findall(Cat-LT-Limit,
            species_category_rule(Species, Stage, Cat, LT, Limit, _),
            CatRaw),
    sort(CatRaw, CatConstraints),
    % LP求解
    lp_solve_sop(Species, TgtPro, TgtFat, MaxFib, MaxAsh, CatConstraints, Solution),
    % 输出
    (  Solution = infeasible ->
        write('=== 不可行 ==='), nl,
        write('营养目标与品类约束冲突'), nl
    ;  display_recipe(Solution, Species, Stage, TgtPro, TgtFat, MaxFib, MaxAsh)
    ).

% ═══════════════════════════════════════════════════════════════
% LP求解核心
% ═══════════════════════════════════════════════════════════════

lp_solve_sop(Species, TgtPro, TgtFat, MaxFib, MaxAsh, CatConstraints, Solution) :-
    % 可变原料
    findall(Id-Pro-Fat-Fib-Ash-Price-Max-Min,
            ( ingredient(Id, _, Cat, Pro, Fat, Fib, Ash, _, Price, Max, Min),
              Cat \= additive
            ),
            AllVar),
    % 固定原料
    findall(Id-Pct-Price,
            fixed_ingredient(Species, _, Id, Pct, Price),
            FixedData),
    % 固定总量
    sum_fixed_pct(FixedData, 0, FixedTotal),
    VarTotal10 is 1000 - FixedTotal,
    % RHS
    RPro10  is round(TgtPro * 1000),
    RFat10  is round(TgtFat * 1000),
    RFib10  is round(MaxFib * 1000),
    RAsh10  is round(MaxAsh * 1000),
    % 约束
    gen_state(S0),
    extract_ids(AllVar, Ids),
    constraint(Ids = VarTotal10, S0, S1),
    nut_constraint(AllVar, pro, RPro10, >=, S1, S2),
    nut_constraint(AllVar, fat, RFat10, >=, S2, S3),
    nut_constraint(AllVar, fib, RFib10, =<, S3, S4),
    nut_constraint(AllVar, ash, RAsh10, =<, S4, S5),
    all_bounds(AllVar, S5, S6),
    cat_constraints(AllVar, CatConstraints, S6, S7),
    % 目标
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

% ---- 约束构建 ----

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

% ---- 结果提取 ----

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

% ═══════════════════════════════════════════════════════════════
% 结果展示
% ═══════════════════════════════════════════════════════════════

display_recipe(recipe_sop(Items, TotalCost),
               Species, Stage, TgtPro, TgtFat, MaxFib, MaxAsh) :-
    species_name(Species, SName),
    stage_name(Stage, StName),
    nl,
    write('=========================================='), nl,
    write('  AquaFeedFormulator — Prolog SOP v1.0'), nl,
    write('  '), write(SName), write(' · '), write(StName), nl,
    write('------------------------------------------'), nl,
    write('  营养目标:'), nl,
    write('    蛋白>='), write(TgtPro), write('%  脂肪>='), write(TgtFat),
    write('%  纤维<='), write(MaxFib), write('%  灰分<='), write(MaxAsh), nl,
    write('------------------------------------------'), nl,
    write('  配方:'), nl,
    display_items(Items),
    sum_pcts(Items, TotalPct),
    TotalPctR is round(TotalPct * 10) / 10,
    TotalCostT is round(TotalCost * 100000) / 100,
    write('  ---'), nl,
    write('  合计: '), write(TotalPctR), write('%'), nl,
    write('  吨成本: ¥'), write(TotalCostT), write(' /t'), nl,
    (  abs(TotalPctR - 100.0) =< 0.1 ->
        write('  闭合校验: OK'), nl
    ;  write('  闭合校验: FAIL (偏差 '), D is abs(TotalPctR - 100.0), write(D), write('%)'), nl
    ),
    write('=========================================='), nl, nl.

display_items([]).
display_items([Id-Pct-Cost|RT]) :-
    ingredient(Id, Name, _, _, _, _, _, _, _, _, _),
    PctR10 is round(Pct * 10),
    PctR is PctR10 / 10,
    CostPerTon is round(Cost * 100000) / 100,
    write('    '), write(Name), write('  '), write(PctR), write('%  ¥'),
    write(CostPerTon), nl,
    display_items(RT).

sum_pcts([], 0).
sum_pcts([_-Pct-_|RT], T) :-
    sum_pcts(RT, R), T is R + Pct.
