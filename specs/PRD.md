# AquaFeedFormulator — 水产养殖饲料配方智能设计系统

## 产品需求文档 (PRD) v1.0

---

## 1. 产品概述

### 1.1 产品定位
基于 **Prolog 规则推理引擎** 的水产饲料配方智能设计工具。将饲料配方这个「约束满足问题」用声明式规则描述，由 Prolog 回溯引擎自动求解最优原料配比。

### 1.2 核心价值主张
> 传统方式：配方师凭经验 + Excel 线性规划，一个配方要半天。
> AquaFeedFormulator：输入「什么鱼、什么阶段、预算多少」→ Prolog 规则推理 → 秒出配方 + 成本分析 + 营养对比。

### 1.3 为什么 Prolog 是核心
饲料配方本质是 **约束满足 + 多目标优化**：
- 「草鱼幼鱼需要 32% 粗蛋白」→ 这是规则
- 「鱼粉蛋白含量 65%，但单价 12.5 元/kg，最高占比 40%」→ 这是约束
- 「在满足所有约束下，最小化成本」→ 这是目标

Prolog 的声明式规则 + 回溯机制天然匹配这个领域。比 Excel Solver 更可解释、比 Python 脚本更易维护。

---

## 2. 用户画像

| 角色 | 特征 | 核心需求 |
|------|------|----------|
| 配方师 | 懂营养但不懂编程 | 用自然语言描述需求，秒出配方 |
| 饲料厂老板 | 关注成本 | 输入预算和原料库存，求最优解 |
| 养殖户 | 关注生长效果 | 输入养殖品种和阶段，出推荐配方 |
| 研究人员 | 需要对比分析 | 多配方并行对比，营养分析报告 |

---

## 3. 系统架构

```
┌─────────────────────────────────────────────────────────┐
│                    用户界面层                              │
│  LLM 自然语言接口  │  Tauri 桌面应用 (RustAgentTeam)        │
├─────────────────────────────────────────────────────────┤
│               🧠 推理决策层 — PrologAgentTeam                │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Prolog 规则引擎 (scryer-prolog)                  │   │
│  │  ├── 物种营养需求规则库 (species_nutrition.pl)     │   │
│  │  ├── 原料成分数据库 (ingredient_db.pl)            │   │
│  │  ├── 配方求解器 (formulation_solver.pl)           │   │
│  │  ├── 成本优化器 (cost_optimizer.pl)               │   │
│  │  └── 合规校验器 (compliance_checker.pl)           │   │
│  └──────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                     数据与服务层                           │
│  SQLite 本地存储  │  原料行情数据管道 (ScriptAgentTeam)     │
├─────────────────────────────────────────────────────────┤
│                    基础设施层                               │
│  CI/CD (ScriptAgentTeam)  │  打包发布  │  自动测试          │
└─────────────────────────────────────────────────────────┘
```

### 3.1 技术选型

| 层 | 技术 | 负责团队 |
|---|------|----------|
| 推理引擎 | scryer-prolog (Rust) + 自定义 Prolog 规则库 | PrologAgentTeam |
| 桌面应用 | Tauri v2 + Rust + React | RustAgentTeam |
| 自然语言 | LLM (火山方舟 deepseek-v4-pro) → Prolog 查询翻译 | LLM |
| 数据管道 | Python 脚本 (原料行情爬取、批量配方生成) | ScriptAgentTeam |
| 本地存储 | SQLite (原料库、配方历史、用户偏好) | RustAgentTeam |
| 构建部署 | Makefile + GitHub Actions + tauri-bundler | ScriptAgentTeam |

---

## 4. 功能需求 (P0/P1/P2)

### P0 — MVP 核心

| ID | 功能 | 描述 | 实现 |
|----|------|------|------|
| F01 | 自然语言配方请求 | 用户输入「鲤鱼成鱼饲料，预算 4000 元/吨」→ LLM 解析 → Prolog 求解 | LLM + PrologAgentTeam |
| F02 | Prolog 规则求解 | 根据物种/阶段加载营养需求规则，在原料库中回溯求解最优配比 | PrologAgentTeam |
| F03 | 配方结果展示 | 原料清单 + 百分比 + 成本明细 + 营养指标对比表 | RustAgentTeam (GUI) |
| F04 | 原料数据库 | 30+ 常见水产饲料原料，含营养成本/价格/用量限制 | SQLite + Prolog |
| F05 | 5 大养殖物种 | 鲤鱼、草鱼、罗非鱼、南美白对虾、中华绒螯蟹（初期覆盖） | Prolog 规则库 |

### P1 — 增强

