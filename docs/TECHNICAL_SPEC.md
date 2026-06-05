# AquaFeedFormulator 技术说明书 v2.0

> LLM + Prolog + Rust 三核协作 · 水产饲料研发 SOP Agent 系统  
> 版本：v2.0 | 日期：2026-06-05 | 终审整改版

---

## 目录

1. [系统定位](#1-系统定位)
2. [总体架构](#2-总体架构)
3. [SOP 全流程节点 (6 步)](#3-sop-全流程节点)
4. [技术栈 MECE 分解](#4-技术栈-mece-分解)
5. [Prolog 规则层详解](#5-prolog-规则层详解)
6. [Rust 执行层详解](#6-rust-执行层详解)
7. [数据流与文件规范](#7-数据流与文件规范)
8. [已知限制与演进路线](#8-已知限制与演进路线)

---

## 1. 系统定位

AquaFeedFormulator **不是单纯的「自动配方求解器」**，而是一个以 SOP 流程为核心的 Agent 系统。LP 线性规划只是 Prolog 层的一个子模块。

| 层 | 角色 | 职责 | 权限边界 |
|---|------|------|---------|
| **LLM** | 创意层 | 需求理解、知识草案生成、结果解释 | ❌ 不可裁决，输出默认 draft |
| **Prolog** | 裁判层 | SOP 主控、规则验证、门禁判定 | 决定能不能执行 |
| **Rust** | 执行层 | 工程执行、状态管理、JSON/日志/报告输出 | 每步问 Prolog `can_execute` |
| **LP Solver** | 求解子模块 | 约束满足 + 成本最小化 | Prolog 子模块，仅负责数学求解 |

**核心价值链路：**

```
需求澄清 → 规则建模 → 配方求解(LP) → 门禁校验 → 报告交付 → 复盘迭代
```

---

## 2. 总体架构

```
┌──────────────────────────────────────────────────────────────┐
│                         用户接口层                            │
│                   aqua solve --species X --stage Y            │
└───────────────────────────┬──────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│                   Rust CLI (aqua)                              │
│  · 状态管理 (project_state)  · scryer-prolog 调用             │
│  · JSON 序列化               · 执行日志记录                   │
│  · DOCX 报告生成             · 复盘报告生成                   │
└───────────────────────────┬──────────────────────────────────┘
                            │ 每次调用注入 project_state fact
┌───────────────────────────▼──────────────────────────────────┐
│                 Prolog SOP 主控层 (scryer-prolog v0.10)       │
│                                                               │
│  ┌─────────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │ sop_gatekeeper  │  │ sop_engine   │  │ delivery_       │  │
│  │   can_execute   │──│ 编排求解流程  │──│ gatekeeper      │  │
│  │   动作放行/阻断  │  │              │  │   交付判定       │  │
│  └─────────────────┘  └──────┬───────┘  └─────────────────┘  │
│                              │                                │
│              ┌───────────────┼───────────────┐               │
│              │               │               │               │
│     ┌────────▼───────┐ ┌────▼─────┐ ┌───────▼────────┐      │
│     │ LP Solver      │ │ 品类规则  │ │ 反例测试        │      │
│     │ formulation_   │ │ category │ │ counterexample  │      │
│     │ lp_engine.pl   │ │ _rules   │ │ _tests.pl       │      │
│     │ (simplex)      │ │ (唯一源)  │ │ (7 tests)       │      │
│     └────────────────┘ └──────────┘ └────────────────┘      │
│                                                               │
│     ┌─────────────────┐  ┌─────────────────────────────────┐ │
│     │ ingredient_db   │  │ species_nutrition               │ │
│     │ (100+ 原料)     │  │ (18 物种营养目标)                │ │
│     └─────────────────┘  └─────────────────────────────────┘ │
│                                                               │
│     ┌──────────────────────────────────────────────────────┐ │
│     │ self_iteration_engine.pl                             │ │
│     │   cost_anomaly → patch_draft → 回滚就绪               │ │
│     └──────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│                        输出层                                  │
│  · validation_result.json                                    │
│  · delivery_decision.json                                    │
│  · execution_log.json                                        │
│  · retrospective_*.md / .json                                │
│  · patch_draft_*.json                                        │
│  · 南美白对虾成体饲料配方报告.docx                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. SOP 全流程节点

以下是 `aqua solve` 一条命令触发的完整 6 步流程，每个节点包含：**输入 / 处理 / 输出 / 使用技术**。

---

### [1/6] `can_execute` 门禁检查

| 维度 | 内容 |
|------|------|
| **触发** | Rust 构造 `can_execute(project, solve(species, stage)).` 查询 |
| **Prolog 文件** | `rules/sop_gatekeeper.pl` |
| **检查项** | ① 物种存在性 (`species_exists/1`) → 查 `species_nutrition.pl`<br>② 阶段存在性 (`stage_exists/2`) → 查 `species_nutrition.pl`<br>③ 品类规则可用 (`has_category_rules_or_fallback/3`) → 查 `category_rules.pl` + fallback 控制<br>④ 原料库非空 (`ingredients_available/0`) → 查 `ingredient_db.pl` |
| **判定结果** | `allow` → 继续；`block` → 终止 |
| **使用技术** | Prolog 事实匹配 (unification)、`findall/3`、`catch/3`、逻辑否定 `\+` |
| **输出** | Rust `ExecutionStep { result: "allow" \| "block" }` |

**关键设计：生产模式绝不静默 fallback。** `allow_fallback(production, false)` 确保缺品类规则的物种直接阻断。

```
can_execute(production, solve(Species, Stage)) :-
    species_exists(Species),          % → species_nutrition.pl
    stage_exists(Species, Stage),     % → species_nutrition.pl
    has_category_rules_or_fallback(production, Species, Stage), % → category_rules.pl
    ingredients_available.           % → ingredient_db.pl
```

---

### [2/6] LP 配方求解

| 维度 | 内容 |
|------|------|
| **触发** | Rust 构造 `solve_formulation(species, stage).` 查询 |
| **Prolog 文件** | `rules/sop_engine.pl` (编排) + `rules/formulation_lp_engine.pl` (求解) |
| **子步骤** | ① 读取营养目标 → `species_nutrition/6`<br>② 读取品类约束 → `species_category_constraints_strict/3` (唯一源: `category_rules.pl`)<br>③ 构造 LP 模型 → `lp_solve/6` |
| **LP 求解器** | scryer-prolog 内置 `library(simplex)` |
| **整数处理** | Price × 10 取整 (避免浮点精度问题) |
| **品类约束** | 每类原料用量 % 上下限，编译为 LP 约束行 |
| **判定结果** | `solved` → 输出配方；`infeasible` → 输出"不可行" |
| **使用技术** | 线性规划 (Simplex 算法)、约束编译、整数缩放 |
| **输出** | `recipe_sop(Items, TotalCost)` 或 `infeasible` |

**LP 模型构建流程：**

```
原料数据库 (ingredient/11)
        │
        ▼
variable_ingredient/8 ────── 可变原料: 蛋白/脂肪/纤维/灰分/价格/上限/下限
fixed_ingredient/5      ────── 固定原料: 预混料/矿物质等 Min=Max 的原料
        │
        ▼
construct_objective/2  ──────  目标函数: min Σ(Pct_i × Price_i × 10)
construct_nutrition_constraints/6 ── 营养约束: Pro ≥ Tgt, Fat ≥ Tgt, Fib ≤ Max, Ash ≤ Max
construct_category_constraints/2   ── 品类约束: 每类 min ≤ ΣPct ≤ max
construct_closure_constraint/1     ── 闭合约束: ΣPct = 100%
        │
        ▼
simplex: solve(Obj, Constraints, S0, Variables) → States
        │
        ▼
extract_recipe/4 → recipe_sop(Items, TotalCost)
```

**成本单位修正 (P0)：**

| 字段 | 单位 | 说明 |
|------|------|------|
| `ingredient/11` Price | 元/kg | 原始数据 |
| LP 目标函数系数 | `round(Price × 10)` | 整数化 |
| 求解器内部 Cost | `Pct × Price` (元/100kg) | LP 变量 × 系数 |
| 吨成本 | `TotalCost × 10` (元/吨) | 最终输出 |

---

### [3/6] 交付门禁

| 维度 | 内容 |
|------|------|
| **触发** | Rust 构造 `deliverable(species, stage, D), write(D).` 查询 |
| **Prolog 文件** | `rules/delivery_gatekeeper.pl` |
| **检查项** (7 道) | ① 配方闭合 `check_closure/2` — 100% ± 0.1%<br>② 营养达标 `check_nutrition/4` — Pro/Fat≥目标, Fib/Ash≤目标<br>③ 品类约束 `check_category/4` — 全部 `species_category_rule` 满足<br>④ 成本合理 `check_cost_range/4` — 按物种细分区间<br>⑤ 合规检查 `check_compliance/3` — GB/T (占位)<br>⑥ 规则 approved `check_rule_approved/3` — 所有规则已批准<br>⑦ 反例测试 `check_counterexamples/1` — 所有反例通过 |
| **判定结果** | `passed` → 可交付；`failed([Reason])` → 阻断 |
| **使用技术** | 加权平均计算 (`wavg_nut/8`)、`findall/3`、逻辑分支 (`-> ;`) |
| **输出** | `Decision = passed \| failed([...])` → Rust 写 `delivery_decision.json` |

> 当前无配方版本 (`deliverable/3`) 仅检查 ⑤⑥⑦（合规 + 规则 approved + 反例）。有配方版本 (`deliverable/4`) 检查全部 7 道。

---

### [4/6] DOCX 配方报告生成

| 维度 | 内容 |
|------|------|
| **触发** | Rust `generate_docx_report()` → `python3 generate_report.py [json]` |
| **实现语言** | Python 3 |
| **依赖库** | `python-docx` |
| **数据来源** | ① LP 可行 → `generated/recipe_data.json`<br>② LP 不可行 → 内嵌专家经验配方 (Python `get_embedded_data()`) |
| **报告内容** | 封面页、营养需求表、3 方案配方表 (A/B/C)、三方案对比表、Prolog 校验结果、使用建议 |
| **输出路径** | `~/Desktop/南美白对虾成体饲料配方报告.docx` |

---

### [5/6] 复盘报告

| 维度 | 内容 |
|------|------|
| **触发** | Rust `generate_retrospective()` — 纯 Rust 实现 |
| **数据来源** | 运行时变量: `steps`、`deliverable`、起止时间戳 |
| **Markdown 报告** | 概要表 (`物种/阶段/耗时/交付判定/步骤通过率`)、步骤明细表、风险评估 (🔴高/🟡中/🟢低)、进化建议 |
| **JSON 报告** | 结构化复盘数据 (`duration_ms`, `risk_level`, `warnings`, `steps_summary`) |
| **输出路径** | `generated/retrospective_YYYYMMDD-HHMMSS.md` + `.json` |
| **使用技术** | Rust `fs::write`、`chrono::DateTime`、`signed_duration_since`、Markdown 模板字符串 |

---

### [6/6] 自我迭代引擎

| 维度 | 内容 |
|------|------|
| **触发** | Rust `run_self_iteration()` → scryer-prolog `cost_anomaly_iterate/4` |
| **Prolog 文件** | `rules/self_iteration_engine.pl` |
| **当前闭环** | `cost_unit_anomaly → patch_draft → 回滚就绪` |
| **检测逻辑** | 若吨成本超出 `cost_in_range/3` 定义的物种合理区间，触发异常 |
| **patch_draft** | 记录 `trigger`、`root_cause`、`action_type`、`affected_files`、`status: patch_draft` |
| **回滚机制** | `must_rollback/1` 4 种触发 (regression/revoked/anomaly/cost_failed) → `execute_rollback/1` |
| **补丁生命周期** | `draft → validated → approved → active → archived → deprecated` |
| **输出** | `generated/patch_draft_YYYYMMDD-HHMMSS.json` |
| **使用技术** | Prolog 动态事实 (`assertz`/`retractall`)、状态机模式 |

---

## 4. 技术栈 MECE 分解

| 技术领域 | 具体技术/工具 | 版本 | 用途 | 所在节点 |
|---------|-------------|------|------|---------|
| **逻辑编程** | Prolog (scryer-prolog) | v0.10 | SOP 主控、规则验证、门禁判定 | [1][2][3][6] |
| **系统编程** | Rust | 2021 edition | CLI 入口、状态管理、JSON 序列化、进程调度 | [1]~[6] |
| **脚本语言** | Python 3 | ≥3.9 | DOCX 报告生成 | [4] |
| **线性规划** | Simplex (scryer-prolog library) | 内置 | 配方约束求解 | [2] |
| **文档生成** | python-docx | latest | 专业配方报告输出 | [4] |
| **CLI 框架** | clap (Rust) | 4.x | 命令行参数解析 | [1]~[6] |
| **JSON 序列化** | serde + serde_json (Rust) | 1.x | 结构化输出 | [3][5][6] |
| **时间处理** | chrono (Rust) | 0.4.x | 时间戳、耗时计算 | [1]~[6] |
| **进程间通信** | Rust `std::process::Command` | std | Rust ⇄ scryer-prolog ⇄ Python3 | [2][4][6] |
| **状态注入** | Prolog dynamic fact (`assertz`) | — | Rust 每次调用前注入 `project_state/2` | [1]~[3] |
| **文件系统** | Rust `std::fs` | std | 文件读写、目录管理 | [1]~[6] |
| **Markdown** | 纯字符串模板 | — | 复盘报告生成 | [5] |

---

## 5. Prolog 规则层详解

### 5.1 文件职责矩阵

| 文件 | 行数 | 职责 | 被谁依赖 | 提供的公开谓词 |
|------|------|------|---------|-------------|
| `ingredient_db.pl` | ~250 | 100+ 种原料数据 | 所有模块 | `ingredient/11` |
| `species_nutrition.pl` | ~200 | 18 种物种营养需求 | 所有模块 | `species_nutrition/6` |
| `category_rules.pl` | ~170 | ★ 唯一品类约束源 + 成本区间 + fallback | sop_engine, delivery_gatekeeper | `species_category_rule/6`, `species_category_constraints_strict/3`, `reasonable_cost_range/4` |
| `sop_gatekeeper.pl` | 170 | 动作放行/阻断 + fallback 控制 | Rust (all steps) | `can_execute/2`, `allow_fallback/2`, `species_exists/1`, `cost_in_range/3` |
| `sop_engine.pl` | 136 | 求解编排 + 结果展示 | Rust (step 2) | `solve_formulation/2`, `species_name/2`, `stage_name/2` |
| `formulation_lp_engine.pl` | 186 | LP 求解核心 (simplex) | sop_engine | `lp_solve/6` |
| `delivery_gatekeeper.pl` | 199 | 交付门禁 (7 道检查) | Rust (step 3) | `deliverable/3`, `deliverable/4` |
| `counterexample_tests.pl` | 148 | 7 个自动化反例测试 | Rust (aqua test) | `test_all_counterexamples/0` |
| `self_iteration_engine.pl` | 111 | 自我迭代最小闭环 | Rust (step 6, 独立加载) | `cost_anomaly_iterate/4`, `must_rollback/1` |

### 5.2 依赖关系图

```
sop_gatekeeper.pl ───→ species_nutrition.pl
                   ───→ category_rules.pl
                   ───→ ingredient_db.pl

sop_engine.pl ───────→ sop_gatekeeper.pl      (can_execute)
               ───────→ category_rules.pl      (品类约束唯一源)
               ───────→ formulation_lp_engine.pl (LP 求解托管)
               ───────→ species_nutrition.pl

formulation_lp_engine.pl → ingredient_db.pl
                         → library(simplex)

delivery_gatekeeper.pl → category_rules.pl
                       → species_nutrition.pl

counterexample_tests.pl → sop_gatekeeper.pl
                        → category_rules.pl

self_iteration_engine.pl → (独立加载, 不在主 consult 链)
```

### 5.3 核心设计决策

| 决策 | 原因 |
|------|------|
| 品类约束 `category_rules.pl` 唯一源 | 原先 `sop_engine.pl` 和 `formula_closure_validator.pl` 各有一份，修改不同步。现在所有品类规则只在 `category_rules.pl` 定义。 |
| `allow_fallback(production, false)` | 生产模式绝不静默 fallback。缺品类规则的物种直接阻断，不降级为全局兜底规则。 |
| Rust 管状态，Prolog 管判断 | Prolog 不保存状态（无副作用）。每次调用 Prolog 时 Rust 注入 `project_state/2` 动态事实。 |
| LP 求解从 `sop_engine.pl` 提取到 `formulation_lp_engine.pl` | 关注点分离：流程编排 vs 数学求解。 |
| `price × 10` 整数化 | 避免 scryper-prolog simplex 浮点精度问题。 |

---

## 6. Rust 执行层详解

### 6.1 模块结构

```
rust-core/
├── Cargo.toml
│   ├── clap = "4"           # CLI 参数解析
│   ├── chrono = "0.4"       # 时间处理
│   └── serde + serde_json   # JSON 序列化
│
└── src/main.rs (550 行)
    ├── struct Cli / Commands    # 命令行定义
    ├── fn main()                # 路由: Solve | Test | Gate
    ├── fn solve()               # ★ 核心流程 6 步
    ├── fn run_prolog()          # scryer-prolog 调用 + consult 组装
    ├── fn run_prolog_bool()     # 返回 (ok, stdout+stderr)
    ├── fn generate_docx_report()# Python3 调用生成 DOCX
    ├── fn generate_retrospective() # Markdown + JSON 复盘
    ├── fn run_self_iteration()  # Prolog 自我迭代
    ├── fn write_json()          # serde 序列化到 generated/
    ├── fn write_execution_log() # 执行日志
    ├── fn run_counterexample_tests() # aqua test
    ├── fn run_delivery_gate()   # aqua gate
    └── structs: ExecutionLog, ValidationResult,
                  DeliveryDecision, SolutionResult, ...
```

### 6.2 核心函数: `solve()`

```rust
fn solve(project, species, stage) {
    // Step 1: can_execute
    run_prolog_bool("can_execute(project, solve(species, stage)).")
    → allow → 继续 | block → 终止

    // Step 2: LP 求解
    run_prolog_bool("solve_formulation(species, stage).")
    → solved → 继续 | infeasible → 生成 DOCX + 复盘 + 迭代 → return

    // Step 3: 交付门禁
    run_prolog_bool("deliverable(species, stage, D), write(D).")
    → passed / failed

    // JSON 输出
    validation_result.json   ← SolutionResult::Solved / Infeasible
    delivery_decision.json   ← DeliveryDecision { deliverable, checks, warnings }
    execution_log.json       ← ExecutionLog { steps[], exit_code }

    // Step 4: DOCX 报告
    python3 generate_report.py [json_path | __embedded__]

    // Step 5: 复盘报告
    generate_retrospective() → retrospective_*.md + .json

    // Step 6: 自我迭代
    run_self_iteration() → patch_draft_*.json
}
```

### 6.3 Prolog 进程调用机制

```rust
fn run_prolog(query, state_facts) -> Output {
    // Rust 构造 consult 链:
    //   assertz((state_facts)),      ← 仅当有 state_facts
    //   consult('ingredient_db.pl'),
    //   consult('species_nutrition.pl'),
    //   consult('category_rules.pl'),
    //   consult('sop_gatekeeper.pl'),
    //   consult('formulation_lp_engine.pl'),
    //   consult('delivery_gatekeeper.pl'),
    //   consult('sop_engine.pl'),
    //   {query}, halt.

    Command::new("/opt/homebrew/bin/scryer-prolog")
        .args(["-g", &consult_block])
        .current_dir(project_root())
        .output()
}
```

> **注意**: `self_iteration_engine.pl` 不在主 consult 链中（因其 dict 语法与 scryer-prolog 兼容性问题），仅在 `run_self_iteration()` 中独立加载。

---

## 7. 数据流与文件规范

### 7.1 输入文件

| 文件 | 格式 | 内容 |
|------|------|------|
| `rules/ingredient_db.pl` | Prolog facts | 100+ 种原料 (名称/分类/蛋白/脂肪/纤维/灰分/价格/上限/下限) |
| `rules/species_nutrition.pl` | Prolog facts | 18 种物种 × 多阶段的蛋白/脂肪/纤维/灰分目标 |
| `rules/category_rules.pl` | Prolog rules + facts | 品类约束 (每类原料 min/max %) + 按物种成本区间 |

### 7.2 输出文件

| 文件 | 格式 | 生成方式 | 节点 |
|------|------|---------|------|
| `generated/validation_result.json` | JSON | Rust serde | [2] |
| `generated/delivery_decision.json` | JSON | Rust serde | [3] |
| `generated/execution_log.json` | JSON | Rust serde | [1][2][3] |
| `~/Desktop/南美白对虾成体饲料配方报告.docx` | DOCX | Python `python-docx` | [4] |
| `generated/retrospective_*.md` | Markdown | Rust 字符串模板 | [5] |
| `generated/retrospective_*.json` | JSON | Rust serde | [5] |
| `generated/patch_draft_*.json` | JSON | Rust serde | [6] |

### 7.3 JSON Schema 示例

**execution_log.json:**

```json
{
  "project_id": "production",
  "started_at": "2026-06-05T03:14:47.772293+00:00",
  "completed_at": "2026-06-05T03:14:48.025006+00:00",
  "exit_code": 0,
  "steps": [
    {"seq": 1, "action": "can_execute", "result": "allow"},
    {"seq": 2, "action": "solve_formulation", "result": "solved"},
    {"seq": 3, "action": "delivery_gatekeeper", "result": "passed"}
  ]
}
```

**delivery_decision.json:**

```json
{
  "project_id": "production",
  "species": "white_shrimp",
  "stage": "adult",
  "deliverable": true,
  "checks": {
    "closure": "pass", "nutrition": "pass", "category": "pass",
    "cost_range": "pass", "compliance": "skip",
    "rule_approved": "skip", "counterexample": "skip"
  },
  "failures": [],
  "warnings": [
    "当前 LP 解为大宗原料成本最小可行解",
    "氨基酸平衡未建模",
    "未经过养殖试验验证"
  ]
}
```

---

## 8. 已知限制与演进路线

### 8.1 当前限制

| # | 限制 | 影响 | 优先级 |
|---|------|------|--------|
| 1 | **氨基酸平衡未建模** (Lys/Met/Thr) | 配方可能蛋白达标但氨基酸不平衡 | P0 |
| 2 | **Ca/P 比未约束** | 骨骼发育风险 | P1 |
| 3 | **消化率/可消化能未建模** | 实际营养利用率未知 | P1 |
| 4 | **LP 连续解** — 0.1% 步长天然整数但未显式约束 | 实际称量需要整数克 | P2 |
| 5 | **预混料成本按零计** (实际 ¥20-80/kg) | 吨成本低估 | P1 |
| 6 | **self_iteration_engine.pl 的 dict 语法不兼容 scryper-prolog** | 迭代引擎需独立加载，全局 consult 会崩溃 | P2 |
| 7 | **18 物种中仅 5 种有完整品类规则** | 其余 13 种无专用规则 | P1 |
| 8 | **Prolog `format/2` 在 scryper-prolog 0.10 不可用** | 输出格式化受限 | P2 |
| 9 | **LP Simplex 小物种约束冲突时不可行** | 某些物种无法求解 | P0 |

### 8.2 演进路线

```
Phase 1 (当前)  ✅
  ├── Rust CLI 工程闭环 (solve/test/gate)
  ├── Prolog 门禁 + LP 求解
  ├── DOCX 报告输出
  └── 复盘 + 自我迭代

Phase 2 (计划)
  ├── 氨基酸平衡建模 (Lys/Met/Thr)
  ├── Ca/P 比约束
  ├── 消化率数据接入
  ├── 补齐 13 物种品类规则
  └── 修复 self_iteration_engine.pl 兼容性

Phase 3 (远期)
  ├── LLM Agent 需求抽取层集成
  ├── 多目标优化 (成本 vs 营养 vs 可持续)
  ├── 外部 CPLEX/Gurobi 求解器切换
  └── Web UI / API 服务化
```

---

## 附录 A: 技术术语表

| 术语 | 说明 |
|------|------|
| **SOP** | Standard Operating Procedure，标准操作流程 |
| **LP** | Linear Programming，线性规划 |
| **Simplex** | 单纯形法，线性规划的标准求解算法 |
| **MECE** | Mutually Exclusive, Collectively Exhaustive，相互独立、完全穷尽 |
| **scryer-prolog** | Rust 实现的现代 Prolog 解释器，ISO 兼容 |
| **dict (Prolog)** | Prolog 的键值数据结构，类似 JSON object |
| **unification** | Prolog 的核心机制：变量绑定与模式匹配 |
| **fallback** | 品类规则缺失时的降级兜底策略 |
| **can_execute** | SOP 门禁：判定某动作是否允许执行 |
| **deliverable** | 交付门禁：配方是否满足全部质量标准 |

## 附录 B: 快速命令参考

```bash
# 端到端配方求解
cargo run -- solve --species white_shrimp --stage adult

# 反例测试
cargo run -- test

# 门禁验证
cargo run -- gate --project production

# 直接 Prolog 测试
scryer-prolog -g "
    consult('rules/ingredient_db.pl'),
    consult('rules/species_nutrition.pl'),
    consult('rules/category_rules.pl'),
    consult('rules/sop_gatekeeper.pl'),
    consult('rules/formulation_lp_engine.pl'),
    consult('rules/sop_engine.pl'),
    solve_formulation(japanese_eel, adult),
    halt.
"
```

---

*AquaFeedFormulator v2.0 — Rust 执行 + Prolog 门禁 + JSON 结果 + 日志追溯 + 交付判断 + 复盘迭代*
