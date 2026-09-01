---
name: setup-memory
autonomy: act
agents: []
when: "set up memory", "install cavemem", "install mempalace", "remember across sessions", "wire up context7"
---

## Goal

Ava keeps useful context across sessions instead of re-deriving the project
every time, and can reach current library documentation instead of relying on
training data.

Two different problems, two different tools. Do not conflate them:

- **Persistent memory** — what happened on *this* project. cavemem or MemPalace.
- **Current docs** — how a *library* works today. Context7.

## Before installing anything

**Verify the tool still exists and check its README for the current install
command.** Do not run an install command from this file without checking — MCP
servers move fast, and a stale command either fails loudly or, worse, installs
something unexpected. This queue gives you the right repo and the right
questions, not a guaranteed-current incantation.

## Option A — cavemem

Cross-agent persistent memory for coding assistants: captures observations from
sessions, stores them in a local SQLite + vector index, exposes them over MCP.
Local by default, no network calls. Has installers for several coding agents.

**<https://github.com/JuliusBrussee/cavemem>**

⚠️ **The repository is marked "Frozen".** It works, but is not being actively
developed. Say this to the user before installing — an unmaintained dependency
in your memory layer is a real, if slow, risk. If they want something actively
maintained, MemPalace is the alternative.

Fit: strongest when several different coding agents work the same repo and
should share one memory.

## Option B — MemPalace

Local-first structured memory: a hierarchical virtual filesystem for memories,
documents and conversations rather than flat vector search, exposed as MCP
tools. Free and open source, runs fully locally, and is designed for a small
startup token cost.

**<https://www.pulsemcp.com/servers/bunkerlab-net-mempalace>**

Fit: strongest when you want memory organised and browsable rather than
retrieved by similarity alone.

## Context7 — current library docs

Separate concern, worth adding regardless of which memory provider is chosen.
Context7 serves up-to-date, version-specific documentation for libraries into
the agent's context, which is the standard fix for confidently-wrong answers
about a library that changed after the model's cutoff.

Install as an MCP server; verify the current command from its own docs.

## Steps

1. **Ask which provider**, presenting the trade-off honestly — including that
   cavemem is frozen. If the user has no opinion, recommend MemPalace for a new
   setup on maintenance grounds alone, and say that is the reason.
2. Fetch the project's README and follow **its** install steps.
3. Install Context7 as well unless declined.
4. Record the choice in `.claude/ava.config.json` under `memory.provider`.
5. **Verify it works before declaring success**: write one memory, start a
   fresh retrieval, read it back. An unverified memory layer is worse than none
   — it invites reliance on something that may be silently empty.
6. Seed it with the project's shape: repo, branch flow, deploy targets, the
   contents of `AVA-NOTES.md`. Keep seeds short and factual.

## What to store, and what not to

**Store:** decisions and their reasoning, failures and their root causes,
project conventions not derivable from the code, who owns what.

**Do not store:** anything the repo already records (code structure, git
history, file layout) — that is retrievable and goes stale in memory. And never
store credentials, tokens, or connection strings. A local memory store is still
a file on disk, and it is the kind of file people forget to treat as sensitive.

## Stop conditions

- The tool's README contradicts this file → follow the README, and note the
  drift in the report so this queue gets updated.
- Verification fails → do not report success. Set `memory.provider` back to
  `none` and say what broke.

## Report

Which provider, whether the round-trip verification passed, what was seeded, and
whether Context7 is live.
