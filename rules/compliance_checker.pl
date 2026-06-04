% ============================================================
% compliance_checker.pl — 配方合规校验引擎
% AquaFeedFormulator 核心规则模块 4/5
% ============================================================
%
% 校验维度:
%   1. 饲料卫生标准 (GB 13078-2017)
%   2. 药物饲料添加剂禁令 (农业农村部公告第 194 号/第 2625 号)
%   3. 饲料原料目录合规 (农业农村部公告第 1773 号)
%   4. 添加剂用量合规 (农业部公告第 2625 号)
%   5. 标签规范 (GB 10648-2013)
%
% 谓词:
%   check_compliance(+Recipe, -Report)
%   Report = compliance_report(Passed, Violations, Warnings)
%
% 兼容性: scryer-prolog v0.10
%   - sum_list/2, length/2: 手动实现
%   - format/3: 替换为 atom_concat 拼接
% ============================================================

% ==== scryer-prolog 兼容: 工具谓词 ====

sum_list([], 0).
sum_list([H|T], Sum) :- sum_list(T, Rest), Sum is H + Rest.

append([], L, L).
append([H|T], L, [H|R]) :- append(T, L, R).

my_length([], 0).
my_length([_|T], N) :- my_length(T, N0), N is N0 + 1.

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

% ==========================================
% 1. 禁用物质检查
% ==========================================

% 禁用药物饲料添加剂 (2020年起全面禁用)
prohibited_additive(antibiotic_growth_promoter, '抗生素生长促进剂',
    '农业农村部公告第194号: 2020年7月1日起全面禁止饲料中添加促生长类药物').

% 禁用动物源成分 (反刍动物蛋白禁止用于所有饲料)
restricted_ingredient_direct(ruminant_mbm, '反刍动物源性肉骨粉',
    '农业农村部公告: 禁止反刍动物源性成分用于饲料').

restricted_ingredient_direct(melamine, '三聚氰胺',
    '农业部公告第1218号: 严禁在饲料中添加三聚氰胺').

restricted_ingredient_direct(sudan_red, '苏丹红',
    '农业部公告: 严禁在饲料中使用苏丹红等工业染料').

restricted_ingredient_direct(clenbuterol, '瘦肉精/盐酸克伦特罗',
    '农业部公告第176号: 禁止在饲料和动物饮用水中使用').

restricted_ingredient_direct(ractopamine, '莱克多巴胺',
    '农业部公告第176号: 禁止使用').

% ==========================================
% 2. 卫生指标限量 (GB 13078-2017)
% ==========================================

% 重金属限量 (mg/kg 饲料)
heavy_metal_limit(arsenic, '砷(As)', 2.0, 'GB 13078-2017').
heavy_metal_limit(lead, '铅(Pb)', 5.0, 'GB 13078-2017').
heavy_metal_limit(cadmium, '镉(Cd)', 0.5, 'GB 13078-2017').
heavy_metal_limit(mercury, '汞(Hg)', 0.1, 'GB 13078-2017').
heavy_metal_limit(chromium, '铬(Cr)', 5.0, 'GB 13078-2017').

% 真菌毒素限量 (μg/kg 饲料)
mycotoxin_limit(aflatoxin_b1, '黄曲霉毒素B1', 10.0, 'GB 13078-2017').
mycotoxin_limit(deoxynivalenol, '呕吐毒素(DON)', 1000.0, 'GB 13078-2017').
mycotoxin_limit(zearalenone, '玉米赤霉烯酮', 500.0, 'GB 13078-2017').
mycotoxin_limit(t2_toxin, 'T-2毒素', 100.0, 'GB 13078-2017').

% 其他有害物质
hazard_limit(cyanide, '氰化物', 50.0, 'GB 13078-2017').       % mg/kg
hazard_limit(nitrite, '亚硝酸盐', 15.0, 'GB 13078-2017').      % mg/kg
hazard_limit(free_gossypol, '游离棉酚', 200.0, 'GB 13078-2017').  % mg/kg
hazard_limit(isothiocyanate, '异硫氰酸酯', 500.0, 'GB 13078-2017').

% ==========================================
% 3. 原料合规检查
% ==========================================

