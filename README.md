# Ava

**One command that runs a software project.**

Ava sizes up a repo — issues, PRs, CI, branch divergence, deploy state, chat —
decides what actually needs doing, and dispatches sub-agents to do it. You type
`/ava` and plain English. There are no flags to memorise.

```
/ava                                  assess, then decide
/ava check messages and fix issues    two queues, in parallel
/ava can we ship to prod              the gated release check
/ava update queues                    teach Ava a new recurring job
/ava upgrade                          Ava improves its own agents and queues
```

Project-agnostic. Every project-specific fact — branch names, channels,
approvers, deploy targets — lives in `.claude/ava.config.json`, written for you
by onboarding. Your integration branch can be `qa`, `develop`, `staging` or
anything else.

## Install

```
/plugin marketplace add AviOfLagos/ava
/plugin install ava@ava
```

Restart the session, then run `/ava install` once per project. Ava is installed
on your machine and onboarded per repo: onboarding writes
`.claude/ava.config.json`, and committing that file is what makes a teammate's
Ava agree with yours.

Want Ava's version pinned inside a single repo, or using an agent other than
Claude Code? There is a vendored install too. Both are in
[INSTALL.md](INSTALL.md).

## What it does

**Ten queues** — named playbooks Ava dispatches:

| Queue | Does |
| ----- | ---- |
| `onboard` | Maps the project, wires integrations, writes config |
| `triage-issues` | Ranks open issues by real user impact; fixes scoped ones |
| `review-prs` | Reviews diffs, diagnoses stalls, replies to threads |
| `ci-recovery` | Tells a real failure from an infrastructure outage, then fixes |
| `watch-slack` | Incremental chat sweep; silent when nothing is new |
| `inbound-comms` | Customer email → issue + drafted reply |
| `feature-legal` | Does the feature work, and is it disclosed |
| `setup-ci-monitoring` | Installs CI + notification workflows |
| `setup-memory` | Wires persistent memory across sessions |
| `promote-to-production` | Release, **gated** on a named approver's confirmation |

**Six sub-agents** run the work concurrently in the background, so you can walk
away and read one consolidated report later.

Add your own queue with `/ava update queues` — it becomes a file, committed, so
your teammates and their agents get it too.

## The ideas that make it useful

Most of this tool is not automation. It is judgement encoded from failures that
actually happened on real projects.

**Rank by blast radius, not by label.** A label is a claim. Silent data loss
beats a loud cosmetic bug.

**Absence of a check is not a pass.** When CI is down, "no failing checks" means
unverified. Reading it as green is how broken code ships.

**`git log` never proves deployment.** Code being in a branch and code being
live are different facts. A health endpoint returning 200 proves the app
responds, not which commit it serves. One team believed security fixes were live
for a week on exactly this mistake.

**Separate "this PR has a problem" from "the infrastructure has a problem."**
They look identical in a checks list. Only one is worth debugging.

**Gates are checkable facts, never judgement calls.** The release gate requires a
quotable approval from a specific person, recent, about the current tree, not
retracted. No quote, no gate.

**Stop conditions matter as much as steps.** A queue that only knows how to push
forward is how an agent does damage confidently.

**Never bake transient state into instructions.** "CI is currently down" goes
stale and then actively misleads. Write the recognisable signature of a
condition and check it at runtime.

## Safety

Three autonomy tiers. **auto** is read-only. **act** may create branches, PRs,
issues and comments. **gated** requires explicit conditions to pass.

Bound into every agent, regardless of tier:

- Never push directly to a protected branch
- Never mutate the production schema
- Never change production credentials unprompted
- Never add a sub-hourly CI cron (per-run billing has taken out entire pipelines,
  including backups, with no warning)
- Never invent policy in a customer reply
- Report skipped as skipped, and a hypothesis as a hypothesis

Production promotion defaults to reporting GO/NO-GO for a human to execute.
Autonomous merge exists behind a config flag, off by default.

## Requirements

`git`, `gh` authenticated, a repo with a remote. Slack, a deploy CLI, and a
memory provider are optional and degrade gracefully.

## License

MIT
