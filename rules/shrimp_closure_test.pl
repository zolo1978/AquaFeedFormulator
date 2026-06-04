% ============================================================
% shrimp_closure_test.pl — 南美白对虾饲料配方闭合校验测试
% 生成日期: 2026-06-04
% ============================================================
%
% 目标物种: white_shrimp (南美白对虾), juvenile 阶段
% 营养需求: Protein 38%, Fat 6%, Fiber max 5%, Ash max 14%
% 品类约束: 淀粉 ≤ 20%, 动物蛋白 ≥ 25%
%
% 测试场景:
%   test_shrimp_a: 方案A, 高鱼粉型, 100.30% → 应报 over
%   test_shrimp_b: 方案B, 中鱼粉型, 97.80%  → 应报 under
%   test_shrimp_c: 方案C, 低鱼粉+高淀粉, 95.80% → 应报 under + 淀粉超标
%   test_shrimp_ok: 正常配方, 100.00% → 应通过
% ============================================================

% === scryper-prolog 兼容 ===
sum_list([], 0).
sum_list([H|T], Sum) :- sum_list(T, Rest), Sum is H + Rest.

% ==========================================
% 方案A: 高鱼粉型 — 100.30% (微超 0.30%)
%   淀粉: wheat_flour 18.0% → 18% < 20% ✅
%   动物蛋白: 23+7+5+4 = 39% > 25% ✅
% ==========================================
test_shrimp_recipe_a(recipe(white_shrimp, juvenile, Items, 13800, 39.2, 6.5, 3.8, 10.5)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 23.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 7.0, 0),
        item(shrimp_shell_meal, '虾壳粉', 5.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 4.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 15.0, 0),
        item(peanut_meal, '花生粕', 5.0, 0),
        item(cottonseed_meal_dephenol, '棉粕(脱酚)', 4.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(wheat_flour, '面粉', 18.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 3.0, 0),
        item(rice_bran, '米糠', 3.05, 0),
        item(fish_oil, '鱼油', 2.5, 0),
        item(soybean_lecithin, '磷脂油', 1.5, 0),
        item(cholesterol, '胆固醇', 0.3, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 1.8, 0),
        item(premix_vitamin_aqua, '多维', 0.5, 0),
        item(premix_mineral_aqua, '多矿', 0.5, 0),
        item(betaine, '甜菜碱', 0.5, 0),
        item(choline_chloride_50, '氯化胆碱', 0.5, 0),
        item(vitamin_c_phosphate, 'VC磷酸酯', 0.1, 0),
        item(ethoxyquin, '乙氧喹', 0.02, 0),
        item(mold_inhibitor, '防霉剂', 0.03, 0)
    ].

% ==========================================
% 方案B: 中鱼粉型 — 97.80% (不足 2.20%)
%   淀粉: wheat_flour 19.0% → 19% < 20% ✅
%   动物蛋白: 22+6+4.5+3.5 = 36% > 25% ✅
% ==========================================
test_shrimp_recipe_b(recipe(white_shrimp, juvenile, Items, 12800, 37.8, 6.0, 4.0, 10.0)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 22.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 6.0, 0),
        item(shrimp_shell_meal, '虾壳粉', 4.5, 0),
        item(squid_liver_paste, '鱿鱼膏', 3.5, 0),
        item(soybean_meal_46, '豆粕(46%)', 15.0, 0),
        item(peanut_meal, '花生粕', 5.0, 0),
        item(cottonseed_meal_dephenol, '棉粕(脱酚)', 4.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 4.5, 0),
        item(wheat_flour, '面粉', 19.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 3.0, 0),
        item(rice_bran, '米糠', 3.05, 0),
        item(fish_oil, '鱼油', 2.5, 0),
        item(soybean_lecithin, '磷脂油', 1.5, 0),
        item(cholesterol, '胆固醇', 0.3, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 1.8, 0),
        item(premix_vitamin_aqua, '多维', 0.5, 0),
        item(premix_mineral_aqua, '多矿', 0.5, 0),
        item(betaine, '甜菜碱', 0.5, 0),
        item(choline_chloride_50, '氯化胆碱', 0.5, 0),
        item(vitamin_c_phosphate, 'VC磷酸酯', 0.1, 0),
        item(ethoxyquin, '乙氧喹', 0.02, 0),
        item(mold_inhibitor, '防霉剂', 0.03, 0)
    ].

