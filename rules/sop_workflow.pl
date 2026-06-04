% ═══════════════════════════════════════════════════════════════
% sop_workflow.pl — SOP 状态机
% AquaFeedFormulator P0-3
%
% 定义合法的项目状态和状态转换。
% 所有状态变更必须通过此状态机。
% ═══════════════════════════════════════════════════════════════

% ═══════════════════════════════════════════════════════════════
% 状态定义
% ═══════════════════════════════════════════════════════════════

% 项目状态：
%   init                    — 初始状态
%   requirement_draft       — LLM 已生成需求草案
%   requirement_confirmed   — 用户已确认需求
%   knowledge_draft         — LLM 已生成知识草案
%   knowledge_validated     — Prolog 已验证草案一致性
%   knowledge_approved      — 专家已批准规则
%   solving                 — LP 求解中
%   solved                  — 求解完成
%   validated               — 规则校验通过
%   gated                   — 交付门禁通过
%   reporting               — Rust 报告生成中
%   reported                — 报告已生成
%   delivered               — 已交付用户
%   reviewed                — 用户已验收
%   iterating               — 复盘迭代中

% ═══════════════════════════════════════════════════════════════
% 合法状态转换
% ═══════════════════════════════════════════════════════════════

valid_transition(init, requirement_draft).
valid_transition(requirement_draft, requirement_confirmed).
valid_transition(requirement_draft, init).  % 回退

valid_transition(requirement_confirmed, knowledge_draft).
valid_transition(requirement_confirmed, requirement_draft).  % 重新澄清

valid_transition(knowledge_draft, knowledge_validated).
valid_transition(knowledge_draft, knowledge_draft).  % 重新生成

valid_transition(knowledge_validated, knowledge_approved).
valid_transition(knowledge_validated, knowledge_draft).  % 验证失败，重新生成

valid_transition(knowledge_approved, solving).
valid_transition(knowledge_approved, knowledge_draft).  % 规则异常时回退

valid_transition(solving, solved).
valid_transition(solving, knowledge_draft).  % 求解失败（infeasible），可能需要调整规则

valid_transition(solved, validated).
valid_transition(solved, solving).  % 重新求解

valid_transition(validated, gated).
valid_transition(validated, solving).  % 校验失败，重新求解

valid_transition(gated, reporting).
valid_transition(gated, solving).  % 门禁失败，重新求解

valid_transition(reporting, reported).
valid_transition(reporting, reporting).  % 重试

valid_transition(reported, delivered).

valid_transition(delivered, reviewed).

valid_transition(reviewed, iterating).
valid_transition(reviewed, requirement_draft).  % 新需求
valid_transition(iterating, knowledge_draft).   % 迭代后重新进入
valid_transition(iterating, reviewed).            % 不需要迭代

% ═══════════════════════════════════════════════════════════════
% 状态推进
% ═══════════════════════════════════════════════════════════════

% advance(+Project, +CurrentState, -NextState, +Action)
% 执行 Action 后，项目从 CurrentState 推进到 NextState

advance(Project, From, To, Action) :-
    valid_transition(From, To),
    write('  [SOP] '), write(Project), write(': '),
    write(From), write(' → '), write(To),
    write(' ('), write(Action), write(')'), nl.

% ═══════════════════════════════════════════════════════════════
% 回退判定
% ═══════════════════════════════════════════════════════════════

% can_rollback(+Project, +ToState)
% 项目是否可以回退到 ToState
can_rollback(Project, ToState) :-
    % TODO: 从 Rust 获取当前状态
    current_state(Project, _Current),
    valid_transition(_, ToState).

current_state(_, init).  % 占位
