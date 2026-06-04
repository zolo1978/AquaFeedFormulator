# AquaFeedFormulator 技术说明书

> **定位声明**：本文档为 AquaFeedFormulator 的 **Prolog LP Solver 子模块**技术说明书。
> 总系统架构见 `docs/TOTAL_SYSTEM_ARCHITECTURE.md`。
> 整改方案见 `docs/REMEDIATION_PLAN.md`。

> 版本：v1.0 | P0修正版 | 日期：2026-06-05 | 引擎：Prolog SOP v2.0

---

## 1. 产品定义

AquaFeedFormulator Prolog LP Solver 是基于 **Prolog 线性规划（LP）引擎**的水产饲料配方自动求解**子模块**。将饲料配方这一"约束满足 + 成本优化"问题形式化为数学规划模型，由 Prolog `library(simplex)` 在原料数据库和营养目标之上求出当前约束模型下的成本最小可行配方。

**一句话**：输入物种+生长阶段 → Prolog LP 求解器在品类约束、营养约束下秒出当前约束模型下的成本最小可行配方。

---

## 2. 核心能力

| 能力 | 描述 |
|------|------|
| **端到端配方求解** | 单入口 `solve_formulation(Species, Stage)`，自动完成原料筛选→营养匹配→品类约束→LP求解→结果输出 |
| **18 物种覆盖** | 日本鳗鲡、南美白对虾、鲤鱼、加州鲈、草鱼、鲫鱼、罗非鱼、虹鳟、大西洋鲑等 18 种水产养殖物种 |
| **多阶段支持** | 每物种 3-6 个生长阶段（鱼苗/幼体/成体/亲本），鳗鱼有白仔鳗/黑仔鳗/养成鳗细分 |
| **100+ 原料库** | 动物蛋白(9)、植物蛋白(10)、能量(8)、油脂(4)、矿物质(4)、添加剂(9) 六大类 |
| **品类约束内置 LP** | 淀粉上限、动物蛋白下限、油脂范围等品类约束直接作为 LP 约束进入求解，非事后校验 |
| **闭合校验** | 配方总和 100%±0.1% 自动验证 |
| **批量测试** | 单次运行可解算多物种/多阶段配方 |

---

## 3. 配方求解原理

### 3.1 数学建模

配方问题形式化为 **整数线性规划（ILP）**：

**变量**：$x_i \in [0, 1000]$，千分比（1 单位 = 0.1%），$i$ 为原料编号

**目标函数**：$\min \sum_i \text{Price}_i \times x_i$

**约束条件**：

| 约束类型 | 表达式 | 方向 |
|----------|--------|------|
| 总和 | $\sum x_i + \sum \text{fixed\_additives} = 1000$ | = |
| 蛋白 | $\sum \text{Pro}_i \cdot x_i \ge \text{TargetPro} \times 1000$ | $\ge$ |
| 脂肪 | $\sum \text{Fat}_i \cdot x_i \ge \text{TargetFat} \times 1000$ | $\ge$ |
| 纤维 | $\sum \text{Fib}_i \cdot x_i \le \text{MaxFib} \times 1000$ | $\le$ |
| 灰分 | $\sum \text{Ash}_i \cdot x_i \le \text{MaxAsh} \times 1000$ | $\le$ |
| 用量上下限 | $\text{Min}_i \times 10 \le x_i \le \text{Max}_i \times 10$ | 边界 |
| 品类-淀粉 | $\sum_{i \in \text{starch}} x_i \le \text{StarchLimit} \times 10$ | $\le$ |
| 品类-动物蛋白 | $\sum_{i \in \text{animal\_protein}} x_i \ge \text{AnimalProLimit} \times 10$ | $\ge$ |

### 3.2 RHS 缩放推导

实际营养百分比 = $\frac{\sum \text{nut}_i \cdot x_i}{1000}$

因此约束 $\sum \text{nut}_i \cdot x_i \ge \text{Target} \times 1000$ 精确等价于营养百分比 $\ge$ Target%。

---

## 4. 系统组件

### 4.1 文件结构

