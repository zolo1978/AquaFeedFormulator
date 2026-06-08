% ═══════════════════════════════════════════════════════════════
% sop_orchestrator.pl — AquaFeedFormulator Prolog SOP 编排器 v1.0
%
% 职责：串联全部 Prolog 模块，实现端到端 SOP 流程。
% Prolog 成为 SOP 的"唯一大脑" — 决策、校验、风控全在 Prolog 侧。
%
% 入口:
%   run_full_pipeline(+Species, +Stage)
%     端到端执行，结构化输出到 stdout。
%   test_all_species
%     批量测试全部 5 个品类物种。
%
% 调用链:
%   [1] can_execute             — 执行许可
%   [2] solve_formulation_data  — LP 配方求解
%   [3] cost_range_rules        — 成本区间校验
%   [4] mineral_balance         — 矿物质平衡
%   [5] eaa_balance             — 必需氨基酸平衡
%   [6] performance_risk_rules  — FCR 风险提示
%   [7] report_content_selector — 报告内容建议
%   [8] delivery_gatekeeper     — 交付判定
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 物种列表
% ═══════════════════════════════════════════════════════════════

species_name(japanese_eel,    '日本鳗鲡').
species_name(white_shrimp,    '南美白对虾').
species_name(common_carp,     '鲤鱼').
species_name(grass_carp,      '草鱼').
species_name(largemouth_bass, '加州鲈').

pipeline_species(japanese_eel).
pipeline_species(white_shrimp).
pipeline_species(common_carp).
pipeline_species(grass_carp).
pipeline_species(largemouth_bass).

% ═══════════════════════════════════════════════════════════════
% 主入口：端到端执行
% ═══════════════════════════════════════════════════════════════

run_full_pipeline(Species, Stage) :-
    % 注入运行时状态
    assertz(project_state(production, solving)),

    (  run_pipeline_steps(Species, Stage, Status, Items, TotalCost, TonCost,
                          TgtPro, TgtFat, MaxFib, MaxAsh,
                          CostResult, MinResult, EAAResult, RiskResult, ReportResult,
                          Delivery, Confidence, Warnings, Errors) ->
        display_pipeline_result(Species, Stage, Status,
                                Items, TotalCost, TonCost,
                                TgtPro, TgtFat, MaxFib, MaxAsh,
                                CostResult, MinResult, EAAResult, RiskResult, ReportResult,
                                Delivery, Confidence, Warnings, Errors)
    ;  write('FATAL: pipeline 异常终止'), nl
    ),

    retractall(project_state(_, _)).

% ═══════════════════════════════════════════════════════════════
% 核心流水线
% ═══════════════════════════════════════════════════════════════

