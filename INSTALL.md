# Installing Ava

Two audiences. Pick the one that applies.

---

## For a coding agent

If a human told you *"install the Ava skill"*, this section is your instruction
set. Follow it top to bottom.

### 1. Fetch and copy

From the root of the target repository:

```bash
git clone --depth 1 https://github.com/AviOfLagos/ava.git /tmp/ava-install

mkdir -p .claude/skills .claude/agents .claude/queues
cp -R /tmp/ava-install/skills/ava      .claude/skills/
cp    /tmp/ava-install/agents/*.md     .claude/agents/
cp    /tmp/ava-install/queues/*.md     .claude/queues/
cp -R /tmp/ava-install/templates       .claude/ava-templates

rm -rf /tmp/ava-install
```

For an agent other than Claude Code, place the files wherever that agent
discovers skills and sub-agents. The content is plain Markdown with YAML
frontmatter and carries no Claude-specific syntax — only the *location*
changes.

### 2. Make them survive a clone

Many repos ignore `.claude/` wholesale. If so, **do not un-ignore everything** —
add narrow negations so team tooling is shared while local state stays private:

```gitignore
.claude/
!.claude/
!.claude/skills/
!.claude/skills/**
!.claude/agents/
!.claude/agents/**
!.claude/queues/
!.claude/queues/**
.claude/ava-state.json
.claude/settings.local.json
```

Verify with `git add -An .claude` before committing. Exactly the definition
files should be listed and nothing else.

### 3. Restart the agent session

**Skills and sub-agents are discovered at session start.** Files added
mid-session will not register. Restart, then confirm `/ava` appears.

This step is skipped constantly and produces a confusing "the skill doesn't
work" — it is almost always this.

### 4. Onboard

Run `/ava install`. The `onboard` queue maps the repo, detects the branch flow
and deploy target, wires Slack, and writes `.claude/ava.config.json`.

It asks few questions and answers what it can by looking. Do not pre-fill the
config by hand — let onboarding detect it, then correct what it got wrong.

### 5. Verify before reporting success

```bash
test -f .claude/ava.config.json && echo "config written"
ls .claude/skills/ava/SKILL.md .claude/agents/ava-*.md .claude/queues/*.md
```

Then run `/ava status`. It should describe the project back to you accurately.
**If it names the wrong branch or repo, onboarding was wrong — fix the config
before using anything else.** Everything downstream trusts that file.

---

## For a human

```
1. Clone this repo somewhere, or point your agent at it.
2. Tell your agent: "install the Ava skill from https://github.com/AviOfLagos/ava"
3. Restart your Claude Code session.
4. Type: /ava install
5. Answer a handful of questions.
6. Type: /ava
```

Steps 3 and 4 are the ones people skip. Without the restart the command does not
exist; without onboarding Ava does not know your branches.

---

## What gets installed

| Path | What |
| ---- | ---- |
| `.claude/skills/ava/SKILL.md` | The router — intent → queues, priority ladder, hard rules |
| `.claude/agents/ava-*.md` | Six sub-agents |
| `.claude/queues/*.md` | Ten playbooks; add your own with `/ava update queues` |
| `.claude/ava-templates/` | CI workflows and the config template |
| `.claude/ava.config.json` | Written by onboarding. Project-specific facts |
| `.claude/ava-state.json` | Gitignored. Chat cursors, dedupe lists |
| `AVA-NOTES.md` | Project-specific traps Ava learns |

## Requirements

**Required:** `git`, `gh` (authenticated), a repo with a remote.

**Optional but recommended:** Slack tools available to the agent (channel
watching, inbound triage, release approval); a deploy CLI such as `vercel`;
a memory MCP provider (see `queues/setup-memory.md`).

Everything optional degrades gracefully. Without Slack you lose approval-gated
promotion and inbound triage; issues, PRs and CI all still work.

## Updating

```bash
cd /tmp && git clone --depth 1 https://github.com/AviOfLagos/ava.git ava-update
cp -R ava-update/skills/ava .claude/skills/
cp ava-update/agents/*.md .claude/agents/
cp ava-update/queues/*.md .claude/queues/
rm -rf ava-update
```

**This overwrites queues.** Any queue you wrote yourself with a name matching an
upstream one is lost. Keep custom queues under distinct names, and commit before
updating so the diff is reviewable.

`.claude/ava.config.json` is never touched by an update.

## Uninstalling

```bash
rm -rf .claude/skills/ava .claude/agents/ava-*.md .claude/queues .claude/ava-templates
rm -f .claude/ava.config.json .claude/ava-state.json
```

Then revert the `.gitignore` negations. `AVA-NOTES.md` is worth keeping — it is
your project's accumulated hard-won knowledge, not Ava's.
