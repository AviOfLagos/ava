# Ava queues

Named playbooks Ava dispatches. One file per recurring job.

Ava reads this directory on every run — adding a file is how Ava learns a job.
Use `/ava update queues` rather than hand-writing one, so frontmatter stays
consistent.

## Frontmatter

| Field | Meaning |
| ----- | ------- |
| `name` | kebab-case, matches the filename |
| `autonomy` | `auto` (read-only) · `act` (may create branches/PRs/issues) · `gated` (hard gates must pass) |
| `agents` | which sub-agents this queue spawns |
| `when` | plain-English triggers — how Ava recognises this job in a request |

## Body

`## Goal` · `## Gates` (gated only) · `## Steps` · `## Stop conditions` ·
`## Report`.

## What makes a queue good

**Gates are checkable facts, never judgement calls.** "An approval message
exists from user X, posted within 24 hours, referencing the current HEAD" is a
gate. "The release seems ready" is not.

**Stop conditions get as much thought as steps.** A queue that only knows how to
push forward is how an agent does damage confidently.

**No transient state.** Never write "CI is currently down" — write the
recognisable signature of an outage and an instruction to check at runtime.
Baked-in state goes stale and then actively misleads.

**Name the failure the queue prevents.** A queue whose Goal explains what goes
wrong without it is one an agent can reason about when reality does not match
the steps.
