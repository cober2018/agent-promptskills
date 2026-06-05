# QuantAgents Agent & Skill 体系

> **开发期 AI 工具的 Agent / Skill 配置文件目录**。
> 与运行时平台 Agent（`/tradingagents/agents/`、`/skills/`）解耦，专用于 Claude Code、Cursor、Gemini CLI 等开发工具。
>
> 权威源：组织架构与派工规则见 [`agents/ROUTING.md`](./ROUTING.md)；本文件是**总览**。

## 目录结构

```
agents/
├── README.md                    # 本文件：组织总览
├── ROUTING.md                   # ★ 权威源：Agent×Skill 路由矩阵 + 派工硬约束
├── agents/                      # 7 个 Agent 定义
│   ├── pm.md                    # 业务侧 PM（入口）
│   ├── 4a-architect.md          # 4A 架构师（评审 + 派工）
│   ├── backend-engineer.md      # 后端专家
│   ├── frontend-engineer.md     # 前端专家
│   ├── data-engineer.md         # 数据工程师
│   ├── qa-engineer.md           # QA 专家（E2E / 压测 / 质量门禁）
│   └── quant-lead.md      # 量化研究员（业务 Lead + 技术执行者双角色）
└── skills/                      # 30 个 Skill
    ├── 架构层（4）              # business-/application-/data-/technology-architecture
    ├── 工程层（4）              # react-frontend + api + database + system-reliability
    ├── 数据层（3）              # pipeline-engineering + data-quality + lakehouse-platform
    ├── 量化层（3）              # factor-engineering + factor-mining + backtest-validation
    ├── 质量层（2）              # test-evidence + quality-gate
    └── 通用 superpowers（13）   # brainstorming / writing-plans / tdd / ...
```

> 注：早期 bootstrap 曾设独立 `quant-pm` 角色（量化业务侧 PM），已被 ADR-0003 修正为合并到 `quant-lead`（双角色合一）。

## 一句话使用

> **用户只对 PM 说话；PM 自动派单给 4A / quant-lead / 专家。**

```
/pm <你的需求>
```

或直接对当前 session 说"我有个需求：..."，主 session 知道走 PM 流程。

## 7 个 Agent 一览

| Agent | 角色 | 主用 Skill | 入口 / 派工 |
|---|---|---|---|
| **业务 PM** | 业务侧总入口，需求对齐 + 拆任务 + 派单 | brainstorming, writing-plans, business-architecture(只读) | `/pm` |
| **量化研究员**（业务 Lead 模式） | 量化业务侧入口，撰写四件套需求文档，4A 评审 | brainstorming, factor-engineering(只读), backtest-validation(只读) | PM 转单 / 用户直找 |
| **量化研究员**（执行模式） | 因子 / 回测 / IC 评估的执行者 | factor-engineering, factor-mining, backtest-validation | 4A 派回时（仅量化业务） |
| **4A 架构师** | 跨业务/应用/数据/技术四层架构评审，ADR + 派工 | 4 个 architecture skill, writing-plans | 业务 PM / quant-lead 派单 |
| **后端专家** | Go / FastAPI 后端代码、并发、分布式、API、SQL | api-engineering, database-engineering, system-reliability | 4A 派单 |
| **前端专家** | React 19 前端架构、状态管理、动效、无障碍 | react-frontend-architecture | 4A 派单 |
| **数据工程师** | 时序/湖仓/Medallion/ClickHouse 调优/DQC 门禁 | data-architecture, pipeline-engineering, data-quality, lakehouse-platform | 4A 派单 |
| **QA 专家** | Playwright E2E / Pytest 数据桩 / Locust 压测 / 质量门禁 / Bug 证据链 | test-evidence, quality-gate | 4A 派单 |

**未在本期装入**（按 YAGNI，需要时再装）：`devops-engineer`、`new-media-operator`、`video-editing-coach`。

## 30 个 Skill 一览

### 架构层（4）

| Skill | 主调度 Agent |
|---|---|
| `business-architecture` | 4A 架构师 / 业务 PM |
| `application-architecture` | 4A 架构师 |
| `data-architecture` | 4A 架构师 / 数据工程师 / 量化研究员（业务 Lead 模式） |
| `technology-architecture` | 4A 架构师 |

### 工程层（4）

