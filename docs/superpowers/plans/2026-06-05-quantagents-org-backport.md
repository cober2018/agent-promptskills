# QuantAgents 多 Agent 架构优化回灌 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 QuantAgents 项目（基于本模板的实例）跑通期间沉淀的优化——单入口导航 / /pm 命令 / 9 步链路硬化 / 量化双角色合一 / PM 推进官硬化——沉淀回本模板仓库 `agent-promptskills`。

**Architecture:** 单次迁移任务，不引入新代码逻辑。所有动作是"文件搬运 + 路径适配 + 人工 diff 同步"。验收通过 13 项 grep / diff / ls / chmod 校验保证正确性。

**Tech Stack:** Bash（diff / grep / chmod / git）/ Markdown / Claude `Agent` frontmatter / PreToolUse hook

**Spec:** `docs/superpowers/specs/2026-06-05-quantagents-org-backport-design.md`

---

## Phase 0: 准备

### Task 0.1: 建目录骨架 + 锁定基线

**Files:**
- Create: `.claude/commands/`
- Create: `.claude/hooks/`
- Create: `docs/tasks/`
- Create: `docs/superpowers/plans/`

- [ ] **Step 1: 创建目录**

```bash
mkdir -p .claude/commands .claude/hooks docs/tasks docs/superpowers/plans
```

- [ ] **Step 2: 验证目录存在**

```bash
test -d .claude/commands && test -d .claude/hooks && test -d docs/tasks && test -d docs/superpowers/plans && echo "ALL_OK"
```

Expected: `ALL_OK`

- [ ] **Step 3: 锁定基线分支 + 工作区干净**

```bash
git status --porcelain | wc -l
```

Expected: 输出一个数字。若不为 0（工作区有未提交改动），**停下来告诉用户**，请用户先 stash 或 commit。

- [ ] **Step 4: 确认当前在 main 分支且最新**

```bash
git rev-parse --abbrev-ref HEAD
git fetch origin && git status -sb | head -1
```

Expected: 当前分支 = `main`；与 `origin/main` 同步或 ahead。

- [ ] **Step 5: Commit（建目录无内容时跳过）**

如果 Step 3 输出 0（工作区干净），跳过此步。否则：

```bash
git add .claude/ docs/tasks/ docs/superpowers/plans/
git commit -m "chore: scaffold .claude/, docs/tasks/, docs/superpowers/plans/ for org backport"
```

---

### Task 0.2: 锁源文件清单（防止 QuantAgents 后续再改）

**Files:**
- Read: `/Users/mshengran/Project/QuantAgents/.agents/agents/pm.md`
- Read: `/Users/mshengran/Project/QuantAgents/.agents/agents/quant-researcher.md`
- Read: `/Users/mshengran/Project/QuantAgents/.agents/ROUTING.md`
- Read: `/Users/mshengran/Project/QuantAgents/.agents/README.md`
- Read: `/Users/mshengran/Project/QuantAgents/docs/standards/AGENT_ORG_INDEX.md`
- Read: `/Users/mshengran/Project/QuantAgents/.claude/commands/pm.md`
- Read: `/Users/mshengran/Project/QuantAgents/.claude/hooks/check-9step.sh`
- Read: `/Users/mshengran/Project/QuantAgents/docs/tasks/_template.md`
- Read: `/Users/mshengran/Project/QuantAgents/docs/standards/multi-agent-team-bootstrap.md`
- Read: `/Users/mshengran/Project/QuantAgents/docs/standards/architecture-collaboration-workflow.md`
- Read: `/Users/mshengran/Project/QuantAgents/docs/standards/agent-delivery-responsibility-routing.md`
- Read: `/Users/mshengran/Project/QuantAgents/agents/4a-architect.md` （注：不同路径）
- Read: `/Users/mshengran/Project/QuantAgents/agents/backend-engineer.md`
- Read: `/Users/mshengran/Project/QuantAgents/agents/frontend-engineer.md`
- Read: `/Users/mshengran/Project/QuantAgents/agents/data-engineer.md`
- Read: `/Users/mshengran/Project/QuantAgents/agents/qa-engineer.md`

- [ ] **Step 1: 验证 16 个源文件全部存在且非空**

```bash
for f in \
  /Users/mshengran/Project/QuantAgents/.agents/agents/pm.md \
  /Users/mshengran/Project/QuantAgents/.agents/agents/quant-researcher.md \
  /Users/mshengran/Project/QuantAgents/.agents/ROUTING.md \
  /Users/mshengran/Project/QuantAgents/.agents/README.md \
  /Users/mshengran/Project/QuantAgents/docs/standards/AGENT_ORG_INDEX.md \
  /Users/mshengran/Project/QuantAgents/.claude/commands/pm.md \
  /Users/mshengran/Project/QuantAgents/.claude/hooks/check-9step.sh \
  /Users/mshengran/Project/QuantAgents/docs/tasks/_template.md \
  /Users/mshengran/Project/QuantAgents/docs/standards/multi-agent-team-bootstrap.md \
  /Users/mshengran/Project/QuantAgents/docs/standards/architecture-collaboration-workflow.md \
  /Users/mshengran/Project/QuantAgents/docs/standards/agent-delivery-responsibility-routing.md \
  /Users/mshengran/Project/QuantAgents/agents/4a-architect.md \
  /Users/mshengran/Project/QuantAgents/agents/backend-engineer.md \
  /Users/mshengran/Project/QuantAgents/agents/frontend-engineer.md \
  /Users/mshengran/Project/QuantAgents/agents/data-engineer.md \
  /Users/mshengran/Project/QuantAgents/agents/qa-engineer.md ; do
  if [ ! -s "$f" ]; then
    echo "MISSING_OR_EMPTY: $f"
    exit 1
  fi
done
echo "ALL_SOURCES_OK"
```

