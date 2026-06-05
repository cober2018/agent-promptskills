# Agent 组织架构文件索引（AGENT_ORG_INDEX）

> **单一入口（Single Entry Point）**：本文件是多 Agent 团队架构的**导航页**。任何"这个文件干什么用 / 怎么用 / 谁引用谁"的问题，从这里查起。
>
> **权威源**：本文件**不**重复任何权威规则——它只指路。规则仍在各自权威源。
>
> **维护者**：业务 PMO
> **状态**：Active
> **上次更新**：2026-06-05

---

## 1. 如何用本索引

3 种典型问题：

| 你的问题 | 跳到 |
|---|---|
| "我接到了任务，先看什么" | §2 启动顺序 |
| "这个文件是干啥的" | §3 五大类文件清单 |
| "谁引用谁" | §4 引用关系图 |

---

## 2. 启动顺序（新成员 / 新任务 5 分钟上手）

按这个顺序读 5 个文件，**15 分钟**能懂架构：

```
Step 1. CLAUDE.md                              1 分钟   ← 项目入口，"## 入口"段指向 /pm
Step 2. agents/pm.md                  3 分钟   ← 业务 PMO 角色 + 4 动作
Step 3. agents/4a-architect.md        3 分钟   ← 4A 双身份（评审 + Lead）
Step 4. agents/ROUTING.md                    4 分钟   ← 派工硬约束（3 层组织）
Step 5. docs/standards/multi-agent-team-      4 分钟   ← 搭建方法论 + 13 步流程
              bootstrap.md（只读 §1 §2 §3，§6 §7 按需查）
```

> 关键记忆：派工链 = **User → PMO → Lead → IC**（3 层组织），不是"PM 派工给 IC"。

---

## 3. 五大类文件清单

### 3.1 A 类：核心 Agent（3 层组织，7 个）

| 文件 | 层级 | 角色 | tools 关键点 |
|---|---|---|---|
| `agents/pm.md` | L1 PMO | **业务 PMO / 需求分流官** | 无 `Agent`（不派工）|
| `agents/4a-architect.md` | L2 Lead | **4A 架构师 / 技术团队 Lead**（双身份）| 有 `Agent`（派技术 IC）|
| `agents/quant-lead.md` | L2 Lead + L3 IC | **业务 Lead 模式 + 执行模式**（双角色合一）| 有 `Agent`（派自己执行模式）|
| `agents/backend-engineer.md` | L3 IC | 后端代码 | 无 `Agent` |
| `agents/frontend-engineer.md` | L3 IC | 前端代码 | 无 `Agent` |
| `agents/data-engineer.md` | L3 IC | 数据工程 | 无 `Agent` |
| `agents/qa-engineer.md` | L3 IC | E2E / 压测 / 质量门禁 | 无 `Agent` |

> **派工边界**（硬约束）：4A 派 be/fe/data/qa；quant-lead 派自己（执行模式）；**永远不跨团队指挥**。

### 3.2 B 类：Skill（30 个，分 6 层）

| 层 | 数量 | 目录 | 主调度 Agent |
|---|---|---|---|
| 架构层 | 4 | `skills/{business,application,data,technology}-architecture/` | 4A |
| 派工路由 | 1 | `skills/pm-engine/` | 4A / 前端派工引擎路由（CC / Codex / Gemini / Antigravity 切换）|
| 工程层 | 4 | `skills/{react-frontend-architecture,api-engineering,database-engineering,system-reliability}/` | be / fe / data |
| 数据层 | 3 | `skills/{pipeline-engineering,data-quality,lakehouse-platform}/` | data |
| 量化层 | 3 | `skills/{factor-engineering,factor-mining,backtest-validation}/` | quant-lead |
| 质量层 | 2 | `skills/{test-evidence,quality-gate}/` | qa |
| 通用 superpowers | 13 | `skills/{using-superpowers,brainstorming,writing-plans,executing-plans,test-driven-development,systematic-debugging,verification-before-completion,subagent-driven-development,dispatching-parallel-agents,requesting-code-review,receiving-code-review,using-git-worktrees,finishing-a-development-branch,writing-skills}/` | 全员按需 |

