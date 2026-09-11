---
name: aside-jun
description: Drive the Aside browser CLI on macOS or Windows for work that needs a real signed-in browser - reading pages behind a login, automating multi-step web flows, and delegating browser tasks to Aside's own agent. Use when a session or cookies are required and an HTTP fetch would fail; not for ordinary public-page fetching or local browser QA.
---

# Aside

Aside is a Chromium fork with a built-in browser agent. Its CLI drives that agent
against the user's real, logged-in profile, which makes it the right tool when a
task genuinely needs an existing session: admin consoles, dashboards behind SSO,
DMs, anything where a plain HTTP fetch gets a login wall.

Aside runs on macOS and Windows under the same CLI contract, measured on both at
`1.26.906.1630`. A local run needs the GUI app running; a remote-host command does
not (see Remote Control below). Everything in this file is platform-neutral. The
host layer - where the CLI lives, how a deadline fires, how a job is locked and
scheduled - differs by OS and lives in one file per OS.

## Host layer

Read exactly one, for the machine you are on:

| OS | file |
|---|---|
| macOS | [references/host-macos.md](references/host-macos.md) |
| Windows | [references/host-windows.md](references/host-windows.md) |

Each documents **both bash and PowerShell** as first-class ways to drive the CLI.
Neither is a fallback. Do not translate a snippet into the other shell to match an
example, and do not assume the shell decides the primitive - the OS does.

Three rules from those files hold everywhere and are not repeated per recipe:

- Resolve the CLI through the host file before the first command. On Windows the
  `aside` name is not resolvable on a fresh install. `aside version` without dashes
  opens an agent session; only `--version` prints a version.
- Every `exec` runs under a host deadline. A fired deadline exits `142` on every OS
  and shell; any other non-zero code came from the CLI itself.
- **Exit `0` is not success.** Every failure mode measured - a denied file tool, a
  repl `ReferenceError`, a repl root escape - still exited `0`. Grep stdout for
  `is blocked by policy`, and verify any file the run claims to have written.

## The rule that matters

An `aside exec` run is non-interactive: an approval prompt, a question, or a Touch
ID gesture has no one to answer it. What that costs changed in CLI `1.26.902`.

Through `1.26.831` the daemon suspended the run and waited. The tool-call line
printed, then silence until an external timeout killed the process. On
`1.26.902.1732` (daemon `1.26.902.1713`) the same calls fail fast, measured
rather than assumed:

| Cause | through 1.26.831 | 1.26.902, default `guard` |
|---|---|---|
| `write_file` outside the account root | hung indefinitely | `blocked by policy` in ~5s; run continues |
| `read_file` outside the allowed roots | hung the same way | `blocked by policy` in ~5s; run continues |
| `ask_user_question` | rendered, then hung | tool absent from the CLI catalog; agent says so, exits 0 |

The full error text is `Permission denied: read '<path>' is blocked by policy`
(or `write`). Evidence:
`devlog/_plan/260902_aside-update-audit/evidence/probe-{A,W,C}-*.log`.

The failure changed shape, not severity. A deny is an error the agent reads and
routes around: in one probe it "did not try other tools", in another it wrote the
inside file and skipped the outside one, and both runs exited 0. Nothing in the
exit status says a step was skipped. The risk is now **silently incomplete
work**, and the prompt clauses below exist so the agent never picks a path that
gets denied.

The guard config itself is unchanged:

```json
{"readableRoots":[],"writableRoots":[],"outsideRead":"ask","outsideWrite":"ask"}
```

`ask` is what the Aside window is configured with; whether it still suspends there
was not probed. A CLI session downgrades it to deny.

`bash` never went through that check. It is governed by the OS sandbox instead, and
that mechanism is the one thing the two platforms do not share: on macOS it denies
with a message, on Windows it does not deny at all. Read your host file and
[references/permissions.md](references/permissions.md) before using it.

### Open the session instead of fencing the prompt

