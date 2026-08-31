# 000 - Aside runtime research

Evidence gathered 2026-08-30 by four parallel read-only analysis lanes plus direct
live probing. Section 9 pins the exact CLI and daemon builds analyzed and gives the
reproduction command for every load-bearing claim, including the negative ones.

## 1. Binaries and where the logic actually lives

| Artifact | Role |
|---|---|
| `~/.aside/cli/Aside CLI.app/Contents/MacOS/aside` | 145MB bun bundle. CLI front end only. Version `1.26.810.1915`. |
| `.../Contents/Resources/native/aside-native.node` | 9MB native addon. No permission vocabulary. |
| `Aside.app/.../AsideDaemon/mac-arm64/.../aside-daemon` | Where the agent, tools, permissions, and REPL scope are implemented. |

The CLI binary contains no permission vocabulary at all. Searching it for
`permission_mode`, `full-access`, `writableRoots`, or `outsideWrite` returns only an
unrelated Commander parser sentinel. All authorization is daemon-side.

## 2. The hang mechanism (root cause)

Three separate hang classes share one cause. The daemon's permission check, on an
`ask` verdict, calls:

```js
xn.suspend("approval", ...)   // waits for a user verdict
```

The CLI, meanwhile, awaits `client.sendMessage()`, which waits on
`pendingRun.promise` with **no timeout**. That promise resolves only in
`#finishRun()`, reached on `agent_end`, `agent_error`, interruption, or transport
failure. A suspended approval emits none of those.

The CLI protocol can send exactly `prompt`, `continue`, `steer`, `queue`, and
`interrupt`. There is **no permission-answer and no question-answer command**. The
event renderer has no `ask_user_question` branch either; it prints
`tool_execution_start` generically and then waits for a result that never comes.

So the chain is: daemon suspends -> CLI has no way to answer -> daemon emits no
terminal event -> CLI waits forever. Only the shell timeout ends it.

`ask_user_question`'s own description confirms the design: "The session will pause
until the user responds."

## 3. No escape hatch exists

Confirmed by exhaustive option-registration extraction. There is no
non-interactive, auto-approve, auto-deny, JSON-output, timeout, or headless flag.
No Aside environment variable changes permission behavior. CLI session creation
reads only `defaultModel` from settings and never reads or writes a permission key.

Two hidden flags do exist, absent from `--help`:

| Flag | Behavior |
|---|---|
| `-t, --thinking <level>` | Alias for `--effort`. Same value set. |
| `--log-dump <path>` | Appends every raw agent event as JSONL. May contain sensitive browser data. |

Because no flag can prevent the suspend, **prevention has to live in the prompt**.
That is the load-bearing conclusion for the skill.

## 4. Session creation payload

```js
trpcClient.sessions.create.mutate({
  accountId,
  trigger: { type: "user", source: "cli" },
  incognito: false,
  ephemeral: true,
  model,
  runtimeConfig: {
    proactiveMode: requestedEffort === "ultrabrowse",
    strictModelSelection: Boolean(options.model || options.provider)
  }
})
```

Two consequences. Passing `-m` or `-p` flips `strictModelSelection` to true, so
omitting the model is not merely a default, it changes selection behavior.
`--effort ultrabrowse` is the only way to set `proactiveMode`.

The CLI sends no roots and no permission mode; the daemon computes them. Observed
in `state.db`: CLI sessions get `permission_mode="guard"`, GUI sessions get
`"full-access"`.

## 5. Live probe results

| Probe | Result |
|---|---|
| exec `write_file` to `~/.aside/u/0/` | Success in ~6s, "Successfully wrote" |
| exec `write_file` to `/tmp` | Hung >100s, no error, no file |
| exec `read_file` on a workspace path | Hung identically. `outsideRead` does NOT fail fast |
| exec `ask_user_question` | Rendered the question, then hung |
| exec download via `chrome.downloads` | Completed. 3808 bytes to `~/Downloads`, zero prompts |
| `aside mcp` stdio initialize+tools/list | Zero bytes on stdout |
| repl `fs` outside roots | Immediate throw, "Path escapes Project and session roots" |

The hang signature is uniform: the tool-call line prints, then total silence. No
error text is ever emitted, so a hang is indistinguishable from slow work.

## 6. Permission internals

`guard` roots observed in `state.db` for CLI sessions:

