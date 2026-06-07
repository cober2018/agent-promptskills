# 解决方案目录（`docs/solutions/`）

> **用途**：Lead（L1 接单方）完成调研后，把详细方案写到本目录，供 PM 派 L2 时引用为 `solution_ref`。
>
> **权威源**：`docs/dispatch/PROTOCOL.md`

## 文件命名规范

`<YYYYMMDD>-<slug>.md`，与对应 L1 dispatch md 同名 slug。

例：L1 dispatch md = `docs/dispatch/2026-06-07-factor-diagnosis-redesign.md` → 方案 = `docs/solutions/2026-06-07-factor-diagnosis-redesign.md`

## 必填字段

每个方案文件必须包含以下内容（PM 校验时检查）：

| 章节 | 必填 | 说明 |
|---|---|---|
| 任务背景 | ✅ | ≤ 5 行（什么场景、为什么做）|
| 现状 / 风险 / 依赖 | ✅ | Lead 调研结果 |
| 架构 / 设计权衡 | ✅ | 选了什么、不选什么、为什么 |
| 子任务拆解 | ✅ | 按 IC 视角拆，每条对应一个 L2 派工单 |
| **`assignments` 数组** | ✅ | `[{ic, task, solution_ref, dependencies}, ...]`（**核心**）|
| 验收标准（DoD）| ✅ | 每条子任务的 DoD |
| ADR 引用 | ⏸ 跨域时填 | `docs/adr/NNNN-xxx.md` |
| 风险与回退 | ✅ | 关键决策的回退方案 |

## `assignments` 字段（**PM 派 L2 的依据**）

```yaml
assignments:
  - ic: frontend-engineer
    task: 因子卡片 + 因子排行 UI 重构
    solution_ref: docs/solutions/2026-06-07-factor-diagnosis-redesign.md#frontend
    dependencies: []
  - ic: backend-engineer
    task: 因子计算 API + 性能优化
    solution_ref: docs/solutions/2026-06-07-factor-diagnosis-redesign.md#backend
    dependencies: [data-engineer]
  - ic: data-engineer
    task: 因子落表 + DQC 门禁
    solution_ref: docs/solutions/2026-06-07-factor-diagnosis-redesign.md#data
    dependencies: []
```

PM 校验通过后，按 `assignments` 数组 **1 对 1 写 L2 dispatch md**（每个 IC 一张单）。

## 状态机

- L1 dispatch md 状态变 `solution_ready` → 方案文件已写好
- L1 dispatch md 状态变 `ready_to_dispatch` → PM 校验通过，可派 L2
- L2 dispatch md 状态变 `done` → 方案归档（**不删**）

## 不做的事

- ❌ **不**在方案里写代码（代码归 L2 IC 写）
- ❌ **不**在方案里写 dispatch md 派工单（PM 派）
- ❌ **不**在方案里写完整 QA 报告（qa-engineer 写）
- ❌ **不**直接改 `docs/dispatch/<id>.md` 的 `solution_ref` 字段（PM 改）

## 例子

见 `docs/dispatch/PROTOCOL.md` § 2 模板与 § 3 状态机。
