% ============================================================
% eel_recipes.pl — 日本鳗鲡幼鳗饲料配方 (3 方案)
% 生成日期: 2026-06-04
% 目标物种: japanese_eel, juvenile
% 营养需求: Protein ≥45%, Fat ≥7%, Fiber ≤3%, Ash ≤12%
% 品类约束: 淀粉 ≤22%, 动物蛋白 ≥40%, 油脂 3-8%
% ============================================================

% ==========================================
% 方案A: 高鱼粉精品型
%   策略: 鱼粉 50% + 强诱食, 面向高品质鳗鱼养殖
%   动物蛋白: 59%  淀粉: 16%  油脂: 4.5%
% ==========================================
eel_recipe_a(recipe(japanese_eel, juvenile, Items, 14200, 47.5, 8.5, 2.2, 10.5)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 35.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 15.0, 0),
        item(poultry_meal, '鸡肉粉', 5.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 4.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 8.5, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 3.0, 0),
        item(wheat_flour, '面粉', 10.0, 0),
        item(tapioca_starch, '木薯淀粉', 6.0, 0),
        item(fish_oil, '鱼油', 3.0, 0),
        item(soybean_lecithin, '磷脂油', 1.5, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 1.5, 0),
        item(premix_vitamin_aqua, '多维预混料', 0.5, 0),
        item(premix_mineral_aqua, '多矿预混料', 0.5, 0),
        item(choline_chloride_50, '氯化胆碱(50%)', 0.5, 0),
        item(vitamin_c_phosphate, 'VC磷酸酯', 0.15, 0),
        item(betaine, '甜菜碱', 0.3, 0),
        item(ethoxyquin, '乙氧喹', 0.02, 0),
        item(mold_inhibitor, '防霉剂', 0.03, 0),
        item(salt, '食盐', 0.5, 0)
    ].

% ==========================================
% 方案B: 平衡型
%   策略: 鱼粉 40% + 植物蛋白补充, 成本与性能兼顾
%   动物蛋白: 48%  淀粉: 16%  油脂: 5.5%
% ==========================================
eel_recipe_b(recipe(japanese_eel, juvenile, Items, 12500, 46.2, 8.0, 2.5, 10.0)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 28.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 12.0, 0),
        item(poultry_meal, '鸡肉粉', 5.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 3.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 14.5, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 4.0, 0),
        item(wheat_flour, '面粉', 12.0, 0),
        item(tapioca_starch, '木薯淀粉', 4.0, 0),
        item(rice_bran_defatted, '脱脂米糠', 3.0, 0),
        item(fish_oil, '鱼油', 4.0, 0),
        item(soybean_lecithin, '磷脂油', 1.5, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 1.5, 0),
        item(premix_vitamin_aqua, '多维预混料', 0.5, 0),
        item(premix_mineral_aqua, '多矿预混料', 0.5, 0),
        item(choline_chloride_50, '氯化胆碱(50%)', 0.5, 0),
        item(vitamin_c_phosphate, 'VC磷酸酯', 0.15, 0),
        item(betaine, '甜菜碱', 0.3, 0),
        item(ethoxyquin, '乙氧喹', 0.02, 0),
        item(mold_inhibitor, '防霉剂', 0.03, 0),
        item(salt, '食盐', 0.5, 0)
    ].

% ==========================================
% 方案C: 经济型
%   策略: 鱼粉 30% + 血粉/鸡肉粉 + 植物蛋白, 控制成本
%   动物蛋白: 40%  淀粉: 18%  油脂: 5.5%
% ==========================================
eel_recipe_c(recipe(japanese_eel, juvenile, Items, 10800, 45.5, 7.5, 2.8, 10.2)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 20.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 10.0, 0),
        item(poultry_meal, '鸡肉粉', 6.0, 0),
        item(blood_meal_spray, '血粉(喷雾干燥)', 2.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 2.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 16.5, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(cottonseed_meal_dephenol, '棉粕(脱酚)', 5.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 3.0, 0),
        item(wheat_flour, '面粉', 14.0, 0),
        item(tapioca_starch, '木薯淀粉', 4.0, 0),
        item(rice_bran_defatted, '脱脂米糠', 3.0, 0),
        item(fish_oil, '鱼油', 4.0, 0),
        item(soybean_lecithin, '磷脂油', 1.5, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 1.5, 0),
        item(premix_vitamin_aqua, '多维预混料', 0.5, 0),
        item(premix_mineral_aqua, '多矿预混料', 0.5, 0),
        item(choline_chloride_50, '氯化胆碱(50%)', 0.5, 0),
        item(vitamin_c_phosphate, 'VC磷酸酯', 0.15, 0),
        item(betaine, '甜菜碱', 0.3, 0),
        item(ethoxyquin, '乙氧喹', 0.02, 0),
        item(mold_inhibitor, '防霉剂', 0.03, 0),
        item(salt, '食盐', 0.5, 0)
    ].

% ==========================================
% 配方验证
% ==========================================
validate_all_eel :-
    eel_recipe_a(RA), eel_recipe_b(RB), eel_recipe_c(RC),
    validate_formula_closure(RA, CA),
    validate_formula_closure(RB, CB),
    validate_formula_closure(RC, CC),
    % 功能完整性 — 用方案A的原料
    RA = recipe(japanese_eel, juvenile, ItemsA, _, _, _, _, _),
    check_functional_completeness(japanese_eel, juvenile, ItemsA, FA),
    write('CLA,'), write(CA), nl,
    write('CLB,'), write(CB), nl,
    write('CLC,'), write(CC), nl,
    write('FNA,'), write(FA), nl.
