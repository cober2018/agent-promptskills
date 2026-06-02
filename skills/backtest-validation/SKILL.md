---
name: 回测与验证
description: 用于以下场景：构建无偏回测引擎、模拟 A 股交易摩擦、防范三大偏误（Lookahead / Survivorship / Announcement Delay）、过拟合诊断、OOS 与 Walk-forward 验证。
---

# 回测与验证

## 概述

构建还原真实交易环境的沙盒，无情戳破过拟合的幻象，确保策略在实盘中能活下去。**回测的好得令人难以置信，那它一定是错的。**

## 何时使用

- 设计回测引擎（A 股 T+1、涨跌停、滑点、印花税）
- 检查回测结果是否含有未来函数 / 幸存者偏差 / 公告延迟偏差
- 做过拟合诊断（OOS、参数扰动、Walk-forward）
- 计算业绩指标（CAGR、Alpha、Max DD、Sharpe、Calmar）
- 评估策略上实盘的可行性

**不要用于：** 因子公式设计（用 `factor-engineering`）、数据采集（用 `pipeline-engineering`）。

## A 股特色交易环境模拟

绝不允许在回测中假设理想交易条件。必须硬编码以下物理限制：

| 限制 | 规则 |
|---|---|
| **T+1 交割** | 今日买入的股票，今日不可卖出；必须独立维护可用资金和可用仓位 |
| **涨跌停** | 涨停板不能买入（排队资金庞大，默认无法成交）；跌停板不能卖出；按前日收盘价计算精确涨跌停价 |
| **停牌** | 停牌日成分股不可被买入或卖出，权重顺延直至复牌 |
| **印花税** | 卖出方单向收取（当前 0.05% 或按最新政策） |
| **佣金** | 双向收取（万分之二至万分之三），有单笔最低 5 元限制 |
| **滑点** | 基于成交额设定冲击成本，或统一 0.1% 固定滑点，或 VWAP 成交模拟 |
| **流动性** | 单笔交易不得超过该股当日总成交量的 10% |

```python
# ✅ T+1 与涨跌停处理伪代码
def process_orders(target_positions, current_holdings, today_data):
    tradeable_mask = (
        (today_data['is_suspended'] == False) &
        (today_data['low'] > today_data['limit_down']) &
        (today_data['high'] < today_data['limit_up'])
    )

    for stock in target_positions:
        if not tradeable_mask[stock]:
            continue  # 遇到涨跌停或停牌，跳过调仓

        if target_positions[stock] < current_holdings[stock]:
            sell_qty = current_holdings[stock] - target_positions[stock]
            if sell_qty <= current_holdings[stock].available_to_sell:
                execute_sell(stock, sell_qty)
```

## 严防四大回测偏误（Bias）

| 偏误 | 描述 | 对策 |
|---|---|---|
| **前视偏差（Lookahead Bias）** | 用今日收盘价计算的信号去做今日开盘的买卖 | 信号计算数据强制 `signal = factor.shift(1)`，今日信号仅决定明日持仓 |
| **幸存者偏差（Survivorship Bias）** | 股票池中剔除退市股票 | 使用包含历史退市股票的全量静态数据映射 |
| **公告延迟偏差（Announcement Delay Bias）** | 假设季报在财报期末立刻获得 | 必须关联财报实际披露日期表，数据对齐 |
| **微盘股偏差（Microcap Bias）** | 极低流动性股票占用不成比例仓位 | 强制按流通市值设置成交量上限过滤 |

## 过拟合诊断（Overfitting Diagnosis）

一个优秀的策略不仅要在样本内表现好，更要经得起参数微调和样本外考验。

**样本外测试（Out-of-Sample, OOS）：**
- 将数据严格分为训练集（70%）和测试集（30%）。
- 回测优化仅在训练集进行，最终一刀切在测试集上验证，防止「看答案做题」。

**参数敏感性分析：**
- 扰动关键参数（如 20 日均线变为 18 日、22 日）。
- 若收益率产生悬崖式暴跌，说明策略严重过拟合了某一特定历史轨迹。

**滚动前向验证（Walk-forward Validation）：**
- 滑动时间窗口持续训练模型并推演下一期，更符合真实世界的流式数据状态。

## 业绩评价体系

必须与基准（沪深 300、中证 500）对标计算主动管理收益。

| 指标 | 公式 / 说明 |
|---|---|
| 年化收益率（CAGR） | 期末净值 / 期初净值的 (1/n) 次方减 1 |
| 超额收益（Alpha） | 策略收益 − 基准收益（或 Beta 调整后收益） |
| 最大回撤（Max Drawdown） | 资金曲线从最高点滑落到最低点的幅度，衡量疼痛指数 |
| 夏普比率（Sharpe Ratio） | (R_p − R_f) / σ_p，每承担一单位总风险带来的超额回报（R_f 通常取无风险利率 2-3%） |
| 卡玛比率（Calmar Ratio） | 年化收益率 / 最大回撤，衡量抗风险恢复能力 |

## 常见错误

| 错误做法 | 正确做法 |
|---|---|
| 假设 T+0 交易 | T+1 交割，单独维护可用仓位 |
| 涨跌停仍可成交 | 涨跌停拒单，排队逻辑 |
| 忽略交易成本 | 印花税 + 佣金 + 滑点全部扣除 |
| 因子信号当日使用 | `.shift(1)` 后才能用于次日交易 |
| 股票池用当下成分股 | 动态加载对应历史时刻的实际成分股 |
| 用全样本做参数优化 | OOS 验证 + Walk-forward 滚动 |
| 调参后只在历史最优区段展示 | 全时段展示，提供最大回撤与卡玛比率 |

## 产出物清单

- [ ] 撮合引擎代码：带 T+1、滑点、涨跌停过滤的对账与仓位推演逻辑
- [ ] 过拟合诊断报告：参数平面热力图与样本外验证分析
- [ ] 资金曲线与评价指标图表：含基准对比的净值走势和最大回撤填补图
