---
name: pipeline-engineering
description: 管线工程能力——采集脚本开发、ODS→DWD→DWS→ADS 四级管线实现、CDC/增量加载、调度编排、幂等写入。适配 ClickHouse + Tushare/AmazingData 金融数仓场景。当任务涉及数据采集、管线开发、ETL/ELT 实现时激活。
---

🔧 管线工程（Pipeline Engineering）
核心问题：数据怎么从源头流到消费方？怎么保证不丢不重？


📌 采集脚本开发流程

  标准流程：
  1. 确定数据源（Tushare / AmazingData / AKShare）
  2. 查询数据字典与开发规范，确认目标 ODS 表是否已存在
  3. 若已有表 → 对比字段映射，确认是否需要新增字段
  4. 新建表 → 参考数仓开发规范设计表结构（ReplacingMergeTree + 分区 + 排序键）
  5. 编写 Python 采集脚本（包含字段映射与幂等写入逻辑）
  6. 自检：语法检查 → 导入测试 → 边缘与极端情况测试
  7. 更新数据字典与字段标准

  字段映射规范：
    采集脚本在写入数据前，必须输出精确映射关系
    源字段名 → 标准字段名 → 类型转换 → 备注
    示例：TOTAL_VOLUME → vol（Float64）原始单位为万手，需乘10000
    示例：trade_date → trade_date（Date）YYYYMMDD 字符串转换为 Date


📌 四级管线架构（ODS→DWD→DWS→ADS）

  ODS 管线（原始采集）：
    职责：从数据源获取原始数据，零转换写入
    写入策略：只追加，不修改历史
    幂等保证：ReplacingMergeTree(updated_at) + ORDER BY 主键自动去重
    元数据捕获：source_system、ingested_at、source_file
    Schema 演化：mergeSchema = true，告警但不阻塞
    分区策略：按月分区 PARTITION BY toYYYYMM(trade_date)

    项目实例：
      每日 15:30 → AmazingData 采集全市场 1 分钟 K 线 → ods_astock_1min_price_amz_df
      每日 16:00 → Tushare 采集日 K/财务 → ods_astock_daily_his_df
      每日 16:30 → Tushare 采集涨停板/融资融券 → ods_astock_limit_board_ak_df

  DWD 管线（清洗与标准化）：
    职责：字段标准化、类型统一、前复权计算、去重
    关键输出：前复权物理表（不是动态视图）
    前复权计算公式：
      前复权价格 = 原始价格 × 当日复权因子
      前复权成交量 = 原始成交量 / 当日复权因子
    写入策略：每日覆盖当日数据，ReplacingMergeTree 保证幂等
    调度窗口：19:30 开始

    项目实例：
      ods_astock_daily_his_df → dwd_astock_daily_adj_df（日 K 前复权）
      ods_astock_1min_price_amz_df → dwd_astock_1min_price_adj_df（1 分钟前复权）

  DWS 管线（聚合）：
    职责：按交易日/标的/行业聚合跨表指标
    典型输出：市场宽度、情绪因子、板块涨跌
    调度窗口：20:00 开始，同一层内任务间隔 5 分钟错峰

    项目实例：
      dws_astock_date_daily_measures_df（市场宽度：上涨/下跌家数）
      dws_astock_sentiment_factors_daily_df（情绪因子：涨停强度、封板率）

  ADS 管线（应用）：
    职责：直接服务于业务场景（因子值、策略信号）
    写入方式：由业务触发（因子计算、策略回测）
    调度窗口：20:30 开始

    项目实例：
      ads_factor_value_df（因子数值矩阵）
      ads_strategy_signal_df（策略信号与交易记录）


📌 调度依赖管理

  依赖链（严格顺序，上游失败则下游不执行）：
    ODS 采集（15:30-19:00）
        ↓
    DWD 清洗（19:30）← 依赖 ODS 数据就绪
        ↓
    DWS 聚合（20:00）← 依赖 DWD 物理表计算完成
        ↓
    ADS 应用（20:30）← 依赖 DWS 因子数据就绪

  调度规则：
    交易日才执行行情类管线（Cron 中用 1-5 限制工作日）
    新闻/舆情类任务可全天候运行
    上游失败时暂停下游任务并告警
    计算失败时记录错误日志，保留原始数据


📌 写入优化（ClickHouse 专项）

  严禁高频小批次写入：
    ClickHouse 对大量小批次插入极其敏感
    策略 A（推荐）：应用层攒齐 1 万条以上再统一 INSERT
    策略 B：开启 async_insert = 1，ClickHouse 自动缓冲
    策略 C：极致实时场景引入 Kafka，通过 Kafka 引擎表批量消费

  严禁高频 ALTER DELETE/UPDATE：
    ClickHouse 的 Mutations 是极度沉重的异步操作
    替代策略 A（推荐）：ReplacingMergeTree 直接 INSERT 覆盖
    替代策略 B：大规模重刷时 DROP PARTITION 然后重新插入

  规避内存瓶颈：
    批次处理：每 5-10 万行执行一次 insert_df
    ELT 替代 ETL：Python 只投递到 ODS，转换逻辑在 ClickHouse 内部执行


📌 1 分钟 K 线数据生命周期管线

  实时层：ods_astock_1min_price_amz_df
    当天盘中实时写入，收盘后不再更新

  热表：ods_astock_1min_price_his_hot
    每日收盘后接收合并数据，2021 年至今，SSD 存储

  冷表：ods_astock_1min_price_his_cold
    2010-2021 历史数据，HDD 存储

  查询入口：ods_vw_astock_1min_price_his_df
    联合 hot + cold 提供全量历史查询（UNION ALL 视图）

  Redis 实时层：
    Key 模式：ods_astock_1min_price_rt:{ts_code}（Sorted Set，48h TTL）
    Redis 不可用时回退为仅返回 ClickHouse 历史数据


📌 管线工程产出物清单
  采集脚本（含字段映射表）
  管线依赖图（DAG）
  调度配置（Cron 表达式 + 依赖关系）
  写入策略文档（引擎选择、批次大小、幂等机制）
  数据生命周期说明（热/冷分区、TTL、归档策略）
  运行手册（Runbook：什么会坏、怎么修、谁负责）
