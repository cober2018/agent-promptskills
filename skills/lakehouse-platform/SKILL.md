---
name: 数仓平台工程
description: 用于以下场景：ClickHouse 表结构设计与引擎选型、分区索引优化、冷热分离、视图设计、存储选型与性能调优——适配金融时序数据仓库场景。任务涉及建表、引擎选型、查询优化、存储架构设计时激活。
---

# 数仓平台工程

## 概述

金融时序数据怎么存、怎么查、怎么省？**数仓不是单纯的存储，而是为查询而生的分层结构。** ClickHouse 主导时序数据，MongoDB 兜底元数据，Redis 承接实时热点。

## 何时使用

- ClickHouse 表 DDL 设计（字段类型、分区、排序键）
- 引擎选型（ReplacingMergeTree / MergeTree / SummingMergeTree / View / MaterializedView）
- 分区策略与 ORDER BY 排序键设计
- 普通视图与物化视图设计
- 冷热数据分层与合并视图
- 查询性能调优（分区裁剪、LowCardinality 优化、批量写入）

**不要用于：** 数据采集与 ETL 脚本（用 `pipeline-engineering`）、数据质量门禁（用 `data-quality`）、数据库索引与 SQL 优化（用 `database-engineering`）。

## 存储系统分工

| 系统 | 库 | 定位 | 适用 | 数据量级 |
|---|---|---|---|---|
| ClickHouse | quant 库 | 列式存储，高吞吐写入，批量分析 | 日 K、分钟 K、因子值、融资融券、龙虎榜 | ODS 层 1400 万 ~ 18 亿行 |
| MongoDB | quantsystem | 文档型，灵活 Schema，低写入频次 | 用户、配置、调度任务、因子 / 策略定义、审批记录 | 元数据为主 |
| Redis | — | 内存型，高吞吐，自动过期 | 实时 1 分钟 K 线（48h TTL）、股票基础信息缓存、慢请求热点 | 短期热点 |

**降级策略：** Redis 不可用时回退为仅返回 ClickHouse 历史数据。

**历史遗留：** MongoDB 目前存了大量业务行情数据（stock_daily_quotes 等），后续应迁移至 ClickHouse。

## 引擎选型速查

| 引擎 | 适用 | 关键参数 | 备注 |
|---|---|---|---|
| **ReplacingMergeTree** | 有主键去重需求的表（ODS/DWD/DWS 增量写入） | `ReplacingMergeTree(updated_at)`，以 `updated_at` 作为版本字段 | 90%+ 场景默认选择；查询未合并数据需加 `FINAL` 关键字 |
| **MergeTree** | 无需去重的静态追加型表 | — | 适用于复盘数据 `dws_astock_review_daily_df`；上游已保证唯一或仅追加不覆盖 |
| **SummingMergeTree** | 只需按某字段求和的统计表 | — | 使用场景较少；大多数聚合用 `ReplacingMergeTree` + 视图更灵活 |
| **VersionedCollapsingMergeTree** | 需要记录数据变更生命周期的表 | — | 极少使用；仅追踪"新增→修改→删除"完整生命周期时使用 |
| **View（普通视图）** | 分钟级聚合（15/30 分钟 K 线）、月 K 线 | — | 不占物理存储，每次查询实时计算；适合聚合逻辑简单、查询频率不高 |
| **MaterializedView（物化视图）** | 高频且固定的聚合查询 | 需设计底层目标表 | 适合查询频率极高、数据量大、聚合逻辑固定 |

## 表结构设计规范

### 命名规范

| 类型 | 命名格式 | 示例 |
|---|---|---|
| 物理表 | `{层级}_{主题}_{数据粒度}[_来源标识]` | `ods_astock_daily_his_df`、`dwd_astock_daily_adj_df`、`dws_astock_sentiment_factors_daily_df` |
| 视图 | `ods_vw_{主题}_{粒度}_df` | `ods_vw_astock_15min_df` |

**命名禁则：**

| 禁则 | 正确做法 |
|---|---|
| 驼峰命名（`AstockDailyHis`） | 全小写下划线 |
| 下划线开头（`_ods_astock_daily`） | 直接以层级开头 |
| 表名加版本号（`ods_astock_daily_v2`） | 用影子表过渡 |
| 空格、中文、特殊字符 | 仅 `[a-z0-9_]` |

### 必备字段（每张表都必须有）

| 字段 | 类型 | 默认值 | 作用 |
|---|---|---|---|
| `created_at` | DateTime | `now()` | 记录创建时间 |
| `updated_at` | DateTime | `now()` | ReplacingMergeTree 版本字段 |

### 核心业务字段标准

| 字段 | 类型 | 说明 |
|---|---|---|
| `trade_date` | Date | 交易日期（日级，格式 YYYY-MM-DD） |
| `trade_time` | DateTime | 交易时间（分钟/秒级，完整时间戳） |
| `ts_code` | String | 证券代码（带交易所后缀：`000001.SZ`） |
| `open/high/low/close` | Float32 | 价格（元） |
| `vol` | Float64 | 成交量（不是 `volume`） |
| `amount` | Float64 | 成交额（元） |
| `pct_chg` | Float32 | 涨跌幅（%） |
| `adj_factor` | Float32 | 复权因子 |
| `*_adj` 后缀 | — | 复权后字段（如 `close_adj`、`vol_adj`） |

