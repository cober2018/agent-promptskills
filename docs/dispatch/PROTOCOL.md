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
| PM 推进 10 步用 `AskUserQuestion` 或口头"ping owner" | PM 改 dispatch md 的 `pm_pinged_at` + `last_pm_note` |

## 2. dispatch md 模板

文件路径：`docs/dispatch/<id>.md`，文件名约定 `<YYYYMMDD>-<slug>.md`。

### L1 派工包（PM → Lead，layer=L1）

```yaml
---
id: 0025-factor-diagnosis-redesign
created_at: 2026-06-07 14:30:00
created_by: pm
title: 因子诊断页面 UX 重构
owner: 4a-architect          # L1 接收方：4a-architect / quant-lead / <Lead>
layer: L1                    # L1（派 Lead 写方案）
priority: P1                  # P0 / P1 / P2
status: pending               # pending → investigating → solution_ready → ready_to_dispatch | blocked
solution_ref: null            # L1 完成时填 docs/solutions/<id>.md
assignments: []               # L1 完成时填 [{ic, task}, ...]
artifact: null
pm_pinged_at: null
last_pm_note: null
---

# 派工包（L1）

## 任务背景
（≤ 5 行：什么场景、为什么做）

## 任务目标
（具体动作 / 产物）

## 子任务列表
- [ ] T1: xxx
- [ ] T2: xxx

## 验收标准（DoD）
- [ ] 方案落 `docs/solutions/<id>.md`
- [ ] assignments 列明 L2 派给哪些 IC

## 派工 context
- 关联 ADR: ADR-NNNN
- 关联 requirement: docs/requirements/NNNN
- 派工包参考: docs/dispatch/<id>.md

## 进度日志
- 2026-06-07 14:30 [pm] L1 落盘，status=pending, owner=4a-architect
- 2026-06-07 14:35 [4a] 接单，status=investigating
- 2026-06-07 18:00 [4a] 方案完成，status=solution_ready
- 2026-06-07 19:00 [pm] 方案校验通过，status=ready_to_dispatch
```

### L2 派工包（PM → IC，layer=L2）

```yaml
---
id: 0025-factor-diagnosis-redesign-frontend
created_at: 2026-06-07 19:00:00
created_by: pm
title: 因子诊断页面 UX 重构 - 前端
owner: frontend-engineer      # L2 接收方：backend-engineer / frontend-engineer / data-engineer / qa-engineer / <IC>
layer: L2                    # L2（派 IC 执行）
solution_ref: docs/solutions/2026-06-07-factor-diagnosis-redesign.md   # **必填**
assignments: [{ic: frontend-engineer, task: '因子卡片 + 因子排行 UI'}]
priority: P1
status: pending               # pending → in_progress → review → done | blocked
artifact: null
pm_pinged_at: null
last_pm_note: null
---

# 派工包（L2）

## 任务背景
（≤ 5 行：什么场景、为什么做）

## 任务目标
（具体动作 / 产物）

## 方案参考
详见 `docs/solutions/2026-06-07-factor-diagnosis-redesign.md`（**必读**）

## 子任务列表
- [ ] T1: xxx
- [ ] T2: xxx

## 验收标准（DoD）
- [ ] 单测全过
- [ ] **PM 真实 e2e**（强制动作 —— mock 绿 ≠ 端到端绿）
- [ ] artifact 路径填到本 dispatch md 的 `artifact` 字段

## 派工 context
- 关联 L1 派工包: docs/dispatch/0025-factor-diagnosis-redesign.md
- 关联方案: docs/solutions/2026-06-07-factor-diagnosis-redesign.md
- 关联 ADR: ADR-NNNN
- 关联 requirement: docs/requirements/NNNN

## 进度日志
- 2026-06-07 19:00 [pm] L2 落盘，owner=frontend-engineer, solution_ref=<path>
- 2026-06-07 19:05 [frontend] 接单，status=in_progress
- 2026-06-07 22:00 [frontend] 完成，status=review
- 2026-06-08 09:00 [pm] 真实 e2e 验收通过，status=done
```

## 3. 状态机（状态链，**2026-06-07 修订**）

### L1 状态链

```
pending                     # PM 落盘
   ↓ Lead 接单
investigating               # Lead 调研中
   ↓ Lead 完成方案
solution_ready              # 方案 + assignments 已落
   ↓ PM 校验通过
ready_to_dispatch           # 待派 L2
   ↘ 任何步卡住
blocked                     # 谁卡的 + 卡因 + 升级
```

### L2 状态链

```
pending                     # PM 落盘（**必填** solution_ref）
   ↓ IC 接单
in_progress                 # IC 改
   ↓ IC 完成
review                      # 待 Lead 评审 + 真实 e2e
   ↓ review + 真实 e2e 过
done                        # 写 artifact + commit hash
   ↘ 任何步卡住
blocked                     # 谁卡的 + 卡因 + 升级
```

## 4. 角色动作（**2026-06-07 修订：4 动作**）

### PM 派工 4 动作（**核心：L1 + L2 都由 PM 派**）

#### 动作 1：派 L1（owner=Lead）
1. Write 写 `docs/dispatch/<id>.md`，frontmatter 填 `owner=<Lead>` / `layer=L1` / `status=pending` / `solution_ref: null` / `assignments: []`
2. **不要**调 `Agent()`（PM 工具列表里没有）
3. **不要**只设 `TaskUpdate(owner=...)`（那只是 metadata，Lead 不知道）

