# Why Aside CLI denies or parks, and what actually prevents it

Background for the rules in SKILL.md. Read this when a rule seems overcautious, or
when a run skipped a step or parked and you need to know whether a retry can help.
Current invocation choices live in [exec.md](exec.md). Use only the task's
already-authorized scope. Guard denial is not permission to switch tools or
widen access. Full access can remove a file-tool restriction but cannot guarantee
completion or grant authority. The mechanism and probe tables below are dated
historical evidence; see [compatibility](compatibility.md).

The code blocks below reproduce old probes. They are diagnostic records, not
instructions to bypass a denial with bash or automatically grant roots. For a
current task follow [exec.md](exec.md); any configuration grant requires the
existing task's authorization and must remain scoped.

## The mechanism

Aside's daemon runs a permission check before every tool call. When a check returns
`ask`, the daemon calls:

```js
xn.suspend("approval", ...)
```

and waits for a verdict from a human.

Meanwhile the CLI is inside `client.sendMessage()`, awaiting `pendingRun.promise`.
That promise has **no timeout**. It resolves only in `#finishRun()`, which runs on
`agent_end`, `agent_error`, an interrupt, or transport failure. A suspended
approval produces none of those events.

The CLI protocol carries exactly five verbs: `prompt`, `continue`, `steer`,
`queue`, `interrupt`. **None of them can answer a permission request or a
question.** The event renderer has no branch for approvals either; it prints
`tool_execution_start` and then waits for a result that will never arrive.

The result is a deadlock with no error text. The tool-call line prints, then
silence, until the shell timeout kills the process. A hang is indistinguishable
from slow work by looking at output.

## What changed in 1.26.902

The suspend path above is still in the daemon bundle (its strings are present in
1.26.902.1713); whether the Aside window still uses it was not probed. A CLI
session no longer reaches it under any `--permission` value. Measured on CLI
`1.26.902.1732` with daemon `1.26.902.1713`, guard config untouched
(`outsideRead`/`outsideWrite` both `ask`):

| Probe | Result | Log |
|---|---|---|
| `read_file` on a workspace file, default mode | `Permission denied: read '<path>' is blocked by policy` after 4.7s, run exits 0 | `evidence/probe-A-guard-readfile.log` |
| `write_file` to `/tmp` and to `~/.aside/u/0` in one run | outside denied by policy, inside `Successfully wrote`, run exits 0 | `probe-W-writefile.log` |
| `ask_user_question` | not in the session's tool catalog; the agent says so and exits 0 | `probe-C-askuser.log`, `probe-Q-askuser2.log` |
| `read_file` on the same workspace file with `--permission full-access` | contents returned in 4.2s | `probe-B-full-readfile.log` |
| `bash head` on the workspace file and `cat /etc/hosts` | both succeeded (`sandbox.enabled` false on this install) | `probe-D-bash-outside.log` |

The `bash` row is the macOS 1.26.902 probe (`permission.sandbox.enabled` false).
Windows 1.26.906 has `permission.sandbox.enabled` true; under `guard` the shell
tool deadlocks and prints no denial. File-tool denials match on both platforms;
the shell tool does not. See the platform branch below.

The Sep 2 release note says it plainly: "permission / ask user question tool /
final confirm won't throw an error" (`evidence/aside-discord-changelog-260902.md`).
For a CLI session `ask` is downgraded to deny and the question tool is removed.

The new failure is quieter than the old one. A denied call returns an error string
the agent reads; it then either stops ("I did not try other tools") or finishes the
parts it could. Exit status is 0 either way, so a skipped step is visible only in
the transcript. The historical full-access recipe removed that observed file-tool denial.
Choose it only for already-authorized scope; prompt clauses are instructions,
not an enforced filesystem fence. Current guidance is in [exec.md](exec.md).

## The permission flag

```bash
aside exec --permission full-access "<prompt>"   # only for already-authorized scope when needed
aside exec --permission guard "<prompt>"         # same as omitting the flag
aside exec --permission ask "<prompt>"           # accepted, but normalizes to guard on 1.26.902
```

