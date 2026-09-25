# CLI 1.26.906 sync, parallel REPL probe and fleet deploy

The user asked for the 2026-09-25 feedback to be folded into `aside-jun`, a
parallel REPL probe to be run and recorded, the change pushed, every installed
copy (this Mac and `ssh mini`) updated, and a visual report produced. A later
message added one more requirement: the skill must say that `aside exec` can
sign in by itself through the password manager, so an agent delegates login
before asking the user to sign in by hand.

The feedback came from driving CLI 1.26.906.1630 on macOS on 2026-09-25. The
findings are the inputs; each work-phase below consumes one of them.

## Inputs (measured 2026-09-25, macOS, CLI 1.26.906.1630)

- F1. `~/.claude.json` registers `aside mcp`; the session exposes native
  `exec`, `repl`, `memory_search`. SKILL.md routes only aside-codemode MCP.
- F2. `aside memory search|list|show|path` is read-only and the official guide
  says to query it before asking the user; SKILL.md never mentions it.
- F3. `aside exec` exited 0 on a provider 403 (quota). REPL exits 0 on thrown,
  syntax and reference errors (already in repl-api.md).
- F4. A subcommand passed as one argv (`"account list"` under zsh) became a
  prompt and started an agent session. Generalises the `aside version` note.
- F5. `codemode` has no `--version`/`--help` (EBADARGV). Three installs on the
  Mac: `~/.local/bin` and nvm resolve to `~/aside-codemode` 0.9.2,
  `/opt/homebrew` is 0.9.1. SKILL.md still describes "Released codemode 0.9.0".
- F6. Undocumented CLI surface: `session list/archive/delete`,
  `host list/use/status`, `settings set-default-profile`, `--effort
  ultrabrowse`, `-s fast`, `skills install` (installs official aside-browser,
  which shadows aside-jun).
- F7. builtin-skills.md is from 902/906 trees; 1.26.916.1741 is offered.
- F8 (user, 2026-09-25). In a lidge-ai-web session the coding agent told the
  user to sign in to Cloudflare by hand; the user corrected it: `aside exec`
  can log in on its own. Login is exec's job first; the human is asked only
  after exec reports a concrete blocker.

## Work-phases (one PABCD cycle each)

| id | Outcome | Files |
|---|---|---|
| wp1 | This roadmap (docs only) | `000_roadmap.md` |
| wp2 | Parallel REPL probe, evidence recorded | `010_parallel-repl-probe.md`, `evidence/` |
| wp3 | Skill edits F1–F8 + probe result | `aside-jun/SKILL.md`, `references/{exec,credentials,codemode,repl-api,compatibility}.md` |
| wp4 | Commit, push aside-skill, bump parent `aside`, deploy all installs | `020_deploy.md` |
| wp5 | Visual report (HTML) | `030_report.html` |

## wp2 probe design

Read-only, public pages only (example.com, example.org, iana.org). Measure:

1. N=4 concurrent one-shot `aside repl` processes, each `openTab` → `snapshot`
   → `closeTab`, wall time vs sequential, all `[ok|` markers, no leaked tabs
   (`listBrowserTabs` before/after).
2. One REPL call opening 4 tabs with `Promise.all` inside a single session.
3. Tab isolation: two concurrent processes never see each other's `page`.

Pass: every run ends `[ok |`, titles correct, tab count returns to baseline.

## wp3 diff-level plan

- SKILL.md: add route row "native Aside MCP (`exec`/`repl`/`memory_search`)
  attached to this caller → prefer it over shelling out"; add "Login is
  delegated" bullet (F8); add memory lookup bullet (F2); add argv/prompt trap
  (F4); widen exit-0 statement (F3); replace 0.9.0 paragraph with version
  identification (F5); forbid `aside skills install` (F6).
- exec.md: login delegation section + provider-error detection + session
  list/archive/delete.
- credentials.md: top summary that exec searches Vault/connected providers
  and SSO on its own; human only for MFA/passkey/CAPTCHA/locked Vault or a
  missing credential that exec reported.
- codemode.md: version identification recipe; multiple installs.
- repl-api.md: parallel probe result.
- compatibility.md: 2026-09-25 row.

## wp4 deploy targets

- Mac: `~/.claude/skills/aside-jun`, `~/.codex/skills/aside-jun` (copies).
- mini: `/mnt/c/Users/super/.codex/skills/aside-jun` (copy),
  `C:\Users\super\Developers\aside` checkout (pull + submodule update).
- Copy with rsync excluding `.codexclaw/`. Verify with `diff -rq`.
- Push only `lidge-jun/aside-skill` and `lidge-jun/aside` (never the `new`
  root repo).

## Non-goals

No Aside app/CLI update, no codemode release, no settings changes, no login or
account-touching probes.

## Audit fold (A, 2026-09-25, reviewer verdict NEAR-PASS)

- B1 folded: wp3 also edits `references/builtin-skills.md` (staleness note:
  catalog is from 902/906 trees, 916 offered) plus the compatibility row.
- B2 folded: F8 rewrites existing wording in this order — (a) delegate login
  to `exec` first and do not ask the user to sign in or unlock beforehand;
  (b) ask the human only after exec reports a concrete blocker (locked Vault,
  MFA, passkey, CAPTCHA, missing credential, policy `Never`). Verified path is
  Vault / `passwordManager` autofill; SSO is exec's judgment and marked
  unmeasured. Exec login stays within the task's authorization: no account
  switching, no policy changes, no new account creation without the user.
- B3 folded: parent bump stages only `aside-skill` (`git add aside-skill`),
  never `-a`/`.`; the other dirty pointers stay as they are.
- Suggestions taken: wp2 judges leaks and isolation by the probe's own
  targetIds, `closeTab` in `finally`, explicit `--account u0 --host local`;
  F1 wording: `memory_search` comes from the guide / attached tool list, not
  `mcp --help`; `skills install` = "only on explicit user request";
  deploy with `rsync -a --delete --exclude .codexclaw/`; check mini checkout
  clean and look for a Claude skills dir there too.
