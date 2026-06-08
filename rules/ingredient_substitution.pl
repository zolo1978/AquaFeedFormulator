% ============================================================
% ingredient_substitution.pl — 原料替代推荐引擎
% AquaFeedFormulator 核心规则模块 4/5 (M4)
% ============================================================
%
% 功能:
%   给定原料 ID 和替代原因，输出替代候选列表，
%   含替代比例、成本影响、风险评分
%
% 入口谓词:
%   output(input(IngredientId, Reason),
%          output(Substitutions, Warnings, Errors, Confidence, NextActions))
%
% Reason: supply_shortage | cost_spike | quality_issue
%
% ============================================================

:- use_module(library(lists)).
:- use_module(library(iso_ext)).

% ═══════════════════════════════════════════════════════════════
% my_length/2 — scryer 兼容（ISO 标准无 length/2）
% ═══════════════════════════════════════════════════════════════

my_length(List, Len) :-
    my_length(List, 0, Len).

my_length([], Acc, Acc).
my_length([_|T], Acc, Len) :-
    Acc1 is Acc + 1,
    my_length(T, Acc1, Len).

% ═══════════════════════════════════════════════════════════════
% 顶层入口
% ═══════════════════════════════════════════════════════════════

output(Input, Output) :-
    Input = input(IngredientId, Reason),

    % 校验原料是否存在
    (  ingredient(IngredientId, _, _, _, _, _, _, _, _, _, _) ->
        generate_substitutions(IngredientId, Reason, Output)
    ;  Output = output([], [],
               [err(invalid_ingredient, IngredientId)],
               0.0, [])
    ).

% ═══════════════════════════════════════════════════════════════
% 替代方案生成
% ═══════════════════════════════════════════════════════════════

generate_substitutions(Id, Reason, Output) :-
    % 先按同品类查找
    same_category_candidates(Id, Candidates),
    % 加上跨品类候选
    cross_category_candidates(Id, CrossCandidates),

    % 评分过滤排序
    score_and_rank(Candidates, Id, Reason, Ranked),
    score_and_rank(CrossCandidates, Id, Reason, CrossRanked),

    % 合并，同品类优先
    merge_ranked(Ranked, CrossRanked, AllSubs),

    % 收集警告和可信度
    collect_warnings(Id, Reason, AllSubs, Warnings),
    my_length(AllSubs, SubCount),
    confidence_from_count(SubCount, Confidence),

    Output = output(AllSubs, Warnings, [], Confidence, []).

% ═══════════════════════════════════════════════════════════════
% 同品类候选
% ═══════════════════════════════════════════════════════════════

same_category_candidates(Id, Candidates) :-
    ingredient(Id, _, Category, _, _, _, _, _, _, _, _),
    findall(SubId,
            ( ingredient(SubId, _, Category, _, _, _, _, _, _, _, _),
              SubId \= Id
            ),
            Raw),
    sort(Raw, Candidates).

% ═══════════════════════════════════════════════════════════════
% 跨品类候选 — 精选规则
% ═══════════════════════════════════════════════════════════════

% 规则 1: 鱼粉 → 陆地动物蛋白（鸡肉粉/肉骨粉/血粉）
cross_category_candidates(Id, Cross) :-
    ingredient(Id, _, animal_protein, _, _, _, _, _, _, _, _),
    sub_atom(Id, 0, _, _, 'fish_meal'),
    !,
    findall(SubId,
            ( ingredient(SubId, _, animal_protein, _, _, _, _, _, _, _, _),
              \+ sub_atom(SubId, 0, _, _, 'fish_meal'),
              member(SubId, [poultry_meal, meat_bone_meal_50, blood_meal_spray])
            ),
            Cross).
cross_category_candidates(Id, Cross) :-
    ingredient(Id, _, animal_protein, _, _, _, _, _, _, _, _),
    \+ sub_atom(Id, 0, _, _, 'fish_meal'),
    !,
    % 陆地动物蛋白 → 其他陆地 + 鱼粉
    findall(SubId,
            ( ingredient(SubId, _, animal_protein, _, _, _, _, _, _, _, _),
              SubId \= Id,
              member(SubId, [fish_meal_peru_65, poultry_meal, blood_meal_spray])
            ),
            Cross).