run_pipeline_steps(Species, Stage, Status, Items, TotalCost, TonCost,
                   TgtPro, TgtFat, MaxFib, MaxAsh,
                   CostResult, MinResult, EAAResult, RiskResult, ReportResult,
                   Delivery, Confidence, Warnings, Errors) :-

    % ── [1/8] can_execute 门禁 ──────────────────────────
    write('[1/8] can_execute...'), nl,
    (  once(can_execute(production, solve(Species, Stage))) -> write('  PASS'), nl
    ;  Status = blocked,
        Items = [], TotalCost = 0, TonCost = 0,
        TgtPro = 0, TgtFat = 0, MaxFib = 0, MaxAsh = 0,
        CostResult = skipped, MinResult = skipped, EAAResult = skipped,
        RiskResult = skipped, ReportResult = skipped,
        Delivery = blocked, Confidence = 0.0,
        Warnings = ['can_execute 拒绝执行'],
        Errors = ['production_solve_denied'],
        write('  FAIL (blocked)'), nl, !
    ),

    % ── [2/8] LP 配方求解 ───────────────────────────────
    write('[2/8] LP求解...'), nl,
    (  once(solve_formulation_data(Species, Stage,
               Items, TotalCost, TgtPro, TgtFat, MaxFib, MaxAsh)) ->
        TonCost is round(TotalCost * 10),
        write('  PASS — TotalCost='), write(TotalCost),
        write(' TonCost='), write(TonCost), nl
    ;  Status = infeasible,
        Items = [], TotalCost = 0, TonCost = 0,
        TgtPro = 0, TgtFat = 0, MaxFib = 0, MaxAsh = 0,
        CostResult = skipped, MinResult = skipped, EAAResult = skipped,
        RiskResult = skipped, ReportResult = skipped,
        Delivery = infeasible, Confidence = 0.0,
        Warnings = [],
        Errors = ['LP infeasible — 营养目标与品类约束冲突'],
        write('  FAIL (infeasible)'), nl, !
    ),

    % ── [3/8] 成本区间校验 ──────────────────────────────
    write('[3/8] 成本区间校验...'), nl,
    (  catch(once(cost_range_check(Species, Stage, TonCost, CostResult)),
             E, (write('  EXCEPTION: '), write(E), nl, fail)) ->
        write('  PASS'), nl
    ;  write('  FAIL'), nl, fail
    ),

    % ── [4/8] 矿物质平衡 ────────────────────────────────
    write('[4/8] 矿物质平衡...'), nl,
    (  catch(once(mineral_check(Species, Stage, Items, MinResult)),
             E, (write('  EXCEPTION: '), write(E), nl, fail)) ->
        write('  PASS'), nl
    ;  write('  FAIL'), nl, fail
    ),

    % ── [5/8] 必需氨基酸平衡 ────────────────────────────
    write('[5/8] 氨基酸平衡...'), nl,
    (  catch(once(eaa_check(Species, Stage, Items, EAAResult)),
             E, (write('  EXCEPTION: '), write(E), nl, fail)) ->
        write('  PASS'), nl
    ;  write('  FAIL'), nl, fail
    ),

    % ── [6/8] 绩效风险评估 ──────────────────────────────
    write('[6/8] 绩效风险评估...'), nl,
    (  catch(once(performance_risk_check(Species, Stage, Items, RiskResult)),
             E, (write('  EXCEPTION: '), write(E), nl, fail)) ->
        write('  PASS'), nl
    ;  write('  FAIL'), nl, fail
    ),

    % ── [7/8] 报告内容选择 ──────────────────────────────
    write('[7/8] 报告内容选择...'), nl,
    nutrients_from_items(Items, Nutrients),
    (  catch(once(report_check(Species, Stage, Items, Nutrients, ReportResult)),
             E, (write('  EXCEPTION: '), write(E), nl, fail)) ->
        write('  PASS'), nl
    ;  write('  FAIL'), nl, fail
    ),

    % ── [8/8] 交付门禁 ──────────────────────────────────
    write('[8/8] 交付门禁...'), nl,
    (  once(deliverable(Species, Stage, passed)) ->
        Delivery = passed,
        write('  PASS'), nl
    ;  Delivery = failed,
        write('  FAIL'), nl
    ),

    % ── 汇总 ───────────────────────────────────────────
    Status = solved,
    aggregate_confidence([CostResult, MinResult, EAAResult, RiskResult], Confidence),
    collect_warnings([CostResult, MinResult, EAAResult, RiskResult, ReportResult], Warnings),
    collect_errors([CostResult, MinResult, EAAResult, RiskResult, ReportResult], Errors).

% ═══════════════════════════════════════════════════════════════
% 辅助：从 Items 计算营养摘要
% ═══════════════════════════════════════════════════════════════

nutrients_from_items(Items, nutrients(Pro, Fat, Fib, Ash)) :-
    sum_nutrients(Items, 0, Pro, 0, Fat, 0, Fib, 0, Ash,
                  0, _, 0, _, 0, _, 0, _).

sum_nutrients([], Pro, Pro, Fat, Fat, Fib, Fib, Ash, Ash,
              APro, APro, PPro, PPro, MOil, MOil, VOil, VOil).
