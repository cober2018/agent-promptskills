# Agent 交付职责路由标准（Agent Delivery Responsibility Routing）

> 权威源（Authoritative Source）
> 本文件是开发阶段多 agent 协作的职责划分权威源，用于回答「这类任务应该由谁主做、谁协作、谁验收、谁发布」。
> `4a-architect` 及其他架构类 prompt 只保留必须自检的硬约束；具体任务分工、协作流与反例以本文为准。

## 1. 适用范围

本文适用于以下场景：

- 需要在 `frontend-engineer`、`backend-engineer`、`data-engineer`、`devops-engineer`、`qa-engineer` 之间判定主责时
- 涉及调度器、采集任务、数仓表、DQC、因子/指标（Ins）开发时
- 需要明确交付流中谁负责实现、谁负责发布、谁负责测试时

本文不替代 4A 分层治理。能力域判断、ADR 触发条件、架构评审清单仍以 `docs/standards/architecture-collaboration-workflow.md` 为准。

## 2. 判定原则

在分派任务前，先按以下顺序判断：

1. **先看运行时归属**：问题发生在前端应用、API 服务、调度中心、执行 Worker、数据仓库、CI/CD 还是测试环境。
2. **再看单一事实源**：权威源是 API 契约、数据库表、调度配置、IaC 配置、测试用例还是设计稿。
3. **最后看改动对象**：修改的是平台能力本身，还是跑在平台上的业务任务 / 数据任务。

### 2.1 调度相关铁律

- **调度器平台本身异常**：由 `backend-engineer` 主责。
  - 例：调度 API、任务注册协议、执行器框架、权限控制、任务状态机、运行日志接口。
- **调度器正常，但跑在其上的任务有问题**：由 `data-engineer` 主责。
  - 例：采集脚本逻辑、ETL/ELT SQL、任务依赖关系、目标表写入、任务参数、任务级重试策略、数据回填。
- **调度器部署、进程守护、监控告警、发布回滚有问题**：由 `devops-engineer` 主责。

### 2.2 数据与前端相关铁律

- **数据定义、数据流、表结构、血缘、DQC、指标/因子/Ins 开发**：`data-engineer` 主责。
- **为业务能力暴露 API / 权限 / 审计 / 事务边界**：`backend-engineer` 主责。
- **页面交互、状态管理、视图编排、BFF 之外的前端呈现问题**：`frontend-engineer` 主责。
- **涉及跨存储选型、跨层数据权威源调整**：先由 `4a-architect` 定边界，再由对应实现 agent 落地。

### 2.3 交付流铁律

- `frontend-engineer`、`backend-engineer` 和 `data-engineer` 负责实现，但**不单独闭环发布**。
- `devops-engineer` 负责环境、部署、发布编排、可观测性和回滚预案。
- `qa-engineer` 负责测试设计、执行、缺陷证据和发布闸口结论。
- 没有 `devops-engineer` 的发布链路，或没有 `qa-engineer` 的验收结论，不应标记为完成交付。

## 3. 角色职责矩阵

| 任务类型 | 主责 Agent | 协作 Agent | 单一事实源 |
|---|---|---|---|
| 页面、组件、路由、状态管理、前端权限呈现、交互可用性 | `frontend-engineer` | `backend-engineer`、`qa-engineer` | 前端代码、设计稿、页面契约、交互 standards |
| HTTP / RPC API、认证鉴权、请求校验、领域服务编排 | `backend-engineer` | `4a-architect`、`qa-engineer` | OpenAPI / Protobuf、服务代码、接口 standards |
| 调度中心、任务注册框架、执行器协议、任务状态机 | `backend-engineer` | `devops-engineer`、`qa-engineer` | 调度服务代码、调度 standards、运行配置 |
| 采集脚本、ETL/ELT、任务 DAG、回填任务、落表逻辑 | `data-engineer` | `backend-engineer`、`frontend-engineer`、`qa-engineer` | 任务定义、脚本内容、目标表 schema、数仓文档 |
| 数仓分层（ODS / DWD / DWS / ADS）、宽表 / 指标 / 因子 / Ins 开发 | `data-engineer` | `4a-architect`、`qa-engineer` | 数据模型文档、数据库表、数据契约 |
| DQC 规则、完整性/准确性/一致性检查、告警阈值 | `data-engineer` | `frontend-engineer`、`qa-engineer`、`observability-ops` | DQC 规则配置、数据质量 standards、告警定义 |
| 容器、CI/CD、环境变量、反向代理、监控、告警、扩缩容、回滚 | `devops-engineer` | `frontend-engineer`、`backend-engineer`、`data-engineer` | IaC、部署清单、监控面板、运行手册 |
| 测试策略、测试用例、回归、E2E、发布建议 | `qa-engineer` | `frontend-engineer`、`backend-engineer`、`data-engineer`、`devops-engineer` | 测试计划、测试代码、测试报告 |
| 跨服务边界、跨域权责、跨存储选型、SLO 调整 | `4a-architect` | 所有受影响实现 agent | ADR、架构 standards、架构蓝图 |

