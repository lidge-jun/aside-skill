# Parity ledger

Every normative statement in the official `aside-browser` SKILL.md, classified
against `aside-jun`. Line references point at the state of the files BEFORE the
010/020 corrections land, so they are a snapshot of what the audit found.

| verdict | count |
|---|---|
| PRESENT | 26 |
| MISSING | 47 |
| CONTRADICTS-CORRECTLY | 1 |
| CONTRADICTS-WRONGLY | 3 |
| total | 77 |

| # | official rule | in aside-jun | verdict |
|---:|---|---|---|
| 1 | exec works across logged-in accounts, cookies, apps, memory, history | SKILL.md:8 | PRESENT |
| 2 | repl provides low-level Playwright-compatible interaction | SKILL.md:154 | PRESENT |
| 3 | Whole-task delegation goes to aside exec | SKILL.md:134 | PRESENT |
| 4 | Direct evidence, downloads, screenshots, exact verification go to aside repl | SKILL.md:154 | PRESENT |
| 5 | Inspect aside --help, exec --help, repl --help before relying on memory | NO | MISSING |
| 6 | Continue exec with --session, retained about 15 min | SKILL.md:244 | PRESENT |
| 7 | aside repl dies with the process | implied only | MISSING |
| 8 | Run repl in a TTY so output streams live | NO | MISSING |
| 9 | Treat exec like a browser-special subagent | SKILL.md:136 | PRESENT |
| 10 | Poll exec and watch it | SKILL.md:234 | PRESENT |
| 11 | Give the user a status update about every 60 seconds | NO | MISSING |
| 12 | REPL is persistent; top-level const and let bindings persist | SKILL.md:276, repl-api.md:7 | CONTRADICTS-WRONGLY |
| 13 | Use fresh variable names | NO | MISSING |
| 14 | Global page is the current Page | repl-api.md:20 | PRESENT |
| 15 | Global tabs lists session-attached pages | repl-api.md:20 | PRESENT |
| 16 | listBrowserTabs lists browser tabs without attaching | repl-api.md:14 signature only | MISSING |
| 17 | attachBrowserTab(targetId) attaches and sets page | repl-api.md:15 signature only | MISSING |
| 18 | attachActiveBrowserTab attaches the active tab | repl-api.md:16 signature only | MISSING |
| 19 | getTabByTargetId resolves an already-attached Page | repl-api.md:146 | PRESENT |
| 20 | openTab opens, waits for interactive, updates page and tabs | repl-api.md:13 | PRESENT |
| 21 | closeTab closes owned tabs and detaches borrowed ones | repl-api.md:17 | PRESENT |
| 22 | snapshot is the primary reading API and returns tree and diff | repl-api.md:70 | PRESENT |
| 23 | annotatedScreenshot and page.screenshot give visual verification | repl-api.md:88 | PRESENT |
| 24 | page.pdf saves user-visible PDFs under ./artifacts/ | NO | MISSING |
| 25 | fetch is cookie-bearing and limited to safe trusted GET/HEAD | repl-api.md:144 cookies only | MISSING |
| 26 | Globals fs, path, Buffer, sleep, display, pwd | partial: fs and display only | MISSING |
| 27 | Always use console.log to return values to yourself | repl-api.md:7 | PRESENT |
| 28 | repl starts neutral; do not assume page is the user's current tab | repl-api.md:20 | PRESENT |
| 29 | When the user mentions the current or an open tab, inspect open tabs first | NO | MISSING |
| 30 | Print targetId, active, title, url when listing tabs | return shape only | MISSING |
| 31 | Use attachActiveBrowserTab only when the user asks about the active page | NO | MISSING |
| 32 | Use attachBrowserTab for a matching open tab or a given target id | NO | MISSING |
| 33 | After attaching, read with an interactive snapshot | NO | MISSING |
| 34 | Only call openTab when no relevant tab exists | NO | MISSING |
| 35 | ALWAYS use snapshot as the primary way to read a webpage | repl-api.md:154 | PRESENT |
| 36 | Snapshot options are interactive, showHidden, ref, selector | repl-api.md:77 | PRESENT |
| 37 | The selector option takes CSS even though the tree prints ARIA roles | NO | MISSING |
| 38 | Snapshot returns unique ref ids such as e12 or f1e1 | repl-api.md:79 | PRESENT |
| 39 | The tree includes title, URL, iframe contents, and off-screen elements | NO | MISSING |
| 40 | Ref ids are virtual; pass them to locator and never mix them into CSS | repl-api.md:79 partial | MISSING |
| 41 | Each new snapshot invalidates all earlier ref ids | repl-api.md:83 | PRESENT |
| 42 | Save snapshots as const s1, const s2 so they stay reusable | NO | MISSING |
| 43 | Print tree first; after an action always print diff | repl-api.md:156 | PRESENT |
| 44 | Never guess ref ids, selectors, page content, or snapshot size | partial | MISSING |
| 45 | NEVER truncate a snapshot with substring, slice, or split | SKILL.md:284 and repl-api.md:159 both use slice | CONTRADICTS-WRONGLY |
| 46 | Reading escalation step 1 is snapshot with interactive true | NO | MISSING |
| 47 | Reading escalation step 2 is a full snapshot | NO | MISSING |
| 48 | Reading escalation step 3 waits and re-snapshots only while still changing | NO | MISSING |
| 49 | Reading escalation step 4 is annotatedScreenshot or page.screenshot | repl-api.md:88 without the order | MISSING |
| 50 | Avoid page.content and page.evaluate unless the selector is known | NO | MISSING |
| 51 | Use Playwright APIs through the global page object | repl-api.md:23 | PRESENT |
| 52 | Always use openTab and closeTab; newPage and page.close leak memory | NO | MISSING |
| 53 | Never guess URLs unless they are well-known destinations | NO | MISSING |
| 54 | Prefer locator actions with ref ids over page.evaluate | partial | MISSING |
| 55 | Pack action and snapshot in one call when the next step is state-independent | NO | MISSING |
| 56 | Split calls after a snapshot when the next action depends on updated refs | NO | MISSING |
| 57 | Treat an action as unconfirmed until a fresh snapshot shows the expected state | repl-api.md:154 | PRESENT |
| 58 | Accepted website state is evidence; recheck only on a concrete contradiction | NO | MISSING |
| 59 | On unexpected state suspect a missed, stale, or wrong-target action first | NO | MISSING |
| 60 | openTab and click already wait for interactivity and DOM stability | repl-api.md:13 partial | MISSING |
| 61 | Never add a redundant sleep right after navigation or an action | NO | MISSING |
| 62 | Use sleep only when a fresh snapshot shows the page still transitioning | NO | MISSING |
| 63 | No scroll needed; snapshot includes off-screen and click scrolls to targets | NO | MISSING |
| 64 | Prefer available autofill paths for ID/PW, email, payment, address forms | credentials.md:143 | PRESENT |
| 65 | If autofill does not finish, take a fresh snapshot and continue manually | credentials.md:158 | PRESENT |
| 66 | ASK USER AS THE LAST RESORT | SKILL.md:198 forbids questions in exec | CONTRADICTS-CORRECTLY |
| 67 | Use fetch only for same-origin or explicitly trusted download urls | NO | MISSING |
| 68 | Resolve the href against page.url, check res.ok, write the Buffer | NO | MISSING |
| 69 | Blob, redirect, POST-backed, and button downloads use download handling | NO | MISSING |
| 70 | Verify the file path returned by download.path | NO | MISSING |
| 71 | Use download.saveAs only when an artifacts copy is actually needed | NO | MISSING |
| 72 | Record suggestedFilename, the download path, and the size | NO | MISSING |
| 73 | fs cannot browse the real ~/Downloads directory | SKILL.md:203 says downloading there is fine | CONTRADICTS-WRONGLY |
| 74 | In one-shot repl verify the download inside the same command | NO | MISSING |
| 75 | After downloading a document, extract facts with local document tools | NO | MISSING |
| 76 | Report only facts found in the file or confirmed on the page | SKILL.md:324 | PRESENT |
| 77 | Save user-visible PDFs and downloads under ./artifacts/ | NO | MISSING |

## Not official rules

Two facts that earlier drafts wrongly counted as official statements. Both are our
own measurements, and neither appears as a normative line in the official text, so
they do not belong in the ledger:

- repl `pwd` is `~/.aside/u/0/sessions/<session-id>`, which is what makes the
  official `./artifacts/` recommendation compatible with our write confinement. The
  official doc recommends the path without saying where it resolves; that gap is
  row 77 above, classified MISSING.
- repl `fs` refuses any path outside the roots with
  `Path escapes Project and session roots: <path>`, throwing rather than suspending.
  The official text only says `fs` cannot browse `~/Downloads` (row 73). The general
  boundary is ours to document, not a rule we agree or disagree with.
