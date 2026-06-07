---
name: candlestick-pattern
description: 用于以下场景：K 线与量价指标形态特征识别——涵盖红三兵、吞没、吊颈线等 20 种经典 K 线形态的量化规则、阻力位支撑位技术形态识别规范。
---

# K 线形态量化特征识别

## 概述

K 线形态是短线交易中市场情绪与力量博弈的直观体现。为了让智能体能够客观、无偏地识别技术指标，本技能包将模糊的形态描述转化为严格的价格数学关系表达式。

## 何时使用

*   A股市场分析师在技术面扫描中判定看涨/看跌的日线与周线组合。
*   识别阻力位与支撑位附近的形态突变，用以设计 T+1 短线止损/止盈。

**不要用于：**
*   估值与财务分析（使用 `fundamental` 策略包）。
*   计算全局统计因子（使用 `quant-alpha-zoo`）。

## K 线基础特征数学定义

为统一描述，定义单根 K 线的各部分特征：
*   **实体长度 (Body)**: $B = |Close - Open|$
*   **上影线长度 (Upper Shadow)**: $US = High - \max(Open, Close)$
*   **下影线长度 (Lower Shadow)**: $LS = \min(Open, Close) - Low$
*   **K 线全长 (Range)**: $R = High - Low$

## 经典形态的量化识别规则

| K线形态 | 市场含义 | 量化判定条件 (LaTeX) |
|:---|:---|:---|
| **锤头线 / 吊颈线 (Hammer / Hanging Man)** | 底部反转 / 顶部见顶 | $LS > 2 \times B \quad \text{and} \quad US < 0.1 \times R$ |
| **十字星 (Doji)** | 多空势均力敌 | $B < 0.05 \quad \text{and} \quad US > 0.4 \times R \quad \text{and} \quad LS > 0.4 \times R$ |
| **看涨吞没 (Bullish Engulfing)** | 强劲买盘吞噬空头 | $Close_{T-1} < Open_{T-1} \quad \text{and} \quad Close_T > Open_T \quad \text{and} \quad Open_T < Close_{T-1} \quad \text{and} \quad Close_T > Open_{T-1}$ |
| **红三兵 (Red Three Soldiers)** | 稳健上行，空头退守 | $Close_i > Open_i \quad \text{for } i \in [T-2, T] \quad \text{and} \quad Close_T > Close_{T-1} > Close_{T-2}$ 且成交量温和放大 |

## 阻力与支撑的数学确认

*   **均线支撑**：若价格跌至均线附近（如 MA20），且当日最低价满足 $Low_T \le MA20_T \times 1.005$ 且 $Close_T \ge MA20_T$，同时出现下影线（$LS > 1.5 \times B$），判定为支撑确认。
*   **平台突破**：股价连续 10 日受制于特定阻力位 $R_{line}$（偏差小于 1%），当日收盘价满足 $Close_T > R_{line} \times 1.015$ 且成交量满足 $Volume_T > \text{mean}(Volume, 10) \times 1.8$，判定为放量平台突破。

## 常见错误

| 错误做法 | 正确做法 |
|:---|:---|
| 用眼睛看图并说“这个 K 线看起来像流星线” | 使用数学不等式验证实体与上下影线的具体比例关系 |
| 忽略成交量配合孤立判定 K 线形态 | 必须结合前置 $N$ 日均量对比，判断形态的有效度 |
| 跨市场混用技术形态阈值（如主板与科创板）| 根据市场涨跌幅限制（10% 或 20%）微调 K 线实体长度的绝对判定阈值 |

## 产出物清单

- [ ] 技术面扫描模块中用于筛选 K 线形态的 Python/SQL 判定逻辑
- [ ] 量化支撑位/阻力位突破信号（含成交量偏离度数据）
- [ ] 标注各形态命中情况的技术分析子报告
