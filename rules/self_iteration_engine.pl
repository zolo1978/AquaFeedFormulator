% ═══════════════════════════════════════════════════════════════
% self_iteration_engine.pl — 自我迭代引擎
% AquaFeedFormulator P0-7
%
% 在每次执行、验收、失败或用户反馈后，
% 将问题归因转化为可测试补丁，
% 通过 Prolog 反例测试、专家确认和版本管理，
% 使知识库、规则库、SOP、执行策略与报告模板持续进化。
%
% 核心原则：
%   - 复盘只能生成 patch_draft，不能直接修改 active 规则
%   - 补丁激活需通过 4 道门禁
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 复盘 → 诊断 → 生成补丁
% ═══════════════════════════════════════════════════════════════

% iterate(+IssueType, +Description, -Patch)
% 复盘发现的问题 → 迭代动作映射

% 需求漏问 → 更新需求澄清模板
iterate(requirement_missing, Description, Patch) :-
    Patch = patch{
        id: _,
        trigger: Description,
        root_cause: '需求澄清模板不完整',
        action_type: update_requirement_template,
        affected_files: ['requirement_gatekeeper.pl'],
        status: patch_draft
    }.

% 知识缺失 → 更新知识库
iterate(knowledge_gap, Description, Patch) :-
    Patch = patch{
        id: _,
        trigger: Description,
        root_cause: '知识库缺少该领域的规则/数据',
        action_type: update_knowledge_base,
        affected_files: ['ingredient_db.pl', 'species_nutrition.pl'],
        status: patch_draft
    }.

% 规则未拦截错误 → 新增 Prolog 规则
iterate(rule_failed_to_catch, Description, Patch) :-
    Patch = patch{
        id: _,
        trigger: Description,
        root_cause: '现有限制规则不足以拦截该异常',
        action_type: add_validation_rule,
        affected_files: ['category_rules.pl', 'formula_rule_engine.pl'],
        status: patch_draft
    }.

% 流程跳步 → 修改 SOP 状态机
iterate(process_skipped_step, Description, Patch) :-
    Patch = patch{
        id: _,
        trigger: Description,
        root_cause: 'SOP 状态机允许了不该允许的转换',
        action_type: modify_sop_state_machine,
        affected_files: ['sop_workflow.pl', 'sop_gatekeeper.pl'],
        status: patch_draft
    }.

% 同类错误重复 → 新增反例测试
iterate(repeated_error, Description, Patch) :-
    Patch = patch{
        id: _,
        trigger: Description,
        root_cause: '反例测试库未覆盖该场景',
        action_type: add_counterexample_test,
        affected_files: ['counterexample_tests.pl'],
        status: patch_draft
    }.

% 执行失败 → 更新 Rust 执行策略
iterate(execution_failure, Description, Patch) :-
    Patch = patch{
        id: _,
        trigger: Description,
        root_cause: 'Rust 执行策略未处理该错误路径',
        action_type: update_rust_strategy,
        affected_files: ['rust-core/src/recovery.rs'],
        status: patch_draft
    }.

% 报告误导 → 更新报告模板
iterate(report_misleading, Description, Patch) :-
    Patch = patch{
        id: _,
        trigger: Description,
        root_cause: '报告模板未包含必要的免责声明或说明',
        action_type: update_report_template,
        affected_files: ['rust-core/src/report_builder.rs'],
        status: patch_draft
    }.

% 需人工判断 → 标记 expert_review
iterate(needs_expert_judgment, Description, Patch) :-
    Patch = patch{
        id: _,
        trigger: Description,
        root_cause: '当前系统无法自动判定，需专家介入',
        action_type: mark_expert_review_required,
        affected_files: [],
        status: patch_draft
    }.

% 未知问题类型
iterate(unknown, Description, Patch) :-
    Patch = patch{
        id: _,
        trigger: Description,
        root_cause: '未归类问题，需人工分析',
        action_type: manual_analysis_required,
        affected_files: [],
        status: patch_draft
    }.

% ═══════════════════════════════════════════════════════════════
% 补丁生命周期
% ═══════════════════════════════════════════════════════════════

% patch_draft → patch_validated → patch_approved → patch_active
%                                                       │
%                                             old_rule → archived
%
% 回滚路径：patch_active → patch_rollback (恢复旧规则)

% 推进状态
advance_patch(Patch, NextStatus) :-
    patch_status(Patch, Current),
    valid_transition(Current, NextStatus).

valid_transition(patch_draft, patch_validated).
valid_transition(patch_validated, patch_approved).
valid_transition(patch_approved, patch_active).
valid_transition(patch_active, archived).
valid_transition(archived, deprecated).
valid_transition(patch_active, patch_rollback).   % ← 回滚路径
valid_transition(patch_rollback, patch_draft).    % ← 修复后可重新进入

% ═══════════════════════════════════════════════════════════════
% 回滚条件 (P0-7 新增)
% ═══════════════════════════════════════════════════════════════

% 新规则导致原有正例失败 → 自动回滚
must_rollback(Patch) :-
    patch_status(Patch, patch_active),
    regression_failed(Patch).

% 专家撤销确认 → 回滚
must_rollback(Patch) :-
    patch_status(Patch, patch_active),
    expert_revoked(Patch).