sum_nutrients([Id-Pct-_|T], Pro0, Pro, Fat0, Fat, Fib0, Fib, Ash0, Ash,
              APro0, APro, PPro0, PPro, MOil0, MOil, VOil0, VOil) :-
    ingredient(Id, _, _, ProPct, FatPct, FibPct, AshPct, _, _, _, _),
    NPro  is Pro0  + ProPct  * Pct / 100,
    NFat  is Fat0  + FatPct  * Pct / 100,
    NFib  is Fib0  + FibPct  * Pct / 100,
    NAsh  is Ash0  + AshPct  * Pct / 100,
    NAPro is APro0, NPPro is PPro0,
    NMOil is MOil0, NVOil is VOil0,
    sum_nutrients(T, NPro, Pro, NFat, Fat, NFib, Fib, NAsh, Ash,
                  NAPro, APro, NPPro, PPro, NMOil, MOil, NVOil, VOil).

% ═══════════════════════════════════════════════════════════════
% 辅助：汇总置信度
% ═══════════════════════════════════════════════════════════════

aggregate_confidence(Results, Conf) :-
    findall(C, (
        member(R, Results),
        R \= skipped,
        arg(4, R, C),
        number(C)
    ), Confs),
    (  Confs \= [] ->
        sum_list(Confs, Sum),
        length(Confs, N),
        Conf is Sum / N
    ;  Conf = 0.5
    ).

% ═══════════════════════════════════════════════════════════════
% 辅助：收集警告/错误
% ═══════════════════════════════════════════════════════════════

collect_warnings(Results, Warnings) :-
    findall(Msg, (
        member(R, Results),
        R \= skipped,
        arg(2, R, Ws),
        is_list(Ws),
        member(W, Ws),
        warn_msg(W, Msg)
    ), Warnings).

collect_errors(Results, Errors) :-
    findall(Msg, (
        member(R, Results),
        R \= skipped,
        arg(3, R, Es),
        is_list(Es),
        member(E, Es),
        err_msg(E, Msg)
    ), Errors).

warn_msg(W, Msg) :-
    (  W = warn(Msg) -> true
    ;  W = warning(_, Msg) -> true
    ;  term_string(W, Msg)
    ).

err_msg(E, Msg) :-
    (  E = error(Msg) -> true
    ;  term_string(E, Msg)
    ).

is_list([]).
is_list([_|_]).

% ═══════════════════════════════════════════════════════════════
% 结果展示
% ═══════════════════════════════════════════════════════════════

display_pipeline_result(Species, Stage, Status,
                        Items, TotalCost, TonCost,
                        TgtPro, TgtFat, MaxFib, MaxAsh,
                        CostResult, MinResult, EAAResult, RiskResult, ReportResult,
                        Delivery, Confidence, Warnings, Errors) :-
    species_name(Species, SName),
    stage_name(Stage, StName),
    nl,
    write('══════════════════════════════════════════════'), nl,
    write('  AquaFeedFormulator — Prolog SOP 编排器 v1.0'), nl,
    write('  '), write(SName), write(' · '), write(StName), nl,
    write('──────────────────────────────────────────────'), nl,

    % 状态
    write('  Pipeline: '),
    (  Status = solved -> write('✅ SOLVED')
    ;  Status = blocked -> write('🚫 BLOCKED')
    ;  Status = infeasible -> write('❌ INFEASIBLE')
    ;  write('⚠ UNKNOWN')
    ), nl,
    Conf100 is round(Confidence * 100),
    write('  Confidence: '), write(Conf100), write('%'), nl,

    (  Status = solved ->
        % 配方
        nl,
        write('  ── 配方 ──'), nl,
        write('    蛋白≥'), write(TgtPro), write('%  脂肪≥'), write(TgtFat),
        write('%  纤维≤'), write(MaxFib), write('%  灰分≤'), write(MaxAsh), nl,
        display_items(Items),
        sum_pcts(Items, TotalPct),
        TotalPctR is round(TotalPct * 10) / 10,
        write('    吨成本: ¥'), write(TonCost), write('/t  (闭合: '),
        write(TotalPctR), write('%)'), nl,

        % 模块检查
        nl,
        write('  ── 模块检查 ──'), nl,
        display_check(cost_range, CostResult),
        display_check(mineral_balance, MinResult),
        display_check(eaa_balance, EAAResult),
        display_check(performance_risk, RiskResult),
        display_check(report_content, ReportResult),

        % 交付
        nl,
        write('  ── 交付判定 ──'), nl,
        (  Delivery = passed ->
            write('    ✅ PASS — 可交付'), nl
        ;  write('    ❌ FAIL — 需整改'), nl
        )
    ;  true
    ),

    % 警告/错误
    (  Warnings \= [] ->
        nl, write('  ── 警告 ──'), nl,
        maplist(show_line, Warnings)
    ;  true
    ),
    (  Errors \= [] ->
        nl, write('  ── 错误 ──'), nl,
        maplist(show_line, Errors)
    ;  true
    ),

    write('══════════════════════════════════════════════'), nl, nl.

