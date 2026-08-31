---
name: aside-jun
description: Drive the Aside browser CLI for work that needs a real signed-in browser - reading pages behind a login, automating multi-step web flows, and delegating browser tasks to Aside's own agent. Use when a session or cookies are required and an HTTP fetch would fail; not for ordinary public-page fetching or local browser QA.
---

# Aside

Aside is a Chromium fork with a built-in browser agent. Its CLI drives that agent
against the user's real, logged-in profile, which makes it the right tool when a
task genuinely needs an existing session: admin consoles, dashboards behind SSO,
DMs, anything where a plain HTTP fetch gets a login wall.

## The one rule that matters

A non-interactive `aside exec` **cannot answer a prompt**. When the Aside agent
tries to touch a path outside its allowed roots, or asks the user a question, the
daemon suspends the run and waits for a human. The CLI has no way to reply, no
timeout of its own, and emits no error. The tool-call line prints and then there is
silence until something external kills it.

Three ways to cause it, all observed:

| Cause | What happens |
|---|---|
| Writing outside `~/.aside/u/0/` | Hangs. The same write inside finishes in seconds. |
| Reading outside the allowed roots | Hangs the same way. Reads are not safer than writes. |
| Asking the user anything | Hangs. The question renders, then nothing. |

That applies to the file tools, `read_file`, `write_file`, and `edit_file`. They go
through a permission check that can suspend.

Still true on CLI `1.26.810.1915` with daemon `1.26.829.1514`, re-verified rather
than assumed. The guard config is unchanged:

```json
{"readableRoots":[],"writableRoots":[],"outsideRead":"ask","outsideWrite":"ask"}
```

`ask` is the mechanism. An exec run told to `read_file` a workspace path printed the
tool-call line and then produced nothing further; the process was still parked when
killed by hand. No flag turns `ask` into `deny`, so the prompt clauses remain the
only prevention.

`bash` does not. It runs under a separate `sandbox-exec` Seatbelt profile that
denies rather than asks, so a blocked path returns
`Operation not permitted` on stderr immediately and the run continues. That makes
`bash` the safe tool for touching an uncertain path, but it is not a permission
bypass: the Seatbelt profile has its own boundary. In one probe `head` on a
workspace file was denied outright while `/etc/hosts` was read and `/tmp` was
written in the same command.

So the rule for exec prompts is blunt: **never let the agent use `read_file`,
`write_file`, or `edit_file` on a path outside `~/.aside/u/0/`.** Tell it to use
`bash` instead. A denial you can see beats a silent deadlock.

### Granting a path on purpose

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
only, the same `write_file` would have met `outsideWrite: "ask"` and parked. The
spread in step 2 is what makes it additive; assigning a bare array there is the other
bug this sequence exists to avoid.

While a grant is live, the first standing clause has to name the granted path too,
or the prompt forbids the very access you just arranged. The clause and the grant
must cover the same operations: `outsideWrite` stays `ask`, so a path present only in
`readableRoots` still suspends on a write.

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
file there returned its contents immediately instead of hanging. Note
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
No flag prevents this. There is no `--yes`, no auto-deny, no timeout option.
Prevention lives in two places: the prompt you write, and a deadline you impose
from outside.

**Always run exec under a host timeout.**

```bash
timeout 300 aside exec "<prompt>"
```

Without it, a hung run holds the shell indefinitely.

A fired timeout kills the CLI, not the work already done. Everything the agent
completed before it suspended still happened: files written inside the allowed
roots, downloads, form submissions, messages sent. **Inspect the real state before
retrying**, or a rerun duplicates a side effect. The only thing that certainly did
not happen is the suspended call itself.

The Aside session survives as `status: suspended`, with `suspension.kind` of
`approval` or `ask-user-question`. It waits for a human who never arrives from a
CLI, so these accumulate rather than clearing themselves. Do not resume one with
`--session` expecting it to continue.

They are also invisible to the ordinary session API: CLI runs are created
`ephemeral`, and `aside.sessions.list()` returns only visible sessions, so it
reports zero while several are parked. Read the database directly instead:

```bash
python3 -c "import sqlite3,json;c=sqlite3.connect('file:$HOME/.aside/u/0/state.db?mode=ro',uri=True);\
print([(r[0], json.loads(r[1])['kind']) for r in c.execute(\
\"select id,suspension from sessions where status='suspended'\")])"
```

