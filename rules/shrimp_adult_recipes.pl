% ============================================================
% 南美白对虾成体 (adult) 饲料配方 (3 方案)
% 营养需求: Protein ≥35%, Fat ≥5%, Fiber ≤5%, Ash ≤14%
% ============================================================

% 基础工具
member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

% ==========================================
% 方案A: 高鱼粉精品型
%   策略: 高动物蛋白(41%)+强诱食体系, 面向高密度精养成虾
% ==========================================
shrimp_adult_recipe_a(recipe_a(white_shrimp, adult, Items, 11200, 38.5, 8.5, 3.2, 12.5)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 20.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 10.0, 0),
        item(shrimp_shell_meal, '虾壳粉', 5.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 3.0, 0),
        item(poultry_meal, '鸡肉粉', 3.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 15.0, 0),
        item(peanut_meal, '花生粕', 5.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 3.0, 0),
        item(wheat_flour, '面粉', 18.0, 0),
        item(tapioca_starch, '木薯淀粉', 3.0, 0),
        item(rice_bran_defatted, '脱脂米糠', 2.0, 0),
        item(fish_oil, '鱼油', 2.5, 0),
        item(soybean_lecithin, '磷脂油', 1.5, 0),
        item(cholesterol, '胆固醇', 0.3, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 2.0, 0),
        item(premix_vitamin_aqua, '多维预混料', 0.5, 0),
        item(premix_mineral_aqua, '多矿预混料', 0.5, 0),
        item(choline_chloride_50, '氯化胆碱(50%)', 0.5, 0),
        item(vitamin_c_phosphate, 'VC磷酸酯', 0.15, 0),
        item(betaine, '甜菜碱', 0.5, 0),
        item(ethoxyquin, '乙氧喹', 0.02, 0),
        item(mold_inhibitor, '防霉剂', 0.03, 0),
        item(salt, '食盐', 0.5, 0)
    ].

% ==========================================
% 方案B: 平衡型
%   策略: 动物/植物蛋白均衡(30%动物蛋白), 性价比最优
% ==========================================
shrimp_adult_recipe_b(recipe_b(white_shrimp, adult, Items, 9600, 37.5, 7.8, 3.8, 11.8)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 15.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 8.0, 0),
        item(poultry_meal, '鸡肉粉', 4.0, 0),
        item(shrimp_shell_meal, '虾壳粉', 3.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 2.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 20.0, 0),
        item(peanut_meal, '花生粕', 6.0, 0),
        item(cottonseed_meal_dephenol, '棉粕(脱酚)', 5.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 2.0, 0),
        item(wheat_flour, '面粉', 16.0, 0),
        item(tapioca_starch, '木薯淀粉', 2.0, 0),
        item(rice_bran_defatted, '脱脂米糠', 4.0, 0),
        item(fish_oil, '鱼油', 2.5, 0),
        item(soybean_lecithin, '磷脂油', 1.5, 0),
        item(cholesterol, '胆固醇', 0.3, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 2.0, 0),
        item(premix_vitamin_aqua, '多维预混料', 0.5, 0),
        item(premix_mineral_aqua, '多矿预混料', 0.5, 0),
        item(choline_chloride_50, '氯化胆碱(50%)', 0.5, 0),
        item(vitamin_c_phosphate, 'VC磷酸酯', 0.15, 0),
        item(betaine, '甜菜碱', 0.5, 0),
        item(ethoxyquin, '乙氧喹', 0.02, 0),
        item(mold_inhibitor, '防霉剂', 0.03, 0),
        item(salt, '食盐', 0.5, 0)
    ].

