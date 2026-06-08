% ═══════════════════════════════════════════════════════════════
% prolog_modules_registry.pl — Prolog 模块注册中心 v1.0
% AquaFeedFormulator Phase 0 治理基础
%
% 所有 Prolog 模块必须在此注册。
% Rust CLI 通过此文件发现模块、检查依赖、读取元信息。
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 模块注册
% prolog_module(+Id, +Phase, +Category, +Status)
%
%   Id       — 唯一标识符
%   Phase    — 实施阶段: phase0 | phase1 | phase2 | phase3 | phase4 | phase5
%   Category — 功能分类: governance | decision | planning | validation
%   Status   — 成熟度: draft | stable | production
% ═══════════════════════════════════════════════════════════════

% ==== Phase 0: 治理基础 ====

prolog_module(prolog_modules_registry, phase0, governance, draft).
prolog_module(module_test_template,     phase0, governance, draft).
prolog_module(output_contract_validator, phase0, governance, draft).
prolog_module(module_test_runner,       phase0, governance, draft).

% ==== Phase 0: 已有模块 (补注册) ====

prolog_module(ingredient_db,              phase0, data,       stable).
prolog_module(species_nutrition,          phase0, data,       stable).
prolog_module(category_rules,             phase0, data,       stable).
prolog_module(formulation_lp_engine,      phase0, planning,   stable).
prolog_module(sop_engine,                 phase0, decision,   stable).
prolog_module(sop_gatekeeper,             phase0, decision,   stable).
prolog_module(sop_workflow,               phase0, decision,   stable).
prolog_module(delivery_gatekeeper,        phase0, validation, stable).
prolog_module(counterexample_tests,       phase0, validation, stable).
prolog_module(self_iteration_engine,      phase0, decision,   draft).
prolog_module(compliance_checker,         phase0, validation, stable).
prolog_module(nutrition_calculator,       phase0, planning,   stable).
prolog_module(functional_additive_checker,phase0, validation, stable).
prolog_module(cross_species_consistency,  phase0, validation, stable).

% ==== Phase 1: 快速验证 ====

prolog_module(price_alert_rules,          phase1, decision,   draft).
prolog_module(report_content_selector,    phase1, decision,   draft).

% ==== Phase 2: 核心增强 ====

prolog_module(recipe_planner,             phase2, planning,   stable).
prolog_module(ingredient_substitution,    phase2, decision,   stable).

% ==== Phase 3: 矿物平衡 ====

prolog_module(mineral_balance,            phase3, validation, stable).

% ==== Phase 4: 氨基酸平衡 ====

prolog_module(eaa_balance,                phase4, validation, stable).
prolog_module(ingredient_amino,           phase4, data,       stable).

% ==== Phase 5: 成本 + 风险 ====

prolog_module(cost_range_rules,           phase3, validation, stable).
prolog_module(performance_risk_rules,     phase5, validation, stable).

% ═══════════════════════════════════════════════════════════════
% 模块依赖
% module_depends(+Module, +Dependency)
% ═══════════════════════════════════════════════════════════════

% Phase 1
module_depends(price_alert_rules,       ingredient_db).
module_depends(report_content_selector,  recipe_planner).
module_depends(report_content_selector,  delivery_gatekeeper).

% Phase 2
module_depends(recipe_planner,          formulation_lp_engine).
module_depends(recipe_planner,          category_rules).
module_depends(recipe_planner,          species_nutrition).
module_depends(recipe_planner,          ingredient_db).
module_depends(ingredient_substitution, ingredient_db).

% Phase 3
module_depends(mineral_balance,         ingredient_db).
module_depends(mineral_balance,         species_nutrition).

% Phase 4
module_depends(eaa_balance,             ingredient_amino).
module_depends(eaa_balance,             species_nutrition).
module_depends(ingredient_amino,        ingredient_db).

% Phase 5
module_depends(cost_range_rules,        species_nutrition).
module_depends(performance_risk_rules,  recipe_planner).
module_depends(performance_risk_rules,  ingredient_db).