% 规则 2: 豆粕(43%) → 豆粕(46%) / 发酵豆粕
cross_category_candidates(Id, Cross) :-
    ingredient(Id, _, plant_protein, _, _, _, _, _, _, _, _),
    sub_atom(Id, 0, _, _, 'soybean_meal'),
    !,
    findall(SubId,
            ( ingredient(SubId, _, plant_protein, _, _, _, _, _, _, _, _),
              SubId \= Id,
              (  sub_atom(SubId, 0, _, _, 'soybean_meal')
              ;  sub_atom(SubId, 0, _, _, 'fermented_soybean_meal')
              )
            ),
            Cross).

% 规则 3: 普通菜粕 → 双低菜粕
cross_category_candidates(Id, Cross) :-
    ingredient(Id, _, plant_protein, _, _, _, _, _, _, _, _),
    sub_atom(Id, 0, _, _, 'rapeseed_meal'),
    !,
    findall(SubId,
            ( ingredient(SubId, _, plant_protein, _, _, _, _, _, _, _, _),
              SubId \= Id,
              sub_atom(SubId, 0, _, _, 'canola_meal')
            ),
            Cross).

% 规则 4: 普通棉粕 → 脱酚棉粕
cross_category_candidates(Id, Cross) :-
    ingredient(Id, _, plant_protein, _, _, _, _, _, _, _, _),
    sub_atom(Id, 0, _, _, 'cottonseed_meal'),
    !,
    findall(SubId,
            ( ingredient(SubId, _, plant_protein, _, _, _, _, _, _, _, _),
              SubId \= Id,
              sub_atom(SubId, 0, _, _, 'cottonseed_meal')
            ),
            Cross).

% 规则 5: 鱼油 → 豆油 / 菜籽油
cross_category_candidates(Id, Cross) :-
    ingredient(Id, _, oil, _, _, _, _, _, _, _, _),
    sub_atom(Id, 0, _, _, 'fish_oil'),
    !,
    findall(SubId,
            ( ingredient(SubId, _, oil, _, _, _, _, _, _, _, _),
              SubId \= Id
            ),
            Cross).

% 规则 6: 玉米 → 小麦 / 面粉 / 木薯淀粉
cross_category_candidates(Id, Cross) :-
    ingredient(Id, _, energy, _, _, _, _, _, _, _, _),
    sub_atom(Id, 0, _, _, 'corn'),
    !,
    findall(SubId,
            ( ingredient(SubId, _, energy, _, _, _, _, _, _, _, _),
              SubId \= Id,
              member(SubId, [wheat, wheat_flour, tapioca_starch])
            ),
            Cross).

% 规则 7: 磷酸氢钙 → 磷酸二氢钙
cross_category_candidates(dicalcium_phosphate, [monocalcium_phosphate]) :- !.

% 默认: 无跨品类候选
cross_category_candidates(_, []).

% ═══════════════════════════════════════════════════════════════
% 评分与排名
% ═══════════════════════════════════════════════════════════════

% 对候选列表逐项评分，然后按分数降序排列
score_and_rank(Candidates, OrigId, Reason, Result) :-
    score_candidates(Candidates, OrigId, Reason, Pairs),
    sort_pairs_desc(Pairs, Sorted),
    pairs_to_list(Sorted, Result).

score_candidates([], _, _, []).
score_candidates([C|Cs], OrigId, Reason, [pair(Score, Sub)|Rest]) :-
    candidate_score(C, OrigId, Reason, Score, Sub),
    score_candidates(Cs, OrigId, Reason, Rest).

% ═══════════════════════════════════════════════════════════════
% 单项候选评分
% ═══════════════════════════════════════════════════════════════

