---
name: QuantAgents 多 Agent 架构优化回灌 spec
description: 把 QuantAgents 项目（基于本模板的实例）跑通期间沉淀的优化——单入口导航 / /pm 命令 / 9 步链路硬化 / 量化双角色合一——沉淀回本模板仓库。
type: design
status: Draft
date: 2026-06-05
---

# QuantAgents 多 Agent 架构优化回灌

## 1. 背景

本仓库（`agent-promptskills`）是**多 Agent 协作团队模板**。QuantAgents（`/Users/mshengran/Project/QuantAgents`）是基于本模板 bootstrap 的第一个真实项目实例，跑通后沉淀了若干优化点。本 spec 把这些优化回灌到本模板，做成"沉淀 → 复用"闭环。

### 1.1 本次回灌的优化

| 优化项 | 来源 | 在 QuantAgents 的形态 | 回灌到本模板 |
|---|---|---|---|
| 单入口导航页 | 新增 | `docs/standards/AGENT_ORG_INDEX.md` | `docs/standards/AGENT_ORG_INDEX.md`（路径适配） |
| 派工硬约束权威源 | 新增 | `.agents/ROUTING.md` | `agents/ROUTING.md`（含 Agent × Skill 路由矩阵） |
| .agents 总览 | 新增 | `.agents/README.md` | `agents/README.md` |
| 业务 PM Agent（含"推进官"硬化）| 新增 | `.agents/agents/pm.md`（2026-06-05 硬化：name 加"推进官"、核心使命加"9 步推进"、新增完整 `## 推进 9 步` 节）| `agents/pm.md`（采用 QuantAgents 最新版，**不重写**）|
| 量化双角色合一（ADR-0003） | 改造 | `quant-researcher.md` 单文件 | 删除 `agents/quant/` 4 子文件 → 新增 `agents/quant-researcher.md` |
| /pm 命令入口 | 新增 | `.claude/commands/pm.md` | `.claude/commands/pm.md` |
| 9 步链路 PreToolUse hook | 新增 | `.claude/hooks/check-9step.sh` | `.claude/hooks/check-9step.sh` |
| 9 步 plan 模板 | 新增 | `docs/tasks/_template.md` | `docs/tasks/_template.md` |
| 7 个同名 Agent 优化差异 | 同步 | diff 已生成 | 按需 merge |
| 3 个 standards 优化差异 | 同步 | diff 已生成 | 按需 merge |

### 1.2 不在本次范围

- `AGENT_SCHEDULER_GUIDE.md` —— QuantAgents 项目特定（APScheduler 平台架构），不属于通用沉淀。
- `三主题域落地*.md` / `数据仓库架构文档.md` / `数据字典.md` / `数据源接口上下文文档.md` / `金融数仓开发规范.md` —— 全部项目特定。
- 用户级 / 跨项目 memory（`~/.claude/projects/.../memory/`）—— 不在 git repo 内。
- 用户级 skill（`~/.claude/skills/weekly-retro/` 等）—— 不在 git repo 内。

### 1.3 路径适配

QuantAgents 用 `.agents/`（带点号目录），本模板用 `agents/`。INDEX 与所有引用路径需按本模板实际目录调整；hook 与命令路径以本模板的 `.claude/` 为准（首次创建）。

## 2. 设计

### 2.1 文件级变更清单

#### 2.1.1 新增（10 个文件）