display_items([]).
display_items([Id-Pct-Cost|RT]) :-
    (  ingredient(Id, Name, _, _, _, _, _, _, _, _, _) ->
        PctR is round(Pct * 10) / 10,
        CPct is round(Cost * 10),
        write('    '), write(Name), write('  '), write(PctR), write('%  ¥'),
        write(CPct), nl
    ;  write('    '), write(Id), write('  '), write(Pct), write('%'), nl
    ),
    display_items(RT).

sum_pcts([], 0).
sum_pcts([_-Pct-_|RT], T) :- sum_pcts(RT, R), T is R + Pct.

display_check(Module, Result) :-
    (  Result = skipped ->
        write('    ⊘ '), write(Module), write(' (skipped)'), nl
    ;  write('    ? '), write(Module), write(' '), write(Result), nl
    ).

show_line(X) :-
    write('    · '),
    (  atom(X) -> write(X)
    ;  write(X)
    ),
    nl.

% ═══════════════════════════════════════════════════════════════
% 批量测试
% ═══════════════════════════════════════════════════════════════

test_all_species :-
    write('══════════════════════════════════════════════'), nl,
    write('  AquaFeedFormulator — 全物种端到端测试'), nl,
    write('══════════════════════════════════════════════'), nl, nl,
    findall(Species-Result, (
        pipeline_species(Species),
        run_full_pipeline(Species, adult)
    ), _),
    write('=== 全物种测试完成 ==='), nl.

% ═══════════════════════════════════════════════════════════════
% 自检
% ═══════════════════════════════════════════════════════════════

self_check :-
    write('=== 模块加载自检 ==='), nl,
    required_modules(Mods),
    self_check_modules(Mods).

required_modules([
    ingredient_db,
    species_nutrition,
    category_rules,
    sop_gatekeeper,
    formulation_lp_engine,
    delivery_gatekeeper,
    sop_engine,
    cost_range_rules,
    mineral_balance,
    eaa_balance,
    ingredient_amino,
    performance_risk_rules,
    report_content_selector
]).

self_check_modules([]) :-
    write('全部模块可用 ✅'), nl.
self_check_modules([M|T]) :-
    (  current_predicate(_:M/_) ->
        write('  ✅ '), write(M), nl
    ;  write('  ❌ '), write(M), write(' — 不可用'), nl
    ),
    self_check_modules(T).

% ═══════════════════════════════════════════════════════════════
% 统一 Pipeline 入口 (v2.0)
%
% run_unified_pipeline(+Species, +Stage)
%   单次调用，输出配方 + 营养 + 约束 + 原料 + 校验，
%   格式与 bridge_prolog_docx.rb 解析器兼容。
%
% 用法:
%   scryer-prolog -g "consult('rules/...'),run_unified_pipeline(white_shrimp,adult)"
% ═══════════════════════════════════════════════════════════════

run_unified_pipeline(Species, Stage) :-
    % ── Section 1: Meta (species + nutrition + constraints + ingredients) ──
    write_meta_section(Species, Stage),
    nl,

    % ── Section 2: Plans (3 strategies) ──
    (  catch(generate_recipe_plans(Species, Stage, PlanOut), _, fail) ->
        PlanOut = output(Plans, _, _, _, _),
        write_plan_sections(Plans)
    ;  write('PLAN_ERROR: recipe_planner failed'), nl
    ),

    % ── Section 3: Validation per plan ──
    (  nonvar(Plans) ->
        write_validation_sections(Species, Stage, Plans)
    ;  true
    ),

    nl, write('PIPELINE_DONE'), nl.

