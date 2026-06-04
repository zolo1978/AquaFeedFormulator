# formulation-engine — 配方求解引擎 Agent

## 元信息
- **团队**: PrologAgentTeam
- **类型**: Solver Agent
- **版本**: v1.0
- **规则文件**: `rules/formulation_solver.pl`

## 定位
整个 AquaFeedFormulator 的核心计算引擎。将饲料配方问题建模为约束满足问题(CSP)，利用 Prolog 回溯搜索 + 成本优化找到最优原料配比。

## 核心能力

### 1. 精确求解 (全量回溯)
`solve_recipe(Species, Stage, Budget, Recipe)`

对所有主料以 0.5% 步长进行全量回溯搜索，找到所有满足约束的可行解，取成本最低者。
- 搜索空间: ~30 种原料 × (0% ~ Max%) / 0.5% 步长
- 约束: 营养达标 + 用量范围 + 预算 + 总和=100%
- 适用: 离线批量计算

### 2. 启发式求解 (快速模式)
`solve_recipe_heuristic(Species, Stage, Budget, Recipe)`

只对 14 种核心原料以 1% 步长搜索，固定添加剂和油脂用量。
- 求解时间 < 1 秒
- 适用: 交互式配方设计、即时预览

### 3. 多目标优化
同时考虑 3 个目标:
- 成本最小化 (主目标)
- 营养达标 (硬约束)
- 原料多样性 (软约束, 降低单一原料依赖)

### 4. 约束类型
- **营养约束**: 蛋白≥目标, 脂肪≥目标, 纤维≤上限, 灰分≤上限
- **用量约束**: 每原料 [Min%, Max%]
- **总和约束**: Σ百分比 = 100%
- **预算约束**: 总成本 ≤ 预算
- **安全约束**: 合规校验通过

## 求解流程
```
1. 加载营养目标 (species_nutrition)
2. 收集候选原料 (base_ingredient)
3. 固定添加剂用量
4. 计算主料可分配空间
5. 回溯搜索配比组合
6. 逐组校验约束
7. 成本排序取最优
8. 构建输出 Recipe
```

## 输出格式
```prolog
recipe(Species, Stage,
  [item(Id, Name, Percent, CostContrib), ...],
  TotalCost,
  CalcProtein, CalcFat, CalcFiber, CalcAsh)
```

## 依赖
- `rules/species_nutrition.pl` (营养目标)
- `rules/ingredient_db.pl` (原料数据)
- `rules/compliance_checker.pl` (合规校验)
- scryer-prolog 引擎