% ==========================================
% 方案C: 低鱼粉+高淀粉型 — 96.80% (不足 3.20%)
%   淀粉: wheat_flour 22.0% + tapioca_starch 3.0% = 25.0% > 20% ❌
%   动物蛋白: 20.5+5.5+4+3 = 33% > 25% ✅
% ==========================================
test_shrimp_recipe_c(recipe(white_shrimp, juvenile, Items, 11200, 35.5, 5.5, 4.2, 9.8)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 20.5, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 5.5, 0),
        item(shrimp_shell_meal, '虾壳粉', 4.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 3.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 13.5, 0),
        item(peanut_meal, '花生粕', 4.5, 0),
        item(cottonseed_meal_dephenol, '棉粕(脱酚)', 4.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 4.0, 0),
        item(wheat_flour, '面粉', 22.0, 0),
        item(tapioca_starch, '木薯淀粉', 3.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 2.0, 0),
        item(rice_bran, '米糠', 3.05, 0),
        item(fish_oil, '鱼油', 2.0, 0),
        item(soybean_lecithin, '磷脂油', 1.5, 0),
        item(cholesterol, '胆固醇', 0.3, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 1.8, 0),
        item(premix_vitamin_aqua, '多维', 0.5, 0),
        item(premix_mineral_aqua, '多矿', 0.5, 0),
        item(betaine, '甜菜碱', 0.5, 0),
        item(choline_chloride_50, '氯化胆碱', 0.5, 0),
        item(vitamin_c_phosphate, 'VC磷酸酯', 0.1, 0),
        item(ethoxyquin, '乙氧喹', 0.02, 0),
        item(mold_inhibitor, '防霉剂', 0.03, 0)
    ].

% ==========================================
% 方案OK: 正常配方 — 100.00% 
%   淀粉: wheat_flour 18.0% = 18% < 20% ✅
%   动物蛋白: 22+7+5+3 = 37% > 25% ✅
% ==========================================
test_shrimp_recipe_ok(recipe(white_shrimp, juvenile, Items, 13500, 38.5, 6.2, 4.0, 10.2)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 22.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 7.0, 0),
        item(shrimp_shell_meal, '虾壳粉', 5.0, 0),
        item(squid_liver_paste, '鱿鱼膏', 3.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 16.0, 0),
        item(peanut_meal, '花生粕', 5.0, 0),
        item(cottonseed_meal_dephenol, '棉粕(脱酚)', 4.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(wheat_flour, '面粉', 18.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 3.0, 0),
        item(rice_bran, '米糠', 3.4, 0),
        item(fish_oil, '鱼油', 2.5, 0),
        item(soybean_lecithin, '磷脂油', 2.0, 0),
        item(cholesterol, '胆固醇', 0.3, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 1.8, 0),
        item(premix_vitamin_aqua, '多维', 0.5, 0),
        item(premix_mineral_aqua, '多矿', 0.5, 0),
        item(betaine, '甜菜碱', 0.5, 0),
        item(choline_chloride_50, '氯化胆碱', 0.4, 0),
        item(vitamin_c_phosphate, 'VC磷酸酯', 0.1, 0)
    ].

% ==========================================
% 测试执行
% ==========================================

% 测试 1: 方案A — 100.30%, 应报 over
test_shrimp_a :-
    write('=== 虾配方 方案A (100.30%) ==='), nl,
    test_shrimp_recipe_a(Recipe),
    validate_formula_closure(Recipe, Report),
    write('Report: '), write(Report), nl,
    Report = closure_report(failed, TotalPct, Crits, _Warns),
    write('Total: '), write(TotalPct), write('%'), nl,
    member(closure_violation(over, TotalPct, _), Crits),
    write('  [PASS] 检出 over'), nl,
    nl.