#### 动作 2：校验方案（L1 完成调研后）
1. Read L1 dispatch md → status=`solution_ready`
2. Read `docs/solutions/<id>.md`（Lead 写的方案）
3. 校验：方案是否完整 / assignments 是否合理 / 架构是否一致
4. 校验通过 → 改 L1 status=`ready_to_dispatch`
5. 进度日志写 `[pm] 方案校验通过，assignments=<...>`

#### 动作 3：派 L2（owner=IC，**PM 派 IC 是核心**）
1. Write 写 `docs/dispatch/<id>.md`（**L2**），frontmatter 填 `owner=<IC>` / `layer=L2` / `solution_ref=<path>`（**必填**）/ `assignments: [{ic, task}, ...]`
2. status=`pending`
3. 进度日志写 `[pm] L2 派工包落盘，owner=<IC>, solution_ref=<path>`

#### 动作 4：改 done（**前提：Lead 评审通过 + 真实 e2e 跑通**）
1. Read L2 dispatch md → status=`review`
2. 校验进度日志有 `[lead] 评审通过`
3. PM 自己跑真实 e2e 三件套（服务 / 鉴权 / 链路）
4. 校验通过 → 进度日志写 `[pm] 真实 e2e 验收通过，<时间戳>`
5. 改 status=`review` → `done`

### Lead 接单时（L1）
1. 启动时用 Read/Glob 查 `docs/dispatch/*.md` 找 `layer=L1 AND status=pending AND owner=<自己>`
2. 接单 → 改 status=`investigating` + 写进度日志
3. 写方案到 `docs/solutions/<id>.md`（必填 assignments 数组）
4. 改 status=`solution_ready` + 填 `solution_ref` 字段
5. 阻塞 → 改 status=`blocked` + 写卡因

### Lead 完成时（L2 → review）
1. L2 dispatch md status=`review` 时
2. Lead 评审 → 进度日志写 `[lead] 评审通过` 或 `[lead] 评审不通过: <原因>`
3. 评审通过 → 不动 status，等 PM 跑真实 e2e

### IC 接单时（L2）
1. 启动时用 Read/Glob 查 `docs/dispatch/*.md` 找 `layer=L2 AND status=pending AND owner=<自己>`
2. **校验 `solution_ref` 字段非空**（没有 = 拒绝接单，反馈 PM）
3. Read 派工包 + 读 `docs/solutions/<id>.md` 方案
4. 接单 → 改 status=`in_progress` + 写进度日志
5. 完成 → 改 status=`review` + 填 `artifact` 字段

### PM 推进 10 步时
1. 用 Read 查 `docs/dispatch/<id>.md` 看 status
2. 卡 24h+ → 改 `pm_pinged_at` + `last_pm_note`（给 Lead 留言）
3. 卡 72h+ → 升级 User

### 主 session 轮询（**强约束**）
每个 turn 开头：
1. Glob `docs/dispatch/*.md`
2. 找 `status=pending` 的包
3. 对每个 pending 包：
   - 解析 frontmatter 的 `layer` 字段（L1 / L2）
   - 解析 `owner` 字段
   - `Agent(subagent_type=owner, prompt=<payload>)` 派 Lead / IC
   - L1：改 status=`investigating`；L2：改 status=`in_progress`

## 5. 与 TaskCreate / TaskUpdate 的关系

| 工具 | 何时用 | 何时不用 |
|---|---|---|
| `TaskCreate` / `TaskUpdate` | **PM 自己的 todo list**（PM 推进 10 步时的待办，不是派工）| 派工通知（用 dispatch md）|
| `dispatch md` (L1) | **派 Lead 写方案**（PM → Lead）| 派 IC（用 L2 dispatch md）|
| `dispatch md` (L2) | **派 IC 执行**（PM → IC，**必填** `solution_ref`）| 派 Lead（用 L1 dispatch md）|

**硬规则**：`TaskUpdate(owner=...)` **不等于派工**——这只是 metadata 字段，Lead / IC 不知道。**任何派工动作必须以 dispatch md 落盘为准**。

**L1 / L2 边界**：
- L1（派 Lead）= `owner=Lead` + `layer=L1` + `solution_ref=null`
- L2（派 IC）= `owner=IC` + `layer=L2` + `solution_ref=<path>`（**必填**）
- L1 → L2 必经 `solution_ready` + `ready_to_dispatch` 状态

## 6. 迁移期

2026-06-07 ~ 2026-06-14 过渡：
- 新派工一律走 dispatch md（L1 + L2 都要落盘）
- 老 `TaskUpdate(owner=...)` 还能用，但**不再被 Lead 主动巡检**
- 现有 ADR / REVIEW 里的派工描述保留原样（仅历史）
- L1 / L2 渐进启用：先 L1（派 Lead 写方案），方案就绪后启 L2（PM 派 IC）
- 已存在 dispatch md 可逐步补 `layer` / `solution_ref` 字段；缺失视为 L1（兼容旧派工）

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
| **PM 跳过 L1 直接派 L2** | 没有方案，IC 接到任务没有 `solution_ref` | L2 dispatch md 必填 `solution_ref`，IC 接单时校验 |
| **PM 改 done 跳过真实 e2e** | mock 绿 ≠ 端到端绿 | 改 done 必经 `[lead] 评审通过` + `[pm] 真实 e2e 通过` |
| **Lead 私派 IC** | 派工链路不可追溯 | Lead 派 IC 必走 PM 派 L2（除非 4A 内部 IC 拆分） |
| **L1→L2 跳级** | PM 直接从 `pending` 派 L2，没经过 `solution_ready` | L1 必经 `investigating` → `solution_ready` → `ready_to_dispatch` 才能派 L2 |
