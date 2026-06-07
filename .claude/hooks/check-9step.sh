#!/bin/bash
# PreToolUse hook for Bash tool: enforce CLAUDE.md 10-step chain.
#
# Blocks `git commit` for non-routine messages unless a plan file
# exists in docs/tasks/ (any *.md file counts as proof of task tracking).
# Routine commits (chore/docs/test/ci/Merge/Revert/fixup!) are exempt.
# Bypass: git commit --no-verify -m "..."

set -u

# Read tool input from stdin (PreToolUse passes tool_input as JSON)
INPUT="$(cat)"

# Only trigger on git commit. Use grep -E (ERE) for reliable whitespace
# match — bash's [[ =~ ]] can be flaky with character classes across versions.
if ! echo "$INPUT" | grep -qE 'git commit'; then
  echo '{}'
  exit 0
fi

# Extract commit message from -m "..." or -m '...'
MSG=""
if echo "$INPUT" | grep -qE ' -m[[:space:]]+["\x27]'; then
  MSG=$(echo "$INPUT" | sed -nE 's/.* -m[[:space:]]+["\x27]([^"\x27;]+).*/\1/p' | head -1)
fi

# Allow routine commit types (governance, docs, build chores)
case "$MSG" in
  chore*|docs*|test*|ci*|Merge*|Revert*|fixup!*)
    echo '{}'
    exit 0
    ;;
esac

# Check docs/tasks/ has any real plan file (excluding _template.md)
if [ -d docs/tasks ] && \
   [ -n "$(find docs/tasks -maxdepth 1 -name '*.md' ! -name '_template.md' -type f 2>/dev/null)" ]; then
  echo '{}'
  exit 0
fi

# Block: no plan found
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
cat >&2 <<EOF
10-step chain not satisfied: docs/tasks/ is empty.

Before coding, create docs/tasks/${BRANCH}.md (or any *.md) with
10-step checklist per CLAUDE.md:
  1. brainstorming          6. systematic-debugging
  2. writing-plans          7. /qa
  3. /autoplan              8. code-review
  4. subagent-driven-dev    9. /ship
  5. TDD                   10. /cso

Bypass for routine cases: git commit --no-verify -m "..."
EOF
echo '{"permissionDecision":"deny","message":"10-step chain not satisfied: docs/tasks/ is empty. See stderr."}'
exit 0