% 饲料原料目录 (部分 — 农业农村部公告第1773号)
approved_feed_ingredient(fish_meal_peru_65).
approved_feed_ingredient(fish_meal_domestic_60).
approved_feed_ingredient(soybean_meal_43).
approved_feed_ingredient(soybean_meal_46).
approved_feed_ingredient(rapeseed_meal_regular).
approved_feed_ingredient(cottonseed_meal_regular).
approved_feed_ingredient(corn).
approved_feed_ingredient(wheat).
approved_feed_ingredient(wheat_flour).
approved_feed_ingredient(wheat_middlings).
approved_feed_ingredient(rice_bran_fullfat).
approved_feed_ingredient(rice_bran_defatted).
approved_feed_ingredient(corn_gluten_meal_60).
approved_feed_ingredient(corn_ddgs).
approved_feed_ingredient(fish_oil).
approved_feed_ingredient(soybean_oil).
approved_feed_ingredient(soybean_lecithin).
approved_feed_ingredient(dicalcium_phosphate).
approved_feed_ingredient(monocalcium_phosphate).
approved_feed_ingredient(limestone_powder).
approved_feed_ingredient(salt).
approved_feed_ingredient(blood_meal_spray).
approved_feed_ingredient(meat_bone_meal_50).
approved_feed_ingredient(poultry_meal).

% ==========================================
% 4. 添加剂用量合规
% ==========================================

% 水产饲料添加剂限量 (农业部公告第2625号)
% additive_limit(AdditiveId, MaxMgPerKg)

% 维生素类 — 上限不限(按推荐量), 但需注意:
% 维生素A: 过量有害, 建议 < 20000 IU/kg
% 维生素D3: 过量有害, 建议 < 5000 IU/kg

% 矿物质类 — 水产中需控制总磷
max_total_phosphorus(12.0).   % 总磷 ≤ 12 g/kg (1.2%)

% 抗氧化剂
additive_limit(ethoxyquin, '乙氧基喹啉', 150.0).   % 上限 150 mg/kg

% 防霉剂
additive_limit(propionic_acid, '丙酸', 3000.0).     % 上限 3000 mg/kg

% 色素类 — 虾青素在水产中无严格上限, 建议 < 80 mg/kg

% ==========================================
% 5. 校验执行
% ==========================================

% 主入口: 校验配方合规性
check_compliance(recipe(_, _, Items, _, _, _, _, _), Report) :-
    findall(V, check_violation(Items, V), AllViolations),
    (
        AllViolations = [] ->
            Report = compliance_report(passed, [], [])
        ;
            separate_violations(AllViolations, Critical, Warnings),
            Report = compliance_report(failed, Critical, Warnings)
    ).

% 逐项检查
check_violation(Items, Violation) :-
    member(item(Id, Name, Pct, _), Items),
    (
        % 检查 1: 禁用物质
        has_prohibited_substance(Id, Name, Violation)
        ;
        % 检查 2: 未批准原料
        \+ approved_feed_ingredient(Id),
        Violation = violation(warning, Name, '未在饲料原料目录中确认, 请核实合规性')
        ;
        % 检查 3: 高棉酚风险
        (Id == cottonseed_meal_regular ; Id == cottonseed_meal_dephenol),
        Pct > 20,
        Violation = violation(warning, Name, '棉粕用量超过20%, 游离棉酚风险升高, 建议控制在15%以内')
        ;
        % 检查 4: 高硫苷风险
        (Id == rapeseed_meal_regular),
        Pct > 25,
        Violation = violation(warning, Name, '菜粕用量超过25%, 硫苷/异硫氰酸酯风险, 建议用双低菜粕替代')
        ;
        % 检查 5: 鱼粉过量
        Id == fish_meal_peru_65,
        Pct > 45,
        Violation = violation(warning, Name, '鱼粉超过45%, 成本高且磷排放多, 建议控制在40%以内')
        ;
        % 检查 6: 总磷检查
        Id == dicalcium_phosphate ; Id == monocalcium_phosphate,
        find_total_phosphorus(Items, TotalP),
        TotalP > 1.2,
        Violation = violation(critical, '总磷含量', '总磷超过1.2%, 可能违反水产养殖排放标准(SC/T 9101)')
    ).

% ==========================================
% 辅助函数
% ==========================================

has_prohibited_substance(Id, Name, Violation) :-
    restricted_ingredient_direct(Id, _, Reason),
    Violation = violation(critical, Name, Reason).

find_total_phosphorus(Items, TotalP) :-
    findall(PContrib, (
        member(item(Id, _, Pct, _), Items),
        (
            Id == dicalcium_phosphate -> PContrib is Pct * 0.18
            ; Id == monocalcium_phosphate -> PContrib is Pct * 0.22
            ; PContrib = 0
        )
    ), PContribs),
    sum_list(PContribs, TotalP).

