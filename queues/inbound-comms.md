---
name: inbound-comms
autonomy: act
agents: [ava-feature-steward]
when: "any customer emails", "check the inbox", "did anyone complain", "respond to feedback"
---

## Goal

No inbound human waits unanswered, and anything that is also a defect becomes an
issue.

## Steps

1. Read forward from the cursor: the inbound channel for real external mail —
   skip our own sends, routing checks, cold sales pitches — and the ops channel
   for feedback and problem-report events.
2. Classify: complaint · question · bug report · feature request · noise.
3. **File an issue when it is also a defect.**
4. Draft a reply — plain, specific, answers the actual question.
5. Send **only** if `autonomy.allowSendCustomerReplies` is true AND every fact
   in it is already documented. If it depends on undocumented policy — billing,
   retention, refunds, anything contractual — **do not send**; escalate with the
   exact questions.
6. Post a digest of what was caught, only when something needs attention. Never
   paste a customer's full email; one quoted line. Never include credentials.

## Stop conditions

- The reply would require inventing policy → escalate, do not send.
- The person is angry, or raising a legal, privacy or refund matter → draft
  only, always escalate. These need a human voice.

## Report

Items found, sent vs drafted, issues filed, and the questions a human must
answer before the remaining drafts go out.
