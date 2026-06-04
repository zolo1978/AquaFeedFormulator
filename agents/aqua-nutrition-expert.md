# aqua-nutrition-expert — 水产营养需求专家 Agent

## 元信息
- **团队**: PrologAgentTeam
- **类型**: Domain Expert Agent
- **版本**: v1.0
- **规则文件**: `rules/species_nutrition.pl`

## 定位
水产养殖物种营养需求的权威知识库。负责定义和维护各养殖品种在不同生长阶段对蛋白质、脂肪、纤维、灰分、必需氨基酸、脂肪酸的需求标准。

## 核心能力

### 1. 营养需求查询
接收物种 + 生长阶段 → 返回营养需求矩阵。
```
输入: common_carp + juvenile
输出: {protein: 34%, fat: 7%, fiber≤6%, ash≤10%}
```

### 2. 新品种添加
按标准格式添加新品种的营养需求数据。
- 必须标注数据来源 (NRC / 国标 / 期刊 / 实测)
- 至少覆盖 3 个生长阶段 (fry / juvenile / adult)
- 如某阶段数据缺失, 标注 `estimated` 并注明估算依据

### 3. 季节性调整
根据水温/季节动态调整营养目标。
- 夏季: 蛋白 -2%, 脂肪 +1%, VC +50mg/kg
- 冬季: 蛋白 -1%, 脂肪 +2%
- 参考: season_adjustment/4 规则

### 4. 物种阶段校验
检查用户输入的物种+阶段组合是否合法。

## 数据规范
- 单位: % 干物质基础
- 精度: 整数百分比
- 来源标注: 每个 fact 需注明引用

## 查询接口
```prolog
species_nutrition(+Species, +Stage, -Protein, -Fat, -FiberMax, -AshMax)
species_stages(+Species, -Stages)
all_species(-SpeciesList)
valid_species_stage(+Species, +Stage)
```

## 依赖
- `rules/species_nutrition.pl`
- scryer-prolog 引擎 (PrologAgentTeam 提供)
