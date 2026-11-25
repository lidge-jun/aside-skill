---
name: aside-jun
description: Use Aside's signed-in browser from Codex, Claude Code or another coding agent. Route authenticated browsing, explicit Aside code-mode batches and visual artifact work between aside-codemode, Aside REPL and Aside's agent. Use when the user asks for Aside or its extensions, or needs its existing browser session; ordinary public HTTP fetching and unrelated local coding work stay with the host's tools.
---

# Aside from a coding agent

Use the smallest available surface that can finish the requested work. Codex,
Claude Code and other callers can invoke **aside-codemode directly**; they do not
need to ask Aside's agent to run every batch. This skill is guidance, not a runtime
or an installer. The user's chosen tools, scope and permissions remain decisive.

## Choose the execution surface

| Work | Route | Read |
|---|---|---|
| Any Aside work when this caller's live tool list shows the native Aside MCP (`aside mcp`: `exec`, `repl`, `memory_search`, `browser_profiles` on 1.26.1115) | Call those tools instead of shelling out to the CLI; pass `profile_id` from `browser_profiles` to a new `exec`/`repl` when the account has several profiles, omit it when continuing with `session_id`. The REPL/exec rules below still apply | [Delegation](references/exec.md), [REPL](references/repl-api.md) |
| Directory/project search within an explicitly requested Aside/code-mode workflow; 2+ independent known files, URLs, queries or captures | **Direct aside-codemode** through a tool exposed to this caller, otherwise the installed CLI | [Code-mode calls](references/codemode.md) |
| First look at an unfamiliar page; one visible click; a dependent form/wizard step | Native Aside REPL, inspect → act → inspect | [REPL](references/repl-api.md) |
| Current/already-open tab | Identify and attach the existing tab; never replace it with a fresh URL batch | [REPL](references/repl-api.md); verified codemode `browse.attach` is also available |
| Login, MFA, account change, approval, or a browser task needing judgment | Aside `exec` — it signs in by itself; hand it the login first. Within the task's existing authorization; stop when a human gesture is required | [Delegation](references/exec.md), [credentials](references/credentials.md) |
| Composed HTML/SVG report, visual explanation or PDF through Aside | `exec` using the selected Aside account's **dev-visualizer** skill; codemode may collect inputs first | [Visualizer handoff](references/visualizer.md) |
| A public page that only needs HTTP, or unrelated local coding work | The host's existing reader/search/file tools, unless the user explicitly selected Aside/code mode | No Aside setup needed |

Aside's own guide (`aside guide`, skill v5) recommends `exec` for most browser
tasks and `repl` only when you must inspect DOM/screenshots directly. This skill
keeps codemode/REPL for known mechanical batches, but when the route is unclear,
prefer `exec`: it carries the user's skills, memory and sign-in handling.

Independent means one item's result is not needed to choose the next item's
operation. Do not turn a login flow, cart, wizard or uncertain side effect into a
parallel batch. A batch failure is a result to inspect, not an invitation to replay
completed actions.

