# Agent × Skill 路由矩阵与派工链路

> **权威源（Authoritative Source）**
> 本文件是 `agents/` 目录下 Agent 与 Skill 路由的**唯一权威源**。
> Agent 提示词（`agents/*.md`）只承载自检硬约束与角色定义，**不再内联**路由细节。
> 提示词与本文冲突时，**以本文为准**。

## 1. 组织架构

```
                          ┌──────────────────────┐
                          │      User（你）        │
                          └──────────┬───────────┘
                                     ▼
                          ┌──────────────────────┐
                          │  PM 业务 PM（入口）    │  /pm
                          │  L1 派工（派 Lead）    │
                          │  L2 派工（派 IC，核心）│
                          └──────────┬───────────┘
                                     ▼
                  ┌──────────────────┴──────────────────┐
                  ▼                                     ▼
      ┌──────────────────────────┐    ┌──────────────────────────┐
      │ quant-lead         │    │ 4a-architect 4A 架构师   │
      │ (L1: 业务 Lead 模式)     │    │  (L1: 技术团队 Lead)     │
      │  - 量化需求立项           │    │  - 写方案 + assignments  │
      │  - 撰写四件套             │    │  - ADR + 评审            │
      │  - 派 4A 评审             │    │  - 不直接派 IC           │
      │  (L2: 执行模式)           │    │                          │
      │  - 因子 / 回测代码执行    │    │                          │
      └──────────┬───────────────┘    └─────────────┬────────────┘
                 │                                  │
                 └────────────────┬─────────────────┘
                                  ▼
      ┌──────────┬──────────┬──────────┬──────────┬──────────┐
      ▼          ▼          ▼          ▼          ▼          ▼
  backend    frontend    data-eng   quant-rs   qa-eng    (devops /
  -engineer  -engineer   -engineer  (L2 IC)    -engineer new-media / video
  (L2 IC)    (L2 IC)     (L2 IC)              (L2 IC)  未装)
       ↑ PM 按 Lead 方案 assignments 数组 1 对 1 写 L2 dispatch md 派发
```

## 2. 派工硬约束（**2026-06-07 修订：L1/L2 级联派工**）

> **核心**：派工 = L1（PM 派 Lead 写方案）→ L2（PM 派 IC 执行，**必填** `solution_ref`）。
> 详见 [`docs/dispatch/PROTOCOL.md`](../docs/dispatch/PROTOCOL.md)。

### 派工级联（**PM 派 IC 是核心**）

| 派工层级 | 派工方 | 接收方 | 必填字段 |
|---|---|---|---|
| **L1**（方案层）| PM | Lead（4a-architect / quant-lead / `<domain>`）| `owner=Lead` + `layer=L1` + `solution_ref=null` |
| **L2**（执行层）| PM | IC（backend-engineer / frontend-engineer / data-engineer / qa-engineer / `<IC>`）| `owner=IC` + `layer=L2` + `solution_ref=<path>`（**必填**）|

### 派工硬约束

- ✅ **PM 派 L1**：粗探查后写 L1 dispatch md（`layer=L1`），派 Lead 做方案
- ✅ **PM 派 L2**：Lead 写完方案（`docs/solutions/<id>.md`）→ PM 校验 → 写 L2 dispatch md（`layer=L2`），**必填** `solution_ref`
- ✅ **L1 → L2 必经** `solution_ready` + `ready_to_dispatch` 两个状态
- ❌ **不**让 Lead 私派 IC（派工必须经 PM 派 L2，可追溯）
- ❌ **不**跳过方案校验直接派 L2
- ❌ **不**用 `TaskUpdate(owner=...)` 当派工通知（必须用 dispatch md）
- ❌ **不**改 `done` 跳过真实 e2e 三件套（`[lead] 评审通过` + `[pm] 真实 e2e 通过`）

### Lead 4 件套（替代旧"自派 IC"）

| # | 动作 | 产出 |
|---|---|---|
| 1 | 接单调研 | 摸清现状 / 风险 / 依赖 |
| 2 | 写方案 | `docs/solutions/<id>.md`（含 `assignments` 数组）|
| 3 | 评审 IC | 评审 commit 是否符合方案 |
| 4 | 兜底 | IC 失败/越界时接管 |

**Lead 永远不直接派 IC**——只写方案 + 评审 + 兜底。L2 派工由 PM 按 `assignments` 写 dispatch md 派给 IC。

## 3. 触发 ADR 的边界变更（4A 评审门禁）

满足任一条件即触发 ADR（`docs/adr/NNNN-<slug>.md`）：

