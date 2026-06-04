% ═══════════════════════════════════════════════════════════════
% category_rules.pl — 唯一种类约束源
% AquaFeedFormulator P0-4
%
% 本文件是品类约束的唯一来源。
% 所有模块（LP求解器、闭合校验器、报告生成器、反例测试）均引用此文件。
% 禁止在其他文件中手动复制品类约束。
% ═══════════════════════════════════════════════════════════════

% ==== 品类映射 =================================================
% 定义哪些原料属于哪个品类

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

% ==== 品类约束规则 ==============================================
% species_category_rule(Species, Stage, Category, LimitType, Limit%, Description)
%
% LimitType: min | max
% Stage 可用通配 _ 匹配所有阶段
% 注意：没有通配 Species=_ 的全局兜底规则 —— 生产模式下必须显式定义
%       仅在 allow_fallback(true) 时使用全局兜底规则

% --- 日本鳗鲡 ---
species_category_rule(japanese_eel, glass_eel, starch,         max, 18.0, '白仔鳗淀粉上限').
species_category_rule(japanese_eel, glass_eel, animal_protein, min, 45.0, '白仔鳗动物蛋白下限').
species_category_rule(japanese_eel, juvenile,  starch,         max, 22.0, '幼鳗淀粉上限').
species_category_rule(japanese_eel, juvenile,  animal_protein, min, 40.0, '幼鳗动物蛋白下限').
species_category_rule(japanese_eel, grower,    starch,         max, 28.0, '养成鳗淀粉上限').
species_category_rule(japanese_eel, grower,    animal_protein, min, 30.0, '养成鳗动物蛋白下限').
species_category_rule(japanese_eel, _,         starch,         max, 25.0, '鳗鱼通用淀粉上限').
species_category_rule(japanese_eel, _,         animal_protein, min, 35.0, '鳗鱼通用动物蛋白下限').
species_category_rule(japanese_eel, _,         oil,            max, 8.0,  '鳗鱼油脂上限').
species_category_rule(japanese_eel, _,         oil,            min, 3.0,  '鳗鱼油脂下限').

% --- 南美白对虾 ---
species_category_rule(white_shrimp, _, starch,         max, 20.0, '对虾淀粉上限').
species_category_rule(white_shrimp, _, animal_protein, min, 25.0, '对虾动物蛋白下限').
species_category_rule(white_shrimp, _, oil,            max, 8.0,  '对虾油脂上限').
species_category_rule(white_shrimp, _, oil,            min, 2.0,  '对虾油脂下限').

% --- 鲤鱼 ---
species_category_rule(common_carp, _, starch,         max, 35.0, '鲤鱼淀粉上限').
species_category_rule(common_carp, _, animal_protein, min, 10.0, '鲤鱼动物蛋白下限').

% --- 加州鲈 ---
species_category_rule(largemouth_bass, _, starch,         max, 15.0, '加州鲈淀粉上限(肉食性)').
species_category_rule(largemouth_bass, _, animal_protein, min, 35.0, '加州鲈动物蛋白下限').

% --- 草鱼 ---
species_category_rule(grass_carp, _, starch,         max, 30.0, '草鱼淀粉上限').
species_category_rule(grass_carp, _, animal_protein, min, 8.0,  '草鱼动物蛋白下限(草食性)').

% --- 全局兜底（仅 allow_fallback(true) 时启用）---
% 不在生产模式下自动生效
fallback_category_rule(starch,         max, 30.0).
fallback_category_rule(animal_protein, min, 20.0).
fallback_category_rule(oil,            max, 8.0).
fallback_category_rule(oil,            min, 2.0).

% ==== 查询接口 ==================================================

% 获取某物种/阶段的所有品类约束
species_category_constraints(Species, Stage, Constraints) :-
    findall(Cat-LT-Limit,
            species_category_rule(Species, Stage, Cat, LT, Limit, _),
            Raw),
    sort(Raw, Constraints).

% 生产模式：无专用规则时失败
species_category_constraints_strict(Species, Stage, Constraints) :-
    species_category_constraints(Species, Stage, Constraints),
    Constraints \= [].

% fallback 模式：无专用规则时使用全局兜底
species_category_constraints_fallback(Species, Stage, Constraints) :-
    species_category_constraints(Species, Stage, C1),
    (  C1 \= [] -> Constraints = C1
    ;  findall(Cat-LT-Limit,
               fallback_category_rule(Cat, LT, Limit),
               Constraints)
    ).

% 检查某品类约束是否存在
has_category_rules(Species, Stage) :-
    species_category_rule(Species, Stage, _, _, _, _), !.

% 列出所有已定义品类规则的物种
species_with_category_rules(SpeciesList) :-
    findall(Sp,
            ( species_category_rule(Sp, _, _, _, _, _),
              Sp \= '_'  % 排除通配
            ),
            Raw),
    sort(Raw, SpeciesList).
