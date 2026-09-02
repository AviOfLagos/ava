# Roadmap

Written for a fresh session. Each item states what to do and how to know it
worked. Ordered — the first two gate real-world confidence in everything else.

---

## 1. Test onboarding on a second, unrelated project (highest value)

**Nothing here has been run against a project other than the one it came from.**
Onboarding is written from a single example, which is the classic way to encode
accidental assumptions as universal ones.

Pick a project deliberately unlike the origin: different language, different
branch names (`develop` not `qa`), no Slack, maybe no deploy provider.

Watch for:
- Does detection cope with a non-Node package manager?
- Does a two-branch flow (`main` + `develop`) work, or does it assume three?
- Does it degrade cleanly with Slack absent, or stall?
- Does `/ava status` describe the project back accurately?

Fix what breaks, then record what was assumed in `docs/BRIEF.md`.

## 2. Verify the memory install path end to end

`queues/setup-memory.md` deliberately tells the agent to follow each provider's
own README rather than hardcoding a command that may already be stale. That is
correct but untested.

Install cavemem and MemPalace on a scratch project, confirm the round-trip
(write a memory, fresh session, read it back), and record the actual working
commands as a dated appendix — noting they may drift.

Also confirm cavemem's "Frozen" status still holds. If it is archived outright,
demote it to a footnote and make MemPalace the default.

## 3. Publish as an installable plugin — **done**

`.claude-plugin/marketplace.json` and `plugin.json` ship in this repo, so
`/plugin marketplace add AviOfLagos/ava` + `/plugin install ava@ava` installs
Ava once for every project. The vendored path is kept and documented.

One thing a skill cannot do: `${CLAUDE_PLUGIN_ROOT}` is exported to hook
commands only and is empty in a normal shell, so the skill cannot use it to find
its own queues and templates. `bin/ava-home` resolves its own location instead,
and is on PATH automatically for plugin installs.

One trap worth writing down: **do not add an `agents` key to `plugin.json`.**
Agents are auto-discovered from `agents/`, and declaring the key — as a
directory, or as an explicit list of files — silently registers zero of them.
`claude plugin validate --strict` passes either way, so the only thing that
catches it is `claude plugin details ava` after an install, which reads a
snapshot taken at install time and therefore has to be re-checked after a
reinstall, not after an edit.

What is left is release discipline, not plumbing:

- Bump `version` in **both** manifests together — `claude plugin tag` refuses if
  they disagree — and tag `ava--v<version>` on release.
- Nobody has yet installed this on a machine that has never had Ava vendored.
  Test that path before telling anyone else to use it.

## 4. `/ava upgrade` needs a real test

The self-modification path is specified but unexercised. Give it a concrete
task — "make the slack watcher report thread replies separately" — and check it
branches, PRs, and does **not** quietly weaken a gate to make its work pass.
That last part is the actual risk.

## 5. External dead-man's-switch for scheduled jobs

`setup-ci-monitoring` documents the blind spot — a failure alert implemented as
a step inside a job cannot fire when the job never starts — but does not solve
it. Ship a template using a free external cron/uptime service that alerts on the
*absence* of a success ping.

This is not theoretical: it is how seven consecutive nightly backup failures
produced zero alerts on the origin project.

## 6. Support non-GitHub forges

Every queue shells out to `gh`. GitLab and Bitbucket users cannot use this.
Abstract the forge calls behind a thin layer, or state the limitation plainly in
the README. Right now it is implied rather than said.

## 7. Cost controls

Six agents in parallel on a large repo is a lot of tokens. Add a config budget —
max concurrent agents, max per run — and make Ava report what a sweep cost so
the user can calibrate.

## 8. Per-queue metrics

Ava cannot currently answer "is this working?" Track, in state: queues run,
issues filed, PRs opened, how many were merged versus closed unmerged. A queue
whose PRs are always rejected is worse than no queue, and today nothing would
reveal that.

---

## Known limitations, stated plainly

- **Untested outside its origin project.** Item 1 exists for this reason.
- **GitHub-only.**
- **Slack-only** for chat. No Discord, Teams, or Linear.
- **The onboarding Slack flow cannot invite people** to a channel — it names who
  is missing and asks a human. That is a platform permission boundary, not an
  oversight.
- **Sub-agent registration requires a session restart.** Documented in INSTALL,
  and still the most likely first-run confusion.
