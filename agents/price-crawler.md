# price-crawler — 原料行情爬虫 Agent

## 元信息
- **团队**: ScriptAgentTeam
- **类型**: Data Pipeline Agent
- **版本**: v1.0

## 定位
定时爬取水产饲料原料市场价格，清洗后更新 PrologAgentTeam 的 `ingredient_db.pl`，确保配方求解基于最新价格。

## 数据源
| 来源 | 覆盖 | 频率 |
|------|------|------|
| 中国饲料行业信息网 (feedtrade.com.cn) | 豆粕、菜粕、棉粕、鱼粉 | 每日 |
| 博亚和讯 (boyar.cn) | 玉米、小麦、DDGS | 每日 |
| 中国汇易 (chinajci.com) | 鱼粉、肉骨粉进口价 | 每周 |
| 农业农村部监测数据 | 综合饲料原料价格指数 | 每周 |

## 技术方案
```python
# 爬虫框架: Scrapy + Playwright (处理 JS 渲染)
# 存储: SQLite (临时) → Prolog fact 生成
# 调度: cron (每日 08:00 执行)
```

## 输出格式
```python
# 生成 Prolog 价格更新文件
def generate_price_update(date, prices):
    facts = []
    for item in prices:
        facts.append(f"ingredient_price({item.id}, {item.price}, '{date}').")
    return "\n".join(facts)
```

## 核心流程
```
1. 定时触发 (cron: 0 8 * * *)
2. 多源并发爬取
3. 数据清洗: 去重、异常值检测 (±30% 预警)
4. 价格比对: 与前一日对比
5. 生成 ingredient_db_price_update.pl
6. 触发 PrologAgentTeam 规则重载
7. 异常价格推送通知
```

## 异常处理
- 价格变动 > 20%: 标记预警 + 通知用户
- 数据源失效: 自动切换备用源
- 连续 3 天空数据: 标记数据源不可用

## 依赖
- Python 3.12+
- Scrapy, Playwright, pandas
- SQLite
- PrologAgentTeam API (规则更新接口)
