---
name: setup-token-discipline
autonomy: act
agents: []
when: "reduce token usage", "why is my usage so high", "cut my limits usage", "turn off unused tools", "trim context", "optimise token spend", or any `/ava install` on a machine with no Token discipline section in CLAUDE.md
---

## Goal

The user stops paying for capability they never invoke. Three separate leaks,
worth wildly different amounts — fix them in order of what the machine's own
data says, never in order of what is easiest to see.

**The failure this prevents:** a user watches their limit drain and reaches for
the visible knob — usually disabling plugins — while the actual spend is a
subagent fleet running the most expensive model against a 200k context. Tool
schemas are a per-request tax measured in single-digit thousands of tokens.
Subagents and context length are measured in millions. Fixing the small one and
declaring victory is the standard mistake.

## Principle

**Measure before cutting.** Every recommendation in this queue comes from a
number you read on *this* machine. Never disable something because it is
commonly unused — disable it because the usage data for this user says so, and
show them the number.

## Steps

### 1. Read the usage breakdown first

Ask the user to run `/usage` and paste the "What's contributing to your limits
usage?" panel, and to run `/context` for the current prompt breakdown. These are
the ground truth and neither is readable from a script.

Take the headline characteristics seriously and in order — subagent-heavy
sessions and high-context sessions routinely dominate, and the per-subagent
attribution names the specific agent to fix.

### 2. Measure what the tool surface actually costs

Do not estimate this. Claude Code reports it:

```bash
claude plugin list                      # installed, with effective enabled/disabled per cwd
claude plugin details <name>            # component inventory + projected token cost
```

`details` splits the cost the way it actually behaves: **always-on** tokens are
paid on every request of every session, **on-invoke** tokens only when that skill
or agent fires. Optimise the always-on column. A plugin with a huge on-invoke
cost and a small always-on cost is not a problem — it is a tool you are not
paying for until you use it.

Two things this reveals that estimating gets wrong:

- **MCP tool schemas are resolved at runtime and cost ~0 always-on.** A plugin
  exposing a hundred MCP tools can be nearly free to keep installed. Never
  disable an MCP-heavy plugin for token reasons without checking `details`
  first — count skills, not tools.
- **Hooks are harness-only and cost nothing in model context.** A plugin whose
  entire contribution is hooks is not a token problem at any usage count.

Then confirm what is actually unused, reading `pluginUsage` and `skillUsage`
from `~/.claude.json` — usage count against `numStartups`, plus the last-used
date. A plugin with zero uses across dozens of startups is dead weight.

Check `skillUsage` before concluding so: a plugin-provided skill and a built-in
skill can share a name, and the built-in is usually the one being invoked.
Disabling the plugin in that case removes something the user never called and
changes nothing they will notice — but reporting it as "your unused plugin" when
they invoke that name daily destroys trust in the whole sweep.

### 2b. Prefer scoping over disabling

Most heavy plugins are not unused — they are *project-specific*. A deploy plugin
earns its keep in the repo that deploys and costs always-on tokens in every
other session on the machine. The fix is scope, not removal:

```bash
claude plugin disable <name> --scope user       # stop paying for it everywhere
cd <project-that-needs-it>
claude plugin enable  <name> --scope project    # pay for it only here
```

**Order matters, and getting it wrong looks like success.** `enable --scope
project` reports `already_in_goal_state` and writes nothing while user scope
still enables the plugin — the CLI reports *effective* state, not the per-scope
declaration. So: disable at user scope first, then enable at project scope, then
verify with `claude plugin list` from both a needing and a non-needing directory.
Project scope overrides user scope.

Check whether `.claude/settings.json` is git-tracked before using `--scope
project` in a shared repo; if it is, that enable ships to teammates. Use
`--scope local` when the choice should stay on this machine.

Detect which projects genuinely need a plugin from the repo itself rather than
asking — a deploy config file, a driver in the dependency manifest, references
to the service in source — and say what you found.

### 3. Find the heaviest tool output

```bash
python3 - <<'PY'
import json, glob, collections, os
res, calls = collections.Counter(), collections.Counter()
root = os.path.expanduser('~/.claude/projects')
files = sorted(glob.glob(f'{root}/*/*.jsonl'), key=os.path.getsize, reverse=True)[:12]
for p in files:
    ids = {}
    for line in open(p, errors='ignore'):
        try: r = json.loads(line)
        except Exception: continue
        c = r.get('message', {}).get('content')
        if not isinstance(c, list): continue
        for b in c:
            if b.get('type') == 'tool_use':
                ids[b.get('id')] = b.get('name'); calls[b.get('name')] += 1
            elif b.get('type') == 'tool_result':
                res[ids.get(b.get('tool_use_id'), '?')] += len(json.dumps(b.get('content', '')))
print(f"{'tool':42s}{'calls':>7s}{'MB':>8s}{'avg KB':>9s}")
for n, v in res.most_common(10):
    print(f"{n:42s}{calls[n]:7d}{v/1e6:8.2f}{v/max(calls[n],1)/1000:9.1f}")
PY
```

Rank by total MB, then look at avg KB per call. A tool with a high average is a
habit worth changing; a tool with a high total and a low average is usually
fine. Screenshot-producing browser tools are the most common top entry by a wide
margin, because every image stays in context for the rest of the session.

### 4. Install a cheap recon subagent

If `/usage` attributes real spend to `general-purpose`, the fix is a cheaper
agent that handles the mechanical half of what it is being asked to do. Write
`~/.claude/agents/scout.md` with `model: haiku`, read-only tools, a description
that claims *locating* work explicitly, and instructions to return conclusions
and `path:line` references rather than file contents.

Do not silently repoint existing agents at a cheaper model — a subagent that
was chosen for judgement will quietly get worse at it. Add the cheap agent, and
change the routing rule instead.

### 5. Write the rules where they are read every session

Append a **Token discipline** section to the user's global `CLAUDE.md`, and
mirror it to `AGENTS.md` if one exists beside it. Order the rules by what the
measurements in steps 1–3 actually showed, and quote those numbers in the
section so a future reader knows the rules were derived rather than guessed.

Keep it under ~40 lines. **This file is re-sent on every single request**, so a
long treatise on saving tokens costs more than it saves. If the section grows
past that, cut the weakest rule rather than appending.

### 6. Hand back what only the user can do

Connectors authorised on claude.ai (Slack, Drive, Notion, Buffer and the rest)
are toggled in the user's account settings, not in any local file — and every
unauthenticated one still contributes tool names for no capability. List the
ones that appear unused and let the user disable them; do not attempt it.

Same for session hygiene: `/clear` on task switch, `/compact` at a task
boundary, and not running more parallel sessions than the work needs.

## Stop conditions

- The user has not run `/usage` and declines to → do steps 2 and 3 only, and
  say explicitly that the subagent and context findings are unmeasured.
- A plugin looks unused but provides a skill the user invokes by a bare name →
  do not disable it; report the ambiguity and let them decide.
- Disabling anything the user has actively used in the last few sessions → ask
  first, whatever the usage count says.
- Global settings edits are blocked by the permission classifier → report the
  exact change needed and let the user apply it. Never work around the denial.

## Report

Per leak: what it was costing, what changed, and what remains for the user to
do by hand. Include the before/after from `/context`, and name anything you
deliberately left alone and why.