| 路径 | 来源 | 说明 |
|---|---|---|
| `docs/standards/AGENT_ORG_INDEX.md` | QuantAgents 移植 | 5 类文件清单 + 启动顺序 5 分钟上手 + 引用关系图；路径适配本模板（`agents/` 而非 `.agents/`）|
| `agents/ROUTING.md` | QuantAgents 移植 | 派工硬约束 + Agent × Skill 路由矩阵 |
| `agents/README.md` | QuantAgents 移植 | `agents/` 目录总览 |
| `agents/pm.md` | QuantAgents 移植 | 业务 PMO（PM / 需求分流官 / **推进官** 三角色合一；含完整 `## 推进 9 步` 节；含 `## 卡时升级模板` + `## 升级 User 模板`）|
| `agents/quant-researcher.md` | QuantAgents 移植 | 双角色合一（业务 Lead + 技术执行者）|
| `.claude/commands/pm.md` | QuantAgents 移植 | `/pm` 入口命令 |
| `.claude/hooks/check-9step.sh` | QuantAgents 移植 | 9 步链路 PreToolUse 拦截（需 `chmod +x`）|
| `docs/tasks/_template.md` | QuantAgents 移植 | 9 步 plan 模板 |
| `docs/superpowers/specs/2026-06-05-quantagents-org-backport-design.md` | 本 spec | （本文件）|
| `docs/adr/0003-quant-team-merge.md` | 新写 | 记录 quant 4 合 1 决策的 ADR（与 QuantAgents ADR-0003 对齐）|

#### 2.1.2 删除（4 个文件）

| 路径 | 说明 |
|---|---|
| `agents/quant/quant-china-market-analyst.md` | 由 `quant-researcher.md` 覆盖 |
| `agents/quant/quant-factor-researcher.md` | 由 `quant-researcher.md` 覆盖 |
| `agents/quant/quant-news-social-analyst.md` | 由 `quant-researcher.md` 覆盖 |
| `agents/quant/quant-strategy-researcher.md` | 由 `quant-researcher.md` 覆盖 |

> 一次性替换（用户确认）：不留 deprecated 标签，直接删除。原始 git 历史可追溯。

#### 2.1.3 同步差异（10 个文件，merge 内容）

| 文件 | merge 策略 |
|---|---|
| `agents/4a-architect.md` | 采用 QuantAgents 优化版（写入与新 ROUTING.md 一致的硬约束指针）|
| `agents/backend-engineer.md` | 同步 |
| `agents/frontend-engineer.md` | 同步 |
| `agents/data-engineer.md` | 同步 |
| `agents/qa-engineer.md` | 同步 |
| `docs/standards/multi-agent-team-bootstrap.md` | 同步（与新 ROUTING.md 互相引；**采用 QuantAgents 2026-06-05 硬化版**：新增 `§1.4 PM 推进官职责` + `§3.4 PM 持续推进 9 步` + 重写 `§6.1 PM 模板`）|
| `docs/standards/architecture-collaboration-workflow.md` | 同步 |
| `docs/standards/agent-delivery-responsibility-routing.md` | 同步 |
| `README.md` | 顶部加引用 INDEX + 9 步链路段（不替换全文，只加链接）|
| `docs/skill-lifecycle.md` | 顶部加 9 步链路提示 + INDEX 引用 |

### 2.2 适配原则

1. **路径前缀**：所有 `.agents/` → `agents/`；所有 QuantAgents 路径换成模板路径。
2. **保留本模板独有资产**：devops-engineer、new-media-operator、video-editing-coach、Skill 治理（skillify / skill-health / pruning-skills）、新媒体系列 skills、observability-ops、cicd-engineering 全部保留。
3. **不要把 ROUTING.md 与 agent-delivery-responsibility-routing.md 合并**：前者是 Agent×Skill 路由矩阵 + 派工硬约束；后者是按"任务类型"分主责的判定标准。两者正交。
4. **QuantAgents 改的 5 个 Agent 内容需逐字 merge**（不用 git merge，用人工 diff 决策，因为两边分支独立演进）。
5. **新 `quant-researcher.md` 不带 quant/ 子目录**：保持顶层 `agents/` 一致的扁平结构。
6. **AGENT_ORG_INDEX.md §3.1 Agent 清单扩展**：本模板独有的 devops / new-media / video 三个 agent 也列入；不在范围中。
7. **/pm 命令 + check-9step.sh hook 启用前置**：hook 需 `chmod +x`；hook 的 `docs/tasks/` 路径校验与本模板布局一致。
8. **`pm.md` 内链路径适配**（QuantAgents 路径 → 本模板路径）：
   - `../../docs/standards/multi-agent-team-bootstrap.md` → `../docs/standards/multi-agent-team-bootstrap.md`（少一级 `..`）
   - `../../.agents/ROUTING.md` → `ROUTING.md`（同目录）
   - `../../README.md` → `../README.md`（少一级 `..`）