## 4. Frontend / Backend / Data 的明确分界

### 属于 `frontend-engineer`

- 页面、组件、布局、交互反馈、表单体验、前端路由、前端状态管理
- 前端数据展示逻辑、图表呈现、前端权限态和错误态处理
- 与后端 API 对接后的页面编排、用户操作流程和可用性问题
- 只要问题根因在视图层、浏览器行为或前端状态，而不是 API 契约或数据本体，就默认先归 `frontend-engineer`

### 属于 `backend-engineer`

- 面向前端、外部系统或其他服务的 API / BFF / RPC 契约
- 调度平台能力本身：任务注册、调度 API、任务运行状态、权限、审计、任务编排框架
- 业务领域服务、事务边界、用户态配置、平台级异常处理
- 平台级缓存、消息、幂等、限流、鉴权、审计

### 属于 `data-engineer`

- 采集任务本体：脚本、SQL、表写入、字段映射、任务参数、任务依赖、回填逻辑
- 数据仓库分层、表模型、分区策略、宽表拼装、指标/因子/Ins 计算
- 数据质量规则、血缘、保留期、补数、数据对账
- 调度器承载的业务任务内容，只要问题不在调度平台自身，就默认先归 `data-engineer`

### 需要联合处理

- 前端页面报错，但根因可能在接口契约或返回语义
  - `frontend-engineer` 负责页面行为、状态流和交互降级
  - `backend-engineer` 负责接口契约、鉴权和错误码语义
- API 触发任务执行、但失败根因落在任务脚本或目标表
  - `backend-engineer` 负责入口契约、任务触发链路和状态透出
  - `data-engineer` 负责任务内容、数据处理和落表 correctness
- 数据平台页面（任务看板 / DQC 看板 / 因子页面）需要新增可视化或交互
  - `data-engineer` 负责指标定义、口径和数据 SLA
  - `frontend-engineer` 负责页面呈现、交互和前端状态
  - `backend-engineer` 负责需要新增的 API / 聚合接口 / 权限审计
- 数据产品需要新的查询 API
  - `data-engineer` 定义数据模型和 SLA
  - `backend-engineer` 暴露 API、权限、缓存和审计

## 5. DevOps 与 QA 在标准开发流中的位置

### 5.1 标准协作流

1. `4a-architect` 定能力域、运行时归属、边界变更和 ADR / standards 更新要求。
2. `frontend-engineer`、`backend-engineer` 或 `data-engineer` 作为唯一主责实现者落地变更。
3. `devops-engineer` 负责环境准备、发布方案、监控告警、容量和回滚检查。
4. `qa-engineer` 负责测试计划、执行结果、缺陷报告和发布建议。
5. 满足发布条件后再进入人工合并 / 上线流程。

### 5.2 不允许的反模式

- 让 `backend-engineer` 同时承担前端实现、数据任务实现、发布部署和最终测试结论
- 仅因为问题出现在页面上，就忽略其真实根因可能位于 API 或数据任务
- 仅因为问题入口是某个 API，就忽略其真实根因位于采集任务或数仓
- 仅因为任务由调度器触发，就把所有调度相关问题都归给 `backend-engineer`
- 没有测试证据或发布回滚方案，就宣称任务完成

