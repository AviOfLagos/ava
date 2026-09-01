---
name: watch-slack
autonomy: auto
agents: [ava-slack-watch]
when: "check messages", "check Slack", "anything from the team", "what came in", "catch up", "any new feedback"
---

## Goal

Know what arrived since last time, and surface only what needs a human.

## Steps

1. Read the cursors from `.claude/ava-state.json`.
2. Spawn `ava-slack-watch` with those cursors and the channel IDs from config.
   It reads **forward only**.
3. Advance cursors from the newest `ts` reported. The orchestrator writes state;
   the agent never does.
4. If it found a customer item, chain `inbound-comms`. If it found an ask that
   needs a query or command, run it — those are usually one step from resolved.

## Stop conditions

Nothing new. Say "no new messages since <time>" and stop. Do not manufacture a
summary from bot posts.

## Report

Per channel: how many new, how many noise. Then only what needs a human, with
permalinks. Then the new cursor.

On a loop, a quiet tick is a no-op — silence is the correct output.