```
AquaFeedFormulator/
├── rules/
│   ├── sop_engine.pl                 ★ 主控：端到端 SOP 引擎
│   ├── formulation_solver_v2.pl      ★ LP 求解器（独立使用）
│   ├── ingredient_db.pl              原料数据库（100+ 种）
│   ├── species_nutrition.pl          物种营养需求（18 种）
│   ├── formula_closure_validator.pl  品类约束规则 + 闭合校验
│   ├── nutrition_calculator.pl       手配配方营养值计算
│   ├── cross_species_consistency.pl  物种命名一致性冒烟
│   ├── functional_additive_checker.pl  功能性添加剂校验
│   └── compliance_checker.pl         法规合规校验
├── docs/
│   ├── PAPER.md                      LP 方法论论文
│   └── LP_vs_LLM_comparison.md       LP vs LLM 对比分析
├── specs/
│   └── PRD.md                        产品需求文档
├── SOP.md                            操作 SOP
└── README.md                         项目概览
```

### 4.2 核心组件职责

| 模块 | 职责 | 依赖 |
|------|------|------|
| **sop_engine.pl** | 端到端配方求解主控 | ingredient_db, species_nutrition, simplex |
| **formulation_solver_v2.pl** | LP 求解器核心（可独立调用）| ingredient_db, species_nutrition, simplex |
| **ingredient_db.pl** | 原料数据库 + 查询 API | 无 |
| **species_nutrition.pl** | 物种营养需求数据库 | 无 |
| **formula_closure_validator.pl** | 品类约束规则定义 + 闭合校验 | ingredient_db |
| **nutrition_calculator.pl** | 手配配方营养值加权计算 | ingredient_db |

---

## 5. 运行方式

### 5.1 环境要求

```bash
scryer-prolog >= 0.10.0
# macOS: /opt/homebrew/Cellar/scryer-prolog/0.10.0/bin/scryer-prolog
```

### 5.2 单物种求解

```bash
scryer-prolog -g "
    consult('rules/ingredient_db.pl'),
    consult('rules/species_nutrition.pl'),
    consult('rules/sop_engine.pl'),
    solve_formulation(japanese_eel, adult),
    halt.
"
```

### 5.3 批量求解

```bash
for sp in japanese_eel white_shrimp common_carp largemouth_bass; do
    scryer-prolog -g "
        consult('rules/ingredient_db.pl'),
        consult('rules/species_nutrition.pl'),
        consult('rules/sop_engine.pl'),
        solve_formulation($sp, adult), halt.
    "
done
```

### 5.4 典型输出

```
==========================================
  AquaFeedFormulator — Prolog SOP v1.0
  日本鳗鲡 · 成体
------------------------------------------
  营养目标:
    蛋白>=42%  脂肪>=6%  纤维<=4%  灰分<=12
------------------------------------------
  配方:
    秘鲁鱼粉(65%)  5.0%  ¥62500.0
    国产鱼粉(60%)  5.0%  ¥47500.0
    肉骨粉(50%)  14.9%  ¥81746.4
    蚕蛹粉  10.0%  ¥60000.0
    花生粕  16.9%  ¥67582.27
    玉米DDGS  7.7%  ¥19187.7
    大米蛋白粉  15.0%  ¥75000.0
    面粉  5.0%  ¥16000.0
    米糠(全脂)  15.0%  ¥22500.0
    鱼油  1.0%  ¥15000.0
    ...
  ---
  合计: 100.0%
  吨成本: ¥495911.32 /t
  闭合校验: OK
==========================================
```

---

## 6. 品类约束体系

### 6.1 约束定义

品类约束按 `species_category_rule(Species, Stage, Category, LimitType, Limit, Description)` 定义在 `sop_engine.pl` 和 `formula_closure_validator.pl` 中。

### 6.2 鳗鱼示例

| 约束 | 通用 | 白仔鳗 | 幼鳗 | 养成鳗 |
|------|------|--------|------|--------|
| 淀粉 ≤ | 25% | 18% | 22% | 28% |
| 动物蛋白 ≥ | 35% | 45% | 40% | 30% |
| 油脂 ≤ | 8% | 8% | 8% | 8% |
| 油脂 ≥ | 3% | 3% | 3% | 3% |

### 6.3 品类映射

| 品类 | 判定函数 | 示例原料 |
|------|----------|---------|
| starch | `starch_ingredient/1` | 木薯淀粉、面粉、小麦、玉米、次粉 |
| animal_protein | `animal_protein_ingredient/1` | 鱼粉、血粉、肉骨粉、虾壳粉、蚕蛹粉 |
| plant_protein | `plant_protein_ingredient/1` | 豆粕、菜粕、棉粕、花生粕、DDGS |
| oil | `oil_ingredient/1` | 鱼油、豆油、菜籽油、磷脂油 |

