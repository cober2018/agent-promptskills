---
name: observability-ops
description: 可观测性运维能力——监控体系搭建、告警设计与Runbook、日志聚合、分布式链路追踪、事件响应、自愈系统。当任务涉及监控配置、告警设计、日志分析、故障排查、事件响应时激活。扩展支持 Nginx 高性能网关加固调优与 SRE 磁盘容量日志自动旋转滚动策略。
---

📡 可观测性运维（Observability & Operations）
核心问题：系统现在健康吗？出了问题能多快发现？如何防范日志撑爆磁盘？网关配置是否足够强韧？


📌 Nginx 高性能安全网关加固

  1. 连接与超时管理：
    - 精确设置超时参数，严防慢速网络连接死死霸占 Nginx 及后端服务连接池：
      ```nginx
      keepalive_timeout  65;
      client_body_timeout 15;
      client_header_timeout 15;
      send_timeout 15;
      ```

  2. 缓冲区与 Payload 限制（Buffering & Limits）：
    - 调优读写缓冲区，防止时序高频大负荷 Tick 传输时频繁触发磁盘临时文件读写导致性能雪崩：
      ```nginx
      client_body_buffer_size 128k;
      client_max_body_size 10m; # 限制大体量文件上传
      client_header_buffer_size 1k;
      large_client_header_buffers 4 4k;
      ```

  3. 高安全性 SSL/TLS & CORS 标头硬化：
    - 强制使用 TLS 1.2 / TLS 1.3 安全子集，封堵过期加密协议：
      ```nginx
      ssl_protocols TLSv1.2 TLSv1.3;
      ssl_prefer_server_ciphers on;
      ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
      ```
    - 精确配置 CORS 安全跨域，禁止通配符 `*` 泄露机密，明确白名单源并透传 `X-Request-Id` 用于链路追踪。


📌 SRE 磁盘容量防护与日志滚动（Log Rotation）

  1. 容器级别日志限流限制：
    - 在 Docker Compose 或 K8s 中部署时，必须强制指定日志驱动的最大上限，拒绝日志无限期膨胀打满物理机磁盘：
      ```yaml
      logging:
        driver: "json-file"
        options:
          max-size: "50m"
          max-file: "5"
      ```

  2. 系统级 `logrotate` 配置：
    - 针对非容器化服务（如独立部署的 MongoDB/Nginx 日志），在 `/etc/logrotate.d/` 下部署严格的按天滚动、自动压缩配置：
      ```text
      /var/log/myapp/*.log {
          daily
          rotate 14
          compress
          delaycompress
          missingok
          notifempty
          create 0660 appuser appgroup
          sharedscripts
          postrotate
              /usr/bin/killall -HUP myapp
          endscript
      }
      ```


📌 可观测性三支柱

  Metrics（指标）：
    基础设施指标：CPU、内存、磁盘、网络
    应用指标：QPS、延迟分布（p50/p95/p99）、错误率
    业务指标：因子计算成功数、SLA 达标率
    工具：Prometheus + Grafana

  Logs（日志）：
    格式：结构化 JSON，透传 traceId。
    敏感信息过滤：密码、Token 字段必须通过中间件正则脱敏后方可落盘。

  Traces（链路追踪）：
    跨服务调用的完整链路可视化，每个请求有全局唯一的 traceId。


📌 告警设计

  告警分级：
    P0（立即响应，5 分钟内）：核心服务完全不可用、数据一致性断裂。
    P1（1 小时内响应）：非核心服务异常、性能严重退化。
    P2（当天处理）：磁盘空间预警（超过 80% 触发预警，超过 90% 触发自愈）。

  告警规则设计原则：
    基于 SLO 告警，不是基于资源阈值。
    每条告警必须有可执行的 Runbook 指南。


📌 Runbook 模板

  Runbook: [告警名称]

  告警含义：
    这条告警说明什么问题？影响范围是什么？

  排查步骤：
    1. 查看 Grafana Dashboard [链接]，确认指标异常范围
    2. 查看日志 [链接/命令]，搜索错误关键字
    3. 检查最近的部署记录 [链接]
    4. 检查依赖服务状态

  恢复操作：
    - 回滚最近部署 / 实例扩容 / 启动降级逻辑

  升级路径：
    - 15分钟未恢复自动升级至二级负责人。


📌 自愈系统

  自动恢复机制：
    K8s livenessProbe 失败 $\rightarrow$ 自动重启容器
    磁盘空间告警 $\rightarrow$ 自动触发日志临时目录清理、高频临时 Tick 缓存归档，并发出自愈通知
    自动弹性伸缩（HPA） $\rightarrow$ 依据并发与连接队列饱和度自动横向拉起实例


📌 可观测性运维产出物清单
  - Nginx 高性能反向代理安全加固配置文件
  - Logrotate 磁盘保护日志自动滚动规则
  - Prometheus / Grafana 指标监控大屏定义
  - 核心告警策略规则与对应 Runbook 故障恢复指南
  - 故障自愈（Auto-healing）脚本与探针规则配置说明
