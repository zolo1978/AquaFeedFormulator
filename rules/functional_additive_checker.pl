% ============================================================
% functional_additive_checker.pl — 功能性添加剂完整性检查
% AquaFeedFormulator 核心规则模块 7/9
% ============================================================
%
% 功能:
%   1. 按物种×阶段检查功能性添加剂组覆盖度
%   2. 鳗鱼 4 个功能组: 诱食 / 肝胆保护 / 肠道稳定 / 水稳定
%   3. 报告缺失的功能组和推荐原料
%
% 背景:
%   ChatGPT 评审指出: 方案缺少牛磺酸、肌醇、谷朊粉、酵母细胞壁、
%   芽孢杆菌等功能性添加剂, 且未按功能组展开成产品卖点体系。
%
% 谓词:
%   check_functional_completeness(+Species, +Stage, +Items, -FunctionalReport)
%
% 兼容性: scryper-prolog v0.10
% ============================================================

% ==== scryper-prolog 兼容: 工具谓词 ====

sum_list([], 0).
sum_list([H|T], Sum) :- sum_list(T, Rest), Sum is H + Rest.

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

my_length([], 0).
my_length([_|T], N) :- my_length(T, N0), N is N0 + 1.

% ==========================================
% 1. 功能组定义
% ==========================================

% functional_group(GroupId, GroupName, Description, MinMembers, Severity)
% MinMembers: 最少需要覆盖几种功能原料
% Severity: high(缺少影响生产性能) | medium(影响产品竞争力)

functional_group(attractant, '诱食体系', '促进摄食:核苷酸/小肽/氨基酸诱食', 2, high).
functional_group(liver_protection, '肝胆保护', '防止脂肪肝/肝胆综合症', 2, high).
functional_group(gut_health, '肠道稳定', '益生菌/酶制剂/免疫增强', 1, medium).
functional_group(water_stability, '水稳定', '预糊化淀粉/谷朊粉:防止饲料溃散', 1, high).

% ==========================================
% 2. 原料→功能组 映射
% ==========================================

% ---- 诱食体系 ----
functional_member(attractant, squid_liver_paste, '鱿鱼膏', primary).
functional_member(attractant, betaine, '甜菜碱', primary).
functional_member(attractant, shrimp_shell_meal, '虾壳粉', secondary).
functional_member(attractant, fish_meal_peru_65, '鱼粉(兼引诱食)', auxiliary).
functional_member(attractant, fish_meal_domestic_60, '鱼粉(兼引诱食)', auxiliary).
% 以下原料 IDB 中暂无, 但功能重要:
% functional_member(attractant, yeast_extract, '酵母抽提物', primary).
% functional_member(attractant, taurine, '牛磺酸', primary).

% ---- 肝胆保护 ----
functional_member(liver_protection, choline_chloride_50, '氯化胆碱', primary).
functional_member(liver_protection, soybean_lecithin, '磷脂油', primary).
functional_member(liver_protection, vitamin_c_phosphate, '维生素C磷酸酯', secondary).
functional_member(liver_protection, fish_oil, '鱼油(兼供磷脂)', auxiliary).
% 以下原料 IDB 中暂无:
% functional_member(liver_protection, taurine, '牛磺酸', primary).
% functional_member(liver_protection, inositol, '肌醇', primary).

% ---- 肠道稳定 ----
functional_member(gut_health, phytase, '植酸酶', primary).
functional_member(gut_health, fermented_soybean_meal, '发酵豆粕', secondary).
functional_member(gut_health, premix_vitamin_aqua, '多维(兼免疫)', auxiliary).
% 以下原料 IDB 中暂无:
% functional_member(gut_health, yeast_cell_wall, '酵母细胞壁', primary).
% functional_member(gut_health, bacillus, '芽孢杆菌', primary).
% functional_member(gut_health, complex_enzyme, '复合酶', primary).

% ---- 水稳定 ----
functional_member(water_stability, tapioca_starch, '木薯淀粉', primary).
functional_member(water_stability, wheat_flour, '面粉', primary).
functional_member(water_stability, wheat_gluten, '谷朊粉', primary).
functional_member(water_stability, corn_gluten_meal_60, '玉米蛋白粉', secondary).

% ==========================================
% 3. 物种×阶段 功能组要求
% ==========================================

% 鳗鱼 — 全阶段需要 4 个功能组
species_functional_requirement(japanese_eel, _, attractant, 2).
species_functional_requirement(japanese_eel, _, liver_protection, 2).
species_functional_requirement(japanese_eel, _, gut_health, 1).
species_functional_requirement(japanese_eel, _, water_stability, 1).

% 白仔鳗 — 更高要求
species_functional_requirement(japanese_eel, glass_eel, attractant, 3).
species_functional_requirement(japanese_eel, glass_eel, liver_protection, 3).

