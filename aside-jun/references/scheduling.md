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

## Sessions expire after 15 minutes

CLI-created sessions are ephemeral. The daemon hardcodes:

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
sends `ephemeral: true` at session creation, the app does not.

So `--session` works for a quick follow-up within the window and not for
scheduling. Do not build a cron job around resuming yesterday's session.

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
yourself; see the hang section of the main skill.

There is also nothing useful to stash in the account root on the session's behalf.
A session lives in `state.db` under a daemon-managed id, not in a file you can save
and reload, so writing a session handle into `~/.aside/u/0/` buys you a string that
stops resolving fifteen minutes later. Scripts and state files there are worth
keeping; session ids are not.

## Carry state in files, not sessions

Each scheduled run should be independent, reading what it needs from disk and
writing back what the next run should know. `~/.aside/u/0/` is inside the writable
roots, so the file tools work there without any permission detour.

```bash
#!/bin/bash
JOB=~/.aside/u/0/jobs/youtube-digest
mkdir -p "$JOB"

flock -n /tmp/yt-digest.lock timeout 600 aside exec "$(cat <<EOF
Read $JOB/state.md for what you already handled and skip anything listed there.
Do today's work, append what you handled to $JOB/state.md, and write the output to
$JOB/$(date +%F).md.

Use read_file, write_file and edit_file only under ~/.aside/u/0/. For any other
local path use the bash tool instead - never the file tools.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop.
EOF
)" >> "$JOB/run.log" 2>&1
```

`flock -n` skips the run when the previous one is still going, which matters
because a hung run never exits on its own. `timeout` bounds it. Both are required,
not optional, for unattended execution.

## Aside remembers on its own

Aside keeps a memory store at `~/.aside/u/0/memory/` and gives the exec agent a
`memory_search` tool whose description begins "Mandatory recall step." With
`memory.enabled` true in `settings.json`, the daemon consolidates what it learned
after enough sessions (`dreamingMinHours`, `dreamingMinSessions`).

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
under the account root, so you can read it yourself, and a scheduled job can write
durable facts into `projects/` for later runs to recall.

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
feeds it at a comfortable rate. Treat capacity as a non-issue and spend the effort
on writing memories worth recalling instead of pruning them.

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

Nobody is at the keyboard. A prompt that invites a question produces a process
that waits forever, and the scheduler cheerfully starts another one on the next
tick. The three standing clauses plus `timeout` plus `flock` are what keep an
unattended job from turning into a pile of stuck processes.
