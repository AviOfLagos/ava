#!/usr/bin/env bash
# Ava vendored installer — copies Ava into a target repo's .claude/.
#
# Usage:  ./scripts/install.sh /path/to/target-repo
#
# Prefer the plugin install (see INSTALL.md) unless you specifically want Ava's
# version pinned in the repo, or you are using an agent other than Claude Code.
#
# Does NOT onboard. After running this, restart your agent session and run
# `/ava install` so onboarding can detect the project and write its config.

set -euo pipefail

TARGET="${1:-}"
[ -n "$TARGET" ] || { echo "usage: $0 /path/to/target-repo" >&2; exit 1; }
[ -d "$TARGET/.git" ] || { echo "error: $TARGET is not a git repository" >&2; exit 1; }

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$TARGET/.claude"

# Skill and agents go where the agent discovers them. Everything else lives
# under .claude/ava/ — a self-contained install root, so `ava-home` can find it
# and so shipped queues never share a directory with the project's own.
mkdir -p "$DEST/skills" "$DEST/agents" "$DEST/ava" "$DEST/queues"
cp -R "$SRC/skills/ava"   "$DEST/skills/"
cp    "$SRC/agents/"*.md  "$DEST/agents/"
rm -rf "$DEST/ava/queues" "$DEST/ava/templates" "$DEST/ava/bin"
cp -R "$SRC/queues"       "$DEST/ava/queues"
cp -R "$SRC/templates"    "$DEST/ava/templates"
cp -R "$SRC/bin"          "$DEST/ava/bin"
chmod +x "$DEST/ava/bin/ava-home"

echo "✓ installed Ava into $DEST/ (skill, 6 agents, queues, templates, ava-home)"

# .claude/queues/ is the project's own — queues you write with `/ava update
# queues`. The installer creates it and then never touches it again, so an
# update cannot clobber a queue you wrote.
if [ -z "$(ls -A "$DEST/queues" 2>/dev/null)" ]; then
  cat > "$DEST/queues/README.md" <<'INNER'
# Project queues

Queues this repo added, via `/ava update queues`. Ava reads these alongside the
ones shipped in `.claude/ava/queues/`, and a file here with the same name as a
shipped one replaces it.

Safe to edit and commit. `scripts/install.sh` never writes to this directory,
so an Ava update cannot overwrite anything here.
INNER
fi

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
      !.claude/ava/
      !.claude/ava/**
      !.claude/ava.config.json
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
