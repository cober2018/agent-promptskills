# ADR-0003: 量化团队架构——保留 4 个研究领域 Agent + 引入 quant-lead 工程化入口

- **状态**：Accepted
- **日期**：2026-06-05（修订）
- **决策者**：业务 PMO
- **修订原因**：原方案"4 合 1"经验证后发现原 4 个 Agent 含 1424 行 A 股研究领域知识（技术策略 / 基本面 / 舆情 / 决策），新文件（QuantAgents 的 `quant-lead.md`）定位为"业务 Lead + 因子工程执行者"，两者角色完全不同。

## 背景

本模板在 `agents/quant/` 目录下提供 4 个量化研究 Agent：
- `quant-china-market-analyst.md`（191 行）—— A 股技术面深度分析（11 类技术策略 + A 股特色四维度）
- `quant-factor-researcher.md`（383 行）—— 因子研究层（4 类基本面策略 + 多空 5+5 维辩论 + 防偏误 4 件套）
- `quant-news-social-analyst.md`（386 行）—— 新闻舆情综合（5 类事件影响 + 情绪指数 1-10 + 题材阶段判断）
- `quant-strategy-researcher.md`（464 行）—— 决策层 Lead（多空合成 + 5 项交易计划 + 目标价三档 + 6 大类资产配置）

QuantAgents 项目（基于本模板）在实践中新增了 `quant-lead.md`——定位为"业务 Lead + 因子工程执行者"（写需求文档 / 派 4A 评审 / IC-Rank-IC / 回测），与原 4 个 Agent 的"研究流水线 4 角色"完全不同。

## 决策

1. **保留** `agents/quant/` 下 4 个原 Agent（含 1424 行 A 股研究领域知识）
2. **引入** `agents/quant-lead.md` 作为量化团队的**工程化入口**（业务 Lead + 因子执行者），与 4 个研究领域 Agent 并行
3. 职责边界：
   - `quant-lead.md`：需求入口 → 写四件套 → 派 4A → 因子工程执行 → 回测验收
   - `quant-china-market-analyst.md`：A 股技术面分析（由 PM 或 quant-lead 按需派工）
   - `quant-factor-researcher.md`：因子研究（由 quant-lead 或 4A 按需派工）
   - `quant-news-social-analyst.md`：新闻舆情分析（由 quant-lead 或 4A 按需派工）
   - `quant-strategy-researcher.md`：策略决策（由 quant-lead 或 PM 按需派工）
4. ROUTING.md 已同步更新：所有 `quant-researcher` 引用改为 `quant-lead`

## 备选

- **A. 保留 4 个 + 引入 quant-lead（已采纳）**：领域知识 + 工程入口并存，代价是多一个文件
- **B. 4 合 1 删除原文件（原方案，已否决）**：损失 1424 行 A 股研究知识，quant-lead 无法覆盖技术分析 / 舆情 / 决策能力
- **C. 仅保留 4 个不引入 quant-lead**：缺乏工程化入口，量化团队没有 Lead 接 PM 派工

## 权衡

- 接受：5 个文件而非 1 个；quant-lead 与 4 个研究领域 Agent 职责需在 ROUTING.md 显式标注
- 拒绝：损失研究领域知识（方案 B）；缺乏工程化 Lead 入口（方案 C）

## 后果

- `agents/quant/` 下 4 个原 Agent 文件保留不变
- `agents/quant-lead.md` 作为工程化入口与 4 个研究领域 Agent 并行
- ROUTING.md 派工矩阵已更新：PM 派 quant-lead（业务 Lead 模式）；4A 可派回 quant-lead（执行模式）或按需派 4 个研究领域 Agent
- 使用本模板的量化项目可按需选择：仅装 quant-lead（工程入口）或同时装 4+1（完整研究流水线）