Two independent reads can also run as concurrent one-shot `aside repl`
processes (4 and 8 observed isolated, zero leaked tabs); see
[parallel pages](references/repl-api.md#parallel-pages).

## Sign-in is exec's job

`aside exec` logs in on its own with Aside Vault or a connected password
manager. When a site needs a login, delegate the sign-in to exec in the task
prompt; do not ask the user to sign in or unlock first. Ask the human only
after exec reports a concrete blocker (locked Vault, no credential, MFA,
passkey, CAPTCHA). No account switching, new accounts or policy changes.
Prompt clause and details: [exec](references/exec.md#sign-in-is-delegated),
[credentials](references/credentials.md).

## Direct code-mode calls from Codex and Claude

1. Look for a **currently exposed aside-codemode MCP tool** and inspect its real
   schema and server identity. A matching name alone is insufficient. If present,
   send the bounded guest program directly to it.
2. Otherwise resolve the **already installed** `codemode` command or absolute
   Node/CLI pair, identify its package version, and use `--code-file` with an
   explicit `--cwd`. [The cookbook](references/codemode.md) includes Bash and
   PowerShell forms, executable guest examples and result handling.
3. If neither route is available, report the missing capability and use an
   already available authorized native route when it can satisfy the request.
   Do not install, register MCP, force configuration, or update a package merely
   because this skill was loaded.

`codemode --install-mcp` configures **Aside's** MCP client. It does not register a
server in Codex or Claude Code. Host-qualified tool names vary; never invent
`mcp__...` names from an example. `execute_code` accepts the schema the caller
actually exposes, not arbitrary CLI flags.

The guest is an async JavaScript body: `await` tool operations and **`return` the
answer**. Codemode's `search`, `browse` and `fs` globals exist inside that guest.
They are not globals in Codex `functions.exec`, Claude's shell, Node, or native
`aside repl`. A host Code Mode tool may orchestrate a shell/MCP call if its own
contract allows it; it is a different runtime from aside-codemode.

For completeness-sensitive searches, identify the runtime and require the
0.9.0 result contract, including the actual metadata. Preserve `complete`,
`truncated`, `partial`, `scope` and `scope.coverage`; keep per-item errors and
skipped reads. An older runtime or missing metadata cannot prove exhaustive
absence. Positive bounded reads may still be useful with their limits stated.
Neither an exit code nor `ok:true` proves that a page contains the requested data.

## Confirm browser account and host before use

For browser work, inspect `aside --version`, relevant `--help`, and
`aside account list` on the execution host. Use an explicitly requested account
and host; derive absolute paths from that account instead of copying `u0` from an
example. Never print account credential files.

Current selectors (verified on CLI 1.26.1115.1556, 2026-11-26):

- `--account u0` uses that account's first browser profile; `--account u0:<PROFILE_ID>`
  or `--profile <PROFILE_ID>` picks another. List IDs with
  `aside host profiles [--host <h>] --json`. Saved local profile IDs do not apply to
  remote hosts; existing sessions keep their original profile.
- `--host local | remote | <host-id> | <full device name>`. `remote` works only when
  exactly one remote host is registered. `aside host list` / `host status` /
  `account status` are read-only.
- `aside account use <id>` and `aside host use <host>` change defaults for every
  later command. Run them only when the user asks; prefer one-shot flags.
  (`settings set-default-profile` from 1.26.906 is gone; `aside guide` still
  mentions it, but current `--help` wins.)
- A host without a local Aside needs `aside login` (device code by default) or
  `ASIDE_API_TOKEN`. Remote control must be enabled on the target in Settings >
  Developers and the device must be online.

For personal context (people, projects, preferences) query Aside memory before
asking the user: `aside memory search "<q>" --json`, `list`, `show <path>`, or
the attached `memory_search` tool. It is read-only; never edit memory files, and
route "remember this" through exec.

Codemode's browser runner inherits native `aside repl` defaults unless the
installed build supports explicit context. As of 2026-11-26 npm `latest` is
still 0.9.2; 0.9.1+ adds CLI `--account`/`--host` and per-call MCP
`account`/`host`, 0.9.0 has neither. On the measured Mac a shell `codemode`
resolved to 0.9.2 while Aside's own codemode MCP server ran 0.9.1. codemode
accepts only `u<N>` accounts (no `--profile`, no `u0:<PROFILE_ID>`), so use
native `aside --profile` / `--account u0:<ID>` (or MCP `profile_id`) when a
profile matters. `desktop.*` (PR #52) is merged on `main` but unreleased; check
`typeof desktop` before relying on it.
`codemode` has no `--version`, so identify the build by
[resolving its package](references/codemode.md#identify-the-installed-version)
and check the live schema. When the verified build cannot pin a required
nondefault account or remote host, use native Aside's explicit `--account` /
`--host` route. Keep the same workload split on that native route: REPL for
known mechanical steps, exec for judgment/login. Do not silently switch global defaults to make
a recipe work. For an installed build with the #44 fix, follow the
[explicit context contract](references/codemode.md#context-selection-in-the-091-source-contract);
verify capability rather than assuming a dev merge upgraded the installed package.

Read the host instructions when running Aside `exec` or resolving a missing CLI:
[macOS](references/host-macos.md) or [Windows](references/host-windows.md).
CLI, browser app and background components have separate versions; current help
and measured behavior take precedence over stale examples. See the dated
[compatibility notes](references/compatibility.md).

## Keep execution and evidence honest

- Every noninteractive `exec` uses the host deadline and a prompt that names
  authorized inputs, output paths and the no-question stopping rule. Read
  [exec.md](references/exec.md) before delegating.
- Permission mode changes capability, not user authorization. Do not widen roots,
  enable browsing, disable biometrics or change persistence settings as a fallback
  to a denied operation. Use the authorized scope or report what is blocked.
- Do not rely on Guard as a fence. On 1.26.1115 (2026-11-26) a default-mode
  `exec` read `/etc/hosts` and wrote under `/tmp` with exit 0 even though the
  account's outside-root policy was `ask`. The prompt's path clause and your own
  post-run check are the boundary; see [permissions](references/permissions.md).
- Before native REPL, read `aside guide repl` and the relevant installed builtin
  skill via `aside skills list/show`. Do not assume the builtin catalog includes
  account-installed user skills such as dev-visualizer.
- One-shot `aside repl "..."` commands have separate temporary sessions. Keep an
  inspect–act–verify flow and download verification inside one invocation. Borrow
  an existing tab when it must survive; use current snapshots and real refs.
- Before writing session files, prepare `./tmp` and `./artifacts`. For element
  screenshots use the [tested source-capture and host-crop workflow](references/repl-api.md);
  native locator capture and clip origin are unreliable on measured builds.
- A timeout or indeterminate effect may leave completed side effects behind.
  Inspect the destination state before retrying. Do not repeat a submission just
  because a CLI stopped reporting it.
- Pass subcommands as separate argv words. Anything the CLI does not parse as
  a subcommand becomes an agent prompt: `aside version`, or `"account list"` as
  one quoted word under zsh, starts a paid exec session. Call agent runs
  explicitly as `aside exec -- "<prompt>"`.
- Exit codes are meaningful again on 1.26.1115 (measured 2026-11-26): `exec`
  exits 0 when the run completes, 1 when it fails or `--timeout` passes, 2 for
  invalid usage; `repl` exits 1 on a throw, `ReferenceError` or root escape. Still
  read the result: prefer `--json` (`exec` → `{session:{id},outcome,answer,error}`,
  `repl` → `{run:{content,error,elapsedMs}}`) and require `outcome:"completed"` /
  `error:null`. The 1.26.906 "` • Error 403` with exit 0" case is historical and
  not re-measured.
- Only the answer goes to stdout; the session id, thinking and tool calls go to
  stderr. Take the session id from `--json` instead of scraping stderr.
- `--timeout 10m` stops *waiting*, exits 1, and **leaves the session running**.
  After a timeout, `aside session inspect <id>` and either wait, `steer`, or
  `session stop <id>`; never relaunch the same prompt blindly.
- `--incognito` keeps a task private but has no Vault access; CLI `repl` sessions
  are always incognito, so `imessage`/SMS-code skills only work inside `exec`.
- Do not run `aside settings ...` changes (`save-sessions`, `computer-use`,
  `analytics`) as preflight. `aside settings get` is the read-only check. Current
  help uses `enable`/`disable`; `aside guide`'s `save-sessions true` is stale.
- Run `aside skills install` only when the user asks. It now writes the official
  `aside-browser` skill (v5, which tells agents to prefer Aside over every other
  browser tool and to read `aside guide`) into Codex, Claude Code, Cursor,
  OpenCode and others (`--target`, `--path`); it shadows this one.
- Verify actual content and artifacts before reporting completion. A local path
  returned by a remote Aside host is not yet a file delivered to this caller.

Additional references are conditional: [gated research](references/deep-research.md),
[scheduling](references/scheduling.md), [permission diagnostics](references/permissions.md)
and the [builtin catalog](references/builtin-skills.md). Historical measurements
remain useful diagnostics; they are not universal promises about newer builds.