`1.26.902` added `--permission ask|guard|full-access`. **Use `full-access` by default
for exec runs.** The invocation itself, deadline included, is in your host file.

With it the file tools reach paths that `guard` denies (probe B: `read_file` on
the same workspace file that probe A had blocked returned its contents in 4.2s),
so the skipped-step failure goes away for the paths a task names. It opens the
session to whatever the daemon process can reach, so a read-only task has to say
in the prompt what it must not touch, and the clause that keeps Aside's own output
under the account root stays.

`guard`, the default when the flag is omitted, fits a task that must not be able
to touch the workspace at all and can afford a skipped step. `ask` is accepted by
CLI 1.26.902 but normalizes to `guard` (the help text says so, and two probes with
it were denied the same way, S8-Q4); it does not suspend from a CLI. The older
recipe that widens the roots in settings for one directory still works and remains
the narrow alternative in [references/permissions.md](references/permissions.md).

### Timeouts still matter

There is no timeout option. A run can still park on a passkey gesture or a
credential-manager handshake, and it can simply take long.
Always run under the host deadline from your host file. The spelling matters more
than it looks: the obvious one is wrong on both platforms - macOS has no `timeout`
in the base system, and on Windows the bare word resolves to a System32 program that
*sleeps* instead of wrapping. Both host files carry the working primitive, its
evidence, and the rejected candidates.

A fired timeout kills the CLI, not the work already done: files written,
downloads, form submissions, messages sent all stand. **Inspect the real state
before retrying**, or a rerun duplicates a side effect.

Before letting the timeout fire, reach the run. The id is on the first line the
CLI prints (`created new session: <id>`).
`aside session steer <id> "report what is blocking you and stop"` injects an
instruction into a running session and `aside session stop <id>` ends it cleanly.

A run that did suspend survives as `status: suspended` with `suspension.kind` of
`approval` or `ask-user-question`. `aside session list` does not show those: on
2026-09-02 it listed the idle, interrupted, and aborted CLI sessions and none of
the suspended rows present in `state.db` (S7). Read the database directly:

```bash
python3 -c "import sqlite3,json;c=sqlite3.connect('file:$HOME/.aside/u/0/state.db?mode=ro',uri=True);\
print([(r[0], json.loads(r[1])['kind']) for r in c.execute(\
\"select id,suspension from sessions where status='suspended'\")])"
```

A growing count means prompts are still tripping the approval path. On 1.26.902
the CLI cannot create a new one: `--permission ask` is documented as the same
mode as `guard` and denies instead of parking (S8-Q4). The rows that remain are
older builds' leftovers; `aside session resume` and `steer` refuse them with
`Session is pending purge`, and `aside.sessions` in repl has no approve or answer
method, so clear them yourself when they matter.

Set `aside settings save-sessions true` once. It flips `cli.ephemeral` in
the account's `settings.json` to `false`, so every later CLI session is created
persistent: it appears in `aside session list` as `persistent`, in
`aside.sessions.list()`, and in the Aside window's Chats list, and it is exempt from
the 15-minute purge (S8-Q1..Q5). Details in
[references/scheduling.md](references/scheduling.md).

Read [references/permissions.md](references/permissions.md) for the mechanism,
the exact roots, and the settings-level grant.

## Choosing a surface

```
repl  -> your own tool: you drive the browser, one call, deterministic
exec  -> a subagent: hand Aside's agent a task and read its report
```

This is a deliberate departure from Aside's own `aside-browser` skill, which since
`1.26.902` says to hand work to Aside by default and reach for JavaScript only when
the user names Playwright. The split here stays because a repl call is one
session with a beginning and an end, it throws immediately on a bad path instead
of skipping, and every snapshot and screenshot lands in Codex's hands as evidence.
Delegation buys judgment and costs verifiability, so it is used where judgment is
the point.