Treat that count as a hygiene signal: a growing list means prompts are still
tripping the approval path. Whether a hidden ephemeral session can be answered in
the Aside UI is unconfirmed, so do not rely on clearing them that way.

Retrying the same prompt hangs the same way, so fix the prompt instead.

Read [references/permissions.md](references/permissions.md) when you need the
underlying mechanism, want to confirm whether a path is inside the allowed roots,
or are diagnosing a hang these rules do not explain.

## Choosing a surface

```
exec  -> delegate a task to Aside's agent
repl  -> drive the browser yourself
```

Reach for **exec** when the work needs judgment, a login, or one of Aside's builtin
skills: signing in, navigating an unfamiliar site, reading Gmail or Notion,
handling a CAPTCHA, anything multi-step where the next action depends on what the
last one revealed.

Before delegating anything that has to **sign in**, read
[references/credentials.md](references/credentials.md). Aside's credential layer
has a first-run handshake that hangs a CLI run: Apple Passwords wants a 6-digit
code only a human can read off the screen. That reference covers the one-time
setup, why "Unlock with Touch ID" must stay off, why 1Password is the smoother
choice, and the Importer's EPERM failure. The reliable pattern is that the user
signs in once in the Aside window and `exec` inherits the live session.

Reach for **repl** when you already know what to do. It is a Playwright-style
surface and you control every step. It is also the safer choice for file work,
because the repl filesystem throws immediately on a bad path instead of hanging.

repl shares the signed-in profile, so it is not a private window. A fresh CLI repl
starts with no attached tabs, which reads like an empty browser, but `openTab`
inherits the account's cookies: opening `x.com/home` landed on the signed-in
timeline rather than a login wall, verified against CLI `1.26.810.1915` with daemon
`1.26.829.1514`. If a repl tab does come up signed out on an older build, update
Aside before working around it.

If a task is mostly mechanical with one authenticated step, do the authenticated
part with exec and the rest with repl.

### What repl can automate on its own

repl is more than a DOM driver. Several builtin capabilities are plain globals with
their methods on the prototype, so `Object.keys` shows `{}` and you have to look at
`Object.getPrototypeOf` to see them. Confirmed present in a CLI repl session:

| Global | Reach |
|---|---|
| `twitter` | `getMe`, `getTimeline`, `search`, `tweet`, `reply`, `like`, `sendDm`, `follow`, `getNotifications` |
| `gmail` | `getInbox`, `search`, `getThread`, `openComposer`, `downloadAttachment` |
| `youtube` | `search`, `getMetadata`, `getTranscript`, `getComments` |
| `applePasswords` | `requestAuth`, `verifyAuth`, `listLogins`, `autofillLogin`, `getOtps` |
| `captcha` | `click`, `drag`, `readText` |
| `cua` | `click`, `type`, `scroll`, `keypress`, `getVisibleScreenshot` |
| also | `notion`, `slack`, `linkedin`, `googleDocs`, `googleSheets`, `googleSearch`, `imagegen`, `chrome` |

So a scheduled scrape, a DM, a transcript pull, or a CAPTCHA click needs no exec at
all. Reach for exec when the task needs judgment about what to do next, not merely
the ability to do it.

**Signing in is the exception.** Aside's own credential vault is `passwordManager`,
and it is injected into the `repl` **tool inside an exec run** only - it is
`undefined` in a CLI `aside repl` session. `applePasswords` is the reverse: present
in CLI repl, and its `listLogins` returned `[]` for every site tried even with 319
items in the vault. The practical rule is that a login you want automated goes
through exec, which then uses its repl tool to search the vault and autofill. See
[references/credentials.md](references/credentials.md) for the verified run.

## exec

Every exec prompt ends with these three clauses, used verbatim:

```text
Use read_file, write_file and edit_file only under ~/.aside/u/0/. For any other
local path use the bash tool instead - never the file tools.
Downloading to ~/Downloads is fine; move anything you keep under ~/.aside/u/0/.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop.
```

Assembled:

```bash
timeout 300 aside exec "Go to <url> and <task>. Report <fields>.
Use read_file, write_file and edit_file only under ~/.aside/u/0/. For any other
local path use the bash tool instead - never the file tools.
Downloading to ~/Downloads is fine; move anything you keep under ~/.aside/u/0/.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop."
```

The first clause is the important one, and it is a tool rule rather than a path
rule: the file tools stay inside `~/.aside/u/0/`, and everything else goes through
`bash`. Reading is no safer than writing here, so the clause covers both. Aside's
own system prompt tells the agent to "request access once" for outside paths,
which is precisely the move that deadlocks a CLI run, so the override has to be
explicit.

