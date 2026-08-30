<!-- Retained as historical reference. Superseded by the parent aside skill.
     Frontmatter intentionally removed so no skill loader indexes this file. -->

# aside-cli — Authenticated Browser Automation

Aside is a Chromium fork with a built-in browser agent. Its CLI runs that agent
against the user's real, logged-in profile, which makes it the right tool when a
task needs an existing session (admin consoles, X DMs, dashboards behind SSO).

## When to use this over the alternatives

| Situation | Tool |
|---|---|
| Page needs an existing login session | **aside-cli** |
| Multi-step web flow with judgment (find value, then act on it) | **aside-cli** |
| Public page, no auth, just need the HTML | `curl` |
| Precise click on a native macOS app UI | Computer Use |
| Need to see what the screen actually shows right now | Computer Use screenshot |

Pair them freely: `aside exec` to do the flow, Computer Use to verify the result
on screen. Aside reports what it believes happened; a screenshot proves it.

## Command surface

```
aside "<prompt>"                 # browser agent session (default command)
aside exec "<prompt>"            # same, explicit
aside repl "<javascript>"        # Playwright-like JS against the live browser
aside mcp                        # expose Aside as an MCP server over stdio
aside account list|status|use    # multi-account selection
aside --version
```

Model options, all optional — defaults come from the user's Aside settings:

```
-m, --model <id>          # also accepts provider/model
-p, --provider <name>
-s, --speed default|fast
--effort off|minimal|low|medium|high|xhigh|max|ultrabrowse
--session <id>            # continue a previous session
--account <id>            # e.g. 0 or u0
```

`--effort ultrabrowse` turns on proactive mode at the model's highest thinking
level. Use it for flows that need the agent to recover from surprises on its own.

## Execution pattern (important)

`aside exec` frequently runs for several minutes. Do not block a turn on it.
Start it with a short yield, capture the session id, then poll:

```
exec_command  cmd="aside exec '<prompt>'"  yield_time_ms=30000
   -> returns session_id
write_stdin   session_id=<id>  chars=""  yield_time_ms=120000   # poll, no typing
```

Repeat the poll until the process exits. Empty `chars` polls without sending
keystrokes.

## Writing a good prompt

The agent is capable but literal. A prompt that works has four parts:

1. **Where to go** — full URL, not a description.
2. **What to find or do** — name the exact element or value.
3. **What to report back** — enumerate the fields you want returned.
4. **What not to touch** — say "do not change any settings" when reading.

Read-only example:

```
aside exec "Go to https://admin.example.com/settings. Report: (1) whether I am
logged in and as whom, (2) the exact verification string shown in step 3,
(3) the URL you found it on. Do not change any settings - just read and report."
```

Action example:

```
aside exec "Go to https://example.com/verify (already logged in). Click the
[Submit] button in step 03. Then report exactly what the page says afterwards -
succeeded, failed, or pending. If a confirmation dialog appears, accept it.
Report the final status text verbatim."
```

The agent returns markdown and often saves screenshots under
`~/.aside/u/<account>/sessions/<session>/tmp/`. Those paths are real files — read
them with `view_image` to confirm what it claims.

## Verify, do not trust

The agent narrates its own success. Confirm independently before reporting:

- It says a DNS record was accepted -> `dig +short TXT domain @1.1.1.1`
- It says a form submitted -> re-open the page and read the status line
- It says it found a value -> open its screenshot and read it yourself

A first attempt can fail and a retry succeed, so ask for the final state rather
than assuming the first report is terminal.

## Where Aside keeps its state

Per account under `~/.aside/u/<id>/`:

| Path | Contents |
|---|---|
| `models.json` | custom provider definitions and model list |
| `settings.json` | selected model per category (default/fast/standard) |
| `credentials.json` | provider credentials |
| `sessions/` | per-session transcripts, screenshots, temp files |
| `cache/models-catalog.json` | cached catalogue |
| `state.db` | runtime state |

`~/.aside/logs/daemon-YYYY-MM-DD.log` holds daemon activity — useful when a flow
fails silently. Browser profile data lives separately under
`~/Library/Application Support/Aside/`.

**`models.json` can contain a plaintext API key.** Never paste its raw contents
into a transcript or commit it. Redact before sharing and keep mode `600`.

Editing `models.json` or `settings.json` while Aside is running risks being
overwritten. Quit the app first, edit, then relaunch and re-verify.

## Known limitation

As of Aside 1.0.728.1 the built-in "Import from another browser" fails with
`Invalid import source` when the source has profiles, because the UI drops daemon
profiles whenever the native `getImportSources` returns an empty `profiles`
array. Use the Chromium HTML bookmark importer (`chrome://bookmarks` -> Organize
-> Import bookmarks) and the CSV password importer
(`chrome://password-manager/settings`) instead.
