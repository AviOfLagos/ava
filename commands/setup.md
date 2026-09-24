---
description: Check everything Ava depends on is actually set up — project config, token discipline, commit identity, memory, CI monitoring — then fix the safe parts and report the rest.
argument-hint: "[area, e.g. tokens | memory | ci | identity]  (omit to sweep everything)"
---

Run Ava's `setup` queue.

Arguments: $ARGUMENTS

Read the queue playbook and follow it. If `ava-home` is on PATH, the shipped
copy is at `$(ava-home)/queues/setup.md`; otherwise read `.claude/queues/setup.md`
or the `queues/setup.md` beside Ava's skill file.

If an area was named in the arguments, check only that area. With no arguments,
sweep all of them.

Two rules override anything in the playbook:

1. **Report before you change anything that removes capability.** Additive fixes
   (writing a rules section, adding a cheap agent, creating a missing config)
   may be applied and announced. Anything that disables a plugin, a connector,
   an MCP server, or a workflow waits for an explicit yes.
2. **Never claim a check passed that you did not actually run.** A skipped check
   is reported as skipped, with the reason.