```
writableRoots  ~/.aside/u/0, +/memory, +/skills, ~/Downloads, ~/Documents,
               ~/.aside/u/0/sessions/<id>, ~/.aside/runtime
readableRoots  ~/.aside/u/0, ~/Downloads, ~/Documents, session dir, ~/.aside/runtime
outsideRead    ask
outsideWrite   ask
```

An `always` approval calls `rememberUserApproval`, adding the containing directory
to the session roots. Unreachable from the CLI, since the approval cannot be
answered.

The daemon injects one of three filesystem prompt strings. CLI guard sessions get:

> "This session has limited filesystem access. Use allowed roots normally. For paths
> outside the current permission policy, request access once instead of retrying
> failing commands."

That instruction is itself the trap: "request access once" is exactly the suspend
that cannot be answered from a CLI.

## 7. REPL is a real Playwright surface

`repl` is not a thin wrapper. `page` carries `goto`, `goBack`, `goForward`,
`reload`, `waitForLoadState`, `waitForURL`, `waitForSelector`, `locator`,
`getByRole`, `getByLabel`, `getByText`, `frameLocator`, `evaluate`, `screenshot`,
`pdf`, `content`, `title`, `frames`, `viewportSize`.

`Locator` carries click, fill, selectOption, check, uncheck, setChecked, clear,
type, press, pressSequentially, hover, dblclick, focus, blur, tap,
scrollIntoViewIfNeeded, setInputFiles, dragTo, dispatchEvent, plus the usual
reads and chaining.

`snapshot(page, opts)` returns `{tree, refs, diff}`. Refs are `e<n>` in the main
frame and `f<n>e<n>` in child frames, resolved via `globalThis.__aside.deref`.
Stale refs throw, so re-snapshot after acting.

The repl fs jail accepts only paths under `cwd`, `accountRoot`, or
`sessionStorageDir`. Registered downloads are readable but never writable.
Relative paths starting `artifacts`, `attachments`, or `tmp` resolve against the
session dir.

## 8. Consequences for the skill

1. Prevention is prompt-side. No flag can save a bad prompt.
2. Reads are as dangerous as writes. Both suspend.
3. A question is an unrecoverable hang, so the no-questions clause is mandatory.
4. Downloads are safe and need no special handling beyond relocation.
5. Omit `-m` by default; passing it changes `strictModelSelection`.
6. repl deserves Playwright-style documentation because that is what it is.

## 9. Reproduction

Artifacts pinned at capture time (2026-08-30):

| Artifact | Version / id |
|---|---|
| CLI `aside --version` | `1.26.810.1915` |
| CLI binary sha256 (first 24) | `bfe96c25ace602370aae97b3` |
| Daemon build analyzed | `1.26.829.1514` (also present: `1.26.827.1029`) |
| Daemon path | `~/Library/Application Support/Aside/AsideDaemon/mac-arm64/<version>/Aside Daemon.app/Contents/MacOS/aside-daemon` |

The daemon updates independently of the CLI, so re-pin both before trusting any
claim below on a later install.

### Permission model and roots

```bash
python3 -c "import sqlite3,json;c=sqlite3.connect('file:$HOME/.aside/u/0/state.db?mode=ro',uri=True);\
cols=[r[1] for r in c.execute('PRAGMA table_info(sessions)')];\
row=dict(zip(cols,c.execute('select * from sessions order by rowid desc limit 1').fetchone()));\
print(row['permission_mode']); print(json.loads(row['permission'])['files'])"
```

CLI-triggered rows report `guard`; GUI rows (`trigger.source` of `sidepanel`,
`new-tab`, `tasks-page`) report `full-access`.

### The suspend call and the untimed promise

```bash
DAEMON="$HOME/Library/Application Support/Aside/AsideDaemon/mac-arm64/1.26.829.1514/Aside Daemon.app/Contents/MacOS/aside-daemon"
rg -aUo -m1 'async function checkPermission.*?function permissionRequestToRule' "$DAEMON"
rg -aUo -m1 'function describeFilesystemAccess.*?async function buildSystemPrompt' "$DAEMON"
```

The first recovers the `ask` branch calling `xn.suspend("approval", ...)` and the
`always` branch calling `rememberUserApproval`. The second recovers the three
filesystem prompt strings, including the "request access once" text quoted in
section 6.

