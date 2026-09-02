---
name: setup-ci-monitoring
autonomy: act
agents: []
when: "set up CI", "add notifications", "wire slack alerts", "install monitoring", "notify me when issues close"
---

## Goal

The project has CI that runs on every PR, and the team hears about the events
that matter — without anyone watching a dashboard.

Four notification events, chosen because each one changes what a human does next:

| Event | Why it matters |
| ----- | -------------- |
| Issue opened | Someone should triage it |
| PR merged closing an issue | The work is done; verify it |
| Deployment failed | Production may be stale and nobody knows |
| CI failed on the integration branch | The shared branch is broken for everyone |

Deliberately **not** notified: every push, every green run, every comment. A
channel that fires constantly gets muted, and a muted channel is worse than no
channel — it looks like coverage while providing none.

## Before writing anything

1. Read `.github/workflows/` — do not duplicate what exists. Adding a second
   unit-test workflow is a common and annoying failure of this queue.
2. Detect the test/build commands from the package manifest. Do not assume npm.
3. Check whether a Slack webhook secret already exists:
   `gh secret list | grep -i slack`.

## Steps

1. Copy the needed templates from `$(ava-home)/templates/workflows/` into
   `.github/workflows/`, substituting the detected commands and branch names.
2. If notifications are wanted, ensure a webhook secret exists. If not, stop and
   give the user the exact three steps: create an incoming webhook in Slack, run
   `gh secret set SLACK_WEBHOOK_URL`, re-run this queue.
3. Open a PR. **Never commit workflows directly to a protected branch** —
   workflow changes deserve review precisely because they run with credentials.
4. After merge, trigger one run and confirm a message actually arrives. An
   untested notification path is indistinguishable from a broken one.

## The billing trap — read before adding any schedule

Most CI platforms bill **per run, rounded up to a full minute**. A 9-second
probe on a `*/5` schedule costs 288 minutes a day — roughly 8,600 a month,
against a typical free allowance of 2,000. That exhausts the quota and takes
down **every** workflow: tests, deploys, and backups, usually with no warning.

This has happened in practice.

- **Never** add a sub-hourly `cron:`.
- Uptime probing belongs on an external pinger, not CI.
- A nightly backup at a fixed hour is fine.

## The alerting blind spot — design around it

A failure notification implemented as a **step inside a job** cannot fire when
the job never starts. Billing outages, disabled Actions, and quota exhaustion
all prevent job start — so the workflow stays silent exactly when something is
most wrong.

Observed consequence: seven consecutive nightly backup failures, zero alerts.

If backups or another critical scheduled job matter, add an **external**
dead-man's-switch that alerts on the *absence* of a success ping. Note it in the
report even if the user defers it.

## Stop conditions

- No webhook secret and the user cannot provide one → install CI, skip
  notifications, say which half landed.
- The repo already has equivalent workflows → report that and change nothing.

## Report

Which workflows were added, which already existed, whether a test notification
actually arrived, and any deferred item (especially the dead-man's-switch).