separate_violations([], [], []).
separate_violations([violation(critical, A, B) | Rest], [violation(critical, A, B) | Crits], Warnings) :-
    separate_violations(Rest, Crits, Warnings).
separate_violations([violation(warning, A, B) | Rest], Crits, [violation(warning, A, B) | Warnings]) :-
    separate_violations(Rest, Crits, Warnings).

% ==========================================
% 6. 配方整体评价
% ==========================================

% 评估配方质量 (用于对比排序)
evaluate_recipe_quality(recipe(_, _, Items, Cost, Protein, Fat, Fiber, Ash), Score, Remarks) :-
    % 评价维度:
    % - 动物蛋白占比 (越高越好, 水产需要)
    animal_protein_ratio(Items, AnimalRatio),
    % - 鱼粉占比 (优质但贵)
    fishmeal_ratio(Items, FishmealRatio),
    % - 多样化程度
    ingredient_count(Items, IngCount),
    % - 成本效率
    cost_per_protein(Cost, Protein, CostPerProtein),

    % 综合评分 (满分100)
    AnimalScore is min(25, AnimalRatio * 0.5),         % 动物蛋白得分 (max 25)
    FishmealScore is min(15, FishmealRatio * 0.5),     % 鱼粉得分 (max 15)
    DiversityScore is min(10, IngCount),                 % 多样得分 (max 10)
    CostScore is max(0, 50 - CostPerProtein * 0.5),     % 成本得分 (max 50)

    Score is AnimalScore + FishmealScore + DiversityScore + CostScore,

    concat_remarks(AnimalRatio, FishmealRatio, IngCount, CostPerProtein, Remarks).

animal_protein_ratio(Items, Ratio) :-
    findall(Pct, (
        member(item(Id, _, Pct, _), Items),
        ingredient(Id, _, Category, _, _, _, _, _, _, _, _),
        member(Category, [animal_protein])
    ), Pcts),
    sum_list(Pcts, Ratio).

fishmeal_ratio(Items, Ratio) :-
    findall(Pct, (
        member(item(Id, _, Pct, _), Items),
        (Id == fish_meal_peru_65 ; Id == fish_meal_domestic_60 ; Id == fish_meal_white_68)
    ), Pcts),
    sum_list(Pcts, Ratio).

ingredient_count(Items, Count) :-
    my_length(Items, Count).

cost_per_protein(Cost, Protein, Ratio) :-
    Protein > 0,
    Ratio is Cost / Protein.

% 简化版: 用 compound term 代替 format/3 (scryer-prolog 兼容)
concat_remarks(AR, FR, IC, CPP, remarks(AR, FR, IC, CPP)).

% ==========================================
% 7. 全维度合规校验 (v3 新增: 集成闭合+功能完整性)
% ==========================================

% 增强版合规入口: 合并原有合规检查 + 配方闭合校验 + 功能完整性检查
check_compliance_full(Recipe, FullReport) :-
    % 7.1 原有合规检查 (禁用物质 / 原料合规 / 用量安全)
    check_compliance(Recipe, SafeReport),

    % 7.2 配方闭合 + 品类约束检查 (v3 新增)
    validate_formula_closure(Recipe, ClosureReport),

    % 7.3 功能完整性检查 (v3 新增)
    Recipe = recipe(Species, Stage, Items, _, _, _, _, _),
    check_functional_completeness(Species, Stage, Items, FuncReport),

    % 7.4 合并三份报告
    merge_all_reports(SafeReport, ClosureReport, FuncReport, FullReport).

% 合并三份合规报告
merge_all_reports(
    compliance_report(SafePassed, SafeCrits, SafeWarns),
    closure_report(ClosurePassed, TotalPct, ClosureCrits, ClosureWarns),
    functional_report(FuncPassed, FuncCovered, FuncMissing, FuncWeak),
    full_compliance_report(OverallPassed, TotalPct,
                          AllCriticals, AllWarnings, FuncMissingGroups)
) :-
    append(SafeCrits, ClosureCrits, TempCrits),
    % 将功能缺失组转为违规
    findall(critical_fault(G, N, D, MP), (
        member(group_result(G, N, D, missing, _, MP, _), FuncMissing)
    ), FuncCrits),
    append(TempCrits, FuncCrits, AllCriticals),
    append(SafeWarns, ClosureWarns, TempWarns),
    append(TempWarns, FuncWeak, AllWarnings),
    (
        SafePassed = passed, ClosurePassed = passed, FuncPassed = passed ->
            OverallPassed = passed
        ;
            OverallPassed = failed
    ),
    FuncMissingGroups = FuncMissing.
