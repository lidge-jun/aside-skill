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
# grant
aside repl "const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); \
n.files.readableRoots=['<abs-path>']; aside.settings.set('permission',n); \
console.log(JSON.stringify(aside.settings.get('permission').files))"

timeout 300 aside exec "<task using that path> <the three clauses>"

# restore
aside repl "const c=aside.settings.get('permission'); const n=JSON.parse(JSON.stringify(c)); \
n.files.readableRoots=[]; n.files.writableRoots=[]; aside.settings.set('permission',n); \
console.log(JSON.stringify(aside.settings.get('permission').files))"
```

Verified: with `~/Developer/.../700_projects` granted this way, `read_file` on a
file there returned its contents immediately instead of hanging. Note
`settings.set` returns `undefined` even on success, so read the value back rather
than trusting the return.

Three cautions. Roots are read at session creation, so grant before launching and
never mid-run. Always restore afterwards, in the same turn, so a broad grant does
not outlive the task. And widening the roots is a change to the user's security
posture: do it when the task requires that path, tell the user which path you
granted and that you restored it, and ask first when the scope is broad
(`/Users/jun`, `/`) rather than a specific directory.

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

Reach for **repl** when you already know what to do. It is a Playwright-style
surface and you control every step. It is also the safer choice for file work,
because the repl filesystem throws immediately on a bad path instead of hanging.

If a task is mostly mechanical with one authenticated step, do the authenticated
part with exec and the rest with repl.

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

Beyond the clauses, a good prompt names the URL instead of describing it, names the
element or value to act on, enumerates what to report back, and says what not to
touch when the task is read-only.

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

Useful options: `--session <id>` continues a healthy run, and
`--effort ultrabrowse` enables proactive mode for flows that must recover from
surprises on their own.

Account selection is deliberately missing from that list. Every path rule here is
written for account `u0`, whose root is `~/.aside/u/0/`. Another account moves the
root to `~/.aside/u/<n>/` and silently invalidates the clauses, turning the safe
path into an outside path that suspends. If another account is genuinely needed,
substitute its root everywhere in the clauses first.

## repl

```bash
aside repl "const p = await openTab('example.com'); console.log(await p.title())"
```

`console.log` is required; a bare expression prints nothing. Scope persists across
one session, and there is no `import`.

The working loop is inspect, act, re-inspect:

```js
const p = await openTab('news.ycombinator.com');
const s = await snapshot(p, { interactive: true });
console.log(s.tree.slice(0, 2000));
await p.locator('a').first().click();
console.log((await snapshot(p, { interactive: true })).diff);
```

Refs go stale as soon as the DOM moves, so snapshot again after acting instead of
reusing an old `e12`. When refs cannot target something, such as canvas, drag
handles, or map pins, fall back to `cua` coordinates.

Full surface: [references/repl-api.md](references/repl-api.md).

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
it inside its root and copy it out yourself. Never widen Aside's roots to reach the
workspace.

`~/.aside/u/0/models.json` and `accounts.json` can hold plaintext credentials.
Never print or commit them.