```bash
CLI="$HOME/.aside/cli/Aside CLI.app/Contents/MacOS/aside"
dd if="$CLI" bs=1 skip=103978500 count=11500 2>/dev/null | strings -n 2
dd if="$CLI" bs=1 skip=104136700 count=6500  2>/dev/null | strings -n 2
```

The first shows `sendMessage()` awaiting `pendingRun.promise` and `#finishRun()`
resolving it. The second shows `runExec()` and the `sessions.create.mutate`
payload quoted in section 4. Offsets are build-specific; on a different build,
locate them with `rg -aUo -m1 'async function runExec.*?createExecSession' "$CLI"`.

### Negative claims

These are the strong claims and the commands that establish them.

```bash
# No approval-answer verb in the CLI protocol (only prompt/continue/steer/queue/interrupt)
strings -n 8 "$CLI" | sed -n '333700,333860p'

# No auto-approve / auto-deny / non-interactive / timeout / headless / json flag
strings -n 12 "$CLI" | sed -n '288350,288440p' \
  | rg -in 'json|timeout|headless|non.?interactive|auto.?approve|auto.?deny|yes'

# Complete Aside env var surface (none affect permissions)
strings -n 12 "$CLI" | rg -o 'process\.env\.[A-Za-z_][A-Za-z0-9_]*' | sort -u

# Hidden flags, confirmed live by parser rejection
"$CLI" --thinking __invalid__
"$CLI" exec --log-dump
```

A null result from a `strings` scan is weaker evidence than a positive match: it
shows the token is absent from the extracted region, not that the capability cannot
exist. The hidden-flag claims are stronger because the parser was made to reject a
bad value, which proves the option is registered.

### Live probes

Each hang probe ran as `timeout N aside exec "<single instruction>"` with output
redirected to a file, then the file and the target path were both inspected. The
write-inside control used the identical shape, differing only in the path:

```bash
timeout 180 aside exec 'Use write_file to create ~/.aside/u/0/_probe.txt \
with content ok. Then bash: ls -la that path. Report the ls output verbatim.' \
  > /tmp/probe_inside.txt 2>&1          # completed ~6s, file created

timeout 200 aside exec 'Use write_file to create /tmp/_probe_outside.txt with \
content ok. If denied, report the exact error text. Do not retry, do not use bash, \
do not ask me anything.' > /tmp/probe_outside.txt 2>&1   # hung to timeout, no file
```

The read probe substituted `read_file` on a workspace path; the question probe
instructed the agent to call `ask_user_question`. Both produced the same shape: the
tool-call line, then nothing.

The download probe used `chrome.downloads` against a public raw URL and completed
with `state: complete`, 3808 bytes, and no prompt.

The repl jail check is cheap and safe to re-run:

```bash
aside repl "try{fs.resolvePath('/etc/passwd')}catch(e){console.log(e.message)}"
```

## 10. Correction: bash is not permission-gated

A later probe round revised section 2. The daemon's `FILE_TOOL_CALLS` map contains
only `read_file`, `edit_file`, and `write_file`; `bash` is not in it and therefore
never reaches the `ask` verdict that suspends.

```bash
D="$HOME/Library/Application Support/Aside/AsideDaemon/mac-arm64/1.26.829.1514/Aside Daemon.app/Contents/MacOS/aside-daemon"
rg -aUo -m1 'FILE_TOOL_CALLS=.{0,220}' "$D"
rg -aUo -m1 'sandbox-exec.{0,300}' "$D"    # -> SEATBELT_BASE_POLICY=`(version 1) ...
```

`bash` is instead confined by `sandbox-exec` with a Seatbelt profile, which denies
instead of asking. Measured with both root lists empty, a single bash command was
denied on a workspace path (`Operation not permitted` on stderr) while
simultaneously reading `/etc/hosts` and writing `/tmp`, and the run completed
normally rather than hanging.

The repl surface confirms the split from the other direction: `fs.resolvePath`,
`fetch('file://...')`, and `openTab('file://...')` all fail fast, the last with
"Cannot navigate to a file URL without local file access." No repl global provides
shell access (`bash`, `exec`, `spawn` are all undefined there).

So the hang is specific to the three file tools plus `ask_user_question`, and the
skill should route uncertain paths to `bash`.
