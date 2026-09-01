---
name: promote-to-production
autonomy: gated
agents: [ava-release-warden]
when: "ship to prod", "promote to main", "can we release", "is prod up to date", "did they approve the merge"
---

## Goal

Get the integration branch onto production — but only when it is genuinely
safe, and only when a configured approver has confirmed it. Otherwise produce a
precise NO-GO saying which gate failed and what would clear it.

This is the only queue permitted to merge. It is rare and it is strict.

## Gates

All must hold. **Any gate unmet or ambiguous = NO-GO. Ambiguity is a failure,
never a judgement call to resolve in favour of shipping.**

### G1 — an approver confirmed, and the confirmation is real

The load-bearing gate. Everything else is mechanical; this is human authority.
Counts only when all hold:

1. **Author is in `people.releaseApprovers`** — verified by Slack user ID on the
   message itself. Not a bot post containing their name. Not a third party
   relaying it.
2. **Unambiguously affirmative.** "go ahead" / "ship it" / "approved" count.
   "looks good so far", "should be fine", "once X lands" (unless X is verified
   landed), and questions do not.
3. **Recent** — within `release.approvalMaxAgeHours`. Older approvals describe a
   different tree; ask again rather than reuse.
4. **About this promotion** — names the current integration HEAD, refers to the
   pending commits, or was posted after the newest commit landed.
5. **Not retracted** — a later "hold on" overrides an earlier "go".

Record permalink, timestamp and verbatim text. **No quote, no gate.**

Skip this gate only if `release.requireApproval` is false — which means the
project chose ungated promotion knowingly.

### G2 — you know what is shipping

`git log --oneline origin/<production>..origin/<integration>` plus
`git diff --stat`. Enumerate commits and the issues they close. A promotion
whose contents you cannot state is a NO-GO.

### G3 — CI status understood, not assumed

- Green ⇒ pass.
- **Absent ⇒ not a pass.** Find out why: billing outage, workflows not
  triggering, runs queued. Clears only if the G1 approval explicitly
  acknowledges shipping without CI, or `release.allowMergeWhenCIAbsent` is true.
- Failing for infrastructure reasons ⇒ say so; treat as absent, not as a code
  failure.
- Failing for real ⇒ NO-GO.

### G4 — no unmerged blocker

Open issues at the project's top priority label that this promotion does not
fix. List them; NO-GO unless the approval named them as knowingly deferred.

### G5 — the promotion can actually deploy

If deploys are currently blocked, the merge lands in git but production will
**not** update. This does not block the merge, but must be stated loudly in the
report and the PR body — otherwise the team believes fixes are live when they
are not. That misunderstanding is a recurring, expensive failure.

### G6 — safety rails survive

Any guard script or protective config the project depends on must exist on the
resulting tree. A promotion has silently deleted one before. Verify explicitly.

## Steps

1. G1 first. Fails ⇒ stop; do not spend effort on the rest.
2. G2–G6.
3. All pass **and** `autonomy.allowAutonomousPromotion` is true: create
   `<promotionPrefix><date>` off production, merge integration in, open a PR
   into production, merge it. If the flag is false, report GO and stop — the
   human executes.
4. PR body: commits, issues closed, the approval quote and permalink, and the
   CI/deploy caveats.
5. Run the project's deploy verification; require success. **Never** report
   "live" from a 200 on a health endpoint.
6. Post the outcome to the ops channel.

## Stop conditions

- G1 not satisfied → stop. This is the point of the queue.
- Merge conflict → stop; report the conflicting paths. Never resolve conflicts
  unattended on a production promotion.
- `Closes #A, #B` anywhere → GitHub closes only the first; close the rest by
  hand after merging.
- Anything in the diff the commit messages do not explain → stop and report.

## Report

**GO** — gates with evidence, the approval quote, what shipped, deploy
verification, and whether it is actually live.

**NO-GO** — the first gate that failed, why, and the single specific thing that
would clear it. One blocker stated precisely beats a list of everything checked.
