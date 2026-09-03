# aside-skill

A Codex skill for driving the [Aside](https://asidehq.com) browser CLI without
losing work to a prompt nobody can answer.

Aside is a Chromium fork with a built-in browser agent, and its CLI runs that agent
against your real logged-in profile. That makes it useful for anything behind a
login, and it also makes it easy to lose work quietly: a non-interactive
`aside exec` cannot answer a permission prompt or a question, so through 1.26.831
it waited forever, and since 1.26.902 it denies the call and moves on with exit 0.
This skill encodes the rules that avoid both.

It also covers research behind a login, which is the thing Aside can do that a hosted
web search cannot. The same X search URL returned 289KB with no tweet markup to
`curl`, a sign-in wall to a browser with no session, and a full tree of results to a
signed-in Aside repl. `aside-jun/references/deep-research.md` splits that work between
Codex, repl, and exec and gives the recipes.

It is also checked against Aside's own guidance rather than written beside it. Aside
ships an `aside-browser` skill as a string constant inside its daemon binary; every
normative line in it was extracted and classified, 77 rows in total, and the result
is in `devlog/_plan/260831_aside-official-parity/001_parity-ledger.md`. Three of
those rows were places this skill was wrong and have been fixed. One is a place
Aside's own advice deadlocks a CLI run - "ASK USER AS THE LAST RESORT" - and is
deliberately overridden. The rest of the official protocol is now carried here, so
you should not need to read both.

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
  references/         permissions, repl API, deep research, credentials,
                      scheduling, builtin catalog, superseded skill
  scripts/            regenerate the builtin-skill catalog after an Aside update
devlog/               how the skill was researched and built
```

## What it covers

The skill leads with the failure mode, because it is silent either way. Through
1.26.831 a suspended run printed its tool-call line and then nothing; on 1.26.902
an outside-root file call is denied by policy and the run continues, so a skipped
step shows only in the transcript. Both were verified against a live install.
`--permission full-access` removes the deny for the paths a task names, and the
fixed prompt contract plus a host timeout cover the rest.

It also routes work between the two surfaces. `exec` delegates to Aside's agent for
logins, judgment, and Aside's own builtin skills. `repl` is a Playwright-style
surface Codex drives directly, and it throws on a bad path, where exec under
`guard` skips it.

`aside-jun/references/permissions.md` documents the mechanism with reproduction
commands, including the `--permission` flag and the narrower grant-run-restore
sequence for a task that needs one outside directory.
`devlog/_plan/260830_aside-skill/000_research.md` has the full binary analysis.

## Requirements

Aside installed with its CLI on `PATH`, and at least one signed-in account. Verify
with `aside account list`.

The skill was rebuilt against CLI `1.26.902.1732` and daemon `1.26.902.1713` on
macOS (first built on 1.26.810 / 1.26.829). Offsets cited in the research notes are build-specific; the behavioral rules
are not.
