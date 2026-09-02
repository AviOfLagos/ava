# Ava queues

Named playbooks Ava dispatches. One file per recurring job.

This directory holds the playbooks that ship with Ava. A project adds its own
under `.claude/queues/`, and Ava reads both every run — `ava-home queues` prints
the merged registry. A project file with the same name as one here **replaces**
it, which is how a repo overrides a playbook without forking Ava.

Write new queues into the project, not here: this directory is shared by every
repo on the machine and is overwritten by the next `/plugin update`. Use
`/ava update queues` rather than hand-writing one, so frontmatter stays
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
