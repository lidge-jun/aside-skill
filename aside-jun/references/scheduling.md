# Scheduled runs and continuity

`aside exec` is an ordinary CLI process, so any scheduler can drive it. What needs
care is state: CLI sessions expire quickly, and the run has to be safe to launch
when nobody is watching.

## Put exec in the scheduler directly

There is nothing to build on top of this. Aside has no job runner of its own worth
wiring up, and there is no session to keep warm between ticks. A cron line or a
LaunchAgent that calls `aside exec` with a full prompt is the macOS design;
Task Scheduler is the Windows design. Recipes are in those sections. The path
to the CLI is `$HOME/.local/bin/aside` on macOS and `aside.exe` under
`%LOCALAPPDATA%\Aside\CLI\` on Windows. `~/.aside/cli` has no `bin/` on either
platform.

Each tick is a complete run that starts fresh, does the work, and exits. The only
things it needs from the outside are a deadline, a lock, and a prompt that cannot
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
build a scheduled job around resuming yesterday's session.

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
writing back what the next run should know. The account root (`$HOME/.aside/u/0`
on macOS, `%USERPROFILE%\.aside\u\0` on Windows) is inside the writable roots,
so the file tools work there without any permission detour. Write that path as an
absolute string in the prompt; `~` is a literal directory name on Windows.

A lock and a deadline are both required, not optional, for unattended execution:
the lock skips a tick while the previous one is still going, which matters because
a parked run never exits on its own, and the deadline bounds the run itself.
Sentinel exit code is 142 on every OS and shell. Job scripts live in the macOS
and Windows sections below.

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
way: `$HOME/.local/bin/aside` (measured; `~/.aside/cli` has no `bin/`).

The run assumes the Aside app is running and the relevant sites are still signed
in. Sessions do expire, so a job that logs in should either verify it is signed in
first or report the failure clearly rather than silently producing nothing.

```cron
# macOS / bash
0 9 * * * /Users/<account>/.local/bin/aside exec --permission full-access -- "<prompt with the three clauses>" >> /Users/<account>/.aside/u/0/jobs/digest/run.log 2>&1
```

LaunchAgent `ProgramArguments` is the same job, two interpreters:

```xml
<!-- macOS / bash -->
<ProgramArguments>
  <string>/bin/bash</string>
  <string>/Users/<account>/.aside/u/0/jobs/youtube-digest/run.sh</string>
</ProgramArguments>
```

```xml
<!-- macOS / PowerShell -->
<!-- If pwsh is not installed, this cell is the contract; the primitive is the same. -->
<ProgramArguments>
  <string>pwsh</string>
  <string>-NoProfile</string>
  <string>-File</string>
  <string>/Users/<account>/.aside/u/0/jobs/youtube-digest/run.ps1</string>
</ProgramArguments>
```

The macOS base system ships neither `flock` nor a GNU deadline wrapper. On macOS
27.0 arm64 with Homebrew but without `coreutils`, `flock` is absent; a login PATH
may still expose Homebrew `gtimeout`. An unattended job must not depend on that.
`command not found` exits 127 before `aside` runs, so every tick fails silently
into `run.log` and the job looks scheduled while never once doing its work.
`shlock` and `/usr/bin/perl` are in the base system. `shlock` covers the two cases
a scheduled job actually meets, verified rather than assumed:

| Case | Behaviour |
|---|---|
| Previous tick still running | Refuses the lock, so `|| exit 0` skips the tick |
| Previous tick crashed | Sees the dead pid, reclaims the stale lock, proceeds |

The second case is the one to care about. `shlock` validates the recorded pid
instead of only testing whether a file exists, so a run killed by the deadline, or
by a reboot, does not wedge the job permanently the way a plain
`mkdir`-or-lockfile guard would. The `trap` still removes the lock on a clean exit;
the pid check is the backstop for when there is no clean exit.

```bash
# macOS / bash
#!/bin/bash
ASIDE="$HOME/.local/bin/aside"
ACCOUNT="$HOME/.aside/u/0"
JOB="$ACCOUNT/jobs/youtube-digest"
mkdir -p "$JOB"

LOCK=/tmp/yt-digest.lock
/usr/bin/shlock -p $$ -f "$LOCK" || exit 0
trap 'rm -f "$LOCK"' EXIT

PROMPT=$(cat <<EOF
Read $JOB/state.md for what you already handled and skip anything listed there.
Do today's work, append what you handled to $JOB/state.md, and write the output to
$JOB/$(date +%F).md.

Write and edit files only under $ACCOUNT/. Read other local paths only when
this prompt names them, and never modify them.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop.
EOF
)

