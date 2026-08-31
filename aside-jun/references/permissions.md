# Why Aside CLI hangs, and what actually prevents it

Background for the rules in SKILL.md. Read this when a rule seems overcautious, or
when a session hangs and you need to know whether a retry can help. It cannot.

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

## The three proven classes

| Class | Trigger | Observed |
|---|---|---|
| Write | `write_file` outside the writable roots | Hung past 100s. No error, no file. The same write inside `~/.aside/u/0` finished in ~6s with "Successfully wrote". |
| Read | `read_file` outside the readable roots | Hung identically. `outsideRead: "ask"` does **not** fail fast. |
| Question | `ask_user_question` | Rendered the question, then hung. Its own description says "The session will pause until the user responds." |

## What the guard mode actually allows

CLI-triggered sessions get `permission_mode: "guard"`. GUI sessions get
`"full-access"`, which is why something that works in the Aside window can hang
from the terminal.

```
writableRoots  ~/.aside/u/0, ~/.aside/u/0/memory, ~/.aside/u/0/skills,
               ~/Downloads, ~/Documents,
               ~/.aside/u/0/sessions/<session-id>, ~/.aside/runtime
readableRoots  ~/.aside/u/0, ~/Downloads, ~/Documents,
               session dir, ~/.aside/runtime
outsideRead    ask
outsideWrite   ask
```

Both `ask` values are the trap. Anything outside these roots suspends.

## There is no escape flag

Exhaustively checked against the CLI's option registration. There is no
non-interactive flag, no auto-approve, no auto-deny, no JSON output mode, no
timeout, and no headless flag. No Aside environment variable changes permission
behavior. CLI session creation reads only `defaultModel` and never touches a
permission key.

An `always` approval would call `rememberUserApproval` and widen the session
roots, but it is unreachable from a CLI because the approval cannot be answered.

**Prevention is therefore prompt-side.** That is the entire reason SKILL.md
insists on the three clauses.

## The daemon's own instruction makes it worse

Guard sessions receive this injected system prompt text:

> "This session has limited filesystem access. Use allowed roots normally. For
> paths outside the current permission policy, request access once instead of
> retrying failing commands."

"Request access once" is precisely the suspend that a CLI cannot answer. The
agent is being told to do the thing that hangs it, so the exec prompt has to
override that instruction explicitly.

## Two hidden CLI flags

Absent from `--help`, present in the parser:

| Flag | Behavior |
|---|---|
| `-t, --thinking <level>` | Alias for `--effort`. Same values. |
| `--log-dump <path>` | Appends every raw agent event as JSONL. Useful for diagnosing a hang after the fact. May contain sensitive browser data. |

`--log-dump` is the one genuinely useful debugging affordance: if a session hung
and you need to know which tool call suspended, re-run with it and read the last
event.

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

## bash is governed by a different mechanism

Not every tool suspends. The daemon's `FILE_TOOL_CALLS` gate maps exactly three
tools into the permission check:

```js
FILE_TOOL_CALLS = {
  read_file:  xn => typeof xn?.path === "string"      ? { mode: "read",  path: xn.path } : null,
  edit_file:  xn => typeof xn?.path === "string"      ? { mode: "write", path: xn.path } : null,
  write_file: xn => typeof xn?.file_path === "string" ? { mode: "write", path: xn.file_path } : null,
}
```

`bash` is absent from that map, so it never reaches the `ask` verdict and never
suspends. It is confined instead by an OS sandbox: the daemon shells out through
`sandbox-exec` with a `SEATBELT_BASE_POLICY`, which **denies** rather than asks.

The practical difference, measured in one command with the account's
`readableRoots`/`writableRoots` both empty:

```
bash: head -1 ~/<a-project>/AGENTS.md ; head -2 /etc/hosts
  -> stderr: head: .../AGENTS.md: Operation not permitted
  -> stdout: ##
             # Host Database
  -> run continued normally, no suspend

bash: printf ok > /tmp/_probe.txt && ls -la /tmp/_probe.txt
  -> -rw-r--r--@ 1 <user> wheel 2 ... /tmp/_probe.txt
  -> file really created
```

The same workspace path through `read_file` hangs indefinitely.

Two consequences worth holding onto. First, `bash` is the right tool when a path
might be outside the roots, because a visible denial is strictly better than a
silent deadlock. Second, the Seatbelt boundary is not the same boundary as the
permission roots: `/etc/hosts` and `/tmp` were reachable while a workspace file was
not, so do not assume "bash works" means "bash reaches everything."

A caveat on provenance: an earlier run of these same probes, taken while the
account had the whole home directory temporarily added to both root lists, showed `bash`
reading the workspace file successfully. Re-running after that setting was removed
produced the denial above. So the Seatbelt profile does track the configured roots
to some degree; what it does not do is ask.
