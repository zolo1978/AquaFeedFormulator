# ingredient-db-manager — 原料数据库管理 Agent

## 元信息
- **团队**: PrologAgentTeam
- **类型**: Data Manager Agent
- **版本**: v1.0
- **规则文件**: `rules/ingredient_db.pl`

## 定位
水产饲料原料的权威数据管理。维护 30+ 种常用原料的营养成分、价格、用量限制和安全约束，为配方求解器提供数据基础。

## 核心能力

### 1. 原料查询
按 ID / 分类 / 关键词查询原料数据。
```
输入: fish_meal_peru_65
输出: {name: '秘鲁鱼粉(65%)', protein: 65%, fat: 10%, price: 12.5, max: 50%, min: 5%}
```

### 2. 原料分类管理
按 6 大类管理原料:
- animal_protein: 动物蛋白源 (鱼粉、血粉、肉骨粉)
- plant_protein: 植物蛋白源 (豆粕、菜粕、棉粕)
- energy: 能量原料 (玉米、小麦、米糠)
- oil: 油脂类 (鱼油、豆油、磷脂)
- mineral: 矿物质 (磷酸氢钙、石粉、盐)
- additive: 添加剂 (预混料、胆碱、酶制剂)

### 3. 价格更新
支持原料市场价格的批量更新。
- 更新接口: `update_price(+IngredientId, +NewPrice)`
- 记录价格变动历史
- 触发价格预警 (涨幅超 20%)

### 4. 新原料添加
按标准格式添加新原料:
- 必须提供: 名称、分类、蛋白/脂肪/纤维/灰分、价格、用量上下限
- 可选: 钙、磷、氨基酸组成、脂肪酸组成
- 标注数据来源和日期

## 数据规范
- 营养成分: g/100g 干物质
- 价格: 元/kg
- 用量: 占配方百分比
- 水分: % (用于折干计算)

## 查询接口
```prolog
ingredient(+Id, -Name, -Category, -Protein, -Fat, -Fiber, -Ash, -Moisture, -Price, -MaxUsage, -MinUsage)
ingredients_by_category(+Category, -IngredientList)
ingredient_nutrition(+Id, -Protein, -Fat, -Fiber, -Ash)
ingredient_cost(+Id, -Price)
ingredient_usage_limits(+Id, -Max, -Min)
base_ingredient(-Id)
additive_ingredient(-Id)
```

## 依赖
- `rules/ingredient_db.pl`
- scryer-prolog 引擎
