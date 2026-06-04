% ==== 集成测试: sop_engine.pl ====
% 用法: scryper-prolog test_sop.pl

:- discontiguous(ingredient/10).
:- discontiguous(species_nutrition/5).
:- discontiguous(species_category_rule/6).

:- consult('rules/ingredient_db.pl').
:- consult('rules/species_nutrition.pl').
:- consult('rules/sop_engine.pl').

go :-
    write('════════════════════════════════════'), nl,
    write('  SOP Engine 集成测试'), nl,
    write('════════════════════════════════════'), nl, nl,

    write('=== 测试1: 鳗鱼幼体配方 ==='), nl,
    solve_formulation(japanese_eel, juvenile),

    write('=== 测试2: 南美白对虾幼体配方 ==='), nl,
    solve_formulation(white_shrimp, juvenile),

    write('=== 测试3: 加州鲈幼体配方 ==='), nl,
    solve_formulation(largemouth_bass, juvenile),

    write('=== 测试4: 鲤鱼成体配方 ==='), nl,
    solve_formulation(common_carp, adult),

    write('全部测试完成.'), nl.
