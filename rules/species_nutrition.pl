% ============================================================
% species_nutrition.pl — 水产养殖物种营养需求数据库
% AquaFeedFormulator 核心规则模块 1/5
% ============================================================
%
% 数据来源:
%   - NRC Nutrient Requirements of Fish and Shrimp (2011)
%   - 水产动物营养与饲料配方 (侯永清, 2001)
%   - 水产动物饲料配方与配制技术 (张家国)
%   - 中国饲料成分及营养价值表 (2024)
%
% 谓词: species_nutrition(Species, Stage, Protein%, Fat%, FiberMax%, AshMax%)
%   单位: % 干物质基础
% ============================================================

% ---------- 鲤科鱼类 ----------

% 鲤鱼 (Cyprinus carpio / Common carp)
species_nutrition(common_carp, fry,        38, 8,  4, 12).
species_nutrition(common_carp, juvenile,   34, 7,  6, 10).
species_nutrition(common_carp, adult,      30, 5,  8, 10).
species_nutrition(common_carp, broodstock, 36, 8,  6, 12).

% 草鱼 (Ctenopharyngodon idella / Grass carp)
species_nutrition(grass_carp, fry,         38, 6,  5, 12).
species_nutrition(grass_carp, juvenile,    32, 5,  8, 12).
species_nutrition(grass_carp, adult,       28, 4,  10, 12).
species_nutrition(grass_carp, broodstock,  34, 6,  6, 12).

% 鲫鱼 (Carassius auratus / Crucian carp)
species_nutrition(crucian_carp, fry,       40, 8,  4, 12).
species_nutrition(crucian_carp, juvenile,  36, 7,  5, 10).
species_nutrition(crucian_carp, adult,     32, 5,  8, 10).
species_nutrition(crucian_carp, broodstock, 38, 7,  5, 12).

% 青鱼 (Mylopharyngodon piceus / Black carp)
species_nutrition(black_carp, fry,         40, 7,  4, 12).
species_nutrition(black_carp, juvenile,    35, 6,  6, 12).
species_nutrition(black_carp, adult,       30, 5,  8, 12).
species_nutrition(black_carp, broodstock,  36, 7,  5, 12).

% 团头鲂/武昌鱼 (Megalobrama amblycephala / Wuchang bream)
species_nutrition(wuchang_bream, fry,      36, 6,  6, 12).
species_nutrition(wuchang_bream, juvenile, 30, 5,  10, 12).
species_nutrition(wuchang_bream, adult,    27, 4,  12, 12).
species_nutrition(wuchang_bream, broodstock, 32, 6,  8, 12).

% ---------- 鲶科鱼类 ----------

% 斑点叉尾鮰/沟鲶 (Ictalurus punctatus / Channel catfish)
species_nutrition(channel_catfish, fry,      36, 6,  5, 10).
species_nutrition(channel_catfish, juvenile, 32, 5,  7, 10).
species_nutrition(channel_catfish, adult,    28, 4,  10, 10).
species_nutrition(channel_catfish, broodstock, 34, 6, 6, 10).

% 南方大口鲶 (Silurus meridionalis)
species_nutrition(southern_catfish, fry,      42, 8,  3, 12).
species_nutrition(southern_catfish, juvenile, 38, 7,  5, 12).
species_nutrition(southern_catfish, adult,    34, 6,  6, 12).

% ---------- 丽鱼科 ----------

% 罗非鱼 (Oreochromis niloticus / Tilapia)
species_nutrition(tilapia, fry,         40, 8,  4, 12).
species_nutrition(tilapia, juvenile,    36, 7,  6, 10).
species_nutrition(tilapia, adult,       30, 5,  8, 10).
species_nutrition(tilapia, broodstock,  38, 8,  5, 12).

% ---------- 鲑鳟科 ----------

% 虹鳟 (Oncorhynchus mykiss / Rainbow trout)
species_nutrition(rainbow_trout, fry,       45, 16, 2, 10).
species_nutrition(rainbow_trout, juvenile,  42, 14, 3, 10).
species_nutrition(rainbow_trout, adult,     38, 10, 4, 10).
species_nutrition(rainbow_trout, broodstock, 42, 14, 3, 10).

% 大西洋鲑 (Salmo salar / Atlantic salmon)
species_nutrition(atlanic_salmon, fry,       50, 18, 1, 8).
species_nutrition(atlanic_salmon, juvenile,  45, 16, 2, 8).
species_nutrition(atlanic_salmon, adult,     40, 12, 3, 8).
species_nutrition(atlanic_salmon, broodstock, 45, 16, 2, 8).

% ---------- 甲壳类 ----------

% 南美白对虾 (Litopenaeus vannamei / Whiteleg shrimp)
species_nutrition(white_shrimp, zoea,      45, 8,  3, 14).
species_nutrition(white_shrimp, mysis,     42, 7,  4, 14).
species_nutrition(white_shrimp, postlarva, 40, 7,  4, 14).
species_nutrition(white_shrimp, juvenile,  38, 6,  5, 14).
species_nutrition(white_shrimp, adult,     35, 5,  5, 14).

% 斑节对虾/草虾 (Penaeus monodon / Giant tiger prawn)
species_nutrition(tiger_prawn, postlarva,  42, 7,  4, 14).
species_nutrition(tiger_prawn, juvenile,   40, 6,  4, 14).
species_nutrition(tiger_prawn, adult,      36, 5,  5, 14).

