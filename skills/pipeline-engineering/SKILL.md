---
name: 管线工程
description: 用于以下场景：数据采集与 ETL/ELT 管线开发——涉及采集脚本、ODS→DWD→DWS→ADS 四级分层、CDC / 增量加载、调度编排、幂等写入、ClickHouse 写入优化。适配 ClickHouse + Tushare / AmazingData 金融数仓场景。任务涉及数据采集、管线开发、ETL/ELT 实现时激活。
---

# 管线工程

## 概述

数据怎么从源头流到消费方？**不丢不重是关键，幂等是底线。** 管线工程负责把 Tushare / AmazingData / AKShare 等异构数据源按四级分层（ODS→DWD→DWS→ADS）稳定地搬运到 ClickHouse。

## 何时使用

- 采集脚本开发（Tushare / AmazingData / AKShare 等数据源）
- ODS→DWD→DWS→ADS 四级管线实现
- 字段映射与类型转换
- CDC / 增量加载策略
- 调度编排与依赖管理（Cron + DAG）
- 幂等写入保证（ReplacingMergeTree 替代 Mutation）
- 1 分钟 K 线数据生命周期（实时 → 热表 → 冷表 → Redis 缓存）

**不要用于：** 数仓表结构与引擎选型（用 `lakehouse-platform`）、数据质量校验（用 `data-quality`）、数据库 SQL 优化（用 `database-engineering`）、监控告警（用 `observability-ops`）。

## 采集脚本开发流程

| 步骤 | 内容 |
|---|---|
| 1 | 确定数据源（Tushare / AmazingData / AKShare） |
| 2 | 查询数据字典与开发规范，确认目标 ODS 表是否已存在 |
| 3 | 若已有表 → 对比字段映射，确认是否需要新增字段 |
| 4 | 新建表 → 参考数仓开发规范设计表结构（ReplacingMergeTree + 分区 + 排序键） |
| 5 | 编写 Python 采集脚本（包含字段映射与幂等写入逻辑） |
| 6 | 自检：语法检查 → 导入测试 → 边缘与极端情况测试 |
| 7 | 更新数据字典与字段标准 |

### 字段映射规范

采集脚本在写入数据前，必须输出精确映射关系：**源字段名 → 标准字段名 → 类型转换 → 备注**。

| 示例源字段 | 标准字段 | 类型转换 | 备注 |
|---|---|---|---|
| `TOTAL_VOLUME` | `vol` | Float64 | 原始单位为万手，需乘 10000 |
| `trade_date` | `trade_date` | Date | YYYYMMDD 字符串转换为 Date |

## 四级管线架构

### ODS 管线（原始采集）

| 属性 | 说明 |
|---|---|
| 职责 | 从数据源获取原始数据，零转换写入 |
| 写入策略 | 只追加，不修改历史 |
| 幂等保证 | `ReplacingMergeTree(updated_at)` + `ORDER BY` 主键自动去重 |
| 元数据捕获 | `source_system`、`ingested_at`、`source_file` |
| Schema 演化 | `mergeSchema = true`，告警但不阻塞 |
| 分区策略 | 按月分区 `PARTITION BY toYYYYMM(trade_date)` |

**项目实例：**

| 调度时间 | 数据源 | 目标表 |
|---|---|---|
| 每日 15:30 | AmazingData 采集全市场 1 分钟 K 线 | `ods_astock_1min_price_amz_df` |
| 每日 16:00 | Tushare 采集日 K / 财务 | `ods_astock_daily_his_df` |
| 每日 16:30 | Tushare 采集涨停板 / 融资融券 | `ods_astock_limit_board_ak_df` |

### DWD 管线（清洗与标准化）

| 属性 | 说明 |
|---|---|
| 职责 | 字段标准化、类型统一、前复权计算、去重 |
| 关键输出 | **前复权物理表**（不是动态视图） |
| 前复权价格公式 | `前复权价格 = 原始价格 × 当日复权因子` |
| 前复权成交量公式 | `前复权成交量 = 原始成交量 / 当日复权因子` |
| 写入策略 | 每日覆盖当日数据，`ReplacingMergeTree` 保证幂等 |
| 调度窗口 | 19:30 开始 |

**项目实例：**

| 源表 | 目标表 |
|---|---|
| `ods_astock_daily_his_df` | `dwd_astock_daily_adj_df`（日 K 前复权） |
| `ods_astock_1min_price_amz_df` | `dwd_astock_1min_price_adj_df`（1 分钟前复权） |

### DWS 管线（聚合）

| 属性 | 说明 |
|---|---|
| 职责 | 按交易日 / 标的 / 行业聚合跨表指标 |
| 典型输出 | 市场宽度、情绪因子、板块涨跌 |
| 调度窗口 | 20:00 开始，同一层内任务间隔 5 分钟错峰 |

**项目实例：**

| 目标表 | 用途 |
|---|---|
| `dws_astock_date_daily_measures_df` | 市场宽度：上涨 / 下跌家数 |
| `dws_astock_sentiment_factors_daily_df` | 情绪因子：涨停强度、封板率 |

