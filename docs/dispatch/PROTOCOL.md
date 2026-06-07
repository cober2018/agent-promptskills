# Dispatch 协议规范（2026-06-07 新增）

> **权威源（Authoritative Source）**
> 本文件是"PM → Lead"派工协议的唯一权威源。
> Agent 提示词（`agents/*.md`）和 standards 文档只承载自检硬约束，**不内联**协议细节。
> 提示词/文档与本文冲突时，**以本文为准**。

## 1. 核心问题与解决

| 老协议 | 新协议 |
|---|---|
| PM 用 `TaskUpdate(taskId, owner='4a-architect')` 标"派工"——但**Lead 根本不知道**有派单 | PM 写 `docs/dispatch/<id>.md`（status=pending）= 显式派工通知 |
| PM 用 `TaskList` 跟踪进度——但**Lead 不读 TaskList** | Lead 改 dispatch md 的 `status` + `artifact` 字段，PM 读同一份 |
| 派工信号靠 LLM 自觉遵守 prompt | 派工信号靠**文件落盘**（ground truth）|
| PM 推进 9 步用 `AskUserQuestion` 或口头"ping owner" | PM 改 dispatch md 的 `pm_pinged_at` + `last_pm_note` |

## 2. dispatch md 模板

文件路径：`docs/dispatch/<id>.md`，文件名约定 `<YYYYMMDD>-<slug>.md`。

```yaml
---
id: 0025-factor-diagnosis-redesign
created_at: 2026-06-07 14:30:00
created_by: pm
title: 因子诊断页面 UX 重构
owner: 4a-architect          # 接收方：4a-architect / quant-lead / <domain>
priority: P1                  # P0 / P1 / P2
status: pending               # pending → in_progress → review → done | blocked
---

# 派工包

## 任务背景
（≤ 5 行：什么场景、为什么做）

## 任务目标
（具体动作 / 产物）

## 子任务列表
- [ ] T1: xxx
- [ ] T2: xxx

## 验收标准（DoD）
- [ ] 单测全过
- [ ] **PM 真实 e2e**（强制动作 —— mock 绿 ≠ 端到端绿）
- [ ] artifact 路径填到本 dispatch md 的 `artifact` 字段

## 派工 context
- 关联 ADR: ADR-NNNN
- 关联 requirement: docs/requirements/NNNN
- 派工包参考: docs/dispatch/<id>.md

## 进度日志
- 2026-06-07 14:30 [pm] 派工包落盘，status=pending
- 2026-06-07 14:35 [4a] 接单，status=in_progress
- ...
```

## 3. 状态机

```
pending                     # PM 落盘
   ↓ Lead 接单
in_progress                 # Lead 改
   ↓ Lead 完成
review                      # 待 QA 或 4A review
   ↓ review 过
done                        # Lead 写 artifact + commit hash
   ↘ 任何步卡住
blocked                     # 谁卡的 + 卡因 + 升级
```

## 4. 角色动作

### PM 派工时
1. 写 `docs/dispatch/<id>.md`（status=pending）
2. **不要**调 `Agent()`（PM 工具列表里没有）
3. **不要**只设 `TaskUpdate(owner=...)`（那只是 metadata，Lead 不知道）

### Lead 接单时
1. 启动时用 Read/Glob 查 `docs/dispatch/*.md` 找 `status=pending AND owner=<自己>`
2. 接单 → 改 status=in_progress + 写进度日志
3. 阻塞 → 改 status=blocked + 写卡因

### Lead 完成时
1. 改 status=review
2. 写 `artifact` 字段（commit hash / 文件路径 / 报告路径）
3. QA 过了或 review 过了 → 改 status=done

### PM 推进 9 步时
1. 用 Read 查 `docs/dispatch/<id>.md` 看 status
2. 卡 24h+ → 改 `pm_pinged_at` + `last_pm_note`（给 Lead 留言）
3. 卡 72h+ → 升级 User

### 主 session 轮询（**强约束**）
每个 turn 开头：
1. Glob `docs/dispatch/*.md`
2. 找 status=pending 的包
3. 对每个 pending 包：
   - 解析 frontmatter 的 `owner` 字段
   - `Agent(subagent_type=owner, prompt=<payload>)` 派 Lead
   - 改 status=in_progress（标记"已接"，但 Lead 实际启动后可能改成自己的 in_progress 标记）

## 5. 与 TaskCreate / TaskUpdate 的关系

| 工具 | 何时用 | 何时不用 |
|---|---|---|
| `TaskCreate` / `TaskUpdate` | **PM 自己的 todo list**（PM 推进 9 步时的待办，不是派工）| 派工通知（用 dispatch md）|
| `dispatch md` | **派工通知 + 进度跟踪**（PM → Lead → IC → QA）| 纯 PM 内部 todo（用 TaskList）|

**硬规则**：`TaskUpdate(owner=...)` **不等于派工**——这只是 metadata 字段，Lead 不知道。**任何派工动作必须以 dispatch md 落盘为准**。

## 6. 迁移期

2026-06-07 ~ 2026-06-14 过渡：
- 新派工一律走 dispatch md
- 老 `TaskUpdate(owner=...)` 还能用，但**不再被 Lead 主动巡检**
- 现有 ADR / REVIEW 里的派工描述保留原样（仅历史）

## 7. 例子

完整生命周期（[example.md](./2026-06-07-EXAMPLE.md)）：
1. PM 写 pending 包
2. 主 session 看到 pending → 派 Lead
3. Lead 改 in_progress → review
4. PM 改 done

## 8. 失败模式

| 失败 | 表现 | 修复 |
|---|---|---|
| PM 忘写 dispatch | Lead 不接单，TaskList 显示"已派"但实际无活 | 改 PM prompt 加 checklist |
| Lead 不查 dispatch | 派单堆积 pending | 改 Lead prompt 启动时必查 |
| 主 session 不轮询 | dispatch pending 永远 pending | 改主 session prompt 加 turn 开头 checklist |
| status 字段被任意改 | 状态机破坏 | dispatch md 加 lint（[future]）|
