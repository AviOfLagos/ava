# Transports

The protocol needs one thing from a transport: **an ordered, append-only log
both sides can read and write.** Everything else is convenience.

---

## 1. A GitHub or GitLab issue — the default

Ordered, timestamped, append-only, no merge conflicts, and the human can read it
from a phone. Comments cannot be silently reordered.

**Polling it is free.** A conditional request carrying the previous ETag answers
`304 Not Modified` when nothing changed, and **a 304 does not decrement the rate
limit** — measured, three consecutive calls, `X-Ratelimit-Remaining` unchanged
at 4993. So the cost is one request per *actual* message, not per check, and a
15-second interval is affordable. `agent-channel wait` does this for you.

```bash
# open the channel
gh issue create --title "Coordination channel: <side A> ↔ <side B>" --body-file channel.md

# post (ALWAYS --body-file; backticks in --body are executed by the shell)
gh issue comment 205 --body-file message.md

# read everything since a cursor, oldest first
gh issue view 205 --json comments \
  --jq '.comments[] | "\(.createdAt)\t\(.author.login)\t\(.body)"'
```

**Both sides may post as the same account** when the human's token is what each
session has. Then the header line is the only way to tell who wrote a comment,
and a comment *without* a header is from the human. Say that in the opening
post.

Pitfalls:

- `--body` with backticks in it runs them as a shell command substitution. Use
  `--body-file` for every message. This has bitten twice.
- `gh issue view --json comments` returns all comments; filter by your cursor
  rather than by count.

---

## 2. A committed file — when there is no API

Both machines already have the repo, so it needs no new service. The cost is
merge conflicts: two sides appending to one file conflict on every push.

**Fix it once, in `.gitattributes`:**

```gitattributes
# An append-only channel: two sides adding different messages is not a
# disagreement. Without this, every push by one side conflicts the other.
COORDINATION.md merge=union
```

`merge=union` keeps both sides of a conflicting hunk instead of failing. For an
append-only log that is exactly right — messages may interleave out of order,
which is why every message carries its own id and timestamp.

**The limit, which is not obvious:** a merge driver is run by *git*. GitHub's
squash-merge does not run one, so a pull request opened before another lands
still shows as conflicting on the site, and the symptom is often "no checks
reported" rather than a conflict warning. Resolve by merging the base branch
into yours locally, where the driver runs, then pushing.

Do **not** apply `merge=union` to specifications, decisions or code. There a
conflict is information and must be seen.

Conventions that make a file transport work:

- append at the bottom, never edit an earlier message;
- one commit per message, with the message id in the commit subject, so
  `git log` is a message index;
- pull before you append, push immediately after.

---

## 3. Anything else ordered

A gist, a shared-drive document, an object-store key, a Slack thread, a database
table. The protocol does not care. Check three things before choosing:

1. **Append without clobbering.** Two sides writing near-simultaneously must not
   lose a message. Whole-file overwrite transports fail here unless writes are
   serialised.
2. **Stable ordering.** You need to be able to ask "what is after id N".
3. **The human can read it.** A channel the human cannot open is one they cannot
   arbitrate, and rule 1 of the caps sends disagreements to them.

---

## No socket

There is **no public GitHub WebSocket or streaming API** for issue comments. The
alternatives are webhooks — push, but they need an endpoint your laptop does not
have — and the Events API, which is polling and says so in an `X-Poll-Interval:
60` header. `reference/wake-up.md` § Rung 4 covers the relay that gives a laptop
an endpoint, and what it costs.

## Cursors

Whatever the transport, keep a local cursor — the last message id you processed.

```bash
# read it
test -f .claude/channel-cursor && cat .claude/channel-cursor

# advance it after processing
echo "M-014" > .claude/channel-cursor
```

Keep it out of version control if both machines share the repo, or each side
will keep overwriting the other's position. `.gitignore` it, or name it per side
(`.claude/channel-cursor.linux`).

A cursor survives a context compaction; your memory of "I read up to M-014" does
not.