### ADS 管线（应用）

| 属性 | 说明 |
|---|---|
| 职责 | 直接服务于业务场景（因子值、策略信号） |
| 写入方式 | 由业务触发（因子计算、策略回测） |
| 调度窗口 | 20:30 开始 |

**项目实例：**

| 目标表 | 用途 |
|---|---|
| `ads_factor_value_df` | 因子数值矩阵 |
| `ads_strategy_signal_df` | 策略信号与交易记录 |

## 调度依赖链

```text
ODS 采集（15:30-19:00）
    ↓
DWD 清洗（19:30）← 依赖 ODS 数据就绪
    ↓
DWS 聚合（20:00）← 依赖 DWD 物理表计算完成
    ↓
ADS 应用（20:30）← 依赖 DWS 因子数据就绪
```

### 调度规则

| 规则 | 说明 |
|---|---|
| 交易日执行 | 行情类管线（Cron 中用 `1-5` 限制工作日） |
| 全天候 | 新闻 / 舆情类任务可全天候运行 |
| 失败暂停 | 上游失败时暂停下游任务并告警 |
| 错误日志 | 计算失败时记录错误日志，保留原始数据 |

## ClickHouse 写入优化

### 严禁高频小批次写入

ClickHouse 对大量小批次插入极其敏感。

| 策略 | 适用 |
|---|---|
| **A（推荐）** | 应用层攒齐 1 万条以上再统一 INSERT |
| **B** | 开启 `async_insert = 1`，ClickHouse 自动缓冲 |
| **C** | 极致实时场景引入 Kafka，通过 Kafka 引擎表批量消费 |

### 严禁高频 ALTER DELETE/UPDATE

ClickHouse 的 Mutations 是极度沉重的异步操作。

| 替代方案 | 适用 |
|---|---|
| **A（推荐）** | `ReplacingMergeTree` 直接 INSERT 覆盖 |
| **B** | 大规模重刷时 `DROP PARTITION` 然后重新插入 |

### 规避内存瓶颈

| 手段 | 说明 |
|---|---|
| 批次处理 | 每 5-10 万行执行一次 `insert_df` |
| ELT 替代 ETL | Python 只投递到 ODS，转换逻辑在 ClickHouse 内部执行 |

## 1 分钟 K 线数据生命周期

| 层级 | 存储位置 | 数据范围 |
|---|---|---|
| 实时层 | `ods_astock_1min_price_amz_df` | 当天盘中实时写入，收盘后不再更新 |
| 热表 | `ods_astock_1min_price_his_hot` | 每日收盘后接收合并数据，2021 年至今，SSD |
| 冷表 | `ods_astock_1min_price_his_cold` | 2010-2021 历史数据，HDD |
| 查询入口 | `ods_vw_astock_1min_price_his_df` | 联合 hot + cold 提供全量历史查询（UNION ALL 视图） |
| Redis 实时层 | `ods_astock_1min_price_rt:{ts_code}`（Sorted Set，48h TTL） | 实时行情 |

**降级策略：** Redis 不可用时回退为仅返回 ClickHouse 历史数据。

## 增量与全量策略

| 策略 | 适用 | 实现 |
|---|---|---|
| **增量写入** | 日级行情、财务数据 | 采集最新数据 → INSERT → `ReplacingMergeTree` 去重 |
| **全量重刷** | 复权因子更新、错误修复 | `DROP PARTITION` → 重新 INSERT |
| **CDC 订阅** | 业务数据库同步 | 订阅 binlog / WAL，通过消息队列投递 |
| **UPSERT** | 实时订单、状态变更 | `ReplacingMergeTree(version)` 按版本覆盖 |

## 常见错误

| 错误做法 | 正确做法 |
|---|---|
| 高频小批次写入（< 1 万行 / 次） | 攒批 ≥ 1 万行再 INSERT，或开 `async_insert` |
| 用 `ALTER DELETE/UPDATE` 修正数据 | 用 `ReplacingMergeTree` INSERT 覆盖 |
| Python 端做大量 ETL 转换 | ELT 模式：Python 投递 ODS，ClickHouse 内部转换 |
| 上游失败仍启动下游 | 上游失败时暂停下游任务并告警 |
| 没有字段映射直接采集 | 采集前必须输出字段映射表 |
| 行情类任务 7×24 运行 | 交易日才执行（`1-5` 工作日） |
| 冷热数据混在一张表 | 冷热分层 + 联合视图透明合并 |
| Redis 不可用导致整体失败 | 降级为仅返回 ClickHouse 历史数据 |
| 一次迁移改列名 | 先加新列 → 双写 → 迁移 → 删旧列 |

## 产出物清单

- [ ] 采集脚本（含字段映射表）
- [ ] 管线依赖图（DAG）
- [ ] 调度配置（Cron 表达式 + 依赖关系）
- [ ] 写入策略文档（引擎选择、批次大小、幂等机制）
- [ ] 数据生命周期说明（热 / 冷分区、TTL、归档策略）
- [ ] 运行手册（Runbook：什么会坏、怎么修、谁负责）
