# Skill 生命周期管理（Skill Lifecycle）

> 本文件是 Helper agent 的 **Skill 配置文档**。
> 把 Superpowers 中「写 Skills / 升级 Skills / 评估 Skills / 弃用 Skills」相关技能**单独拎出来**集中维护，作为本仓库（`agent-promptskills`）内部 Skill 治理的统一入口。
> 与各 Skill 自身内容（位于 `skills/<name>/SKILL.md`）的权威源关系：**Skill 自身文件 = 完整工作流**；**本文件 = 入口、决策树、引用清单**。

## 1. 适用对象

- 在本仓库新增 Skill
- 编辑 / 升级现有 Skill
- 评估 Skill 健壮性（健康度、是否过期、是否被绕过）
- 弃用 / 归档 Skill

## 2. 核心心智模型

> **写 Skill = 给流程文档做 TDD。**
> Test case = 在子 agent 上跑的压力场景；
> Production code = Skill 文档（`SKILL.md`）；
> RED = 没有 Skill 时 agent 的 baseline 行为；
> GREEN = 加上 Skill 后 agent 遵从；
> REFACTOR = 关闭新出现的"合理化"漏洞。

`Iron Law：未跑过失败测试的 Skill，禁止合入。` —— 适用于 NEW Skill 和 EDIT Skill 两种场景，没有例外。

## 3. Skill 治理决策树

```
需求出现
  │
  ▼
需要"写"一个新 Skill？
  │
  ├── 是 ──▶ superpowers:writing-skills（RED → GREEN → REFACTOR 全流程）
  │           │
  │           ▼
  │           是否要改 / 升级现有 Skill？ ──▶ 同样走 superpowers:writing-skills
  │
  ├── 否 ── 需要"评估"一个现有 Skill 是否健壮？ ──▶ skill-health
  │
  ├── 否 ── 需要把已有的工作流 / 文档"固化为"一个 Skill？ ──▶ skillify
  │
  ├── 否 ── 需要批量盘点哪些 Skill 已无人引用？ ──▶ prune
  │
  └── 否 ── 需要"冻结"一组 Skill 不再随版本变更（用于基线 / 复盘）？ ──▶ freeze / unfreeze
```

任何 Skill 相关的实质改动，**先**回到这张决策树选定入口，**再**按对应 Skill 的 RED-GREEN-REFACTOR 推进。

## 4. Superpowers 相关 Skill 引用清单

| Skill | 一句话定位 | 何时用 |
|---|---|---|
| `superpowers:writing-skills` | 写 / 改 / 升级 Skill 的全流程权威 | 新建 Skill、编辑现有 Skill、Skill 部署前验证 |
| `superpowers:using-superpowers` | 顶层调度：决定何时调用哪个 Skill | 每个会话开始时定位可用 Skill 集合 |
| `superpowers:test-driven-development` | 写 Skill 之前必须先理解的底层 TDD 原理 | 与 writing-skills 配套，违反"先测试后写"是高频漏洞 |
| `skillify` | 把已有的工作流 / 文档固化为 Skill | 散落在多处的 SOP 出现 ≥ 3 次复用时 |
| `skill-health` | 评估单个 Skill 的健康度 | Skill 上线后定期巡检；用户反馈"Skill 没起作用"时 |
| `prune` | 批量盘点并下线长期无引用的 Skill | 季度 / 半年度 Skill 盘点 |
| `freeze` / `unfreeze` | 把一组 Skill 冻结到某版本基线 | 重大基线切换（如 4A 治理基线）、复盘窗口 |
| `instinct-export` / `instinct-import` / `instinct-status` | 与 Skill 配套的"本能"导出导入 | 跨工作区迁移 Skill 时的辅助 |

> 详细工作流（RED / GREEN / REFACTOR 各阶段、checklist、anti-pattern、audience-based language、CSO）见 `skills/writing-skills/SKILL.md`，本文件不复制全文。

## 5. 落仓流程（Helper 视角）