### 2.3 验收标准

| # | 验证项 | 方法 |
|---|---|---|
| 1 | 10 个新文件全部存在 | `ls` + 文件大小 > 0 |
| 2 | 4 个 quant 旧文件全部删除 | `ls agents/quant/` 为空目录（可保留空目录或删）|
| 3 | 7 个同名 Agent / 3 个同名 standards 内容已同步 | `diff` 关键段（pm 引用、4A 硬约束、ROUTING 引用）|
| 4 | README.md + docs/skill-lifecycle.md 已加 INDEX 引用 | `grep` 关键词 |
| 5 | 新 `quant-researcher.md` 包含双角色段 | `grep "业务 Lead\\|执行模式"` |
| 6 | ROUTING.md 派工矩阵 + Agent×Skill 路由矩阵存在 | 段标题 grep |
| 7 | AGENT_ORG_INDEX.md 5 类文件清单 + 启动顺序存在 | 段标题 grep |
| 8 | `/pm` 命令可识别 | 文件 frontmatter 含 `name: PM` |
| 9 | `check-9step.sh` 可执行 | `[ -x .claude/hooks/check-9step.sh ]` |
| 10 | `docs/tasks/_template.md` 9 步 checklist 全列 | `grep "writing-plans\\|/autoplan\\|subagent-driven-development\\|TDD\\|systematic-debugging\\|/qa\\|code-review\\|/ship\\|/cso"` |
| 11 | `docs/adr/0003-quant-team-merge.md` 存在 | `ls docs/adr/` |
| 12 | 不破坏现有 14 个 Skill（Skill 治理 / 新媒体系列）| `ls skills/` 对比前后 |
| 13 | 路径一致性：INDEX 引用全部用 `agents/` 前缀（无 `.agents/`）| `grep -r "\\.agents/" docs/standards/AGENT_ORG_INDEX.md` 应为空 |

### 2.4 风险与缓解

| 风险 | 缓解 |
|---|---|
| 同步 7 个 Agent 时人工 merge 漏段 | 用 `diff` 出 QuantAgents 与本模板的差异段，逐段确认 |
| `quant-researcher.md` 与新角色（devops / new-media）边界不清 | INDEX §3.1 显式标注本模板独有 agent；ROUTING.md 同步增列 |
| `check-9step.sh` 启用后误拦 commit | 脚本支持 `git commit --no-verify` 旁路；本仓库 README 提示用法 |
| 删除 4 个 quant 文件破坏外部引用 | `git log --diff-filter=D` 保留历史；ADR 记录决策 |
| 新 `quant-researcher.md` 与本模板 quant 拆分工种（analyst/factor/news/strategy）业务经验冲突 | 写 ADR 解释为什么合并更优（参照 QuantAgents ADR-0003）|

## 3. 实施阶段（不在本 spec 展开，仅列大纲）

writing-plans 阶段会拆为：
1. 准备阶段：建 `docs/superpowers/specs/`、建 `.claude/`、建 `docs/tasks/`
2. 增量阶段：先加新文件（不删旧）→ 同步差异 → 一次性替换 quant
3. 收尾阶段：建 ADR、跑 grep 校验、README/skill-lifecycle 顶部加引用
4. 验收：跑 13 项验收标准

## 4. 不做的事

- 不重写 INDEX 全文——只适配路径、增列本模板独有 agent
- 不重构 4A 治理基线——5 条硬约束、ADR 流程保持不变
- 不动 `~/.claude/` 任何用户级配置
- 不改 superpowers 全家桶
- 不写任何额外文档或 README
