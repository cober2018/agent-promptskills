---
name: data-quality
description: 数据质量工程能力——数据契约定义与执行、Schema 校验、异常检测、数据血缘追踪、SLA 监控、质量门禁。适配 ClickHouse 金融数仓场景。当任务涉及数据质量检查、异常排查、契约定义、血缘追踪时激活。
---

✅ 数据质量（Data Quality Engineering）
核心问题：数据可信吗？schema 变了吗？管线按时交付了吗？


📌 数据契约（Data Contract）

  契约定义（每张 DWS/ADS 表必须有）：
    表名与描述
    Owner 团队
    SLA（新鲜度承诺）：例如"交易日 T+60min 内可用"
    Schema 契约：字段名、类型、约束（NOT NULL / UNIQUE / 范围）
    上游依赖：依赖哪些 ODS/DWD 表
    下游消费方：谁在用这张表、用于什么场景

  契约变更规则：
    加字段 → 非破坏性变更，通知消费方即可
    改字段类型/删字段 → 破坏性变更，必须走迁移流程
    改口径 → 即使技术上不破坏 schema，也必须通知消费方并记录 ADR


📌 质量检查维度

  完整性（Completeness）：
    必填字段不为空
    金融场景关键检查：
      adj_factor IS NULL 数量 > 0 → 告警（复权因子缺失导致全链路错误）
      ts_code 为空 → 立即阻断管线
      trade_date 为空 → 立即阻断管线

  准确性（Accuracy）：
    数值范围校验：
      价格字段 > 0（除 ST 股和退市股特殊处理）
      涨跌幅 pct_chg 范围 -20% ~ +20%（主板）、-30% ~ +30%（创业板/科创板）
      成交量 vol >= 0
      复权因子 adj_factor > 0
    交叉验证：
      close × vol 应与 amount 数量级一致
      当日 close 与次日 pre_close 应一致（排除除权日）

  一致性（Consistency）：
    同一标的同一交易日在不同层的数据应一致
    ODS 行数与源系统行数对比偏差 < 0.1%
    DWD 前复权价格与 ODS 原始价格 × adj_factor 误差 < 0.01

  时效性（Timeliness）：
    ODS 日 K 数据：交易日 T+60min 内可用（16:00 采集，17:00 前就绪）
    DWD 前复权表：交易日 T+120min 内可用（19:30 计算）
    DWS 情绪因子：交易日 T+180min 内可用（20:00 聚合）

  唯一性（Uniqueness）：
    ReplacingMergeTree 保证最终唯一（合并后按主键 + version 去重）
    查询时加 FINAL 关键字获取去重后结果
    定期检查：SELECT count() vs SELECT count() ... FINAL 差异应趋近 0


📌 质量门禁（Quality Gate）

  管线入口门禁（写入前检查）：
    Schema 校验：字段名、类型是否与目标表一致
    行数校验：当日行数 vs 历史均值，波动 > 30% → 告警
    空值检查：核心字段空值率超过阈值 → 阻断
    重复检查：主键重复率 > 0% → 告警（ReplacingMergeTree 会处理，但需要知道）

  管线出口门禁（写入后检查）：
    行数验证：写入行数与源数据行数一致
    时间戳验证：最新记录的 trade_date 是否为当天
    抽样校验：随机抽取 N 条记录，对比源数据

  层间传递门禁：
    ODS → DWD：ODS 数据就绪且通过入口门禁后，DWD 管线才启动
    DWD → DWS：DWD 前复权表行数 > 0 且 adj_factor 无空值
    DWS → ADS：DWS 聚合表的 trade_date 包含当天


📌 异常检测

  统计异常检测：
    行数异常：当日行数偏离最近 30 天均值超过 2 个标准差
    空值率异常：某字段空值率突然升高
    数值异常：价格出现负值、成交量出现极端值

  Schema 漂移检测：
    源系统返回了新字段 → 记录并告警
    源系统删除了字段 → 立即告警并暂停管线
    字段类型变更 → 立即告警并暂停管线

  时效性异常：
    管线执行超时（超过历史平均的 3 倍）
    数据未在 SLA 窗口内到达目标表
    上游数据源 API 无响应或返回空数据


📌 数据血缘

  表级血缘（必须维护）：
    每张 DWD/DWS/ADS 表都标注数据来源表
    变更上游表结构前，先查血缘确认下游影响

  字段级血缘（核心字段维护）：
    前复权价格字段追溯到 ODS 原始价格 + adj_factor
    情绪因子追溯到涨停板、封板率等原始指标
    策略信号追溯到因子值 + 策略参数

  项目血缘图：
    Tushare API → ods_astock_daily_his_df
                       ↓
                  dwd_astock_daily_adj_df（前复权）
                       ↓
                  dws_astock_sentiment_factors_daily_df（情绪因子）
                       ↓
                  ads_factor_value_df（因子值）

    AmazingData API → ods_astock_1min_price_amz_df
                           ↓
                      dwd_astock_1min_price_adj_df（分钟前复权）
                           ↓
                      ods_vw_astock_15min_df / 30min / monthly（聚合视图）


📌 监控与告警

  监控指标：
    采集数据量：当日行数 vs 历史均值，波动 > 30% 告警
    复权因子缺失：adj_factor IS NULL 数量 > 0 告警
    行情连续性：股票在某交易日无数据 > 5% 告警
    视图数据完整性：15/30 分钟视图行数校验，波动 > 10% 告警
    管线执行时间：超过 SLA 窗口告警

  异常处理流程：
    上游数据缺失 → 暂停下游任务 + 告警
    计算失败 → 记录错误日志 + 保留原始数据 + 告警
    数据回溯 → 标记受影响时间段，不覆盖历史正确数据

  告警渠道：
    P0（管线中断/数据损坏）：5 分钟内通过钉钉/飞书告警
    P1（质量退化/SLA 超时）：30 分钟内告警
    P2（统计异常/Schema 漂移）：每日质量报告汇总


📌 数据质量产出物清单
  数据契约文档（每张 DWS/ADS 表）
  质量检查规则配置（门禁条件）
  异常检测报告（统计异常 + Schema 漂移）
  数据血缘图（表级 + 核心字段级）
  每日数据质量报告（检查通过率、异常项）
  数据质量 SLA 文档（新鲜度、完整性承诺）
