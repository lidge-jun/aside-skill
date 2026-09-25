# wp2 result — parallel REPL works

Parallel `aside repl` is safe on CLI 1.26.906.1630 / macOS. Four and eight
concurrent one-shot processes all finished `[ok |`, every tab was closed, and
no session ever saw another session's tab. One trap was found: inside one
session, the global `page` after concurrent `openTab` calls is whichever tab
settled last, not the last one requested.

Measured 2026-09-26 00:01 KST, `--account u0 --host local`, raw output in
`evidence/parallel-260925/`, script `evidence/parallel-repl-probe.sh`.

## Numbers

| Case | Wall (s) | Result |
|---|---|---|
| 4 sequential one-shots | 3.61 | 4/4 ok, titles correct |
| 4 concurrent one-shots | 1.61 | 4/4 ok, 2.2× faster than sequential |
| 8 concurrent one-shots | 3.01 | 8/8 ok |
| 1 session, `Promise.allSettled(openTab ×4)` | 1.03 | 4/4 fulfilled, 4 distinct targetIds |
| Isolation A (held 8 s) / B (opened at +3 s) | — | A's `tabs`/`page` identical before and after B; B saw only its own tab |

21 `exit=0` lines, 0 files without an `[ok |` marker, 0 error lines.
Leak check by targetId: 22 probe-owned tabs, 0 present in the after list
(browser had 7 unrelated user tabs before and after).

## What this means for the skill

- Independent read-only page work may fan out as concurrent one-shot
  `aside repl` processes; each gets its own temporary session and its own
  `tabs`. 4–8 at once was fine here; this is not a published limit.
- Inside one session, `Promise.allSettled(urls.map(openTab))` is the fastest
  shape (1.03 s for 4). Use the returned Page handles; **do not read the
  global `page` after concurrent opens** — observed `pageNow` was the 2nd of 4.
- Close each tab in `finally` and track by `page.targetId`, which equals the
  `listBrowserTabs()` entry's `targetId`.
- Parallelism does not extend to dependent steps, forms or logins
  (existing SKILL.md rule stands).
