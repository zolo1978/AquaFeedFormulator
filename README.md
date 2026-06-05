# AquaFeedFormulator — 水产饲料配方 SOP Agent

基于 **LLM + Prolog + Rust** 三核协作的水产饲料配方研发系统。

---

## 一句话

> `./aqua solve --species japanese_eel --stage adult` → 6 步 SOP 全流程 → DOCX 配方报告。

---

## 快速开始

```bash
# 方式 1: 顶层脚本 (推荐)
./aqua solve --species japanese_eel --stage adult

# 方式 2: Makefile
make solve SPECIES=japanese_eel STAGE=adult

# 方式 3: Prolog 直调 (跳过 Rust)
make prolog-solve SPECIES=japanese_eel

# 批量求解全部 5 种品类物种
make solve-all

# 完整帮助
./aqua help
make help
```

**前置依赖**:
- [scryer-prolog](https://github.com/mthom/scryer-prolog) (`brew install scryer-prolog`)
- Rust toolchain (`rustup`)
- Python 3 + `python-docx` (`pip3 install python-docx`)

---

## 架构

```
用户: ./aqua solve --species japanese_eel --stage adult
        │
   ┌────▼────────────────────────────────────┐
   │  Rust CLI: 状态管理 + JSON 输出          │
   │  ┌──────────────────────────────────┐   │
   │  │ Prolog SOP 主控                    │   │
   │  │  1. can_execute     (门禁检查)     │   │
   │  │  2. solve_formulation (LP求解)    │   │
   │  │  3. deliverable      (交付门禁)    │   │
   │  └──────────────────────────────────┘   │
   └────┬────────────────────────────────────┘
        │
   ┌────▼────────────────────────────────────┐
   │  DOCX 报告  →  ~/Desktop/                │
   │  复盘报告    →  generated/                │
   │  自我迭代    →  generated/                │
   └─────────────────────────────────────────┘
```

| 层 | 职责 | 权限 |
|---|------|------|
| LLM | 需求理解、知识草案、结果解释 | 不可裁决 |
| Prolog | SOP 主控、规则验证、交付门禁 | 决定能不能执行 |
| Rust | 工程执行、状态管理、JSON 输出 | 每步问 Prolog can_execute |
| LP Solver | 约束满足 + 成本最小求解 | Prolog 子模块 |

---

## 命令参考

| 命令 | 说明 |
|------|------|
| `./aqua solve --species <s> --stage <t>` | 端到端求解 |
| `./aqua test` | 反例测试 |
| `./aqua gate --project <p>` | 交付门禁 |
| `./aqua prolog --species <s>` | 纯 Prolog 求解 |
| `./aqua price` | 价格监控 |
| `./aqua report --species <s>` | 生成 DOCX |
| `./aqua build` | 编译 release |
| `make solve-all` | 批量求解 5 种品类物种 |

---

## 项目结构

```
AquaFeedFormulator/
├── aqua                          ← ★ 顶层入口脚本
├── Makefile                      ← ★ 任务快捷方式
├── README.md
├── SOP.md                        ← 操作 SOP
├── rust-core/                    ← Rust CLI
│   ├── Cargo.toml
│   └── src/main.rs               ← 求解流程 + Prolog 调用
├── rules/                        ← Prolog 规则库
│   ├── sop_engine.pl             ★ 总入口
│   ├── sop_workflow.pl           ★ SOP 状态机
│   ├── sop_gatekeeper.pl         ★ 门禁 + fallback 控制
│   ├── formulation_lp_engine.pl  ★ LP 求解核心
│   ├── category_rules.pl         ★ 唯一品类约束源
│   ├── delivery_gatekeeper.pl    ★ 交付门禁 (4 项检查)
│   ├── counterexample_tests.pl   ★ 反例测试库
│   ├── self_iteration_engine.pl  ★ 自我迭代引擎
│   ├── ingredient_db.pl          原料数据库 (35 种)
│   ├── species_nutrition.pl      物种营养需求 (18 种)
│   ├── eel_adult_recipes.pl      鳗鱼成体专家配方
│   ├── shrimp_adult_recipes.pl   对虾成体专家配方
│   ├── formulation_solver_v2.pl  LP 求解器 (独立使用)
│   └── ...
├── scripts/
│   └── price_monitor.py          原料价格监控 (每日自动)
├── generate_report.py            通用 DOCX 报告生成
├── generate_eel_adult_report.py  鳗鱼专用 DOCX 报告
├── docs/
│   ├── TOTAL_SYSTEM_ARCHITECTURE.md
│   ├── INGREDIENT_SURVEY.md      35 种原料全景调研
│   ├── RETROSPECTIVE_REQUIREMENT_CLARIFICATION.md ← 需求澄清复盘
│   └── ...
├── schemas/
│   ├── validation_result.schema.json
│   ├── delivery_decision.schema.json
│   └── execution_log.schema.json
└── generated/                    输出目录 (gitignore)
```

---

## 覆盖范围

| 维度 | 当前 | 已建模物种 |
|------|------|-----------|
| 品类规则 | 5 种 | 日本鳗鲡、南美白对虾、鲤鱼、加州鲈、草鱼 |
| 营养目标 | 18 种 | 全部 |
| 原料 | 35 种 | 鱼粉类/植物蛋白/谷物/油脂/添加剂 |
| 营养指标 | 蛋白/脂肪/纤维/灰分 | — |
| LP 求解器 | Simplex 整数缩放 | 5 种品类物种可用 |

---

## 已知限制

1. 氨基酸平衡未建模（赖氨酸/蛋氨酸/苏氨酸）
2. Ca/P 比未约束
3. 消化率/可消化能未建模
4. 抗营养因子未建模
5. 预混料成本按零计
6. 18 物种中仅 5 种有完整品类规则

---

## 需求澄清复盘

项目启动时跳过了需求发现阶段，直接进入开发。详见 [docs/RETROSPECTIVE_REQUIREMENT_CLARIFICATION.md](docs/RETROSPECTIVE_REQUIREMENT_CLARIFICATION.md)。