% ═══════════════════════════════════════════════════════════════
% Section 1: Meta 输出
% ═══════════════════════════════════════════════════════════════

write_meta_section(Species, Stage) :-
    species_name(Species, SName),
    stage_name(Stage, StName),
    write('META_START'), nl,
    write('species_key='), write(Species), nl,
    write('species_cn='), write(SName), nl,
    write('stage='), write(Stage), nl,
    write('stage_cn='), write(StName), nl,
    write('META_END'), nl,

    % 营养需求
    species_nutrition(Species, Stage, Pro, Fat, Fib, Ash),
    write('NUTRITION '), write(Pro), write(' '), write(Fat),
    write(' '), write(Fib), write(' '), write(Ash), nl,

    % 品类约束
    species_category_constraints(Species, Stage, Cats),
    write_cat_constraints(Cats),

    % 原料数据库
    write('INGREDIENTS_START'), nl,
    findall(Id-Cn-Cat-Pro2-Fat2-Fib2-Ash2-Price-Max-Min,
        ingredient(Id, Cn, Cat, Pro2, Fat2, Fib2, Ash2, _, Price, Max, Min),
        All),
    write_ingredient_lines(All),
    write('INGREDIENTS_END'), nl.

write_cat_constraints([]).
write_cat_constraints([Cat-LT-Val|Rest]) :-
    write('CONSTRAINT '), write(Cat), write(' '),
    write(LT), write(' '), write(Val), nl,
    write_cat_constraints(Rest).

write_ingredient_lines([]).
write_ingredient_lines([Id-Cn-Cat-Pro2-Fat2-Fib2-Ash2-Price-Max-Min|Rest]) :-
    write('ing '), write(Id), write('|'), write(Cn), write('|'), write(Cat),
    write('|'), write(Pro2), write('|'), write(Fat2), write('|'), write(Fib2),
    write('|'), write(Ash2), write('|'), write(Price), write('|'),
    write(Max), write('|'), write(Min), nl,
    write_ingredient_lines(Rest).

% ═══════════════════════════════════════════════════════════════
% Section 2: Plans 输出 (配方方案)
% ═══════════════════════════════════════════════════════════════

write_plan_sections([]).
write_plan_sections([plan(Strat, Status, Items, Cost, Profile)|Rest]) :-
    Profile = profile(ApMin, FmMin, Risk, CW),
    write('PLAN_START'), nl,
    write('strategy='), write(Strat), nl,
    write('status='), write(Status), nl,
    write('cost='), write(Cost), nl,
    write('ap_min='), write(ApMin), nl,
    write('fm_min='), write(FmMin), nl,
    write('risk='), write(Risk), nl,
    write('cw='), write(CW), nl,
    write_items_clean(Items),
    write('PLAN_END'), nl,
    write_plan_sections(Rest).

write_items_clean([]).
write_items_clean([item(Id, Pct, Cost)|Rest]) :-
    write('item '), write(Id), write(' '), write(Pct),
    write(' '), write(Cost), nl,
    write_items_clean(Rest).

% ═══════════════════════════════════════════════════════════════
% Section 3: Validation 输出 (校验)
% ═══════════════════════════════════════════════════════════════

write_validation_sections(_, _, []).
write_validation_sections(Species, Stage, [plan(Strat, _, ItemsItem3, _, _)|Rest]) :-
    write('VAL_START '), write(Strat), nl,

    % 格式转换: item(Id,Pct,Cost) → Id-Pct-Cost
    items_to_pairs(ItemsItem3, Items),

    % 实际营养
    calc_actual_nutrition(ItemsItem3, Pro, Fat, Fib, Ash),
    ProR is round(Pro * 10) / 10,
    FatR is round(Fat * 10) / 10,
    FibR is round(Fib * 10) / 10,
    AshR is round(Ash * 10) / 10,
    write('  actual_nutrition '), write(ProR), write(' '), write(FatR),
    write(' '), write(FibR), write(' '), write(AshR), nl,

    % 矿物质校验
    (  catch(once(mineral_check(Species, Stage, Items, MOut)),
             _, MOut = output(data([]),[err(error,_)],[],0.0,[])) ->
        true ; MOut = output(data([]),[err(error,_)],[],0.0,[])
    ),
    write_val_mineral(MOut),

    % 氨基酸校验
    (  catch(once(eaa_check(Species, Stage, Items, AOut)),
             _, AOut = output(data([]),[err(error,_)],[],0.0,[])) ->
        true ; AOut = output(data([]),[err(error,_)],[],0.0,[])
    ),
    write_val_amino(AOut),

    % 绩效风险
    (  catch(performance_risk_check(Species, Stage, Items, ROut),
             _, ROut = output(data([]),[err(error,_)],[],0.0,[])) ->
        true ; ROut = output(data([]),[err(error,_)],[],0.0,[])
    ),
    write_val_risk(ROut),

    write('VAL_END'), nl,
    write_validation_sections(Species, Stage, Rest).