1. **决策树定位入口** —— 按 §3 选定对应 Superpowers Skill。
2. **拉取 Skill 自身** —— 用 `Skill` 工具调用对应 Skill，按其 RED 阶段跑 baseline。
3. **RED → 写 / 改 Skill** —— 在 `skills/<name>/SKILL.md` 落地（或在现有文件上 edit）。
4. **GREEN → 验证** —— 同 baseline 场景下，agent 必须遵从；不遵从则 REFACTOR 关闭漏洞。
5. **REFACTOR 闭环** —— 直到无新"合理化"出现，部署 checklist 全部打勾。
6. **入库** —— 在本仓库的对应 Skill 目录提交，**先** push 到本仓库 `main` 分支，**再**评估是否回灌到 Multica 平台对应 agent 的 `skills` 列表（`multica agent skills add <agent-id> --skill-id <uuid>`）。
7. **登记到本文件 §4** —— 新增 Skill 类型时，更新 §4 引用清单。

## 6. 与 4A 协同工作流的关系

Skill 治理本身属于 **Technology 层**（运行时 / 工具链），但 Skill 改动的边界变更（如新增 Skill 类型、冻结一组 Skill 替换工作流）触发 `docs/standards/architecture-collaboration-workflow.md` §5 的 ADR 强制流程。具体阈值：

- 新增 Skill 类型（影响 ≥ 2 个 agent 的协同方式）── 走 ADR。
- 编辑 Skill 表述（错别字、refactor、CSO 优化）── 不走 ADR，但要走 RED → GREEN 验证。
- 冻结 / 解冻 Skill 集合（基线切换）── 走 ADR + 通知所有相关 agent。
- 弃用 Skill ── 不需要 ADR，但要在 §4 清单中标注 Deprecated 并指向继任者。

## 7. 禁止的"合理化"（写 / 升级 Skill 时高频漏洞）

| 借口 | 现实 |
|---|---|
| "Skill 写得够清楚了，不用测" | 清楚 ≠ 可执行。基线一跑就发现漏 30% 边界。 |
| "Skill 太简单，测是过度" | 简单 Skill 被高频引用，回归一次成本极高。 |
| "我手动测过了" | 手动跑 ≠ 多 agent 在压力下遵从。Skill 的读者是其他 agent。 |
| "等出问题再补" | 部署后再补 = 拖 3 倍修复时间。 |
| "批量写更高效" | 批量 = 没测 = 全部带病上线。逐 Skill RED-GREEN-REFACTOR。 |
| "已有 Skill 改一改就行" | 改 = 同等于新建，必须重跑 baseline。 |
| "把工作流粘贴到 Skill 即可" | 复制粘贴的工作流会原样复制漏洞。要先 RED 才能 GREEN。 |

## 8. 当前 Skill 健康度（季度巡检锚点）

| Skill | 状态 | 备注 |
|---|---|---|
| `superpowers:writing-skills` | 活跃 | 本文件即按其方法论组织 |
| `superpowers:using-superpowers` | 活跃 | 顶层入口，每次会话必跑 |
| `skill-create` | 活跃 | 与 `superpowers:writing-skills` 功能重叠，需在 §4 注明权威源 |
| `skillify` | 待盘 | 触发阈值"≥ 3 次复用"未量化 |
| `skill-health` | 待盘 | 巡检节奏未制度化 |
| `prune` | 待盘 | 上次运行时间未知 |
| `freeze` / `unfreeze` | 待盘 | 与 4A 治理基线（ADR-0001）联动 |

> 状态字段：`活跃`（高频使用 + 文档完整）/`待盘`（存在但未定期巡检）/`Deprecated`（已弃用，指向继任者）。

## 9. 维护

- 本文件随 Skill 治理实践演进，**修改前**必须先跑 `superpowers:writing-skills` 的 RED 流程（即使是文档本身）。
- 状态从 `待盘` → `活跃` 的转换需要在 PR 中附至少一次巡检的 evidence。
- 与 `docs/standards/architecture-collaboration-workflow.md` 冲突时，以 4A 协同工作流为准（详见 §6）。
