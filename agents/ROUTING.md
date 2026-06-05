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
                          └──────────┬───────────┘
                                     ▼
                  ┌──────────────────┴──────────────────┐
                  ▼                                     ▼
      ┌──────────────────────────┐    ┌──────────────────────────┐
      │ quant-lead         │    │ 4a-architect 4A 架构师   │
      │ (量化业务侧 Lead /       │    │  - §3 五条硬约束自检     │
      │  量化技术执行者)         │    │  - ADR + 派工            │
      │  - 量化需求立项           │    │  - 单一事实源声明         │
      │  - 撰写四件套             │    │                          │
      │  - 派 4A 评审             │    │                          │
      │  - 4A 派回时执行因子代码  │    │                          │
      └──────────┬───────────────┘    └─────────────┬────────────┘
                 │                                  │
                 └────────────────┬─────────────────┘
                                  ▼
      ┌──────────┬──────────┬──────────┬──────────┬──────────┐
      ▼          ▼          ▼          ▼          ▼          ▼
  backend    frontend    data-eng   quant-rs   qa-eng    (devops /
  -engineer  -engineer   -engineer  (executor) -engineer new-media / video
                                          ↑                          未装)
                                  4A 派回时执行
```

## 2. 派工硬约束

> **任何派工动作必须先经过对应领域的 Lead / 架构师评审。**
> 业务 PM **不直接**派 `backend-engineer` / `frontend-engineer` / `data-engineer` / `quant-lead`（执行模式）。
> quant-lead（业务 Lead 模式）**不直接**派 `data-engineer`；必须经 `4a-architect` 评审。
> 唯一例外：4A 架构师在评审后可直接派工给具体专家。

| 上游 | 可直接派给 | 不可直接派给 |
|---|---|---|
| 业务 PM | `quant-lead`（业务 Lead 模式）、`4a-architect` | 所有专家（backend/frontend/data-engineer/qa-engineer/quant-lead 执行模式） |
| quant-lead（业务 Lead 模式） | `4a-architect` | `data-engineer` |
| 4a-architect | 任意专家（含 backend/frontend/data-engineer/qa-engineer/quant-lead 执行模式） | — |

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
| **业务 PM** | `brainstorming`、`writing-plans`、`business-architecture`(只读)、`application-architecture`(只读)、`receiving-code-review` | 写需求文档；派工；不写代码 |
| **量化研究员（业务 Lead 模式）** | `brainstorming`、`writing-plans`、`business-architecture`(只读)、`data-architecture`(只读)、`factor-engineering`(只读)、`backtest-validation`(只读)、`receiving-code-review` | 写量化需求四件套；派 4A 评审；不写代码 |
| **量化研究员（执行模式）** | `factor-engineering`、`factor-mining`、`backtest-validation`、`test-driven-development`、`systematic-debugging` | 写因子 / 回测代码；偏误防御；IC 评估（仅 4A 派回时） |
| **4A 架构师** | `business-architecture`、`application-architecture`、`data-architecture`、`technology-architecture`、`writing-plans`、`verification-before-completion` | 评审 + 派工 + 写 ADR；不写业务代码（cc 默认 / codex 通过 /pm-engine 切换）|
| **后端专家** | `api-engineering`、`database-engineering`、`system-reliability`、`test-driven-development`、`systematic-debugging` | 写后端代码；单测；自审 |
| **前端专家** | `react-frontend-architecture`、`test-driven-development`、`systematic-debugging` | 写前端代码；单测；自审（cc 默认 / gemini / agy 通过 /pm-engine 切换）|
| **数据工程师** | `data-architecture`、`pipeline-engineering`、`data-quality`、`lakehouse-platform`、`systematic-debugging` | 写数据代码 / 管线；DQC 门禁 |
| **QA 专家** | `test-evidence`、`quality-gate`、`test-driven-development`、`systematic-debugging` | E2E / 压测 / 质量门禁；Bug 证据链审计 |

**全局过程规范**（不挂到具体 Agent，按需调用）：

| Skill | 适用阶段 |
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

### 例 1：业务需求 → 业务 PM → 4A → 后端

```
用户：「我要加个新接口，POST /v1/orders，下单」
↓
业务 PM：
  - 类型：技术/编码
  - 派给 4a-architect 评审
↓
4A：
  - §3 自检（API 涉及服务边界 → 触发 ADR）
  - 写 ADR docs/adr/NNNN-rest-orders-api.md
  - 派给 backend-engineer
↓
后端：
  - 用 api-engineering / database-engineering
  - TDD：先写测试
  - 完成后自审 + requesting-code-review
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

### 例 3：E2E/压测需求 → 业务 PM → 4A → qa-engineer

```
用户：「加个新接口 POST /v1/orders，要 E2E + 压测」
↓
业务 PM：
  - 类型：技术/编码 + 质量验证
  - 派给 4a-architect 评审
↓
4A：
  - §3 自检（API 涉及服务边界 → 触发 ADR）
  - 评审接口设计
  - 派给 backend-engineer 实现 + 派给 qa-engineer 设计 E2E / 压测
↓
backend-engineer：
  - 用 api-engineering 实现
  - TDD：先写测试
  - 完成后自审
↓
qa-engineer：
  - 用 test-evidence / quality-gate
  - Playwright E2E 覆盖主流程
  - Locust 压测，p99 < 200ms
  - 出 Bug 证据链 / 质量评级（A/B/C/D）
↓
4A 验收：
  - 收集后端 + QA 报告
  - ADR 关闭 / 进入下个 sprint
```

## 7. 维护规则

- 本文件变更必须先提 ADR（流程治理类）。
- 新增 Agent / Skill 必须先更新本表，再写 Agent 提示词。
- 不挂到具体 Agent 的全局过程规范 skill，可独立增减。
- 每 6 个月做一次 skill-health 巡检。

---

> 维护者：业务 PM
> 状态：Active（生效日见 ADR-0002-agent-org-bootstrap + ADR-0003 命名修正）