% 已有模块依赖
module_depends(delivery_gatekeeper,     nutrition_calculator).
module_depends(delivery_gatekeeper,     compliance_checker).
module_depends(delivery_gatekeeper,     counterexample_tests).
module_depends(sop_engine,              formulation_lp_engine).
module_depends(sop_engine,              category_rules).
module_depends(sop_engine,              species_nutrition).
module_depends(formulation_lp_engine,   category_rules).
module_depends(formulation_lp_engine,   species_nutrition).
module_depends(formulation_lp_engine,   ingredient_db).
module_depends(nutrition_calculator,    species_nutrition).
module_depends(nutrition_calculator,    ingredient_db).
module_depends(counterexample_tests,    delivery_gatekeeper).
module_depends(self_iteration_engine,   sop_engine).
module_depends(cross_species_consistency, species_nutrition).
module_depends(cross_species_consistency, category_rules).
module_depends(functional_additive_checker, ingredient_db).

% ═══════════════════════════════════════════════════════════════
% 模块元信息
% ═══════════════════════════════════════════════════════════════

% module_output_format(+Module, +Format) — Format: json | term
module_output_format(price_alert_rules,       json).
module_output_format(report_content_selector, json).
module_output_format(recipe_planner,          json).
module_output_format(ingredient_substitution, json).
module_output_format(mineral_balance,         json).
module_output_format(eaa_balance,             json).
module_output_format(cost_range_rules,        json).
module_output_format(performance_risk_rules,  json).
module_output_format(delivery_gatekeeper,     json).

% module_test_level(+Module, +Level) — Level: low | medium | high
module_test_level(price_alert_rules,       low).
module_test_level(report_content_selector, low).
module_test_level(recipe_planner,          medium).
module_test_level(ingredient_substitution, medium).
module_test_level(mineral_balance,         medium).
module_test_level(eaa_balance,             high).
module_test_level(cost_range_rules,        low).
module_test_level(performance_risk_rules,  high).
module_test_level(delivery_gatekeeper,     medium).
module_test_level(counterexample_tests,    low).

% module_version(+Module, +Version)
module_version(price_alert_rules,       '1.0.0').
module_version(report_content_selector, '1.0.0').
module_version(recipe_planner,          '1.0.0').
module_version(ingredient_substitution, '1.0.0').
module_version(mineral_balance,         '1.0.0').
module_version(eaa_balance,             '1.0.0').
module_version(cost_range_rules,        '1.0.0').
module_version(performance_risk_rules,  '1.0.0').
module_version(delivery_gatekeeper,     '2.0.0').

% ═══════════════════════════════════════════════════════════════
% 工具谓词
% ═══════════════════════════════════════════════════════════════

% phase_modules(+Phase, -Modules) — 获取某阶段的所有模块
phase_modules(Phase, Modules) :-
    findall(Id, prolog_module(Id, Phase, _, _), Modules).

% all_deps(+Module, -AllDeps) — 递归获取所有依赖
all_deps(Module, AllDeps) :-
    findall(D, (
        transitive_dep(Module, D),
        D \= Module
    ), Deps),
    sort(Deps, AllDeps).

transitive_dep(Module, Dep) :-
    module_depends(Module, Dep).
transitive_dep(Module, Dep) :-
    module_depends(Module, Mid),
    transitive_dep(Mid, Dep).

% module_ready(+Module) — 模块的所有依赖均已 stable/production
module_ready(Module) :-
    forall(
        module_depends(Module, Dep),
        ( prolog_module(Dep, _, _, stable)
        ; prolog_module(Dep, _, _, production)
        )
    ).

% render_module_list — 打印所有注册模块及状态
render_module_list :-
    write('  Module                            Phase     Category    Status'), nl,
    write('  ──────────────────────────────────────────────'), nl,
    findall(Id-Phase-Cat-Status,
            prolog_module(Id, Phase, Cat, Status),
            Modules),
    render_list_items(Modules).

render_list_items([]).
render_list_items([Id-Phase-Cat-Status|Rest]) :-
    write('  '), write(Id),
    write('                    '),
    write(Phase),
    write('    '),
    write(Cat),
    write('    '),
    write(Status), nl,
    render_list_items(Rest).