> Skill **不**内联流程规则——只承载"怎么用"的硬约束。流程规则走 §3.3 治理权威源。

### 3.3 C 类：治理权威源（3 份）

| 文件 | 角色 |
|---|---|
| `agents/ROUTING.md` | **派工硬约束**权威源（派工矩阵 + 跨域 ADR 清单）|
| `docs/standards/multi-agent-team-bootstrap.md` | **搭建方法论**权威源（5 原则 + 13 步流程 + 5 个 prompt 模板）|
| `docs/standards/architecture-collaboration-workflow.md` | **4A 治理**权威源（4A 协同工作流 + 五条硬约束 + 评审清单）|

> **冲突原则**：Agent 提示词 vs 权威源 → **以权威源为准**。Agent 提示词只承载硬约束指针 + 角色定义。

### 3.4 D 类：运行时配置

| 文件 | 作用 |
|---|---|
| `.claude/settings.json` | `teammateMode: "auto"` + 2 个 PreToolUse hooks（Skill/Bash matcher）|
| `.claude/agents → ../agents/` | **软链**，让 CC auto-discover 自定义 Agent |
| `.claude/commands/pm.md` | `/pm` 命令入口（用户唯一对话接口）|
| `.claude/hooks/check-gstack.sh` | (existing) gstack 必装检查 |
| `.claude/hooks/check-9step.sh` | **★ 本 session 落地**——9 步链路 commit 阶段硬拦截 |
| `docs/tasks/_template.md` | 9 步 plan 文件模板（PM 接到需求第一步拷这个）|

### 3.5 E 类：决策记录（ADR）

| 文件 | 状态 | 主题 |
|---|---|---|
| `docs/adr/0001-platform-architecture-governance.md` | 其他 agent 写的 | 平台架构治理 |
| `docs/adr/0001-4a-collaboration-baseline.md` | (其他 agent) | 4A 协同基线 |
| `docs/adr/0002-agent-delivery-responsibility-routing.md` | 其他 agent 写的 | 派工责任分配 |
| `docs/adr/0002-agent-org-bootstrap.md` | ★ 我们的 | Agent org 初次 bootstrap |
| `docs/adr/0003-agent-org-pm-naming-correction.md` | ★ 我们的 | PM 命名修正（quant-pm 合并到 quant-lead）|
| `docs/adr/0004+` | 其他 agent 的活 | paper trading / dqc / strategy 等 |

> 我们的 ADR 2 个（0002/0003）；其他 22+ 个是其他 agent 的工作记录。

### 3.6 F 类：横切关注点（独立于 git repo）

> **本模板范围内无 F 类内容。** F 类（如跨会话 memory、周复盘、跨项目 skill）属于用户级 / 项目级配置（`~/.claude/`），由使用本模板的项目按需建立，不在通用模板内。

---

## 4. 引用关系图（精确反向链接）

```
┌─────────────────────────────────────────────────────────────┐
│ 用户 / CC harness                                            │
└────────────────────┬────────────────────────────────────────┘
                     │
   ┌─────────────────▼─────────────────┐
   │  CLAUDE.md（项目入口）              │  → "## 入口"段指向 /pm
   └─────────────────┬─────────────────┘
                     │
   ┌─────────────────▼─────────────────┐
   │  .claude/commands/pm.md            │  ← /pm 命令
   └─────────────────┬─────────────────┘
                     │ dispatch
                     ▼
   ┌────────────────────────────────────┐
   │  .claude/agents                     │  ← 软链
   │       → agents/            │  ← CC auto-discover
   └────────────────┬───────────────────┘
                    │
   ┌────────────────▼────────────────────────────────────────┐
   │  7 Agent 文件（agents/）                       │
   │  pm.md / 4a-architect.md / quant-lead.md /     │
   │  backend-engineer.md / frontend-engineer.md /          │
   │  data-engineer.md / qa-engineer.md                     │
   └─┬──────────────┬─────────────────┬──────────────────┘
     │              │                 │
     │ 引用 C       │ 引用 C          │ 引用 ADR
     ▼              ▼                 ▼
   ┌──────────────────┐    ┌────────────────────────┐
   │ multi-agent-team-│    │ architecture-            │
   │ bootstrap.md     │    │ collaboration-          │
   │ (搭建方法论)     │    │ workflow.md              │
   │                  │    │ (4A 治理)               │
   └────────┬─────────┘    └────────────┬───────────┘
            │ 互引                      │ 引用
            ▼                            ▼
   ┌─────────────────────┐    ┌────────────────────────┐
   │  agents/ROUTING.md  │    │  docs/adr/0001-...md   │
   │  (派工硬约束)        │    │  (4A 治理基线)         │
   └─────────────────────┘    └────────────────────────┘

   skills/ 30 个   ← 各 Agent 调用的 skill（主用）
   docs/tasks/_template.md  ← 9 步 plan 模板
   .claude/hooks/check-9step.sh  ← 拦 git commit
   .claude/settings.json  ← 注册 hook + teammateMode=auto

   ~/.claude/projects/.../memory/  ← 跨工具通用知识（sub-agent reliability 等）
```

