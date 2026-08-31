# 010 - SKILL.md corrections

Fix our own defects first, then state the official overrides where we are right.

File ownership: this phase owns `aside-jun/SKILL.md` only. Where the same defect
also appears in `references/repl-api.md`, that copy belongs to 020, so each file has
exactly one owner and the two cycles stay independent.

## Remove snapshot truncation from examples

Current SKILL.md repl example uses `s.tree.slice(0, 2000)` and repl-api.md does the
same. Both teach the habit the official doc forbids. Replace with printing `tree`
directly and `diff` after an action, and add the rule:

> Never truncate a snapshot with `slice`, `substring`, or `split`. The ref you need
> is often the one that gets cut.

Adopt the official `const s1`, `const s2` naming so earlier snapshots stay usable.
The identical `.slice()` in `references/repl-api.md` is 020's to fix.

## Replace the persistence sentence

Delete "Scope persists across one session" and state the measured lifetime: each
`aside repl` invocation is its own session; bindings, `page`, `tabs`, and refs die
with the process, and tabs it opened are closed. Give the two consequences - keep a
flow in one call, or reattach a window tab with `attachBrowserTab`.

## Fix the ~/Downloads clause

The standing clause says downloading to `~/Downloads` is fine. That is true for the
exec agent's bash tool and false for repl `fs`, which cannot browse it. Keep the
clause for exec, and note in the repl section that `fs` cannot read `~/Downloads`;
a registered download is readable through `download.path()` within the same
invocation.

## State the ASK USER override

Quote the official "ASK USER AS THE LAST RESORT" and refute it for non-interactive
exec, with the mechanism: `ask` verdict suspends, no CLI verb answers, no timeout.
Give the agent the alternative ladder instead of a bare prohibition - inherited
session, vault match, external provider, password/OAuth fallback behind "Try
another way", available TOTP, captcha tools - then a clean stop naming the exact
blocking screen.

## Add the login decision tree

One compact tree covering: already signed in, vault autofill available, 1Password
locked, passkey prompt, 2FA/TOTP, CAPTCHA, biometrics. Each leaf names the surface
(CLI repl / exec / exec's repl tool) and the concrete call. Ground every call in a
builtin skill or a verified run; invent nothing.

## Record artifact path resolution

`pwd` is `~/.aside/u/0/sessions/<session-id>`. Say it once, so `./artifacts/` is
understood as inside the account root rather than looking like a violation.
