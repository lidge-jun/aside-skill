# Scheduled runs and continuity

`aside exec` is an ordinary CLI process, so any scheduler can drive it. What needs
care is state: CLI sessions expire quickly, and the run has to be safe to launch
when nobody is watching.

## Put exec in the scheduler directly

There is nothing to build on top of this. Aside has no job runner of its own worth
wiring up, and there is no session to keep warm between ticks. A cron line or a
LaunchAgent that calls `aside exec` with a full prompt is the whole design:

```cron
0 9 * * * /Users/<you>/.aside/cli/bin/aside exec "<prompt with the three clauses>" >> ~/.aside/u/0/jobs/digest/run.log 2>&1
```

Each tick is a complete run that starts fresh, does the work, and exits. The only
things it needs from the outside are a `timeout`, a lock, and a prompt that cannot
ask a question. Everything else it can rediscover.

## Sessions expire after 15 minutes unless saved

CLI-created sessions are ephemeral while `save-sessions` is off (the shipped
default; this skill turns it on, below). The daemon hardcodes:

```js
EPHEMERAL_SESSION_RETENTION_MS = 900 * 1e3   // 15 minutes
```

and refuses to resume one past that:

```js
if (isEphemeralPurgePending(session))
    throw Error(`Session is pending purge: ${sessionId}`)
```

Verified both ways. A CLI session 135 minutes old failed immediately with
`Error Session is pending purge`, while a GUI-created session seven days old
resumed normally and answered. The difference is the `ephemeral` flag: the CLI
sends `ephemeral: true` at session creation, the app does not. Re-verified on
1.26.902: the `9e5` constant and the `Session is pending purge` string are still in
the daemon bundle.

So `aside session resume <id>` works for a quick follow-up within the window and
not for scheduling. The `--session` flag itself was removed in 1.26.902. Do not
build a cron job around resuming yesterday's session.

Inside that window the control verbs are worth knowing. `aside session resume <id> "<prompt>"`
runs one turn and exits; `aside session resume <id>` with no prompt opens an interactive
session with `>`, `/session`, and `/exit`, which is not something a script wants.
`aside session steer <id> "<text>"` redirects the running turn and
`aside session queue <id> "<text>"` schedules an instruction after the current step; both
print `ok` and exit, so neither waits for the run. `aside session archive <id>` and
`aside session delete <id>` clear a finished or unwanted session.

Two different 15-minute values exist and are easy to confuse.
`agentTabs.closeAfterIdleMinutes` in `settings.json` closes idle agent tabs and is
configurable. `EPHEMERAL_SESSION_RETENTION_MS` deletes the session itself, is
hardcoded, and cannot be changed.

The purge does not clean up after a hang, though. Its query only touches terminal
statuses:

```js
TERMINAL_SESSION_STATUSES = ['idle', 'errored', 'interrupted', 'aborted']
// purgeEphemeralSessions(): where ephemeral = true
//   and status in TERMINAL_SESSION_STATUSES
//   and archivedAt is null
//   and updatedAt < now - EPHEMERAL_SESSION_RETENTION_MS
```

`suspended` is not in that list, so a hung session is refused on resume and still
kept as a row. A count on `state.db` found nine of them, the oldest 14.4 hours past
its `updated_at`, every one `ephemeral = 1`. Expect them to pile up and clear them
yourself; see the parked-run section of the main skill.

## Keep CLI sessions on the chat list

`aside settings save-sessions true` puts CLI runs on the Aside chat list. Set it once
and leave it on; it is the default recommendation of this skill.

Measured on 1.26.902 (002_save-sessions-probe.md, S8):

| What | `save-sessions false` (shipped default) | `save-sessions true` |
|---|---|---|
| `~/.aside/u/0/settings.json` | `"cli": {"ephemeral": true}` | `"cli": {"ephemeral": false}` - the only file that changes |
| new CLI session row in `state.db` | `ephemeral = 1` | `ephemeral = 0` |
| `aside session list` | `ephemeral` | `persistent` |
| `aside.sessions.list()` | excluded | included |
| Aside window, Chats | not listed by policy, though the run made right before the flip was still showing after it | listed, with an unread dot (`evidence/probe-S3-aside-chat-list.png`) |
| 15-minute purge | applies once the session is terminal | never: the purge query has an explicit `ephemeral = true` predicate |

Existing rows are not rewritten, so sessions created before the flip keep their
ephemeral flag and their purge deadline. API and window do not agree on those:
`aside.sessions.list()` excluded the pre-flip baseline while the Chats list showed
it (`evidence/probe-S3-chat-list.log`), so the database flag is the persistence
classification and the sidebar is a separate exposure policy.

Whether a parked approval can be answered from the Chats list is still open. On
1.26.902 an outside-root file approval cannot park a CLI run through
`--permission ask`: it is the same mode as `guard` and denies, so no fresh
approval card could be produced (S8-Q4). The older
suspended rows are purge-pending and refuse `resume` and `steer`.

`aside session list` shows running, idle, interrupted, and aborted CLI sessions and
hides suspended ones regardless of this setting, so the `state.db` query in SKILL.md
stays the way to count parked runs.

With `save-sessions` off, there is also nothing useful to stash in the account
root on the session's behalf. A session lives in `state.db` under a daemon-managed
id, not in a file you can save and reload, so writing a session handle into
`~/.aside/u/0/` buys you a string that stops resolving fifteen minutes later.
Scripts and state files there are worth keeping; session ids are only worth keeping
once the setting is on, and even then a fresh run per tick is simpler.

## Carry state in files, not sessions

Each scheduled run should be independent, reading what it needs from disk and
writing back what the next run should know. `~/.aside/u/0/` is inside the writable
roots, so the file tools work there without any permission detour.