Expected: `ALL_SOURCES_OK`

- [ ] **Step 2: 记录各文件 SHA-256 摘要到本地笔记（不提交）**

```bash
mkdir -p .git/scratch
for f in \
  /Users/mshengran/Project/QuantAgents/.agents/agents/pm.md \
  /Users/mshengran/Project/QuantAgents/.agents/agents/quant-researcher.md \
  /Users/mshengran/Project/QuantAgents/.agents/ROUTING.md \
  /Users/mshengran/Project/QuantAgents/docs/standards/AGENT_ORG_INDEX.md ; do
  shasum -a 256 "$f" | tee -a .git/scratch/source-shas.txt
done
```

这是为了让后续若 QuantAgents 改动能发现；`.git/scratch/` 不入 git。

- [ ] **Step 3: 不 commit（无产物变更）**

---

## Phase 1: 新增文件（先加新文件，不动旧文件）

### Task 1.1: 新增 `docs/standards/AGENT_ORG_INDEX.md`

**Files:**
- Create: `docs/standards/AGENT_ORG_INDEX.md`
- Source: `/Users/mshengran/Project/QuantAgents/docs/standards/AGENT_ORG_INDEX.md`

- [ ] **Step 1: 复制源文件**

```bash
cp /Users/mshengran/Project/QuantAgents/docs/standards/AGENT_ORG_INDEX.md \
   docs/standards/AGENT_ORG_INDEX.md
```

- [ ] **Step 2: 路径适配——把 `.agents/` 引用改为 `agents/`**

源文件中所有 `.agents/agents/` 改为 `agents/`，所有 `.agents/ROUTING.md` 改为 `agents/ROUTING.md`，所有 `.agents/README.md` 改为 `agents/README.md`，所有 `.agents/skills/` 改为 `agents/skills/`（如果存在）。

```bash
sed -i '' \
  -e 's|`\.agents/agents/|`agents/|g' \
  -e 's|`\.agents/ROUTING\.md`|`agents/ROUTING.md`|g' \
  -e 's|`\.agents/README\.md`|`agents/README.md`|g' \
  -e 's|`\.agents/skills/|`skills/|g' \
  -e 's|\.claude/agents → \.\./\.agents/agents/|\.claude/agents → ../agents/|g' \
  docs/standards/AGENT_ORG_INDEX.md
```

- [ ] **Step 3: 删除 QuantAgents 项目特定的 F 类（用户级 / 项目级 memory 引用）**

源 INDEX §3.6 包含 `~/.claude/projects/-Users-mshengran-Project-QuantAgents/memory/...`，是项目特定的，**不属于本模板**。把整个 §3.6 段从 INDEX 中移除（或留空 + 加 "本模板无 F 类" 说明）。本任务采用"删除 §3.6 整段并把 §4 引用关系图中的对应部分也清理"。

```bash
# 打印当前 §3.6 行号范围
grep -n "^### 3.6 F 类" docs/standards/AGENT_ORG_INDEX.md
grep -n "^## 4\." docs/standards/AGENT_ORG_INDEX.md
```

人工用 Read + Edit 删除 §3.6 整段（含 `---` 分隔符之间到 `## 4.` 之前的内容），并在原位插入：

```markdown
### 3.6 F 类：横切关注点（独立于 git repo）

> **本模板范围内无 F 类内容。** F 类（如跨会话 memory、周复盘、跨项目 skill）属于用户级 / 项目级配置（`~/.claude/`），由使用本模板的项目按需建立，不在通用模板内。
```

- [ ] **Step 4: 校验：INDEX 不再含 `.agents/` 引用**

```bash
grep -n "\.agents/" docs/standards/AGENT_ORG_INDEX.md && echo "STILL_HAS_DOT_AGENTS" || echo "OK"
```

Expected: `OK`

- [ ] **Step 5: 校验：INDEX 5 类文件清单 + 启动顺序 + 引用关系图都存在**

```bash
grep -c "^### 3\." docs/standards/AGENT_ORG_INDEX.md
grep -n "## 2. 启动顺序" docs/standards/AGENT_ORG_INDEX.md
grep -n "## 4. 引用关系图" docs/standards/AGENT_ORG_INDEX.md
```

Expected: 输出 6（3.1 到 3.6），两个 grep 都有行号。

- [ ] **Step 6: Commit**

```bash
git add docs/standards/AGENT_ORG_INDEX.md
git commit -m "feat(docs): add AGENT_ORG_INDEX as single-entry nav (backport from QuantAgents)"
```

---

### Task 1.2: 新增 `agents/ROUTING.md`

**Files:**
- Create: `agents/ROUTING.md`
- Source: `/Users/mshengran/Project/QuantAgents/.agents/ROUTING.md`

- [ ] **Step 1: 复制并路径适配**

