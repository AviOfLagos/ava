---
name: setup
autonomy: act
agents: []
when: "/ava:setup", "/ava setup", "check my setup", "is everything configured", "what's missing", "set ava up properly", "audit my config"
---

## Goal

One sweep that answers "is this machine and this project actually set up, or
have I been running on defaults?" — then closes every gap it is safe to close
without asking, and hands back a short list of the ones that need a human.

**The failure this prevents:** setup rot. Each `setup-*` queue works fine when
someone remembers to run it, and nobody does. Ava ends up half-configured on a
machine — no memory, no cost rules, commits under the wrong identity — and
nothing surfaces it, because every individual piece degrades silently. A single
periodic sweep is the only thing that catches a gap nobody was looking for.

## The pattern

Every area below follows the same three beats, and any new area added to this
queue must follow them too:

1. **Check** — one cheap command whose output is unambiguous. If you cannot
   check it in a command, it does not belong here; ask the user directly and
   mark it unverified.
2. **Fix, if purely additive** — apply it and say so in one line. Additive means
   it *adds* a file, a rule, or a default and removes no capability: writing a
   missing config, appending a rules section, installing a read-only agent.
3. **Hand back, if not** — anything that disables, deletes, rewrites history, or
   spends money is reported with the exact change needed, and waits.

Never invert beats 2 and 3 because the fix looks small. "Small" and "reversible"
are different properties, and only the second one matters here.

## Steps

### 1. Project onboarding

```bash
cat .claude/ava.config.json 2>/dev/null | head -5 || echo MISSING
```

Missing ⇒ this project was never onboarded. Stop the sweep and run `onboard`
instead; everything below assumes a known project, and guessing branch names is
how work lands in the wrong place.

### 2. Token discipline

```bash
grep -ql 'Token discipline' ~/.claude/CLAUDE.md 2>/dev/null && echo rules-present || echo rules-absent
ls ~/.claude/agents/scout.md >/dev/null 2>&1 && echo scout-present || echo scout-absent
```

Absent ⇒ additive, so fix it: install the cheap `scout` recon agent and append
the Token discipline section to global `CLAUDE.md` (mirroring to `AGENTS.md` if
one sits beside it), per `setup-token-discipline` steps 4 and 5. Measure first
where you can, so the numbers are this machine's own.

Present ⇒ say so and move on. Do not re-append; a duplicated rules section
costs tokens on every request, which is precisely the thing it exists to stop.

While here, report the always-on cost of what is loaded:

```bash
claude plugin list
claude plugin details <name>   # always-on vs on-invoke tokens
```

Always-on tokens are paid on every request of every session. A plugin that is
heavy and project-specific should be *scoped*, not removed — see
`setup-token-discipline` §2b. Report the opportunity here; do not act on it.

Trimming or rescoping plugins and connectors is **not** part of this sweep — it
removes capability from somewhere. Offer `setup-token-discipline` for that.

### 3. Commit identity

```bash
git remote get-url origin 2>/dev/null
git config user.email
gh auth status 2>&1 | grep -i 'account' | head -3
```

The active identity must match the account that should own commits on **this**
remote. A mismatch is worth stopping for: it is invisible until the commits are
already pushed and attributed to the wrong person, and rewriting published
history to fix it is far more expensive than the check.

If the machine documents its own account-switching procedure (commonly in
`CLAUDE.md` or `AGENTS.md`), follow that rather than improvising one. If it does
not and there are multiple accounts, report the mismatch and let the user pick —
never guess which identity they intended.

### 4. Persistent memory

```bash
python3 -c "import json,os;d=json.load(open(os.path.expanduser('~/.claude.json')));print(list(d.get('mcpServers',{}).keys()) or 'none global')" 2>/dev/null
```

Absent ⇒ **not** additive in the sense that matters: it installs a third-party
MCP server and makes a durable choice about where project context lives. Offer
`setup-memory`, do not run it.

### 5. CI monitoring

```bash
ls .github/workflows/ 2>/dev/null || echo 'no workflows'
gh run list --limit 3 --json conclusion,workflowName 2>/dev/null
```

No workflows, or none that notify on failure ⇒ offer `setup-ci-monitoring`.
Modifying CI changes what happens on every future push, so it waits for a yes.

Workflows present but every recent run is failing or skipped ⇒ that is not a
setup gap, it is a live problem. Name it and point at `ci-recovery`.

### 6. Landmines file

```bash
ls AVA-NOTES.md 2>/dev/null || echo MISSING
```

Missing ⇒ additive. Create it with a one-line header. An empty landmines file
invites the habit of writing failures down; an absent one guarantees they are
re-learned.

### 7. Permission friction

If the session has been prompting repeatedly for the same read-only commands,
that is friction, not safety — each prompt costs a round trip and trains the
user to approve without reading. Mention the `fewer-permission-prompts` skill
where it exists. Never widen an allowlist unasked: permissions are the one area
where the additive change is also the dangerous one.

## Stop conditions

- No `.claude/ava.config.json` → run `onboard`, not this.
- Commit identity mismatch → stop and surface it before any commit happens.
- A check command is unavailable (`gh` absent, not a git repo) → report that
  area as unverified. Never infer a pass from a missing tool.
- Any global config write is blocked by the permission classifier → report the
  exact change and let the user apply it. Do not work around the denial.

## Report

A short table: area, state (`ok` / `fixed` / `needs you` / `unverified`), and
one line of detail. Then the follow-on queues worth running, in impact order.

Keep it to what changed and what is outstanding. A sweep that reports six
green rows at length is a sweep nobody will run twice.
