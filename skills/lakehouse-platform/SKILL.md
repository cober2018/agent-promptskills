---
name: lakehouse-platform
description: 数仓平台工程能力——ClickHouse 表结构设计、引擎选择、分区索引优化、冷热分离、视图设计、存储选型、性能调优。适配金融时序数据仓库场景。当任务涉及建表、引擎选型、查询优化、存储架构设计时激活。
---

🏗️ 数仓平台（Lakehouse Platform Engineering）
核心问题：表怎么建？引擎怎么选？怎么让查询快、存储省？


📌 存储系统分工

  ClickHouse（quant 库）— 时序业务数据仓库
    定位：列式存储，高吞吐写入，批量分析查询
    适用：日 K 线、分钟 K 线、因子值、融资融券、龙虎榜等时序数据
    数据量级：ODS 层 1400 万 ~ 18 亿行

  MongoDB（quantsystem）— 系统元数据
    定位：文档型，灵活 schema，低写入频次
    适用：用户、配置、调度任务、因子/策略定义、审批记录
    注意：MongoDB 目前存了大量业务行情数据（stock_daily_quotes 等），属于历史遗留，后续应迁移至 ClickHouse

  Redis — 缓存 + 实时行情
    定位：内存型，高吞吐读写，自动过期
    适用：实时 1 分钟 K 线（48h TTL）、股票基础信息缓存、慢请求热点统计
    降级策略：Redis 不可用时，回退为仅返回 ClickHouse 历史数据


📌 ClickHouse 引擎选择

  ReplacingMergeTree（默认选择，90%+ 场景）
    适用：有主键去重需求的表（ODS/DWD/DWS 增量写入）
    参数：ReplacingMergeTree(updated_at)，以 updated_at 作为版本字段
    工作原理：后台合并时按 ORDER BY 主键保留 updated_at 最大的行
    注意：查询未合并数据时需加 FINAL 关键字

  MergeTree
    适用：无需去重的静态追加型表（如复盘数据 dws_astock_review_daily_df）
    使用条件：上游已保证数据唯一，或数据性质为增量追加不覆盖

  SummingMergeTree
    适用：只需按某字段求和的统计表
    使用场景较少，大多数聚合场景用 ReplacingMergeTree + 视图更灵活

  VersionedCollapsingMergeTree
    适用：需要记录数据变更生命周期的表
    使用场景：极少，仅在需要追踪记录"新增→修改→删除"完整生命周期时使用

  View（普通视图）
    适用：分钟级聚合（15/30 分钟 K 线）、月 K 线
    不占物理存储，每次查询实时计算
    适合聚合逻辑简单、查询频率不高的场景

  MaterializedView（物化视图）
    适用：高频且固定的聚合查询
    需要设计底层的目标表
    适合查询频率极高、数据量大、聚合逻辑固定的场景


📌 表结构设计规范

  命名规范：
    物理表：{层级}_{主题}_{数据粒度}[_来源标识]
    视图：ods_vw_{主题}_{粒度}_df
    示例：
      ods_astock_daily_his_df       → ODS 日 K 原始
      dwd_astock_daily_adj_df       → DWD 日 K 前复权
      dws_astock_sentiment_factors_daily_df → DWS 情绪因子
      ods_vw_astock_15min_df        → 15 分钟 K 线视图

  命名禁则：
    ❌ 驼峰命名（AstockDailyHis）
    ❌ 下划线开头（_ods_astock_daily）
    ❌ 表名加版本号（ods_astock_daily_v2）→ 用影子表过渡
    ❌ 空格、中文、特殊字符

  必备字段（每张表都必须有）：
    created_at    DateTime   DEFAULT now()   → 记录创建时间
    updated_at    DateTime   DEFAULT now()   → ReplacingMergeTree 版本字段

  核心业务字段标准：
    trade_date    Date        交易日期（日级，格式 YYYY-MM-DD）
    trade_time    DateTime    交易时间（分钟/秒级，完整时间戳）
    ts_code       String      证券代码（带交易所后缀：000001.SZ）
    open/high/low/close  Float32  价格（元）
    vol           Float64     成交量（不是 volume）
    amount        Float64     成交额（元）
    pct_chg       Float32     涨跌幅（%）
    adj_factor    Float32     复权因子
    *_adj 后缀               复权后字段（close_adj, vol_adj）

  字段类型规范：
    价格（元）→ Float32（精度足够，节省存储）
    成交量/成交额 → Float64（数值大，Float32 溢出风险）
    计数（家数/次数）→ UInt32（非负整数）
    代码/名称 → String
    高重复度字符串（ts_code, source, status）→ LowCardinality(String)