| 类别 | 例子 |
|---|---|
| 服务边界 | 新增 / 删除 / 拆分 / 合并服务 |
| 存储边界 | 新增 / 替换 / 退役数据库、消息队列、缓存、对象存储 |
| 调度边界 | 新增 / 替换调度器、调度策略、JobStore |
| 跨能力域 | 业务→技术、数据→应用 等跨域数据流 |
| API 契约 | 跨团队的 API 契约变更 |
| 安全合规 | 新认证 / 授权 / 审计路径 |
| SLI/SLO | 调整可用性目标 |

**4A 评审清单**（`docs/standards/architecture-collaboration-workflow.md` §6）必跑。

## 4. Agent × Skill 路由矩阵

| Agent | 调用的 Skill（主用） | 调用权限 |
|---|---|---|
| **业务 PM** | `brainstorming`、`writing-plans`、`swarm-dag-orchestration`、`business-architecture`(只读)、`application-architecture`(只读)、`receiving-code-review` | 写需求文档；派工；Swarm DAG 编排 |
| **量化研究员（业务 Lead 模式）** | `brainstorming`、`writing-plans`、`swarm-dag-orchestration`(只读)、`business-architecture`(只读)、`data-architecture`(只读)、`factor-engineering`(只读)、`backtest-validation`(只读)、`receiving-code-review` | 写量化需求四件套；派 4A 评审；不写代码 |
| **量化研究员（执行模式）** | `factor-engineering`、`factor-mining`、`backtest-validation`、`quant-alpha-zoo`、`earnings-revision`、`candlestick-pattern`、`options-strategy`、`onchain-analysis`、`agent-self-evolution`、`test-driven-development`、`systematic-debugging` | 写因子 / 回测代码；偏误防御；IC 评估；自进化反思（仅 4A 派回时） |
| **4A 架构师** | `business-architecture`、`application-architecture`、`data-architecture`、`technology-architecture`、`writing-plans`、`verification-before-completion` | 评审 + 派工 + 写 ADR；不写业务代码（cc 默认 / codex 通过 /pm-engine 切换）|
| **后端专家** | `api-engineering`、`database-engineering`、`system-reliability`、`test-driven-development`、`systematic-debugging` | 写后端代码；单测；自审 |
| **前端专家** | `react-frontend-architecture`、`test-driven-development`、`systematic-debugging` | 写前端代码；单测；自审（cc 默认 / gemini / agy 通过 /pm-engine 切换）|
| **数据工程师** | `data-architecture`、`pipeline-engineering`、`data-quality`、`lakehouse-platform`、`systematic-debugging` | 写数据代码 / 管线；DQC 门禁 |
| **QA 专家** | `test-evidence`、`quality-gate`、`test-driven-development`、`systematic-debugging` | E2E / 压测 / 质量门禁；Bug 证据链审计 |

**全局与量化过程规范**（按需调用）：

| Skill | 适用阶段 / 核心能力 |
|---|---|
| `using-superpowers` | 启动任何任务时 |
| `brainstorming` | 需求对齐、方案讨论前 |
| `writing-plans` | 编码前的微任务计划 |
| `executing-plans` | 编码与计划落地 |
| `test-driven-development` | 所有业务代码编写 |
| `systematic-debugging` | Bug 修复 / 异常排查 |
| `verification-before-completion` | 任务交付前 |
| `subagent-driven-development` | 复杂大任务拆分 |
| `dispatching-parallel-agents` | 并发任务处理 |
| `requesting-code-review` | 提 PR 前自检 |
| `receiving-code-review` | 接 Review 意见时 |
| `using-git-worktrees` | 多任务并行 / 分支隔离 |
| `finishing-a-development-branch` | 分支合并 / 临时分支清理 |
| `writing-skills` | 自定义 Skill 扩充 |
| `skill-health` | Skill 健康度检查 |
| `pruning-skills` | 清理过期 Skill |
| `swarm-dag-orchestration` | 量化智能体 Swarm 团队配置与 DAG 工作流编排 |
| `agent-self-evolution` | 智能体回测/评估失败后的反思与规避指令自适应优化 |
| `quant-alpha-zoo` | WorldQuant 101/191 等因子库数学公式及 Pandas 向量化标准 |
| `candlestick-pattern` | K 线实体影线数学特征及 20 种经典形态量化识别 |
| `earnings-revision` | 卖方分析师一致预期修正比例与财报超预期幅度 (SUE) 分析 |
| `options-strategy` | BS 期权定价模型、希腊字母 (Greeks) 风险对冲组合设计 |
| `onchain-analysis` | 交易所流入流出 (NEF)、巨鲸筹码与 TVL 链上数据监测 |

## 5. 量化业务需求四件套

quant-lead（业务 Lead 模式）派单时，需求文档必含：