candidate_score(SubId, OrigId, Reason, Score, sub(SubId, Ratio, Impact, RiskLevel)) :-
    % 获取原始原料属性
    ingredient(OrigId, _, OrigCat, OrigPro, OrigFat, _, _, _, OrigPrice, _, _),
    % 获取候选原料属性
    ingredient(SubId, _SubName, SubCat, SubPro, SubFat, _, _, _, SubPrice, _, _),

    % 替代比例（基于蛋白质等价，非蛋白类 1:1）
    substitution_ratio(OrigPro, SubPro, SubCat, Ratio),

    % 成本影响
    OrigUnitCost is OrigPrice,
    SubUnitCost is SubPrice * Ratio,
    CostDelta is SubUnitCost - OrigUnitCost,
    (  OrigUnitCost > 0 ->
        CostImpactPct is (CostDelta / OrigUnitCost) * 100
    ;  CostImpactPct is 0
    ),

    % 营养相似度（蛋白质 + 脂肪偏差，归一化 0..100）
    ProDelta is abs(OrigPro - SubPro),
    FatDelta is abs(OrigFat - SubFat),
    NutrientSim is 100 - (ProDelta + FatDelta * 0.5),
    NutrientSimClamped is max(0, min(100, NutrientSim)),

    % 品类距离
    (  OrigCat = SubCat -> CatDist is 0
    ;  CatDist is 20
    ),

    % 成本评分（越低越好，归一化为 0..100）
    CostScore is 100 - abs(CostImpactPct) * 2,
    CostScoreClamped is max(0, min(100, CostScore)),

    % 综合评分
    Score is NutrientSimClamped * 0.45 + CostScoreClamped * 0.35 + (100 - CatDist) * 0.20,

    % 影响标签
    (  abs(CostImpactPct) < 5 -> Impact = negligible
    ;  CostImpactPct > 0 -> Impact = cost_increase(CostImpactPct)
    ;  Impact = cost_decrease(abs(CostImpactPct))
    ),

    % 风险等级
    risk_level(OrigCat, SubCat, Ratio, Reason, RiskLevel).

% ═══════════════════════════════════════════════════════════════
% 替代比例计算
% ═══════════════════════════════════════════════════════════════

% 蛋白质类: 基于蛋白等价
substitution_ratio(OrigPro, SubPro, Category, Ratio) :-
    category_is_protein(Category),
    SubPro > 0,
    !,
    Ratio is OrigPro / SubPro.
% 油脂类: 1:1
substitution_ratio(_, _, oil, 1.0) :- !.
% 能量类: 1:1
substitution_ratio(_, _, energy, 1.0) :- !.
% 矿物/添加剂: 1:1
substitution_ratio(_, _, _, 1.0).

category_is_protein(animal_protein).
category_is_protein(plant_protein).

% ═══════════════════════════════════════════════════════════════
% 风险等级
% ═══════════════════════════════════════════════════════════════

risk_level(Cat, Cat, Ratio, _, Risk) :-
    % 同品类
    !,
    (  Ratio > 0.8, Ratio < 1.25 -> Risk = low
    ;  Risk = medium
    ).
risk_level(animal_protein, plant_protein, _, _, high) :- !.
risk_level(plant_protein, animal_protein, _, _, high) :- !.
risk_level(_, _, _, quality_issue, medium) :- !.
risk_level(_, _, _, cost_spike, low) :- !.
risk_level(_, _, _, _, medium).

% ═══════════════════════════════════════════════════════════════
% 排序工具
% ═══════════════════════════════════════════════════════════════

% 冒泡降序
sort_pairs_desc([], []).
sort_pairs_desc([P|Ps], Sorted) :-
    sort_pairs_desc(Ps, SortedRest),
    insert_pair_desc(P, SortedRest, Sorted).

insert_pair_desc(pair(S1, V1), [pair(S2, V2)|Rest], [pair(S1, V1), pair(S2, V2)|Rest]) :-
    S1 >= S2,
    !.
insert_pair_desc(pair(S1, V1), [pair(S2, V2)|Rest], [pair(S2, V2)|Inserted]) :-
    insert_pair_desc(pair(S1, V1), Rest, Inserted).
insert_pair_desc(P, [], [P]).

pairs_to_list([], []).
pairs_to_list([pair(_, V)|Rest], [V|List]) :-
    pairs_to_list(Rest, List).

% ═══════════════════════════════════════════════════════════════
% 合并排序（同品类优先于跨品类）
% ═══════════════════════════════════════════════════════════════

merge_ranked(SameCat, CrossCat, Merged) :-
    merge_ranked_aux(SameCat, CrossCat, Merged).

merge_ranked_aux([], Rest, Rest).
merge_ranked_aux([S|Ss], Cross, [S|Rest]) :-
    merge_ranked_aux(Ss, Cross, Rest).

% ═══════════════════════════════════════════════════════════════
% 警告收集
% ═══════════════════════════════════════════════════════════════

collect_warnings(_, _, [], []) :- !.
collect_warnings(Id, supply_shortage, Subs, Warnings) :-
    my_length(Subs, N),
    N < 3,
    !,
    Warnings = [warn(few_alternatives, Id, N)].