📌 分区与索引设计

  分区策略（PARTITION BY）：
    行情类表：按月分区 PARTITION BY toYYYYMM(trade_date)
    基础信息表：不分区或按年分区
    重要禁则：分区字段不得出现在 ORDER BY 中

  排序键设计（ORDER BY）：
    ReplacingMergeTree 中 ORDER BY 包含所有业务标识字段
    金融时序查询通常基于"标的 + 时间"
    推荐：ORDER BY (ts_code, trade_date) 或 ORDER BY (ts_code, trade_time)
    因子值表：ORDER BY (factor_name, ts_code, trade_date)
    禁止：仅用单一字段（ts_code）或仅用 updated_at 作为 ORDER BY

  LowCardinality 优化：
    对重复度极高的字段必须使用 LowCardinality(String)
    典型字段：ts_code、source、status、board_type
    效果：大幅压缩存储、显著提升查询和聚合速度


📌 视图设计

  使用原则：
    分钟级聚合（15/30 分钟 K 线）和月 K 线统一使用普通 View
    视图只进行不丢失信息的聚合（OHLCV），不做额外清洗
    视图的 ORDER BY 必须为 (ts_code, trade_time/trade_date)
    数据来源为 DWD 层前复权物理表

  聚合逻辑模板（15 分钟 K 线）：
    SELECT
      ts_code,
      toStartOfInterval(trade_time, INTERVAL 15 MINUTE) AS trade_time,
      argMin(open_adj, trade_time) AS open,
      max(high_adj) AS high,
      min(low_adj) AS low,
      argMax(close_adj, trade_time) AS close,
      sum(vol_adj) AS vol,
      sum(amount) AS amount
    FROM dwd_astock_1min_price_adj_df
    GROUP BY ts_code, trade_time

  联合视图（冷热合并）：
    ods_vw_astock_1min_price_his_df = hot UNION ALL cold
    对外提供统一查询入口，屏蔽冷热分区细节


📌 冷热分离策略

  热数据（SSD）：
    近期高频访问的数据（2021 年至今）
    存储在 ods_astock_1min_price_his_hot
    用于回测、策略研究、实时分析

  冷数据（HDD）：
    历史低频访问的数据（2021 年之前）
    存储在 ods_astock_1min_price_his_cold
    用于长周期回测、合规审计

  查询入口：
    联合视图 ods_vw_astock_1min_price_his_df 透明合并
    应用层无需感知冷热分区


📌 性能调优

  查询优化：
    利用分区裁剪：WHERE trade_date >= '2025-01-01' 自动跳过无关分区
    利用排序键：WHERE ts_code = '000001.SZ' AND trade_date = '2025-01-15' 精确命中
    避免 SELECT *：只查询需要的列（列式存储的核心优势）
    大结果集用 LIMIT 限制，避免客户端 OOM

  写入优化：
    批量写入：每次 >= 1 万行
    避免高频小批次：ClickHouse 对碎片写入极其敏感
    async_insert = 1：让 ClickHouse 自动缓冲
    禁止 ALTER DELETE/UPDATE：用 ReplacingMergeTree 代替

  存储优化：
    LowCardinality 压缩高重复字段
    合理分区粒度（按月，不是按天——分区太多影响合并性能）
    定期 OPTIMIZE TABLE ... FINAL 触发合并（低峰期执行）


📌 数仓平台产出物清单
  表 DDL 定义（含注释、约束、引擎、分区、排序键）
  引擎选型决策记录（为什么用这个引擎）
  视图定义（聚合逻辑、数据来源）
  冷热分离方案文档
  性能基线报告（关键查询的执行时间）
  数据字典更新（每个字段的含义和规则）
