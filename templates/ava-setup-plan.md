# Ava setup plan

Everything Ava intends to do on this project, in one file. Read it once, change
whatever you disagree with, then say `go`.

**Editing is the interface.** Delete a line and Ava will not do it — no prompt,
no follow-up question. Change a value and Ava uses the changed value.

Ava will not do anything that is not written here. If it finds a new need while
executing, it stops, amends this file, and asks again.

Generated: `<timestamp>` · Project: `<repo>`

---

## 1. Ava will do these

Each line: what it is, why it was proposed, and who publishes it. The "why" is
tied to something actually found in this repo — if it reads like a generic
pitch, delete it.

| # | What | Why — what was detected | Publisher |
| --- | --- | --- | --- |
| 1 | | | |

Anything that overwrites existing config, changes CI, or touches a protected
branch is marked **⚠ destructive** in the What column. Read those twice.

## 2. Ava will need you for these

Ava stops at each of these and waits. They are listed now rather than sprung on
you one at a time, so you know the total cost before agreeing to any of it.

| # | Handoff | What you do | Where the value goes |
| --- | --- | --- | --- |
| 1 | | | |

Ava never reads, types or stores a secret. It will tell you which field to copy
and which file to paste it into; the value goes from the provider's page to your
file without passing through Ava.

## 3. Ava is skipping these

Proposed and declined, or detected as not applicable. This section is why the
same question is not asked again on the next run — delete a line here to make
it eligible again.

| # | What | Why skipped |
| --- | --- | --- |
| 1 | | |

---

## Confirming

Reply `go` when this file says what you want. Ava executes top to bottom and
reports as it goes.

A failed item does not stop the run — it is recorded, execution continues, and
the final report names what failed and the one action that fixes it.