The third clause overrides Aside's own instruction. Its builtin guidance ends the
login section with "**ASK USER AS THE LAST RESORT**", which is sound advice in the
app window and a deadlock in a non-interactive run: there is no last resort, only a
parked process. Replace it with a ladder that ends in a clean stop:

> Never ask a question from a non-interactive `aside exec` run. The CLI cannot
> answer `ask_user_question`, an approval prompt, Touch ID, a passkey gesture, or a
> macOS Apple Passwords code. Instead, work the routes that are already available:
> the inherited signed-in session, a clearly matching password-manager item, a
> configured external provider, a password or OAuth fallback behind "Try another
> way", an already-available TOTP, or the `captcha` tools. If completion still needs
> a human, do not ask and do not wait. Report the exact blocking screen, what a
> human would have to do, and any side effect already completed, then stop.

Beyond the clauses, a good prompt names the URL instead of describing it, names the
element or value to act on, enumerates what to report back, and says what not to
touch when the task is read-only.

The `~/Downloads` clause is scoped to the exec agent, whose `bash` tool can reach it.
repl `fs` cannot: it sees only the session and project roots. A file the browser
downloaded is still readable through `download.path()`, but within the same
invocation only.

Omit `-m`. Passing a model flips `strictModelSelection` in the session config, so
leaving it off is a behavioral choice rather than laziness. Aside's own settings
pick the model.

Runs take minutes. Start one, capture the session, then poll:

```
exec_command  cmd="timeout 300 aside exec '<prompt>'"  yield_time_ms=30000
write_stdin   session_id=<id>  chars=""  yield_time_ms=120000
```

Empty `chars` polls without typing. If output stops right after a tool-call line
and stays stopped, that is a hang rather than slow work.

The user cannot see the Aside CLI's output, so a long run needs narration: tell them
roughly every 60 seconds what the agent is doing and what it has established. Aside's
own guidance asks for this and it is the difference between a run that looks alive and
one that looks hung.

Useful options: `--session <id>` continues a healthy run, and
`--effort ultrabrowse` enables proactive mode for flows that must recover from
surprises on their own.

`--session` only works for about 15 minutes. CLI sessions are created ephemeral
and the daemon purges them after that, so a later resume fails with
`Session is pending purge`. For anything scheduled or long-running, carry state in
files under `~/.aside/u/0/` instead of threading a session, and let Aside's own
memory store hold what is generally true. See
[references/scheduling.md](references/scheduling.md) before putting `exec` in cron
or a LaunchAgent.

Scheduling needs no machinery beyond that. Point cron or a LaunchAgent straight at
`aside exec` with a full prompt, wrap it in `timeout` and `flock`, and let each
tick be a complete run. Session ids are not worth saving to disk, because they stop
resolving after the purge window. Aside's memory store has room to spare - a store
in daily use sat at 7.4MB with 217 index entries - so let it accumulate what is
generally true and keep per-job bookkeeping in your own files under the account
root.

Account selection is deliberately missing from that list. Every path rule here is
written for account `u0`, whose root is `~/.aside/u/0/`. Another account moves the
root to `~/.aside/u/<n>/` and silently invalidates the clauses, turning the safe
path into an outside path that suspends. If another account is genuinely needed,
substitute its root everywhere in the clauses first.

## repl

```bash
aside repl "const p = await openTab('example.com'); console.log(await p.title())"
```

`console.log` is required; a bare expression prints nothing. There is no `import`
or `require`, and the execution timeout is 120 seconds.

### One invocation is one session

Aside's own guidance says the repl is "a persistent ES2023+ JavaScript environment"
where "top-level `const` and `let` bindings persist." That is true inside a single
invocation and false between them. Measured across two consecutive
`aside repl` calls:

| probe set in call 1 | call 2 |
|---|---|
| `globalThis.MARK` | `undefined` |
| `page` | `null` |
| `tabs.length` | `0` |
| the tab it opened, via `listBrowserTabs()` | gone, the tab was closed |

Two consequences worth designing around. A whole inspect-act-verify flow has to fit
in one call, which is fine because one call can hold an entire flow. And a tab you
need to survive should be opened in the Aside window, then borrowed with
`attachBrowserTab(targetId)`, which detaches instead of closing on exit.

### The working loop

Inspect, act, re-inspect:

