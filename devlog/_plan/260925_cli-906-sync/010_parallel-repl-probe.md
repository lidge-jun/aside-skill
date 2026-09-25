# wp2 — parallel REPL probe

Previous D (wp1): roadmap locked; this cycle runs the wp2 probe exactly as
designed there, with the audit's targetId suggestions folded in. No skill
text changes in this cycle; the result feeds wp3.

## What is measured

Host macOS, CLI 1.26.906.1630, `--account u0 --host local` passed explicitly,
every call under a 110 s perl alarm (REPL itself caps at 120 s). Public
read-only pages only: example.com/.org/.net and iana.org/help/example-domains.

| Case | Shape | Pass |
|---|---|---|
| base/after | `listBrowserTabs()` targetIds | no probe-owned targetId remains after |
| 10 seq | 4 one-shot `aside repl` in sequence | all `[ok |`, correct title |
| 20 par4 | 4 one-shot processes at once | same, wall < seq |
| 25 par8 | 8 one-shot processes at once | same; record any failure |
| 30 Promise.all | one process, `Promise.all(openTab)` ×4 | 4 distinct targetIds, titles correct |
| 40 isolation | process A holds a tab 8 s while B opens its own | each session's `tabs` contains only its own targetId; A's `page` unchanged after B |

Each job closes its tab in `finally`. Leak is judged by the probe's own
targetIds, not by total tab count (the user's browser is live).

Probe prep finding (P exploration): `openTab()` returns a Page with a
`targetId` string equal to the `listBrowserTabs()` entry's `targetId`, so
leak and isolation checks can match on it directly.

## Files

- Probe script: `evidence/parallel-repl-probe.sh`
- Raw output: `evidence/parallel-260925/`
- Result: `011_probe-result.md`

## Audit fold (reviewer NEAR-PASS)

- Folded: isolation case logs `page`/`tabs` and `Date.now()` before and after
  A's wait, and B logs its own timestamp, so overlap is proven by timestamps.
- Folded: `Promise.allSettled` so a partial open failure still closes every
  opened tab.
- Folded: each job prints `OPEN<n> <targetId>` right after `openTab`, so an
  alarm-killed job leaves a traceable id; base/after list `[targetId, url]`;
  every case records `exit=`.
- Rebutted: "`sleep` may not exist" — `aside guide repl` lists `sleep` among
  REPL globals (`fs, path, Buffer, sleep, display, pwd`).
- Expected titles: example.com/.org/.net → "Example Domain"; iana page →
  "Example Domains".
