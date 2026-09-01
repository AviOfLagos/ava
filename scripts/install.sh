#!/usr/bin/env bash
# Ava installer — copies the skill, agents and queues into a target repo.
#
# Usage:  ./scripts/install.sh /path/to/target-repo
#
# Does NOT onboard. After running this, restart your agent session and run
# `/ava install` so onboarding can detect the project and write its config.

set -euo pipefail

TARGET="${1:-}"
[ -n "$TARGET" ] || { echo "usage: $0 /path/to/target-repo" >&2; exit 1; }
[ -d "$TARGET/.git" ] || { echo "error: $TARGET is not a git repository" >&2; exit 1; }

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$TARGET/.claude/skills" "$TARGET/.claude/agents" "$TARGET/.claude/queues"
cp -R "$SRC/skills/ava"   "$TARGET/.claude/skills/"
cp    "$SRC/agents/"*.md  "$TARGET/.claude/agents/"
cp    "$SRC/queues/"*.md  "$TARGET/.claude/queues/"
cp -R "$SRC/templates"    "$TARGET/.claude/ava-templates"

echo "✓ copied skill, 6 agents, queues and templates into $TARGET/.claude/"

# Many repos ignore .claude wholesale. Warn rather than silently editing
# someone's .gitignore — that file is theirs.
if [ -f "$TARGET/.gitignore" ] && grep -qE '^\.claude/?$' "$TARGET/.gitignore"; then
  cat <<'WARN'

⚠️  .gitignore ignores .claude/ wholesale, so none of this will be committed
    and teammates will not get it. Add narrow negations:

      !.claude/
      !.claude/skills/
      !.claude/skills/**
      !.claude/agents/
      !.claude/agents/**
      !.claude/queues/
      !.claude/queues/**
      .claude/ava-state.json
      .claude/settings.local.json

    Then check with:  git add -An .claude
WARN
fi

cat <<'NEXT'

Next:
  1. RESTART your agent session — skills are discovered at startup, so /ava
     will not exist until you do.
  2. Run:  /ava install
  3. Then: /ava
NEXT
