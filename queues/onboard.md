---
name: onboard
autonomy: act
agents: []
when: "/ava install", "set up ava", "onboard this project", or ANY /ava run where .claude/ava.config.json is missing
---

## Goal

Go from "Ava's files are in this repo" to "Ava knows this project and every
integration it needs is either working or has a named blocker". Ends with a
written `.claude/ava.config.json` and a short report of what is live and what
is not.

Run by the orchestrator directly — no sub-agents. It asks questions, and
questions belong in the main thread.

## Principle

**Detect first, ask second.** Every question you ask that you could have
answered by looking is a question that makes this tool feel like work. Aim to
present a filled-in draft and ask only for confirmation plus the handful of
things that are genuinely unknowable.

## Steps

### 1. Map the repo (no questions yet)

```bash
git remote -v && git branch -a --format='%(refname:short)' | head -30
gh repo view --json nameWithOwner,defaultBranchRef,visibility 2>/dev/null
ls package.json pyproject.toml go.mod Cargo.toml Gemfile 2>/dev/null
ls .github/workflows/ 2>/dev/null
cat CLAUDE.md AGENTS.md README.md 2>/dev/null | head -120
```

Infer: language and package manager, test command, build command, existing CI,
and the branch topology. A repo with `main` + `develop` is a two-tier flow; one
with `main` + `qa` + feature branches is three-tier.

**Read `CLAUDE.md` / `AGENTS.md` closely if present.** Projects often already
document their branch flow, deploy rules, and landmines. Adopt what is there
rather than inventing a parallel convention.

### 2. Branch flow — confirm, don't interrogate

State what you found and ask one question:

> I see `main` (default) and `qa`. Reading it as: feature → PR → `qa` →
> promote → `main` = production. Correct?

Set `branches.integration`, `branches.production`, `branches.directPushBlocked`.

If there is only one branch, say so plainly: promotion gating has nothing to
gate, so `promote-to-production` will be inert until a second branch exists.

### 3. Deploy target

```bash
ls vercel.json netlify.toml fly.toml Dockerfile 2>/dev/null
vercel whoami 2>/dev/null && vercel project ls 2>/dev/null | head
```

Ask only what you cannot detect: the production URL, and the QA/staging URL if
one exists. Fill `environments[]`.

If the deploy CLI is not authenticated, try to fix it rather than filing it:
`vercel login` and the equivalents open a browser, and with browser tools
available you can carry that through — see **Doing the work yourself** in
`SKILL.md`, and stop at the boundaries it names. Only if that is unavailable
does this become a recorded blocker, and then say what would unblock it.

### 4. Chat — Slack

Check whether Slack tools are available to you at all. If not, set
`slack.enabled: false`, note what is needed, and move on. **Do not block
onboarding on Slack.**

If available, ask for **channel names, not IDs** — resolving them is your job:

> Which channel should I post ops updates to (CI, deploys, alerts)? And which
> for inbound customer email/feedback? Names are fine — I'll find the IDs.

Then:

1. Resolve each name to an ID via channel search.
2. **If a channel does not exist**, offer to create it, and ask public or
   private before creating — that is not your call to make. Default to the same
   visibility as the workspace's other engineering channels if the user has no
   preference.
3. After creating, **list who should be invited** and ask the user to add them.
   You generally cannot add people to a channel on someone's behalf, and should
   not try; naming who is missing is the useful part.
4. Write resolved IDs into `slack.channels.*.id`. IDs, not names — names get
   renamed and then nothing routes.

Post one test message to the ops channel to prove the wiring, and say you are
doing it so it is not mistaken for noise.

### 5. Release approver

> Production promotion is gated. Who has to approve before anything reaches
> `<production>`? I need their Slack user ID so an approval can be verified as
> genuinely theirs.

Fill `people.releaseApprovers[]`. If nobody is named, set
`release.requireApproval: false` and **say clearly** that promotion is then
ungated — that is a real reduction in safety and the user should choose it
knowingly, not by omission.

### 6. Production database identifier

> Is there a production database? Give me a substring of its host that appears
> in no other environment's connection string.

This becomes `database.productionIdentifier`, the string Ava refuses to run
schema-mutating commands against. Skip if there is no database.

### 7. Autonomy

Present the three defaults and confirm:

- `autonomy.default: "act"` — creates branches, PRs, issues; does not merge.
- `autonomy.allowSendCustomerReplies: false` — drafts replies, does not send.
- `autonomy.allowAutonomousPromotion: false` — assembles the release gate
  evidence and reports GO/NO-GO; a human executes the merge.

Raise any of these only if the user explicitly asks.

### 8. Write config and verify

```bash
mkdir -p .claude && cp "$(ava-home)/templates/ava.config.json" .claude/ava.config.json
```

Fill it in from what you detected. Then check `.gitignore`:

- `.claude/ava-state.json` **must** be ignored — per-machine cursors, nothing a
  teammate wants.
- `.claude/ava-setup-plan.md` **must** be ignored — it records what one person
  approved on one machine, and is actively misleading in someone else's
  checkout.
- `.claude/ava.config.json` **must not** be — teammates and their agents need
  the branch names, channels and approvers you just wrote.
- If `ava-home` prints a path *inside this repo*, Ava is vendored here rather
  than plugin-installed, and the same applies to the skill, agents and queues:
  team tooling, must survive a fresh clone.

If `.claude/` is ignored wholesale, add narrow negations rather than
un-ignoring everything. Verify with `git add -An .claude` before committing —
exactly the intended files should be listed and nothing else.

Create `AVA-NOTES.md` with a one-line header if absent.

### 9. Hand off to `setup-toolchain`

Do not ask a second round of yes/no questions here. Everything still
outstanding — the repo scan, skills worth installing for *this* project,
persistent memory, current library docs, CI and notification workflows — goes
into one plan the user reads once.

Run `setup-toolchain`. It writes `.claude/ava-setup-plan.md`, asks for a single
confirmation, and then executes without further prompting. `setup-memory` and
`setup-ci-monitoring` become items in that plan rather than separate things the
user has to know to ask for.

The first item it proposes is a supply-chain scan of the repo you have just
finished mapping, and that ordering is deliberate: the triggers are opening the
folder and running a build, which are the next two things anyone does.

## Stop conditions

- The repo has no git remote → stop. Ava needs a remote to be useful.
- The user does not know their branch flow → stop and ask them to confirm with
  whoever does. Guessing here is how work lands on the wrong branch.
- A credential is missing → record it as a blocker, keep going. Partial
  onboarding beats none; the report names what is missing.

## Report

Two lists, kept short:

**Working** — what is wired, one line each.

**Blocked** — each with the single concrete action that fixes it, in the form
"1. Run `X`" or "2. Give me Y". Numbered, no prose. This list is the handoff.

Then: the config path, and the one command to start using it — `/ava`.

Finally, say how a teammate gets the same setup. If `ava-home` resolves outside
the repo, the config you just committed is not enough on its own — each person
also installs Ava once, for every repo they work on:

```
/plugin marketplace add AviOfLagos/ava
/plugin install ava@ava
```