/usr/bin/perl -e 'alarm shift; exec @ARGV' 600 "$ASIDE" exec --permission full-access -- "$PROMPT" >> "$JOB/run.log" 2>&1
```

```powershell
# macOS / PowerShell
# If pwsh is not installed, this cell is the contract; the primitive is the same.
$aside = "$HOME/.local/bin/aside"
$account = "$HOME/.aside/u/0"
$JOB = "$account/jobs/youtube-digest"
if (-not (Test-Path -LiteralPath $JOB)) {
  New-Item -ItemType Directory -Path $JOB | Out-Null
}

$lock = "/tmp/yt-digest.lock"
& /usr/bin/shlock -p $PID -f $lock
if ($LASTEXITCODE -ne 0) { exit 0 }
try {
  $code = $null
  $day = Get-Date -Format 'yyyy-MM-dd'
  $prompt = @"
Read $JOB/state.md for what you already handled and skip anything listed there.
Do today's work, append what you handled to $JOB/state.md, and write the output to
$JOB/$day.md.

Write and edit files only under $account/. Read other local paths only when
this prompt names them, and never modify them.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop.
"@
  $out = "$JOB/aside-out.txt"
  $err = "$JOB/aside-err.txt"
  $p = Start-Process -FilePath $aside -PassThru -NoNewWindow `
       -RedirectStandardOutput $out -RedirectStandardError $err `
       -ArgumentList @('exec','--permission','full-access','--',$prompt)
  if (-not $p.WaitForExit(600000)) {
    $p.Kill()
    $code = 142
  }
  Get-Content -LiteralPath $out, $err | Add-Content -LiteralPath "$JOB/run.log" -Encoding ASCII
  if ($null -eq $code) { $code = $p.ExitCode }
} finally {
  Remove-Item -LiteralPath $lock -ErrorAction SilentlyContinue
}
exit $code
```

## Scheduling on Windows

Task Scheduler is the Windows host. Configure it as:

- trigger: repeat every N minutes
- run only when the user is logged on
- if the task is already running: Do not start a new instance (that is the native lock)
- the job script calls `aside.exe` by absolute path

The action line is given twice:

```text
# Windows / PowerShell (5.1)
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -File <run.ps1>
```

```text
# Windows / Git Bash
<located bash.exe absolute path> --noprofile --norc <run.sh> --quiet
```

Do not write a bare `pwsh.exe`. schtasks' default PATH contains
`WindowsPowerShell\v1.0` and not PowerShell 7, which is why the job script is
5.1-safe. Do not write `Get-Command bash`: the WindowsApps `bash.exe` is a 0-byte
WSL stub. The locator (host-windows.md) rejects a `WindowsApps` segment, requires
the file name `bash.exe`, and requires length greater than 0. Do not hardcode
`Program Files\Git`.

```powershell
# Windows / PowerShell (5.1 and 7)
# Action: %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -File <run.ps1>
$aside = Join-Path $env:LOCALAPPDATA 'Aside\CLI\current\aside.exe'
if (-not (Test-Path -LiteralPath $aside)) {
  $aside = Get-ChildItem "$env:LOCALAPPDATA\Aside\CLI\versions\*\aside.exe" |
           Sort-Object FullName | Select-Object -Last 1 -ExpandProperty FullName
}
$account = Join-Path $env:USERPROFILE '.aside\u\0'
$JOB = Join-Path $account 'jobs\youtube-digest'
if (-not (Test-Path -LiteralPath $JOB)) {
  New-Item -ItemType Directory -Path $JOB | Out-Null
}