### 4.1 谁引用谁（精确反向表）

| 权威源 | 引用方 | 引用方式 |
|---|---|---|
| `multi-agent-team-bootstrap.md` | `pm.md` | 链接到 spec §1.2 层级关系与 ROUTING |
| `architecture-collaboration-workflow.md` | `4a-architect.md` | 4A 五条硬约束全部引向此源 |
| `architecture-collaboration-workflow.md` | `multi-agent-team-bootstrap.md` | spec §1.2 + §11 引用 |
| `architecture-collaboration-workflow.md` | `agent-delivery-responsibility-routing.md`, `sandbox-script-field-semantics.md`, `architecture-review-checklist.md`, `AGENT_SCHEDULER_GUIDE.md` | (其他 standards) |
| `docs/adr/` | `4a-architect.md`, `ROUTING.md`, `multi-agent-team-bootstrap.md` | 引用 ADR 模板 + 边界变更必登记 |
| `docs/requirements/quant/NNNN-<slug>.md` | `quant-lead.md` | 量化需求文档落点 |
| `docs/tasks/` | `multi-agent-team-bootstrap.md`（§立项工作流段）, `check-9step.sh`, `ROUTING.md` | 9 步 plan 模板 + 强制 |
| `~/.claude/skills/weekly-retro/` | `multi-agent-team-bootstrap.md`（§10） | 配套工具 |

---

## 5. 文件总览（按目录树，标关键文件）

```
QuantAgents/
├── agents/                                    ← ★ 多 Agent 团队根
│   ├── README.md                               ★ 总览
│   ├── ROUTING.md                              ★ 派工硬约束权威源
│   ├── agents/                                 ★ 7 Agent
│   │   ├── pm.md                              ★ L1 PMO
│   │   ├── 4a-architect.md                    ★ L2 Lead (技术)
│   │   ├── quant-lead.md                 ★ L2 Lead (量化) + L3 IC
│   │   ├── backend-engineer.md                 ← L3 IC
│   │   ├── frontend-engineer.md                ← L3 IC
│   │   ├── data-engineer.md                    ← L3 IC
│   │   └── qa-engineer.md                      ← L3 IC
│   └── skills/                                 ★ 30 Skill
│       ├── 架构层（4）+ 工程层（4）+ 数据层（3）
│       └── 量化层（3）+ 质量层（2）+ 通用 superpowers（13）
│
├── .claude/
│   ├── agents → ../agents/             ★ 软链（CC auto-discover）
│   ├── settings.json                           ★ 含 teammateMode + hooks
│   ├── hooks/
│   │   ├── check-gstack.sh                     (existing)
│   │   └── check-9step.sh                      ★ 本 session 落地
│   └── commands/
│       └── pm.md                                ★ /pm 命令入口
│
├── docs/
│   ├── standards/
│   │   ├── AGENT_ORG_INDEX.md                  ← ★ 本文件（导航页）
│   │   ├── multi-agent-team-bootstrap.md      ★ 搭建方法论权威源（29KB）
│   │   ├── architecture-collaboration-workflow.md  ★ 4A 治理权威源
│   │   ├── architecture-review-checklist.md    (4A 评审清单)
│   │   ├── agent-delivery-responsibility-routing.md  (其他 agent)
│   │   ├── sandbox-script-field-semantics.md   (沙箱脚本)
│   │   ├── 三主题域落地*.md                    (项目特定)
│   │   ├── 数据仓库架构文档.md                  (项目特定)
│   │   ├── 数据字典.md / 数据源接口上下文文档.md  (项目特定)
│   │   └── 金融数仓开发规范.md                  (项目特定)
│   ├── adr/                                     ★ 决策记录（24+ 个）
│   │   ├── 0002-agent-org-bootstrap.md          ★ 我们的
│   │   ├── 0003-agent-org-pm-naming-correction.md  ★ 我们的
│   │   └── 0001 / 0004-0014                     (其他)
│   ├── tasks/
│   │   └── _template.md                         ★ 9 步 plan 模板
│   ├── requirements/                            (PM 产出的需求文档落点)
│   ├── operations/                              (运维文档)
│   ├── strategy/                                (量化策略文档)
│   └── retros/                                  (周复盘)
│
├── CLAUDE.md                                    ★ 项目入口
│
└── ~/.claude/                                    ← (独立于 git repo)
    ├── projects/-Users-mshengran-Project-QuantAgents/
    │   └── memory/
    │       ├── MEMORY.md                        ★ 17 条 memory 索引
    │       └── feedback_*.md / project_*.md     (16 条)
    └── skills/
        ├── weekly-retro/SKILL.md                 ★ 本 session 写（周复盘）
        └── bootstrap-team/SKILL.md              ★ 本 session 写（搭团队入口）
```

