---
name: pm-engine
description: PM 引擎路由开关 — 手动控制 4A 架构师与前端 Agent 的 AI 提供者（CC / Codex / Gemini / Antigravity）。状态持久化到 .claude/engine-config.json。
version: 1.0.0
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
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

> **关于 YOLO 模式**：3 个外部引擎（codex / gemini / agy）默认都有工具授权拦截（write_file / run_shell_command 等）。派工时必须带 YOLO 标志跳过拦截，否则引擎只能"打印建议"无法落盘。YOLO 标志的副作用：引擎拥有完整文件写权限 + 命令执行权限；建议只在受信任的 e2e 探针或 sandbox 任务中使用。

## 用法

```
/pm-engine <role> <engine>     # 设置某角色使用的引擎
/pm-engine status              # 查看当前配置
/pm-engine reset               # 全部切回 cc 默认
```

### 示例

```
/pm-engine 4a codex            # 4A 架构师派工走 Codex
/pm-engine 4a cc               # 4A 切回 CC 默认
/pm-engine frontend gemini     # 前端 Agent 走 Gemini
/pm-engine frontend agy        # 前端 Agent 走 Antigravity
/pm-engine frontend cc         # 前端切回 CC 默认
/pm-engine status              # 查看所有角色当前引擎
/pm-engine reset               # 全部切回 cc
```

## 支持的角色

| role 关键字 | 角色 | 可选引擎 |
|---|---|---|
| `4a` / `architect` | 4A 架构师（技术团队 Lead）| `cc`、`codex` |
| `frontend` / `fe` | 前端 Agent | `cc`、`gemini`、`agy` |

## 状态文件

`.claude/engine-config.json`，示例：

```json
{
  "4a": "cc",
  "frontend": "cc"
}
```

- 文件不存在时，全部角色默认 `cc`
- 文件存在但某 role 缺失时，缺失角色默认 `cc`
- 修改后立即生效，新派单走新引擎

## 实现要点（仅供维护者参考）

1. 用户调用 `/pm-engine <role> <engine>`
2. 校验 role 和 engine 合法性
3. 读/写 `.claude/engine-config.json`
4. 输出当前配置 + 下一步操作建议

## 配套改动

使用本 skill 后，`.claude/agents/4a-architect.md` 与 `.claude/agents/frontend-engineer.md`
需要在派工逻辑里加一段规则：派工前先读 `.claude/engine-config.json`，
按配置决定走 `Agent()` 还是 CLI 引擎。

详见各 agent 定义末尾的「引擎路由」段。
