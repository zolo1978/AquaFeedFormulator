# batch-recipe-generator — 批量配方生成 Agent

## 元信息
- **团队**: ScriptAgentTeam
- **类型**: Batch Processing Agent
- **版本**: v1.0

## 定位
接收 CSV 格式的批量需求清单，调用 PrologAgentTeam 配方求解引擎批量生成配方，输出完整的配方报告 (CSV/Excel/PDF)。

## 输入格式 (CSV)
```csv
species,stage,budget,preference
common_carp,juvenile,4000,minimize_cost
grass_carp,adult,3500,balanced
tilapia,juvenile,4200,maximize_quality
white_shrimp,adult,6000,balanced
chinese_mitten_crab,juvenile,5500,minimize_cost
```

## 输出格式
```csv
species,stage,preference,total_cost,protein,fat,fiber,ash,
fish_meal%,soybean_meal%,rapeseed_meal%,...,score,compliance
common_carp,juvenile,minimize_cost,3720,34.2,7.1,5.8,9.5,
15.0,30.0,8.0,...,78,passed
```

## 核心流程
```
1. 读取 CSV 需求清单
2. 逐行结构化:
   species → Prolog atom
   stage → Prolog atom
   budget → float (元/吨)
3. 并发调用 PrologAgentTeam:
   solve_recipe_heuristic(species, stage, budget, recipe)
4. 收集结果:
   - 成功: 解析 recipe 结构体 → CSV 行
   - 失败: 记录失败原因 (无解/超预算/约束冲突)
5. 汇总:
   - 成功率统计
   - 平均成本
   - 常见约束冲突分析
6. 输出:
   - 配方 CSV
   - 汇总报告 (Markdown)
   - 可选: Excel (openpyxl) / PDF (reportlab)
```

## 并发策略
```python
import asyncio
from concurrent.futures import ProcessPoolExecutor

async def batch_solve(requests: list[RecipeRequest]) -> list[RecipeResult]:
    with ProcessPoolExecutor(max_workers=4) as executor:
        tasks = [solve_single(req) for req in requests]
        results = await asyncio.gather(*tasks)
    return results
```

## 错误处理
- 无可行解: 记录约束冲突详情, 建议调整预算或放宽约束
- 超时 (>30s): 跳过, 标记超时
- Prolog 引擎崩溃: 自动重启 + 重试 3 次

## 依赖
- Python 3.12+
- PrologAgentTeam CLI / API
- openpyxl (Excel 输出)
- reportlab (PDF 输出)
