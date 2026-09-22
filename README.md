# aside-skill

Use [Aside](https://aside.com) from Codex, Claude Code or another coding agent.
The `aside-jun` skill chooses between direct **aside-codemode** calls, native
Aside REPL, and delegation to Aside's own agent. It also connects visual document
work to the user's Aside **dev-visualizer** skill.

| Task | Execution |
|---|---|
| Known independent URLs/files/searches/captures | Caller invokes aside-codemode directly via its available MCP or CLI |
| First inspection, one visible action, current tab, dependent flow | Native Aside REPL |
| Login or a task needing browser judgment | Aside `exec` |
| Composed HTML/SVG/report/PDF through Aside | Aside `exec` loads account skill `dev-visualizer` |

The skill does not install these tools or enforce another agent's behavior. It
provides routing instructions and executable recipes. Explicit user choices and
host permissions still apply. Public HTTP work and unrelated local coding work
stay with the host's tools unless Aside/code mode was requested.

## Direct calls from a coding agent

If the caller already exposes an identified aside-codemode MCP tool, inspect its
live schema and call it. Otherwise use the installed CLI. Save this async guest
body as a task-owned `batch.js`:

```js
const hits = await search.content({ path: '.', query: 'TODO', max: 20 });
const paths = [...new Set(hits.map(hit => hit.file))];
const excerpts = await fs.readMany(paths, { maxBytes: 4096, totalBytes: 8192 });
return { hits, excerpts };
```

With `codemode` already resolved and configured for the authorized project:

```bash
codemode --cwd /absolute/project --code-file /absolute/batch.js
```

For controlled execution use the resolved absolute Node/CLI pair. See
[the codemode cookbook](aside-jun/references/codemode.md) for Bash/PowerShell,
MCP payloads, version discovery, browser batches and failure handling. `--cwd`
does not grant filesystem access. Read result metadata and per-file errors;
`ok:true` or process exit zero is not a complete-content guarantee.

**Aside MCP registration and caller MCP registration are different.**
`codemode --install-mcp` configures Aside; it does not attach a tool to Codex or
Claude Code. Tool prefixes vary by caller. Codex's native Code Mode is also a
different runtime: codemode guest globals are available only inside codemode.

## Install the skill

Only `aside-jun/` is installed. `devlog/` contains the source investigation and
verification records. Clone this repository, then copy the directory contents to
the chosen agent's skill directory:

```bash
git clone https://github.com/lidge-jun/aside-skill.git
```

### Codex

```bash
skill_dest="${CODEX_HOME:-$HOME/.codex}/skills/aside-jun"
mkdir -p "$skill_dest"
cp -R aside-skill/aside-jun/. "$skill_dest/"
```

### Claude Code

```bash
skill_dest="$HOME/.claude/skills/aside-jun"
mkdir -p "$skill_dest"
cp -R aside-skill/aside-jun/. "$skill_dest/"
```

For a project-only Claude install use `.claude/skills/aside-jun/`. Keep the whole
folder so relative references resolve. Invoke `/aside-jun`, or let the matching
description select it. See [Claude skills documentation](https://code.claude.com/docs/en/skills).

### Windows PowerShell

Choose the actual destination, then copy the contents rather than nesting an
extra `aside-jun` directory on updates:

```powershell
# Codex: respect CODEX_HOME when set. For Claude use
# $skillDest = Join-Path $env:USERPROFILE '.claude\skills\aside-jun'
$codexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$skillDest = Join-Path $codexRoot 'skills\aside-jun'
New-Item -ItemType Directory -Force -Path $skillDest | Out-Null
Get-ChildItem -Force -LiteralPath 'aside-skill\aside-jun' |
  Copy-Item -Recurse -Force -Destination $skillDest
Get-Item -LiteralPath (Join-Path $skillDest 'SKILL.md')
```

Copying replaces matching files; back up user-edited skill files before an update.
Reload the skill in the agent before checking the new routing behavior. This task's
repository changes do not automatically update installed copies.

### Other agents

Point a compatible skill loader at `aside-jun/SKILL.md`, preserving its supporting
files. For a rules-only host, add a rule that tells the agent when to read that
file and its selected references; copying just the entrypoint loses the cookbook.
No agent-specific MCP tool name or plugin installation is assumed.

## Optional capabilities and setup

- Aside CLI/browser: follow the [official setup](https://docs.aside.com/help/developers).
  Windows now has a signed PowerShell installer that adds user PATH; Settings >
  Developers also installs the CLI. Historical fallbacks are in the host reference.
- [aside-codemode](https://github.com/lidge-jun/aside-codemode): install/configure
  only when requested. The 0.9.0 result contract is the baseline for complete
  search disclosures; do not silently upgrade an older installation.
- [aside-visualizer](https://github.com/lidge-jun/aside-visualizer): installs as
  `dev-visualizer` inside a selected Aside account. See the
  [handoff recipe](aside-jun/references/visualizer.md). It is not automatically
  installed alongside this coding-agent skill.

Browser use needs a verified account/host context. Codemode 0.9.0 does not expose
per-call browser account/host selectors, so a nondefault requirement may need
native Aside with explicit flags. Local filesystem batches need no browser login.

## Layout

```text
aside-jun/
  SKILL.md                 common routing and execution boundaries
  agents/openai.yaml       Codex UI metadata
  references/codemode.md   direct caller CLI/MCP recipes
  references/visualizer.md Aside account skill handoff
  references/exec.md       noninteractive delegation contract
  references/compatibility.md dated evidence and known differences
  references/              REPL, credentials, host, research and scheduling details
  scripts/                 catalog refresh, session prep and element-crop helpers
devlog/                    source research, plan and verification evidence
```

## Verification and limits

The [compatibility reference](aside-jun/references/compatibility.md) separates
current official docs, installed versions and runtime probes. New CLI/MCP recipes
were checked against a temporary 0.9.0 source snapshot without upgrading the
installed package or modifying accounts. Browser schema validation does not prove
authenticated rendering, and raw MCP protocol smoke does not prove a specific
Codex/Claude host has attached that server.

Older permission and session-retention measurements remain dated diagnostics.
No blanket disabling of biometrics or automatic full-access/persistence changes
is needed to follow the skill. Actual artifacts and destination state, not an
agent's success narrative, are the completion evidence.

## Native REPL compatibility helpers

The [REPL reference](aside-jun/references/repl-api.md) includes idempotent session
directory preparation and verified element capture. The latter captures a full
viewport and crops on the caller host with an already available Pillow runtime:
native locator screenshots fail and native clip origin can be ignored. These are
skill-level mitigations for issues #1/#2, not patches to Aside's daemon.
