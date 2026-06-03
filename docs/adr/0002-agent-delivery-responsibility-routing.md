# ADR-0002：采用 Agent 交付职责路由基线（明确 frontend / backend / data / devops / qa 分工）

- **状态（Status）**: Accepted
- **日期（Date）**: 2026-06-03
- **触发背景**: 4A 协同治理在落地到具体交付分派时，需要稳定地区分前端、后端、数据、DevOps 与 QA 的主责边界

## 背景（Context）

当前项目在开发阶段已经引入 `frontend-engineer`、`backend-engineer`、`data-engineer`、`devops-engineer`、`qa-engineer` 等角色，但实际协作仍存在四类反复出现的问题：

1. **Frontend 易被忽略**：页面、交互、前端状态、图表与可用性问题，常被粗暴并入“后端问题”或“数据问题”，导致真正的视图层责任不清。
2. **Backend 吞并过多职责**：数据采集任务、数仓表、DQC 规则、测试验收、发布部署等工作，经常因为入口是某个 API 或调度页面而被默认丢给 `backend-engineer`。
3. **调度场景归属混乱**：团队没有稳定地区分「调度平台本身故障」与「调度器承载的任务逻辑故障」，导致采集脚本和平台框架问题在不同 agent 之间来回转派。
4. **交付链条缺口**：实现完成后，`devops-engineer` 与 `qa-engineer` 没有被稳定纳入发布和验收闭环，容易出现“代码写完就算完成”的口头交付。

## 决策（Decision）

采用 `docs/standards/agent-delivery-responsibility-routing.md` 作为开发阶段多 agent 协作的职责划分权威源，并执行四项治理动作：

1. **明确 frontend / backend / data 分界**：
   - `frontend-engineer` 负责页面、组件、交互、前端状态管理、视图层错误处理与页面可用性。
   - `backend-engineer` 负责平台能力、服务契约、调度框架、权限审计与业务编排。
   - `data-engineer` 负责采集任务、ETL/ELT、数仓建模、DQC、指标 / 因子 / Ins 开发。
2. **固化调度判定铁律**：
   - 调度器平台异常 → `backend-engineer` 主责。
   - 调度器正常、跑在其上的任务异常 → `data-engineer` 主责。
   - 部署、进程守护、监控告警、回滚异常 → `devops-engineer` 主责。
3. **把 `devops-engineer` 与 `qa-engineer` 纳入标准交付流**：
   - `devops-engineer` 负责环境、部署、监控、发布和回滚。
   - `qa-engineer` 负责测试策略、执行证据、缺陷报告和发布建议。
4. **让 4A 治理文档引用职责路由基线**：
   - 在 `docs/standards/architecture-collaboration-workflow.md` 中补充交付协作清单和文档关系；
   - `4a-architect` prompt 只保留硬约束，不再内联详细角色分派说明。

## 备选（Alternatives Considered）

### 备选 A：维持“backend 默认兜底，frontend 不单列”（被否决）

- **做法**：继续把大部分实现、测试、发布问题默认丢给 `backend-engineer`，有争议时再临时讨论。
- **劣势**：
  - 前端问题、数据任务和平台任务长期混淆，问题定位慢。
  - DevOps / QA 难以形成稳定闸口，交付质量依赖个人自觉。
  - 角色边界不可追溯，每次新任务都要重复裁决。

### 备选 B：只在 `4a-architect` prompt 中补充说明（被否决）

- **做法**：直接扩写 prompt，细化任务分派细节，不落标准文档。
- **优势**：改动表面最少。
- **劣势**：
  - 与 ADR-0001 确立的“prompt 指针化、流程文档权威化”方向冲突。
  - 后续 wording 漂移风险高，其他 agent 无法复用同一基线。

### 备选 C：建立独立职责路由标准并被 4A 流程引用（即本决策）

- **优势**：
  - 分工规则可复用、可评审、可在多个 prompt / 文档间共享。
  - 能同时解决调度归属、数据职责与交付闭环问题。
  - 与 ADR-0001 的治理方向一致。
- **代价**：
  - 需要新增一份 standards 文档，并维护其与 4A 流程的关系。

## 权衡（Trade-offs）

- **已接受代价**：
  - 任务分派前需要多做一次运行时归属和单一事实源判断，短期决策成本略升。
  - 某些跨前端、API 与数据处理的场景需要 frontend/backend/data 联合处理，分工说明必须写得更明确。
- **正向收益**：
  - 页面问题不再默认落给后端，前端 owner 能被稳定识别。
  - 调度问题不再一律落到后端，数据任务能更快进入正确责任域。
  - DevOps / QA 从“可选协作方”升级为标准交付流中的显式角色。
  - `4a-architect` 可用统一标准裁决分工争议，而不是重复写 prompt 特例。

## 后果（Consequences）

- **短期**：
  - 新增 `docs/standards/agent-delivery-responsibility-routing.md` 作为职责路由权威源。
  - `docs/standards/architecture-collaboration-workflow.md` 新增 §6.5 交付协作清单，并把职责路由文档纳入文档关系。
  - `README.md` 增加入口提示，提醒使用者在分派任务时优先按职责路由标准判责。
- **长期**：
  - 后续若新增 `dataops`、`ml-engineer` 等开发期角色，必须先更新该标准文档，再扩展 prompt。
  - 任何涉及角色主责调整的治理变更，应先更新 ADR 与 standards，再改 agent 提示词。

## 正文链接（References）

- `docs/standards/agent-delivery-responsibility-routing.md`
- `docs/standards/architecture-collaboration-workflow.md`
- `docs/adr/0001-4a-collaboration-baseline.md`