```bash
cp /Users/mshengran/Project/QuantAgents/.agents/ROUTING.md agents/ROUTING.md
sed -i '' \
  -e 's|skills/writing-skills/|skills/writing-skills/|g' \
  -e 's|skills/subagent-driven-development/|skills/subagent-driven-development/|g' \
  -e 's|skills/systematic-debugging/|skills/systematic-debugging/|g' \
  -e 's|skills/verification-before-completion/|skills/verification-before-completion/|g' \
  -e 's|skills/test-driven-development/|skills/test-driven-development/|g' \
  -e 's|skills/dispatching-parallel-agents/|skills/dispatching-parallel-agents/|g' \
  -e 's|skills/requesting-code-review/|skills/requesting-code-review/|g' \
  -e 's|skills/receiving-code-review/|skills/receiving-code-review/|g' \
  -e 's|skills/using-git-worktrees/|skills/using-git-worktrees/|g' \
  -e 's|skills/finishing-a-development-branch/|skills/finishing-a-development-branch/|g' \
  -e 's|skills/brainstorming/|skills/brainstorming/|g' \
  -e 's|skills/writing-plans/|skills/writing-plans/|g' \
  -e 's|skills/executing-plans/|skills/executing-plans/|g' \
  -e 's|docs/standards/multi-agent-team-bootstrap\.md|docs/standards/multi-agent-team-bootstrap.md|g' \
  agents/ROUTING.md
```

> **注**：源 ROUTING.md 用的是相对路径 `skills/<name>/SKILL.md`（不带 `.agents/` 前缀），已与本模板一致；但 §2 派工矩阵引用了 QuantAgents 路径，需人工核对一遍。

- [ ] **Step 2: 人工 Read + 校对：派工矩阵中"上游 / 可直接派给"列出的 agent 在本模板中存在**

```bash
grep -E "quant-researcher|4a-architect|backend-engineer|frontend-engineer|data-engineer|qa-engineer" \
  agents/ROUTING.md | head -20
```

人工确认 7 个角色名（pm / 4a-architect / quant-researcher / backend-engineer / frontend-engineer / data-engineer / qa-engineer）全部出现在 ROUTING 派工矩阵中。

- [ ] **Step 3: 校验：路由矩阵 + 派工硬约束段存在**

```bash
grep -n "^## 1\.\|^## 2\.\|^## 4\." agents/ROUTING.md
```

Expected: 三个段落都存在。

- [ ] **Step 4: Commit**

```bash
git add agents/ROUTING.md
git commit -m "feat(agents): add ROUTING.md with dispatch matrix + agent-skill routing (backport)"
```

---

### Task 1.3: 新增 `agents/README.md`

**Files:**
- Create: `agents/README.md`
- Source: `/Users/mshengran/Project/QuantAgents/.agents/README.md`

- [ ] **Step 1: 复制并路径适配**

```bash
cp /Users/mshengran/Project/QuantAgents/.agents/README.md agents/README.md
sed -i '' \
  -e 's|`\.agents/agents/|`agents/|g' \
  -e 's|`\.agents/ROUTING\.md`|`agents/ROUTING.md`|g' \
  -e 's|`\.agents/README\.md`|`agents/README.md`|g' \
  agents/README.md
```

- [ ] **Step 2: 校验**

```bash
test -s agents/README.md && echo "OK"
grep -c "\.agents/" agents/README.md
```

Expected: 第一行 `OK`；第二行输出 0。

- [ ] **Step 3: Commit**

```bash
git add agents/README.md
git commit -m "docs(agents): add agents/ directory overview README (backport)"
```

---

### Task 1.4: 新增 `agents/pm.md`（业务 PMO + 推进官三角色合一）

**Files:**
- Create: `agents/pm.md`
- Source: `/Users/mshengran/Project/QuantAgents/.agents/agents/pm.md`

- [ ] **Step 1: 复制并显式路径替换（按 spec §2.2 rule 8）**

```bash
cp /Users/mshengran/Project/QuantAgents/.agents/agents/pm.md agents/pm.md

# 路径适配（少一级 `..`，且 .agents/ROUTING.md 改为 ROUTING.md）
sed -i '' \
  -e 's|../../docs/standards/multi-agent-team-bootstrap\.md|../docs/standards/multi-agent-team-bootstrap.md|g' \
  -e 's|../../\.agents/ROUTING\.md|ROUTING.md|g' \
  -e 's|../../README\.md|../README.md|g' \
  agents/pm.md
```

- [ ] **Step 2: 校验：3 个路径引用全部被改写**

```bash
grep -n "\.\./\.\./" agents/pm.md && echo "STILL_HAS_DOUBLE_DOT_DOT" || echo "OK_NO_DOUBLE_DOT"
grep -n "\.agents/ROUTING" agents/pm.md && echo "STILL_REFERENCES_DOT_AGENTS_ROUTING" || echo "OK_NO_DOT_AGENTS_ROUTING"
```

Expected: 两个 grep 都 `OK_*`。

- [ ] **Step 3: 校验：frontmatter 含 name "推进官"，正文含 `## 推进 9 步`**

```bash
head -5 agents/pm.md
grep -n "^## 推进 9 步" agents/pm.md
grep -n "推进官" agents/pm.md | head -3
```

Expected: frontmatter `name:` 含"推进官"；存在 `## 推进 9 步` 段；正文中"推进官"出现 ≥ 1 次。

- [ ] **Step 4: Commit**

```bash
git add agents/pm.md
git commit -m "feat(agents): add pm.md (PMO/需求分流官/推进官 three-role, backport + path adapt)"
```

---

### Task 1.5: 新增 `agents/quant-researcher.md`（双角色合一）

**Files:**
- Create: `agents/quant-researcher.md`
- Source: `/Users/mshengran/Project/QuantAgents/.agents/agents/quant-researcher.md`

- [ ] **Step 1: 复制并路径适配**

