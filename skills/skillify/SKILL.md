---
name: skillify
description: Use when the same multi-step workflow recurs across 3+ unrelated tasks or projects and a CLAUDE.md note or one-off skill isn't enough — converts a proven workflow into a durable, agent-loadable skill
---

# Skillify

## Overview

A workflow deserves to become a skill when the cost of rediscovery exceeds the cost of writing + testing it. This skill is the gate: it tells you when to promote a workflow from "thing we do" to "thing an agent can load" — and walks you through the promotion so you don't skip RED.

The output of this skill is **always** a tested skill file (`SKILL.md`) plus any supporting references, registered in `docs/skill-lifecycle.md` §4. The output is **never** a Slack message, a README paragraph, or a CLAUDE.md bullet.

## When to Use

Use this skill when **all** of the following are true:

- The workflow has been executed **3 or more times** across unrelated tasks or projects.
- The rediscovery cost (re-deriving the steps each time) is observable in transcripts.
- The workflow is **judgment-heavy** (not regex-enforceable, not a single command).
- The workflow is **scope-portable** (it generalizes beyond the original context).

**Don't use** for:

- One-off solutions. Write a CLAUDE.md note instead.
- Standard practices well-documented by upstream tools (link to those, don't duplicate).
- Mechanical constraints enforceable with lint / CI (automate, don't document).
- Project-specific conventions (put in `CLAUDE.md` in that project).

## Core Methodology

### 1. Validate the 3-Signal Threshold

Before writing anything, confirm all four gates from "When to Use". If any one fails, route to the correct alternative (CLAUDE.md, upstream doc, automation, or project CLAUDE.md) and stop.

### 2. Mine the Evidence

Pull the 3+ prior executions from conversation transcripts / PR history. Extract:

- The exact steps the agent took (verbatim, not paraphrased).
- The rationalizations the agent had to overcome.
- The mistakes the agent made on first attempt.
- The minimal prompt that would have produced the correct steps first time.

If the prior transcripts are thin or hypothetical, **stop** — you don't have RED evidence yet. The skill will be untestable.

### 3. Write the Skill via `writing-skills`

Hand off to `writing-skills` for the full RED → GREEN → REFACTOR cycle. **Do not** write `SKILL.md` directly without that handoff — `writing-skills` is the discipline-enforcing skill that prevents "well-meaning but untested" skills from being committed.

The minimum handoff payload is:

- The evidence transcripts (step 2 output).
- The proposed skill name + a 1-sentence trigger.
- A pointer to the closest existing skill in the namespace (if any) so the new one can be distinguished.

### 4. Register the New Skill

After `writing-skills` GREEN, register the new skill in `docs/skill-lifecycle.md`:

- Add to §4 引用清单 with one-line positioning.
- Add to §8 健康度台账 as `活跃` (or `待盘` if rollout is staged).
- If the skill affects cross-agent behavior, file an ADR per `docs/standards/architecture-collaboration-workflow.md` §5.

## Quick Reference

| Question | Answer |
|---|---|
| "Is this worth a skill?" | Only after 3+ real executions. |
| "Where do the steps come from?" | From real transcripts, not from memory. |
| "Can I skip RED?" | No. Use `writing-skills` for the full cycle. |
| "Where do I document the new skill?" | `docs/skill-lifecycle.md` §4 + §8. |
| "What if it's project-specific?" | Don't skillify it; put in project `CLAUDE.md`. |

## Common Mistakes

| Mistake | Fix |
|---|---|
| Writing the skill before 3 executions exist | Stop. Mine more evidence first. |
| Skipping `writing-skills` and committing `SKILL.md` directly | Handoff to `writing-skills` for the RED-GREEN-REFACTOR cycle. |
| Treating one thoughtful execution as "established practice" | One execution = anecdote. Three = data. |
| Writing a 500-line skill for a 3-line workflow | Skillify the **minimal viable skill**, link to upstream docs for the rest. |
| Registering in `skill-lifecycle.md` without testing | Registration is the **last** step, after GREEN. |
| Skillifying a regex-enforceable rule | Automate it with a hook or linter instead. |

## Required Background

- `superpowers:writing-skills` — the actual RED-GREEN-REFACTOR machinery. This skill is the gate; `writing-skills` is the factory.
- `superpowers:using-superpowers` — to know which skills to load alongside this one.
- `docs/skill-lifecycle.md` — where the new skill is registered after GREEN.

## Related Skills

- `writing-skills` — does the actual authoring + testing.
- `skill-health` — periodic check on the resulting skill.
- `pruning-skills` — handles skills that turn out to be unskillifiable (after 6 months of failed attempts).
