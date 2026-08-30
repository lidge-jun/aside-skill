# Scheduled runs and continuity

`aside exec` is an ordinary CLI process, so any scheduler can drive it. What needs
care is state: CLI sessions expire quickly, and the run has to be safe to launch
when nobody is watching.

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

One upside: suspended sessions left behind by a hang are ephemeral too, so they
purge themselves rather than accumulating forever.

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
