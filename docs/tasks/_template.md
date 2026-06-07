# Task Plan Template

> **用途**：复制此文件 → `docs/tasks/<branch-name>.md`，按 10 步 checklist 逐项打勾。
> **强制要求**（CLAUDE.md）：任何非例行 commit（feature / fix / refactor）前必须建本文件，否则 `git commit` 会被 ``.claude/hooks/check-9step.sh`` 拦截。

---

## 元信息

- **任务 ID**：`0000-short-slug`
- **分支**：`feature/xxx` 或 `fix/xxx`
- **派工链**：PM → 业务 Lead / 4A → 专家
- **立项时间**：YYYY-MM-DD
- **需求来源**：用户直接提 / 业务 PM 转单

## 范围

- 目标：...
- 不在范围：...

## 验收标准

1. ...
2. ...

---

## 10 步 Checklist（每步必须显式打勾才算走完，**2026-06-07 修订：brainstorming 加为步 1**）

| # | 步骤 | 必走 Skill / 命令 | 状态 | 完成时间 | 备注 |
|---|---|---|---|---|---|
| 1 | **brainstorming** 需求粗调研 | superpowers:brainstorming | ☐ | | 输出粗调研报告 |
| 2 | **writing-plans** 写计划 | superpowers:writing-plans | ☐ | | 写 docs/solutions/<id>.md（Lead 写）|
| 3 | **/autoplan** 多视角审查 | gstack:/autoplan（调 Codex + Gemini 审） | ☐ | | 计划获批才能进 #4 |
| 4 | **subagent-driven-development** 编码 | superpowers:subagent-driven-development | ☐ | | PM 按方案 assignments 派 L2 |
| 5 | **TDD** 验证（单测/集成） | superpowers:test-driven-development | ☐ | | |
| 6 | **systematic-debugging** 调试（如需） | superpowers:systematic-debugging | ☐ | | |
| 7 | **/qa** 真实环境验证 | gstack:/qa | ☐ | | |
| 8 | **code-review** 代码审查 | superpowers:requesting-code-review | ☐ | | |
| 9 | **/ship** 发布 | gstack:/ship | ☐ | | |
| 10 | **/cso** 安全审计 | gstack:/cso | ☐ | | 发布前 |

---

## 风险与缓解

| 风险 | 缓解 |
|---|---|
| ... | ... |

## 进度日志

- YYYY-MM-DD HH:MM — Step X 完成
- YYYY-MM-DD HH:MM — 阻塞原因 / 解法