```js
const p = await openTab('news.ycombinator.com');
const s1 = await snapshot(p, { interactive: true });
console.log(s1.tree);
await p.locator('a').first().click();
const s2 = await snapshot(p, { interactive: true });
console.log(s2.diff);
```

Print `tree` the first time and `diff` after acting. Never truncate a snapshot with
`slice`, `substring`, or `split`: the ref you need is usually the one that gets cut.
Number them `s1`, `s2` so an earlier tree stays readable.

Refs go stale as soon as the DOM moves, so snapshot again after acting instead of
reusing an old `e12`. Pass a ref straight to `p.locator('e31')` and never splice it
into a CSS selector. When refs cannot target something, such as canvas, drag
handles, or map pins, fall back to `cua` coordinates.

A passkey prompt is usually a fork rather than a wall. Most sites keep a password
fallback behind "Try another way", and an exec agent can take it and finish the
sign-in on its own. Say so in the prompt instead of treating passkeys as fatal.

Files and downloads live inside the session directory: `pwd` is
`~/.aside/u/0/sessions/<session-id>`, so a relative `./artifacts/` path is already
inside the account root. Anything outside the roots throws
`Path escapes Project and session roots: <path>` immediately rather than suspending,
which is the opposite of the exec file tools.

Full surface, including the tab-inspection protocol, the reading-escalation ladder,
download handling, and the service globals:
[references/repl-api.md](references/repl-api.md).

## What Aside already knows

Aside ships skills covering Gmail, Google Docs and Sheets, Notion, Slack, X,
KakaoTalk, iMessage, YouTube, Chrome APIs, seven password managers, CAPTCHA
solving, and document formats, plus a set of site-specific skills for services like
Jira, Linear, GitHub, and Trello. **Only exec can load them.** You cannot invoke one
directly; name it in the prompt and the agent picks it up.

```bash
timeout 300 aside exec "Use the google-sheets skill to read the totals from <url>.
Report each row label and its total.
Use read_file, write_file and edit_file only under ~/.aside/u/0/. For any other
local path use the bash tool instead - never the file tools.
Downloading to ~/Downloads is fine; move anything you keep under ~/.aside/u/0/.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop."
```

Naming the skill usually beats describing the workflow, because several of them
reach an API and never open a tab at all.

The catalog, including which skills are backed by a repl global you could drive
yourself: [references/builtin-skills.md](references/builtin-skills.md). Regenerate
it after an Aside update with `scripts/refresh-builtin-summary.sh`.

## Verify what it tells you

The agent narrates its own success and is sometimes wrong. Confirm independently
before reporting: re-open the page and read the status line, check the file
yourself, run `dig` against the DNS record it claims to have set. Screenshots land
under `~/.aside/u/<account>/sessions/<session>/tmp/` and are real files you can
open.

A first attempt can fail and a retry succeed, so ask for the final state rather
than trusting the first report.

## When something goes wrong

**Silence after a tool call.** That is a hang. Let the timeout end it, then check
the prompt for a path outside `~/.aside/u/0/` or a request that invites a question.
Re-running with the undocumented `--log-dump <path>` flag records every agent event
as JSONL, which shows exactly which call suspended.

**A model error such as `401 Model not supported`.** The account's configured
default model is unavailable. Pass a working model once with `-m`, and tell the
user their Aside default needs updating rather than hardcoding a model into future
calls. Check what is configured with `aside repl "console.log(JSON.stringify(aside.settings.get('defaultModel')))"`.

**`aside mcp` produces nothing.** Expected. It emits no stdout for a plain
initialize over stdio; it is meant to be driven by an MCP client, not probed by
hand.

**Wrong account.** `aside account list` shows which is signed in. If you switch
with `aside account use <id>`, re-confirm with `aside account list` and rewrite
every `~/.aside/u/0/` in your clauses to the new account's root before running
anything, or each prompt now points outside the allowed roots.

## Boundaries

Everything Aside writes belongs under `~/.aside/u/0/`. Codex has full filesystem
access of its own, so when a result needs to reach the workspace, let Aside write
it inside its root and copy it out yourself. Copying out is the default and it is
almost always enough.

Widening the roots is the exception, not a second normal path. Reach for the
grant-run-restore sequence above only when a task genuinely cannot be done any other
way, keep the grant to one specific directory, restore it in the same turn, and tell
the user what you granted. Do not widen the roots merely to save yourself a copy.

`~/.aside/u/0/models.json` and `accounts.json` can hold plaintext credentials.
Never print or commit them.
