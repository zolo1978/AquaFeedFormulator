% ═══════════════════════════════════════════════════════════════
% cost_range_rules.pl — 配方成本区间校验 (M7a)
% AquaFeedFormulator Phase 3
%
% 校验配方吨成本是否在合理区间内。
% 支持通胀指数动态调整区间。
%
% 依赖: species_nutrition (仅物种校验)
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 输出协议
% output(+Input, -Output)
%   Input  = input(Species, Stage, TotalCost)           — 通胀默认 0
%          | input(Species, Stage, TotalCost, Inflation) — 显式通胀
%   TotalCost  : 元/吨 (int/float)
%   Inflation  : 小数 (e.g. 0.03 = 3%)
%   Output = output(Data, Warnings, Errors, Confidence, NextActions)
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% cost_range_output/2 子句（必须连续，否则 scryer 报 discontiguous）
% 使用 cost_range_output 避免与 mineral_balance/eaa_balance 等
% 模块的 output/2 发生跨文件谓词合并冲突
% ═══════════════════════════════════════════════════════════════

% 默认通胀为 0
cost_range_output(input(Species, Stage, Cost), Output) :-
    cost_range_output(input(Species, Stage, Cost, 0.0), Output).

cost_range_output(input(Species, Stage, Cost, Inflation), Output) :-
    ( valid_species_stage(Species, Stage) ->
        ( base_cost_range(Species, Stage, BaseMin, BaseMax) ->
            DynMin is BaseMin * (1.0 + Inflation),
            DynMax is BaseMax * (1.0 + Inflation),
            MidPoint is (DynMin + DynMax) / 2,
            evaluate_cost(Cost, DynMin, DynMax, MidPoint,
                          Status, Detail, NextActions),
            Confidence = 0.95,
            Output = output(
                data(cost_check(Status, Detail)),
                [],
                [],
                Confidence,
                NextActions
            )
        ;   % 物种在 nutrition 中存在但无成本区间
            Output = output(
                data(cost_check(skipped, no_range_defined)),
                [warn(cost_range, 'no cost range defined for this species/stage')],
                [],
                0.0,
                []
            )
        )
    ;   % 无效物种
        Output = output(
            data(cost_check(error, invalid_species)),
            [],
            [err(invalid_species, Species)],
            0.0,
            []
        )
    ).

% 编排器入口（scryer-prolog 无模块系统，需唯一谓词名）
cost_range_check(Species, Stage, Cost, Output) :-
    once(cost_range_output(input(Species, Stage, Cost), Output)).

% ═══════════════════════════════════════════════════════════════
% 成本区间评估
% ═══════════════════════════════════════════════════════════════

evaluate_cost(Cost, Min, Max, Mid, Status, Detail, Actions) :-
    ( Cost >= Min, Cost =< Max ->
        % 在区间内 — 进一步分档
        ( Cost < Mid * 0.85 ->
            Status = passed_low,
            Detail = in_range_low_side,
            Actions = ['成本偏低，检查原料品质']
        ; Cost > Mid * 1.15 ->
            Status = passed_high,
            Detail = in_range_high_side,
            Actions = ['成本偏高，关注替代原料机会']
        ; Status = passed,
            Detail = in_range_optimal,
            Actions = []
        )
    ; Cost < Min ->
        Gap is Min - Cost,
        Status = failed_low,
        Detail = under_min,
        Actions = ['成本低于下限，排查配方完整性']
    ; Cost > Max ->
        Gap is Cost - Max,
        Status = failed_high,
        Detail = over_max,
        Actions = ['成本超上限，优先评估替代原料',
                   '若市场整体涨价，调整通胀系数']
    ).

% ═══════════════════════════════════════════════════════════════
% 基准成本区间 (元/吨, 2025 基准)
% 数据来源: 行业报价 + 配方经验值
% ═══════════════════════════════════════════════════════════════

base_cost_range(japanese_eel,    adult, 8000,  14000).
base_cost_range(white_shrimp,    adult, 6000,  12000).
base_cost_range(common_carp,     adult, 3500,  6000).
base_cost_range(grass_carp,      adult, 3000,  5500).
base_cost_range(largemouth_bass, adult, 7000,  12000).

% ═══════════════════════════════════════════════════════════════
% 工具谓词
% ═══════════════════════════════════════════════════════════════

my_length([], 0).
my_length([_|T], N) :- my_length(T, M), N is M + 1.

member(X, [X|_]).
member(X, [_|T]) :- member(X, T).

% ═══════════════════════════════════════════════════════════════
% 内嵌测试
% ═══════════════════════════════════════════════════════════════

test_all :-
    write('=== M7a cost_range_rules ==='), nl,
    test_should_pass,
    test_should_fail,
    test_determinism,
    test_output_structure,
    test_inflation,
    test_edge_cases,
    write('=== M7a done ==='), nl.

