% ============================================================
% shrimp_recipes.pl — 南美白对虾幼虾饲料配方 (3 方案)
% 生成日期: 2026-06-04
% 目标物种: white_shrimp, juvenile
% 营养需求: Protein ≥38%, Fat ≥6%, Fiber ≤5%, Ash ≤14%
% ============================================================

% ==========================================
% 方案A: 高鱼粉精品型
%   策略: 高动物蛋白+强诱食体系, 面向高密度精养
%   动物蛋白: 44%  淀粉: 16%
% ==========================================
shrimp_recipe_a(recipe(white_shrimp, juvenile, Items, 12850, 41.1, 9.7, 3.0, 12.8)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 25.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 10.0, 0),
        item(shrimp_shell_meal, '虾壳粉', 5.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 4.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 14.0, 0),
        item(peanut_meal, '花生粕', 5.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 3.0, 0),
        item(wheat_flour, '面粉', 16.0, 0),
        item(rice_bran_defatted, '脱脂米糠', 3.0, 0),
        item(fish_oil, '鱼油', 3.0, 0),
        item(soybean_lecithin, '磷脂油', 2.0, 0),
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
%   策略: 动物/植物蛋白均衡, 成本与性能兼顾
%   动物蛋白: 33%  淀粉: 18%
% ==========================================
shrimp_recipe_b(recipe(white_shrimp, juvenile, Items, 11000, 40.5, 8.8, 3.5, 12.0)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 18.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 8.0, 0),
        item(shrimp_shell_meal, '虾壳粉', 4.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 3.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 18.0, 0),
        item(peanut_meal, '花生粕', 6.0, 0),
        item(cottonseed_meal_dephenol, '棉粕(脱酚)', 5.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 2.0, 0),
        item(wheat_flour, '面粉', 18.0, 0),
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
%   策略: 适度植物蛋白替代, 控制原料成本
%   动物蛋白: 28%  淀粉: 15%
% ==========================================
shrimp_recipe_c(recipe(white_shrimp, juvenile, Items, 9800, 39.5, 8.1, 4.0, 11.5)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 12.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 5.0, 0),
        item(poultry_meal, '鸡肉粉', 6.0, 0),
        item(shrimp_shell_meal, '虾壳粉', 3.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 2.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 21.0, 0),
        item(peanut_meal, '花生粕', 5.0, 0),
        item(cottonseed_meal_dephenol, '棉粕(脱酚)', 5.0, 0),
        item(rapeseed_meal_regular, '菜粕', 5.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 2.0, 0),
        item(wheat_flour, '面粉', 15.0, 0),
        item(rice_bran_defatted, '脱脂米糠', 4.0, 0),
        item(fish_oil, '鱼油', 3.0, 0),
        item(soybean_lecithin, '磷脂油', 2.0, 0),
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
% 配方验证 + JSON 输出
% ==========================================

% 运行全部校验并输出结果
validate_all_shrimp :-
    shrimp_recipe_a(RA), shrimp_recipe_b(RB), shrimp_recipe_c(RC),
    validate_formula_closure(RA, CA),
    validate_formula_closure(RB, CB),
    validate_formula_closure(RC, CC),
    check_functional_completeness(white_shrimp, juvenile,
        [item(fish_meal_peru_65,_,25.0,_),item(fish_meal_domestic_60,_,10.0,_),
         item(shrimp_shell_meal,_,5.0,_),item(squid_liver_paste,_,4.0,_),
         item(soybean_meal_46,_,14.0,_),item(peanut_meal,_,5.0,_),
         item(fermented_soybean_meal,_,5.0,_),item(corn_gluten_meal_60,_,3.0,_),
         item(wheat_flour,_,16.0,_),item(rice_bran_defatted,_,3.0,_),
         item(fish_oil,_,3.0,_),item(soybean_lecithin,_,2.0,_),
         item(cholesterol,_,0.3,_),item(dicalcium_phosphate,_,2.0,_),
         item(premix_vitamin_aqua,_,0.5,_),item(premix_mineral_aqua,_,0.5,_),
         item(choline_chloride_50,_,0.5,_),item(vitamin_c_phosphate,_,0.15,_),
         item(betaine,_,0.5,_),item(ethoxyquin,_,0.02,_),
         item(mold_inhibitor,_,0.03,_),item(salt,_,0.5,_)],
         FA),
    write('CLA,'), write(CA), nl,
    write('CLB,'), write(CB), nl,
    write('CLC,'), write(CC), nl,
    write('FNA,'), write(FA), nl.

% 输出 JSON 格式 (供 DOCX 脚本消费)
dump_recipe_json :-
    shrimp_recipe_a(recipe(_, _, Items, Cost, Pro, Fat, Fib, Ash)),
    write('{"plan":"A","name":"高鱼粉精品型","species":"南美白对虾","stage":"幼虾","cost":'),
    write(Cost), write(',"protein":'), write(Pro),
    write(',"fat":'), write(Fat), write(',"fiber":'), write(Fib),
    write(',"ash":'), write(Ash), write(',"items":['),
    dump_items_json(Items),
    writeln(']},').

dump_items_json([item(Id, Name, Pct, _)]) :-
    write('{"id":"'), write(Id), write('","name":"'),
    write(Name), write('","pct":'), write(Pct), write('}').
dump_items_json([item(Id, Name, Pct, _) | Rest]) :-
    Rest \= [],
    write('{"id":"'), write(Id), write('","name":"'),
    write(Name), write('","pct":'), write(Pct), write('},'),
    dump_items_json(Rest).