```bash
#!/bin/bash
JOB=~/.aside/u/0/jobs/youtube-digest
mkdir -p "$JOB"

LOCK=/tmp/yt-digest.lock
shlock -p $$ -f "$LOCK" || exit 0
trap 'rm -f "$LOCK"' EXIT

perl -e 'alarm shift; exec @ARGV' 600 aside exec --permission full-access "$(cat <<EOF
Read $JOB/state.md for what you already handled and skip anything listed there.
Do today's work, append what you handled to $JOB/state.md, and write the output to
$JOB/$(date +%F).md.

Write and edit files only under ~/.aside/u/0/. Read other local paths only when
this prompt names them, and never modify them.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop.
EOF
)" >> "$JOB/run.log" 2>&1
```

A lock and a deadline are both required, not optional, for unattended execution:
the lock skips a tick while the previous one is still going, which matters because
a parked run never exits on its own, and the deadline bounds the run itself.

Neither is spelled the usual way, because **macOS ships neither `flock` nor
`timeout`** and Aside is macOS-only. On macOS 27.0 arm64 with Homebrew but without
`coreutils`, `flock`, `timeout`, and `gtimeout` are all absent. That matters more
in a scheduled job than at an interactive prompt: `command not found` exits 127
before `aside` runs, so every tick fails silently into `run.log` and the job looks
like it is scheduled while never once doing its work.

`shlock` and `perl` are both in the macOS base system, so this script runs on a
stock machine. `shlock` is a pid-file lock from the news-server era and it covers
the two cases a scheduled job actually meets, verified rather than assumed:

| Case | Behaviour |
|---|---|
| Previous tick still running | Refuses the lock, so `|| exit 0` skips the tick |
| Previous tick crashed | Sees the dead pid, reclaims the stale lock, proceeds |

The second case is the one to care about. `shlock` validates the recorded pid
instead of only testing whether a file exists, so a run killed by the deadline, or
by a reboot, does not wedge the job permanently the way a plain
`mkdir`-or-lockfile guard would. The `trap` still removes the lock on a clean exit;
the pid check is the backstop for when there is no clean exit.

With `brew install coreutils` the original spelling works as
`flock -n /tmp/yt-digest.lock gtimeout 600 aside exec`. Prefer the base-system form
for anything unattended, since a scheduled job should not depend on a Homebrew
package staying installed.

## Aside remembers on its own

Aside keeps a memory store at `~/.aside/u/0/memory/` and gives the exec agent a
`memory_search` tool whose description begins "Mandatory recall step." With
`memory.enabled` true in `settings.json`, the daemon consolidates what it learned
after enough sessions (`dreamingMinHours`, `dreamingMinSessions`).

The same store is readable from the CLI: `aside memory path` prints the directory
(`~/.aside/u/0/memory` on this account), `aside memory list` and `show <id>` browse
entries, and `aside memory search <query>` runs the recall the agent uses. Add
`--json` to `search` and `list` when the output feeds a program rather than a reader.
Aside's own guidance is to recall before asking: check this store for prior context
before putting the question to the user.

This is not theoretical. After the experiments behind this skill, Aside had
written its own notes into `memory/MEMORY.md`:

> Bash access to user project paths is session-dependent: `read_file` may succeed
> when bash returns `Operation not permitted`.

> Playwright `page.screenshot({ path })` cannot write under `~/.aside/u/0/` (path
> escapes the session directory); write to session tmp, then `cp`.

That second note explains why an agent asked for a screenshot under the account
root will capture to session tmp and `cp` it across without being told.

The layout is `MEMORY.md` (briefing), `USER.md`, `TAXONOMY.md`, plus `agent/`,
`projects/`, `routines/`, `sites/`, `users/`, `episodic/`. It is a real directory
under the account root, so you can read it yourself - but never write into it. Aside
owns these files and consolidates them on its own schedule; an outside write fights
that. When a run should remember something durably, say so in the exec prompt and let
the agent record it. Keep your own job bookkeeping in `jobs/` instead, which is yours.

There is plenty of room in it. A store in active daily use measured 7.4MB with 217
entries in `memory-index.json`, a month of `episodic/` day files, and ten
per-site notes, which is nothing against the disk. The tunables that matter are
in `settings.json`:

```json
"memory": { "enabled": true, "episodicRetentionDays": 0,
            "dreamingMinHours": 24, "dreamingMinSessions": 5 }
```

`episodicRetentionDays: 0` keeps day files indefinitely; consolidation waits for
both 24 hours and 5 sessions before it runs, so a job firing a few times a day
feeds it at a comfortable rate. Treat capacity as a non-issue and spend the effort on
giving Aside facts worth recalling instead of pruning what it already kept.

Practical consequence: repeated jobs get better over time without you threading a
session through them. Let the memory store hold what is generally true, and keep
job-specific bookkeeping in your own `jobs/` files where you control it.

## Scheduling on macOS

`cron` runs with a thin `PATH` and outside the GUI session; Aside needs the app
and a real browser. A user LaunchAgent in `~/Library/LaunchAgents/` runs in the
logged-in GUI context and is the better fit. Call `aside` by absolute path either
way.

The run assumes the Aside app is running and the relevant sites are still signed
in. Sessions do expire, so a job that logs in should either verify it is signed in
first or report the failure clearly rather than silently producing nothing.

## Why the clauses matter more here

Nobody is at the keyboard. A prompt that invites a question ends the run with the
question unanswered, a denied path is skipped without an error exit, and the
scheduler cheerfully starts another one on the next tick. The three standing
clauses plus a deadline plus a lock are what keep an unattended job from turning
into a pile of stuck processes. On macOS that means `perl -e 'alarm ...'` and
`shlock`, not `timeout` and `flock`, neither of which the system provides.