| ID | 功能 | 描述 | 实现 |
|----|------|------|------|
| F06 | 配方对比 | 并排展示 3 个方案（最低成本 / 最佳营养 / 平衡方案） | RustAgentTeam |
| F07 | 原料替换建议 | 某原料缺货时，Prolog 推断可替代原料及配方调整 | PrologAgentTeam |
| F08 | 合规校验 | 根据 GB/T 饲料卫生标准 + 农业农村部公告自动校验 | PrologAgentTeam |
| F09 | 配方历史管理 | 保存/加载/版本对比配方 | SQLite |
| F10 | 原料行情更新 | 定时拉取原料市场价格，自动更新数据库 | ScriptAgentTeam |

### P2 — 扩展

| ID | 功能 | 描述 | 实现 |
|----|------|------|------|
| F11 | 批量配方生成 | CSV 导入多物种需求，批量出配方 | ScriptAgentTeam |
| F12 | 季节性微调 | 水温/季节变化的营养需求调整规则 | PrologAgentTeam |
| F13 | 配方导出报告 | PDF 专业配方报告（含营养成分表 + 成本分析） | RustAgentTeam |
| F14 | 配方分享 | 导出标准格式（JSON/YAML），可导入其他系统 | RustAgentTeam |
| F15 | 自建原料 | 用户自定义原料，自动计算对配方的影响 | PrologAgentTeam |

---

## 5. Prolog 规则体系设计

### 5.1 物种营养需求 (species_nutrition.pl)

```prolog
% species_nutrition(Species, Stage, Protein%, Fat%, Fiber%, Ash%, ...)
species_nutrition(grass_carp, juvenile, 32, 6, 8, 12).
species_nutrition(grass_carp, adult,   28, 5, 10, 12).
species_nutrition(common_carp, juvenile, 34, 7, 6, 10).
species_nutrition(common_carp, adult,   30, 6, 8, 10).
species_nutrition(tilapia, juvenile,    36, 7, 6, 10).
species_nutrition(tilapia, adult,       30, 5, 8, 10).
species_nutrition(white_shrimp, juvenile, 40, 7, 4, 14).
species_nutrition(white_shrimp, adult,    35, 6, 5, 14).
species_nutrition(chinese_mitten_crab, juvenile, 38, 7, 5, 12).
species_nutrition(chinese_mitten_crab, adult,    32, 6, 6, 12).
```

### 5.2 原料数据库 (ingredient_db.pl)

```prolog
% ingredient(Ingredient, Protein%, Fat%, Fiber%, Ash%, Price/kg, Max%, Min%)
ingredient(fish_meal_peru,       65, 10, 1,  18, 12.5, 40, 5).
ingredient(soybean_meal,         44, 1.5, 7, 6,   4.2, 45, 0).
ingredient(cottonseed_meal,      40, 1,  15, 7,   3.0, 20, 0).
ingredient(rapeseed_meal,        36, 2,  12, 8,   2.8, 25, 0).
ingredient(wheat_bran,           15, 3,  10, 6,   1.5, 20, 0).
ingredient(corn_gluten_meal,     60, 2.5, 2, 3,   5.8, 15, 0).
ingredient(blood_meal,           80, 1,  1,  5,   8.0, 5,  0).
ingredient(bone_meal,            0,  0,  0,  95,  3.5, 8,  0).
ingredient(fish_oil,             0,  99, 0,  0,   15.0, 5, 0).
ingredient(soybean_oil,          0,  99, 0,  0,   10.0, 5, 0).
ingredient(wheat_flour,          12, 1,  2,  1,   2.0, 30, 5).
ingredient(rice_bran,            14, 15, 8,  8,   1.2, 15, 0).
ingredient(corn,                 8,  3.5, 2, 1.5, 2.2, 25, 0).
ingredient(dicalcium_phosphate,  0,  0,  0,  100, 4.0, 3,  1).
ingredient(premix_vitamin,       0,  0,  0,  0,   25.0, 2, 0.5).
ingredient(premix_mineral,       0,  0,  0,  0,   15.0, 2, 0.5).
ingredient(salt,                 0,  0,  0,  0,   0.5, 0.5, 0.2).
ingredient(choline_chloride,     0,  0,  0,  0,   6.0, 0.5, 0.1).
```

### 5.3 约束求解器 (formulation_solver.pl)

```prolog
% 核心求解: 找到满足营养目标的原料组合
% solve_recipe(Species, Stage, BudgetPerTon, Recipe)

% 约束类型:
% 1. 营养达标: sum(ingredient_i% * nutrient_ij) >= target_j
% 2. 用量范围: min_i <= ingredient_i% <= max_i
% 3. 预算约束: sum(ingredient_i% * price_i) * 1000 <= budget_per_ton
% 4. 总和约束: sum(all_ingredients%) == 100

% 求解策略:
% - 先满足蛋白质和脂肪 (主要约束)
% - 再微调填充料达到 100%
% - 最后在满足约束的可行域中选成本最低的
```