% 虾 — 水稳定要求更高
species_functional_requirement(white_shrimp, _, water_stability, 2).

% 通用水产
species_functional_requirement(_, _, attractant, 1).
species_functional_requirement(_, _, liver_protection, 1).
species_functional_requirement(_, _, gut_health, 0).     % 可选
species_functional_requirement(_, _, water_stability, 1).

% ==========================================
% 4. 主入口: 功能完整性检查
% ==========================================

check_functional_completeness(Species, Stage, Items, Report) :-
    findall(G, functional_group(G, _, _, _, _), AllGroups),
    check_all_groups(AllGroups, Species, Stage, Items, GroupResults),
    separate_functional_results(GroupResults, Passed, Missing, Weak),
    (
        Missing = [], Weak = [] ->
            Report = functional_report(passed, Passed, [], [])
        ;
            Report = functional_report(failed, Passed, Missing, Weak)
    ).

% 逐组检查
check_all_groups([], _, _, _, []).
check_all_groups([G | Rest], Species, Stage, Items, [Result | RestResults]) :-
    check_single_group(G, Species, Stage, Items, Result),
    check_all_groups(Rest, Species, Stage, Items, RestResults).

% 检查单个功能组
check_single_group(Group, Species, Stage, Items, Result) :-
    functional_group(Group, Name, Desc, _, Severity),

    % 获取该组的成员要求
    (
        species_functional_requirement(Species, Stage, Group, Required) ->
            true
        ;
            species_functional_requirement(Species, _, Group, Required) ->
            true
        ;
            species_functional_requirement(_, _, Group, Required) ->
            true
        ;
            Required = 0
    ),

    % 统计配方中该组成员覆盖数
    count_functional_members(Group, Items, ActualCount, CoveredMembers, MissingPrimary),

    % 判断
    (
        Required = 0 ->
            Result = group_result(Group, Name, Desc, skipped, CoveredMembers, [], [])
        ;
        ActualCount >= Required ->
            Result = group_result(Group, Name, Desc, covered, CoveredMembers, [], [])
        ;
            MissingPrimary \= [] ->
            % 缺少主要功能原料
            Result = group_result(Group, Name, Desc, missing,
                                 CoveredMembers, MissingPrimary, Required)
        ;
            % 覆盖不足但无特定缺失(因为成员总数就不够)
            Result = group_result(Group, Name, Desc, weak,
                                 CoveredMembers, MissingPrimary, Required)
    ).

% ==========================================
% 5. 辅助函数
% ==========================================

% 统计配方中某功能组的覆盖
count_functional_members(Group, Items, Count, Covered, MissingPrimary) :-
    findall(member_info(Id, Name, Role), (
        % 收集配方中属于该功能组的原料
        member(item(Id, Name, _, _), Items),
        functional_member(Group, Id, Name, Role)
    ), Covered),

    % 统计该组所有 primary 成员
    findall(primary_missing(Id, RecName), (
        functional_member(Group, Id, RecName, primary),
        \+ member(item(Id, _, _, _), Items)   % 不在配方中
    ), MissingPrimary),

    my_length(Covered, Count).

% 分类结果
separate_functional_results([], [], [], []).
separate_functional_results([group_result(G, N, D, covered, C, _, _) | Rest],
                            [group_result(G, N, D, covered, C, [], []) | P], M, W) :-
    separate_functional_results(Rest, P, M, W).
separate_functional_results([group_result(G, N, D, missing, C, MP, R) | Rest],
                            P, [group_result(G, N, D, missing, C, MP, R) | M], W) :-
    separate_functional_results(Rest, P, M, W).
separate_functional_results([group_result(G, N, D, weak, C, MP, R) | Rest],
                            P, M, [group_result(G, N, D, weak, C, MP, R) | W]) :-
    separate_functional_results(Rest, P, M, W).
separate_functional_results([group_result(_, _, _, skipped, _, _, _) | Rest],
                            P, M, W) :-
    separate_functional_results(Rest, P, M, W).

% ==========================================
% 6. 推荐缺失原料
% ==========================================

% 为缺失功能组推荐原料
recommend_missing_ingredients(Group, Recommendations) :-
    findall(rec(Id, Name, Reason), (
        functional_member(Group, Id, Name, primary),
        Reason = '功能组必需原料, 当前配方中缺失'
    ), Recommendations).

% 批量推荐
recommend_all_missing(MissingGroups, AllRecs) :-
    findall(rec(Group, Id, Name, Reason), (
        member(group_result(Group, _, _, missing, _, _, _), MissingGroups),
        recommend_missing_ingredients(Group, Recs),
        member(rec(Id, Name, Reason), Recs)
    ), AllRecs).
