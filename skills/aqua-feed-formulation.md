# aqua-feed-formulation — 水产饲料配方领域 Skill

## 元信息
- **Skill ID**: aqua-feed-formulation
- **版本**: v1.0
- **领域**: 水产养殖营养与饲料科学
- **引擎**: PrologAgentTeam (scryer-prolog)

## 描述
水产饲料配方设计的完整领域知识 + 求解能力。涵盖 18 个养殖品种的营养需求、30+ 种原料的组成数据、约束求解算法、合规校验逻辑。

## 核心概念

### 饲料配方五要素
1. **营养需求** (Nutritional Requirement): 目标物种在特定阶段的蛋白/脂肪/纤维/灰分/氨基酸需求
2. **原料选择** (Ingredient Selection): 从原料库中选择合适的蛋白源/能量源/添加剂
3. **约束满足** (Constraint Satisfaction): 配比需满足营养达标 + 用量范围 + 总合为 100%
4. **成本优化** (Cost Optimization): 在所有可行解中找最低成本配方
5. **合规校验** (Compliance): 符合国家饲料卫生标准 (GB 13078-2017) 等法规

### Prolog 核心谓词
```prolog
% 营养需求
species_nutrition(Species, Stage, Protein, Fat, Fiber, Ash)

% 原料数据
ingredient(Id, Name, Category, Protein, Fat, Fiber, Ash, Moisture, Price, Max, Min)

% 配方求解
solve_recipe(Species, Stage, Budget, Recipe)
solve_recipe_heuristic(Species, Stage, Budget, Recipe)

% 合规校验
check_compliance(Recipe, Report)

% 替代建议
suggest_substitute(MissingIngredient, Alternatives)

% 质量评分
evaluate_recipe_quality(Recipe, Score, Remarks)
```

## 使用方式

### 1. 加载规则集
```prolog
?- consult('rules/species_nutrition.pl').
?- consult('rules/ingredient_db.pl').
?- consult('rules/formulation_solver.pl').
?- consult('rules/compliance_checker.pl').
?- consult('rules/cost_optimizer.pl').
```

### 2. 求解配方
```prolog
?- solve_recipe_heuristic(common_carp, juvenile, 4000, Recipe).
Recipe = recipe(common_carp, juvenile, [item(...), ...], 3720.5, 34.2, 7.1, 5.8, 9.5).
```

### 3. 多方案对比
```prolog
?- multi_scenario_solve(common_carp, juvenile, 4000, Scenarios).
Scenarios = scenarios(RecipeEcon, RecipePrem, RecipeBal).
```

## 规则文件
| 文件 | 行数 | 职责 |
|------|------|------|
| `species_nutrition.pl` | ~200 | 18品种 × N阶段营养需求 |
| `ingredient_db.pl` | ~200 | 30+ 原料营养成分+价格 |
| `formulation_solver.pl` | ~400 | 约束求解器 (回溯+启发式) |
| `compliance_checker.pl` | ~250 | GB 13078 合规校验 |
| `cost_optimizer.pl` | ~250 | 替换建议 + 灵敏度 + 季节 |

## 支持的养殖品种 (18)
鲤鱼、草鱼、鲫鱼、青鱼、武昌鱼、斑点叉尾鮰、南方大口鲶、罗非鱼、虹鳟、大西洋鲑、南美白对虾、斑节对虾、罗氏沼虾、中华绒螯蟹、日本鳗、黄颡鱼、加州鲈、乌鳢