### 5.4 合规校验器 (compliance_checker.pl)

```prolog
% 中国饲料卫生标准 GB 13078-2017 校验
% 农业农村部公告第 2625 号 药物饲料添加剂
% 违规 ingredient 自动排除

restricted_ingredient(antibiotics, prohibited).
restricted_ingredient(growth_hormone, prohibited).
heavy_metal_limit(arsenic, 2).     % mg/kg
heavy_metal_limit(lead, 5).
heavy_metal_limit(cadmium, 0.5).
```

---

## 6. Agent 团队分工

| Agent | 所属团队 | 职责 |
|-------|----------|------|
| **aqua-nutrition-expert** (Prolog) | PrologAgentTeam | 营养需求规则定义、物种数据库维护 |
| **ingredient-db-manager** (Prolog) | PrologAgentTeam | 原料成分数据、价格、用量限制 |
| **formulation-engine** (Prolog) | PrologAgentTeam | 核心求解器：约束满足 + 成本优化 |
| **compliance-validator** (Prolog) | PrologAgentTeam | 法规合规校验、质量安全把关 |
| **recipe-planner** (Orchestrator) | PrologAgentTeam | 总编排：接收请求 → 路由子 Agent → 汇总结果 |
| **aqua-ui-architect** | RustAgentTeam | Tauri 桌面应用架构设计 |
| **aqua-ui-coder** | RustAgentTeam | 配方管理、对比、导出 GUI 实现 |
| **aqua-db-coder** | RustAgentTeam | SQLite 本地数据库设计与实现 |
| **price-crawler** | ScriptAgentTeam | 原料行情爬虫 + 数据清洗 |
| **batch-recipe-generator** | ScriptAgentTeam | CSV 批量配方生成脚本 |

---

## 7. 典型用户流程

```
1. 用户打开 AquaFeedFormulator 桌面应用
2. 输入/选择：「鲤鱼 | 幼鱼阶段 | 预算 4000 元/吨」
3. LLM 将自然语言翻译为 Prolog 查询:
   ?- species_nutrition(common_carp, juvenile, P, F, Fi, A)
   ?- solve_recipe(common_carp, juvenile, 4000, Recipe)
4. PrologAgentTeam:
   a. 加载营养需求规则
   b. 加载原料数据库
   c. 约束求解器回溯搜索可行解
   d. 成本优化器在可行域中选最优
   e. 合规校验器检查配方安全性
5. 返回配方结果到 GUI:
   ┌─────────────────────────────────┐
   │ 配方方案: 鲤鱼幼鱼饲料           │
   │ 成本: 3,720 元/吨               │
   │ 粗蛋白: 34.2% ✅ (目标 34%)      │
   │ 粗脂肪: 7.1%  ✅ (目标 7%)       │
   │                                 │
   │ 鱼粉(秘鲁)   15.0%  1,875 元    │
   │ 豆粕         30.0%  1,260 元    │
   │ 棉粕         10.0%    300 元    │
   │ 菜粕          8.0%    224 元    │
   │ 次粉         20.0%    300 元    │
   │ 鱼油          3.0%    450 元    │
   │ 预混料        2.0%    500 元    │
   │ ...                            │
   │ ────────────────────────────── │
   │ 合计        100.0%  3,720 元    │
   └─────────────────────────────────┘
6. 用户可调整约束 → 重新求解 → 对比方案 → 导出/保存
```

---

## 8. 里程碑

| 阶段 | 内容 | 预计产出 |
|------|------|----------|
| M1: 规则引擎 | Prolog 规则库 + 求解器 CLI 可运行 | formulations_solver.pl 可独立求解 |
| M2: GUI MVP | Tauri 桌面应用 + 配方求解联调 | 可用的配方计算器 |
| M3: 增强 | 原料行情爬虫 + 配方对比 + 合规校验 | 完整的 v1.0 |
| M4: 发布 | 打包 macOS/Windows + 文档 + 示例 | 可分发安装包 |

---

## 9. 成功指标

- 配方求解时间 < 2 秒（Prolog 回溯）
- 原料库覆盖 ≥ 30 种水产常用原料
- 物种覆盖 ≥ 5 大养殖品种 × 2 生长阶段
- Prolog 规则可解释：每个配方能追溯到具体规则
- 桌面应用启动 < 3 秒，内存 < 200MB
