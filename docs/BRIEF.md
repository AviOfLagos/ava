# Brief — what was asked for

Recorded from the originating request so the next session has the intent, not
just the artefact. Ticked items are in this repo already.

## Core ask

Export the Ava tooling built inside a specific product (an AI-interviewer
project) into a **product-agnostic** skill, published on GitHub, installable by
telling any coding agent "install the Ava skill", working out of the box.

- [x] Generalise everything — "qa → main" becomes "integration branch →
      production branch", configurable per project
- [x] One entry point, `/ava`, taking plain English rather than flags
- [x] Separate repo, outside the origin project
- [x] Install instructions an agent can execute unattended
- [x] MIT licensed

## On install, it should

- [x] Map the project (language, branches, CI, deploy target)
- [x] Check GitHub / deploy provider / Slack connectivity
- [x] Ask where things deploy
- [x] Give short numbered instructions for anything not connected
- [x] Take Slack **channel names**, resolve IDs itself
- [x] Create a channel if missing — asking public/private first
- [x] Name who should be invited to that channel
- [ ] Verified against a real second project (**not yet done** — see ROADMAP)

## CI and monitoring

- [x] Install CI per project
- [x] Notify on: issue opened, PR merged closing an issue, deploy failed, CI
      failed on the integration branch
- [x] Sample workflows and sample message copy included as templates
- [x] Document the per-run billing trap and the job-never-starts alerting blind
      spot

## Memory

- [x] Use cavemem or MemPalace (explicitly not Obsidian)
- [x] Context7 for current library documentation
- [x] Verified both projects exist; recorded that cavemem is marked "Frozen"
- [ ] Install path tested end to end (**not yet** — instructions say to follow
      each project's own README rather than trusting a possibly-stale command)

## Deliberate design decisions

**Config over convention.** Every project-specific fact lives in
`.claude/ava.config.json`. The skill, agents and queues contain no project
identifiers at all — verified by grep. That separation is what makes this
portable rather than a fork per project.

**Queues as files.** A recurring job is a file, not a code change, so
`/ava update queues` genuinely extends the tool and teammates inherit it
through git.

**Gates are facts, not judgement.** The release gate demands a quotable
approval from a named person, recent, about the current tree, not retracted.
"No quote, no gate" is deliberately mechanical so it cannot be reasoned around.

**Stop conditions are first-class.** Every queue has them. A queue that only
knows how to push forward is how an agent does damage confidently.

**Autonomy is tiered and defaults conservative.** Autonomous production merge
exists but is off by default, because a clean gate proves less when CI is
degraded — and CI degradation is exactly when someone reaches for the override.

## Origin

Extracted from work on a production project where each encoded rule traces to a
real incident: an Actions billing outage that silently killed seven nightly
backups; a deploy blocked for a week because merge commits carried an
unattributable git author; a cross-tenant leak whose "obvious" fix would have
re-opened the bug it was meant to close.

The value here is the encoded judgement, not the automation.
