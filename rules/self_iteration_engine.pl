% ═══════════════════════════════════════════════════════════════
% self_iteration_engine.pl — 自我迭代引擎 v2.0（最小闭环）
% AquaFeedFormulator 终审整改
%
% 当前只做 cost_unit_anomaly 闭环，不做完整自进化：
%
%   cost_unit_anomaly 触发
%     → 生成 patch_draft
%     → 跑 7 个反例测试
%     → 人工确认
%     → patch_active
%     → 可回滚 (must_rollback + execute_rollback)
%
% 把这个跑通，再扩展其他类型。
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 最小闭环: cost_unit_anomaly → patch_draft → 回滚就绪
% ═══════════════════════════════════════════════════════════════

% cost_anomaly_iterate(+Species, +Stage, +Description, -Patch)
% 成本异常触发后的最小迭代闭环

cost_anomaly_iterate(Species, Stage, Description, Patch) :-
    Patch = patch{
        id: _,
        trigger: Description,
        root_cause: '成本单位异常：需检查 Price 单位(元/kg)或吨成本公式',
        action_type: rule_fix,
        affected_files: ['sop_engine.pl', 'cost_in_range'],
        species: Species,
        stage: Stage,
        status: patch_draft
    },
    write('[ITERATION] cost_unit_anomaly 迭代触发'), nl,
    write('  species: '), write(Species), nl,
    write('  stage: '), write(Stage), nl,
    write('  patch: '), write(Patch), nl.

% ═══════════════════════════════════════════════════════════════
% 回滚条件
% ═══════════════════════════════════════════════════════════════

% must_rollback(+Patch) — 4 种回滚触发条件

must_rollback(Patch) :-
    patch_status(Patch, patch_active),
    regression_failed(Patch).

must_rollback(Patch) :-
    patch_status(Patch, patch_active),
    expert_revoked(Patch).

must_rollback(Patch) :-
    patch_status(Patch, patch_active),
    critical_output_anomaly(Patch).

must_rollback(Patch) :-
    patch_status(Patch, patch_active),
    cost_validation_failed(Patch).

% execute_rollback(+Patch)
execute_rollback(Patch) :-
    patch_status(Patch, OldStatus),
    write('[ROLLBACK] '), write(Patch), write(' '),
    write(OldStatus), write(' -> patch_rollback'), nl,
    retractall(patch_status(Patch, OldStatus)),
    assertz(patch_status(Patch, patch_rollback)).

% ═══════════════════════════════════════════════════════════════
% 补丁生命周期
% ═══════════════════════════════════════════════════════════════

% patch_draft → patch_validated → patch_approved → patch_active
%                                                       │
%                                             old_rule → archived
%
% 回滚：patch_active → patch_rollback

valid_transition(patch_draft, patch_validated).
valid_transition(patch_validated, patch_approved).
valid_transition(patch_approved, patch_active).
valid_transition(patch_active, archived).
valid_transition(archived, deprecated).
valid_transition(patch_active, patch_rollback).
valid_transition(patch_rollback, patch_draft).

% 激活条件（4 道门禁）
% 1. Prolog 规则一致性测试通过
% 2. 反例回归测试通过
% 3. 专家或用户确认
% 4. 旧版本可回滚

can_activate_patch(Patch) :-
    rule_consistency_passed(Patch),
    counterexample_regression_passed(Patch),
    expert_confirmed(Patch),
    rollback_available_for(Patch).

% ── 占位子句（Rust 注入） ──
patch_status(_, patch_draft).        % 默认状态
rule_consistency_passed(_).          % TODO: Rust 注入
counterexample_regression_passed(_). % TODO: Rust 注入
expert_confirmed(_).                 % TODO: Rust 注入
rollback_available_for(_).           % TODO: Rust 注入

% ── 回滚检测占位 ──
regression_failed(_) :- fail.
expert_revoked(_) :- fail.
critical_output_anomaly(_) :- fail.
cost_validation_failed(_) :- fail.
