---
name: options-strategy
description: 用于以下场景：期权定价、希腊字母风险管理与对冲策略——涉及 Black-Scholes 模型、Greeks（Delta/Gamma/Vega/Theta）计算标准、备兑/价差组合对冲设计。
---

# 期权定价与希腊字母对冲策略

## 概述

衍生品是管理多头组合风险、提取非线性收益的重要工具。本技能包规范了期权定价模型的基础公式、希腊字母（Greeks）风险度量指标以及经典对冲策略的构建规范。

## 何时使用

*   量化策略研究员在资产配置中引入期权对冲尾部风险（Tail Risk）。
*   设计波动率策略（如跨式套利、宽跨式套利）以应对财报或宏观决议的波动。
*   构建 Delta 中性策略，剥离方向性 Beta 风险，赚取纯粹的 Gamma 或 Theta 收益。

**不要用于：**
*   纯粹的底层现货选股因子计算（使用 `quant-alpha-zoo`）。
*   技术面走势分类（使用 `candlestick-pattern`）。

## Black-Scholes 经典期权定价模型

欧式看涨期权 $C$ 与看跌期权 $P$ 的定价公式标准：

$$C = S_0 N(d_1) - K e^{-rT} N(d_2)$$
$$P = K e^{-rT} N(-d_2) - S_0 N(-d_1)$$

其中：
$$d_1 = \frac{\ln(S_0 / K) + (r + \sigma^2 / 2) T}{\sigma \sqrt{T}}$$
$$d_2 = d_1 - \sigma \sqrt{T}$$

*   $S_0$: 现货标的价格
*   $K$: 执行价格
*   $T$: 距离到期时间（年化）
*   $r$: 无风险利率
*   $\sigma$: 标的资产波动率（隐含波动率或历史波动率）
*   $N(x)$: 累积标准正态分布函数

## 希腊字母 (Greeks) 风险敞口定义

| 希腊字母 | 经济含义 | 敏感性关系式 | 对冲操作 |
|:---|:---|:---|:---|
| **Delta ($\Delta$)** | 标的价格变化对期权价格的影响 | $\Delta = \frac{\partial V}{\partial S}$ | Delta 中性对冲需要动态买卖现货 |
| **Gamma ($\Gamma$)** | 标的价格变化对 Delta 的影响 | $\Gamma = \frac{\partial^2 V}{\partial S^2}$ | 正 Gamma 享受大波动，负 Gamma 怕跳空 |
| **Vega ($v$)** | 隐含波动率变化对期权价格的影响 | $v = \frac{\partial V}{\partial \sigma}$ | 买期权做多 Vega，卖期权做空 Vega |
| **Theta ($\theta$)** | 时间流逝对期权价格的影响 | $\theta = \frac{\partial V}{\partial t}$ | 买方支付时间价值，卖方收取时间价值 |

## 经典期权风险对冲组合

1.  **备兑看涨期权 (Covered Call)**：
    *   *结构*：持有 100% 现货 + 卖出 1 份虚值看涨期权（OTM Call）。
    *   *目的*：获取 Theta 时间价值，为现货提供有限的下行保护。
2.  **Delta 中性对冲 (Delta Neutral Hedging)**：
    *   *结构*：持有期权多头，同时买卖 $\Delta_{total} = 0$ 的现货头寸。
    *   *目的*：消除一阶方向性风险，赚取波动率溢价，需每日截面重平衡。

## 常见错误

| 错误做法 | 正确做法 |
|:---|:---|
| 在市场流动性极差的期权合约上频繁调仓 | 必须监控买卖价差（Bid-Ask Spread）与未平仓合约量（Open Interest），排除流动性黑洞 |
| 直接用历史波动率（HV）替代隐含波动率（IV）计算定价 | 使用牛顿迭代法或 Brent 法从市场中期权价格逆向求解出 IV，防止定价偏差 |
| 忽视 Delta 动态对冲产生的摩擦成本（滑点、手续费） | 在回测中显式加入滑点损耗，计算换手率阈值，防止高频对冲蚕食全部收益 |

## 产出物清单

- [ ] Black-Scholes 期权定价与 Greeks 计算的 Python 函数
- [ ] 投资计划中的期权对冲方案（含具体标的、行权价、到期日与 Delta 敞口）
- [ ] 多空对冲投资组合的实时 Vega 与 Gamma 监测表
