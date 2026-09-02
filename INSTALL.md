# Installing Ava

Ava installs two ways. Pick one.

| | **Plugin** | **Vendored** |
| --- | --- | --- |
| Where it lives | Once on your machine | Committed into one repo |
| Available in | Every project you open | That repo |
| Updates | `/plugin update ava` | Re-run the installer |
| Teammates get it | By installing it themselves | With their next `git pull` |
| Works with | Claude Code | Any agent that reads Markdown skills |

**Install it as a plugin unless you have a reason not to.** Ava is a tool you
use *on* projects, not a part of any one of them — you want it wherever you are.
The vendored path exists for teams who want Ava's version pinned in the repo, or
for agents other than Claude Code.

Either way, **each project is onboarded separately**. Ava's judgement is
portable; the branch names and channels are not.

---

## Plugin install

```
/plugin marketplace add AviOfLagos/ava
/plugin install ava@ava
```

Restart the session, then in each project you want Ava to run:

```
/ava install
```

That is the whole thing. `/ava install` runs the `onboard` queue, which maps the
repo, detects the branch flow and deploy target, wires Slack, and writes
`.claude/ava.config.json`. Commit that file — it is what makes your teammates'
Ava agree with yours.

Outside an interactive session the same two steps are:

```bash
claude plugin marketplace add AviOfLagos/ava
claude plugin install ava@ava
```

### What lands where

Nothing is copied into your repo except its own config:

| Path | What |
| ---- | ---- |
| *(plugin install root)* | The skill, six agents, ten queues, templates, `bin/ava-home` |
| `.claude/ava.config.json` | **Per project.** Written by onboarding, committed |
| `.claude/ava-state.json` | **Per project.** Gitignored — chat cursors, dedupe lists |
| `.claude/queues/*.md` | **Per project, optional.** Queues this repo added |
| `AVA-NOTES.md` | **Per project.** Traps Ava learns here |

`ava-home` prints the install root; `ava-home queues` prints the queue registry
Ava will actually read, project overrides first.

---

## Vendored install

For pinning Ava in a repo, or for agents other than Claude Code.

```bash
git clone --depth 1 https://github.com/AviOfLagos/ava.git /tmp/ava-install
/tmp/ava-install/scripts/install.sh .
rm -rf /tmp/ava-install
```

This copies the skill, agents, queues, templates and `bin/ava-home` into
`.claude/`. For a non-Claude-Code agent, put them wherever that agent discovers
skills and sub-agents — the content is plain Markdown with YAML frontmatter and
carries no Claude-specific syntax, so only the *location* changes.

Then restart the session and run `/ava install`.

### Make it survive a clone

Many repos ignore `.claude/` wholesale, which means none of this reaches your
teammates. Add narrow negations rather than un-ignoring everything:

```gitignore
.claude/
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
```

Verify with `git add -An .claude` before committing. Exactly the definition
files and the config should be listed, and nothing else.

---

## Restart. Really.

**Skills, agents and plugins are discovered at session start.** Files added
mid-session do not register, and neither does a freshly installed plugin.

This step is skipped constantly and produces a confusing "the skill doesn't
work". It is almost always this. Restart, then confirm `/ava` appears.

---

## Verify before reporting success

```bash
ava-home && ava-home queues        # plugin install: root, then 10+ queue paths
test -f .claude/ava.config.json && echo "config written"
```

`ava-home: command not found` means either the plugin is installed but the
session was not restarted, or the install did not take. On a vendored install,
run `.claude/ava/bin/ava-home` instead.

Then run `/ava status`. It should describe the project back to you accurately.
**If it names the wrong branch or repo, onboarding was wrong — fix the config
before using anything else.** Everything downstream trusts that file.

---

## Requirements

**Required:** `git`, `gh` (authenticated), a repo with a remote.

**Optional but recommended:** Slack tools available to the agent (channel
watching, inbound triage, release approval); a deploy CLI such as `vercel`; a
memory MCP provider (see `queues/setup-memory.md`).

Everything optional degrades gracefully. Without Slack you lose approval-gated
promotion and inbound triage; issues, PRs and CI all still work.

---

## Updating

```
/plugin update ava
```

Restart to apply. Your queues are safe: an update replaces the shipped
playbooks only, and anything under a project's `.claude/queues/` overrides a
shipped file of the same name rather than being overwritten by it. Project
config is never touched.

Vendored installs re-run `scripts/install.sh`, which **does** overwrite the
shipped queues in place. Commit first so the diff is reviewable.

---

## Uninstalling

```
/plugin uninstall ava
```

Per project, if you want the traces gone too:

```bash
rm -f .claude/ava.config.json .claude/ava-state.json
```

Leave `.claude/queues/` alone unless you mean it — those are queues you wrote,
not Ava's.

Vendored: `rm -rf .claude/ava .claude/skills/ava .claude/agents/ava-*.md` and
revert the `.gitignore` negations.

`AVA-NOTES.md` is worth keeping either way — it is your project's accumulated
hard-won knowledge, not Ava's.