% ── 格式转换 ──
items_to_pairs([], []).
items_to_pairs([item(Id, Pct, Cost)|T], [Id-Pct-Cost|RT]) :-
    items_to_pairs(T, RT).

% ── 营养计算 ──
calc_actual_nutrition([], 0, 0, 0, 0).
calc_actual_nutrition([item(_, 0, _)|T], P, F, B, A) :-
    !, calc_actual_nutrition(T, P, F, B, A).
calc_actual_nutrition([item(Id, Pct, _)|T], Pro, Fat, Fib, Ash) :-
    ingredient(Id, _, _, IngPro, IngFat, IngFib, IngAsh, _, _, _, _),
    calc_actual_nutrition(T, PR, FR, BR, AR),
    Pro is PR + Pct * IngPro / 100,
    Fat is FR + Pct * IngFat / 100,
    Fib is BR + Pct * IngFib / 100,
    Ash is AR + Pct * IngAsh / 100.

% ── 矿物质输出 ──
write_val_mineral(output(data(Checks), _Ws, _Es, Conf, _)) :-
    write('  mineral_confidence '), write(Conf), nl,
    write_mineral_checks(Checks).

write_mineral_checks([]).
write_mineral_checks([C|T]) :-
    C =.. [check|Args],
    (  Args = [Name, Status, Actual, Required] ->
        write('  mineral_check '), write(Name), write(' '),
        write(Status), write(' '), write(Actual), write(' '),
        write(Required), nl
    ;  Args = [ca_p_ratio, Status, Ratio, Min, Max] ->
        write('  mineral_check ca_p_ratio '), write(Status),
        write(' '), write(Ratio), write(' '), write(Min),
        write('-'), write(Max), nl
    ;  Args = [ca_p_ratio, Status, Ratio, Min, Max, _Dir] ->
        write('  mineral_check ca_p_ratio '), write(Status),
        write(' '), write(Ratio), write(' '), write(Min),
        write('-'), write(Max), nl
    ;  true
    ),
    write_mineral_checks(T).

% ── 氨基酸输出 ──
write_val_amino(output(data(Checks), _Ws, _Es, Conf, _)) :-
    write('  amino_confidence '), write(Conf), nl,
    write_amino_checks(Checks).

write_amino_checks([]).
write_amino_checks([C|T]) :-
    C =.. [check, Name, Status, Actual, Required|_],
    write('  amino_check '), write(Name), write(' '),
    write(Status), write(' '), write(Actual), write(' '),
    write(Required), nl,
    write_amino_checks(T).

% ── 绩效风险输出 ──
write_val_risk(output(data(Checks), _Ws, _Es, Conf, _)) :-
    write('  risk_confidence '), write(Conf), nl,
    write_risk_checks(Checks).

write_risk_checks([]).
write_risk_checks([C|T]) :-
    C =.. [risk, Name, Level, Value],
    write('  risk_check '), write(Name), write(' '),
    write(Level), write(' '), write(Value), nl,
    write_risk_checks(T).

% ═══════════════════════════════════════════════════════════════
% 独立测试入口
% ═══════════════════════════════════════════════════════════════

test_unified_pipeline :-
    write('=== Unified Pipeline Test ==='), nl,
    run_unified_pipeline(white_shrimp, adult).
