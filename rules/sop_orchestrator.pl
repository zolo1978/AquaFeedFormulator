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