Reach for **exec** when the work needs judgment, a login, or one of Aside's builtin
skills: signing in, navigating an unfamiliar site, reading Gmail or Notion,
handling a CAPTCHA, anything multi-step where the next action depends on what the
last one revealed.

Before delegating anything that has to **sign in**, read
[references/credentials.md](references/credentials.md). Aside's credential layer
has a first-run handshake that parks a CLI run: Apple Passwords wants a 6-digit
code only a human can read off the screen. That reference covers the one-time
setup, why "Unlock with Touch ID" must stay off, why 1Password is the smoother
choice, and the Importer's EPERM failure. The reliable pattern is that the user
signs in once in the Aside window and `exec` inherits the live session.

Reach for **repl** when you already know what to do. It is a Playwright-style
surface and you control every step. It is also the safer choice for file work,
because the repl filesystem throws immediately on a bad path instead of skipping it.
A task that is mostly mechanical with one authenticated step does that step with
exec and the rest with repl.

repl shares the signed-in profile, so it is not a private window. A fresh CLI repl
starts with no attached tabs, which reads like an empty browser, but `openTab`
inherits the account's cookies: opening `x.com/home` landed on the signed-in
timeline rather than a login wall, verified against CLI `1.26.902.1732` with daemon
`1.26.902.1713` (signed-in discord.com and aside.com tabs on 2026-09-02). If a repl
tab does come up signed out on an older build, update Aside before working around it.

### Research behind a login

Ordinary research does not need Aside; a hosted web search plus opening the page is
cheaper for anything public. Aside earns its place when the sources are gated: the
same X search URL gave `curl` 289KB with zero tweet markup, a sessionless browser a
sign-in wall, and a CLI repl on the signed-in profile a 15063-char tree of results.

The split follows from that. Codex discovers and synthesises, repl proves what needs
cookies and queries the service APIs directly, exec handles anything needing an
account - signing up to read documentation, logging in, clearing a CAPTCHA - because
`passwordManager` lives only there. Record which surface proved each claim; a
snapshot proves the source displays the claim, not that it is true.

