# Issue clusters

The canonical map from a GitHub issue to the part of this product it belongs to.
`cluster-and-dispatch` labels every open issue from this file, and each cluster
is handed to exactly one `ava-cluster-owner` agent.

> **This is a starter file.** The rows below are a worked example from a
> hypothetical product, not defaults. Replace them with this project's real
> areas before dispatching anything — a borrowed taxonomy is worse than none,
> because dispatch stops being predictable. Keep the two sections that are not
> examples: the rule, and the judgement-call log.

## The rule that makes dispatch safe

**One issue, exactly one cluster.** Not a taxonomy of everything an issue
touches — a statement of _who owns it_. Two labels on one issue means two agents
can both believe it is theirs, and multi-agent collision is the failure this
whole design exists to avoid.

Cross-cutting work is handled by the owning cluster **pulling in** the related
issue and saying so, never by dual-labelling. Ownership goes to the expertise
that decides whether the fix is _right_, which is not always the area the code
lives in.

## How to derive the clusters for this project

A cluster is a **body of expertise**, not a directory. The test: could one agent
competently own every issue in it? Derive them from, in order —

1. **The open issue list.** Read all of it. The clusters are the shapes already
   in the titles, not a tidy abstraction over them.
2. **The repo's structure** — modules, route groups, services. Where the code is
   split is usually where expertise is split.
3. **`CLAUDE.md` / `AGENTS.md` / the README.** If the project already names its
   surfaces, adopt those names instead of inventing parallel ones.

Six to fourteen rows suits most projects. Fewer and there is nothing to
parallelise; more and most clusters are empty on any given run.

Create a label per row: `gh label create "cluster:<name>" --description "<owns>"`.

Commit this file. Teammates and their agents need the same map.

## Clusters

Two rows that survive in almost every project:

| Label          | Owns                                                             |
| -------------- | ---------------------------------------------------------------- |
| `cluster:infra-ci` | CI, deploys, environments, database ops, monitoring, release process |
| `cluster:meta`     | Trackers, boards, coordination and documentation-only issues     |

**Example rows — delete these and write your own:**

| Label                         | Owns                                                                |
| ----------------------------- | ------------------------------------------------------------------- |
| `cluster:billing`             | Payments, plans, pricing, refunds, credits/quota, payment webhooks   |
| `cluster:user-account`        | Auth, login, sessions, profile, account settings, device alerts      |
| `cluster:<core-domain>`       | The thing users come for — name it after the product, not the module |
| `cluster:notifications`       | Transactional email/push, templating, unsubscribe, deliverability    |
| `cluster:integrations`        | Third-party connectors, inbound webhooks, imports                    |
| `cluster:marketing-growth`    | Public site, SEO, analytics, attribution, lead capture               |
| `cluster:security-compliance` | Security posture, secrets, CORS, privacy, retention, regulated flows |
| `cluster:ux-quality`          | Cross-cutting UX, accessibility, design-system and tech-debt consistency |

## Judgement calls, written down so they stay stable

Record the ones that genuinely could go either way. **The reasoning matters more
than the answer** — an inconsistent taxonomy is worse than an imperfect one,
because dispatch stops being predictable. Write each as "X → cluster, not
cluster, because …".

Four that recur across projects, as a guide to the shape:

- **A pricing page → billing, not marketing.** It is a marketing surface, but
  what makes it right or wrong is whether the numbers match the billing code.
  Billing expertise decides that.
- **Retention windows and deletion → security/compliance,** even when the
  control lives in account settings. The question is what the law requires.
- **A user-facing notification → notifications, not the feature it is about.**
  Delivery, templating and unsubscribe are one body of knowledge; what the user
  can _do_ in the product is another.
- **Trackers stay meta.** A tracker is a view of work, not work. An owner that
  "fixes" a tracker has usually just closed something prematurely.

## Adding a cluster

Only when an issue genuinely has no owner among the existing rows — not because
a cluster is large. A big cluster is a prioritisation problem; a missing cluster
is a dispatch problem. Add the row, create the label, and add the judgement call
above if it was close.
