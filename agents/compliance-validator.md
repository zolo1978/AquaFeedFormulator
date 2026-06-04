# compliance-validator — 合规校验 Agent

## 元信息
- **团队**: PrologAgentTeam
- **类型**: Validator Agent
- **版本**: v1.0
- **规则文件**: `rules/compliance_checker.pl`

## 定位
配方安全与法规合规的最后一道防线。在配方生成后自动校验是否符合国家饲料卫生标准、原料目录、添加剂规范。

## 核心能力

### 1. 禁用物质检查
自动排查配方中是否含有禁用成分:
- 抗生素生长促进剂 (2020年全面禁止)
- 反刍动物源性肉骨粉
- 三聚氰胺、苏丹红等工业添加剂
- 瘦肉精类 β-激动剂

### 2. 卫生标准校验
参照 GB 13078-2017:
- 重金属限量 (As≤2, Pb≤5, Cd≤0.5, Hg≤0.1 mg/kg)
- 真菌毒素限量 (黄曲霉毒素B1≤10μg/kg 等)
- 氰化物、亚硝酸盐、游离棉酚、异硫氰酸酯

### 3. 原料目录合规
参照农业农村部公告第1773号:
- 所有原料必须在批准目录中
- 未列入目录的标注警告

### 4. 添加剂用量合规
参照农业部公告第2625号:
- 抗氧化剂: 乙氧基喹啉 ≤150mg/kg
- 总磷: ≤12g/kg (水产排放标准 SC/T 9101)
- 防霉剂用量限制

### 5. 配方质量评估
`evaluate_recipe_quality(Recipe, Score, Remarks)`
- 动物蛋白占比 (水产需要高动物蛋白消化率)
- 鱼粉占比 (优质但贵, 需平衡)
- 原料多样性 (降低单一原料依赖风险)
- 成本效率 (每% 蛋白的成本)

## 报告格式
```prolog
compliance_report(Status, CriticalViolations, Warnings)
% Status: passed | failed
% Critical: [violation(critical, Item, Reason), ...]
% Warnings: [violation(warning, Item, Advice), ...]
```

## 校验触发时机
- 配方生成后立即校验 (阻塞式, 不合格不允许输出)
- 用户手动修改配方后重新校验
- 法规更新后批量重新校验历史配方

## 依赖
- `rules/compliance_checker.pl`
- `rules/ingredient_db.pl`
- scryer-prolog 引擎
