% ============================================================
% ingredient_db.pl — 水产饲料原料数据库
% AquaFeedFormulator 核心规则模块 2/5
% ============================================================
%
% 数据来源:
%   - 中国饲料成分及营养价值表 (2024 第35版)
%   - NRC Nutrient Requirements of Fish and Shrimp (2011)
%   - 水产饲料调制加工与配方集萃 (薛敏)
%   - 各原料供应商技术参数
%
% 谓词: ingredient(Name, Protein%, Fat%, Fiber%, Ash%, Moisture%, PriceYuanPerKg, MaxUsage%, MinUsage%)
%   蛋白/脂肪/纤维/灰分: g/100g 干物质
%   价格: 元/kg (2024-2025 市场参考价)
%   用量: 占配方百分比范围
%
% 成本单位: price_unit(ingredient_id, yuan_per_kg).
%   所有原料价格单位为 元/kg，吨成本 = Σ(Pct × Price) × 10
%
% 分类:
%   1. 动物蛋白源 (fish_meal, blood_meal, meat_bone_meal, ...)
%   2. 植物蛋白源 (soybean_meal, rapeseed_meal, cottonseed_meal, ...)
%   3. 能量原料 (corn, wheat, rice_bran, ...)
%   4. 油脂类 (fish_oil, soybean_oil, ...)
%   5. 矿物质 (dicalcium_phosphate, limestone, salt, ...)
%   6. 添加剂 (premix_vitamin, premix_mineral, choline, ...)
% ============================================================

% ==========================================
% 1. 动物蛋白源
% ==========================================

% 鱼粉 — 秘鲁蒸汽鱼粉 (FAQ 65%)
ingredient(fish_meal_peru_65, '秘鲁鱼粉(65%)', animal_protein,
           65, 10, 1, 18, 8,     12.5, 50, 5).

% 鱼粉 — 国产鱼粉 (FAQ 60%)
ingredient(fish_meal_domestic_60, '国产鱼粉(60%)', animal_protein,
           60, 9, 1.5, 20, 8,    9.5, 50, 5).

% 鱼粉 — 白鱼粉 (FAQ 68%, 高端)
ingredient(fish_meal_white_68, '白鱼粉(68%)', animal_protein,
           68, 8, 0.5, 16, 8,    15.0, 40, 0).

% 血粉 — 喷雾干燥
ingredient(blood_meal_spray, '血粉(喷雾干燥)', animal_protein,
           80, 1, 1, 5, 8,       8.0, 8, 0).

% 肉骨粉 (CP 50%)
ingredient(meat_bone_meal_50, '肉骨粉(50%)', animal_protein,
           50, 10, 3, 30, 8,     5.5, 15, 0).

% 鸡肉粉
ingredient(poultry_meal, '鸡肉粉', animal_protein,
           62, 12, 1, 18, 8,     7.0, 15, 0).

% 虾壳粉
ingredient(shrimp_shell_meal, '虾壳粉', animal_protein,
           35, 3, 12, 30, 8,     4.0, 10, 0).

% 乌贼膏/鱿鱼膏 (诱食剂 + 蛋白)
ingredient(squid_liver_paste, '鱿鱼膏', animal_protein,
           40, 15, 2, 8, 30,     18.0, 8, 0).

% 蚕蛹粉
ingredient(silkworm_pupae_meal, '蚕蛹粉', animal_protein,
           55, 25, 4, 4, 8,      6.0, 10, 0).

% ==========================================
% 2. 植物蛋白源
% ==========================================

% 豆粕 — 43% 蛋白
ingredient(soybean_meal_43, '豆粕(43%)', plant_protein,
           43, 1.5, 7, 6, 12,    4.2, 50, 0).

% 豆粕 — 46% 蛋白 (高蛋白)
ingredient(soybean_meal_46, '豆粕(46%)', plant_protein,
           46, 1.5, 6, 6, 12,    4.6, 50, 0).

% 发酵豆粕
ingredient(fermented_soybean_meal, '发酵豆粕', plant_protein,
           50, 1, 4.5, 7, 10,    5.5, 30, 0).

% 菜粕 (普通)
ingredient(rapeseed_meal_regular, '菜粕(普通)', plant_protein,
           36, 2, 12, 8, 12,     2.8, 30, 0).

% 菜粕 (双低/Canola)
ingredient(canola_meal, '双低菜粕', plant_protein,
           38, 3, 10, 7, 12,     3.2, 35, 0).

% 棉粕 (普通)
ingredient(cottonseed_meal_regular, '棉粕(普通)', plant_protein,
           40, 1, 15, 7, 12,     3.0, 20, 0).

% 棉粕 (脱酚)
ingredient(cottonseed_meal_dephenol, '棉粕(脱酚)', plant_protein,
           45, 1, 12, 6, 12,     3.8, 25, 0).

% 花生粕
ingredient(peanut_meal, '花生粕', plant_protein,
           48, 1, 6, 6, 12,      4.0, 20, 0).

% 玉米蛋白粉 (CP 60%)
ingredient(corn_gluten_meal_60, '玉米蛋白粉(60%)', plant_protein,
           60, 2.5, 2, 3, 10,    5.8, 15, 0).

% 玉米 DDGS (含可溶物干酒糟)
ingredient(corn_ddgs, '玉米DDGS', plant_protein,
           28, 10, 8, 5, 10,     2.5, 20, 0).

% 大米蛋白粉
ingredient(rice_protein_meal, '大米蛋白粉', plant_protein,
           65, 2, 1, 5, 10,      5.0, 15, 0).

% ==========================================
% 3. 能量原料
% ==========================================

