% ============================================================
% closure_validator_test.pl — 闭合校验 + 功能完整性测试
% 验证三个问题配方能否被自动检出
% ============================================================
%
% 测试场景:
%   test_closure_a: 方案A, 总和 100.20% → 应报 over
%   test_closure_b: 方案B, 总和 97.40%  → 应报 under
%   test_closure_c: 方案C, 总和 95.40%  → 应报 under
%   test_closure_ok: 正常配方, 100.00% → 应通过
%   test_category_starch: 淀粉 30%    → 应报品类超限
%   test_functional_missing: 缺功能组 → 应报缺失
% ============================================================

% === scryper-prolog 兼容 ===
sum_list([], 0).
sum_list([H|T], Sum) :- sum_list(T, Rest), Sum is H + Rest.

% ==========================================
% 测试配方构建
% ==========================================

% 方案 A: 100.20% (超标 0.20%)
test_recipe_a(recipe(eel, glass_eel, Items, 12737, 48.85, 10.5, 2.5, 8.5)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 32.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 15.0, 0),
        item(poultry_meal, '鸡肉粉', 10.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 8.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(corn_gluten_meal_60, '玉米蛋白粉(60%)', 3.0, 0),
        item(wheat_flour, '面粉', 10.0, 0),
        item(tapioca_starch, '木薯淀粉', 12.3, 0),   % ★ 导致超标
        item(fish_oil, '鱼油', 3.0, 0),
        item(soybean_lecithin, '磷脂油', 1.0, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 0.6, 0),
        item(premix_vitamin_aqua, '多维', 0.2, 0),
        item(premix_mineral_aqua, '多矿', 0.1, 0)
    ].

% 方案 B: 97.40% (缺 2.60%)
test_recipe_b(recipe(eel, juvenile, Items, 12176, 46.85, 9.5, 2.5, 8.5)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 28.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 10.0, 0),
        item(poultry_meal, '鸡肉粉', 10.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 12.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 6.0, 0),
        item(wheat_flour, '面粉', 12.0, 0),
        item(tapioca_starch, '木薯淀粉', 14.4, 0),   % ★ 故意不足
        item(fish_oil, '鱼油', 3.0, 0),
        item(soybean_lecithin, '磷脂油', 1.0, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 0.8, 0),
        item(premix_vitamin_aqua, '多维', 0.2, 0)
    ].

% 方案 C: 95.40% (缺 4.60%)
test_recipe_c(recipe(eel, grower, Items, 11391, 43.50, 8.5, 3.0, 9.0)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 22.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 8.0, 0),
        item(poultry_meal, '鸡肉粉', 8.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 12.0, 0),
        item(rapeseed_meal_regular, '菜粕', 6.0, 0),
        item(cottonseed_meal_regular, '棉粕', 4.0, 0),
        item(wheat_flour, '面粉', 10.0, 0),
        item(tapioca_starch, '木薯淀粉', 20.4, 0),   % ★ 28%! 但总和仍不足
        item(fish_oil, '鱼油', 3.0, 0),
        item(soybean_lecithin, '磷脂油', 1.0, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 0.8, 0),
        item(premix_vitamin_aqua, '多维', 0.2, 0)
    ].

% 正常配方: 100.00% (应通过)
test_recipe_ok(recipe(eel, juvenile, Items, 12000, 46.0, 9.0, 2.5, 8.5)) :-
    Items = [
        item(fish_meal_peru_65, '秘鲁鱼粉(65%)', 25.0, 0),
        item(fish_meal_domestic_60, '国产鱼粉(60%)', 10.0, 0),
        item(poultry_meal, '鸡肉粉', 8.0, 0),
        item(soybean_meal_46, '豆粕(46%)', 10.0, 0),
        item(fermented_soybean_meal, '发酵豆粕', 5.0, 0),
        item(wheat_flour, '面粉', 10.0, 0),
        item(tapioca_starch, '木薯淀粉', 5.0, 0),
        item(fish_oil, '鱼油', 3.0, 0),
        item(soybean_lecithin, '磷脂油', 1.0, 0),
        item(betaine, '甜菜碱', 0.3, 0),
        item(choline_chloride_50, '氯化胆碱', 0.5, 0),
        item(dicalcium_phosphate, '磷酸氢钙', 1.0, 0),
        item(vitamin_c_phosphate, 'VC磷酸酯', 0.1, 0),
        item(premix_vitamin_aqua, '多维', 0.5, 0),
        item(premix_mineral_aqua, '多矿', 0.5, 0),
        item(squid_liver_paste, '鱿鱼膏', 2.0, 0),
        item(phytase, '植酸酶', 0.05, 0),
        item(monocalcium_phosphate, '磷酸二氢钙', 0.5, 0),
        item(salt, '食盐', 0.3, 0),
        item(limestone_powder, '石粉', 0.5, 0),
        % 补充至 100%
        item(corn_gluten_meal_60, '玉米蛋白粉', 3.0, 0),
        item(soybean_meal_43, '豆粕(43%)', 4.0, 0),
        item(blood_meal_spray, '血粉', 2.0, 0),
        item(corn, '玉米', 6.25, 0),
        item(rice_bran_defatted, '脱脂米糠', 1.5, 0)
    ].

