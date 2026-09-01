---
name: feature-legal
autonomy: act
agents: [ava-feature-steward]
when: "check the legal pages", "are our features documented", "compliance check", "does this actually work end to end"
---

## Goal

Every feature the product markets actually works for a real user, and every
feature that touches personal data or a decision about a person is disclosed
where it must be.

If the product makes automated decisions about people — hiring, lending,
housing, insurance — disclosure is usually a legal requirement, not a
documentation nicety. An undisclosed data-touching feature is a compliance
problem.

## Steps

1. Trace each marketed promise through route → action → data write → what the
   user receives. Check the seams, not just that code exists.
2. For each feature touching personal data, recordings, automated scoring, a
   sub-processor, or a decision about a person: confirm it is named in the
   relevant policy pages.
3. Check the reverse — policy or changelog text describing something the product
   no longer does.
4. File an issue per gap stating the promise, where it is made, what actually
   happens, and the specific edit that closes it.

## Stop conditions

- **Never edit legal copy directly.** Propose exact wording; a human approves.
- Evidence must be a committed file. A gitignored directory does not exist in a
  clone.

## Report

Gaps found, issues filed, and the single most serious promise-vs-delivery
mismatch.