% ==========================================
% 方案C: 经济型
%   策略: 适度植物蛋白替代(25%动物蛋白), 控制原料成本
% ==========================================
shrimp_adult_recipe_c(recipe_c(white_shrimp, adult, Items, 8500, 36.2, 7.2, 4.2, 11.2)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 10.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 5.0, 0),
        item(poultry_meal, '鸡肉粉', 5.0, 0),
        item(shrimp_shell_meal, '虾壳粉', 3.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 2.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 22.0, 0),
        item(peanut_meal, '花生粕', 5.0, 0),
        item(cottonseed_meal_dephenol, '棉粕(脱酚)', 5.0, 0),
        item(rapeseed_meal_regular, '菜粕', 4.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 2.0, 0),
        item(wheat_flour, '面粉', 16.0, 0),
        item(tapioca_starch, '木薯淀粉', 2.0, 0),
        item(rice_bran_defatted, '脱脂米糠', 4.0, 0),
        item(fish_oil, '鱼油', 2.5, 0),
        item(soybean_lecithin, '磷脂油', 1.5, 0),
        item(cholesterol, '胆固醇', 0.3, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 2.0, 0),
        item(premix_vitamin_aqua, '多维预混料', 0.5, 0),
        item(premix_mineral_aqua, '多矿预混料', 0.5, 0),
        item(choline_chloride_50, '氯化胆碱(50%)', 0.5, 0),
        item(vitamin_c_phosphate, 'VC磷酸酯', 0.15, 0),
        item(betaine, '甜菜碱', 0.5, 0),
        item(ethoxyquin, '乙氧喹', 0.02, 0),
        item(mold_inhibitor, '防霉剂', 0.03, 0),
        item(salt, '食盐', 0.5, 0)
    ].

% ==========================================
% 主入口: recipe_for_report(S) 输出结构化 JSON
% ==========================================
recipe_for_report(white_shrimp, adult) :-
    shrimp_adult_recipe_a(RA),
    shrimp_adult_recipe_b(RB),
    shrimp_adult_recipe_c(RC),
    tell('generated/recipe_data.json'),
    write('{"species":"南美白对虾","stage":"成体","species_key":"white_shrimp","stage_key":"adult","nutrition":{"protein":35,"fat":5,"fiber":5,"ash":14},"plans":['),
    recipe_to_json(RA, 'A', '高鱼粉精品型'),
    write(','),
    recipe_to_json(RB, 'B', '平衡型'),
    write(','),
    recipe_to_json(RC, 'C', '经济型'),
    write('],'),
    write('"constraints":['),
    write('{"type":"starch","limit":20,"op":"max","desc":"淀粉上限"},'),
    write('{"type":"animal_protein","limit":25,"op":"min","desc":"动物蛋白下限"},'),
    write('{"type":"oil","limit":8,"op":"max","desc":"油脂上限"},'),
    write('{"type":"oil","limit":2,"op":"min","desc":"油脂下限"}'),
    write(']}'), nl,
    told.

recipe_to_json(recipe_a(_, _, Items, Cost, Pro, Fat, Fib, Ash), Id, Name) :-
    write('{"id":"'), write(Id),
    write('","name":"'), write(Name),
    write('","strategy":"'),
    (  Id = 'A' -> write('高动物蛋白(41%)+强诱食体系。面向高密度精养成虾，追求最高生长速度和成活率。')
    ;  Id = 'B' -> write('动物/植物蛋白均衡(30% 动物蛋白)。成本与生长性能兼顾，适合主流商业养殖。')
    ;  Id = 'C' -> write('适度植物蛋白替代(25% 动物蛋白)。控制原料成本，适合价格敏感市场。')
    ;  write('')
    ),
    write('","cost":'), write(Cost),
    write(',"protein":'), write(Pro),
    write(',"fat":'), write(Fat),
    write(',"fiber":'), write(Fib),
    write(',"ash":'), write(Ash),
    write(',"animal_protein_pct":'),
    (  Id = 'A' -> write(41)
    ;  Id = 'B' -> write(30)
    ;  Id = 'C' -> write(25)
    ),
    write(',"starch_pct":'),
    (  Id = 'A' -> write(21)
    ;  Id = 'B' -> write(18)
    ;  Id = 'C' -> write(18)
    ),
    write(',"items":['),
    recipe_items_json(Items),
    write(']}').

recipe_items_json([]).
recipe_items_json([item(Id, Name, Pct, _)]) :-
    write('{"id":"'), write(Id), write('","name":"'), write(Name),
    write('","pct":'), write(Pct), write('}').
recipe_items_json([item(Id, Name, Pct, _) | Rest]) :-
    Rest \= [],
    write('{"id":"'), write(Id), write('","name":"'), write(Name),
    write('","pct":'), write(Pct), write('},'),
    recipe_items_json(Rest).
