---
name: aside
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

No flag prevents this. There is no `--yes`, no auto-deny, no timeout option.
Prevention lives in two places: the prompt you write, and a deadline you impose
from outside.

**Always run exec under a host timeout.**

```bash
timeout 300 aside exec "<prompt>"
```

Without it, a hung run holds the shell indefinitely. When the timeout fires the run
is finished: nothing was written, and re-running the same prompt will hang again.
Fix the prompt rather than retrying. The suspended session stays parked inside
Aside and needs no cleanup, but do not try to continue it with `--session`.

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
Read and write files only under ~/.aside/u/0/ - do not read or write any other
local path, including ~/Documents or anywhere else on my filesystem.
Downloading to ~/Downloads is fine; move anything you keep under ~/.aside/u/0/.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop.
```

Assembled:

```bash
timeout 300 aside exec "Go to <url> and <task>. Report <fields>.
Read and write files only under ~/.aside/u/0/ - do not read or write any other
local path, including ~/Documents or anywhere else on my filesystem.
Downloading to ~/Downloads is fine; move anything you keep under ~/.aside/u/0/.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop."
```

The read clause carries as much weight as the write clause. Guard mode does
technically permit reading `~/Documents` and `~/Downloads`, but naming a single
root keeps the agent from drifting to a neighbouring path that suspends. Aside's
own system prompt tells the agent to "request access once" for outside paths, so
without this override it will do precisely the thing that deadlocks it.

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

Useful options: `--session <id>` continues a healthy run, `--account <id>` picks an
account, and `--effort ultrabrowse` enables proactive mode for flows that must
recover from surprises on their own.

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
Read and write files only under ~/.aside/u/0/ - do not read or write any other
local path, including ~/Documents or anywhere else on my filesystem.
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

**Wrong account.** `aside account list` shows which is signed in, and
`aside account use <id>` switches.

## Boundaries

Everything Aside writes belongs under `~/.aside/u/0/`. Codex has full filesystem
access of its own, so when a result needs to reach the workspace, let Aside write
it inside its root and copy it out yourself. Never widen Aside's roots to reach the
workspace.

`~/.aside/u/0/models.json` and `accounts.json` can hold plaintext credentials.
Never print or commit them.
