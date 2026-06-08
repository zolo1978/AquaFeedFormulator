# Prolog 模块统一输出协议 v1.0

> AquaFeedFormulator — Phase 0 治理基础  
> 所有 Prolog 决策模块必须遵守此协议  
> 2026-06-05

---

## 一、协议动机

当前 13 个 Prolog 模块各自输出格式不同。扩展到 20 个模块后，如果没有统一外壳，Rust/Python 的解析逻辑会随模块数量线性膨胀，最终不可维护。

**协议原则**：
1. Rust/Python 只解析**一层**：协议外壳
2. `data` 内字段由各模块自行定义
3. 错误/警告/证据统一格式，便于汇总报告

---

## 二、统一 JSON 外壳

```json
{
  "module":     "<模块 ID>",
  "version":    "<语义化版本>",
  "timestamp":  "<ISO 8601>",
  "status":     "passed | failed | partial | skipped",
  "data":       { /* 模块专属结构 */ },
  "warnings":   [ { "code": "<...>", "message": "<...>", "severity": "low|medium|high" } ],
  "errors":     [ { "code": "<...>", "message": "<...>" } ],
  "evidence":   [ { "source": "<...>", "value": "<...>", "unit": "<...>" } ],
  "confidence": 0.0,
  "next_actions": [ "<...>" ]
}
```

### 字段定义

| 字段 | 必填 | 类型 | 说明 |
|------|:---:|------|------|
| `module` | ✅ | string | 唯一模块 ID，如 `price_alert_rules` |
| `version` | ✅ | string | 语义化版本，如 `1.0.0` |
| `timestamp` | ✅ | string | ISO 8601，Rust 注入 |
| `status` | ✅ | enum | `passed` / `failed` / `partial` / `skipped` |
| `data` | ✅ | object | 各模块专属数据结构 |
| `warnings` | ❌ | array | 非阻断性警告列表 |
| `errors` | ❌ | array | 阻断性错误列表 |
| `evidence` | ❌ | array | 支撑判断的证据链 |
| `confidence` | ❌ | float | 0.0-1.0，模块对自身输出的置信度 |
| `next_actions` | ❌ | array | 建议的后续动作 |

### Status 语义

| Status | 含义 | 示例 |
|--------|------|------|
| `passed` | 全部检查通过 | EAA 全部达标 |
| `failed` | 至少一项检查未通过 | 赖氨酸缺口 12% |
| `partial` | 部分通过，部分跳过 | 有数据但缺 3 种 EAA 未计算 |
| `skipped` | 该模块被跳过 | 用户指定不运行合规检查 |

---

## 三、各模块专属 data 结构

### M1: `price_alert_rules`

```json
{
  "module": "price_alert_rules",
  "data": {
    "alerts": [
      {
        "ingredient": "fish_meal_peru_65",
        "deviation": 0.28,
        "level": "high",
        "action": "评估替代原料 + 调整配方成本模型",
        "should_recompute": true,
        "recompute_species": ["japanese_eel", "white_shrimp"]
      }
    ],
    "summary": {
      "total_checked": 20,
      "alerts_triggered": 2,
      "urgent_count": 0,
      "high_count": 1
    }
  }
}
```

### M2: `report_content_selector`

```json
{
  "module": "report_content_selector",
  "data": {
    "sections": [
      {
        "id": "warnings",
        "items": [
          {
            "code": "shrimp_water_stability",
            "severity": "medium",
            "evidence": { "gluten_pct": 0.3, "recommended_min": 0.5 }
          }
        ]
      },
      {
        "id": "suggestions",
        "items": [
          {
            "code": "low_fish_oil_attractant",
            "severity": "medium",
            "evidence": { "fish_oil_pct": 1.5, "recommended_min": 3.0 }
          }
        ]
      }
    ]
  }
}
```

> ⚠️ M2 只输出 **warning_code / suggestion_code**，自然语言文案由 Rust/Python 报告层根据 code 查表生成。

### M3: `recipe_planner`

```json
{
  "module": "recipe_planner",
  "data": {
    "plans": [
      {
        "strategy": "premium",
        "status": "passed",
        "recipe": {
          "items": [ { "ingredient": "fish_meal_peru_65", "pct": 30.0 }, "..." ],
          "total_cost_per_ton": 10200,
          "crude_protein": 44.2,
          "animal_protein_pct": 45.0
        },
        "strategy_profile": {
          "animal_protein_min": 45,
          "fishmeal_min": 20,
          "attractant_min_count": 2,
          "risk_tolerance": "low",
          "cost_weight": 0.4
        }
      }
    ]
  }
}
```

