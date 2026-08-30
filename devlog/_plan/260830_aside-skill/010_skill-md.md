# 010 - SKILL.md authoring spec

Consumed by work-phase wp1-skill. One PABCD cycle.

## Frontmatter

```yaml
---
name: aside
description: Drive the Aside browser CLI for authenticated web work - reading logged-in pages, running browser automation, and delegating multi-step web tasks to the Aside agent. Use when a task needs a real signed-in browser session rather than an HTTP fetch.
---
```

Boundary clause matters: this must not attract plain HTTP fetches or generic
browser QA that agbrowse already covers.

## Body outline (target: under 150 lines)

1. **Two surfaces, one decision.** A short table routing work to `exec` vs `repl`.
   exec = delegate to the Aside agent (login, multi-step judgment, Aside's builtin
   skills). repl = Codex drives the browser directly, Playwright-style.

2. **The hang rule.** This leads the body, not an appendix. Three proven classes,
   one signature, no recovery. State plainly that a hung exec can only be ended by
   the shell timeout.

3. **The exec prompt contract.** Three standing clauses that every exec prompt
   carries. Give a copy-paste template, not prose describing a template.

4. **repl quick reference.** openTab/snapshot/refs/locator/cua loop with a working
   example. Point to references/repl-api.md for the full surface.

5. **What Aside owns.** Name the builtin skill set and say to instruct exec to use
   them by name. Point to references/builtin-skills.md.

6. **Verify, do not trust.** The agent narrates success; confirm independently.

7. **Troubleshooting.** Model 401, mcp silence, account selection.

## Non-negotiable content

- Omit `-m` by default. Mention `strictModelSelection` as the reason.
- `~/.aside/u/0/` is the only write target. Downloads land in `~/Downloads` and
  get relocated.
- Never let exec ask a question.
- Reads outside the roots hang exactly like writes.

## Out of scope

Do not document Aside settings mutation, account switching beyond `account use`,
or anything requiring the GUI.

## Audit amendments (round 1)

- **Host deadline is mandatory.** Every exec example uses `timeout 300 aside exec`.
  The body is explicit that a fired timeout kills the CLI but not the work already
  done: completed writes, downloads, submissions and messages persist, so the real
  state must be inspected before retrying or a rerun duplicates a side effect. The
  Aside session survives as `status: suspended` with `suspension.kind` of
  `approval` or `ask-user-question` and accumulates rather than clearing itself;
  resuming it with `--session` is forbidden. These sessions are `ephemeral` and
  therefore invisible to `aside.sessions.list()`, which reports zero while several
  are parked, so SKILL.md documents a read-only `state.db` query instead. Whether a
  hidden ephemeral session can be answered in the Aside UI is unconfirmed and must
  not be asserted.
- **Account scope is fixed to u0.** `--account` is omitted from the options list
  because every clause hardcodes `~/.aside/u/0/`; the body explains that another
  account moves the root and invalidates the clauses, and the troubleshooting entry
  requires rewriting the root before running anything.
- **The three clauses are literal.** SKILL.md carries them verbatim in a `text`
  block and again inside an assembled example. The read clause explicitly forbids
  `~/Documents` and every other local path, because guard technically allows those
  roots and a near-miss path is what suspends.
- **permissions.md is routed** from the hang section with a stated read condition.
- **The 401 troubleshooting entry** is generalized to "a model error such as", with
  a repl command for reading the account's configured default rather than an
  unsourced claim about one model id.
