---
name: ci-recovery
autonomy: act
agents: [ava-ci-medic, ava-issue-triage]
when: "check CI", "why did the build fail", "get the branch green", "fix the failing tests", "retry CI"
---

## Goal

Every open PR either has a green pipeline or a written, accurate explanation of
why it does not — and where the cause is ours, a fix is in flight.

The failure this prevents: a red check nobody reads, so a real bug and an
infrastructure outage look identical.

## Step 0 — is CI even running?

Before touching a single PR. Getting it wrong wastes the whole run.

```bash
gh run list --limit 15 --json name,conclusion,createdAt,headBranch,databaseId
gh run view <id>   # read the annotation, not just the conclusion
```

- **Annotation about failed payments or a spending limit** → billing outage.
  Jobs die in 2–3s before any step runs. **Stop.** Retrying and code-fixing are
  both useless. File **one** issue for the outage, not one per PR.
- **Real failures** → continue.
- **No runs at all** → workflows are not triggering. Check the `on:` filters and
  path globs before assuming anything is broken.

## Steps

1. **Group failures by cause, not by PR.** Six PRs failing on one missing secret
   is one problem.
2. **Classify each cause:**
   - *Ours* — real test failure, type error, lint or format violation.
   - *Infrastructure* — expired credential, unreachable service, missing secret,
     billing. These fail every PR regardless of diff, which is the tell.
   - *Flake* — passes on re-run. But a suite sharing one database across runs
     and deliberately serialized is **not** flaky; concurrent runs corrupt each
     other's fixtures. Never "fix" that with retries or parallelism.
3. **Retry only where meaningful** — a suspected flake, or after a credential is
   restored. **Once**, then escalate. Never retry billing or code failures.
4. **File an issue per distinct cause**, not per PR. Include the failing job,
   the exact annotation, and which PRs it affects. Reserve the top priority
   label for causes blocking *all* PRs — inflating it hides the real ones.
5. **Fix what is ours.** One agent per cause, in parallel: branch, fix, add the
   missing test, run suites plus format and lint locally, open a PR.
6. **Re-check.** If still red, do not loop blindly — report what changed and
   what did not.
7. **Escalate infrastructure.** Name the exact missing thing and who can supply
   it.

## While CI is unavailable

- Say so on every PR you touch, so nobody debugs a healthy branch.
- **Run the checks locally** and report exactly which you ran.
- Never call a PR "passing" on absent checks. "No checks ran; I ran X and Y
  locally, both passed" is the honest form.

## Stop conditions

- Billing outage → report and stop; nothing downstream is actionable.
- Same cause fails twice after a fix attempt → stop; a third try is guessing.
- A fix would touch auth, billing, or the product's core flow → open the PR but
  flag it for human review rather than treating it as routine.

## Report

Causes (not PRs): what failed, ours or infrastructure, what you did, current
state. Then the PRs that are genuinely fine and only *look* broken — usually the
most useful thing here.
