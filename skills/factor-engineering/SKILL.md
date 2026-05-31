---
name: factor-engineering
description: 量化因子工程能力——阿尔法因子（Alpha Factor）数学建模、Pandas/NumPy 高效向量化矩阵运算、横截面去极值与标准化算法、行业与市值中性化、IC/Rank-IC 与换手率统计学指标分析。当涉及因子设计、时序/截面矩阵计算、因子中性化或因子预测能力评估时激活。
---

📈 阿尔法因子工程（Alpha Factor Engineering）
核心问题：如何用严密的数学公式与高效的向量化代码开发预测能力显著、计算迅捷的量化因子？


📌 因子向量化运算规范（Speed & Memory）

  1. 矩阵化思维（Matrix Paradigm）：
    - 绝不允许使用 `for index, row in df.iterrows()` 遍历计算时序因子。
    - 将数据重构为 Panel Data，即以 `trade_date` 和 `security_id` 为 MultiIndex 的三维面板矩阵，全面利用 `df.groupby(level=0)` (截面) 或 `df.groupby(level=1)` (时序) 的向量化内置函数。

  2. 滚动窗口优化（Rolling Window Efficiency）：
    - 计算时序移动平均、滚动标准差等，必须使用 `df.rolling(window=N).mean()` 或 NumPy 快速滑块视图 `np.lib.stride_tricks.sliding_window_view`。
    - 确保运算全部发生在 C 语言底层，避免 Python 级别的循环开销。


📌 因子数据处理流水线（Cross-Sectional Processing）

  1. 截面去极值（Winsorization）：
    - 为了避免异常的离群值（Outliers）扭曲因子多空效果，必须在截面（同一交易日的所有标的）上对因子进行去极值。
    - 优先选用 MAD（Median Absolute Deviation）去极值法：
      $$\text{MAD} = \text{median}(|X_i - \text{median}(X)|)$$
      将超出三倍 MAD 的数据强制拉回阈值边界。

  2. 截面标准化（Standardization / Z-Score）：
    - 去极值后，通过 Z-Score 对因子值进行无量纲标准化处理，使其均值为 0，标准差为 1，确保因子能在横截面上进行直接比较。
      $$Z_i = \frac{X_i - \mu}{\sigma}$$

  3. 行业与市值中性化（Neutralization）：
    - 因子预测力可能被大盘股或特定行业所主导。必须通过线性回归剥离市值因子和行业哑变量（Industry Dummy Variables）：
      $$Factor_{raw} = \beta_{size} \cdot Log(MarketCap) + \sum \beta_{ind, j} \cdot Ind_j + Residual$$
      残差（$Residual$）即为完全剥离了市值与行业暴露的纯净中性化因子值。


📌 因子预测力统计学特征

  1. 信息系数（IC）审计：
    - IC：计算 $T$ 时刻的因子值与 $T+1$ 时刻的股票收益率之间的 Pearson 相关系数。
    - Rank IC（推荐）：计算因子值排名与股票收益率排名之间的 Spearman 秩相关系数，能够对非线性关系和残存离群值提供高鲁棒性。

  2. 指标达标硬约束：
    - Rank IC 均值：优秀因子应 $> 0.05$。
    - Rank IC IR（信息比率，$\text{Mean}(IC) / \text{Std}(IC)$）：衡量因子稳定性，优秀因子应 $> 1.5$。
    - 因子换手率（Turnover Rate）：评估实际交易可行性，高频因子的截面相关系数（Auto-correlation）必须处于合理区间，防止调仓成本击穿超额收益。


📌 产出物清单
  - 阿尔法因子数学公式定义（LaTeX 格式）
  - 高效向量化因子计算 Python 源码（Pandas/NumPy）
  - 因子 IC / Rank IC / IR 分析报告与多头分组收益曲线