```bash
cp /Users/mshengran/Project/QuantAgents/.agents/agents/quant-researcher.md agents/quant-researcher.md
sed -i '' \
  -e 's|`\.agents/agents/|`agents/|g' \
  -e 's|`\.agents/ROUTING\.md`|`agents/ROUTING.md`|g' \
  -e 's|`\.agents/README\.md`|`agents/README.md`|g' \
  -e 's|`\.agents/skills/|`skills/|g' \
  -e 's|../../docs/standards/|../docs/standards/|g' \
  -e 's|../../README\.md|../README.md|g' \
  agents/quant-researcher.md
```

- [ ] **Step 2: 校验：双角色段都存在**

```bash
grep -n "业务 Lead\|Lead 模式\|执行模式" agents/quant-researcher.md | head -10
```

Expected: ≥ 3 行匹配（业务 Lead + Lead 模式 + 执行模式）。

- [ ] **Step 3: 校验：路径无 `.agents/` 残留**

```bash
grep -n "\.agents/" agents/quant-researcher.md && echo "STILL_HAS_DOT_AGENTS" || echo "OK"
```

Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add agents/quant-researcher.md
git commit -m "feat(agents): add quant-researcher.md (业务 Lead + 执行模式 dual-role, backport)"
```

---

### Task 1.6: 新增 `.claude/commands/pm.md`（/pm 命令入口）

**Files:**
- Create: `.claude/commands/pm.md`
- Source: `/Users/mshengran/Project/QuantAgents/.claude/commands/pm.md`

- [ ] **Step 1: 复制并路径适配**

```bash
cp /Users/mshengran/Project/QuantAgents/.claude/commands/pm.md .claude/commands/pm.md
sed -i '' \
  -e 's|参见 `\.agents/agents/pm\.md`|参见 `agents/pm.md`|g' \
  -e 's|`\.agents/agents/|`agents/|g' \
  .claude/commands/pm.md
```

- [ ] **Step 2: 校验**

```bash
head -5 .claude/commands/pm.md
grep -n "推进官\|PM" .claude/commands/pm.md | head -3
```

Expected: frontmatter `name: PM`；正文中"PM"出现 ≥ 2 次。

- [ ] **Step 3: Commit**

```bash
git add .claude/commands/pm.md
git commit -m "feat(cli): add /pm command entry (backport from QuantAgents)"
```

---

### Task 1.7: 新增 `.claude/hooks/check-9step.sh`（9 步链路 PreToolUse 拦截）

**Files:**
- Create: `.claude/hooks/check-9step.sh`
- Source: `/Users/mshengran/Project/QuantAgents/.claude/hooks/check-9step.sh`

- [ ] **Step 1: 复制**

```bash
cp /Users/mshengran/Project/QuantAgents/.claude/hooks/check-9step.sh .claude/hooks/check-9step.sh
```

- [ ] **Step 2: 设为可执行**

```bash
chmod +x .claude/hooks/check-9step.sh
ls -l .claude/hooks/check-9step.sh
```

Expected: 权限位含 `x`（`-rwxr-xr-x` 或类似）。

- [ ] **Step 3: 校验：hook 含 9 步关键字 + 路径 `docs/tasks/`**

```bash
grep -c "writing-plans\|/autoplan\|subagent-driven-development\|TDD\|systematic-debugging\|/qa\|code-review\|/ship\|/cso" \
  .claude/hooks/check-9step.sh
grep -n "docs/tasks" .claude/hooks/check-9step.sh
```

Expected: 第一个 grep ≥ 1；第二个 grep 有行号。

- [ ] **Step 4: 干跑 hook（不应拦截无 git commit 的输入）**

```bash
echo '{}' | bash .claude/hooks/check-9step.sh
```

Expected: 输出 `{}`，无 stderr。

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/check-9step.sh
git commit -m "feat(hook): add check-9step.sh PreToolUse guard for 9-step chain (backport)"
```

---

### Task 1.8: 新增 `docs/tasks/_template.md`（9 步 plan 模板）

**Files:**
- Create: `docs/tasks/_template.md`
- Source: `/Users/mshengran/Project/QuantAgents/docs/tasks/_template.md`

- [ ] **Step 1: 复制并路径适配**

```bash
cp /Users/mshengran/Project/QuantAgents/docs/tasks/_template.md docs/tasks/_template.md
sed -i '' \
  -e 's|`\.claude/hooks/check-9step\.sh`|`.claude/hooks/check-9step.sh`|g' \
  -e 's|docs/standards/multi-agent-team-bootstrap\.md|docs/standards/multi-agent-team-bootstrap.md|g' \
  -e 's|docs/standards/architecture-collaboration-workflow\.md|docs/standards/architecture-collaboration-workflow.md|g' \
  docs/tasks/_template.md
```

> 模板里 `docs/tasks/<branch-name>.md` 已经是相对路径，无需改写。

- [ ] **Step 2: 校验：9 步 checklist 全列**

```bash
grep -E "writing-plans|/autoplan|subagent-driven-development|TDD|systematic-debugging|/qa|code-review|/ship|/cso" \
  docs/tasks/_template.md | wc -l
```

Expected: ≥ 9 行匹配。

- [ ] **Step 3: Commit**

```bash
git add docs/tasks/_template.md
git commit -m "feat(docs): add docs/tasks/_template.md 9-step plan template (backport)"
```

---

### Task 1.9: 新增 `docs/adr/0003-quant-team-merge.md`

**Files:**
- Create: `docs/adr/0003-quant-team-merge.md`

- [ ] **Step 1: 写 ADR**

参照 `docs/adr/0001-4a-collaboration-baseline.md` 的风格（先 Read 它再写），写新 ADR。结构（按 `architecture-collaboration-workflow.md` §4 模板：标题 / 状态 / 背景 / 决策 / 备选 / 权衡 / 后果）：