| Skill | 主调度 Agent |
|---|---|
| `react-frontend-architecture` | 前端专家 |
| `api-engineering` | 后端专家 |
| `database-engineering` | 后端专家 |
| `system-reliability` | 后端专家 |

### 数据层（3）

| Skill | 主调度 Agent |
|---|---|
| `pipeline-engineering` | 数据工程师 |
| `data-quality` | 数据工程师 |
| `lakehouse-platform` | 数据工程师 |

### 量化层（3）

| Skill | 主调度 Agent |
|---|---|
| `factor-engineering` | 量化研究员（执行模式 / 业务 Lead 评审用） |
| `factor-mining` | 量化研究员（执行模式） |
| `backtest-validation` | 量化研究员（执行模式 / 业务 Lead 评审用） |

### 质量层（2）

| Skill | 主调度 Agent |
|---|---|
| `test-evidence` | QA 专家 |
| `quality-gate` | QA 专家 |

### 通用 superpowers（13，按需调用，不挂到具体 Agent）

| Skill | 适用阶段 |
|---|---|
| `using-superpowers` | 启动任何任务时 |
| `brainstorming` | 需求对齐、方案讨论前 |
| `writing-plans` | 编码前的微任务计划 |
| `executing-plans` | 编码与计划落地 |
| `test-driven-development` | 业务代码编写 |
| `systematic-debugging` | Bug 修复 / 异常排查 |
| `verification-before-completion` | 任务交付前 |
| `subagent-driven-development` | 复杂大任务拆分 |
| `dispatching-parallel-agents` | 并发任务处理 |
| `requesting-code-review` | 提 PR 前自检 |
| `receiving-code-review` | 接 Review 意见 |
| `using-git-worktrees` | 多任务并行 / 分支隔离 |
| `finishing-a-development-branch` | 分支合并 / 临时分支清理 |
| `writing-skills` | 自定义 Skill 扩充 |

> 仓库中 `skill-health`、`pruning-skills` 等运维类 Skill 本期未列入；需要时再装。

## 派工硬约束

> **唯一权威源：[`agents/ROUTING.md`](./ROUTING.md)**

| 上游 | 可直接派给 | 不可直接派给 |
|---|---|---|
| 业务 PM | `quant-lead`（业务 Lead）、`4a-architect` | 所有专家（backend/frontend/data-engineer/quant-lead 执行模式） |
| quant-lead（业务 Lead） | `4a-architect` | `data-engineer` |
| 4A 架构师 | 任意专家 | — |

跨域变更 100% 触发 ADR（`docs/adr/NNNN-<slug>.md`），由 4A 评审登记。

## 关键参考文档

| 文档 | 关系 |
|---|---|
| [`agents/ROUTING.md`](./ROUTING.md) | **★ Agent×Skill 路由 + 派工硬约束的权威源** |
| [`docs/standards/architecture-collaboration-workflow.md`](../docs/standards/architecture-collaboration-workflow.md) | 4A 协同工作流的权威源（4A 评审清单、ADR 模板） |
| [`docs/adr/0001-4a-collaboration-baseline.md`](../docs/adr/0001-4a-collaboration-baseline.md) | 4A 治理基线 ADR |
| [`docs/adr/0002-agent-org-bootstrap.md`](../docs/adr/0002-agent-org-bootstrap.md) | 多 Agent 组织 bootstrap 决策（已被 ADR-0003 部分修正） |
| [`docs/adr/0003-agent-org-pm-naming-correction.md`](../docs/adr/0003-agent-org-pm-naming-correction.md) | quant-pm 命名修正（合并到 quant-lead） |
| `AGENTS.md` | 项目级 AI 协作规则（含 Canonical Directories 划分） |
| `CLAUDE.md` | 项目级 Claude 配置 |

## 演进规则

- 本目录变更必须先提 ADR（流程治理类）。
- 新增 Agent / Skill 必先更新 ROUTING.md，再写 Agent 提示词。
- 全局过程规范 Skill（superpowers 系列）独立增减，不挂具体 Agent。
- 每 6 个月做一次 `skill-health` 巡检。
- 不挂到本目录的内容：运行时平台 Agent（`/tradingagents/agents/`、`/skills/`），不要混存。

---

> 安装源：[cober2018/agent-promptskills](https://github.com/cober2018/agent-promptskills)（裁剪后 7 Agent / 30 Skill）
> 维护者：业务 PM
> 状态：Active
