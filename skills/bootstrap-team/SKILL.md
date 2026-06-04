---
name: bootstrap-team
description: 用于以下场景：为一个新项目搭建多 Agent 协作团队——按 13 步流程从 0 到跑通 /pm 入口，含 4A 治理基线、Agent 选型、Skill 路由、ROUTING 权威源、teammateMode、ADR 登记、commit。规格权威源见 `<project>/docs/standards/multi-agent-team-bootstrap.md`。
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
triggers:
  - bootstrap team
  - bootstrap agents
  - 搭建团队
  - 装 agent
  - 装 skill
---

# bootstrap-team — 多 Agent 团队搭建

按规格文档为新项目搭建多 Agent 协作团队。**13 步流程，每步可中断可恢复**。

## 权威源

**完整方法论与决策树**见 `<project>/docs/standards/multi-agent-team-bootstrap.md`（规格文档）。
本 skill 是**执行版入口**，所有规则 / 模板 / 失败案例都在规格文档里。

## 何时触发

- 用户说"为 X 项目搭建多 Agent 团队"
- 用户说"装 agent"、"装 skill"、"按 4A 框架搭团队"
- 新项目初始化阶段的"AI 工具配置"环节

## 不要做

- **不跳过前置**——4A 治理基线 ADR 没写就装 agent，是无锚之锚
- **不为 YAGNI 装**——"未来会用到"不算理由
- **不把派工规则写到 Agent 提示词里**——违反权威源原则，只能写硬约束
- **不在 settings.json 用 `enabledAgents` 字段**——v2.1.x schema 不支持
- **不直接改 ROUTING 而不开 ADR**——派工规则改动必须登记
- **不抄一遍每个 Agent 文件**——直接 cp 上游 `cober2018/agent-promptskills` 仓库的，按需裁剪

## 工作流

### Step 1：必问用户 3 个关键问题（1 关键问题原则）

```
1. 项目属于什么业务领域？（量化 / 普通业务 / 内容运营 / 其他）
2. 当前项目阶段？（0→1 / 已 MVP / 规模化 / 维护期）
3. 这次装好后，预期多 Agent 团队跑多久？（< 1 周试用 / 1-3 月生产 / 长期）
```

> 答不出来就先 brainstorming 对齐，不要硬上。

### Step 2：选角色（参考规格 §2.1 / §2.2）

| 必装 | 按需装 |
|---|---|
| pm, 4a-architect, backend-engineer, frontend-engineer, data-engineer | qa-engineer, <业务>-researcher（双角色合一）, devops-engineer, new-media-operator, video-editing-coach |

输出：列表。给用户确认："这些角色 OK 吗？有要合并的（参考 §9.1 业务 Lead 双角色）？"

### Step 3：选 Skill（参考规格 §Phase 1）

- 4 个 architecture skill
- 工程类：react-frontend-architecture + api-engineering + database-engineering + system-reliability
- 数据类：pipeline-engineering + data-quality + lakehouse-platform
- 量化类：factor-engineering + factor-mining + backtest-validation
- superpowers（13 个通用过程规范）
- 质量类（仅装 QA 时）：test-evidence + quality-gate

### Step 4：建项目骨架

```bash
mkdir -p <project>/.agents/agents <project>/.agents/skills
# 4A 权威源（必须先有）
mkdir -p <project>/docs/standards <project>/docs/adr
```

如果 `docs/standards/architecture-collaboration-workflow.md` 已有（来自上游 ADR-0001），跳过；没有则从上游拷贝。

### Step 5：写 4A 治理基线 ADR

