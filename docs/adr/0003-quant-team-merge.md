# ADR-0003: 量化团队 4 合 1（quant-researcher 单文件 + 双角色合一）

- **状态**：Accepted
- **日期**：2026-06-05
- **决策者**：业务 PMO（回灌自 QuantAgents ADR-0003）

## 背景

本模板原本在 `agents/quant/` 目录下提供 4 个 quant Agent：
- `quant-china-market-analyst.md`
- `quant-factor-researcher.md`
- `quant-news-social-analyst.md`
- `quant-strategy-researcher.md`

QuantAgents 项目 bootstrap 时发现 4 个 agent 在实际派工中**频繁合并调用**——同一类任务（如写小市值反转因子）需要 4 个 agent 协同，沟通开销大于收益。quant-pm 与 quant-researcher 的边界也模糊（业务 Lead 不懂技术，懂技术的不管业务）。

## 决策

1. 删除 `agents/quant/` 子目录及 4 个子 agent 文件
2. 新增 `agents/quant-researcher.md` 单文件 Agent，**业务 Lead 模式 + 执行模式**双角色合一
3. 双角色边界由 ROUTING.md §3.1 派工矩阵明确：业务 Lead 模式接 PM 派工；执行模式仅 4A 派回时调用
4. 保留 git 历史供追溯

## 备选

- **A. 保留 4 个文件 + 新增 quant-researcher.md 作为 Lead**：增加 5 个文件而非 1 个，违反 YAGNI
- **B. 拆出独立 quant-pm**：业务 Lead 不懂技术，懂技术的不管业务，沟通开销更大
- **C. 维持原 4 个文件不变**：4 个文件协同派工时沟通开销大，不符合实战经验

## 权衡

- 接受：单文件变大（~150 行）；不同业务子领域在同一文件内需要切角色
- 拒绝：4 个文件协同的沟通成本；新增 quant-pm 的角色冲突

## 后果

- `agents/quant-researcher.md` 替换 4 个原 quant/* 文件
- 任何使用本模板的量化项目只需装 1 个 quant agent
- 业务 Lead 与执行者的角色边界由文件内"## 业务侧（Lead）职责 / ## 技术侧（执行）职责"段显式标注
- 量化项目的 4 个子领域（中国市场 / 因子 / 新闻舆情 / 策略）通过 ROUTING.md 的路由矩阵派发