% 玉米
ingredient(corn, '玉米', energy,
           8.5, 3.5, 2, 1.5, 14, 2.4, 30, 0).

% 小麦
ingredient(wheat, '小麦', energy,
           13, 2, 2, 2, 13,      2.6, 30, 0).

% 次粉 (小麦加工副产品)
ingredient(wheat_middlings, '次粉', energy,
           15, 3, 8, 5, 12,      1.8, 25, 0).

% 面粉 (粘合剂 + 能量)
ingredient(wheat_flour, '面粉', energy,
           12, 1, 1, 0.5, 13,    3.2, 25, 5).

% 米糠 (全脂)
ingredient(rice_bran_fullfat, '米糠(全脂)', energy,
           14, 15, 8, 8, 10,     1.5, 15, 0).

% 脱脂米糠
ingredient(rice_bran_defatted, '米糠(脱脂)', energy,
           16, 2, 10, 12, 10,    1.8, 15, 0).

% 木薯粉 (α-淀粉, 虾料粘合剂)
ingredient(tapioca_starch, '木薯淀粉', energy,
           1, 0.5, 1, 1, 12,     4.0, 25, 0).

% 高粱
ingredient(sorghum, '高粱', energy,
           9, 3, 2, 2, 14,       2.0, 20, 0).

% ==========================================
% 4. 油脂类
% ==========================================

ingredient(fish_oil, '鱼油', oil,
           0, 99.5, 0, 0, 0,     15.0, 8, 1).

ingredient(soybean_oil, '豆油', oil,
           0, 99.5, 0, 0, 0,     10.0, 8, 1).

ingredient(rapeseed_oil, '菜籽油', oil,
           0, 99.5, 0, 0, 0,     9.5, 8, 1).

ingredient(soybean_lecithin, '磷脂油', oil,
           0, 95, 0, 0, 1,       8.0, 5, 0.5).

% ==========================================
% 5. 矿物质
% ==========================================

ingredient(dicalcium_phosphate, '磷酸氢钙', mineral,
           0, 0, 0, 95, 3,       4.0, 4, 1).
% Ca: ~23%, P: ~18%

ingredient(limestone_powder, '石粉', mineral,
           0, 0, 0, 98, 1,       0.3, 4, 0).
% Ca: ~38%

ingredient(salt, '食盐', mineral,
           0, 0, 0, 99, 1,       0.5, 0.5, 0.1).

ingredient(magnesium_sulfate, '硫酸镁', mineral,
           0, 0, 0, 99, 1,       2.0, 0.5, 0).

% ==========================================
% 6. 添加剂
% ==========================================

ingredient(premix_vitamin_aqua, '水产多维预混料', additive,
           0, 0, 0, 0, 1,        30.0, 2, 0.5).

ingredient(premix_mineral_aqua, '水产多矿预混料', additive,
           0, 0, 0, 0, 1,        20.0, 2, 0.5).

ingredient(choline_chloride_50, '氯化胆碱(50%)', additive,
           0, 0, 0, 0, 5,        6.0, 0.5, 0.1).

ingredient(vitamin_c_phosphate, '维生素C磷酸酯', additive,
           0, 0, 0, 0, 1,        45.0, 0.3, 0.02).

ingredient(antioxidant, '抗氧化剂(乙氧基喹啉)', additive,
           0, 0, 0, 0, 0,        25.0, 0.05, 0.01).

ingredient(mold_inhibitor, '防霉剂(丙酸钙)', additive,
           0, 0, 0, 0, 0,        15.0, 0.3, 0.05).

ingredient(phytase, '植酸酶', additive,
           0, 0, 0, 0, 0,        80.0, 0.05, 0.01).

% ═══════════════════════════════════════════════════════════════
% 成本单位声明 (P0-2)
% ═══════════════════════════════════════════════════════════════

% 所有原料价格单位为 元/kg
% 吨成本 = Σ(配方百分比 × 元/kg) × 10
% 合理成本区间: 3000 - 30000 元/吨
price_unit(Id, yuan_per_kg) :- ingredient(Id, _, _, _, _, _, _, _, _, _, _).

ingredient(betaine, '甜菜碱(诱食剂)', additive,
           0, 0, 0, 0, 0,        20.0, 0.5, 0).

ingredient(monocalcium_phosphate, '磷酸二氢钙', additive,
           0, 0, 0, 95, 3,       5.0, 3, 0.5).
% Ca: ~16%, P: ~22% — 水产首选磷源

% ==========================================
% 实用查询函数
% ==========================================

% 按分类列出原料
ingredients_by_category(Category, IngredientList) :-
    findall(ingredient(Id, Name, Category, Pro, Fat, Fib, Ash, Moist, Price, Max, Min),
            ingredient(Id, Name, Category, Pro, Fat, Fib, Ash, Moist, Price, Max, Min),
            IngredientList).

% 获取原料关键属性
ingredient_nutrition(Id, Protein, Fat, Fiber, Ash) :-
    ingredient(Id, _, _, Protein, Fat, Fiber, Ash, _, _, _, _).

% 获取原料成本
ingredient_cost(Id, Price) :-
    ingredient(Id, _, _, _, _, _, _, _, Price, _, _).

% 获取原料用量限制
ingredient_usage_limits(Id, Max, Min) :-
    ingredient(Id, _, _, _, _, _, _, _, _, Max, Min).

% 所有可用原料(排除添加剂 — 添加剂在配方求解中单独处理)
base_ingredient(Id) :-
    ingredient(Id, _, Category, _, _, _, _, _, _, _, _),
    Category \= additive.

% 所有添加剂
additive_ingredient(Id) :-
    ingredient(Id, _, additive, _, _, _, _, _, _, _, _).
