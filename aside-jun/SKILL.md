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
| Directory/project search within an explicitly requested Aside/code-mode workflow; 2+ independent known files, URLs, queries or captures | **Direct aside-codemode** through a tool exposed to this caller, otherwise the installed CLI | [Code-mode calls](references/codemode.md) |
| First look at an unfamiliar page; one visible click; a dependent form/wizard step | Native Aside REPL, inspect → act → inspect | [REPL](references/repl-api.md) |
| Current/already-open tab | Identify and attach the existing tab; never replace it with a fresh URL batch | [REPL](references/repl-api.md); verified codemode `browse.attach` is also available |
| Login, MFA, account change, approval, or a browser task needing judgment | Aside `exec`, within the task's existing authorization; stop when a human gesture is required | [Delegation](references/exec.md), [credentials](references/credentials.md) |
| Composed HTML/SVG report, visual explanation or PDF through Aside | `exec` using the selected Aside account's **dev-visualizer** skill; codemode may collect inputs first | [Visualizer handoff](references/visualizer.md) |
| A public page that only needs HTTP, or unrelated local coding work | The host's existing reader/search/file tools, unless the user explicitly selected Aside/code mode | No Aside setup needed |

Independent means one item's result is not needed to choose the next item's
operation. Do not turn a login flow, cart, wizard or uncertain side effect into a
parallel batch. A batch failure is a result to inspect, not an invitation to replay
completed actions.

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

Released codemode 0.9.0's browser runner invokes `aside repl` without per-call account/host
arguments. Its MCP schema has no `account`, `host` or `cwd` field. Use it only
when its existing execution context is verified to match the task. For a required
nondefault account or remote host, use native Aside's explicit `--account` /
`--host` route unless the installed codemode contract proves equivalent routing.
Keep the same workload split on that native route: REPL for known mechanical
steps, exec for judgment/login. Do not silently switch global defaults to make
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
- Verify actual content and artifacts before reporting completion. A local path
  returned by a remote Aside host is not yet a file delivered to this caller.

Additional references are conditional: [gated research](references/deep-research.md),
[scheduling](references/scheduling.md), [permission diagnostics](references/permissions.md)
and the [builtin catalog](references/builtin-skills.md). Historical measurements
remain useful diagnostics; they are not universal promises about newer builds.
