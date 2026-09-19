---
name: cluster-and-dispatch
autonomy: act
agents: [ava-cluster-owner, ava-pr-reviewer]
when: "work the issues", "take on the issues", "cluster the issues", "fix everything", "spread the work", "what can we parallelise", "run the backlog"
---

## Goal

Every open issue carries exactly one cluster label, each cluster chosen for this
run is worked by one specialist agent in its own worktree, and nothing reaches
`<integration>` without a second agent having reviewed it.

**The failure this prevents:** a flat backlog cannot be parallelised safely.
Point several agents at one undifferentiated list and two of them pick the same
issue, edit the same files, and the second silently undoes the first — or both
open a PR and the duplicate reads like a follow-up rather than a collision.
Clustering is what turns "run several agents at once" into a safe instruction.
One issue, exactly one owner.

## Steps

### 0. The taxonomy — `.claude/ava-clusters.md`

Clusters are **this project's** product areas. Ava ships no default set; a
borrowed taxonomy is worse than none, because dispatch stops being predictable.

```bash
cat .claude/ava-clusters.md 2>/dev/null \
  || cp "$(ava-home)/templates/ava-clusters.md" .claude/ava-clusters.md
```

If you had to copy the template, derive the real taxonomy now, before labelling
anything, from three sources in this order:

1. **The open issue list itself.** Read all of it. The clusters are the shapes
   already in the titles, not a tidy abstraction over them.
2. **The repo's own structure** — top-level modules, route groups, service
   directories. Where the code is split is usually where expertise is split.
3. **`CLAUDE.md` / `AGENTS.md` / the README.** Many projects already name their
   surfaces; adopt those names rather than inventing parallel ones.

A cluster is a **body of expertise**, not a file path: the test is whether one
agent could competently own every issue in it. Six to fourteen rows suits most
projects. Fewer and dispatch cannot parallelise; more and most clusters are
empty on any given run. Then create the labels:

```bash
gh label create "cluster:<name>" --color <hex> --description "<what it owns>"
```

Commit `.claude/ava-clusters.md` — teammates and their agents need the same map,
the same way they need `.claude/ava.config.json`.

### 1. Cluster every open issue — all of them, every run

```bash
gh issue list --state open --limit 300 --json number,title,labels
```

Label each from `.claude/ava-clusters.md`. **Exactly one `cluster:` label per
issue.** That file explains why, and it is the invariant the whole design rests
on: two labels means two agents can both believe an issue is theirs.

Verify before dispatching, rather than assuming the loop worked:

```bash
gh issue list --state open --limit 300 --json number,labels \
  --jq '[.[] | select([.labels[].name | select(startswith("cluster:"))] | length != 1)] | length'
# must print 0
```

A new issue with no cluster is the normal case on later runs — label it and move
on. An issue that fits no cluster is a taxonomy gap: add the cluster to
`.claude/ava-clusters.md` with its judgement call, do not force a bad fit.

### 2. Pick which clusters to run

Not all of them. Choose by what is actually inside them:

- a cluster whose top item is **broken for a real user right now** goes first
- a cluster that is **all trackers, or all blocked on a human** is skipped, and
  say so rather than spawning an agent to discover it
- otherwise rank clusters by their highest-priority live issue, using the
  priority ladder in the Ava skill

Scale to the work. Three clusters with real bugs beats twelve agents where nine
have nothing to do; every spawned agent costs tokens and a worktree.

### 3. Spawn one agent per chosen cluster, in ONE message

`ava-cluster-owner`, concurrently, so they run in parallel and the user can
interject. Each prompt carries:

- its cluster label, and that everything else belongs to a peer running **now**
- the issue numbers currently in it
- what you already know from the situation assessment — CI health, deploy state,
  how far `<integration>` is ahead of `<production>`. Never make an agent
  re-derive it.
- the hard rules from the Ava skill
- the worktree requirement, verbatim, including the git identity from
  `git.requiredAuthorName` / `git.requiredAuthorEmail`

### 4. Review before anything merges

When an agent opens a PR, hand it to `ava-pr-reviewer`. The author does not
merge their own work, and the reviewer does not merge either — it reports.

The reviewer reads the **diff**, not the description, and checks what this
project has actually been bitten by: read `AVA-NOTES.md` for that list. Two that
generalise — tenant or ownership scoping on any new data read, and a test that
genuinely fails without its fix. If the change renders or responds, the review
wants evidence that someone loaded the page, not that the build went green.

### 5. Merge to `<integration>` when it is genuinely green

Verify by **head sha**, never by the PR badge:

```bash
SHA=$(gh pr view <n> --json headRefOid --jq '.headRefOid')
gh run list --limit 40 --json headSha,name,conclusion \
  --jq ".[] | select(.headSha==\"$SHA\") | \"\(.name)\t\(.conclusion)\""
```

A `cancelled` run **disappears from the badge list** rather than showing red —
absence is not a pass. Re-run it. A PR that conflicts gets no CI at all, because
the merge ref cannot be built, and it displays whatever last succeeded, pinned
to an older sha.

Read the PR's **comments** before merging, not just its description. A hold
arrives later, in a comment; a description is written once, at open.

Then check the merge actually deployed. `git log` proves code is on a branch,
never that it is live.

## Stop conditions

- **A cluster's top item needs a human decision** — a policy call, a credential,
  a product choice. Report it as a decision; do not guess a default.
- **CI is down.** Do not read the reds as code failures, and do not merge on a
  green from before the outage — that is a stale signal pinned to an older sha.
  Either hold, or verify locally and say plainly that is what you did.
- **Two agents touch the same file.** Stop the second and report the overlap. It
  means the clustering is wrong, and the fix is the taxonomy, not the merge.
- **A migration is required.** Propose it; never run one against production.

## Report

One report for the whole run, not one per agent:

- **Clusters** — the counts, and which you ran versus skipped and why.
- **Landed** — merged to `<integration>`, with issue/PR numbers.
- **In review** — open PRs and what they are waiting on.
- **Needs you** — decisions, one sentence each, naming the specific question.
- **Taxonomy changes** — any cluster added or issue re-clustered, with why.
