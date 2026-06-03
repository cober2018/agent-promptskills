# ADR-0001：4A 协同治理基线（采用 `docs/standards/architecture-collaboration-workflow.md` 作为权威源）

- **状态（Status）**: Accepted
- **日期（Date）**: 2026-06-03
- **触发 Issue**: [WS-5](https://multica.ai/issues/cacf1e98-d206-4e2c-a039-e524d5b57c5c)（4a-architect 提示词对齐 4A 协同工作流）

## 背景（Context）

平台长期依赖 `4a-architect` agent 提示词内联的 4A（Business / Application / Data / Technology）流程、清单与 ADR 模板，存在三类问题：

1. **漂移严重**——跨 prompt 的措辞、清单条目、ADR 字段不一致，跨 agent 协同时出现「同一件事两种说法」。
2. **无法演进**——任何条款调整都要修改 agent 提示词，再下发到所有运行实例，迭代成本高、版本不可追溯。
3. **新架构 agent 接入无基线**——后续若引入领域架构师、平台架构师等角色，没有可复用的统一基线。

WS-3（采集任务暂停事件）的复盘中已经暴露出「4A 协同规则散落在多份 standards 文档与 agent prompt 中、归属不清」的具体痛点。

## 决策（Decision）

采用 `docs/standards/architecture-collaboration-workflow.md` 作为 4A 协同的**唯一权威源**，并配套三项治理动作：

1. **新增**权威源文档 `docs/standards/architecture-collaboration-workflow.md`，承载 4A 分层定义、能力域判定规则、5 条硬约束、ADR 模板、§6 架构评审清单（含调度 / 存储 / 跨域三场景）、文档关系与演进规则。
2. **改造** `4a-architect` agent 提示词：仅保留 5 条必须自检的硬约束作为指针，不再内联 4A 流程、清单与 ADR 模板；提示词与权威源冲突时以权威源为准。
3. **建立**边界变更触发 ADR 的强制流程：跨服务、跨存储、跨调度、跨能力域任一边界变更，必须先写或更新 `docs/adr/NNNN-*.md` 与对应 standards 文档，再提交代码。

## 备选（Alternatives Considered）

### 备选 A：增量基线（即本决策）

- **做法**：先建权威源文档，再把 agent prompt 改为指针；ADR 流程逐步强约束。
- **优势**：
  - 落地快，1 个 PR 即可生效，不打断当前在跑的 WS-3 / WS-4 修复工作。
  - 漂移收敛立即可见，新接入的架构 agent 直接引用权威源。
  - ADR 与 standards 文档同时入库，证据链完整。
- **代价**：
  - 旧 prompt 中部分重复段落需要清理，存在一次性的「指针化」改动。
  - 后续若有 agent 漏改，需要靠运行时自检与人工 review 把关。

### 备选 B：Big Bang 重写（被否决）

- **做法**：一次性重写所有 4A 相关 standards 文档 + 所有架构类 agent prompt + 所有 ADR 模板。
- **优势**：
  - 终态干净，一次到位。
- **劣势**：
  - 经验上 70% 失败，剩余 30% 延期 1 年以上（与 `4a-architect` 既有「演进优于一步到位」原则相悖）。
  - 当前 WS-3 / WS-4 修复与未来 WS-5+ 任务并行推进，重写会阻塞 in-flight 工作的合并。
  - 一次性变更太大，code review 成本高、出错面广。

### 备选 C：维持现状（被否决）

- **做法**：不引入权威源，继续以 agent prompt 内联 4A 流程。
- **劣势**：漂移、演进成本、接入成本三类问题均不解决；WS-3 暴露的归属不清问题会持续复发。

## 权衡（Trade-offs）

- **已接受代价**：
  - 短期内所有架构类输出都要多走一次「指针引用 → 权威源」的心智回路，agent 自检开销略增。
  - 权威源文档与 agent prompt 之间的版本对齐需要靠 CI 或人工巡检兜底。
- **正向收益**：
  - 跨架构类 agent 协同（4a-architect ↔ 未来领域架构师 ↔ backend-engineer）有统一口径。
  - 边界变更证据链（ADR + standards + 代码）首次可在一次 PR 内同时落地。
  - 新架构 agent 接入成本从「写一份新 prompt」下降到「引用权威源 + 加自己的硬约束」。

## 后果（Consequences）

- **短期**：
  - `4a-architect` agent 提示词已对齐到本 ADR 配套的工作流文档（见 WS-5 评论）。
  - 本 ADR 与 `docs/standards/architecture-collaboration-workflow.md` 必须**同时**合并，缺一不可。
- **长期**：
  - 6 个月后（不晚于 2026-12-03）做一次架构委员会复盘：检查权威源是否被有效引用、是否需要追加新约束、是否有条款过期。
  - 任何对 `architecture-collaboration-workflow.md` 的修改必须先提新 ADR（流程治理类）。
  - 新增架构类 agent 必须先接入本权威源，再写 agent prompt。
- **联动文档**：
  - `docs/standards/AGENT_SCHEDULER_GUIDE.md` —— 调度器事实源，本 ADR §6.2 引用其结论。
  - `docs/standards/数据仓库架构文档.md` —— 数仓事实源，本 ADR §6.3 引用其结论。
  - `openspec/changes/**` —— 业务级变更提案，跨边界变更需同时走 ADR。

## 正文链接（References）

- WS-5 Issue: `cacf1e98-d206-4e2c-a039-e524d5b57c5c`（4a-architect 提示词对齐）
- 配套权威源: `docs/standards/architecture-collaboration-workflow.md`
- WS-3 复盘: `d1111420-af49-41bc-8a6d-65978ba01183`（4A 漂移问题的具体复盘）