`full-access` is the mode name GUI sessions carry in `state.db`
(`permission_mode`). From the CLI it let `read_file` reach a workspace path that
`guard` had denied (probe B); other tools and paths were not exercised, so treat
it as "the file tools are no longer fenced" rather than as a proof of parity with
the window. Say in the prompt what a read-only task must not touch and keep
Aside's own output under the account root as an absolute path
(`$HOME/.aside/u/0/` on macOS, `%USERPROFILE%\.aside\u\0\` on Windows).
`~` is not expanded on Windows: `write_file` reports `Successfully wrote` and
creates a directory literally named `~`.

`guard` fits a task that must not be able to reach the workspace and can afford
a skipped step; check the transcript for `blocked by policy` afterwards.
On Windows, `guard` cannot afford a `bash` call: that tool deadlocks.
`full-access` is the requirement for any Windows run that will use the shell tool.

`ask` is accepted by CLI 1.26.902 but normalizes to Guard, exactly like `guard`:
the help text says "--permission ask and --permission guard are the same", and
outside-root file calls fail fast with `blocked by policy` and do not suspend
(`evidence/probe-S4-suspension.log`). Genuine approval behaviour in the Aside window
was not verified by this probe. If a run does park on something else (a
credential handshake, a passkey), `aside session steer <id>` or `stop <id>` is the
way out.

## The three classes, as they behaved through 1.26.831

| Class | Trigger | Observed |
|---|---|---|
| Write | `write_file` outside the writable roots | Hung past 100s. No error, no file. The same write inside `~/.aside/u/0` finished in ~6s with "Successfully wrote". |
| Read | `read_file` outside the readable roots | Hung identically. `outsideRead: "ask"` does **not** fail fast. |
| Question | `ask_user_question` | Rendered the question, then hung. Its own description says "The session will pause until the user responds." |

On 1.26.902 each of these returns an error instead; see above.

## What the guard mode actually allows

CLI-triggered sessions get `permission_mode: "guard"` unless `--permission` says
otherwise. GUI sessions get `"full-access"`, which is why something that works in
the Aside window was denied (or, through 1.26.831, hung) from the terminal.

```
writableRoots  ~/.aside/u/0, ~/.aside/u/0/memory, ~/.aside/u/0/skills,
               ~/Downloads, ~/Documents,
               ~/.aside/u/0/sessions/<session-id>, ~/.aside/runtime
readableRoots  ~/.aside/u/0, ~/Downloads, ~/Documents,
               session dir, ~/.aside/runtime
outsideRead    ask
outsideWrite   ask
```

Both `ask` values are the trap. Anything outside these roots suspended through
1.26.831 and is denied on 1.26.902.

On Windows the same keys are present. Account root is
`%USERPROFILE%\.aside\u\0` (`C:\Users\super\.aside\u\0` on the measured
host). Do not treat `%USERPROFILE%\Documents` as Documents: this host's
Documents folder is OneDrive-redirected to `C:\Users\super\OneDrive\문서`.
Resolve the shell folder (`[Environment]::GetFolderPath('MyDocuments')`) rather
than concatenating `Documents` onto the profile path.

## Flags, then and now

Through 1.26.831: exhaustively checked against the CLI's option registration. There is no
non-interactive flag, no auto-approve, no auto-deny, no JSON output mode, no
timeout, and no headless flag. No Aside environment variable changes permission
behavior. CLI session creation reads only `defaultModel` and never touches a
permission key.

An `always` approval would call `rememberUserApproval` and widen the session
roots, but it is unreachable from a CLI because the approval cannot be answered.

1.26.902 added `--permission` (above) and removed `--session`. There is still no
timeout, no JSON output mode, and no auto-answer for a genuine approval prompt.

**Prevention was therefore prompt-side**, and under `guard` it still is. That is
the reason SKILL.md keeps the three clauses even when a task uses authorized `full-access`.

## The daemon's own instruction makes it worse

Guard sessions receive this injected system prompt text:

> "This session has limited filesystem access. Use allowed roots normally. For
> paths outside the current permission policy, request access once instead of
> retrying failing commands."

"Request access once" is precisely the suspend that a CLI cannot answer, and on
1.26.902 it is the call that gets denied and skipped. The agent is being told to do
the thing that parks or drops its work, so the exec prompt has to override that
instruction explicitly.

## Historical hidden flags (1.26.902 parser probes)

These were absent from `--help` but present in the probed parser. Their current
support is unverified; do not use them without verifying the installed build:

| Flag | Behavior |
|---|---|
| `-t, --thinking <level>` | Alias for `--effort`. Same values. |
| `--log-dump <path>` | Appends every raw agent event as JSONL. Useful for diagnosing a hang after the fact. May contain sensitive browser data. |

Inspect the existing session and destination before any retry. Logging can
expose private browser data; do not replay a side effect solely to capture a log.

## Session creation detail

```js
runtimeConfig: {
  proactiveMode: requestedEffort === "ultrabrowse",
  strictModelSelection: Boolean(options.model || options.provider)
}
```

Passing `-m` or `-p` flips `strictModelSelection` to true. Omitting them is not
just a default; it changes how the model is selected. Leave them off unless a
specific model is genuinely required.

## The shell tool is governed by a different mechanism

Not every tool goes through the permission check. The daemon's `FILE_TOOL_CALLS`
gate maps exactly three tools into it:

```js
FILE_TOOL_CALLS = {
  read_file:  xn => typeof xn?.path === "string"      ? { mode: "read",  path: xn.path } : null,
  edit_file:  xn => typeof xn?.path === "string"      ? { mode: "write", path: xn.path } : null,
  write_file: xn => typeof xn?.file_path === "string" ? { mode: "write", path: xn.file_path } : null,
}
```

That map is the same on macOS and Windows. File-tool denials are also the same.
A `guard` `read_file` outside the readable roots returns
`Permission denied: read '<path>' is blocked by policy` after roughly 5s, exit 0,
run continues: 4.7s on macOS 1.26.902 (`evidence/probe-A-guard-readfile.log`) and
the same string on Windows 1.26.906 (`evidence/probe-win-permission.md`, ~4.9s).
`write_file` outside the writable roots is the same shape:
`Permission denied: write '<path>' is blocked by policy`. Exit 0 is not a success
signal; look for `is blocked by policy` in stdout.

`bash` is absent from that map, so it never reaches the `ask` verdict and never
suspends through the file-tool gate. It is confined by an OS sandbox instead, and
the two platforms do not share a sandbox, a denial string, or a failure mode.
The tool is named `bash` on both; on Windows the interpreter is PowerShell
(`Shell: powershell` in the catalog). Bash syntax there fails with a
`ParserError` or fails silently.

### macOS

The daemon shells out through `sandbox-exec` with a `SEATBELT_BASE_POLICY`, which
**denies** rather than asks. On the measured Mac, `permission.sandbox.enabled` is
**false**.

Measured in one command with `readableRoots`/`writableRoots` both empty:

```
bash: head -1 <project>/AGENTS.md ; head -2 /etc/hosts
  -> stderr: head: .../AGENTS.md: Operation not permitted
  -> stdout: ##
             # Host Database
  -> run continued normally, no suspend

bash: printf ok > /tmp/_probe.txt && ls -la /tmp/_probe.txt
  -> -rw-r--r--@ 1 <user> wheel 2 ... /tmp/_probe.txt
  -> file really created
```

The same workspace path through `read_file` hung indefinitely on 1.26.831 and is
denied by policy on 1.26.902, with the cross-platform string above.

Two consequences. Under `guard`, `bash` is the right tool when a path might be
outside the roots, because a visible `Operation not permitted` beats a silently
skipped file-tool step. The Seatbelt boundary is not the permission-root
boundary: `/etc/hosts` and `/tmp` were reachable while a workspace file was not,
so do not assume "bash works" means "bash reaches everything."

A caveat on provenance: an earlier run of these same probes, taken while the
account had the whole home directory temporarily added to both root lists, showed
`bash` reading the workspace file successfully. Re-running after that setting was
removed produced the denial above. So the Seatbelt profile does track the
configured roots to some degree; what it does not do is ask.

### Windows

The daemon bundle also contains `AsideWindowsSandboxHelper` (AppContainer +
JobObject). On the measured Windows 11 host, `permission.sandbox.enabled` is
**true**. That does not produce a Seatbelt-style denial.

Under `guard`, the shell tool does not print `Operation not permitted` or any
other denial string. It deadlocks. The helper process is never spawned. There is
no Windows equivalent of the macOS denial text.

```
bash(title: 'Read README first line',
     command: 'Get-Content -TotalCount 1 C:\\Users\\super\\Developers\\aside\\README.md')
stderr: created new session: X0gol2MDSg8i4O16
```

The run stops there. Four reproductions (manual kill 130s/75s, deadline kill
150s/90s). `Write-Output HELLOPROBE`, which touches no file, deadlocked the same
way at 90s, so this is not a file-policy miss. While hung: CPU 0.20s (not a
spin), `Responding=True`, no `AsideWindowsSandboxHelper.exe` child, no approval
prompt on stdout/stderr/PTY or in the desktop app, session `messages.jsonl` has a
`toolCall` and no matching tool result (`001_parity-ledger-windows.md` §2).

The matching path pair for the macOS probe is
`C:\Windows\System32\drivers\etc\hosts` and `$env:TEMP\_probe.txt`. They were not
reached under `guard`; the session never returned.

The same command with `--permission full-access` finished in 9.6s, exit 0:

```
 > # aside
[powershell] current cwd changed to C:\Users\super\.aside\u\0\
```

A file written under full-access lists as an ordinary NTFS file, not a macOS
`wheel`/`@` line:

```
Get-Item -LiteralPath $env:TEMP\_probe.txt
  -> Mode: -a----  Length: 2
  -> FullName: C:\Users\super\AppData\Local\Temp\_probe.txt
```

Under `guard` on Windows, do not call the `bash` tool. Use the file tools, which
fail fast with the same `Permission denied: ... is blocked by policy` string as
macOS, or run with `--permission full-access`. A host deadline is required:
without one, the hung `bash` call consumes the whole turn.

## Granting a path on purpose

This is the narrow alternative to `--permission full-access`: use it when one
directory must be reachable and the rest of the filesystem must not be. The steps
are unchanged on 1.26.902, and the clause variants below are the `guard`-mode
fence, not the write fence SKILL.md uses under `full-access`.

When the task genuinely needs a specific outside path, widen the roots first
rather than hoping. `aside.settings.set` writes the account permission config, and
a session created afterwards picks it up. Deadline sentinel is 142 on every OS
and shell. On Windows this grant is for the file tools; the `bash` tool still
deadlocks under `guard` even after a grant.

```bash
# macOS / bash
ASIDE="$HOME/.local/bin/aside"
ROOTS=/tmp/aside-roots.json
PROMPT="<task using that path> <clauses, first one naming both roots>"

# 1. save what is already configured - do not skip this
# 2>/dev/null drops the CLI's timing line; head -1 keeps just the JSON
"$ASIDE" repl "console.log(JSON.stringify(aside.settings.get('permission').files))" \
  2>/dev/null | head -1 > "$ROOTS"
cat "$ROOTS"

# 2. grant, adding to the saved lists rather than replacing them.
"$ASIDE" repl "const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); \
n.files.readableRoots=[...n.files.readableRoots,'<abs-path>']; \
n.files.writableRoots=[...n.files.writableRoots,'<abs-path>']; \
aside.settings.set('permission',n); \
console.log(JSON.stringify(aside.settings.get('permission').files))"

# 3. run, with the granted-root variant of the clauses
/usr/bin/perl -e 'alarm shift; exec @ARGV' 300 "$ASIDE" exec -- "$PROMPT"

# 4. restore the saved values, not empty lists
saved_json=$(cat "$ROOTS")
"$ASIDE" repl "const saved=$saved_json; \
const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); \
n.files.readableRoots=saved.readableRoots; n.files.writableRoots=saved.writableRoots; \
aside.settings.set('permission',n); \
console.log(JSON.stringify(aside.settings.get('permission').files))"
```

```bash
# Windows / Git Bash
ASIDE="$LOCALAPPDATA/Aside/CLI/current/aside.exe"
[ -x "$ASIDE" ] || ASIDE=$(ls -1 "$LOCALAPPDATA"/Aside/CLI/versions/*/aside.exe | sort | tail -1)
ROOTS="$TEMP/aside-roots.json"
PROMPT="<task using that path> <clauses, first one naming both roots>"

# 1. save what is already configured - do not skip this
"$ASIDE" repl "console.log(JSON.stringify(aside.settings.get('permission').files))" \
  2>/dev/null | head -1 > "$ROOTS"
cat "$ROOTS"

# 2. grant, adding to the saved lists rather than replacing them.
"$ASIDE" repl "const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); \
n.files.readableRoots=[...n.files.readableRoots,'<abs-path>']; \
n.files.writableRoots=[...n.files.writableRoots,'<abs-path>']; \
aside.settings.set('permission',n); \
console.log(JSON.stringify(aside.settings.get('permission').files))"

# 3. run, with the granted-root variant of the clauses
/usr/bin/timeout --kill-after=5 300 "$ASIDE" exec -- "$PROMPT"
rc=$?
if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then rc=142; fi

# 4. restore the saved values, not empty lists
saved_json=$(cat "$ROOTS")
"$ASIDE" repl "const saved=$saved_json; \
const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); \
n.files.readableRoots=saved.readableRoots; n.files.writableRoots=saved.writableRoots; \
aside.settings.set('permission',n); \
console.log(JSON.stringify(aside.settings.get('permission').files))"
exit $rc
```

```powershell
# macOS / PowerShell
# If pwsh is not installed, this cell is the contract; the primitive is the same.
$aside = "$HOME/.local/bin/aside"
$rootsFile = "/tmp/aside-roots.json"
$prompt = "<task using that path> <clauses, first one naming both roots>"

# 1. save what is already configured - do not skip this
$json = & $aside repl "console.log(JSON.stringify(aside.settings.get('permission').files))" 2>$null |
  Select-Object -First 1
Set-Content -LiteralPath $rootsFile -Value $json -Encoding ASCII
Get-Content -LiteralPath $rootsFile

# 2. grant, adding to the saved lists rather than replacing them.
& $aside repl "const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); n.files.readableRoots=[...n.files.readableRoots,'<abs-path>']; n.files.writableRoots=[...n.files.writableRoots,'<abs-path>']; aside.settings.set('permission',n); console.log(JSON.stringify(aside.settings.get('permission').files))"

# 3. run, with the granted-root variant of the clauses
$out = "/tmp/aside-grant-out.txt"
$err = "/tmp/aside-grant-err.txt"
$p = Start-Process -FilePath $aside -PassThru -NoNewWindow `
     -RedirectStandardOutput $out -RedirectStandardError $err `
     -ArgumentList @('exec','--',$prompt)
if (-not $p.WaitForExit(300000)) {
  $p.Kill()
  $code = 142
} else {
  $code = $p.ExitCode
}

# 4. restore the saved values, not empty lists
$saved = Get-Content -LiteralPath $rootsFile -Raw
& $aside repl "const saved=$saved; const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); n.files.readableRoots=saved.readableRoots; n.files.writableRoots=saved.writableRoots; aside.settings.set('permission',n); console.log(JSON.stringify(aside.settings.get('permission').files))"
exit $code
```

```powershell
# Windows / PowerShell (5.1 and 7)
$aside = Join-Path $env:LOCALAPPDATA 'Aside\CLI\current\aside.exe'
if (-not (Test-Path -LiteralPath $aside)) {
  $aside = Get-ChildItem "$env:LOCALAPPDATA\Aside\CLI\versions\*\aside.exe" |
           Sort-Object FullName | Select-Object -Last 1 -ExpandProperty FullName
}
$rootsFile = Join-Path $env:TEMP 'aside-roots.json'
$prompt = "<task using that path> <clauses, first one naming both roots>"

# 1. save what is already configured - do not skip this
$json = & $aside repl "console.log(JSON.stringify(aside.settings.get('permission').files))" 2>$null |
  Select-Object -First 1
Set-Content -LiteralPath $rootsFile -Value $json -Encoding ASCII
Get-Content -LiteralPath $rootsFile

# 2. grant, adding to the saved lists rather than replacing them.
& $aside repl "const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); n.files.readableRoots=[...n.files.readableRoots,'<abs-path>']; n.files.writableRoots=[...n.files.writableRoots,'<abs-path>']; aside.settings.set('permission',n); console.log(JSON.stringify(aside.settings.get('permission').files))"

# 3. run, with the granted-root variant of the clauses
$out = Join-Path $env:TEMP 'aside-grant-out.txt'
$err = Join-Path $env:TEMP 'aside-grant-err.txt'
$p = Start-Process -FilePath $aside -PassThru -NoNewWindow `
     -RedirectStandardOutput $out -RedirectStandardError $err `
     -ArgumentList @('exec','--',$prompt)
if (-not $p.WaitForExit(300000)) {
  & "$env:SystemRoot\System32\taskkill.exe" /PID $p.Id /T /F | Out-Null
  $code = 142
} else {
  $code = $p.ExitCode
}

# 4. restore the saved values, not empty lists
$saved = Get-Content -LiteralPath $rootsFile -Raw
& $aside repl "const saved=$saved; const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); n.files.readableRoots=saved.readableRoots; n.files.writableRoots=saved.writableRoots; aside.settings.set('permission',n); console.log(JSON.stringify(aside.settings.get('permission').files))"
exit $code
```

Step 1 is not optional. Restoring to `[]` would silently delete roots the user had
configured before you arrived, which is a worse outcome than the hang you were
avoiding.

The round trip was run as written. Saved `{"readableRoots":[],"writableRoots":[]}`,
granted both lists, then an `exec` run wrote and read a file under the granted path:
`write_file` returned `Successfully wrote` and `read_file` returned the contents, in
seconds, with no suspension. Restoring put the original empty lists back.

That is the proof the grant has to cover writes: with the path in `readableRoots`
only, the same `write_file` would have met `outsideWrite: "ask"` and parked (denied,
on 1.26.902). The
spread in step 2 is what makes it additive; assigning a bare array there is the other
bug this sequence exists to avoid.

While a grant is live, the first standing clause has to name the granted path too,
or the prompt forbids the very access you just arranged. The clause and the grant
must cover the same operations: `outsideWrite` stays `ask`, so a path present only in
`readableRoots` is still refused on a write.

```text
Use read_file, write_file and edit_file only under <account-root> and <abs-path>.
<account-root> is an absolute path ($HOME/.aside/u/0 on macOS,
%USERPROFILE%\.aside\u\0 on Windows), never ~.
macOS: for any other local path use the bash tool instead - never the file tools.
Windows: do not call the bash tool under guard; stay on the file tools or use
--permission full-access.
```

For a read-only task, drop `writableRoots` from step 2 and narrow the clause to
match:

```text
Use read_file only under <account-root> and <abs-path>, and write_file and edit_file
only under <account-root>. macOS: for any other local path use the bash tool
instead - never the file tools. Windows: do not call the bash tool under guard.
```

Revert to the plain clause as soon as the grant is restored.

Verified: with a single project directory granted this way, `read_file` on a
file there returned its contents immediately instead of being refused. Note
`settings.set` returns `undefined` even on success, so read the value back rather
than trusting the return.

Three cautions. Roots are read at session creation, so grant before launching and
never mid-run. Always restore afterwards, in the same turn, so a broad grant does
not outlive the task. And widening the roots is a change to the user's security
posture: do it when the task requires that path, tell the user which path you
granted and that you restored it, and ask first when the scope is broad
(a whole home directory, or `/`) rather than a specific directory.

The cheaper move is usually to avoid the grant entirely. Aside can write its
output under the account root as an absolute path and Codex, which has full
filesystem access, copies it wherever it belongs.