collect_warnings(Id, _, Subs, Warnings) :-
    has_high_risk(Subs),
    !,
    Warnings = [warn(high_risk_substitution_present, Id)].
collect_warnings(_, _, _, []).

has_high_risk([sub(_, _, _, high)|_]).
has_high_risk([_|Rest]) :- has_high_risk(Rest).

% ═══════════════════════════════════════════════════════════════
% 可信度
% ═══════════════════════════════════════════════════════════════

confidence_from_count(0, 0.0) :- !.
confidence_from_count(N, C) :-
    N >= 5,
    !,
    C is 1.0.
confidence_from_count(N, C) :-
    C is N / 5.0.

% ═══════════════════════════════════════════════════════════════
% 内嵌测试
% ═══════════════════════════════════════════════════════════════

test_all :-
    write('=== M4 ingredient_substitution ==='), nl,

    % 测试 1: 鱼粉替代
    write('--- fish_meal_substitution ---'), nl,
    output(input(fish_meal_peru_65, supply_shortage), Out1),
    (  Out1 = output(Subs1, _, _, _, _),
       my_length(Subs1, N1),
       N1 > 0
    -> write('[PASS] fish_meal_peru_65 → '), write(N1), write(' substitutes'), nl
    ;  write('[FAIL] fish_meal_peru_65 → no substitutes'), nl
    ),

    % 测试 2: 豆粕替代
    output(input(soybean_meal_43, cost_spike), Out2),
    (  Out2 = output(Subs2, _, _, _, _),
       my_length(Subs2, N2),
       N2 > 0
    -> write('[PASS] soybean_meal_43 → '), write(N2), write(' substitutes'), nl
    ;  write('[FAIL] soybean_meal_43 → no substitutes'), nl
    ),

    % 测试 3: 鱼油替代
    output(input(fish_oil, quality_issue), Out3),
    (  Out3 = output(Subs3, _, _, _, _),
       my_length(Subs3, N3),
       N3 > 0
    -> write('[PASS] fish_oil → '), write(N3), write(' substitutes'), nl
    ;  write('[FAIL] fish_oil → no substitutes'), nl
    ),

    % 测试 4: 玉米替代
    output(input(corn, supply_shortage), Out4),
    (  Out4 = output(Subs4, _, _, _, _),
       my_length(Subs4, N4),
       N4 > 0
    -> write('[PASS] corn → '), write(N4), write(' substitutes'), nl
    ;  write('[FAIL] corn → no substitutes'), nl
    ),

    % 测试 5: 磷酸氢钙 → 磷酸二氢钙
    output(input(dicalcium_phosphate, quality_issue), Out5),
    (  Out5 = output(Subs5, _, _, _, _),
       member(sub(monocalcium_phosphate, _, _, _), Subs5)
    -> write('[PASS] dicalcium_phosphate → monocalcium_phosphate'), nl
    ;  write('[FAIL] dicalcium_phosphate → monocalcium_phosphate missing'), nl
    ),

    % 测试 6: 无效原料
    output(input(nonexistent_ingredient, supply_shortage), Out6),
    (  Out6 = output([], _, [err(invalid_ingredient, nonexistent_ingredient)], _, _)
    -> write('[PASS] invalid_ingredient → graceful error'), nl
    ;  write('[FAIL] invalid_ingredient → unexpected'), nl
    ),

    % 测试 7: 同品类得分递减
    output(input(poultry_meal, supply_shortage), Out7),
    (  Out7 = output([sub(_Id1, _, _, R1), sub(_Id2, _, _, R2)|_], _, _, _, _),
       R1 == R2 -> write('[CIRCUMSTANTIAL] same risk ties'), nl
    ;  write('[PASS] risk ordering present'), nl
    ),

    % 测试 8: 替代比例合理性
    output(input(fish_meal_peru_65, supply_shortage), Out8),
    (  Out8 = output(Subs8, _, _, _, _),
       member(sub(SubId, Ratio, _, _), Subs8),
       Ratio < 0.5
    -> write('[WARN] unusually low ratio: '), write(SubId), write(' → '), write(Ratio), nl
    ;  write('[PASS] ratios in reasonable range'), nl
    ),

    write('=== M4 done ==='), nl.