> ★ = 这次 session 涉及 / 关键

---

## 6. 快速跳转（按角色）

| 你是 | 必看 |
|---|---|
| **新加入团队的 PM** | `pm.md` + `multi-agent-team-bootstrap.md §6.1` + `ROUTING.md` |
| **新加入团队的 Lead**（4A / quant） | 对应 Agent 文件 + `architecture-collaboration-workflow.md`（4A）/ `multi-agent-team-bootstrap §6.2`（quant）|
| **新加入团队的 IC**（be/fe/data/qa） | 对应 Agent 文件 + `ROUTING.md`（看派工矩阵）|
| **审计 / 评估架构** | 本 INDEX + `multi-agent-team-bootstrap.md`（整篇）|
| **排查 sub-agent 可靠性问题** | `~/.claude/projects/.../memory/feedback_subagent_*.md`（4 条 sub-agent 相关）|
| **新写 Skill** | 模仿已有 `multi-agent-team-bootstrap.md §6` 模板 + `~/.claude/skills/weekly-retro/SKILL.md` 风格 |
| **新写 ADR** | 按 `architecture-collaboration-workflow.md §4` 模板（标题 / 状态 / 背景 / 决策 / 备选 / 权衡 / 后果）|
| **修派工规则** | **不要**改 Agent 提示词——只改 `ROUTING.md §2 派工矩阵` + 开 ADR 登记 |

---

## 7. 维护规则

1. **改任何权威源之前**：先看本 INDEX 的"引用关系"，看会牵连哪些文件
2. **新文件入索引**：
   - Agent 提示词 → `§3.1` + `§5` + 引用关系
   - Skill → `§3.2`
   - 权威源（standards/adr）→ `§3.3 / §3.5`
   - Memory → `§3.6`
3. **删文件**：
   - 先看引用方（`grep -r <filename>`）
   - 没有引用方才能删
   - 删完同步更新本 INDEX
4. **每月一次巡检**：
   - 引用方是否仍有效
   - 章节数 / Agent 数 / Skill 数是否与实际一致
5. **任何权威源变更必须先开 ADR**（per `architecture-collaboration-workflow.md §3.2`）

---

## 8. 待办（试运行期间观察后写）

- [ ] ADR 登记 9 步链路硬化（待试运行数据）
- [ ] ADR 登记 3 层组织硬化（`04f177b` 这次提交）
- [ ] 试运行 1-2 天后回填本 INDEX 的"实际引用次数"统计
- [ ] 评估是否需要 §3.6 加"非记忆类全局 skill"（如 superpowers 全家桶）

> 维护者：业务 PMO
> 状态：Active
> 上次更新：2026-06-05（伴随 `04f177b` 架构硬化提交）