```markdown
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
```

- [ ] **Step 2: 校验**

```bash
test -s docs/adr/0003-quant-team-merge.md && echo "OK"
grep -E "^## (背景|决策|备选|权衡|后果)" docs/adr/0003-quant-team-merge.md
```

Expected: 5 个二级标题（背景 / 决策 / 备选 / 权衡 / 后果）。

- [ ] **Step 3: Commit**

```bash
git add docs/adr/0003-quant-team-merge.md
git commit -m "docs(adr): add ADR-0003 for quant team 4-merge-1 with dual-role"
```

---

## Phase 2: 同步差异（merge 7 Agent + 3 standards + 2 文档）

### Task 2.1: 同步 `agents/4a-architect.md`

**Files:**
- Modify: `agents/4a-architect.md`
- Source diff: `diff -u /Users/mshengran/Project/agent-promptskills/agents/4a-architect.md /Users/mshengran/Project/QuantAgents/agents/4a-architect.md`

- [ ] **Step 1: 跑 diff 记录差异**

```bash
diff -u /Users/mshengran/Project/agent-promptskills/agents/4a-architect.md \
        /Users/mshengran/Project/QuantAgents/agents/4a-architect.md \
  > .git/scratch/diff-4a-architect.patch
wc -l .git/scratch/diff-4a-architect.patch
```

- [ ] **Step 2: 阅读 diff，逐段决定接受 / 拒绝 / 改写**

人工用 Read 工具查看 `agents/4a-architect.md` 和 QuantAgents 版本，按以下原则决定：
- **接受** QuantAgents 的：硬约束指针更新（指向新 ROUTING.md、新 INDEX）、量化业务相关内容、3 层组织（PMO → Lead → IC）语句
- **拒绝** QuantAgents 的：项目特定的命令引用（如特定文件路径、特定项目 ADR 编号）
- **保留** 本模板的：本模板独有的硬约束（如 SKILL.md 风格、特定章节）

- [ ] **Step 3: 用 Edit 工具应用接受的部分**

逐段 Edit。每段 Edit 完成后，跳到 Step 4 校验。

- [ ] **Step 4: 校验：4A 硬约束段（4A 协同工作流硬约束）仍完整**

```bash
grep -n "^## 协同工作流硬约束" agents/4a-architect.md
grep -c "^[0-9]\. \*\*" agents/4a-architect.md
```

Expected: 段标题存在；编号列表 ≥ 5 条（4A 五条硬约束）。

- [ ] **Step 5: Commit**

```bash
git add agents/4a-architect.md
git commit -m "refactor(agents): sync 4a-architect.md with QuantAgents hardening"
```

---

### Task 2.2: 同步 `agents/backend-engineer.md`

**Files:**
- Modify: `agents/backend-engineer.md`
- Source diff: `diff -u /Users/mshengran/Project/agent-promptskills/agents/backend-engineer.md /Users/mshengran/Project/QuantAgents/agents/backend-engineer.md`

- [ ] **Step 1: 跑 diff 记录差异**

```bash
diff -u /Users/mshengran/Project/agent-promptskills/agents/backend-engineer.md \
        /Users/mshengran/Project/QuantAgents/agents/backend-engineer.md \
  > .git/scratch/diff-backend-engineer.patch
wc -l .git/scratch/diff-backend-engineer.patch
```

- [ ] **Step 2: 阅读 diff，逐段决定接受 / 拒绝 / 改写**

原则同 Task 2.1。Backend engineer 硬约束（不派工 / 单测 / 自审）必须保留。

- [ ] **Step 3: 用 Edit 工具应用**

- [ ] **Step 4: 校验：硬约束段（关键规则）仍存在**

```bash
grep -n "^## 关键规则\|^## 硬约束" agents/backend-engineer.md
```

Expected: 段标题存在。

- [ ] **Step 5: Commit**

```bash
git add agents/backend-engineer.md
git commit -m "refactor(agents): sync backend-engineer.md with QuantAgents hardening"
```

---

### Task 2.3: 同步 `agents/frontend-engineer.md`

**Files:**
- Modify: `agents/frontend-engineer.md`

- [ ] **Step 1-5**: 重复 Task 2.2 流程，把 `backend-engineer` 替换为 `frontend-engineer`。每步 git 操作都用 frontend 名字。

---

### Task 2.4: 同步 `agents/data-engineer.md`

**Files:**
- Modify: `agents/data-engineer.md`

- [ ] **Step 1-5**: 重复 Task 2.2 流程。

---

### Task 2.5: 同步 `agents/qa-engineer.md`

**Files:**
- Modify: `agents/qa-engineer.md`

- [ ] **Step 1-5**: 重复 Task 2.2 流程。

---

### Task 2.6: 同步 `docs/standards/multi-agent-team-bootstrap.md`（关键：含 §1.4 / §3.4 / §6.1）

**Files:**
- Modify: `docs/standards/multi-agent-team-bootstrap.md`

- [ ] **Step 1: 跑 diff 记录差异**

```bash
diff -u /Users/mshengran/Project/agent-promptskills/docs/standards/multi-agent-team-bootstrap.md \
        /Users/mshengran/Project/QuantAgents/docs/standards/multi-agent-team-bootstrap.md \
  > .git/scratch/diff-bootstrap.patch
wc -l .git/scratch/diff-bootstrap.patch
```

- [ ] **Step 2: 阅读 diff**

人工 Review diff。重点关注：
- 是否包含 `### 1.4 PM 的"推进官"职责`
- 是否包含 `### 3.4 PM 持续推进 9 步`
- 是否 §6.1 PM 模板被重写

