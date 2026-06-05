---
name: pm-engine
description: PM 引擎路由开关 — 手动控制 4A 架构师与前端 Agent 的 AI 提供者（CC / Codex / Gemini / Antigravity）。交互式菜单选择，状态持久化到 .claude/engine-config.json。
version: 2.0.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# /pm-engine — 派工引擎路由开关

## 用途

手动切换 4A 架构师与前端 Agent 派工时使用的 AI 引擎。当前支持 4 个引擎：

| 引擎 | CLI（YOLO 模式）| 适用角色 |
|---|---|---|
| `cc` | Claude Code `Agent()` | 默认；4A / 前端 |
| `codex` | `codex exec --dangerously-bypass-approvals-and-sandbox "<prompt>"` | 4A 架构师（困难任务）|
| `gemini` | `gemini -p --yolo "<prompt>"` | 前端 |
| `agy` | `agy --dangerously-skip-permissions --print "<prompt>"` | 前端（Antigravity） |

> **关于 YOLO 模式**：3 个外部引擎（codex / gemini / agy）默认都有工具授权拦截。派工时必须带 YOLO 标志跳过拦截，否则引擎只能"打印建议"无法落盘。建议只在受信任的 sandbox / e2e 探针任务中使用。

## 交互流程

被调用时按以下 4 步执行（**不要跳步**）：

### Step 1 — 读取并显示当前配置

```bash
bash .claude/skills/pm-engine/route.sh status
```

**展示规则**：先打印当前状态（用 `route.sh status` 的输出原文），再继续 Step 2。如果配置文件不存在，明确告诉用户"全部角色默认 cc"。

### Step 2 — 用 AskUserQuestion 询问"操作类型"

**问题**：「你要做什么？」

**4 个选项（4 选 1）**：

| 选项目（label）| 描述（description）| value |
|---|---|---|
| 切换 4A 架构师引擎 | 修改 4A 派工时使用的 AI 引擎 | `set-4a` |
| 切换前端 Agent 引擎 | 修改前端派工时使用的 AI 引擎 | `set-frontend` |
| 全部切回 cc 默认 | 重置 4A 与前端都为 CC | `reset` |
| 只查看当前配置 | 不修改，只看 | `view` |

**用 `AskUserQuestion` 调用，header 写 "操作"**。

### Step 3 — 二级路由（**无 LLM 决策**）

收到 Step 2 的答案后，**立即**按下面条件分支，**不要输出任何中间文字**：

| Step 2 答案 | 动作 |
|---|---|
| `set-4a` | **立即**调 AskUserQuestion 问「4A 架构师用哪个引擎？」（header: "4A 引擎"，2 选 1：`cc` / `codex`）|
| `set-frontend` | **立即**调 AskUserQuestion 问「前端 Agent 用哪个引擎？」（header: "前端引擎"，3 选 1：`cc` / `gemini` / `agy`）|
| `reset` | **立即**执行 `bash .claude/skills/pm-engine/route.sh reset`，输出原文，结束本轮 |
| `view` | **立即**再跑一次 `bash .claude/skills/pm-engine/route.sh status`（或直接复用 Step 1 输出），结束本轮 |

**绝对禁止**：在 Step 2 答案与 Step 3 弹窗之间写任何分析、说明、解释。LLM 在这一步只做"看答案 → 弹下一题"的路由，不做思考。

### Step 4 — 应用设置（仅 set-4a / set-frontend 走）

根据 Step 3 收集到的 `<engine>`，执行：

```bash
bash .claude/skills/pm-engine/route.sh <role> <engine>
```

`<role>` 已在 Step 2 选定（`set-4a` → `4a`，`set-frontend` → `frontend`）。

示例：用户选 `set-4a` + `codex` → 执行 `bash .claude/skills/pm-engine/route.sh 4a codex`

### Step 5 — 确认

展示 `route.sh` 的输出（已包含新配置 + 路径），结束本轮 skill。**不要再追加任何"下一步"或额外说明文字。**

## 支持的角色与引擎矩阵

| 角色 | 可选引擎 |
|---|---|
| 4A 架构师 | `cc`、`codex` |
| 前端 Agent | `cc`、`gemini`、`agy` |

## 状态文件

`.claude/engine-config.json`，示例：

```json
{
  "4a": "cc",
  "frontend": "cc"
}
```

- 文件不存在 → 全部角色默认 `cc`
- 某 role 字段缺失 → 该 role 默认 `cc`
- 修改后立即生效，新派单走新引擎

## 实现细节（仅供维护者参考）

- `route.sh` 是状态管理后端；SKILL.md 是用户流程前端
- 菜单用 `AskUserQuestion` 工具，禁止让用户手敲命令
- 改配置后必须展示新状态，让用户看到变化
- 4A / 前端 agent 定义里有「引擎路由」段，读 config 决定走哪条路

## 配套改动

使用本 skill 后，`.agents/agents/4a-architect.md` 与 `.agents/agents/frontend-engineer.md`
需要在派工逻辑里加一段规则：派工前先读 `.claude/engine-config.json`，
按配置决定走 `Agent()` 还是 CLI 引擎。

详见各 agent 定义末尾的「引擎路由」段。
