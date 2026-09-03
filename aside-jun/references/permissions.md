# Why Aside CLI denies or parks, and what actually prevents it

Background for the rules in SKILL.md. Read this when a rule seems overcautious, or
when a run skipped a step or parked and you need to know whether a retry can help.
Under `guard` it cannot; under `full-access` the step runs.

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

The Sep 2 release note says it plainly: "permission / ask user question tool /
final confirm won't throw an error" (`evidence/aside-discord-changelog-260902.md`).
For a CLI session `ask` is downgraded to deny and the question tool is removed.

The new failure is quieter than the old one. A denied call returns an error string
the agent reads; it then either stops ("I did not try other tools") or finishes the
parts it could. Exit status is 0 either way, so a skipped step is visible only in
the transcript. That is why SKILL.md now opens the session with `--permission full-access` and
turns the first prompt clause into a write fence instead of a tool fence.

## The permission flag

```bash
aside exec --permission full-access "<prompt>"   # default recommendation
aside exec --permission guard "<prompt>"         # same as omitting the flag
aside exec --permission ask "<prompt>"           # accepted, but normalizes to guard on 1.26.902
```

`full-access` is the mode name GUI sessions carry in `state.db`
(`permission_mode`). From the CLI it let `read_file` reach a workspace path that
`guard` had denied (probe B); other tools and paths were not exercised, so treat
it as "the file tools are no longer fenced" rather than as a proof of parity with
the window. Say in the prompt what a read-only task must not touch and keep
Aside's own output under `~/.aside/u/0/`.

`guard` fits a task that must not be able to reach the workspace and can afford
a skipped step; check the transcript for `blocked by policy` afterwards.

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
the reason SKILL.md keeps the three clauses even with `full-access` as the default.

## The daemon's own instruction makes it worse

Guard sessions receive this injected system prompt text:

> "This session has limited filesystem access. Use allowed roots normally. For
> paths outside the current permission policy, request access once instead of
> retrying failing commands."

"Request access once" is precisely the suspend that a CLI cannot answer, and on
1.26.902 it is the call that gets denied and skipped. The agent is being told to do
the thing that parks or drops its work, so the exec prompt has to override that
instruction explicitly.

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

Not every tool goes through the permission check. The daemon's `FILE_TOOL_CALLS`
gate maps exactly three tools into it:

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

The same workspace path through `read_file` hung indefinitely on that build and is
denied by policy on 1.26.902.

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

## Granting a path on purpose

This is the narrow alternative to `--permission full-access`: use it when one
directory must be reachable and the rest of the filesystem must not be. The steps
are unchanged on 1.26.902, and the clause variants below are the `guard`-mode
fence, not the write fence SKILL.md uses under `full-access`.

When the task genuinely needs a specific outside path, widen the roots first
rather than hoping. `aside.settings.set` writes the account permission config, and
a session created afterwards picks it up:

```bash
# 1. save what is already configured - do not skip this
# 2>/dev/null drops the CLI's timing line; head -1 keeps just the JSON
aside repl "console.log(JSON.stringify(aside.settings.get('permission').files))" \
  2>/dev/null | head -1 > /tmp/aside-roots.json
cat /tmp/aside-roots.json

# 2. grant, adding to the saved lists rather than replacing them.
# Grant reads only, or reads and writes - but match what the clause allows.
aside repl "const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); \
n.files.readableRoots=[...n.files.readableRoots,'<abs-path>']; \
n.files.writableRoots=[...n.files.writableRoots,'<abs-path>']; \
aside.settings.set('permission',n); \
console.log(JSON.stringify(aside.settings.get('permission').files))"

# 3. run, with the granted-root variant of the clauses
timeout 300 aside exec "<task using that path> <clauses, first one naming both roots>"

# 4. restore the saved values, not empty lists
aside repl "const saved=$(cat /tmp/aside-roots.json); \
const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); \
n.files.readableRoots=saved.readableRoots; n.files.writableRoots=saved.writableRoots; \
aside.settings.set('permission',n); \
console.log(JSON.stringify(aside.settings.get('permission').files))"
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
Use read_file, write_file and edit_file only under ~/.aside/u/0/ and <abs-path>. For
any other local path use the bash tool instead - never the file tools.
```

For a read-only task, drop `writableRoots` from step 2 and narrow the clause to
match:

```text
Use read_file only under ~/.aside/u/0/ and <abs-path>, and write_file and edit_file
only under ~/.aside/u/0/. For any other local path use the bash tool instead - never
the file tools.
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
output under `~/.aside/u/0/` and Codex, which has full filesystem access, copies it
wherever it belongs.