如果 `docs/adr/0001-4a-collaboration-baseline.md` 不存在，按规格 [architecture-collaboration-workflow.md §3-§4](./architecture-collaboration-workflow.md#3-硬约束agent-自检项) 写。

### Step 6：装 Agent

```bash
# 从 cober2018/agent-promptskills 仓库
SRC=/tmp/agent-promptskills  # 用户需要先 git clone
for f in pm 4a-architect backend-engineer frontend-engineer data-engineer qa-engineer quant-researcher; do
  [ -f "$SRC/agents/$f.md" ] && cp "$SRC/agents/$f.md" "<project>/.agents/agents/$f.md"
done
```

### Step 7：给 Agent YAML 加 `tools` 字段

按规格 §5：
- 业务 PM / Lead / 4A：`Agent, Read, Grep, Glob, Write, Edit, [Bash]`
- 纯执行专家：`Read, Grep, Glob, Bash, Write, Edit`

### Step 8：装 Skill

```bash
for s in business-architecture application-architecture data-architecture technology-architecture \
         react-frontend-architecture api-engineering database-engineering system-reliability \
         pipeline-engineering data-quality lakehouse-platform \
         factor-engineering factor-mining backtest-validation \
         test-evidence quality-gate \
         using-superpowers brainstorming writing-plans executing-plans \
         test-driven-development systematic-debugging verification-before-completion \
         subagent-driven-development dispatching-parallel-agents \
         requesting-code-review receiving-code-review \
         using-git-worktrees finishing-a-development-branch writing-skills; do
  [ -d "$SRC/skills/$s" ] && cp -R "$SRC/skills/$s" "<project>/.agents/skills/$s"
done
```

### Step 9：写 ROUTING.md

按规格 §4.2 必备章节填：
1. 组织架构（ASCII 图）
2. 派工硬约束（派工矩阵 + 跨域 ADR 清单）
3. Agent × Skill 路由矩阵
4. 派工示例（3 个标准模式）
5. 维护规则

**模板来源**：可以直接复用 `QuantAgents/.agents/ROUTING.md` 作为参考样板。

### Step 10：写 README.md（总览）

### Step 11：建软链 + 配 teammateMode + 写 /pm 命令

```bash
cd <project>
ln -s ../.agents/agents .claude/agents  # CC auto-discover
# .claude/settings.json 加 "teammateMode": "auto"
# .claude/commands/pm.md 写 PM 入口逻辑（参考 QuantAgents 版本）
```

### Step 12：写 ADR-0002（bootstrap 决策）

按规格 §7 Phase 3 step 11 写：
- 背景（为什么搭这个团队）
- 决策（装哪些 Agent / Skill，理由）
- 备选（至少 2 个方案对比）
- 权衡（已接受代价 / 正向收益）
- 后果（短期 / 长期 / 联动文档）

引用本规格文档与 4A 权威源。

### Step 13：校验 + commit

**校验清单**（必跑）：
- [ ] N/N Agent YAML 完整（name + description + tools）
- [ ] M/M Skill YAML 完整
- [ ] ROUTING 与 README 一致
- [ ] 软链能扫到所有 Agent（`ls .claude/agents/`）
- [ ] `teammateMode: "auto"` 在 `settings.json`
- [ ] `/pm` 命令在 `.claude/commands/pm.md`
- [ ] ADR-0002 + ADR-0001 都存在
- [ ] CLAUDE.md 顶部有"## 入口"指向 `/pm`

**commit**：
```bash
git add -A
git commit -m "feat(agents): bootstrap multi-agent org with PM entry

按 docs/standards/multi-agent-team-bootstrap.md 13 步流程搭建：
- N 个 Agent: pm, 4a-architect, ...
- M 个 Skill: 4 架构 + ... 
- 派工硬约束见 .agents/ROUTING.md
- /pm 入口见 .claude/commands/pm.md
- ADR-0002 登记 bootstrap 决策
- 引用本规格：docs/standards/multi-agent-team-bootstrap.md"
```

**push**前必须等用户审批（per CLAUDE.md "Commit or push only when the user asks"）。

## 输出物清单

完成后应有：

```
<project>/
├── .agents/
│   ├── README.md
│   ├── ROUTING.md              ← 派工权威源
│   ├── agents/                  ← N 个 .md
│   └── skills/                  ← M 个 SKILL.md
├── .claude/
│   ├── agents → ../.agents/agents  ← 软链
│   ├── commands/pm.md           ← /pm 入口
│   └── settings.json            ← 含 teammateMode=auto
├── docs/
│   ├── standards/
│   │   ├── architecture-collaboration-workflow.md  ← 4A 权威源
│   │   └── multi-agent-team-bootstrap.md          ← 搭建方法论权威源（本 skill 引用）
│   └── adr/
│       ├── 0001-4a-collaboration-baseline.md
│       └── 0002-agent-org-bootstrap.md
└── CLAUDE.md                    ← 顶部有"## 入口"指向 /pm
```

## 失败案例

参考规格 §9：
- **§9.1 业务 Lead 与执行专家拆成两个** → 合并成双角色
- **§9.2 `enabledAgents` 字段不存在** → 用软链代替
- **§9.3 周复盘错把教科书知识当候选** → 严格 `~/.claude/skills/weekly-retro/SKILL.md` 硬约束

## 与其他 skill 的关系

- `multi-plan` (CCG) — 用途不同：CCG multi-plan 调外部多模型（Codex + Gemini）出方案；本 skill 调**自有 Agent** 派工
- `superpowers:subagent-driven-development` — 是本 skill 的**子模式**：单任务内多 agent 协同
- `superpowers:dispatching-parallel-agents` — 是本 skill 的**并发模式**：并行多 agent
- `/weekly-retro` — 配套：**装好后**每周扫 7d 沉淀新知识

## 维护规则

- 本 skill 是规格的薄壳入口；**所有规则更新先改规格文档，再同步本 skill**
- 任何用户问"怎么改派工规则" → 必先开 ADR，再改 `ROUTING.md`，不要碰 Agent 提示词
- 任何"加新 Agent"需求 → 走规格 §8.1 流程，不要直接 cp