test_should_pass :-
    % 鳗鱼成体 10200 元/吨 — 在 [8000, 14000] 内
    cost_range_output(input(japanese_eel, adult, 10200),
           output(data(cost_check(S, D)), [], [], _C, _)),
    ( S = passed, D = in_range_optimal ->
        write('[PASS] eel 10200 -> passed'), nl
    ; write('[FAIL] eel 10200 -> '), write(S), write(' / '), write(D), nl
    ),
    % 对虾成体 8500 — 在 [6000, 12000] 内
    cost_range_output(input(white_shrimp, adult, 8500),
           output(data(cost_check(S2, _)), [], [], _, _)),
    member(S2, [passed, passed_high, passed_low]),
    write('[PASS] shrimp 8500 -> passed'), nl,
    % 鲤鱼成体 4000 — 在 [3500, 6000] 内
    cost_range_output(input(common_carp, adult, 4000),
           output(data(cost_check(S3, _)), [], [], _, _)),
    member(S3, [passed, passed_high, passed_low]),
    write('[PASS] carp 4000 -> passed'), nl.

test_should_fail :-
    % 鳗鱼 15000 — 超过 [8000, 14000]
    cost_range_output(input(japanese_eel, adult, 15000),
           output(data(cost_check(S1, _D1)), [], [], _, _A1)),
    ( S1 = failed_high ->
        write('[PASS] eel 15000 -> failed_high'), nl
    ; write('[FAIL] eel 15000 -> '), write(S1), nl
    ),
    % 对虾 4000 — 低于 [6000, 12000]
    cost_range_output(input(white_shrimp, adult, 4000),
           output(data(cost_check(S2, _D2)), [], [], _, _A2)),
    ( S2 = failed_low ->
        write('[PASS] shrimp 4000 -> failed_low'), nl
    ; write('[FAIL] shrimp 4000 -> '), write(S2), nl
    ),
    % 无效物种
    cost_range_output(input(nonexistent, adult, 5000),
           output(data(cost_check(error, invalid_species)), [],
                  [err(invalid_species, nonexistent)], 0.0, [])),
    write('[PASS] invalid_species -> graceful error'), nl.

test_determinism :-
    cost_range_output(input(white_shrimp, adult, 8500), Out1),
    cost_range_output(input(white_shrimp, adult, 8500), Out2),
    ( Out1 = Out2 ->
        write('[PASS] determinism - identical outputs'), nl
    ; write('[FAIL] determinism - outputs differ'), nl
    ).

test_output_structure :-
    cost_range_output(input(white_shrimp, adult, 8500),
           output(data(cost_check(S, _D)), _W, _E, Conf, _NA)),
    ( S \= error, Conf > 0.9 ->
        write('[PASS] structure valid'), nl
    ; write('[FAIL] structure invalid'), nl
    ).

test_inflation :-
    % 3% 通胀 — 鳗鱼区间变为 [8240, 14420]
    cost_range_output(input(japanese_eel, adult, 10200, 0.03),
           output(data(cost_check(S, _)), [], [], _, _)),
    ( S = passed ->
        write('[PASS] eel 10200 +3% inflation -> passed'), nl
    ; write('[FAIL] eel 10200 +3% inflation -> '), write(S), nl
    ),
    % 10% 通胀 — 鲤鱼区间 [3850, 6600]，5000 仍在区间内
    cost_range_output(input(common_carp, adult, 5000, 0.10),
           output(data(cost_check(S2, _)), [], [], _, _)),
    ( S2 = passed ->
        write('[PASS] carp 5000 +10% inflation -> passed'), nl
    ; write('[FAIL] carp 5000 +10% inflation -> '), write(S2), nl
    ).

test_edge_cases :-
    % 5 个物种全部可校验
    test_species_cost(japanese_eel,    10200),
    test_species_cost(white_shrimp,     8500),
    test_species_cost(common_carp,      4000),
    test_species_cost(grass_carp,       3500),
    test_species_cost(largemouth_bass,  8500),
    % 边际值 — 刚好在边界上
    cost_range_output(input(japanese_eel, adult, 8000),
           output(data(cost_check(S6, _)), [], [], _, _)),
    ( S6 = passed_low ->
        write('[PASS] eel 8000 (lower bound) -> passed_low'), nl
    ; write('[FAIL] eel 8000 bound -> '), write(S6), nl
    ),
    cost_range_output(input(japanese_eel, adult, 14000),
           output(data(cost_check(S7, _)), [], [], _, _)),
    ( S7 = passed_high ->
        write('[PASS] eel 14000 (upper bound) -> passed_high'), nl
    ; write('[FAIL] eel 14000 bound -> '), write(S7), nl
    ).

test_species_cost(Sp, Cost) :-
    cost_range_output(input(Sp, adult, Cost),
           output(data(cost_check(S, _)), _W, E, _, _)),
    ( S \= error, E = [] ->
        write('[PASS] '), write(Sp), write(' -> passed'), nl
    ; write('[FAIL] '), write(Sp), write(' -> '), write(E), nl
    ).
