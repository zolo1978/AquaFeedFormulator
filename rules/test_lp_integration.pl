% ==== 集成测试: formulation_solver_v2.pl ====
% scryer-prolog 加载方式

:- discontiguous(ingredient/10).
:- discontiguous(species_nutrition/5).

:- consult('ingredient_db.pl').
:- consult('species_nutrition.pl').
:- consult('formulation_solver_v2.pl').

go :-
    write('=== 鳗鱼 LP 配方 ==='), nl,
    eel_lp, nl,
    write('=== 虾 LP 配方 ==='), nl,
    shrimp_lp, nl.
