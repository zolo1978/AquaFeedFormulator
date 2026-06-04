% 调试版：逐步构建约束，定位不可行之处
:- consult('ingredient_db.pl').
:- consult('species_nutrition.pl').
:- consult('formulation_solver_v2.pl').

debug_eel :-
    Ids = [fish_meal_peru_65, fish_meal_domestic_60, soybean_meal_46,
           fermented_soybean_meal, corn_gluten_meal_60, wheat_flour,
           tapioca_starch, rice_bran_defatted, fish_oil, soybean_lecithin],

    species_nutrition(japanese_eel, juvenile, TgtPro, TgtFat, MaxFib, MaxAsh),
    write('Target: Pro='), write(TgtPro), write(' Fat='), write(TgtFat),
    write(' Fib<='), write(MaxFib), write(' Ash<='), write(MaxAsh), nl,

    % 可变原料
    findall(Id-Pro-Min-Max-Price,
            (member(Id, Ids), ingredient(Id,_,_,Pro,_,_,_,_,Price,Max,Min)),
            VarData),
    write('Var ingredients: '), write(VarData), nl,

    % 固定原料
    findall(Id-Name-Pro-Fat-Fib-Ash-Min-Price,
            ( ingredient(Id, Name, _, Pro, Fat, Fib, Ash, _, Price, Min, Max),
              \+ member(Id, Ids), Max =< 2.0, Min > 0, Min = Max ),
            FixedData),
    write('Fixed ingredients: '), write(FixedData), nl,

    fixed_sum(FixedData, FixPct, FixProC, FixFatC, FixFibC, FixAshC, _FixCost),
    write('Fixed: Sum='), write(FixPct), write(' ProC='), write(FixProC),
    write(' FatC='), write(FixFatC), write(' FibC='), write(FixFibC),
    write(' AshC='), write(FixAshC), nl,

    VarTotal10 is round(1000.0 - FixPct * 10),
    RemPro10 is round(TgtPro * 10 - FixProC * 10),
    RemFat10 is round(TgtFat * 10 - FixFatC * 10),
    RemFib10 is round(MaxFib * 10 - FixFibC * 10),
    RemAsh10 is round(MaxAsh * 10 - FixAshC * 10),

    write('VarTotal10='), write(VarTotal10), nl,
    write('RemPro10='), write(RemPro10), write(' RemFat10='), write(RemFat10),
    write(' RemFib10='), write(RemFib10), write(' RemAsh10='), write(RemAsh10), nl,

    % 逐步构建
    gen_state(S0),

    % 总和
    sum_constraint(VarData, SC),
    ( SC = [] -> S1 = S0 ; (write('Adding sum constraint: '), write(SC = VarTotal10), nl, constraint(SC = VarTotal10, S0, S1), write('Sum OK'), nl) ),

    % 蛋白
    nutrient_constraint(VarData, pro, NCPro),
    ( NCPro = [] -> S2 = S1 ; (write('Adding pro constraint: '), write(NCPro >= RemPro10), nl, constraint(NCPro >= RemPro10, S1, S2), write('Pro OK'), nl) ),

    % 脂肪
    nutrient_constraint(VarData, fat, NCFat),
    ( NCFat = [] -> S3 = S2 ; (write('Adding fat constraint: '), write(NCFat >= RemFat10), nl, constraint(NCFat >= RemFat10, S2, S3), write('Fat OK'), nl) ),

    % 纤维
    nutrient_constraint(VarData, fib, NCFib),
    ( NCFib = [] -> S4 = S3 ; (write('Adding fib constraint: '), write(NCFib =< RemFib10), nl, constraint(NCFib =< RemFib10, S3, S4), write('Fib OK'), nl) ),

    % 灰分
    nutrient_constraint(VarData, ash, NCAsh),
    ( NCAsh = [] -> S5 = S4 ; (write('Adding ash constraint: '), write(NCAsh =< RemAsh10), nl, constraint(NCAsh =< RemAsh10, S4, S5), write('Ash OK'), nl) ),

    % bounds
    individual_bounds(VarData, S5, S6),
    write('Bounds OK'), nl,

    % 目标
    cost_objective(VarData, Obj),
    write('Objective: '), write(Obj), nl,
    minimize(Obj, S6, SFinal),
    write('Minimized!'), nl,

    extract_items(VarData, FixedData, SFinal, Items, TotalCost),
    write('Items: '), write(Items), nl,
    write('TotalCost: '), write(TotalCost), nl.
