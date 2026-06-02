---
name: 基础设施自动化
description: 用于以下场景：基础设施即代码（IaC）与容器化——涉及 Docker 多阶段 Distroless 安全构建、镜像 Layer 缓存优化、Terraform / Pulumi、K8s 资源配置、多环境管理、密钥管理、成本优化。
---

# 基础设施自动化

## 概述

基础设施怎么搭？容器怎么构建得既安全又小巧？怎么控制成本？**基础设施是代码，镜像构建是艺术，安全左移是常识。**

## 何时使用

- Docker 多阶段构建（Distroless / Alpine）
- 容器非 root 用户安全加固
- 镜像 Layer 缓存优化
- Terraform / Pulumi IaC 编写
- K8s 资源配置（requests / limits / 探针）
- 多环境管理（dev / staging / prod）
- 密钥管理（Vault / Secrets Manager）
- 资源 Right-Sizing 成本优化

**不要用于：** CI/CD 流水线（用 `cicd-engineering`）、Nginx 网关调优（用 `observability-ops`）、监控告警（用 `observability-ops`）。

## Docker 极简与高安全多阶段构建

### 1. 多阶段构建（Multi-stage Build）核心模板

必须将「编译构建阶段」与「生产运行阶段」彻底剥离。

**Go 极简安全构建示例：**

```dockerfile
# 阶段一：构建编译器环境
FROM golang:1.22-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git ca-certificates && update-ca-certificates
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# 静态编译二进制，剔除符号表，减小体积
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o main .

# 阶段二：生产极简镜像
FROM gcr.io/distroless/static-debian12:latest-amd64
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/main /main
# 强制使用 nonroot 安全用户启动
USER 65532:65532
ENTRYPOINT ["/main"]
```

### 2. 容器非 root 用户运行规范（Non-root Security）

- 绝不允许直接在容器里运行默认的 root（UID 0）用户。
- 使用 Distroless：直接指定非 root 用户 ID `USER 65532:65532`。
- 使用 Alpine / Debian 基础镜像：必须手动创建用户组并切换：

```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
```

### 3. 高效 Layer 缓存优化（Layer Caching）

严格根据 Docker 镜像分层缓存特性安排指令顺序：

| 顺序 | 步骤 | 原因 |
|---|---|---|
| **前**（变化极低） | 复制依赖定义（`package.json`、`go.mod`、`requirements.txt`）+ 执行依赖下载 | 这些层极少变化，缓存命中率高 |
| **后**（频繁变动） | 源代码拷贝（`COPY . .`） | 防止源码微小修改击穿依赖缓存，导致每次重新下载 |

## IaC（Infrastructure as Code）

**核心原则：**

| 原则 | 说明 |
|---|---|
| 所有基础设施通过代码定义 | 禁止手动创建 / 修改 |
| 与应用代码同等对待 | 版本管理、PR 审查、CI 检查 |
| 环境可复现 | 销毁后从代码能重建完整环境 |
| 状态管理 | Terraform state 存储在远程后端（S3 + DynamoDB 锁） |

**目录结构（Terraform 示例）：**

```
infrastructure/
  modules/              可复用的基础设施模块
    networking/          VPC、子网、安全组
    compute/             EC2、ASG、ECS
    database/            RDS、Redis、ClickHouse
    monitoring/          CloudWatch、Prometheus
  environments/
    dev/                 开发环境配置
    staging/             预发布环境配置
    prod/                生产环境配置
  global/                跨环境共享资源（IAM、DNS）
```

## Kubernetes 资源配置

### 资源限制（必须设置）

| 字段 | 设置 | 原因 |
|---|---|---|
| `requests` | 保证最低资源 | 调度依据 |
| `limits` | 限制最大资源 | 防止打爆节点 |
| CPU | requests = 平均使用量，limits = 峰值的 2 倍 | 弹性 + 安全 |
| Memory | requests = limits | 避免 OOM Kill |

### 探针配置（必须设置）

| 探针 | 作用 |
|---|---|
| `livenessProbe` | 检测容器是否存活（失败则重启） |
| `readinessProbe` | 检测容器是否就绪（失败则移出流量） |
| `startupProbe` | 检测容器是否启动完成（给慢启动应用宽限期） |

## 多环境管理

| 环境 | 用途 | 管控 |
|---|---|---|
| dev | 开发者自由使用 | 随时可销毁重建 |
| staging | 预发布，模拟生产 | 用于集成测试和验收 |
| prod | 生产 | 严格管控，只能通过 CI/CD 部署 |

## 密钥管理

| 环境 | 存储方式 |
|---|---|
| 开发 | `.env` 文件（已加入 `.gitignore`） |
| CI/CD | 平台内置 Secrets（GitHub Secrets / GitLab Variables） |
| 生产 | Vault / AWS Secrets Manager / GCP Secret Manager |

**严禁：** 在 Dockerfile、Compose、代码中硬编码 `ENV API_KEY="xyz"`。

## 成本优化

### 资源 Right-Sizing

| 监控指标 | 处置 |
|---|---|
| 使用率持续 < 30% | 降规格 |
| 使用率持续 > 70% | 升规格或加实例 |

## 常见错误

| 错误做法 | 正确做法 |
|---|---|
| 单阶段构建（含编译工具链） | 多阶段构建，生产镜像只含运行时 |
| 容器以 root 启动 | `USER nonroot`（如 65532） |
| 先 `COPY . .` 再 `go mod download` | 先复制 `go.mod`、`go.sum` 并下载依赖 |
| 手动 SSH 改服务器配置 | 全部走 Terraform / Ansible IaC |
| 资源 requests / limits 都不设 | 必设，且 Memory requests = limits |
| 密钥写在 ENV 注入 Dockerfile | 走 Secrets 管理 |
| 监控 / 告警 / 部署配置脱节 | 监控即代码，与服务同步启动 |

## 产出物清单

- [ ] 高效多阶段、非 root 安全 Dockerfile 模板
- [ ] docker-compose 本地快速管线编排配置文件
- [ ] Terraform / Pulumi 基础设施定义代码
- [ ] Kubernetes 资源描述配置
- [ ] 动态多环境变量与 Secret 注入机制方案
