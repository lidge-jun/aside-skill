# Compatibility and evidence status

This snapshot was assembled on **2026-09-22**. Version presence, source support,
and end-to-end runtime compatibility are different claims. Use current CLI help,
the active Aside guide, and the resolved package source when they conflict with an
older website example or an installed copy. Do not update an app, CLI, package, or
account configuration solely to match this table.

## Version matrix

| Surface | Version | Evidence on 2026-09-22 | What it proves |
|---|---:|---|---|
| Installed Aside CLI | `1.26.906.1630` | Local `aside --version` observation recorded in this repository | The inspected host had this CLI. It is not the minimum or current required version. |
| CLI update offered | `1.26.916.1741` | The installed CLI advertised this update; no update was run | An offer existed for that host. It does not prove the offered build was installed or exercised. |
| Installed Aside app | `1.0.914.1` | Local app version observation | The inspected app had this version. No live browser compatibility run was performed for this documentation unit. |
| Official Aside components | `1.26.917.1731` | [Official components changelog](https://docs.aside.com/changelog/components), dated 2026-09-17 | Official source describes this component release, including current multi-account Vault ownership behavior. It does not prove the inspected host ran it. |
| aside-codemode GitHub `main` | `0.9.0` at `b76c911318ebe64f03dffb7bb27b37b23ebab777` | Source inspection plus browser-disabled fixture execution | The current source contract and local guest/MCP fixtures worked at this revision. |
| aside-codemode npm | `0.9.0` | [npm package page](https://www.npmjs.com/package/aside-codemode) | The registry published this version. Registry presence alone is not runtime proof. |
| Local aside-codemode sibling | `0.8.1` | Resolved local package metadata | The installed/local sibling was older. Do not attribute 0.9.0 completeness metadata or options to it without checking. |

Aside app, CLI, daemon, component, and extension versions use separate release
lines. A numerically newer component entry is not proof that every local surface
was updated together.

### 2026-09-25 re-check (macOS)

| Surface | Version | Evidence | What it proves |
|---|---:|---|---|
| Installed Aside CLI | `1.26.906.1630` | `aside --version`, full `--help` walk | Still installed; `memory`, `mcp` (tools `exec`, `repl`), `host`, `session list/archive/delete`, `settings set-default-profile`, `skills install`, `--effort ultrabrowse`, `-s fast` exist on it. |
| CLI update offered | `1.26.916.1741` | `aside guide` footer | Offer only; not installed. |
| aside-codemode npm | `0.9.2` (`latest`) | `npm view aside-codemode version` | Registry state. |
| Local aside-codemode | `0.9.2` checkout via `~/.local/bin` and nvm; `0.9.1` under `/opt/homebrew` | realpath + `package.json` | Two versions coexist; PATH order picks one. |
| Parallel REPL | 4 and 8 concurrent one-shots | `devlog/_plan/260925_cli-906-sync/011_probe-result.md` | Isolation and zero tab leaks on public pages. |

## Source proof and runtime proof

The initial 0.9.0 source snapshot checks used temporary files, narrowed roots,
and browser access disabled. It proved:

- CLI `--code-file`, `--cwd`, `search.content`, and `fs.readMany` for bounded local
  fixtures;
- visible `complete`, `truncated`, `partial`, and `scope.coverage` metadata;
- `EROOT` for an outside-root read and `EGUESTIMPORT` for a Node guest import;
- MCP `initialize` identity `aside-codemode/0.9.0`, an `execute_code` input of
  `{code: string, timeoutMs?: number}`, and execution JSON in `content[0].text`.

Those checks did **not** prove a live browser session, an authenticated site,
current Windows execution, Claude Code integration, or arbitrary caller MCP
configuration. A successful source check or process exit also does not prove an
exhaustive search: inspect completeness metadata and per-item failures.

The local 0.8.1 package may still handle a bounded positive read after its API is
verified. It must not be used to prove exhaustive absence when the 0.9.0
completeness fields are unavailable. Record the actual runtime version separately
from the recipe's source version, and never update it automatically.

## Known boundaries and contradictions

- The [official developer page](https://docs.aside.com/help/developers) documents
  the signed Windows installer and user `PATH` setup. This is source proof; this
  unit did not install it or run a current Windows validation. The 2026-09-11
  junction failure remains a dated fallback in [Windows host](host-windows.md),
  not a universal current-install premise.
- That developer page still shows an older `--session` continuation example.
  Installed help and the official components changelog use `aside session resume`;
  prefer current help for the active CLI.
- The [official Vault documentation](https://docs.aside.com/help/password-manager)
  supports Touch ID and Windows Hello and separates unlock choice from agent access
  policy. Older Apple Passwords helper and biometric observations are retained as
  dated evidence in [Credentials](credentials.md), not current guarantees.
- aside-codemode 0.9.0 accepts execution `--host` and `--account` flags but does
  not propagate them to the native browser spawn. Its MCP call has no per-call
  account or host selector. Use native Aside routing for an unverified nondefault
  account or remote host. Tracking: [aside-codemode issue #44](https://github.com/lidge-jun/aside-codemode/issues/44).
- `--install-mcp` configures MCP inside the selected Aside account; it does not
  prove that Codex, Claude Code, or another caller has attached that server. Inspect
  the caller's actual tool identity and live schema.

For invocation recipes and the older-runtime decision, read
[Code-mode calls](codemode.md). Re-check this matrix whenever a task depends on a
specific version, host, account, browser state, or caller integration.

## Follow-up authenticated-browser check (2026-09-22)

After the initial documentation checks, native Aside REPL and the same verified
0.9.0 codemode snapshot read an existing signed-in GitHub tab on macOS.
`browse.attach` returned `complete:true`, `truncated:false`, the expected
authenticated controls, and `effects:[]`. The borrowed tab remained open afterward.
No login, MFA, credential access or site mutation was attempted. This proves that
one read-only authenticated tab path; it does not prove host MCP attachment or
all browser/account combinations. Neither runtime package was upgraded.

## Follow-up Windows CLI check (2026-09-22)

Windows 11 Pro build 26200, PowerShell 5.1.26100.8655 and existing Node v24.16.0
ran an installed codemode 0.9.0 with the documented absolute Node/CLI pair,
`--config`, `--cwd` and `--code-file`. Two temporary fixture files returned the
expected hits/excerpts and completeness/coverage metadata. Browser access was disabled.
An outside-root compound read reported a per-row error despite outer `ok:true`;
dynamic import returned `EGUESTIMPORT`/exit1. No runtime was installed or upgraded.
This verifies the Windows CLI recipe, not Windows authenticated browsing, Vault,
MFA, GUI launch or the signed installer.

## Deployment update: 0.9.2 (2026-09-22)

The earlier matrix records the investigation baseline. The subsequent deployment
published [aside-codemode 0.9.2](https://github.com/lidge-jun/aside-codemode/releases/tag/v0.9.2)
from commit `0936c1c2f3b4a6bb77524529fb562f7baf9e9a5a`. npm reports `latest: 0.9.2`;
its artifact integrity equals the audited tarball. Registry signature and SLSA
attestation verification passed on a fresh install. The exact main commit passed
the five-job OS/Node CI matrix and release dry-run before OIDC publication.

0.9.2 preserves the per-call MCP selectors described in [Code-mode calls](codemode.md).
It requires explicit `host: "local"` for local artifact materialization, prevents
incomplete identities from reusing persistent state, and rejects malformed
administrative arguments before settings writes. Source-linked installs should
retain their link and be fast-forwarded; registry installs should select the exact
version. Do not infer that an already running MCP process has reloaded new code.
