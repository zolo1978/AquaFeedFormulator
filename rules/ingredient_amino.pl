% ============================================================
% ingredient_amino.pl — 水产饲料原料氨基酸谱数据库
% AquaFeedFormulator M6 eaa_balance 依赖
% ============================================================
%
% 数据来源:
%   - 中国饲料成分及营养价值表 (2024 第35版)
%   - NRC Nutrient Requirements of Fish and Shrimp (2011)
%   - CVB Feed Table (2018, Netherlands)
%   - Feedipedia (INRAE/CIRAD/AFZ)
%
% 谓词: ingredient_amino(+Id, +Lys%, +Met%, +MetCys%, +Thr%,
%        +Trp%, +Arg%, +Ile%, +Leu%, +Val%, +His%, +Phe%)
%
% 所有数值: g/100g 原料 (风干基础 / as-fed basis)
%
% 说明:
%   - Lys = 赖氨酸 (第一限制性AA for 多数植物蛋白配方)
%   - Met = 蛋氨酸 (第一限制性AA for 豆粕基配方)
%   - MetCys = 蛋氨酸+胱氨酸 (TSAA总含硫氨基酸)
%   - Thr = 苏氨酸
%   - Trp = 色氨酸
%   - Arg = 精氨酸
%   - Ile/Ile = 异亮氨酸
%   - Leu = 亮氨酸
%   - Val = 缬氨酸
%   - His = 组氨酸
%   - Phe = 苯丙氨酸 (Phe+Tyr 可部分替代)
%
% 非蛋白原料 (油脂/矿物/添加剂) AA 含量按 0.0 处理,
% 由 eaa_balance 中的默认规则兜底.
% ============================================================

% ═══════════════════════════════════════════════════════════════
% 1. 动物蛋白源
% ═══════════════════════════════════════════════════════════════

% 鱼粉 — 秘鲁蒸汽鱼粉 (FAQ 65%)
ingredient_amino(fish_meal_peru_65, 4.90, 1.85, 2.42, 2.70, 0.70,
                 3.80, 2.80, 4.80, 3.30, 1.70, 2.70).

% 鱼粉 — 国产鱼粉 (FAQ 60%)
ingredient_amino(fish_meal_domestic_60, 4.30, 1.60, 2.10, 2.35, 0.60,
                 3.40, 2.40, 4.20, 2.90, 1.45, 2.35).

% 鱼粉 — 白鱼粉 (FAQ 68%, 高端)
ingredient_amino(fish_meal_white_68, 5.30, 2.00, 2.60, 2.90, 0.75,
                 4.10, 3.00, 5.20, 3.55, 1.85, 2.90).

% 血粉 — 喷雾干燥 (极高 Lys, 极低 Met/Ile)
ingredient_amino(blood_meal_spray, 7.00, 0.70, 1.61, 3.20, 1.10,
                 3.50, 0.90, 10.30, 6.50, 4.90, 5.30).

% 肉骨粉 (CP 50%)
ingredient_amino(meat_bone_meal_50, 2.60, 0.70, 0.98, 1.70, 0.28,
                 3.50, 1.50, 3.20, 2.20, 1.00, 1.70).

% 鸡肉粉
ingredient_amino(poultry_meal, 3.20, 1.15, 2.00, 2.30, 0.50,
                 3.80, 2.10, 4.00, 2.70, 1.20, 2.20).

% 虾壳粉
ingredient_amino(shrimp_shell_meal, 1.60, 0.65, 0.80, 1.20, 0.30,
                 2.60, 1.30, 2.20, 1.70, 0.70, 1.40).

% 鱿鱼膏 (诱食剂 + 蛋白)
ingredient_amino(squid_liver_paste, 2.40, 0.95, 1.20, 1.60, 0.40,
                 2.80, 1.60, 2.80, 1.80, 0.80, 1.60).

% 蚕蛹粉
ingredient_amino(silkworm_pupae_meal, 3.20, 1.10, 1.50, 2.00, 0.60,
                 3.00, 2.00, 3.50, 2.50, 1.20, 2.40).

% ═══════════════════════════════════════════════════════════════
% 2. 植物蛋白源
% ═══════════════════════════════════════════════════════════════

% 豆粕 — 43% 蛋白
ingredient_amino(soybean_meal_43, 2.68, 0.59, 1.20, 1.71, 0.57,
                 3.08, 1.93, 3.29, 2.04, 1.13, 2.18).

% 豆粕 — 46% 蛋白 (高蛋白)
ingredient_amino(soybean_meal_46, 2.83, 0.62, 1.27, 1.82, 0.60,
                 3.28, 2.05, 3.50, 2.18, 1.21, 2.33).

% 发酵豆粕
ingredient_amino(fermented_soybean_meal, 3.00, 0.65, 1.25, 1.95, 0.58,
                 3.40, 2.20, 3.80, 2.30, 1.20, 2.50).

% 菜粕 (普通)
ingredient_amino(rapeseed_meal_regular, 1.70, 0.60, 1.20, 1.50, 0.40,
                 2.10, 1.40, 2.50, 1.80, 0.90, 1.40).

