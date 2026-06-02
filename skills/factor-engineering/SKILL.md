---
name: 量化因子工程
description: 用于以下场景：量化因子分类与设计——涉及因子分类体系（动量 / 波动率 / 量价 / 流动性 / 价值）、向量化计算（Pandas / ClickHouse）、去极值与中性化、IC / Rank IC 评估、未来函数防范。
---

# 量化因子工程

## 概述

因子是量化研究的灵魂。**你痛恨低效的 `for` 循环迭代代码，视「未来函数」为量化领域的死罪。**

## 何时使用

- 因子分类与设计（动量 / 波动率 / 量价 / 流动性 / 价值）
- 向量化因子计算（Pandas / ClickHouse SQL）
- 去极值、标准化、中性化处理
- 因子预测能力评估（IC / Rank IC / IR / IC Decay）
- 未来函数防范（shift + announcement_date）
- 多因子合成与权重分配

**不要用于：** 回测引擎与防偏误（用 `backtest-validation`）、AI 工作流节点化挖掘（用 `factor-mining`）、数据采集（用 `pipeline-engineering`）。

## 因子分类体系（Factor Zoo）

| 体系 | 描述 | 示例 |
|---|---|---|
| 动量（Momentum） | 时序动量、截面排名 | 过去 N 日对数收益率、截面反转效应 |
| 波动率（Volatility） | 价格波动幅度 | 特质波动率、振幅、高低价差比 |
| 量价（Price-Volume） | 价格与成交量关系 | 量价相关性、主买主卖失衡（Order Imbalance） |
| 流动性（Liquidity） | 交易活跃度 | 换手率变异系数、Amihud 非流动性指标 |
| 价值 / 成长（基本面） | 财务质量 | 账面市值比（PB）、盈利收益率（EP）、ROE 变动 |

## 核心计算原则：向量化是唯一铁律

绝不允许在时间序列或截面上使用 `iterrows()` 或普通 `for` 循环。

### Pandas 向量化示例

```python
# ✅ 动量反转因子（过去 20 天收益率排名）
def calc_reversal_20d(prices: pd.DataFrame) -> pd.DataFrame:
    ret_20d = prices.pct_change(periods=20)
    # 截面排名，值越小（跌得多）排名越靠前（反转做多）
    return -ret_20d.rank(axis=1, pct=True)

# ✅ 波动率因子（过去 20 日对数收益率标准差）
def calc_volatility_20d(prices: pd.DataFrame) -> pd.DataFrame:
    log_ret = np.log(prices / prices.shift(1))
    return log_ret.rolling(window=20).std()
```

### ClickHouse SQL 向量化示例

```sql
-- ✅ 利用聚合窗口函数计算 20 日动量
SELECT
    trade_date,
    symbol,
    (close / any(close) OVER (
        PARTITION BY symbol ORDER BY trade_date
        ROWS BETWEEN 20 PRECEDING AND 20 PRECEDING
    ) - 1) AS momentum_20d
FROM ods.astock_1d_price
```

## 因子处理流程：清洗与中性化

单个因子往往带有行业或大盘的 Beta 暴露，必须进行提纯。

### 1. 去极值（Winsorization - MAD 法绝对中位差）

计算中位数 $M$，计算绝对偏差中位数 $MAD = median(|X - M|)$。将落在 $[M - 3 \times 1.483 \times MAD, M + 3 \times 1.483 \times MAD]$ 之外的值强行截断。

### 2. 标准化（Z-Score）

去除极值后，在**每日截面**上做标准化：$X_{norm} = \frac{X - \mu}{\sigma}$，使得因子服从均值为 0、方差为 1 的分布。

### 3. 正交与中性化（Orthogonalization）

剔除行业、市值的共线性干扰。对行业哑变量矩阵和对数市值做多元线性回归：

$$Factor = \beta_1 \cdot MktCap + \beta_2 \cdot Industry + \epsilon$$

取残差 $\epsilon$ 作为最终的「纯净 Alpha 因子」。

## 因子评估体系

不看绝对收益曲线，只看统计显著性。

| 指标 | 公式 | 说明 |
|---|---|---|
| **IC（Information Coefficient）** | 因子暴露度与下一期收益率的皮尔逊相关系数 | 越接近 ±1 越强 |
| **Rank IC** | 因子排位与下一期收益率排位的斯皮尔曼等级相关系数 | 规避极值影响，最常用 |
| **IC Decay（因子衰减）** | 因子与未来第 T 期收益率的 Rank IC | 判断因子是高频（T=1 显著，T=5 衰减至 0）还是低频 |
| **IR（Information Ratio）** | $IR = \frac{mean(IC)}{std(IC)}$ | 评价因子稳定性 |

**IR 评价标准：**

| IR 范围 | 评价 |
|---|---|
| > 0.5 | 优秀 |
| > 0.8 | 极其卓越 |
| > 1.5 | **往往暗示包含未来函数或过度拟合**（需重审） |

## 未来函数绝对防范

- **时序严格 shift：** 收盘后计算出的因子，只能用于 T+1 日的开盘或收盘交易。
- **财务数据公告日：** 必须验证 `announcement_date`，绝不能在报表发布前使用财务数据。
- **滚动窗口核查：** 计算滚动指标（滑动平均、滑动方差）时，窗口不得包含未来数据。

## 常见错误

| 错误做法 | 正确做法 |
|---|---|
| 在 Panel Data 上 `iterrows()` | 全面向量化（Pandas / NumPy / Polars） |
| 因子原始值未去极值 | MAD 法 Winsorize，截断 `[M - 3 × 1.483 × MAD, M + 3 × 1.483 × MAD]` 之外 |
| 标准化跨日累积 | 每日截面重新标准化（μ、σ 按当日截面计算） |
| 未做行业 / 市值中性化 | 多元回归取残差作为最终因子 |
| 因子 T 日数据用于 T 日决策 | 严格 `.shift(1)` |
| 财务数据按报告期使用 | 按 `announcement_date` 公告日对齐 |
| 看绝对收益曲线下结论 | 以 IC / Rank IC / IR 等量化指标证明预测能力 |
| IR > 1.5 就开心接受 | 警惕未来函数或过拟合，必须重审 |

## 产出物清单

- [ ] 因子计算代码：纯向量化的 Pandas 或 ClickHouse SQL 脚本
- [ ] 处理 Pipeline：包含去极值、标准化、中性化的处理函数
- [ ] 因子检验报告：Rank IC、IC IR 统计值及分组收益累积曲线分析的代码片段
- [ ] 未来函数审计清单（shift / announcement_date / 滚动窗口）