### M4: `ingredient_substitution`

```json
{
  "module": "ingredient_substitution",
  "data": {
    "substitutions": [
      {
        "original": "fish_meal_peru_65",
        "substitute": "chicken_meal_65",
        "savings_per_ton": 1200,
        "max_replace_pct": 8,
        "risk_level": "medium",
        "risks": [
          { "code": "palatability_risk", "message": "鸡肉粉适口性低于鱼粉" },
          { "code": "eaa_gap_possible", "message": "蛋氨酸可能不足，需补充" }
        ],
        "requires_rebalance": true
      }
    ]
  }
}
```

### M5: `mineral_balance`

```json
{
  "module": "mineral_balance",
  "data": {
    "result": "passed",
    "checks": [
      {
        "check": "ca_p_ratio",
        "status": "passed",
        "ratio": 1.25,
        "range": [1.0, 1.5],
        "evidence": [
          { "source": "calc_recipe_calcium", "value": 1.8, "unit": "%" },
          { "source": "calc_recipe_available_p", "value": 1.44, "unit": "%" }
        ]
      }
    ]
  }
}
```

### M6: `eaa_balance`

```json
{
  "module": "eaa_balance",
  "data": {
    "status": "failed",
    "gaps": [
      {
        "amino_acid": "lysine",
        "required": 5.8,
        "actual": 4.9,
        "gap_pct": 15.5,
        "severity": "high"
      }
    ],
    "passing": [
      { "amino_acid": "methionine", "required": 2.0, "actual": 2.2, "status": "ok" }
    ],
    "data_quality": {
      "ingredients_with_eaa_data": 30,
      "ingredients_total": 35,
      "missing_eaa_sources": ["fish_meal_white_68", "squid_liver_paste", "..."]
    }
  }
}
```

### M7a: `cost_range_rules`

```json
{
  "module": "cost_range_rules",
  "data": {
    "species": "japanese_eel",
    "stage": "adult",
    "recipe_cost_per_ton": 10200,
    "cost_range": [8000, 14000],
    "market_adjustment": 0.03,
    "dynamic_range": [8240, 14420],
    "status": "passed"
  }
}
```

### M7b: `performance_risk_rules`

```json
{
  "module": "performance_risk_rules",
  "data": {
    "status": "partial",
    "risks": [
      {
        "code": "fcr_estimate_low_confidence",
        "message": "当前配方动物蛋白偏低，FCR 可能劣于基准值",
        "severity": "low",
        "requires": "trial_validation"
      }
    ],
    "confidence": 0.35,
    "disclaimer": "FCR 预估为经验规则，未经过养殖试验验证，不可作为配方性能承诺。"
  }
}
```

---

## 四、Rust 注入字段

以下字段由 Rust CLI 在调用 Prolog 后、写入 JSON 前注入：

| 字段 | 注入方式 | 示例 |
|------|---------|------|
| `module` | Rust 根据调用目标填入 | `"price_alert_rules"` |
| `version` | Rust 从 registry 读取 | `"1.0.0"` |
| `timestamp` | `Utc::now().to_rfc3339()` | `"2026-06-05T08:00:00Z"` |

各模块 Prolog 只输出 `data` + `warnings` + `errors` + `confidence` + `next_actions` 五项，Rust 负责包装外层的 `module`/`version`/`timestamp`/`status`。

---

## 五、Prolog 侧输出约定

每个 Prolog 模块必须提供以下谓词作为统一入口：

```prolog
% 主输出谓词 — 所有模块必须实现
% output(+Input, -Output)
% Output = output{data: Data, warnings: Warnings, errors: Errors,
%                 confidence: Confidence, next_actions: Actions}

output(Input, Output) :- ...
```

### 测试约定

每个模块附带一个自检谓词：

```prolog
% 模块自检 — 验证输出结构完整性
% self_check → 成功静默返回 / 失败打印错误
self_check :-
    output(MockInput, Output),
    validate_output_structure(Output).
```

---

## 六、版本管理

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-06-05 | 初始版本，定义统一外壳 + 7 模块专属结构 |
