# 020 - references and demotion spec

Consumed by work-phase wp2-refs.

## references/refskill-aside.md

Source: the current `~/.codex/skills/aside-cli/SKILL.md`.

Transform: strip the YAML frontmatter block entirely, including both `---`
delimiters and the `name`/`description`/`metadata` keys. The file must begin with a
Markdown heading so no skill loader can index it. Add a one-line note at the top
explaining that it is retained as historical reference and superseded by the
parent skill.

Verification: `head -1` must not be `---`.

## references/builtin-skills.md

A generated summary of the builtin skills in `~/.aside/u/0/skills/builtin/`. The
hierarchy is NOT flat: 33 top-level directories each carry their own SKILL.md, and
one container, `site-specific/`, carries no SKILL.md of its own while holding 16
per-site skills a level deeper. Enumerate `*/SKILL.md`, never `*/`, so the
container is never emitted as a loadable skill.

Two tables, each with a `Backing` column marking an entry as `repl global` or
`instructions`, so a reader can tell which skills expose a JS object that Codex
could drive from repl directly. Verify that list against the live repl scope after
an Aside update rather than assuming it.

Not full copies. The point is letting Codex name the right skill when instructing
exec.

## references/repl-api.md

The Playwright-shaped surface recovered from the daemon: page methods, locator
actions, snapshot/refs semantics, cua coordinate fallback, the fs jail rules, and
the exact rejection string.

## references/permissions.md

The guard model, the three hang classes with their evidence, the suspend
mechanism, and the absence of any escape flag. This is the "why" behind the
SKILL.md rules; SKILL.md itself stays imperative.

## scripts/refresh-builtin-summary.sh

Regenerates builtin-skills.md by reading each builtin SKILL.md frontmatter
description. This is the documented update path. Must be run and verified, not
just written.

## Audit amendments (round 1)

The installed layout is **not** 34 uniform skills. It is 33 top-level directories,
each with its own SKILL.md, plus one container `site-specific/` that has **no
SKILL.md of its own** and holds 16 per-site skills one level deeper.

The first refresh script counted directories and therefore emitted a
`site-specific | (no description)` row for a thing that cannot be loaded. Fixed:

- Iterate `*/SKILL.md` rather than `*/`, so a container without a manifest is
  never listed as a skill.
- Emit a second table for `site-specific/*/SKILL.md` with a note that the container
  is not itself loadable.
- Add a `Backing` column marking each top-level skill as `repl global` or
  `instructions`, so the reader can tell which skills expose a JS object that Codex
  could drive directly from repl.
- Report both counts explicitly in the generated header.
