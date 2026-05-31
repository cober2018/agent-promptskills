---
name: infrastructure-automation
description: 基础设施自动化能力——IaC（Terraform/Pulumi）、容器编排（Docker/K8s）、多环境管理、密钥管理、云资源配置、成本优化。当任务涉及基础设施搭建、容器化、环境管理、云资源规划时激活。
---

🏗️ 基础设施自动化（Infrastructure Automation）
核心问题：基础设施怎么搭？怎么保证可复现？怎么控制成本？


📌 IaC（Infrastructure as Code）

  核心原则：
    所有基础设施通过代码定义，禁止手动创建/修改
    基础设施代码和应用代码同等对待：版本管理、PR 审查、CI 检查
    环境可复现：销毁后从代码能重建完整环境
    状态管理：Terraform state 存储在远程后端（S3 + DynamoDB 锁）

  目录结构（Terraform 示例）：
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

  模块设计原则：
    每个模块做一件事，有明确的输入（variables）和输出（outputs）
    模块内部封装复杂度，对外暴露简洁接口
    通过变量区分环境差异（实例规格、副本数、备份策略）
    模块有文档和使用示例

  变更流程：
    1. 本地修改 → terraform plan（查看变更计划）
    2. 提交 PR → CI 自动运行 plan 并评论到 PR
    3. 团队 review plan 输出
    4. 合并到 main → CI 自动 apply
    5. 验证基础设施状态


📌 容器编排

  Docker 最佳实践：
    多阶段构建：减小最终镜像体积
    非 root 用户运行：安全加固
    .dockerignore：排除不需要的文件
    固定基础镜像版本：FROM node:20.11-alpine（不用 latest）
    一个容器一个进程
    健康检查：HEALTHCHECK CMD curl -f http://localhost:8080/health

  Kubernetes 资源配置：
    资源限制（必须设置）：
      requests：保证最低资源（调度依据）
      limits：限制最大资源（防止打爆节点）
      CPU requests = 平均使用量，limits = 峰值的 2 倍
      Memory requests = limits（避免 OOM Kill）

    探针配置（必须设置）：
      livenessProbe：检测容器是否存活（失败则重启）
      readinessProbe：检测容器是否就绪（失败则移出流量）
      startupProbe：检测容器是否启动完成（给慢启动应用宽限期）

    Pod 反亲和性：
      核心服务的 Pod 分散到不同节点
      避免单节点故障导致服务完全不可用

    PDB（Pod Disruption Budget）：
      限制同时不可用的 Pod 数量
      保证滚动更新和节点维护时服务可用


📌 多环境管理

  环境分级：
    dev        开发环境    开发者自由使用，随时可销毁重建
    staging    预发布环境  尽量模拟生产，用于集成测试和验收
    prod       生产环境    严格管控，只能通过 CI/CD 部署

  环境差异管理：
    通过变量控制：实例规格、副本数、备份频率
    dev 用最小规格（省成本），prod 按容量规划配置
    Staging 数据：脱敏后的生产数据子集（不是空库）
    环境隔离：独立 VPC / 命名空间 / 数据库实例

  环境配置规范：
    通过 ConfigMap / 环境变量注入，不硬编码在镜像中
    敏感配置通过 Secret / Vault 管理
    配置版本化，和应用代码一起管理


📌 密钥管理

  密钥存储：
    开发环境：.env 文件（已加入 .gitignore）
    CI/CD：平台内置 Secrets（GitHub Secrets / GitLab Variables）
    生产环境：Vault / AWS Secrets Manager / GCP Secret Manager

  密钥轮换：
    数据库密码：每 90 天自动轮换
    API Token：每 180 天轮换
    TLS 证书：自动续期（cert-manager / Let's Encrypt）
    轮换过程零停机：新旧密钥并存过渡期

  密钥引用规范：
    应用通过环境变量读取，不通过文件
    日志中密钥必须脱敏
    代码审查时检查是否有硬编码密钥
    CI 中集成密钥泄露检测工具


📌 成本优化

  资源 Right-Sizing：
    监控实际资源使用率（CPU / 内存 / 磁盘）
    使用率持续 < 30% 的实例 → 降规格
    使用率持续 > 70% 的实例 → 升规格或加实例
    定期（每月）审查资源使用报告

  成本控制策略：
    开发/测试环境非工作时间自动关机（省 60%+）
    稳定负载用预留实例 / Savings Plans（省 30-50%）
    突发负载用 Spot 实例（省 60-90%，需容忍中断）
    存储冷热分离：低频数据转低成本存储层
    清理未使用的资源：闲置 EBS、未绑定 EIP、过期快照

  成本可见性：
    按团队/服务/环境打标签（tagging），归属成本
    每月生成成本报告，追踪趋势
    设置预算告警，超支前预警


📌 基础设施自动化产出物清单
  IaC 代码（Terraform / Pulumi 模块 + 环境配置）
  Dockerfile + docker-compose（开发环境）
  K8s 资源定义（Deployment / Service / Ingress / HPA）
  环境管理文档（dev / staging / prod 差异说明）
  密钥管理规范（存储方式 + 轮换策略）
  成本优化报告（当前成本 + 优化建议 + 预期节省）