$mutex = New-Object System.Threading.Mutex($false, 'Global\AsideJob-yt-digest')
$taken = $false
try {
  try {
    $taken = $mutex.WaitOne(0)
  } catch [System.Threading.AbandonedMutexException] {
    $taken = $true
  }
  if (-not $taken) { exit 0 }

  $code = 0
  $day = Get-Date -Format 'yyyy-MM-dd'
  $prompt = @"
Read $JOB\state.md for what you already handled and skip anything listed there.
Do today's work, append what you handled to $JOB\state.md, and write the output to
$JOB\$day.md.

Write and edit files only under $account\. Read other local paths only when
this prompt names them, and never modify them.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop.
"@
  $out = Join-Path $JOB 'aside-out.txt'
  $err = Join-Path $JOB 'aside-err.txt'
  $p = Start-Process -FilePath $aside -PassThru -NoNewWindow `
       -RedirectStandardOutput $out -RedirectStandardError $err `
       -ArgumentList @('exec','--permission','full-access','--',$prompt)
  if (-not $p.WaitForExit(600000)) {
    & "$env:SystemRoot\System32\taskkill.exe" /PID $p.Id /T /F | Out-Null
    $code = 142
  }
  Get-Content -LiteralPath $out, $err | Add-Content -LiteralPath (Join-Path $JOB 'run.log') -Encoding ASCII
  if ($code -eq 0) { $code = $p.ExitCode }
} finally {
  if ($taken) { $mutex.ReleaseMutex() }
  $mutex.Dispose()
}
exit $code
```

`Start-Process` does not set `$LASTEXITCODE`; read `$p.ExitCode`. Its
`.StandardOutput` is empty unless redirected. `$p.Kill($true)` does not exist on
Windows PowerShell 5.1 (`Kill` has one overload, 0 parameters). Tree-kill is
`taskkill /PID <id> /T /F`. `-ArgumentList` is a string array; do not join
fragments with a semicolon. Put `--` before the prompt or the CLI reports prose
as unknown flags (measured: `unknown option '-TotalCount'`).

An abandoned mutex is reclaimed automatically. Do not build the task principal
from `$env:USERNAME`; use the token SID
(`[Security.Principal.WindowsIdentity]::GetCurrent().User.Value`).

```powershell
# Windows / PowerShell (5.1 and 7) - register the task
$run = 'C:\Users\<account>\.aside\u\0\jobs\youtube-digest\run.ps1'
$action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -File $run"
$trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 9999)
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$principal = New-ScheduledTaskPrincipal -UserId $sid -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName 'AsideJob-yt-digest' -Action $action -Trigger $trigger -Settings $settings -Principal $principal
```

The Git Bash action uses the same task settings and a different `Exec` line.
`schtasks /Create` cannot set IgnoreNew; set it on the task Settings
(`MultipleInstancesPolicy` = IgnoreNew) or register with the snippet above.

```bash
# Windows / Git Bash
# Action: <located bash.exe absolute path> --noprofile --norc <run.sh> --quiet
# --quiet is passed by the action line; this script has no other mode.
ASIDE="$LOCALAPPDATA/Aside/CLI/current/aside.exe"
[ -x "$ASIDE" ] || ASIDE=$(ls -1 "$LOCALAPPDATA"/Aside/CLI/versions/*/aside.exe | sort | tail -1)
ACCOUNT="$USERPROFILE/.aside/u/0"
JOB="$ACCOUNT/jobs/youtube-digest"
mkdir -p "$JOB"

LOCKDIR="$TEMP/yt-digest.lock"
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$LOCKDIR"' EXIT

PROMPT=$(cat <<EOF
Read $JOB/state.md for what you already handled and skip anything listed there.
Do today's work, append what you handled to $JOB/state.md, and write the output to
$JOB/$(date +%F).md.

Write and edit files only under $ACCOUNT/. Read other local paths only when
this prompt names them, and never modify them.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop.
EOF
)

/usr/bin/timeout --kill-after=5 600 "$ASIDE" exec --permission full-access -- "$PROMPT" >> "$JOB/run.log" 2>&1
rc=$?
if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then rc=142; fi
exit $rc
```

`/usr/bin/timeout` is GNU coreutils 8.32 inside Git Bash. System32's
`timeout.exe` is a sleep, not a wrapper; do not call it, and do not write a bare
name that could resolve there. The wrapper remaps GNU 124/137 to 142 so the
public sentinel stays 142. A `mkdir` lock directory is not reclaimed if the
previous process died without `rmdir`; Task Scheduler's IgnoreNew is the native
lock for an already-running tick.

```bash
# Windows / Git Bash - register the task (IgnoreNew still has to be set on Settings)
schtasks /Create /TN "AsideJob-yt-digest" /SC MINUTE /MO 15 /IT /F /TR "\"<located bash.exe absolute path>\" --noprofile --norc \"C:\\Users\\<account>\\.aside\\u\\0\\jobs\\youtube-digest\\run.sh\" --quiet"
```

## Why the clauses matter more here

Nobody is at the keyboard. A prompt that invites a question ends the run with the
question unanswered, a denied path is skipped without an error exit, and the
scheduler cheerfully starts another one on the next tick. The three standing
clauses plus a deadline plus a lock are what keep an unattended job from turning
into a pile of stuck processes.

On macOS the deadline is `/usr/bin/perl -e 'alarm shift; exec @ARGV'` (exit 142)
and the lock is `shlock`.

On Windows the deadline sentinel is also 142. PowerShell uses `Start-Process
-PassThru` + `WaitForExit(ms)` and `taskkill /T /F`. Git Bash uses
`/usr/bin/timeout` and remaps GNU 124/137 to 142 inside the wrapper. The lock is
a named mutex `Global\AsideJob-<job>` in PowerShell, and a `mkdir` lock
directory in Git Bash. Task Scheduler IgnoreNew is the native lock on
already-running ticks.
