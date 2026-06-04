% ═══════════════════════════════════════════════════════════════
% AquaFeedFormulator — Prolog SOP 引擎 v2.0
% 端到端配方求解: solve_formulation(Species, Stage).
%
% P0 修正：
%   - 成本单位修正（吨成本 ×10 而非 ×1000）
%   - 品类约束从 category_rules.pl 引用（唯一源）
%   - fallback 由 sop_gatekeeper 控制
%   - LP 求解逻辑委托给 formulation_lp_engine.pl
% ═══════════════════════════════════════════════════════════════

% ==== 基础工具 ====
member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

sum_list([], 0).
sum_list([X|Xs], S) :- sum_list(Xs, S0), S is S0 + X.

append([], L, L).
append([H|T], L, [H|R]) :- append(T, L, R).

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
    % 生产模式校验（禁止静默 fallback — 缺规则就直接失败）
    (  can_execute(production, solve(Species, Stage)) -> true
    ;  write('FATAL: 生产模式 can_execute 失败 — 禁止执行'), nl, fail
    ),
    % 营养目标
    species_nutrition(Species, Stage, TgtPro, TgtFat, MaxFib, MaxAsh),
    % 品类约束（从唯一源 category_rules.pl 读取）
    category_constraints_for(Species, Stage, CatConstraints),
    % LP求解（委托给 formulation_lp_engine.pl）
    lp_solve(TgtPro, TgtFat, MaxFib, MaxAsh, CatConstraints, Solution),
    % 输出
    (  Solution = infeasible ->
        write('=== 不可行 ==='), nl,
        write('营养目标与品类约束冲突'), nl
    ;  display_recipe(Solution, Species, Stage, TgtPro, TgtFat, MaxFib, MaxAsh)
    ).

% 品类约束获取（从唯一源 category_rules.pl 读取，不重复定义）
category_constraints_for(Species, Stage, Constraints) :-
    species_category_constraints_strict(Species, Stage, Constraints).


% ═══════════════════════════════════════════════════════════════
% 结果展示
% ═══════════════════════════════════════════════════════════════

display_recipe(recipe_sop(Items, TotalCost),
               Species, Stage, TgtPro, TgtFat, MaxFib, MaxAsh) :-
    species_name(Species, SName),
    stage_name(Stage, StName),
    nl,
    write('=========================================='), nl,
    write('  AquaFeedFormulator — Prolog SOP v2.0'), nl,
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
    % P0-2+ 修正：吨成本 = TotalCost(元/100kg) × 10
    TotalCostT is round(TotalCost * 10),
    write('  ---'), nl,
    write('  合计: '), write(TotalPctR), write('%'), nl,
    write('  吨成本: ¥'), write(TotalCostT), write(' /t'), nl,
    % P0-2+：成本异常检测（按物种）
    (  cost_in_range(Species, Stage, TotalCostT) -> true
    ;  write('  ⚠ cost_unit_anomaly: 吨成本超出 '),
       write(Species), write(' 合理区间'), nl
    ),
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
    CostPerTon is round(Cost * 10),
    write('    '), write(Name), write('  '), write(PctR), write('%  ¥'),
    write(CostPerTon), nl,
    display_items(RT).

sum_pcts([], 0).
sum_pcts([_-Pct-_|RT], T) :-
    sum_pcts(RT, R), T is R + Pct.