| 四件套 | 内容 |
|---|---|
| **数据契约** | 行情频率 / 复权方式 / 起止时间 / 品种池 / 缺失值处理 / SLA |
| **因子假设** | 因子定义 / 经济学直觉 / 计算口径 / 预期 IC 方向 |
| **回测方案** | 调仓频率 / 持仓周期 / 交易摩擦 / 样本内外划分 / 偏误防御 |
| **验收标准** | IC ≥ ? / Rank-IC ≥ ? / 年化 ≥ ? / 最大回撤 ≤ ? / 换手率 ≤ ? |

**偏误防御**（必显式声明）：

| 偏误 | 防御手段 |
|---|---|
| 未来函数（Lookahead Bias） | 时序平移 `.shift(1)` |
| 幸存者偏差（Survivorship Bias） | 股票池动态加载，含已退市 |
| 公告日延迟（Announcement Delay） | 对接实际公告发布日而非结算日 |
| 复权口径 | 显式声明前/后复权、切换点 |
| 交易摩擦 | 印花税 / 佣金 / 滑点（默认 A 股标准） |

## 6. 派工示例

### 例 1：业务需求 → 业务 PM → 4A（L1）→ PM（L2）→ 后端

```
用户：「我要加个新接口，POST /v1/orders，下单」
↓
业务 PM（L1 派工）：
  - 类型：技术/编码
  - 写 L1 dispatch md: layer=L1, owner=4a-architect
↓
4A（L1 接单调研）：
  - §3 自检（API 涉及服务边界 → 触发 ADR）
  - 写 ADR docs/adr/NNNN-rest-orders-api.md
  - 写方案 docs/solutions/<id>.md（assignments=[{ic: backend-engineer, task: ...}]）
  - L1 status → solution_ready
↓
业务 PM（校验方案 + L2 派工）：
  - 校验方案 → 改 L1 status=ready_to_dispatch
  - 写 L2 dispatch md: layer=L2, owner=backend-engineer, solution_ref=<path>
↓
后端（L2 接单执行）：
  - 校验 solution_ref 非空 + 必读方案
  - 用 api-engineering / database-engineering
  - TDD：先写测试
  - 完成后改 status=review + 填 artifact
↓
4A 评审 → 业务 PM 跑真实 e2e → 改 done
```

### 例 2：量化业务 → 业务 PM → quant-lead（业务 Lead）→ 4A → quant-lead（执行模式）

```
用户：「我要个小市值反转因子」
↓
业务 PM：
  - 类型：量化业务
  - 派给 quant-lead（业务 Lead 模式）
↓
quant-lead（业务 Lead）：
  - brainstorming 1 关键问题（持仓周期 / 品种池 / 是否含 ST）
  - 撰写四件套（数据契约 / 因子假设 / 回测方案 / 验收标准）
  - 派给 4a-architect 评审
↓
4A：
  - §3 自检（数据 → 应用跨域 → 触发 ADR）
  - 评审四件套
  - 派回 quant-lead（执行模式，写因子 / 回测代码）
↓
quant-lead（执行模式）：
  - 用 factor-engineering / backtest-validation
  - 偏误防御先行
  - 完成后 IC 评估 + 报告
↓
quant-lead（业务 Lead 验收）：
  - 看 IC、Sharpe、回撤
  - 达标 → 归档
```

### 例 3：E2E/压测需求 → 业务 PM → 4A（L1）→ PM（L2×2）→ 后端 + qa

```
用户：「加个新接口 POST /v1/orders，要 E2E + 压测」
↓
业务 PM（L1 派工）：
  - 类型：技术/编码 + 质量验证
  - 写 L1 dispatch md: layer=L1, owner=4a-architect
↓
4A（L1 写方案）：
  - §3 自检（API 涉及服务边界 → 触发 ADR）
  - 写方案 docs/solutions/<id>.md
  - assignments=[{ic: backend-engineer, task: 接口实现}, {ic: qa-engineer, task: E2E + 压测}]
↓
业务 PM（派 L2 × 2）：
  - 校验方案 → L1 status=ready_to_dispatch
  - 写 L2 dispatch md × 2（分别派 backend-engineer + qa-engineer）
↓
backend-engineer（L2）：
  - 用 api-engineering 实现 → TDD → 改 status=review
↓
qa-engineer（L2）：
  - 用 test-evidence / quality-gate
  - Playwright E2E 覆盖主流程
  - Locust 压测，p99 < 200ms
  - 出 Bug 证据链 / 质量评级（A/B/C/D）
↓
4A 评审 → 业务 PM 跑真实 e2e → 改 done
```

## 7. 维护规则

- 本文件变更必须先提 ADR（流程治理类）。
- 新增 Agent / Skill 必须先更新本表，再写 Agent 提示词。
- 不挂到具体 Agent 的全局过程规范 skill，可独立增减。
- 每 6 个月做一次 skill-health 巡检。

---

> 维护者：业务 PM
> 状态：Active（生效日见 ADR-0002-agent-org-bootstrap + ADR-0003 命名修正）
