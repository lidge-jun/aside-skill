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

## Install for other agents

The skill is a plain `SKILL.md` plus supporting files, which is the same shape
Claude Code uses, so most agents take it with a copy.

### Claude Code

Personal skills live in `~/.claude/skills/<skill-name>/SKILL.md`, and the
**directory name becomes the slash command**:

```bash
git clone https://github.com/lidge-jun/aside-skill.git
cp -R aside-skill/aside-jun ~/.claude/skills/aside-jun
```

Verify with `/skills` inside Claude Code, then invoke it as `/aside-jun`. Claude
Code also picks it up automatically when a request matches the `description`.

Claude Code watches `~/.claude/skills/` and usually notices edits during a
session, but if you created the top-level directory after starting Claude Code,
restart the session. For a project-only install use
`<project>/.claude/skills/aside-jun/SKILL.md` instead. Remove it by deleting the
directory.

No conversion is needed: this skill's frontmatter is already `name` +
`description`, and its `references/` and `scripts/` directories are exactly the
supporting-file layout Claude Code expects.

See [Extend Claude with skills](https://code.claude.com/docs/en/skills).

### Cursor

Cursor does not read `SKILL.md`. It uses **project rules** in `.cursor/rules/`, and
the file must be `.mdc` — a plain `.md` in that directory is ignored. The
frontmatter keys differ too: Cursor takes `description`, `globs`, and
`alwaysApply`.

Convert with:

```bash
mkdir -p .cursor/rules
{
  echo '---'
  echo 'description: "Drive the Aside browser CLI for authenticated web work without hanging it"'
  echo 'alwaysApply: false'
  echo '---'
  echo
  sed '1{/^---$/!q;};1,/^---$/d' aside-jun/SKILL.md
} > .cursor/rules/aside-jun.mdc
```

That strips this repo's YAML header and writes Cursor's. With `description` set and
`alwaysApply: false`, Cursor's agent decides when the rule is relevant. Set
`alwaysApply: true` to include it in every session, or add
`globs: "..."` to attach it only when matching files are in context. With no
activation field at all it becomes a manual rule you invoke as `@aside-jun`.

One caveat: the relative links to `references/` will not resolve from
`.cursor/rules/`. Either copy `references/` alongside the rule, or accept that the
entrypoint is self-contained enough for most work.

See [Cursor Rules](https://cursor.com/docs/rules).

### Codex

```bash
cp -R aside-jun ~/.codex/skills/aside-jun
```

Or `"$CODEX_HOME/skills/aside-jun"` when that variable is set.

### A note on plugins

A skill is a capability; a plugin marketplace is a distribution mechanism. This
repository is a standalone skill, installed by copying a directory. It is not a
Claude Code plugin marketplace, so there is nothing to `/plugin install` here.
