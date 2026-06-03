---
name: pruning-skills
description: Use when the workspace's skill namespace has grown past what agents actually load, when a skill is fully superseded by a successor, or during a quarterly/half-year skill cleanup to mark skills `Deprecated` with a successor pointer
---

# Pruning Skills

## Overview

Pruning a skill is **not** deleting the file. Pruning is the discipline of marking a skill `Deprecated`, pointing every reference at the successor, and waiting one full release window before any deletion. This protects agents that haven't migrated yet and preserves the audit trail of how the workflow evolved.

This skill defines the four-step pruning protocol and the verdict matrix that decides what to prune.

## When to Use

Use this skill when **any** of the following triggers fire:

- Quarterly / half-year skill cleanup tick.
- A new skill supersedes an old one (e.g. `writing-skills` supersedes a now-redundant "skill-v1" skill).
- A skill is consistently **not loaded** for ≥ 2 quarters.
- A skill is **not loadable** (broken frontmatter, missing dependencies, target tool no longer exists).
- The workspace skill count exceeds a soft cap (suggested: > 80 skills triggers a pruning pass).

**Don't use** to fix a skill that has a `Drift` verdict (use `writing-skills` REFACTOR) or to clean up a single malformed skill (just fix it directly).

## Pruning Protocol

A pruning pass is a 4-step loop. Each step has a deliverable; the next step cannot start without the previous one's deliverable.

### Step 1 — Inventory

For each skill in the workspace, collect:

| Field | Source |
|---|---|
| Last loaded (date) | Transcript grep, runtime log |
| Last referenced (date) | Git blame on `docs/skill-lifecycle.md` |
| Compliance diff (does loading it still change behavior?) | `skill-health` last report |
| Successor (if any) | Manual + `skill-health` rotation check |
| Severity | `Healthy` / `Drift` / `Bloat` / `Retire` / `Broken` |

Deliverable: a one-row-per-skill table.

### Step 2 — Verdict

For each row, assign a verdict and an action:

| Verdict | Definition | Action |
|---|---|---|
| `Keep` | Healthy, loaded in last quarter, compliance diff > 0 | None. |
| `Migrate` | Healthy but a successor exists | Update all references to point at successor; mark current `Deprecated`. |
| `Retire` | Compliance diff = 0 AND zero loads in 2 quarters | Mark `Deprecated` with successor = "absorbed into model behavior". Wait one release window. |
| `Rewrite` | `Drift` from `skill-health` | Hand off to `writing-skills` REFACTOR. |
| `Remove` | `Broken` (unloadable) AND no users | Mark `Deprecated`; delete only after one release window. |

### Step 3 — Execute

For each `Migrate` / `Retire` / `Remove` verdict, do **all** of the following in one PR:

1. Update the skill's `SKILL.md` frontmatter description to start with `DEPRECATED:` and end with a `Successor:` line. Do **not** delete the file.
2. Update `docs/skill-lifecycle.md` §4 to mark the row as `Deprecated` and point at the successor.
3. Grep the rest of the workspace for any reference to this skill (other skill frontmatter, agent prompts, docs, runbooks) and rewrite each reference to the successor.
4. If the skill is also listed in any platform agent's `skills` array (e.g. `multica agent skills`), remove it after the successor has been added to the same agent.

### Step 4 — Wait + Re-evaluate

After one full release window:

- If no agent or transcript has loaded the deprecated skill: delete the file.
- If something still loaded it: investigate why the migration missed it. Either improve the successor or extend the wait.

## What Pruning Is NOT

| Misconception | Reality |
|---|---|
| Pruning = delete the file | Pruning = mark `Deprecated` + migrate references + wait. Deletion comes after a release window. |
| Pruning = judgement call | Pruning has a fixed protocol; deviations must be documented in the PR. |
| Pruning = write `Removed: <date>` in the frontmatter | The frontmatter is for the new state; the audit trail lives in `docs/skill-lifecycle.md` and git history. |
| Pruning is a one-time event | Pruning is a recurring hygiene task (quarterly / half-year). |

## Quick Reference

| Question | Answer |
|---|---|
| "When can I delete a skill?" | After one full release window post-`Deprecated` with zero loads. |
| "How do I migrate references?" | Grep for the old name, rewrite to the successor, commit in one PR. |
| "What if a deprecated skill is still being loaded?" | Don't delete yet. Investigate the migration gap. |
| "What if I have no successor?" | Mark `Retire` (absorbed into model behavior), not `Remove`. |
| "What if the file is unparseable?" | Mark `Broken` and `Remove` only after one release window. |

## Common Mistakes

| Mistake | Fix |
|---|---|
| Deleting the file immediately | Stop. Mark `Deprecated`, migrate references, wait. |
| Marking `Deprecated` without updating references | All references must be rewritten in the same PR, otherwise agents still load the old skill. |
| Forgetting the platform `multica agent skills` array | The agent's `skills` list is a separate source of truth. Remove from there too. |
| Pruning without a baseline | Use `skill-health` first. Pruning an `Healthy` skill by mistake loses working capability. |
| Batching > 5 skills in one PR | Hard to review. One PR per pruning verdict class. |
| Using `prune` as a verb in a commit message | Use `chore(skills): deprecate <name>, successor=<new>`. |

## Required Background

- `superpowers:writing-skills` — to know what a "compliant skill" looks like before deciding to retire one.
- `skill-health` — supplies the verdict matrix and the compliance-diff number.
- `superpowers:using-superpowers` — for the meta-routing decision of when to load this skill.
- `docs/skill-lifecycle.md` §4 / §8 — the registration / health ledger.

## Related Skills

- `writing-skills` — does the actual edit / upgrade work for `Rewrite` verdicts.
- `skill-health` — supplies the inventory and verdict.
- `skillify` — the inverse operation; promotes a workflow to a skill instead of retiring one.
