# aside-skill

A Codex skill for driving the [Aside](https://asidehq.com) browser CLI without
deadlocking it.

Aside is a Chromium fork with a built-in browser agent, and its CLI runs that agent
against your real logged-in profile. That makes it useful for anything behind a
login, and it also makes it easy to hang: a non-interactive `aside exec` cannot
answer a permission prompt or a question, so it waits forever with no error output.
This skill encodes the rules that avoid that.

## Install

Only the `aside-jun/` directory is the skill. Copy it into your Codex skills
directory:

```bash
git clone https://github.com/lidge-jun/aside-skill.git
cp -R aside-skill/aside-jun ~/.codex/skills/aside-jun
```

Or without keeping the clone:

```bash
git clone --depth 1 https://github.com/lidge-jun/aside-skill.git /tmp/aside-skill
cp -R /tmp/aside-skill/aside-jun ~/.codex/skills/aside-jun
rm -rf /tmp/aside-skill
```

If `CODEX_HOME` is set, install to `"$CODEX_HOME/skills/aside-jun"` instead.

Rename the destination directory if you want a different skill name; the folder
name and the `name:` field in `aside-jun/SKILL.md` should match.

Verify:

```bash
ls ~/.codex/skills/aside-jun/SKILL.md
```

Do not copy `devlog/`. It holds the research and planning notes behind the skill,
not skill content.

## Layout

```
aside-jun/            the skill itself - this is what gets installed
  SKILL.md            entrypoint: hang rules, exec contract, repl routing
  agents/             UI metadata
  references/         permissions, repl API, builtin catalog, superseded skill
  scripts/            regenerate the builtin-skill catalog after an Aside update
devlog/               how the skill was researched and built
```

## What it covers

The skill leads with the failure mode, because it is silent and unrecoverable. A
suspended run prints its tool-call line and then nothing at all, which is
indistinguishable from slow work.

Three ways to trigger it, all verified against a live install: writing outside the
allowed roots, reading outside them, and asking the user a question. The daemon
suspends the run awaiting a human verdict while the CLI waits on a promise with no
timeout, and the CLI protocol has no verb that can answer. No flag disables this,
so the skill prevents it with a fixed prompt contract and a mandatory host timeout.

It also routes work between the two surfaces. `exec` delegates to Aside's agent for
logins, judgment, and Aside's own builtin skills. `repl` is a Playwright-style
surface Codex drives directly, and it fails fast on a bad path instead of hanging.

`references/permissions.md` documents the mechanism with reproduction commands.
`devlog/_plan/260830_aside-skill/000_research.md` has the full binary analysis.

## Requirements

Aside installed with its CLI on `PATH`, and at least one signed-in account. Verify
with `aside account list`.

The skill was built against CLI `1.26.810.1915` and daemon `1.26.829.1514` on
macOS. Offsets cited in the research notes are build-specific; the behavioral rules
are not.
