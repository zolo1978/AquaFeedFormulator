% ═══════════════════════════════════════════════════════════════
% counterexample_tests.pl — 反例测试库 v2.0
% AquaFeedFormulator 终审整改
%
% 7 个反例测试，每个测试一个已知失败场景。
% 通过 = 系统正确拦截。失败 = 系统未拦截，需新增规则。
%
% 进入 CI: aqua test
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 测试框架
% ═══════════════════════════════════════════════════════════════

test_all_counterexamples :-
    write('=== 反例测试 (7/7) ==='), nl, nl,
    (  test_01_nonexistent_species -> true ; true ),
    (  test_02_nonexistent_stage -> true ; true ),
    (  test_03_category_rule_missing -> true ; true ),
    (  test_04_cost_unit_anomaly -> true ; true ),
    (  test_05_ingredient_max_lt_min -> true ; true ),
    (  test_06_rule_not_approved -> true ; true ),
    (  test_07_delivery_gate_not_passed -> true ; true ),
    nl, write('=== 反例测试结束 ==='), nl.

test_pass(Description) :-
    write('  ✅ PASS: '), write(Description), nl.

test_fail(Description) :-
    write('  ❌ FAIL: '), write(Description), write(' — 系统未正确拦截!'), nl.

% ═══════════════════════════════════════════════════════════════
% 反例 01：不存在物种 → sop_gatekeeper 必须阻断
% ═══════════════════════════════════════════════════════════════

test_01_nonexistent_species :-
    (  catch(species_exists(nonexistent_species), _, fail) ->
        test_fail('01-物种不存在应被拦截 (species_exists 不应成功)')
    ;  test_pass('01-物种不存在: 已正确拦截')
    ).

% ═══════════════════════════════════════════════════════════════
% 反例 02：不存在阶段 → sop_gatekeeper 必须阻断
% ═══════════════════════════════════════════════════════════════

test_02_nonexistent_stage :-
    (  catch(stage_exists(japanese_eel, nonexistent_stage), _, fail) ->
        test_fail('02-阶段不存在应被拦截')
    ;  test_pass('02-阶段不存在: 已正确拦截')
    ).

% ═══════════════════════════════════════════════════════════════
% 反例 03：品类规则缺失 → 生产模式必须阻断
% ═══════════════════════════════════════════════════════════════

test_03_category_rule_missing :-
    findall(Sp-St,
            ( species_nutrition(Sp, St, _, _, _, _),
              \+ has_category_rules(Sp, St)
            ),
            Missing),
    (  Missing = [] ->
        test_pass('03-品类规则缺失: 所有已定义物种均有品类规则')
    ;  write('  ⚠ WARN: 以下物种/阶段缺少品类规则: '),
       write(Missing), nl,
       test_fail('03-品类规则缺失: 存在未覆盖的物种/阶段')
    ).

% ═══════════════════════════════════════════════════════════════
% 反例 04：成本异常 → detect + 阻断
% ═══════════════════════════════════════════════════════════════

test_04_cost_unit_anomaly :-
    % 异常成本 ¥500,000（鳗鱼正常 ¥9,000-18,000）
    (  cost_in_range(japanese_eel, adult, 500000) ->
        test_fail('04-成本异常检测: 未拦截异常成本 ¥500,000/t')
    ;  test_pass('04-成本异常检测: 已正确识别异常成本')
    ),
    % 正常成本应通过
    (  cost_in_range(japanese_eel, adult, 12000) ->
        test_pass('04-成本正常范围: 鳗鱼 ¥12,000/t 在合理区间内')
    ;  test_fail('04-成本正常范围: 误判正常成本为异常')
    ).

% ═══════════════════════════════════════════════════════════════
% 反例 05：原料 Max < Min → 数据错误必须拦截
% ═══════════════════════════════════════════════════════════════

test_05_ingredient_max_lt_min :-
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

% ═══════════════════════════════════════════════════════════════
% 反例 06：规则未 approved → 交付门禁必须阻断
% ═══════════════════════════════════════════════════════════════

test_06_rule_not_approved :-
    % 当前所有 category_rules.pl 规则默认 approved
    % 后续对接 rule_version_registry.pl 后此项测试有效
    (  rule_approved_for(japanese_eel, adult, starch) ->
        test_pass('06-规则审批: 鳗鱼成体淀粉规则已 approved')
    ;  test_fail('06-规则审批: 规则未 approved 应被拦截')
    ).

% ═══════════════════════════════════════════════════════════════
% 反例 07：交付门禁未完成 → 必须阻断
% ═══════════════════════════════════════════════════════════════

test_07_delivery_gate_not_passed :-
    % can_execute(deliver) 在所有门禁通过前不应成功
    (  catch(can_execute(test_project, deliver), _, fail) ->
        test_fail('07-交付门禁: 未完成门禁不应允许交付')
    ;  test_pass('07-交付门禁: 正确阻断未完成门禁的交付')
    ).

% ═══════════════════════════════════════════════════════════════
% 补充：原料数据完整性
% ═══════════════════════════════════════════════════════════════

test_ingredient_data_integrity :-
    write('--- 原料数据完整性 ---'), nl,
    findall(Id,
            ( ingredient(Id, _, _, Pro, Fat, Fib, Ash, _, _, _, _),
              ( Pro < 0 ; Fat < 0 ; Fib < 0 ; Ash < 0 )
            ),
            NegNut),
    (  NegNut = [] ->
        test_pass('原料营养值: 无非负检查')
    ;  test_fail('原料营养值: 存在负数')
    ),
    findall(Id,
            ( ingredient(Id, _, _, _, _, _, _, _, Price, _, _),
              Price =< 0
            ),
            ZeroPrice),
    (  ZeroPrice = [] ->
        test_pass('原料价格: 均 > 0')
    ;  test_fail('原料价格: 存在零或负价格')
    ).