% ==========================================
% 测试执行
% ==========================================

% 闭合测试辅助
assert_closure_failed(Report) :-
    Report = closure_report(failed, _, _, _).
assert_closure_passed(Report) :-
    Report = closure_report(passed, _, _, _).

% 测试 1: 方案 A — 应报告 failed + 总和不闭合
run_test_closure_a :-
    write('=== Test 1: 方案A (100.20%) ==='), nl,
    test_recipe_a(Recipe),
    validate_formula_closure(Recipe, Report),
    write('Result: '), write(Report), nl,
    Report = closure_report(failed, TotalPct, Crits, Warns),
    write('Total: '), write(TotalPct), write('%'), nl,
    write('Critical violations: '), write(Crits), nl,
    write('Warnings: '), write(Warns), nl,
    member(closure_violation(over, TotalPct, _), Crits),
    nl.

% 测试 2: 方案 B — 应报告 under
run_test_closure_b :-
    write('=== Test 2: 方案B (97.40%) ==='), nl,
    test_recipe_b(Recipe),
    validate_formula_closure(Recipe, Report),
    write('Result: '), write(Report), nl,
    Report = closure_report(failed, TotalPct, Crits, Warns),
    write('Total: '), write(TotalPct), write('%'), nl,
    write('Critical violations: '), write(Crits), nl,
    member(closure_violation(under, TotalPct, _), Crits),
    nl.

% 测试 3: 方案 C — 应报告 under + 淀粉超限
run_test_closure_c :-
    write('=== Test 3: 方案C (95.40% + 淀粉28%) ==='), nl,
    test_recipe_c(Recipe),
    validate_formula_closure(Recipe, Report),
    write('Result: '), write(Report), nl,
    Report = closure_report(failed, TotalPct, Crits, _Warns),
    write('Total: '), write(TotalPct), write('%'), nl,
    write('Violations: '), write(Crits), nl,
    % 应有闭合 under 违规
    member(closure_violation(under, TotalPct, _), Crits),
    % 应有淀粉超限违规 (养成鳗 max 28%, 实际 30.4%)
    member(category_violation(max, starch, _, _, _), Crits),
    nl.

% 测试 4: 正常配方 — 应通过
run_test_closure_ok :-
    write('=== Test 4: 正常配方 (100.00%) ==='), nl,
    test_recipe_ok(Recipe),
    validate_formula_closure(Recipe, Report),
    write('Result: '), write(Report), nl,
    Report = closure_report(passed, 100.0, [], []),
    nl.

% 测试 5: 功能完整性 — 鳗鱼配方应报缺失
run_test_functional :-
    write('=== Test 5: 功能完整性检查 ==='), nl,
    test_recipe_a(Recipe),   % 方案A: 缺多个功能组
    Recipe = recipe(eel, glass_eel, Items, _, _, _, _, _),
    check_functional_completeness(eel, glass_eel, Items, Report),
    write('Result: '), write(Report), nl,
    Report = functional_report(failed, _, Missing, _),
    write('Missing groups: '), write(Missing), nl,
    nl.

% 测试 6: 全维度校验 — 方案A
run_test_full_a :-
    write('=== Test 6: 全维度校验 方案A ==='), nl,
    test_recipe_a(Recipe),
    check_compliance_full(Recipe, Report),
    write('Result: '), write(Report), nl,
    Report = full_compliance_report(failed, TotalPct, Crits, Warns, FuncMissing),
    write('Total: '), write(TotalPct), write('% | '),
    write('Criticals: '), my_length(Crits, NC),
    write(NC), write(' | Warnings: '), my_length(Warns, NW),
    write(NW), write(' | Missing func groups: '), my_length(FuncMissing, NM),
    write(NM), nl.

my_length([], 0).
my_length([_|T], N) :- my_length(T, N0), N is N0 + 1.