- [ ] **Step 3: 用 QuantAgents 2026-06-05 硬化版覆盖 §1.4 / §3.4 / §6.1 三个段**

由于本模板原版的 §1.4 / §3.4 / §6.1 不存在，**直接**从 QuantAgents 复制这三个段（路径已在 QuantAgents 文件内正确）：

```bash
# 提取 §1.4 段
awk '/^### 1\.4 /,/^---$/' \
  /Users/mshengran/Project/QuantAgents/docs/standards/multi-agent-team-bootstrap.md \
  > .git/scratch/section-1.4.md

# 提取 §3.4 段
awk '/^### 3\.4 /,/^---$/' \
  /Users/mshengran/Project/QuantAgents/docs/standards/multi-agent-team-bootstrap.md \
  > .git/scratch/section-3.4.md

# 提取 §6.1 段
awk '/^### 6\.1 /,/^### 6\.2 /' \
  /Users/mshengran/Project/QuantAgents/docs/standards/multi-agent-team-bootstrap.md \
  > .git/scratch/section-6.1.md

wc -l .git/scratch/section-*.md
```

Expected: 三个文件都有内容（> 10 行）。

- [ ] **Step 4: 在本模板的 bootstrap 文件中插入 §1.4（在 §1.3 之后）**

```bash
# 用 Read 工具先看 §1.3 结束位置，然后 Edit 在 §1.3 末尾插入 §1.4 内容
```

- [ ] **Step 5: 在 §3.3 之后插入 §3.4**

- [ ] **Step 6: 用 QuantAgents §6.1 替换本模板的 §6.1**

- [ ] **Step 7: 校验：3 个新段都存在 + 路径引用无 `.agents/` 残留**

```bash
grep -n "^### 1\.4 \|^### 3\.4 \|^### 6\.1 " docs/standards/multi-agent-team-bootstrap.md
grep -n "\.agents/" docs/standards/multi-agent-team-bootstrap.md && echo "STILL_HAS_DOT_AGENTS" || echo "OK"
```

Expected: 3 个段标题都有；`OK`。

- [ ] **Step 8: Commit**

```bash
git add docs/standards/multi-agent-team-bootstrap.md
git commit -m "refactor(standards): sync multi-agent-team-bootstrap with PM 推进官 hardening (2026-06-05)"
```

---

### Task 2.7: 同步 `docs/standards/architecture-collaboration-workflow.md`

**Files:**
- Modify: `docs/standards/architecture-collaboration-workflow.md`

- [ ] **Step 1-5**: 重复 Task 2.2 流程（diff → review → edit → verify → commit）。4A 治理基线 5 条硬约束 + ADR 流程保持不变（spec §4 红线）。

---

### Task 2.8: 同步 `docs/standards/agent-delivery-responsibility-routing.md`

**Files:**
- Modify: `docs/standards/agent-delivery-responsibility-routing.md`

- [ ] **Step 1-5**: 重复 Task 2.2 流程。

---

### Task 2.9: 更新 `README.md`（顶部加 INDEX 引用 + 9 步链路段）

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 读 README.md 顶部 30 行**

```bash
head -30 README.md
```

- [ ] **Step 2: 在合适位置（一般在"## 入口"或类似段）插入新段**

插入内容（不超过 8 行）：

```markdown
## 多 Agent 团队架构

- 导航：[`docs/standards/AGENT_ORG_INDEX.md`](docs/standards/AGENT_ORG_INDEX.md) —— 5 类文件清单 + 启动顺序 + 引用关系图
- 派工权威源：[`agents/ROUTING.md`](agents/ROUTING.md) —— 派工硬约束 + Agent × Skill 路由矩阵
- 团队搭建方法论：[`docs/standards/multi-agent-team-bootstrap.md`](docs/standards/multi-agent-team-bootstrap.md) —— 13 步 bootstrap 流程 + 5 个 prompt 模板 + 9 步推进机制
- 4A 治理：[`docs/standards/architecture-collaboration-workflow.md`](docs/standards/architecture-collaboration-workflow.md)
```

- [ ] **Step 3: 校验**

```bash
grep -n "AGENT_ORG_INDEX\|ROUTING\.md\|multi-agent-team-bootstrap" README.md
```