% 测试 2: 方案B — 97.80%, 应报 under
test_shrimp_b :-
    write('=== 虾配方 方案B (97.80%) ==='), nl,
    test_shrimp_recipe_b(Recipe),
    validate_formula_closure(Recipe, Report),
    write('Report: '), write(Report), nl,
    Report = closure_report(failed, TotalPct, Crits, _Warns),
    write('Total: '), write(TotalPct), write('%'), nl,
    member(closure_violation(under, TotalPct, _), Crits),
    write('  [PASS] 检出 under'), nl,
    nl.

% 测试 3: 方案C — 96.80% + 淀粉 25% > 20%
test_shrimp_c :-
    write('=== 虾配方 方案C (96.80% + 淀粉 25%) ==='), nl,
    test_shrimp_recipe_c(Recipe),
    validate_formula_closure(Recipe, Report),
    write('Report: '), write(Report), nl,
    Report = closure_report(failed, TotalPct, Crits, _Warns),
    write('Total: '), write(TotalPct), write('%'), nl,
    write('Violations: '), write(Crits), nl,
    % 应有闭合 under
    member(closure_violation(under, TotalPct, _), Crits),
    % 应有淀粉超限 (虾 max 20%, 实际 25%)
    member(category_violation(max, starch, _, _, _), Crits),
    write('  [PASS] 检出 under + 淀粉超标'), nl,
    nl.

% 测试 4: 正常配方 — 100.00%, 应通过
test_shrimp_ok :-
    write('=== 虾配方 OK (100.00%) ==='), nl,
    test_shrimp_recipe_ok(Recipe),
    validate_formula_closure(Recipe, Report),
    write('Report: '), write(Report), nl,
    Report = closure_report(passed, 100.0, [], []),
    write('  [PASS] 正常配方通过'), nl,
    nl.

% 测试 5: 功能完整性 — 虾配方应报水稳定不足
test_shrimp_functional :-
    write('=== 虾配方 功能完整性 ==='), nl,
    test_shrimp_recipe_a(Recipe),
    Recipe = recipe(white_shrimp, juvenile, Items, _, _, _, _, _),
    check_functional_completeness(white_shrimp, juvenile, Items, Report),
    write('Report: '), write(Report), nl,
    % 虾需要 water_stability >= 2, 方案A 无专门水稳定剂
    Report = functional_report(failed, _, Missing, _),
    write('Missing: '), write(Missing), nl,
    write('  [PASS] 检出功能组缺失'), nl,
    nl.

% 测试 6: 全维度校验 方案A
test_shrimp_full_a :-
    write('=== 虾配方 全维度校验 方案A ==='), nl,
    test_shrimp_recipe_a(Recipe),
    check_compliance_full(Recipe, Report),
    write('Report: '), write(Report), nl,
    Report = full_compliance_report(failed, _, Crits, Warns, FuncMissing),
    length_list(Crits, NC),
    length_list(Warns, NW),
    length_list(FuncMissing, NM),
    write('Total violations: critical='), write(NC),
    write(', warning='), write(NW),
    write(', func_missing='), write(NM), nl,
    NC >= 1,
    write('  [PASS] 全维度校验检出问题'), nl,
    nl.

% 辅助: length
length_list([], 0).
length_list([_|T], N) :- length_list(T, N0), N is N0 + 1.

% ==========================================
% 运行全部测试
% ==========================================
run_all_shrimp_tests :-
    test_shrimp_a,
    test_shrimp_b,
    test_shrimp_c,
    test_shrimp_ok,
    test_shrimp_functional,
    test_shrimp_full_a,
    write('=============================='), nl,
    write('  全部虾配方测试完成'), nl,
    write('=============================='), nl.