## 6. 升级与协作规则

- 触发跨服务、跨存储、跨调度、跨能力域的边界调整时，先走 ADR 与架构文档更新，再分派实现 agent。
- 当 `frontend-engineer`、`backend-engineer` 与 `data-engineer` 对归属有争议时，由 `4a-architect` 按运行时归属和单一事实源裁决。
- 当问题已经确认是环境、发布、资源、监控、网络、权限策略导致时，转由 `devops-engineer` 主责。
- 当需要验收是否可发布时，以 `qa-engineer` 的测试结论和残余风险判断为准。

## 7. 最小分派清单

每次分派前至少确认以下五项：

- [ ] 主责 agent 是否唯一且可解释
- [ ] 运行时归属是否已声明（前端 / 服务 / 调度器 / 任务 / 存储 / 部署 / 测试）
- [ ] 单一事实源是否已声明（契约 / 表 / 配置 / 文档 / 测试）
- [ ] 是否已排除把前端、后端、数据三类实现工作混成一个默认 owner
- [ ] 是否需要同时拉入 `devops-engineer` 和 `qa-engineer`

## 8. Dispatch 协议（**关键** 2026-06-07 新增）

> **权威源**：`docs/dispatch/PROTOCOL.md`

### 为什么需要新协议

老协议：PM 用 `TaskUpdate(taskId, owner=...)` 标"派工"——**但 Lead 不知道**有派单来了。
- PM 工具列表**没有** `Agent()`，没法直接派 Lead
- Lead 不读 `TaskList`，所以 `TaskUpdate` 设 owner 等于啥也没干
- 派工通知靠"prompt 里写约束 + LLM 自觉"——**不可靠**

新协议：**派工 = 写文件**（dispatch md 落盘 = ground truth 通知）

```
PM 写 docs/dispatch/<id>.md（status=pending, owner=4a-architect）
   ↓
主 session 每个 turn 开头 Glob dispatch/ 发现 pending 包
   ↓
主 session 调 Agent(subagent_type=owner) 派 Lead
   ↓
Lead 改 status=in_progress，推进，status=review
   ↓
QA / review 过，PM 改 status=done
```

### 角色动作速查

| 角色 | 何时 | 动作 | 改 dispatch md 哪部分 |
|---|---|---|---|
| **PM** | 派工 | Write 新 dispatch md | 整文件落盘，status=pending |
| **PM** | 推进 9 步 | Read 查 status | 改 `pm_pinged_at` / `last_pm_note` |
| **PM** | 升级 | 改 status=blocked + 升级 User | status + 写卡因 |
| **主 session** | 每个 turn 开头 | Glob dispatch/ 找 pending | 调 Agent() 派 Lead |
| **Lead** | 启动 | Glob 查 own 的 pending | 改 status=in_progress + 进度日志 |
| **Lead** | 完成 | 改 status=review | 填 artifact 字段 |
| **QA** | 验收 | 改 status=done（如果主 session 也是 QA） | status |

### 硬约束（不遵守 = 派工失败）

1. **PM 禁止用 `TaskUpdate(owner=...)` 当派工通知**——那只是 metadata，Lead 不知道
2. **PM 禁止用 `Agent(subagent_type=...)` 派 Lead**——PM 工具列表里**没有** Agent 工具
3. **Lead 启动后必须 Glob dispatch/**——不查 = 不接单 = 派工堆积
4. **主 session 每个 turn 开头必须 Glob dispatch/ 找 pending**——不轮询 = 派工永远 pending
5. **status 状态机单向**：`pending → in_progress → review → done`，卡住时改 `blocked`（用 `pm_pinged_at` 标记时间）

### 与 TaskCreate / TaskUpdate 的边界

| 工具 | 适用 | 不适用 |
|---|---|---|
| `TaskCreate` / `TaskUpdate` | PM 自己的 todo list（"我还要做哪些事"）| 派工通知（用 dispatch md）|
| `docs/dispatch/<id>.md` | 派工通知 + Lead 进度跟踪 + PM 推进 9 步 | PM 内部 todo |

**简单记忆**：**派工 = 文件**，**todo = TaskList**——别混。