### 字段类型规范

| 数据 | 类型 | 理由 |
|---|---|---|
| 价格（元） | Float32 | 精度足够，节省存储 |
| 成交量 / 成交额 | Float64 | 数值大，Float32 溢出风险 |
| 计数（家数 / 次数） | UInt32 | 非负整数 |
| 代码 / 名称 | String | — |
| 高重复度字符串（`ts_code`、`source`、`status`） | `LowCardinality(String)` | 大幅压缩存储、提升查询聚合速度 |

## 分区与索引设计

### 分区策略（PARTITION BY）

| 表类型 | 分区策略 |
|---|---|
| 行情类表 | 按月分区 `PARTITION BY toYYYYMM(trade_date)` |
| 基础信息表 | 不分区或按年分区 |

**重要禁则：** 分区字段不得出现在 `ORDER BY` 中。

### 排序键设计（ORDER BY）

| 场景 | 推荐排序键 |
|---|---|
| 日级行情 | `ORDER BY (ts_code, trade_date)` |
| 分钟级行情 | `ORDER BY (ts_code, trade_time)` |
| 因子值表 | `ORDER BY (factor_name, ts_code, trade_date)` |

**禁则：** 禁止仅用单一字段（`ts_code`）或仅用 `updated_at` 作为 `ORDER BY`。`ReplacingMergeTree` 中 `ORDER BY` 须包含所有业务标识字段。

### LowCardinality 优化

对重复度极高的字段必须使用 `LowCardinality(String)`，典型字段：`ts_code`、`source`、`status`、`board_type`。

## 视图设计

### 使用原则

- 分钟级聚合（15/30 分钟 K 线）和月 K 线统一使用普通 View。
- 视图只进行不丢失信息的聚合（OHLCV），不做额外清洗。
- 视图的 `ORDER BY` 必须为 `(ts_code, trade_time/trade_date)`。
- 数据来源为 DWD 层前复权物理表。

### 聚合逻辑模板（15 分钟 K 线）

```sql
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
```

### 联合视图（冷热合并）

- `ods_vw_astock_1min_price_his_df = hot UNION ALL cold`
- 对外提供统一查询入口，屏蔽冷热分区细节。

## 冷热分离策略

| 层级 | 存储 | 数据范围 | 表 | 用途 |
|---|---|---|---|---|
| 热数据 | SSD | 近期高频访问（2021 年至今） | `ods_astock_1min_price_his_hot` | 回测、策略研究、实时分析 |
| 冷数据 | HDD | 历史低频访问（2021 年之前） | `ods_astock_1min_price_his_cold` | 长周期回测、合规审计 |
| 查询入口 | — | — | `ods_vw_astock_1min_price_his_df` 联合视图 | 透明合并热冷分区 |

应用层无需感知冷热分区。

## 性能调优

### 查询优化

| 手段 | 说明 |
|---|---|
| 分区裁剪 | `WHERE trade_date >= '2025-01-01'` 自动跳过无关分区 |
| 排序键命中 | `WHERE ts_code = '000001.SZ' AND trade_date = '2025-01-15'` 精确命中 |
| 列裁剪 | 避免 `SELECT *`，只查需要的列（列式存储核心优势） |
| 结果集限制 | 大结果集用 `LIMIT`，避免客户端 OOM |

### 写入优化

| 手段 | 说明 |
|---|---|
| 批量写入 | 每次 ≥ 1 万行 |
| async_insert | `async_insert = 1`，让 ClickHouse 自动缓冲 |
| 禁用 Mutation | 禁止 `ALTER DELETE/UPDATE`；用 `ReplacingMergeTree` 代替 |
| OPTIMIZE 合并 | 定期 `OPTIMIZE TABLE ... FINAL` 触发合并（低峰期执行） |

### 存储优化

| 手段 | 说明 |
|---|---|
| LowCardinality 压缩 | 高重复字段压缩存储 |
| 分区粒度 | 合理选择（按月，不是按天——分区太多影响合并性能） |

## 常见错误

| 错误做法 | 正确做法 |
|---|---|
| 用单一字段或 `updated_at` 作为 `ORDER BY` | `ORDER BY` 包含所有业务标识字段 |
| 分区字段出现在 `ORDER BY` 中 | 分区与排序键分离 |
| 行情表按天分区 | 行情表按月分区 |
| 高频 `ALTER DELETE/UPDATE` | 用 `ReplacingMergeTree` INSERT 覆盖 |
| 写入批次过小（< 1 万行） | 攒批 ≥ 1 万行再 INSERT |
| `SELECT *` 拉全列 | 按需查询列 |
| 价格用 Float64 | 价格用 Float32 节省存储 |
| 把分钟级 K 线建成物理表 | 用普通 View 实时计算 |
| 表名带版本号 | 影子表过渡，不在表名上标记版本 |

## 产出物清单

- [ ] 表 DDL 定义（含注释、约束、引擎、分区、排序键）
- [ ] 引擎选型决策记录（为什么用这个引擎）
- [ ] 视图定义（聚合逻辑、数据来源）
- [ ] 冷热分离方案文档
- [ ] 性能基线报告（关键查询的执行时间）
- [ ] 数据字典更新（每个字段的含义和规则）
