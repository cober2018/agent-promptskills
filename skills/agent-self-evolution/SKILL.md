---
name: agent-self-evolution
description: 用于以下场景：量化智能体自进化与反思机制——涉及回测错误定位、审计失败捕获、规避指令生成、Prompt/上下文自适应优化。
---

# 智能体自进化与反思机制

## 概述

智能体在量化开发中面临复杂的代码与统计约束。当系统发生回测指标不达标（如 Rank IC 偏低、最大回撤超标）或发生逻辑错误（如未来函数泄露、数据格式不匹配）时，必须通过 **自进化反思回路** 自动记录错误并生成自适应防御机制，确保后续运行不再重复犯错。

## 何时使用

*   回测或因子评估未达到四件套的验收标准（例如：Rank IC 目标为 0.05，实际回测为 0.02）。
*   QA 审计或 Live 运行中被 Mandate Gate 驳回（例如：发现未来函数、幸存者偏差）。
*   发生代码执行报错或 API 限频被封。

**不要用于：**
*   策略的正常调参过程（如单纯调整 MA 的 window，应由策略自身参数优化算法处理）。
*   非量化业务的通用工程 bug（由 backend-engineer 通过 systematic-debugging 处理）。

## 反思记忆的持久化规范

当任务被退回或验证失败时，执行 Agent 必须提取“反思记忆（Reflective Memories）”并写入专用存储文件中，避免修改核心提示词文件。

### 1. 记忆文件路径
*   `docs/memories/quant/<agent-name>-reflection.md`

### 2. 记忆文件结构
每个反思记忆必须包含以下字段：
*   `fail_timestamp`: 失败时间
*   `fail_scenario`: 失败场景描述
*   `root_cause`: 根本原因（如：在时序 rolling mean 中漏掉了 `.shift(1)` 导致未来函数泄露）
*   `evading_instruction`: **规避指令**（具体的防范规则，以命令式语气写给未来的自己）

## 规避指令编写标准

规避指令必须明确、具体，且可被未来的 LLM 直接理解执行：

| 错误类型 | ❌ 模糊的指令 | ✅ 具体的规避指令 |
|:---|:---|:---|
| 未来函数 | 以后注意未来函数。 | 必须对所有滚动滑动平均自变量（如 `close.rolling().mean()`）整体进行 `.shift(1)` 延后。 |
| 公告日延迟 | 财务数据要注意时间。 | 必须从 ClickHouse 读取 `ann_date`（公告日期）作为时序索引，不可直接以 `report_date`（报告期终日）对齐。 |
| API 超时 | 接口慢要小心。 | 调用 Tushare 接口时必须配置 `retry_count=3` 且每次报错后进行 `time.sleep(2)` 指数退避。 |

## 运行时加载自进化指令

在 Agent 启动时，系统会将对应的 `docs/memories/quant/<agent-name>-reflection.md` 中的 `evading_instruction` 作为 `past_memory_str` 或 `system_override_rules` 动态挂载到提示词的 Context 头部，实现运行时强制防御。

## 常见错误

| 错误做法 | 正确做法 |
|:---|:---|
| 每次失败都直接编辑 Agent prompt 的 md 文件 | 将反思持久化在 `docs/memories/` 中，以动态上下文注入 |
| 规避指令写成感性总结（如“我要努力写好代码”） | 规避指令写成具体、可测量的代码与逻辑硬约束 |
| 在反思中编造或美化错误原因 | 诚实直白记录失败指标与 traceback 日志 |

## 产出物清单

- [ ] 反思文件：`docs/memories/quant/<agent-name>-reflection.md`
- [ ] 动态运行时 Prompt 注入段（在 system prompt 的反思加载段呈现）
- [ ] 验证报告：修复后的代码是否通过了之前的失败用例