Rungs, recipes, the claim-ledger format, and why `googleSearch` is not usable:
[references/deep-research.md](references/deep-research.md).

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
Write and edit files only under <account-root>. Read other local paths only when
this prompt names them, and never modify them.
Downloading to <downloads> is fine; move anything you keep under <account-root>.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop.
```

Substitute the two placeholders with **absolute** paths taken from your host file,
and never send a literal `~`: Aside's path layer does not expand it. On Windows it
silently creates a directory named `~` and still reports `Successfully wrote`.
Assemble the task sentence, then these clauses, inside your host file's deadline.

The first clause is the write fence. `--permission full-access` opens the session,
so the prompt is what keeps Aside's output under its own root and keeps its hands
off workspace files it was only meant to read: name the paths a task may read, and
Codex copies results out afterwards. Aside's own system prompt tells the agent to
"request access once" for outside paths, which under `full-access` is unnecessary
and under `guard` is denied and skipped, so the override has to be explicit.

Running under `guard` instead? Prefix the clauses with the older fence, `Use
read_file, write_file and edit_file only under <account-root>. For any other local
path use the bash tool instead - never the file tools.`, so a denied call never
silently drops a step. What `bash` can reach under `guard` is the one thing that
does not carry across: on macOS it reaches whatever the sandbox profile allows,
which varied between probes, and on Windows it does not answer at all - the call
deadlocks the session. If a task needs the shell tool, run it `full-access`.

The third clause overrides Aside's own instruction. Its builtin guidance ends the
login section with "**ASK USER AS THE LAST RESORT**", which is sound advice in the
app window; in a non-interactive run there is no last resort: the tool is absent
from the CLI catalog and a question typed into chat ends the run. Replace it with a
ladder that ends in a clean stop:

> Never ask a question from a non-interactive `aside exec` run. The CLI has no
> `ask_user_question` tool and cannot answer an approval prompt, Touch ID, a passkey
> gesture, or a macOS Apple Passwords code. Instead, work the routes that are
> already available: the inherited signed-in session, a clearly matching
> password-manager item, a
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

Omit `-m` by default: passing a model flips `strictModelSelection` and Aside's own
settings pick the model. When a specific model is required, use the slash form
with the provider in front, `-m opencodex/xai/grok-4.6`. The split form
`-m xai/grok-4.6 -p opencodex` fails.

Runs take minutes. Start one, capture the session, then poll:

```
exec_command  cmd="<host-file deadline wrapper> aside exec --permission full-access -- '<prompt>'"  yield_time_ms=30000
write_stdin   session_id=<id>  chars=""  yield_time_ms=120000
```

Empty `chars` polls without typing. If output stops right after a tool-call line
and stays stopped, that is a parked run rather than slow work; `aside session steer`
it before the timeout fires. The user cannot see the Aside CLI's output, so narrate
a long run: roughly every 60 seconds, what the agent is doing and has established.

Useful options: `--permission full-access` (above), `--effort ultrabrowse` for flows that
must recover from surprises on their own, and `--log-dump <path>` to record every
agent event as JSONL (re-verified on 1.26.902, `evidence/probe-L-log-dump-summary.log`:
`agent_start`, `turn_start`, `message_*`, `toolcall_*` and `tool_execution_*`
events).

The `--session` flag is gone as of `1.26.902`; passing it prints the help text. A
healthy run continues with `aside session resume <id> "<prompt>"`, a running one is
redirected with `aside session steer <id> "<text>"` or handed a follow-up with
`aside session queue <id> "<text>"`. Re-pass `-m` on resume: without it the daemon
reads the model id stored in the session, which for a routed model comes back
provider-less and fails with `<model> is not available`.

With `save-sessions` off, resume works for about 15 minutes: CLI sessions are
created ephemeral and purged after `EPHEMERAL_SESSION_RETENTION_MS = 9e5`
(unchanged in 1.26.902), so a later resume fails with `Session is pending purge`.
With it on (above) new sessions are persistent and the purge query's
`ephemeral = true` predicate skips them (S8-Q5); a resume past 15 minutes on such
a session has not been timed yet. For anything scheduled or long-running, carry
state in files under the account root and let Aside's memory store hold what is
generally true; `aside memory search|list|show|path` read that store from the CLI.
See [references/scheduling.md](references/scheduling.md) before putting `exec` in
cron or a LaunchAgent.

Scheduling needs no machinery beyond that. Point the OS scheduler straight at
`aside exec` with a full prompt, wrap it in the deadline and lock your host file
names, and let each tick be a complete run. Session ids are not worth saving to disk while
`save-sessions` is off, because they stop resolving after the purge window; with it
on they persist, but a fresh run per tick is still the simpler design. Aside's
memory store has room to spare - a store in daily use sat at 7.4MB with 217 index
entries - so let it accumulate what is generally true and keep per-job bookkeeping
in your own files under the account root.

Account selection is deliberately missing from that list. Every path rule here is
written for account `u0`, whose absolute root your host file gives. Another account moves the
root to `~/.aside/u/<n>/` and silently invalidates the clauses, turning the safe
path into an outside path that `guard` denies. If another account is genuinely
needed, substitute its root everywhere in the clauses first.

Remote Control routes a run to another machine. Aside's own skill documents the surface:
`aside host list|use|status`, `--host <id>` on `exec` and `repl`, and `aside login` once,
after which it says the local app need not be running. What was measured here is narrower:
`aside host list` answers locally, `{"defaultHost":"local","hosts":[]}`, because no host is
enrolled - the daemon reads that from `<account-root>/remote-control.json`, absent on this
machine. Enrolling registers this desktop with Aside's API, so nothing beyond that is tested.

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
`<account-root>/sessions/<session-id>`, so a relative `./artifacts/` path is already
inside the account root. Anything outside the roots throws
`Path escapes Project and session roots: <path>` immediately rather than suspending,
which is the opposite of the exec file tools.

That directory starts **empty**, so `fs.writeFile` into `./tmp/` or `./artifacts/`
throws `ENOENT` until you `fs.mkdir(path, { recursive: true })`. Only
`page.screenshot({ path })` and `page.pdf({ path })` make their own parent.

Full surface, including the tab-inspection protocol, the reading-escalation ladder,
download handling, and the service globals:
[references/repl-api.md](references/repl-api.md).

## What Aside already knows

Aside ships skills covering Gmail, Google Docs and Sheets, Notion, Slack, X,
KakaoTalk, YouTube, Chrome APIs, seven password managers, CAPTCHA
solving, and document formats, plus a set of site-specific skills for services like
Jira, Linear, GitHub, and Trello.

**exec loads them on its own**: name the skill in the prompt and the agent picks it
up. Codex can also read one before delegating: `aside skills list` prints a
CLI-listed subset (11 names on 1.26.902, `evidence/probe-K-skills-list.log`; not
identical to the repl-backed set) and `aside skills show <name>` prints any skill's
body, which is how to learn what a skill will do or to drive its repl global yourself.

Name the skill in the first sentence, then append the three clauses above:
`Use the google-sheets skill to read the totals from <url>. Report each row label
and its total.` The rest of the prompt and the deadline are unchanged.

Naming the skill usually beats describing the workflow, because several of them
reach an API and never open a tab at all. `aside skills install` copies Aside's own
`aside-browser` skill into a Codex, Claude Code, Cursor, or OpenCode skills
directory; do not run it here, this skill replaces it and two skills in one trigger
space route unpredictably.

The catalog, including which skills are backed by a repl global you could drive
yourself: [references/builtin-skills.md](references/builtin-skills.md). Regenerate
it after an Aside update with `scripts/refresh-builtin-summary.sh`.

## Verify what it tells you

The agent narrates its own success and is sometimes wrong. Confirm independently:
re-open the page, check the file, run `dig` against the record it claims to have set.
Screenshots land under `~/.aside/u/<account>/sessions/<session>/tmp/` as real files.
A retry can succeed after a failure, so ask for the final state, not the first report.

## When something goes wrong

**Silence after a tool call.** The run is parked, most often on a credential or
passkey handshake. Try `aside session steer <id>` first, let the timeout end it
otherwise, then check the prompt for a request that invites a question. Re-running
with `--log-dump <path>` records every agent event as JSONL and shows which call
parked.

**A model error such as `401 Model not supported`.** The account's configured
default model is unavailable. Pass a working model once with `-m provider/model`,
and tell the user their Aside default needs updating rather than hardcoding a model
into future calls. Check what is configured with
`aside repl "console.log(JSON.stringify(aside.settings.get('defaultModel')))"`.

**`aside mcp` produces nothing.** Expected. It emits no stdout for a plain
initialize over stdio; it is meant to be driven by an MCP client, not probed by
hand. Since `1.26.902` it can create and run agent tasks for a connected client.

**Wrong account.** `aside account list` shows which is signed in. If you switch
with `aside account use <id>`, re-confirm with `aside account list` and rewrite
every account-root path in your clauses to the new account's root before running
anything, or each prompt now points outside the allowed roots.

## Boundaries

Everything Aside writes belongs under the account root, and with `full-access` the
first prompt clause is the only thing holding that line. Codex has full filesystem
access of its own, so when a result needs to reach the workspace, let Aside write
it inside its root and copy it out yourself. Copying out is the default and it is
almost always enough.

`--permission full-access` is the normal way to let a run reach a workspace path;
tell the user a run was opened when the task touches anything outside Aside's root.
The settings-level root grant is the narrow alternative for one directory; keep it
to that directory, restore it in the same turn, and say what was granted.

The account's `models.json`, and `accounts.json` at the data root one level above
it, can hold plaintext credentials.
Never print or commit them.