Expected: 3 个引用都出现。

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(readme): add org architecture section pointing to INDEX + ROUTING + bootstrap"
```

---

### Task 2.10: 更新 `docs/skill-lifecycle.md`（顶部加 9 步链路 + INDEX 引用）

**Files:**
- Modify: `docs/skill-lifecycle.md`

- [ ] **Step 1: 读 docs/skill-lifecycle.md 顶部 20 行**

```bash
head -20 docs/skill-lifecycle.md
```

- [ ] **Step 2: 在文件开头（> 引用之后，§1 之前）插入一段**

插入内容（不超过 6 行）：

```markdown
> **强制 9 步链路**：本仓库 Skill 治理与任何非例行 commit 受 `.claude/hooks/check-9step.sh` 拦截。完整流程见 [`docs/standards/AGENT_ORG_INDEX.md`](AGENT_ORG_INDEX.md) + 模板 [`docs/tasks/_template.md`](../tasks/_template.md)。
```

- [ ] **Step 3: 校验**

```bash
grep -n "check-9step\|AGENT_ORG_INDEX" docs/skill-lifecycle.md
```

Expected: 2 个引用都出现。

- [ ] **Step 4: Commit**

```bash
git add docs/skill-lifecycle.md
git commit -m "docs(skill-lifecycle): add 9-step chain + AGENT_ORG_INDEX reference"
```

---

## Phase 3: 一次性删除 4 个 quant 旧文件（用户已确认）

### Task 3.1: 验证 `agents/quant-researcher.md` 覆盖原 4 个文件

**Files:**
- Read: `agents/quant/quant-china-market-analyst.md`
- Read: `agents/quant/quant-factor-researcher.md`
- Read: `agents/quant/quant-news-social-analyst.md`
- Read: `agents/quant/quant-strategy-researcher.md`
- Read: `agents/quant-researcher.md`

- [ ] **Step 1: 读 4 个旧文件 + 新 quant-researcher.md**

```bash
ls -la agents/quant/
ls -la agents/quant-researcher.md
wc -l agents/quant/*.md agents/quant-researcher.md
```

- [ ] **Step 2: 人工对照确认 quant-researcher.md 覆盖了 4 个原 agent 的核心能力**

读每个原文件，列出其"## 核心使命 / ## 能力"段，与 quant-researcher.md 的"业务侧（Lead）职责 + 技术侧（执行）职责"段对照，确认 4 个子领域（中国市场 / 因子 / 新闻舆情 / 策略）的能力都已在新文件中以段或子节形式表达。如果有遗漏，**停下来**先补 quant-researcher.md，再继续。

- [ ] **Step 3: 不 commit（无产物变更）**

---

### Task 3.2: 删除 4 个 quant 旧文件

**Files:**
- Delete: `agents/quant/quant-china-market-analyst.md`
- Delete: `agents/quant/quant-factor-researcher.md`
- Delete: `agents/quant/quant-news-social-analyst.md`
- Delete: `agents/quant/quant-strategy-researcher.md`

- [ ] **Step 1: git rm 4 个文件**

```bash
git rm agents/quant/quant-china-market-analyst.md \
       agents/quant/quant-factor-researcher.md \
       agents/quant/quant-news-social-analyst.md \
       agents/quant/quant-strategy-researcher.md
```

- [ ] **Step 2: 移除空目录（如有）**

```bash
test -d agents/quant && rmdir agents/quant && echo "REMOVED_EMPTY_DIR" || echo "DIR_NOT_EMPTY_OR_GONE"
```

- [ ] **Step 3: 校验：4 个文件已删，agents/quant 目录不存在**

```bash
ls agents/quant/ 2>&1
ls agents/ | grep quant
```

Expected: 第一个命令报"目录不存在"；第二个命令只剩 `quant-researcher.md`。

- [ ] **Step 4: Commit**

```bash
git commit -m "refactor(agents): remove 4 quant sub-agents, replaced by unified quant-researcher.md (per ADR-0003)"
```

---

## Phase 4: 验收（跑 13 项检查）

### Task 4.1: 跑全量 13 项验收

**Files:**
- Read-only validation (no changes)

- [ ] **Step 1: 验收项 1-2（新文件存在 + 旧文件已删）**

```bash
test -s docs/standards/AGENT_ORG_INDEX.md && \
test -s agents/ROUTING.md && \
test -s agents/README.md && \
test -s agents/pm.md && \
test -s agents/quant-researcher.md && \
test -s .claude/commands/pm.md && \
test -s .claude/hooks/check-9step.sh && \
test -s docs/tasks/_template.md && \
test -s docs/adr/0003-quant-team-merge.md && \
test -s docs/superpowers/specs/2026-06-05-quantagents-org-backport-design.md && \
test -s docs/superpowers/plans/2026-06-05-quantagents-org-backport.md && \
echo "PASS: 1-新文件"
ls agents/quant/ 2>&1 | grep -q "No such file" && echo "PASS: 2-旧文件已删"
```

Expected: `PASS: 1-新文件` + `PASS: 2-旧文件已删`

- [ ] **Step 2: 验收项 3（同名 Agent / standards 同步）**

```bash
test -s agents/4a-architect.md && \
test -s agents/backend-engineer.md && \
test -s agents/frontend-engineer.md && \
test -s agents/data-engineer.md && \
test -s agents/qa-engineer.md && \
test -s docs/standards/multi-agent-team-bootstrap.md && \
test -s docs/standards/architecture-collaboration-workflow.md && \
test -s docs/standards/agent-delivery-responsibility-routing.md && \
echo "PASS: 3-同步差异文件"
```

Expected: `PASS`

- [ ] **Step 3: 验收项 4（README + skill-lifecycle 已加引用）**

```bash
grep -q "AGENT_ORG_INDEX" README.md && echo "PASS: 4a-README"
grep -q "AGENT_ORG_INDEX" docs/skill-lifecycle.md && echo "PASS: 4b-skill-lifecycle"
```

Expected: 2 个 `PASS`

- [ ] **Step 4: 验收项 5（quant-researcher.md 含双角色）**

```bash
grep -q "业务 Lead" agents/quant-researcher.md && \
grep -q "执行模式" agents/quant-researcher.md && \
echo "PASS: 5-quant 双角色"
```

Expected: `PASS`

- [ ] **Step 5: 验收项 6（ROUTING.md 派工矩阵 + Agent×Skill 路由矩阵）**

```bash
grep -q "^## 1\." agents/ROUTING.md && \
grep -q "^## 2\." agents/ROUTING.md && \
grep -q "^## 4\." agents/ROUTING.md && \
echo "PASS: 6-ROUTING 段"
```

Expected: `PASS`

- [ ] **Step 6: 验收项 7（INDEX 5 类文件清单 + 启动顺序）**

```bash
N=$(grep -c "^### 3\." docs/standards/AGENT_ORG_INDEX.md)
test "$N" -ge 5 && echo "PASS: 7a-INDEX 5+类 ($N)"
grep -q "^## 2\. 启动顺序" docs/standards/AGENT_ORG_INDEX.md && echo "PASS: 7b-INDEX 启动顺序"
grep -q "^## 4\. 引用关系图" docs/standards/AGENT_ORG_INDEX.md && echo "PASS: 7c-INDEX 引用关系图"
```

Expected: 3 个 `PASS`

- [ ] **Step 7: 验收项 8（/pm 命令可识别）**

```bash
head -3 .claude/commands/pm.md | grep -q "name: PM" && echo "PASS: 8-/pm 命令"
```

Expected: `PASS`

- [ ] **Step 8: 验收项 9（hook 可执行）**

```bash
[ -x .claude/hooks/check-9step.sh ] && echo "PASS: 9-hook 可执行"
```

Expected: `PASS`

- [ ] **Step 9: 验收项 10（_template.md 9 步 checklist）**

```bash
N=$(grep -cE "writing-plans|/autoplan|subagent-driven-development|TDD|systematic-debugging|/qa|code-review|/ship|/cso" docs/tasks/_template.md)
test "$N" -ge 9 && echo "PASS: 10-_template 9 步 ($N)"
```

Expected: `PASS`

- [ ] **Step 10: 验收项 11（ADR-0003 存在）**

```bash
test -s docs/adr/0003-quant-team-merge.md && echo "PASS: 11-ADR-0003"
```

Expected: `PASS`

- [ ] **Step 11: 验收项 12（Skill 治理 + 新媒体系列不丢失）**

```bash
for s in skillify skill-health pruning-skills xhs-operation bilibili-operation wechat-operation douyin-tiktok-operation news-gathering video-editing-direction video-transcript-copywriting; do
  test -d "skills/$s" || { echo "MISSING: skills/$s"; exit 1; }
done
echo "PASS: 12-Skill 治理+新媒体系列"
```

Expected: `PASS`

- [ ] **Step 12: 验收项 13（路径一致性：无 `.agents/` 残留）**

```bash
for f in docs/standards/AGENT_ORG_INDEX.md agents/ROUTING.md agents/README.md agents/pm.md agents/quant-researcher.md; do
  if grep -q "\.agents/" "$f"; then
    echo "DIRTY: $f still has .agents/"
    grep -n "\.agents/" "$f"
    exit 1
  fi
done
echo "PASS: 13-路径一致性"
```

Expected: `PASS`

- [ ] **Step 13: 跑 13 项最终汇总**

回到 Step 1-12，把每步输出贴在一起，确认 13 个 `PASS:*` 标签全有。如缺任一，**停下来**修复后重跑。

- [ ] **Step 14: 不 commit（无产物变更）**

---

### Task 4.2: 完整收尾

**Files:**
- Read-only

- [ ] **Step 1: 工作区状态确认**

```bash
git status --porcelain
```

Expected: 输出为空（除非有未跟踪的 `.git/scratch/`——这不需 commit）。

- [ ] **Step 2: 看 commit 历史**

```bash
git log --oneline -20
```

确认 11 个 commit（Phase 1 = 9 + Phase 2 = 10 + Phase 3 = 1 = 20）按顺序排列。

- [ ] **Step 3: 推送到远端（如用户要求）**

询问用户是否 push。若要 push：

```bash
git push origin main
```

- [ ] **Step 4: 通知用户完成**

```
✅ QuantAgents org backport 完成
- 10 新增 / 4 删除 / 10 同步 / 1 ADR / 1 spec / 1 plan
- 13 项验收全 PASS
- 工作区干净
下一步：可走 gstack:/ship 或 /cso（如需）
```

---

## Self-Review（plan 完成时跑过）

**1. Spec coverage**：
- spec §1.1 全部 10 行优化项 → Task 1.1-1.9 + Task 2.1-2.10 覆盖 ✓
- spec §1.2 不在范围 → 全 plan 显式排除 ✓
- spec §1.3 路径适配 → Task 1.1 Step 2 + Task 1.4 Step 1 + §2.2 rule 8 显式 ✓
- spec §2.1.1 新增 10 个文件 → Task 1.1-1.9 + spec/plan 自身 ✓
- spec §2.1.2 删除 4 个文件 → Task 3.2 ✓
- spec §2.1.3 同步 10 个文件 → Task 2.1-2.10 ✓
- spec §2.2 适配原则 8 条 → Task 1.1-1.7 路径 sed 命令 + Task 1.4 内链 sed 覆盖 ✓
- spec §2.3 验收 13 项 → Task 4.1 全部覆盖 ✓
- spec §2.4 风险与缓解 → 13 项验收 + ADR + git 历史兜底 ✓

**2. Placeholder scan**：全 plan 实际命令、文件路径、commit message、grep 模式——无"TBD / TODO / 适当处理 / 等等"。

**3. Type consistency**：所有 `agents/<name>.md`、`docs/standards/<name>.md`、`.claude/commands/pm.md`、`.claude/hooks/check-9step.sh` 名称跨 Task 一致。

**Gaps**：
- 验收项 4（README + skill-lifecycle）有 4a/4b 两个子项，在 Step 3 已覆盖
- 验收项 7（INDEX）有 3 个子项（5+ 类 / 启动顺序 / 引用关系图），在 Step 6 覆盖
- 验收项 12（Skill 系列）有 10 个 skill 目录需要存在，Step 11 显式列出

**No-spec-extras**：所有 plan 任务都能映射到 spec 行；plan 没引入 spec 外的新需求。