% 关键输出异常 → 回滚
must_rollback(Patch) :-
    patch_status(Patch, patch_active),
    critical_output_anomaly(Patch).

% 补丁激活后成本校验失败 → 回滚
must_rollback(Patch) :-
    patch_status(Patch, patch_active),
    cost_validation_failed(Patch).

% 回滚执行
execute_rollback(Patch) :-
    patch_status(Patch, OldStatus),
    write('[ROLLBACK] '), write(Patch), write(' '),
    write(OldStatus), write(' -> patch_rollback'), nl,
    retractall(patch_status(Patch, OldStatus)),
    assertz(patch_status(Patch, patch_rollback)),
    restore_previous_rule(Patch).

% 推断占位子句（子 agent 实现）
regression_failed(Patch) :-
    write('[ITERATION] 检查回归测试: '), write(Patch), nl,
    fail.  % TODO: 调用 counterexample_tests

expert_revoked(Patch) :-
    write('[ITERATION] 检查专家确认状态...'), nl,
    fail.  % TODO: 检查 approval 记录

critical_output_anomaly(Patch) :-
    write('[ITERATION] 检查输出异常...'), nl,
    fail.  % TODO: 成本/营养阈值检测

cost_validation_failed(Patch) :-
    write('[ITERATION] 成本校验失败...'), nl,
    fail.

restore_previous_rule(Patch) :-
    write('[ITERATION] 从 rule_version_registry 恢复旧版规则...'), nl.
    % TODO: 实现规则恢复

% ═══════════════════════════════════════════════════════════════
% 完整迭代流程
% ═══════════════════════════════════════════════════════════════

full_iteration_cycle(IssueType, Description) :-
    write('[ITERATION] === 开始迭代周期 ==='), nl,
    % 1. 归因
    iterate(IssueType, Description, Patch),
    write('[ITERATION] 归因完成: '), write(Patch), nl,
    % 2. 一致性测试
    (  rule_consistency_passed(Patch) ->
        write('[ITERATION] 一致性测试: PASS'), nl,
        advance_patch(Patch, patch_validated)
    ;  write('[ITERATION] 一致性测试: FAIL'), nl, fail
    ),
    % 3. 回归测试
    (  counterexample_regression_passed(Patch) ->
        write('[ITERATION] 回归测试: PASS'), nl
    ;  write('[ITERATION] 回归测试: FAIL'), nl, fail
    ),
    % 4. 等待确认
    write('[ITERATION] 等待专家确认...'), nl,
    % 5. 激活
    (  can_activate_patch(Patch) ->
        advance_patch(Patch, patch_active),
        write('[ITERATION] 补丁已激活, 旧规则已归档, 可回滚'), nl
    ;  write('[ITERATION] 激活条件不满足'), nl, fail
    ).

% ═══════════════════════════════════════════════════════════════
% 激活门禁
% ═══════════════════════════════════════════════════════════════

% 补丁激活必须满足 4 个条件：
%   1. Prolog 规则一致性测试通过
%   2. 反例回归测试通过
%   3. 专家或用户确认
%   4. 旧版本可回滚

can_activate_patch(Patch) :-
    rule_consistency_passed(Patch),
    counterexample_regression_passed(Patch),
    expert_confirmed(Patch),
    rollback_available_for(Patch).

% 占位子句
rule_consistency_passed(_) :-
    write('  [迭代] 规则一致性测试... (需实现)'), nl.
    % TODO: 加载更新后的规则文件，运行一致性测试

counterexample_regression_passed(_) :-
    write('  [迭代] 反例回归测试... (需实现)'), nl.
    % TODO: 运行 test_all_counterexamples

expert_confirmed(_) :-
    write('  [迭代] 专家确认状态检查... (需实现)'), nl.
    % TODO: 检查 patch.approved_by 字段

rollback_available_for(_) :-
    write('  [迭代] 回滚可用性检查... (需实现)'), nl.
    % TODO: 检查 rule_version_registry 中是否有旧版本

% ═══════════════════════════════════════════════════════════════
% 补丁状态查询
% ═══════════════════════════════════════════════════════════════

patch_status(Patch, Status) :-
    % TODO: 从规则版本库查询
    Status = patch_draft.

% ═══════════════════════════════════════════════════════════════
% 复盘总结生成
% ═══════════════════════════════════════════════════════════════

% review_report(+ProjectId, +Issues, -Report)
% 对一次完整执行的复盘生成结构化总结

review_report(ProjectId, Issues, Report) :-
    Report = review{
        project_id: ProjectId,
        date: _,
        issues: Issues,
        patches: _,
        summary: _
    }.

% ═══════════════════════════════════════════════════════════════
% 典型复盘场景示例
% ═══════════════════════════════════════════════════════════════

% 场景1：成本单位异常触发后的迭代
% 复盘 → 诊断根因(display_recipe 公式错误) → 补丁 → 测试 → 激活

% 场景2：品类约束缺失导致不可行解
% 复盘 → 新增品类规则草案 → 验证 → 专家确认 → 激活

% 场景3：新物种营养需求缺失
% 复盘 → LLM 生成知识草案 → Prolog 验证 → 专家确认 → 入库
