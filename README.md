# AquaFeedFormulator — 水产养殖饲料配方智能设计系统

基于 **LLM + PrologAgentTeam + RustAgentTeam + ScriptAgentTeam** 四层协作的水产饲料配方 AI。

---

## 🎯 一句话

> 输入「鲤鱼幼鱼饲料，预算 4000 元/吨」→ Prolog 规则回溯 → 秒出 100g 级精准配方 + 成本分析 + 合规报告。

---

## 🏗️ 架构

```
用户 (自然语言)
  │
  ▼
LLM ──→ 需求解析 ──→ 结构化查询 {species, stage, budget}
  │
  ▼
🧠 PrologAgentTeam (决策核心 — 5 Agent)
  ├── aqua-nutrition-expert    → 18 品种 × N 阶段营养需求
  ├── ingredient-db-manager    → 30+ 原料营养成分 + 价格
  ├── formulation-engine       → 约束回溯求解器
  ├── compliance-validator     → GB 13078 法规校验
  └── recipe-planner           → 总调度 + 多方案对比
  │
  ├─→ 🔧 RustAgentTeam   → Tauri 桌面应用 (配方管理、可视化、导出)
  └─→ 🔗 ScriptAgentTeam → 原料行情爬虫 + 批量配方生成
```

---

## 📦 项目结构

```
AquaFeedFormulator/
├── README.md
├── specs/
│   └── PRD.md                      # 产品需求文档
├── rules/                          # Prolog 规则库 (5 模块)
│   ├── species_nutrition.pl        # 18品种营养需求 (200行)
│   ├── ingredient_db.pl            # 30+原料数据库 (200行)
│   ├── formulation_solver.pl       # 约束求解引擎 (400行)
│   ├── compliance_checker.pl       # 合规校验 (250行)
│   └── cost_optimizer.pl           # 成本优化 + 替换建议 (250行)
├── agents/                         # Agent 定义 (7 个)
│   ├── aqua-nutrition-expert.md   # PrologAgentTeam
│   ├── ingredient-db-manager.md   # PrologAgentTeam
│   ├── formulation-engine.md      # PrologAgentTeam
│   ├── compliance-validator.md    # PrologAgentTeam
│   ├── recipe-planner.md          # PrologAgentTeam (总调度)
│   ├── price-crawler.md           # ScriptAgentTeam
│   └── batch-recipe-generator.md  # ScriptAgentTeam
└── skills/
    └── aqua-feed-formulation.md   # 领域 Skill 定义
```

---

## ⚙️ 技术栈

| 层 | 技术 | 负责方 |
|---|------|--------|
| 推理引擎 | scryer-prolog (Rust native) | PrologAgentTeam |
| 自然语言 | 火山方舟 deepseek-v4-pro | LLM |
| 桌面应用 | Tauri v2 + React + SQLite | RustAgentTeam |
| 数据管道 | Python + Scrapy + Playwright | ScriptAgentTeam |

---

## 🚀 快速开始

### Prolog 规则独立运行

```bash
# 安装 scryer-prolog
cargo install scryer-prolog

# 加载规则
scryer-prolog rules/species_nutrition.pl \
               rules/ingredient_db.pl \
               rules/formulation_solver.pl
```

### Prolog 查询示例

```prolog
% 查询鲤鱼幼鱼营养需求
?- species_nutrition(common_carp, juvenile, P, F, Fi, A).
   P = 34, F = 7, Fi = 6, A = 10.

% 求解配方 (启发式快速模式)
?- solve_recipe_heuristic(common_carp, juvenile, 4000, Recipe).
   Recipe = recipe(common_carp, juvenile, [...], 3720.5, 34.2, 7.1, 5.8, 9.5).

% 查询鱼粉替代品
?- suggest_substitute(fish_meal_peru_65, Alternatives).
   Alternatives = [alt(fish_meal_domestic_60, ..., 1.0, -3.0, ...),
                   alt(poultry_meal, ..., 0.5, -5.5, ...), ...].

% 多方案对比
?- multi_scenario_solve(common_carp, juvenile, 4000, Scenarios).
   Scenarios = scenarios(最低成本方案, 最佳营养方案, 平衡方案).
```

---

## 🧠 Prolog 为什么是核心

饲料配方本质是 **约束满足问题**，Prolog 的回溯机制是天然求解器：

```prolog
% 规则: 鲤鱼幼鱼需要 34% 蛋白
species_nutrition(common_carp, juvenile, 34, 7, 6, 10).

% 事实: 秘鲁鱼粉含 65% 蛋白
ingredient(fish_meal_peru_65, ..., 65, ...).

% 约束: Σ(原料% × 原料蛋白%) ≥ 34%
% Prolog 回溯自动搜索满足条件的所有组合 → 选成本最低的
```

vs. Excel Solver: Prolog 的规则可读、可维护、可版本化。vs. Python 脚本: 声明式 > 命令式，规则即文档。

---

## 📊 覆盖范围

| 维度 | 当前 | 规划 |
|------|------|------|
| 养殖品种 | 18 种 | 30+ |
| 生长阶段 | 每品种 3-4 个 | 细化到 5-6 个 |
| 原料 | 30+ 种 | 50+ |
| 营养指标 | 蛋白/脂肪/纤维/灰分 | + 氨基酸/脂肪酸/Ca/P |
| 法规标准 | GB 13078-2017 | + NY 5072, SC/T 标准 |

---

## 🔗 三团队协作

| | PrologAgentTeam | RustAgentTeam | ScriptAgentTeam |
|---|---|---|---|
| 角色 | 🧠 推理决策 | 🔧 桌面应用 | 🔗 数据管道 |
| Agent 数 | 5 | 3 (UI/DB/Report) | 2 (爬虫/批量) |
| 核心产出 | Prolog 规则 + 求解 | Tauri App | Python 脚本 |

---

## 📄 参考资料

- 水产动物饲料配方与配制技术 (张家国主编)
- 水产动物营养与饲料配方 (侯永清主编)
- 水产饲料调制加工与配方集萃 (薛敏著)
- NRC Nutrient Requirements of Fish and Shrimp (2011)
- 中国饲料成分及营养价值表 (2024 第35版)