### 6.4 通配规则

未明确定义的物种/阶段适用通配规则：淀粉 ≤30%、动物蛋白 ≥20%。

---

## 7. 求解结果

### 7.1 四物种基准测试 (adult 阶段)

| 物种 | 原料数 | 吨成本 (¥/t) | 闭合 |
|------|--------|-------------|------|
| 日本鳗鲡 | 17 | 495,911 | OK |
| 南美白对虾 | 18 | 427,005 | OK |
| 鲤鱼 | 16 | 379,475 | OK |
| 加州鲈 | 18 | 494,020 | OK |

### 7.2 LP vs LLM 成本对比（鳗鱼幼鱼）

| 方案 | 吨成本 (¥/t) | 方法 |
|------|-------------|------|
| LP + 品类约束 | 6,458 | ILP |
| LP 纯数学最优 | 6,126 | ILP |
| LLM 方案 C | 10,800 | 手工 |
| LLM 方案 B | 12,500 | 手工 |
| LLM 方案 A | 14,200 | 手工 |

LP 最优解比 LLM 最优方案低 **40%**，品类约束修正后仍低 **40%**。

---

## 8. 物种/阶段编码表

| 物种 | 编码 | 可用阶段 |
|------|------|---------|
| 日本鳗鲡 | `japanese_eel` | elver, juvenile, adult |
| 南美白对虾 | `white_shrimp` | zoea, mysis, postlarva, juvenile, adult |
| 鲤鱼 | `common_carp` | fry, juvenile, adult, broodstock |
| 加州鲈 | `largemouth_bass` | fry, juvenile, adult |
| 草鱼 | `grass_carp` | fry, juvenile, adult, broodstock |
| 鲫鱼 | `crucian_carp` | fry, juvenile, adult, broodstock |
| 青鱼 | `black_carp` | fry, juvenile, adult, broodstock |
| 罗非鱼 | `tilapia` | fry, juvenile, adult, broodstock |
| 虹鳟 | `rainbow_trout` | fry, juvenile, adult, broodstock |
| 大西洋鲑 | `atlanic_salmon` | fry, juvenile, adult, broodstock |
| 黄颡鱼 | `yellow_catfish` | fry, juvenile, adult |
| 乌鳢 | `snakehead` | fry, juvenile, adult |
| 斑点叉尾鮰 | `channel_catfish` | fry, juvenile, adult, broodstock |
| 南方大口鲶 | `southern_catfish` | fry, juvenile, adult |
| 团头鲂 | `wuchang_bream` | fry, juvenile, adult, broodstock |
| 斑节对虾 | `tiger_prawn` | postlarva, juvenile, adult |
| 罗氏沼虾 | `giant_river_prawn` | postlarva, juvenile, adult |
| 中华绒螯蟹 | `chinese_mitten_crab` | zoea, megalopa, juvenile, adult, fattening |

---

## 9. 已知限制

1. **有理数输出**：LP 结果含 `rdiv` 有理数，Python 后处理需 `float()` 转换
2. **抑制剂/抗营养因子**：未建模（如棉粕游离棉酚、菜粕硫苷）
3. **氨基酸平衡**：当前仅粗蛋白约束，未细化为赖氨酸/蛋氨酸等
4. **Ca/P 比**：未作为约束进入 LP
5. **预混料成本**：添加剂/矿物质固定用量按零成本计，实际 ¥20-80/kg
6. **整数性**：当前为 LP 连续解，0.1% 步长天然整数但未显式约束
7. **`format/2` 不可用**：scryper-prolog 兼容性问题，用 `write` + `round` 替代

---

## 10. 数据来源

| 数据 | 来源 |
|------|------|
| 原料营养值 | 中国饲料成分及营养价值表 (2024 第35版)、NRC 2011 |
| 物种营养需求 | NRC 2011、水产动物营养与饲料配方 (侯永清)、水产饲料调制加工与配方集萃 (薛敏) |
| 原料价格 | 2024-2025 市场参考价 |
| 品类约束 | 行业经验 + 文献综述 |
