---
name: triage-issues
autonomy: act
agents: [ava-issue-triage]
when: "fix issues", "what should we work on", "triage", "what's open", "pick something up"
---

## Goal

The open list is ranked by real user impact, and the top item is either fixed or
sharpened enough that the next person can fix it.

## Steps

1. `gh issue list --state open --limit 100 --json number,title,labels,updatedAt`
2. Rank by the priority ladder in the Ava skill — blast radius on a real user,
   not label. Labels are claims; re-derive severity.
3. Spawn `ava-issue-triage` on the top items. Parallel when independent.
4. Check `handled` in state first so nothing is re-filed or re-fixed.

## Stop conditions

- Diagnosis is a hypothesis, not confirmed → update the issue with what you
  verified and the exact next command. No speculative PRs.
- The fix needs production data you cannot read → say so and ask.
- The issue's proposed fix looks wrong → say why, propose the alternative, and
  do not implement the wrong one just because it was asked for.

## Report

Ranked list with one-line reasons, what was verified, what changed, and anything
you think outranks the current ordering.
