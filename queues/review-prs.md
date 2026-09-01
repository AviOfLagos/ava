---
name: review-prs
autonomy: act
agents: [ava-pr-reviewer]
when: "review PRs", "what's unmerged", "check the pull requests", "why is this PR stuck"
---

## Goal

Every open PR has a current review and a stated reason it is not merged.

## Steps

1. `gh pr list --state open --json number,title,headRefName,baseRefName,isDraft,updatedAt`
2. Spawn `ava-pr-reviewer`, one agent per PR when several need real review.
3. Separate "this PR has a problem" from "the infrastructure has a problem".
   Never report infra noise as a code failure.
4. Reply to unanswered threads addressed to us.

## Stop conditions

**Never merge.** Merging into production belongs to `promote-to-production`;
merging into the integration branch is a human's call.

## Report

Per PR: state, real blocker, verdict. Then which you would merge first, and
which needs a human. Flag PRs whose only failure is infrastructure.
