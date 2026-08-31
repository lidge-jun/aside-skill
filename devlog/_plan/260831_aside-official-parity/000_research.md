# Official parity research

Goal: make aside-jun a strict superset of Aside's own agent guidance, so a reader
never has to open the official doc for logged-in browser work.

## The official document

Aside ships its guidance as a string constant inside the daemon binary, not as a
file. Recovered from:

```
Aside Daemon.app/Contents/MacOS/aside-daemon   ASIDE_BROWSER_SKILL='...'
```

9539 bytes, frontmatter `name: aside-browser`. The daemon exposes it over tRPC as
`developers.getAsideBrowserSkill` and writes it into agent skill dirs via
`installAsideBrowserSkill`, so this constant is exactly what other agents receive.
The HTTP route needs a daemon Authorization token; extracting the constant from the
binary avoids that and gives the same bytes.

Saved locally for diffing at `/tmp/aside_official/aside-browser-SKILL.md`.

## Parity ledger

77 normative statements enumerated from the official text. Result:

| verdict | count |
|---|---|
| PRESENT in aside-jun | 26 |
| MISSING | 47 |
| CONTRADICTS-CORRECTLY | 1 |
| CONTRADICTS-WRONGLY | 3 |

Row-level ledger: [001_parity-ledger.md](001_parity-ledger.md). Totals without rows
are not auditable, so the rows are the artifact and this table is only its summary.

The one we contradict correctly is "ASK USER AS THE LAST RESORT", which is the rule
the official doc gets wrong for non-interactive CLI use. The three we contradict
wrongly are our own defects and must be fixed.

Two measured facts that earlier drafts miscounted as official rules - where repl
`pwd` resolves, and that repl `fs` throws outside the roots - are recorded in the
ledger's "Not official rules" section instead. They are ours to document, not rules
we agree or disagree with.

### Our defects (CONTRADICTS-WRONGLY)

1. **Snapshot truncation.** Official: "NEVER truncate snapshot with
   `substring()`, `slice()`, `split()`, or similar methods." Our SKILL.md and
   repl-api.md both demonstrate `.slice()` on a snapshot tree. The rule exists
   because a truncated tree hides the ref you need; our examples teach the
   opposite of the rule.
2. **Scope persistence.** Official claims top-level bindings persist. We say
   "scope persists across one session", which reads as agreement. Both are wrong
   for the CLI: see below.
3. **`~/Downloads`.** Official: "`fs` cannot browse the real `~/Downloads`
   directory." We say "Downloading to ~/Downloads is fine", conflating what the
   exec agent's bash tool can do with what repl `fs` can reach.

### Where the official doc is wrong (CONTRADICTS-CORRECTLY)

1. **"ASK USER AS THE LAST RESORT."** In non-interactive exec there is no last
   resort: `outsideRead`/`outsideWrite` are `ask`, no CLI protocol verb can answer
   an approval, and the run parks silently. Asking is never the fallback here.

That is the only one. Two things earlier drafts filed here are not disagreements at
all, just facts the official doc never states:

- **Where `./artifacts/` lands.** Official recommends the path without saying where
  it resolves. Measured: repl `pwd` is `~/.aside/u/0/sessions/<session-id>`, already
  inside the account root, so the official advice and our write confinement agree
  once the resolution is written down. In the ledger the official rule counts as
  MISSING, since we do not carry it yet.
- **repl `fs` outside the roots.** Throws immediately with
  `Path escapes Project and session roots: <path>` instead of suspending, the
  opposite of the exec file tools. The official text only says `fs` cannot browse
  `~/Downloads`; the general boundary is ours to document.

## The persistence correction

Official: "The REPL is a persistent ES2023+ JavaScript environment within one live
REPL session. Top-level `const` and `let` bindings persist."

Measured across two consecutive `aside repl` invocations:

| probe | result |
|---|---|
| `globalThis.MARK` set in call 1 | `undefined` in call 2 |
| `page` | `null` |
| `tabs.length` | `0` |
| tab opened in call 1, via `listBrowserTabs()` | absent - the tab was closed |

So the official sentence is true only of one invocation. A one-shot
`aside repl "..."` is its own whole session, and the tab it opens dies with the
process. Two things follow: a full inspect-act-verify flow must fit in one call,
and a tab you need to keep must be opened in the Aside window and reattached with
`attachBrowserTab(targetId)`, which detaches rather than closes.

## What the official doc omits entirely

Recovered from the daemon bundle and the builtin skills:

- `passwordManager`, 8 methods: `listVaults`, `listItems`, `autofillItem`,
  `unlockExternalPasswordManager`, `generatePassword`, `fillPassword`,
  `createItem`, `updateItem`. Injected into the exec agent's repl tool only;
  `undefined` in CLI repl.
- `applePasswords`, 8 methods including `getOtps` and `autofillLogin`. Present in
  CLI repl. Account-level unlock, not per-session.
- Service globals with methods on the prototype: `twitter`, `gmail`, `youtube`,
  `notion`, `slack`, `linkedin`, `googleDocs`, `googleSheets`, `googleSearch`,
  `imageSearch`, `imagegen`, `googleAccounts`, `captcha`, `cua`, `chrome`.
  `Object.keys` returns `{}` for all of them, which is why they look empty.
- `aside.settings/projects/sessions/routines/channels`.
- `installPageScript(page, key, evaluator)` and `display(input, context?)`.

No network-capture, request-interception, console-capture, or cookie-CRUD global
was found. `fetch()` carries cookies, and there is internal CDP `Network.*` use,
but no documented public surface.

## Implementation phases

- `010`: correct the three defects and the persistence model in SKILL.md.
- `020`: bring references/repl-api.md to parity with the official repl protocol.
- `030`: ship - validate, PII scan, commit, push, mirror.
