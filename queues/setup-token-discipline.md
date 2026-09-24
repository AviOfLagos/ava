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

```bash
python3 - <<'PY'
import json, datetime
d = json.load(open(f"{__import__('os').path.expanduser('~')}/.claude.json"))
for k, v in sorted(d.get('pluginUsage', {}).items(), key=lambda kv: kv[1].get('usageCount', 0)):
    if '@inline' in k: continue
    ts = datetime.datetime.fromtimestamp(v.get('lastUsedAt', 0)/1000).date()
    print(f"{v.get('usageCount',0):6d}  last={ts}  {k}")
print('startups:', d.get('numStartups'))
PY
```

A plugin with zero uses across dozens of startups is dead weight, and its cost
is proportional to how many skills and MCP tools it contributes, not to its
size on disk. Check `skillUsage` in the same file before concluding a plugin is
unused — a plugin-provided skill and a built-in skill can share a name, and the
built-in is usually the one being invoked.

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
