---
name: database-engineering
description: 数据库工程能力——Schema 设计模式、索引策略、查询优化、缓存实现、数据迁移、ETL 管道。当任务涉及数据库表设计、SQL 优化、缓存策略、数据管道实现时激活。扩展支持 MongoDB 复合索引与高级聚合管道调优。
---

💾 数据库工程（Database Engineering）
核心问题：数据怎么存？怎么查得快？怎么改得安全？


📌 Schema 设计原则

  关系型数据库命名规范：
    表名：小写复数（users, orders, order_items）
    字段名：小写下划线（created_at, user_id, is_active）
    索引名：idx_{表名}_{字段名}（idx_users_email）
    约束名：fk_{表名}_{引用表名}（fk_orders_users）

  关系型数据库必备字段（每张表都要有）：
    id            主键，UUID 或自增 BIGINT（推荐 UUID 避免信息泄漏）
    created_at    创建时间，TIMESTAMP WITH TIME ZONE，默认 NOW()
    updated_at    更新时间，TIMESTAMP WITH TIME ZONE，默认 NOW()，触发器自动更新

  软删除 vs 硬删除：
    软删除（推荐大多数场景）：
      添加 deleted_at TIMESTAMP WITH TIME ZONE NULL
      所有查询默认加 WHERE deleted_at IS NULL
      索引也加这个条件（部分索引）
      好处：可恢复、有审计记录、外键不会断
    硬删除（特定场景）：
      日志类数据过期清理
      合规要求必须彻底删除的个人数据（GDPR）
      大量临时数据（购物车草稿等）

  关系型数据类型选择：
    金额     → DECIMAL(10,2)，绝对不用 FLOAT/DOUBLE（精度丢失）
    枚举状态  → VARCHAR + CHECK 约束，不用数据库 ENUM（难以迁移）
             或独立状态表（状态多且可能变化时）
    JSON 数据 → JSONB（PostgreSQL），带 GIN 索引
             只用于扩展属性，核心字段必须是独立列
    时间     → TIMESTAMP WITH TIME ZONE，永远存 UTC
    IP 地址  → INET 类型（PostgreSQL），不用 VARCHAR
    手机号   → VARCHAR(20)，带格式校验约束


📌 MongoDB 设计与调优规范

  1. 文档型 Schema 设计原则：
    - 权衡 嵌入（Embedding） vs 引用（Referencing）：
      - 嵌入：1:1 或 1:N（且子对象数量受限，如 <100 个），高内聚，单文档读写效率极高。
      - 引用：1:N（子对象持续增长，如订单项、系统日志）或 M:N，防止单个 BSON 文档突破 16MB 物理限制。
    - 严格避免深度嵌套：文档嵌套层级控制在 3 层以内，越深查询及索引设计越痛苦。

  2. 复合索引与最左前缀：
    - 在创建复合索引 `db.coll.createIndex({ a: 1, b: 1, c: -1 })` 时，严格匹配查询的最左前缀原则。
    - 组合键选择：将等值（Equality）过滤字段排在索引首位，排序（Sort）字段排在第二位，范围（Range）过滤字段排在最后。

  3. 聚合管道调优（Aggregation Pipeline Tuning）：
    - **前置过滤**：必须在 Pipeline 的最开始阶段使用 `$match`，确保尽早过滤掉不相关数据，且该 match 能高效走到索引路由，杜绝全表扫描。
    - **精简内存**：及早使用 `$project` 剔除无关字段，降低网络和内存吞吐。
    - **严防内存崩溃**：MongoDB 聚合管道单阶段物理内存限制为 100MB，如果处理大数据集，必须在聚合中加入 `{ allowDiskUse: true }` 选项以允许磁盘临时缓存，或者通过合理的分页与 `$limit` 规避。


📌 索引策略

  什么时候加索引：
    WHERE / $match 条件中频繁出现的列
    JOIN / $lookup 的关联列
    ORDER BY / $sort 的列
    唯一性约束（UNIQUE 自动创建索引）

  什么时候不加索引：
    表数据量 < 1000 行（全表扫描更快）
    更新极频繁、查询极少的列
    选择性极低的列（如 gender 只有 2-3 个值）
    除非它和高选择性列组合使用

  组合索引设计（最左前缀原则）：
    查询 WHERE a = ? AND b = ? ORDER BY c
    索引 (a, b, c) — 三个条件都能命中
    索引 (b, a, c) — 也行，等值条件的顺序无所谓
    索引 (c, a, b) — 不行，c 在最左但它是范围/排序条件

    口诀：等值条件在前，范围条件在后，排序字段放最后

  部分索引（Partial Index）：
    只索引你查询的子集，更小更快
    示例：活跃用户索引
      CREATE INDEX idx_users_email_active ON users(email) WHERE deleted_at IS NULL AND is_active = true;
    适用：软删除场景、状态过滤场景、只查最近数据的场景

  覆盖索引（Covering Index）：
    把查询需要的所有列都放进索引，避免回表
    示例：
      查询 SELECT id, name, price FROM products WHERE category_id = ?
      索引 CREATE INDEX idx_products_category_cover ON products(category_id) INCLUDE (name, price);
    适用：高频查询、列数少、表很大的场景


