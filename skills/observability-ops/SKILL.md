---
name: 可观测性运维
description: 用于以下场景：可观测性体系建设与 SRE 运维——涉及监控 / 告警 / 日志聚合 / 链路追踪、Nginx 高性能安全网关加固、SRE 磁盘容量防护与日志滚动策略、自愈系统。任务涉及监控配置、告警设计、日志分析、故障排查、事件响应时激活。
---

# 可观测性运维

## 概述

系统现在健康吗？出问题能多快发现？**可观测性不是装几个面板，而是"指标 + 日志 + 链路 + 告警 + Runbook + 自愈"六位一体。**

## 何时使用

- Prometheus / Grafana 监控体系搭建
- 告警规则设计与 Runbook 编写
- 日志聚合（结构化 JSON、敏感信息脱敏）
- 分布式链路追踪（OpenTelemetry / Jaeger）
- Nginx 高性能反向代理安全加固
- SRE 磁盘容量防护与日志自动滚动
- 自愈系统（livenessProbe、HPA、磁盘清理脚本）

**不要用于：** CI/CD 流水线（用 `cicd-engineering`）、数据库性能调优（用 `database-engineering`）、K8s 资源配置（用 `infrastructure-automation`）、质量门禁（用 `quality-gate`）。

## Nginx 高性能安全网关加固

### 1. 连接与超时管理

精确设置超时参数，严防慢速连接死霸 Nginx 及后端服务连接池。

```nginx
keepalive_timeout  65;
client_body_timeout 15;
client_header_timeout 15;
send_timeout 15;
```

### 2. 缓冲区与 Payload 限制

调优读写缓冲区，防止时序高频大负荷 Tick 传输时频繁触发磁盘临时文件读写导致性能雪崩。

```nginx
client_body_buffer_size 128k;
client_max_body_size 10m;       # 限制大体量文件上传
client_header_buffer_size 1k;
large_client_header_buffers 4 4k;
```

### 3. SSL/TLS & CORS 标头硬化

强制使用 TLS 1.2 / TLS 1.3 安全子集，封堵过期加密协议。

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
```

精确配置 CORS 安全跨域：**禁止通配符 `*` 泄露机密**，明确白名单源并透传 `X-Request-Id` 用于链路追踪。

## SRE 磁盘容量防护与日志滚动

### 1. 容器级别日志限流

Docker Compose 或 K8s 部署必须强制指定日志驱动的最大上限，拒绝日志无限期膨胀打满物理机磁盘。

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "50m"
    max-file: "5"
```

### 2. 系统级 logrotate 配置

针对非容器化服务（独立部署的 MongoDB / Nginx），在 `/etc/logrotate.d/` 下部署严格的按天滚动、自动压缩配置。

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

## 可观测性三支柱

| 支柱 | 内容 | 工具 |
|---|---|---|
| **Metrics（指标）** | 基础设施：CPU、内存、磁盘、网络；应用：QPS、延迟分布（p50/p95/p99）、错误率；业务：因子计算成功数、SLA 达标率 | Prometheus + Grafana |
| **Logs（日志）** | 结构化 JSON，透传 traceId；敏感信息（密码、Token）通过中间件正则脱敏后方可落盘 | ELK / Loki |
| **Traces（链路追踪）** | 跨服务调用的完整链路可视化，每个请求有全局唯一的 traceId | OpenTelemetry / Jaeger |

## 告警分级

| 级别 | 响应时效 | 适用 |
|---|---|---|
| **P0** | 5 分钟内 | 核心服务完全不可用、数据一致性断裂 |
| **P1** | 1 小时内 | 非核心服务异常、性能严重退化 |
| **P2** | 当天处理 | 磁盘空间预警（> 80% 预警，> 90% 自愈） |

**告警规则设计原则：**

| 原则 | 说明 |
|---|---|
| 基于 SLO 告警 | 不是基于资源阈值（如 CPU 80%） |
| 配套 Runbook | 每条告警必须有可执行的 Runbook 指南 |

## Runbook 模板

```markdown
## Runbook: [告警名称]

### 告警含义
这条告警说明什么问题？影响范围是什么？

### 排查步骤
1. 查看 Grafana Dashboard [链接]，确认指标异常范围
2. 查看日志 [链接/命令]，搜索错误关键字
3. 检查最近的部署记录 [链接]
4. 检查依赖服务状态

### 恢复操作
- 回滚最近部署 / 实例扩容 / 启动降级逻辑

### 升级路径
- 15 分钟未恢复自动升级至二级负责人
```

## 自愈系统

| 触发条件 | 自愈动作 |
|---|---|
| K8s `livenessProbe` 失败 | 自动重启容器 |
| 磁盘空间告警 | 自动触发日志临时目录清理、高频临时 Tick 缓存归档，并发出自愈通知 |
| 并发与连接队列饱和 | HPA 自动横向拉起实例（自动弹性伸缩） |

## 指标采集与展示规范

| 指标分类 | 必采指标 | 告警阈值参考 |
|---|---|---|
| 基础设施 | CPU 使用率、内存使用率、磁盘使用率、网络 IO | CPU > 80% 持续 5 分钟；磁盘 > 80% 预警 |
| 应用 | QPS、p50/p95/p99 延迟、错误率、饱和度 | 错误率 > 1%；p99 延迟超 SLO |
| 业务 | 因子计算成功率、采集任务完成率、回测执行数 | 业务相关 SLO |

**黄金信号（Four Golden Signals）：** Latency、Traffic、Errors、Saturation。

## 常见错误

| 错误做法 | 正确做法 |
|---|---|
| 容器日志无 max-size 限制 | 强制 `max-size: 50m` + `max-file: 5` |
| 物理机部署无 logrotate 配置 | `/etc/logrotate.d/` 严格按天滚动 |
| 告警基于资源阈值（CPU 80%） | 告警基于 SLO（错误率、延迟） |
| 告警没有 Runbook | 每条告警必须配套可执行 Runbook |
| 敏感信息明文写入日志 | 中间件正则脱敏后再落盘 |
| CORS 配置 `*` 通配符 | 明确白名单源 |
| TLS 协议允许 SSLv3 / TLS 1.0 | 仅允许 TLSv1.2 / TLSv1.3 |
| `client_max_body_size` 不设或过大 | 限制为业务实际所需 |
| 自愈脚本无通知 | 自愈动作必须发出通知（避免静默） |
| 监控 / 告警 / 部署配置脱节 | 监控即代码，与服务同步启动 |

## 产出物清单

- [ ] Nginx 高性能反向代理安全加固配置文件
- [ ] Logrotate 磁盘保护日志自动滚动规则
- [ ] Prometheus / Grafana 指标监控大屏定义
- [ ] 核心告警策略规则与对应 Runbook 故障恢复指南
- [ ] 故障自愈（Auto-healing）脚本与探针规则配置说明
- [ ] 告警通知渠道配置（PagerDuty / 钉钉 / 飞书 / 企微）
- [ ] 链路追踪采样策略与 traceId 透传规范
