---
name: setup-toolchain
autonomy: gated
agents: []
when: "set up my tools", "what skills should I install", "install the skills for this project", "scan this repo", "set up snare", or as the closing step of `onboard`
---

## Goal

The agent working this project has the skills, documentation access and memory
that this *particular* project needs — chosen from what is actually in the repo,
approved in one pass, installed without further questions.

Ends with `.claude/ava-setup-plan.md` written, confirmed and executed, and a
report of what landed and what did not.

Run by the orchestrator directly. It asks a question and then installs things;
neither belongs in a sub-agent.

## Principle

**Detect, propose, confirm once, execute.** The user should read one file and
say one word. Every extra prompt is a tax on a tool whose whole promise is one
command.

And the inverse of the same principle: **do not hand back work you could do.**
See §"Doing the work yourself" in `SKILL.md`. If a step needs a web dashboard,
open it and drive it; stop only at a declared handoff.

## Gates

The plan file is the authorisation. Each of these is a checkable fact:

1. `.claude/ava-setup-plan.md` exists and was written by this run.
2. The user has replied with an unambiguous confirmation *after* the file was
   written. Not "sounds good" to an earlier message — a confirmation of this
   plan, in this session.
3. Every item about to be executed appears in section 1 of the file as it
   currently stands on disk. Re-read it after confirmation; the user may have
   edited it.

Any gate unmet or ambiguous ⇒ stop and report. Never install something that is
not in the file.

## Steps

### 1. Scan the repository before anything else

**snare** — <https://github.com/AviOfLagos/snare> — finds supply-chain droppers
committed directly into a repo: a payload hidden in `.vscode/tasks.json` behind
`"runOn": "folderOpen"`, or appended after thousands of spaces in a build
config. There is no malicious dependency, so `npm audit`, the lockfile and
Dependabot are all clean.

This runs **first**, and the ordering is not cosmetic. The triggers are opening
the folder in an editor and running a build — the next two things anyone does on
a freshly cloned repo. Installing skills and MCP servers onto a machine with a
live dropper on it compromises everything installed afterwards.

Propose it, and if the user is already running it, say so and move on. Follow
its own README for the current install command.

### 2. Read what kind of project this is

Reuse what `onboard` step 1 already found — do not re-derive it. Manifests,
framework, directory shape, CI config, deploy target, and whether anything here
is user-facing.

### 3. Search for skills that match, do not recall them

Map signals to *categories*, then search the available skills and MCP servers
for each category. Do not hardcode a catalogue in this file: registries move,
and a baked-in list rots exactly the way a baked-in install command does.

| Signal in the repo | Category worth searching for |
| --- | --- |
| React/Vue/Svelte, `app/`, `components/` | frontend practice, design systems |
| Public pages, sitemap, metadata, marketing copy | SEO |
| Charts, notebooks, `pandas`, `d3`, dashboards | data visualisation |
| `pyproject.toml`, Django, FastAPI | Python backend practice |
| Any project with dependencies | current library docs — Context7 |
| Any project at all | persistent memory — see `setup-memory.md` |

**Every proposal needs a reason tied to something detected.** "You have
`recharts` in package.json and twelve chart components" is a reason. "Great for
frontend projects" is a pitch, and a pitch in this list is how the file becomes
noise the user stops reading.

Propose few. A list of four things a user reads is worth more than a list of
fifteen they skim.

### 4. Treat installing a skill as the supply-chain event it is

Auto-installing third-party skills is the same class of risk snare exists to
catch, arriving through a different door.

- Record **who publishes** each item and **where it comes from**, in the plan,
  before install rather than after.
- Prefer first-party and well-known publishers. Anything else is proposed as
  **unvetted** in as many words, or not proposed.
- **Verify each tool still exists and follow its own README** for the install
  command. Do not run a command from this file without checking it first.

### 5. Write the plan

```bash
cp "$(ava-home)/templates/ava-setup-plan.md" .claude/ava-setup-plan.md
```

Fill in all three sections. Section 2 — the handoffs — is the one that earns
trust: name every secret to paste, every terms page to accept, every CAPTCHA,
before the user agrees to anything, so they know the total cost up front.

Add `.claude/ava-setup-plan.md` to `.gitignore`. It records what one person
approved on one machine; in a teammate's checkout it is actively misleading.

### 6. Ask once

> I've written `.claude/ava-setup-plan.md`. Edit anything you disagree with —
> deleting a line means don't do it — then reply `go`.

Then stop. Do not narrate the plan back; the file is the artifact.

### 7. Execute

Re-read the file from disk first: the user may have edited it, and the edited
version is the contract.

Work top to bottom. Report as you go rather than asking as you go. At each
handoff, stop, say precisely what is needed, and wait.

A failed item is recorded and execution continues. Partial beats none, and the
report names what failed.

### 8. Record

Write the outcome back into the plan file — installed, failed, skipped — so a
second run can diff against it and propose only what changed. Record the memory
provider in `.claude/ava.config.json` under `memory.provider` as
`setup-memory.md` requires.

## Stop conditions

- No confirmation, or an ambiguous one → stop. Install nothing.
- The user edited the file into something you do not understand → ask about that
  line specifically rather than guessing or skipping silently.
- snare reports a finding → **stop the whole queue** and surface it. Do not
  install anything onto a machine with an unresolved detection; finish the
  incident first.
- A skill cannot be attributed to a publisher → do not install it, and say why.

## Report

**Installed** — one line each, with the reason it was chosen.

**Handed to you** — the declared handoffs that are still outstanding, each with
the single action that closes it.

**Failed** — what broke and the one command that retries it.

**Skipped** — one compressed line; the detail lives in the plan file.