% 罗氏沼虾 (Macrobrachium rosenbergii / Giant freshwater prawn)
species_nutrition(giant_river_prawn, postlarva, 38, 6,  5, 12).
species_nutrition(giant_river_prawn, juvenile,  35, 5,  6, 12).
species_nutrition(giant_river_prawn, adult,     32, 5,  8, 12).

% 中华绒螯蟹/大闸蟹 (Eriocheir sinensis / Chinese mitten crab)
species_nutrition(chinese_mitten_crab, zoea,      45, 8,  3, 12).
species_nutrition(chinese_mitten_crab, megalopa,  42, 7,  4, 12).
species_nutrition(chinese_mitten_crab, juvenile,  38, 7,  5, 12).
species_nutrition(chinese_mitten_crab, adult,     32, 6,  6, 12).
species_nutrition(chinese_mitten_crab, fattening, 36, 8,  5, 12).

% ---------- 其他 ----------

% 鳗鲡/日本鳗 (Anguilla japonica / Japanese eel)
species_nutrition(japanese_eel, elver,    48, 8,  2, 12).
species_nutrition(japanese_eel, juvenile, 45, 7,  3, 12).
species_nutrition(japanese_eel, adult,    42, 6,  4, 12).

% 黄颡鱼 (Pelteobagrus fulvidraco / Yellow catfish)
species_nutrition(yellow_catfish, fry,      42, 8,  3, 12).
species_nutrition(yellow_catfish, juvenile, 38, 7,  5, 12).
species_nutrition(yellow_catfish, adult,    34, 6,  6, 12).

% 加州鲈/大口黑鲈 (Micropterus salmoides / Largemouth bass)
species_nutrition(largemouth_bass, fry,      48, 10, 2, 12).
species_nutrition(largemouth_bass, juvenile, 45, 9,  3, 12).
species_nutrition(largemouth_bass, adult,    42, 8,  3, 12).

% 乌鳢/黑鱼 (Channa argus / Snakehead)
species_nutrition(snakehead, fry,      45, 8,  3, 12).
species_nutrition(snakehead, juvenile, 42, 7,  3, 12).
species_nutrition(snakehead, adult,    38, 6,  4, 12).

% ---------- 实用函数 ----------

% 获取某个物种的所有生长阶段
species_stages(Species, Stages) :-
    findall(Stage, species_nutrition(Species, Stage, _, _, _, _), StagesUnsorted),
    sort(StagesUnsorted, Stages).

% 获取所有支持的物种列表
all_species(SpeciesList) :-
    findall(Species, species_nutrition(Species, _, _, _, _, _), Unsorted),
    sort(Unsorted, SpeciesList).

% 检查物种+阶段组合是否合法
valid_species_stage(Species, Stage) :-
    species_nutrition(Species, Stage, _, _, _, _),
    !.

% ═══════════════════════════════════════════════════════════════
% 物种矿物需求 (M5 mineral_balance 依赖)
% species_mineral_requirement(+Species, +Stage,
%     +AvailP_min_pct, +Ca_p_ratio_min, +Ca_p_ratio_max)
%
% AvailP_min_pct: 有效磷最低需求 (% 配方)
% Ca_p_ratio_min/max: Ca/P 比值范围
% 数据来源: NRC 2011 + GB/T 水生动物营养需要
% ═══════════════════════════════════════════════════════════════

species_mineral_requirement(japanese_eel,    adult, 0.60, 1.0, 1.5).
species_mineral_requirement(white_shrimp,    adult, 0.80, 1.0, 1.8).
species_mineral_requirement(common_carp,     adult, 0.55, 1.0, 2.0).
species_mineral_requirement(grass_carp,      adult, 0.50, 1.0, 2.0).
species_mineral_requirement(largemouth_bass, adult, 0.65, 1.0, 1.5).

% ═══════════════════════════════════════════════════════════════
% 物种必需氨基酸需求 (M6 eaa_balance 依赖)
% species_amino_requirement(+Species, +Stage,
%     +Lys%, +Met%, +MetCys%, +Thr%, +Trp%,
%     +Arg%, +Ile%, +Leu%, +Val%, +His%, +Phe%)
%
% 所有数值: g/100g 日粮 (风干基础 / as-fed basis)
% 数据来源: NRC 2011 + 各物种专项研究
% ═══════════════════════════════════════════════════════════════

% 鳗鲡/日本鳗 (Anguilla japonica) — 成体, 42% CP
species_amino_requirement(japanese_eel, adult,
    2.10, 0.90, 1.20, 1.60, 0.22,
    1.70, 1.50, 2.70, 1.80, 0.80, 1.80).

% 南美白对虾 (Litopenaeus vannamei) — 成体, 35% CP
species_amino_requirement(white_shrimp, adult,
    1.80, 0.70, 1.10, 1.40, 0.20,
    1.80, 1.20, 1.80, 1.40, 0.60, 1.40).

% 鲤鱼 (Cyprinus carpio) — 成体, 30% CP
species_amino_requirement(common_carp, adult,
    1.70, 0.60, 0.90, 1.20, 0.20,
    1.30, 0.90, 1.70, 1.20, 0.60, 1.50).

% 草鱼 (Ctenopharyngodon idella) — 成体, 28% CP
species_amino_requirement(grass_carp, adult,
    1.50, 0.50, 0.80, 1.05, 0.15,
    1.20, 0.80, 1.50, 1.05, 0.50, 1.20).

% 加州鲈 (Micropterus salmoides) — 成体, 42% CP
species_amino_requirement(largemouth_bass, adult,
    2.30, 1.10, 1.40, 1.80, 0.25,
    2.00, 1.60, 3.00, 1.90, 0.90, 2.00).
