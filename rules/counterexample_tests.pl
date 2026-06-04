% ═══════════════════════════════════════════════════════════════
% counterexample_tests.pl — 反例测试库
% AquaFeedFormulator P0-6
%
% 每个反例测试一个已知的失败场景。
% 通过 = 系统正确拦截了异常输入。
% 失败 = 系统未能拦截，需新增规则。
%
% 运行: test_all_counterexamples.
% ═══════════════════════════════════════════════════════════════

% ==== 测试框架 =================================================

test_all_counterexamples :-
    write('=== 反例测试开始 ==='), nl, nl,
    test_01_nonexistent_species,
    test_02_nonexistent_stage,
    test_03_category_rule_missing,
    test_04_cost_unit_anomaly,
    test_05_ingredient_bounds_invalid,
    test_06_rule_not_approved,
    test_07_delivery_gate_not_passed,
    write('=== 反例测试结束 ==='), nl.

test_pass(Description) :-
    write('  ✅ PASS: '), write(Description), nl.

test_fail(Description) :-
    write('  ❌ FAIL: '), write(Description), write(' — 系统未正确拦截!'), nl.

% ==== 反例 01：物种不存在 =====================================

test_01_nonexistent_species :-
    (  catch(species_exists(nonexistent_species), _, fail) ->
        test_fail('01-物种不存在应被拦截')
    ;  test_pass('01-物种不存在: 已正确拦截')
    ).

% ==== 反例 02：阶段不存在 =====================================

test_02_nonexistent_stage :-
    (  catch(stage_exists(japanese_eel, nonexistent_stage), _, fail) ->
        test_fail('02-阶段不存在应被拦截')
    ;  test_pass('02-阶段不存在: 已正确拦截')
    ).

% ==== 反例 03：品类规则缺失（无 fallback）====================

test_03_category_rule_missing :-
    % 检查组已定义物种是否都有品类规则
    findall(Sp-St,
            ( species_nutrition(Sp, St, _, _, _, _),
              \+ has_category_rules(Sp, St)
            ),
            Missing),
    (  Missing = [] ->
        test_pass('03-品类规则缺失: 所有物种均有品类规则')
    ;  write('  ⚠ WARN: 以下物种/阶段缺少品类规则: '),
       write(Missing), nl,
       test_fail('03-品类规则缺失: 存在未覆盖的物种/阶段')
    ).

% ==== 反例 04：成本单位异常 ===================================

test_04_cost_unit_anomaly :-
    % 模拟：吨成本 ¥500,000（正常约 ¥3,000-30,000）
    (  cost_in_range(500000) ->
        test_fail('04-成本异常检测: 未拦截异常成本')
    ;  test_pass('04-成本异常检测: 已正确识别异常成本')
    ),

    % 正常成本应在范围内
    (  cost_in_range(5000) ->
        test_pass('04-成本正常范围: ¥5,000 在合理区间内')
    ;  test_fail('04-成本正常范围: 误判正常成本为异常')
    ).

% ==== 反例 05：原料 Max < Min =================================

test_05_ingredient_bounds_invalid :-
    % 检查原料库中是否有 Max < Min 的数据错误
    findall(Id,
            ( ingredient(Id, _, _, _, _, _, _, _, _, Max, Min),
              Max < Min
            ),
            Bad),
    (  Bad = [] ->
        test_pass('05-原料用量边界: 无 Max < Min 异常')
    ;  write('  ⚠ WARN: 以下原料 Max < Min: '),
       write(Bad), nl,
       test_fail('05-原料用量边界: 存在数据错误')
    ).

% ==== 反例 06：规则未 approved ================================

test_06_rule_not_approved :-
    % 当前为占位实现，规则状态检查待 rule_version_registry.pl 完成
    write('  ⏸ SKIP: 06-规则审批检查 (需 rule_version_registry.pl)'), nl.

% ==== 反例 07：未完成交付门禁 ==================================

test_07_delivery_gate_not_passed :-
    % 当前为占位实现，交付门禁检查待 delivery_gatekeeper.pl 完成
    write('  ⏸ SKIP: 07-交付门禁检查 (需 delivery_gatekeeper.pl)'), nl.

% ==== 原料数据完整性检查 =======================================

test_ingredient_data_integrity :-
    write('--- 原料数据完整性 ---'), nl,
    findall(Id,
            ( ingredient(Id, _, _, Pro, Fat, Fib, Ash, _, _, _, _),
              ( Pro < 0 ; Fat < 0 ; Fib < 0 ; Ash < 0 )
            ),
            NegNut),
    (  NegNut = [] ->
        test_pass('原料营养值: 无非负检查')
    ;  write('  错误: 以下原料有负营养值: '), write(NegNut), nl,
       test_fail('原料营养值: 存在负数')
    ),

    findall(Id,
            ( ingredient(Id, _, _, Pro, _, _, _, _, Price, _, _),
              Price =< 0
            ),
            ZeroPrice),
    (  ZeroPrice = [] ->
        test_pass('原料价格: 价格均 > 0')
    ;  write('  错误: 以下原料价格 ≤ 0: '), write(ZeroPrice), nl,
       test_fail('原料价格: 存在零或负价格')
    ).

% ==== 物种命名一致性检查 =======================================

test_species_naming_consistency :-
    write('--- 物种命名一致性 ---'), nl,
    findall(Sp,
            ( species_nutrition(Sp, _, _, _, _, _),
              \+ species_name(Sp, _)
            ),
            NoName),
    (  NoName = [] ->
        test_pass('物种命名: nutrition 与 name 一致')
    ;  write('  错误: 以下物种无中文名: '), write(NoName), nl,
       test_fail('物种命名: 不一致')
    ).
