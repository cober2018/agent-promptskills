---
name: quant-alpha-zoo
description: 用于以下场景：量化因子公式库（Alpha Zoo）与向量化标准——涵盖经典 Alpha 因子公式（如 Alpha101、Alpha191）、数据预处理（MAD去极值、中性化）、NumPy/Pandas/Polars 向量化计算与加速规范。
---

# 因子动物园与向量化标准

## 概述

因子是量化交易系统的信号核心。本技能包规范了经典 Alpha 因子公式的数学表达、数据预处理方法以及高性能向量化（Vectorization）计算的实现标准，避免在海量面板数据（Panel Data）上使用慢速循环。

## 何时使用

*   设计与计算新的 Alpha 信号（例如动量、量价相关性、流动性因子）。
*   编写因子的数据清洗管线（去极值、截面标准化、中性化）。
*   审查因子代码以消除 `for` 循环和链式赋值。

**不要用于：**
*   编写回测框架（使用 `backtest-validation`）。
*   技术面指标形态识别（使用 `candlestick-pattern`）。

## 经典 Alpha 因子公式

每一个因子的设计都必须明确 LaTeX 公式，并按以下标准向量化实现：

### 1. 经典 Alpha 101 #101
*   **公式**：
    $$\alpha_{101} = \frac{close - open}{(high - low) + 0.001}$$
*   **实现**：
    ```python
    def calc_alpha101(df: pd.DataFrame) -> pd.DataFrame:
        return (df['close'] - df['open']) / ((df['high'] - df['low']) + 0.001)
    ```

### 2. 动量回归 Alpha (时序 Rank 动量)
*   **公式**：
    $$Alpha_{mom} = ts\_rank(delay(close, 1), 10)$$
*   **实现**：
    ```python
    def calc_ts_rank_momentum(df_close: pd.DataFrame) -> pd.DataFrame:
        # df_close 为 Panel 矩阵 (日期为索引，股票代码为列)
        delayed = df_close.shift(1)
        return delayed.rolling(window=10).apply(lambda x: pd.Series(x).rank(pct=True).iloc[-1], raw=True)
    ```

## 因子预处理标准（Python 模板）

### 1. MAD 去极值 (Winsorization)
```python
def winsorize_mad(factor_series: pd.Series, n_sigs: float = 3.0) -> pd.Series:
    median = factor_series.median()
    mad = (factor_series - median).abs().median()
    # 比例因子 1.483 用于对齐正态分布的标准差
    mad_limit = n_sigs * 1.483 * mad
    upper_limit = median + mad_limit
    lower_limit = median - mad_limit
    return factor_series.clip(lower=lower_limit, upper=upper_limit)
```

### 2. 行业与市值中性化 (Neutralization)
```python
import statsmodels.api as sm

def neutralize_factor(factor_series: pd.Series, market_cap: pd.Series, industry_dummies: pd.DataFrame) -> pd.Series:
    """
    对对数市值及行业哑变量进行多元回归，取残差作为中性化因子
    """
    X = pd.concat([np.log(market_cap), industry_dummies], axis=1)
    X = sm.add_constant(X)
    # 拟合回归
    model = sm.OLS(factor_series, X, missing='drop').fit()
    return model.resid
```

## 常见错误

| 错误做法 | 正确做法 |
|:---|:---|
| 使用 `prices.iterrows()` 遍历行计算因子 | 使用向量化的矩阵乘法、时序平移 `.shift()` 和 `rolling()` |
| 跨股票和行业直接比较原始因子值 | 必须在每日截面上进行 Z-Score 标准化与中性化 |
| 回归时将缺失值（NaN）强行插零 | 在回归模型中使用 `missing='drop'` 剔除样本，或合理运用多重插补 |

## 产出物清单

- [ ] 因子计算源文件：符合向量化标准、无链式赋值警告（`SettingWithCopyWarning`）
- [ ] 因子分布图与统计指标（均值、标准差、偏度、峰度）
- [ ] 预处理流水线代码（含 MAD 去极值和中性化函数）
