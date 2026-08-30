# aside-skill

A Codex skill for driving the [Aside](https://asidehq.com) browser CLI without
deadlocking it.

Aside is a Chromium fork with a built-in browser agent, and its CLI runs that agent
against your real logged-in profile. That makes it useful for anything behind a
login, and it also makes it easy to hang: a non-interactive `aside exec` cannot
answer a permission prompt or a question, so it waits forever with no error output.
This skill encodes the rules that avoid that.

## Install

Only the `aside-jun/` directory is the skill. `devlog/` is research and planning
notes; do not install it.

```bash
git clone https://github.com/lidge-jun/aside-skill.git
```

Then copy `aside-jun/` into whichever agent you use.

### Codex

```bash
cp -R aside-skill/aside-jun ~/.codex/skills/aside-jun
ls ~/.codex/skills/aside-jun/SKILL.md
```

Use `"$CODEX_HOME/skills/aside-jun"` when that variable is set.

### Claude Code

Same layout, no conversion needed: this skill already uses `SKILL.md` with
`name` + `description` frontmatter, and `references/` + `scripts/` are exactly the
supporting-file structure Claude Code expects.

```bash
cp -R aside-skill/aside-jun ~/.claude/skills/aside-jun
```

The **directory name becomes the slash command**, so this installs as
`/aside-jun`. Claude Code also loads it automatically when a request matches the
`description`. Confirm with `/skills`.

For a project-only install use `<project>/.claude/skills/aside-jun/` instead.
Claude Code picks up edits during a session, but restart it if you created
`~/.claude/skills/` after launching. Uninstall by deleting the directory.

Reference: [Extend Claude with skills](https://code.claude.com/docs/en/skills).

### Cursor

Cursor does not read `SKILL.md`. It uses **project rules** under `.cursor/rules/`,
the file must end in `.mdc` (a plain `.md` there is ignored), and the frontmatter
keys are `description`, `globs`, and `alwaysApply`. Convert:

```bash
mkdir -p .cursor/rules
{
  echo '---'
  echo 'description: "Drive the Aside browser CLI for authenticated web work without hanging it"'
  echo 'alwaysApply: false'
  echo '---'
  echo
  sed '1{/^---$/!q;};1,/^---$/d' aside-skill/aside-jun/SKILL.md
} > .cursor/rules/aside-jun.mdc
```

That strips this repo's header and writes Cursor's. With `description` set and
`alwaysApply: false`, Cursor decides when the rule applies. Use
`alwaysApply: true` to load it every session, or `globs:` to attach it only when
matching files are in context; with no activation field it becomes a manual rule
invoked as `@aside-jun`.

Caveat: relative links to `references/` will not resolve from `.cursor/rules/`.
Copy `references/` alongside the rule, or rely on the entrypoint alone.

Reference: [Cursor Rules](https://cursor.com/docs/rules).

### Other agents

The skill is plain Markdown with YAML frontmatter, so most agents that read a
prompt file will take it. Point the agent at `aside-jun/SKILL.md`, or paste it in
if the tool has no skill directory. Rename the destination folder freely, but keep
it matching the `name:` field inside `SKILL.md`.

A skill is a capability; a plugin marketplace is a distribution mechanism. This
repository is a standalone skill installed by copying a directory, so there is
nothing to `/plugin install` here.

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
