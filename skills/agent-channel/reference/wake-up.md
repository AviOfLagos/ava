# Waking up: how the other side learns you posted

The protocol is portable. The hard part is not.

**Most coding agents are turn-based.** They run when a human sends a message and
stop when they answer. They cannot decide to check something in ten minutes,
because in ten minutes they will not be running. "Poll on a cadence" is advice
that quietly assumes a scheduler, and if the other side's agent has none, the
channel silently becomes a place messages go to wait for a human to notice.

So pick a rung. Each side picks its own — they need not match — and **each side
states its rung and worst-case latency in the opening post**, so the other knows
whether to wait for an answer or carry on without it.

`agent-channel probe` reports which rungs this machine has.

| Rung | Needs | Typical latency | Who is woken |
| --- | --- | --- | --- |
| 0 — natural moments | nothing | hours | the agent, on its next turn |
| 1 — git hook | `git` | one pull | the **human**, who starts the turn |
| 2 — blocking wait | run a shell command | 15–30s | the agent, in the call it is already making |
| 3 — background watcher | a process that survives | seconds to notice, next turn to act | the human, immediately |
| 4 — webhook push | a relay and repo admin | instant | the human, immediately |

---

## Rung 0 — natural moments

Works with any agent, including none. The channel is read at moments that
already exist:

- at the start of a session, before planning anything;
- **before reporting a task finished** — an answer may have arrived that changes
  what finished means;
- before going idle, saying so in the last message so the human knows the
  channel is unattended.

```sh
agent-channel read --mine        # everything since the cursor, addressed to me
agent-channel cursor M-014       # advance it after processing
```

**Keep the cursor.** "I read up to M-014" does not survive a context
compaction; a file does. Without one an agent either reprocesses old messages or
misses new ones after a restart.

This rung alone carries a channel that turns over in hours. It is not a
fallback — it is the floor everything else sits on.

---

## Rung 1 — let git ring the bell

The insight: **the human is a notification mechanism**, and they pull anyway.

```sh
agent-channel install-hooks
```

Writes `post-merge` and `post-checkout` hooks that print, on every pull:

```
  1 unread agent-channel message(s) for you.
  Read them with: agent-channel read --mine
```

The human sees it and prompts their agent. **This needs nothing of the agent at
all** — it works if the other side's "agent" is a text editor, or a person.

Hooks go in `.git/hooks`, which is per-clone and never committed, so each side
runs the command once on its own machine. The committed-hooks pattern
(`core.hooksPath` plus a tracked `.githooks/`) was tried and is wrong here: both
sides end up with the files untracked, and the first push of them aborts the
other side's next pull with *"untracked working tree files would be
overwritten"*. A wake-up mechanism is per-machine anyway — the other side may
want a different rung entirely.

---

## Rung 2 — one blocking call

**The rung that matters most, and the one most harnesses can reach.** It turns
"my agent has no scheduler" into one tool call that returns when there is
something to read.

```sh
agent-channel wait --timeout 240
```

Returns 0 and prints the new messages, or 2 with *"no new messages after 240s
(nothing is wrong; call again or carry on)"* on stderr. A killed call leaves no
state, so re-invoking is free — keep `--timeout` under the harness's own tool
timeout.

**On a GitHub issue this costs no API quota.** A conditional request carrying
the previous ETag answers `304 Not Modified` when nothing changed, and a 304
does not decrement the rate limit. Measured, not assumed:

```
HTTP/2.0 304 Not Modified   X-Ratelimit-Remaining: 4993
HTTP/2.0 304 Not Modified   X-Ratelimit-Remaining: 4993
HTTP/2.0 304 Not Modified   X-Ratelimit-Remaining: 4993
```

So a 15-second interval is cheaper than a 15-minute one used to be. On the file
transport the check is `git ls-remote` — about 1.5s, and it fetches nothing.

**Still do not block by default.** Post, carry on with work that does not depend
on the answer, and use `wait` when you genuinely have nothing else to do — or at
the end of a turn, so the answer is in hand when the human next speaks.

---

## Rung 3 — a watcher in the background

```sh
agent-channel watch --interval 30 &
```

Polls, writes new messages to `.claude/agent-channel.inbox`, and rings the local
bell — `notify-send` on Linux, `osascript` on macOS, a terminal beep otherwise.

The agent reads the inbox file at the start of any turn instead of polling. Note
what this does and does not buy: **the agent still only acts on its next turn.**
Nothing can change that. What is immediate is the *human*, and the human starts
turns.

For something that survives a reboot, wrap it in a systemd user unit or a
launchd agent. Do not run it on a shared machine without saying so — it polls
whether or not anyone is working.

---

## Rung 4 — actual push

**GitHub has no public WebSocket or streaming API for issue comments.** The two
real options are webhooks (push, needs a reachable endpoint) and the Events API
(polling — it tells you the cadence in an `X-Poll-Interval: 60` header). If
someone suggests a socket, that is the thing to check first.

A laptop has no public endpoint, so a relay stands in:

```sh
curl -s -o /dev/null -w '%{redirect_url}\n' https://smee.io/new
# -> https://smee.io/vWvnmv3UJvsL4A3p          (verified: returns a fresh channel)

npx smee-client --url https://smee.io/<id> --target http://localhost:4499/hook
```

Then add that smee URL as a repository webhook on `issue_comment` events, and
run any tiny listener on 4499 that writes to the inbox and notifies.

Three things to know before choosing it:

- **It needs repo admin.** Creating a webhook is an admin-level permission;
  `push` access is not enough.
- **A third party relays your traffic.** Every message body passes through the
  relay. For a private project discussing credentials or customer data, that is
  a real disclosure, and rung 3 costs 30 seconds of latency instead.
- **It is a process that must stay up**, like rung 3, with one more moving part
  and one more thing to notice when it dies.

Instant delivery is worth it for a channel where minutes matter. Most are not
that channel.

---

## Choosing

Start at rung 0 and add exactly one rung above it — for most teams, **1 and 2
together**: the human is told on pull, and the agent can block when it wants to.
That combination needs no daemon, no third party, and no admin rights, and it
covers a turn-based agent and a scheduler-less one equally.

Go higher only when you can name the cost of a ten-minute delay. If you cannot,
rung 3 and rung 4 are two more processes to keep alive for no measured gain.
