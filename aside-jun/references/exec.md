# Delegate a task to Aside's agent

Use `aside exec` when the next action needs judgment, login handling, or an Aside
skill such as dev-visualizer. Known independent batches can run directly through
[aside-codemode](codemode.md). Delegating does not add authority to post, purchase,
change accounts, configure tools or modify files outside the requested scope.

## Resolve the execution context

Read current `aside exec --help`, identify the requested host and account, and
resolve that account's absolute root. Read [macOS](host-macos.md) or
[Windows](host-windows.md) for CLI discovery and the host deadline. Those files
contain historical full-access examples; choose permission mode for this task,
not by copying the example. Paths on a remote host belong to that host.

Guard is the CLI default. Use it where the task fits existing access. Full access
may be selected for already authorized paths when necessary; it is not a remedy
for missing user authorization. A prompt fence is an instruction, not an enforced
filesystem boundary. Do not use another tool to route around a policy denial.

## Construct a bounded prompt

Name the exact target URL or input paths, requested action, output format and
completion evidence. Append clauses like these, replacing placeholders with real
absolute paths on the selected host:

```text
Read only these task inputs: <authorized-input-paths-or-URLs>.
Write and edit output files only under <selected-account-artifact-directory>.
Do not modify other local files or change account, permission, or tool settings.
Report completed steps, failures, any side effects, and exact output paths.
Do not ask questions from this noninteractive run. If a required human approval,
MFA, vault unlock or missing input blocks the task, report the exact step and stop.
Choose among already-authorized routes only; do not enlarge the task to continue.
```

For a read-only task explicitly forbid sending, submitting or editing. For an
artifact task name the installed skill and preserve the user's format/template.
Create output subdirectories when necessary; never pass literal `~` to Aside's
file APIs. Native REPL and exec file roots differ.

## Run under a host deadline

On macOS, after resolving the CLI, account, host, mode and prompt:

```bash
/usr/bin/perl -e 'alarm shift; exec @ARGV' 300 "$ASIDE" \
  --account "$ASIDE_ACCOUNT" --host "$ASIDE_HOST" \
  exec --permission "$ASIDE_PERMISSION" -- "$PROMPT"
```

Use the Windows wrapper in [host-windows.md](host-windows.md) on Windows; a bare
`timeout` there sleeps rather than wrapping a process. The historical wrappers
use exit 142 for their deadline. The number 300 is an example duration, not a
universal task budget. A deadline ending the CLI does not undo work already done
or prove the remote agent stopped.

Use the caller's managed background execution where available, capture its
process handle, and poll that handle with bounded waits. Keep it separate from
Aside's session ID. Omit a model override unless the task requests one or the
configured provider fails; verify current help before specifying routed models.

## Continue or stop the actual session

The CLI prints the Aside session ID. Current control commands include:

```bash
aside session resume <id> "Continue with the verified remaining work"
aside session steer <id> "Report what is blocking you and stop"
aside session queue <id> "After this step, report the output paths"
aside session stop <id>
```

Reapply the intended account/host using the installed CLI's supported global
options. Omitting the resume prompt opens an interactive shell, so unattended
calls must supply it. `steer` interrupts the current step; `queue` waits for it.
Do not use the obsolete `--session` example still present on some web pages.
Inspect current help before using any model override or undocumented logging flag
on resume. Logs can contain private browser content.

`aside settings save-sessions true` exposes later CLI sessions in the chat list;
it is an optional settings change, not routine preflight. The 15-minute purge
observed on 1.26.902 is historical, not a current guaranteed retention SLA. Keep
long-running task checkpoints in authorized files and see [scheduling](scheduling.md)
when the user actually requests recurrence.

## Verify the outcome before retrying

Aside CLI has historically exited zero for denied file tools and REPL failures.
Read the report, denied/failed steps and actual destination state. For files,
check existence, nonempty contents and the requested format; for browser work,
inspect the result on the site. A timeout, stopped stream or uncertain effect
requires reconciliation before retry, because an earlier submit may have landed.

If an operation needs a human gesture, stop with its exact blocker. Do not change
Vault policy or switch accounts to avoid it. Read [credentials](credentials.md)
for current Vault behavior and dated Apple Passwords observations.

For remote execution, verify the artifact on that host and retrieve it through
an already-authorized transfer route before claiming local delivery. Report any
remaining transfer or verification gap explicitly.