% 双低菜粕 (Canola)
ingredient_amino(canola_meal, 2.00, 0.70, 1.50, 1.75, 0.50,
                 2.30, 1.50, 2.70, 2.00, 1.00, 1.55).

% 棉粕 (普通)
ingredient_amino(cottonseed_meal_regular, 1.60, 0.50, 1.10, 1.30, 0.35,
                 3.60, 1.20, 2.20, 1.80, 1.00, 1.90).

% 棉粕 (脱酚)
ingredient_amino(cottonseed_meal_dephenol, 1.80, 0.55, 1.20, 1.45, 0.38,
                 4.00, 1.35, 2.50, 2.00, 1.10, 2.10).

% 花生粕
ingredient_amino(peanut_meal, 1.54, 0.54, 1.01, 1.28, 0.42,
                 5.20, 1.60, 2.90, 1.90, 1.00, 2.30).

% 玉米蛋白粉 (CP 60%)
ingredient_amino(corn_gluten_meal_60, 0.95, 1.40, 2.00, 2.00, 0.25,
                 1.80, 2.30, 9.50, 2.80, 1.20, 3.60).

% 玉米 DDGS
ingredient_amino(corn_ddgs, 0.80, 0.55, 1.05, 1.05, 0.20,
                 1.20, 1.05, 2.90, 1.40, 0.70, 1.40).

% 大米蛋白粉
ingredient_amino(rice_protein_meal, 2.00, 1.80, 2.50, 2.50, 0.80,
                 5.00, 2.80, 5.50, 3.80, 1.50, 3.50).

% ═══════════════════════════════════════════════════════════════
% 3. 能量原料
% ═══════════════════════════════════════════════════════════════

ingredient_amino(corn, 0.24, 0.18, 0.35, 0.29, 0.07,
                 0.38, 0.28, 0.95, 0.38, 0.22, 0.38).

ingredient_amino(wheat, 0.30, 0.16, 0.35, 0.30, 0.13,
                 0.47, 0.38, 0.68, 0.48, 0.24, 0.48).

ingredient_amino(wheat_flour, 0.22, 0.14, 0.30, 0.24, 0.10,
                 0.36, 0.30, 0.55, 0.36, 0.19, 0.38).

ingredient_amino(wheat_middlings, 0.55, 0.20, 0.45, 0.45, 0.20,
                 0.82, 0.50, 0.90, 0.65, 0.35, 0.55).

ingredient_amino(rice_bran_fullfat, 0.50, 0.22, 0.44, 0.42, 0.12,
                 0.80, 0.40, 0.72, 0.58, 0.30, 0.48).

ingredient_amino(rice_bran_defatted, 0.56, 0.25, 0.50, 0.48, 0.14,
                 0.90, 0.46, 0.82, 0.66, 0.34, 0.54).

ingredient_amino(sorghum, 0.20, 0.15, 0.28, 0.30, 0.09,
                 0.35, 0.38, 1.15, 0.48, 0.20, 0.48).

ingredient_amino(tapioca_starch, 0.05, 0.03, 0.05, 0.04, 0.01,
                 0.08, 0.04, 0.06, 0.05, 0.03, 0.04).

% ═══════════════════════════════════════════════════════════════
% 实用查询函数
% ═══════════════════════════════════════════════════════════════

% 获取原料单个氨基酸含量
amino_content(Id, lys, Lys)       :- ingredient_amino(Id, Lys, _, _, _, _, _, _, _, _, _, _).
amino_content(Id, met, Met)       :- ingredient_amino(Id, _, Met, _, _, _, _, _, _, _, _, _).
amino_content(Id, met_cys, MC)    :- ingredient_amino(Id, _, _, MC, _, _, _, _, _, _, _, _).
amino_content(Id, thr, Thr)       :- ingredient_amino(Id, _, _, _, Thr, _, _, _, _, _, _, _).
amino_content(Id, trp, Trp)       :- ingredient_amino(Id, _, _, _, _, Trp, _, _, _, _, _, _).
amino_content(Id, arg, Arg)       :- ingredient_amino(Id, _, _, _, _, _, Arg, _, _, _, _, _).
amino_content(Id, ile, Ile)       :- ingredient_amino(Id, _, _, _, _, _, _, Ile, _, _, _, _).
amino_content(Id, leu, Leu)       :- ingredient_amino(Id, _, _, _, _, _, _, _, Leu, _, _, _).
amino_content(Id, val, Val)       :- ingredient_amino(Id, _, _, _, _, _, _, _, _, Val, _, _).
amino_content(Id, his, His)       :- ingredient_amino(Id, _, _, _, _, _, _, _, _, _, His, _).
amino_content(Id, phe, Phe)       :- ingredient_amino(Id, _, _, _, _, _, _, _, _, _, _, Phe).

% 判断原料是否有氨基酸数据 (非蛋白原料自动为 0)
has_amino_data(Id) :- ingredient_amino(Id, _, _, _, _, _, _, _, _, _, _, _), !.

% 所有有氨基酸数据的原料列表
amino_ingredients(List) :-
    findall(Id, ingredient_amino(Id, _, _, _, _, _, _, _, _, _, _, _), Unsorted),
    sort(Unsorted, List).