📌 查询优化

  N+1 问题（最常见的性能杀手）：
    症状：查 1 次列表 + N 次关联查询
    示例（伪代码）：
      orders = SELECT * FROM orders WHERE user_id = 123
      for order in orders:
          items = SELECT * FROM order_items WHERE order_id = order.id  ← 循环查询！
    解法：
      方案 A：JOIN 一次查出（适合一对一、一对多且量不大）
        SELECT o.*, oi.* FROM orders o JOIN order_items oi ON o.id = oi.order_id WHERE o.user_id = 123
      方案 B：IN 查询（适合多对多或 ORM 场景）
        order_ids = SELECT id FROM orders WHERE user_id = 123
        SELECT * FROM order_items WHERE order_id IN (order_ids)
      方案 C：ORM 的 eager loading / preload

  慢查询排查流程：
    1. 开启慢查询日志（SQL 阈值 100ms，MongoDB 开启 Profiler 阈值 100ms）
    2. SQL 用 EXPLAIN ANALYZE，MongoDB 用 `explain("executionStats")` 查看执行计划
    3. 看是否有 Seq Scan / COLLSCAN（全表扫描）→ 需要索引
    4. 看是否有 Nested Loop 且外层行数多 → 考虑 JOIN 顺序或索引
    5. 看 actual rows vs planned rows 差距大 → 统计信息过期，ANALYZE
    6. 看是否有 Sort 使用了磁盘 → work_mem 不够或加排序索引
    7. 检查 MongoDB 执行统计中的 `totalKeysExamined` 与 `nReturned`，理想状态两者比例接近 1:1

  常见查询优化模式：
    避免 SELECT * → 只查需要的列
    避免 LIKE '%keyword%' → 用全文索引（to_tsvector + GIN）
    避免大 OFFSET 分页 → 用游标分页（WHERE id > last_id LIMIT 20）
    避免隐式类型转换 → 查询参数类型和列类型一致
    COUNT 优化 → 精确数不重要时用估算（pg_class.reltuples）


📌 缓存策略

  缓存模式选择：

    Cache-Aside（旁路缓存，最常用）
      读：先查缓存 → 未命中 → 查数据库 → 写入缓存 → 返回
      写：更新数据库 → 删除缓存（不是更新缓存）
      适用：读多写少，能接受短暂不一致
      坑：删除缓存和更新数据库不是原子的 → 用延迟双删或订阅 binlog

    Read-Through / Write-Through
      读写都经过缓存层，缓存层负责和数据库同步
      适用：缓存层有中间件支持（如 Hibernate L2 Cache）
      好处：业务代码无感知

    Write-Behind（异步写回）
      写入缓存后立即返回，异步批量写数据库
      适用：写入量大、允许短暂数据丢失风险
      风险：宕机可能丢数据

  缓存常见问题：

    缓存穿透（查不存在的数据）
      症状：恶意或错误请求不存在的 key，每次都打到数据库
      解法：布隆过滤器拦截 / 缓存空值（设短过期时间）

    缓存击穿（热点 key 过期）
      症状：热点 key 过期瞬间，大量并发请求同时打到数据库
      解法：互斥锁（singleflight）只放一个请求去数据库 / 热点 key 永不过期 + 异步刷新

    缓存雪崩（大量 key 同时过期）
      症状：缓存大面积失效，数据库被打垮
      解法：过期时间加随机抖动（base_ttl + random(0, 300s)）

  缓存 Key 设计：
    格式：{service}:{entity}:{id}:{version}
    示例：order:detail:12345:v2
    TTL 参考：热数据 5-15 分钟，温数据 1-4 小时，冷数据 24 小时


📌 数据迁移

  迁移安全规则：
    每次迁移都有对应的回滚脚本
    先加列后删列，永远不在一个迁移里改列名（先加新列 → 双写 → 迁移数据 → 删旧列）
    大表加索引用 CONCURRENTLY（PostgreSQL），避免锁表
    生产迁移必须在低峰期执行
    迁移前备份，迁移后验证数据完整性

  零停机 Schema 变更流程：
    1. 加新列/新表（兼容旧代码）
    2. 部署新代码（同时读写新旧结构）
    3. 迁移历史数据（后台异步）
    4. 验证数据一致性
    5. 部署仅使用新结构的代码
    6. 清理旧列/旧表（确认稳定后）


📌 数据管道 / ETL

  设计原则：
    幂等性：同一批数据跑两次结果一样
    可恢复性：失败后能从断点续跑，不需要从头开始
    可观测性：每一步有计数（输入行数、输出行数、跳过行数、错误行数）
    可回滚性：保留原始数据，加工结果可以重建

  CDC（Change Data Capture）模式：
    订阅数据库 binlog / WAL，捕获数据变更
    通过消息队列投递到下游系统
    适用：实时数据同步、构建物化视图、喂数据仓库
    工具：Debezium（通用）、Maxwell（MySQL）、pg_logical（PostgreSQL）

  批处理 vs 流处理：
    批处理（T+1）：数据量大、时效性要求不高、逻辑复杂 → Spark / dbt
    流处理（实时）：延迟敏感、事件驱动、增量更新 → Flink / Kafka Streams
    Lambda 架构（两者都要）：批处理保底 + 流处理加速，但维护成本翻倍
    Kappa 架构（只用流）：所有数据走流处理，重放历史数据时重新消费 Kafka


📌 数据库工程产出物清单
  - Schema DDL / MongoDB Index Scripts（含注释、约束、索引）
  - 数据字典（每个表每个字段的含义和规则）
  - 索引分析报告（现有索引的使用率和建议）
  - 迁移脚本 + 回滚脚本
  - 缓存策略文档（Key 规范、TTL、失效方式）
  - 慢查询解释计划优化记录对比
