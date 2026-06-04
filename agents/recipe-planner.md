# recipe-planner — 配方规划编排 Agent (总调度)

## 元信息
- **团队**: PrologAgentTeam
- **类型**: Orchestrator Agent
- **版本**: v1.0
- **规则文件**: `rules/cost_optimizer.pl`

## 定位
AquaFeedFormulator 的总调度 Agent。接收用户需求 → 协调子 Agent 协作 → 汇总结果返回。是 LLM 与 Prolog 规则引擎之间的桥梁。

## 核心能力

### 1. 需求解析与路由
接收自然语言需求 → 解析为结构化查询 → 路由到子 Agent:
```
用户: "鲤鱼幼鱼饲料, 预算 4000"
  ↓
recipe-planner 解析:
  Species → common_carp
  Stage → juvenile
  Budget → 4000
  ↓
调用: aqua-nutrition-expert (查询营养目标)
     ingredient-db-manager (加载原料库)
     formulation-engine (求解配方)
     compliance-validator (合规校验)
```

### 2. 多方案生成
`multi_scenario_solve(Species, Stage, Budget, Scenarios)`
同时生成 3 个对比方案:
- 最低成本方案 (预算 = 用户预算)
- 最佳营养方案 (预算 +20%, 选更好的原料)
- 平衡方案 (预算 +10%, 折中)

### 3. 原料替换建议
`suggest_substitute(MissingId, Alternatives)`
某原料缺货或涨价时, 自动推荐替代品并按价格排序:
```
输入: fish_meal_peru_65 (缺货)
输出: [鸡肉粉 (替代50%), 国产鱼粉 (100%), 发酵豆粕 (30%)]
```

### 4. 成本灵敏度分析
`price_sensitivity(Recipe, Ingredient, DeltaPercent, ImpactReport)`
分析某原料价格变动对配方总成本的影响:
```
输入: 鱼粉涨价 20%
输出: 总成本从 3720 → 3920 元/吨 (+5.4%)
```

### 5. 季节性方案调整
根据季节自动微调营养目标:
- 夏季: 降低蛋白 (减少代谢热)
- 冬季: 增加脂肪 (提高能量密度)
- 春秋: 强化维生素 (抗应激)

### 6. 采购建议
`get_procurement_advice(AdviceList)`
基于当前原料价格区间给出采购策略:
- 鱼粉低价 → 建议增加库存, 提高配方占比
- 玉米高价 → 建议用小麦替代

## 编排流程
```
User Request (Natural Language)
  │
  ▼
LLM: 自然语言 → 结构化查询
  │  {species, stage, budget, preferences}
  ▼
recipe-planner: 总调度
  │
  ├─→ aqua-nutrition-expert: 查询营养目标
  ├─→ ingredient-db-manager: 加载原料库
  ├─→ formulation-engine: 求解最优配方
  ├─→ compliance-validator: 合规校验
  └─→ cost_optimizer: 生成对比方案 + 分析报告
  │
  ▼
LLM: 结果汇总 → 自然语言回复
```

## 决策规则 (Prolog)
```prolog
% 根据用户偏好选择求解策略
solve_with_preference(Species, Stage, Budget, minimize_cost, Recipe) :-
    solve_recipe_heuristic(Species, Stage, Budget, Recipe).
solve_with_preference(Species, Stage, Budget, maximize_quality, Recipe) :-
    PremiumBudget is Budget * 1.3,
    solve_recipe_heuristic(Species, Stage, PremiumBudget, Recipe).
solve_with_preference(Species, Stage, Budget, balanced, Recipe) :-
    BalancedBudget is Budget * 1.15,
    solve_recipe_heuristic(Species, Stage, BalancedBudget, Recipe).
```

## 依赖
- `rules/cost_optimizer.pl`
- 所有子 Agent (nutrition, ingredient, formulation, compliance)
- LLM (自然语言解析)
- scryer-prolog 引擎
