% ==== SOP Engine Test ====

:- discontiguous(ingredient/10).
:- discontiguous(species_nutrition/5).
:- discontiguous(species_category_rule/6).

:- use_module('rules/ingredient_db.pl').
:- use_module('rules/species_nutrition.pl').
:- use_module('rules/sop_engine.pl').

go :-
    write('=== SOP Engine Test ==='), nl,
    solve_formulation(japanese_eel, juvenile),
    halt.

:- initialization(go).
