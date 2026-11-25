# CLI 1.26.1115 sync (2026-11-26)

Baseline: macOS (juns-MacBook-Pro) Aside CLI 1.26.1115.1556; `aside guide` offers 1.26.1121.1917 (not installed).
Official agent skill: `aside-browser` v5 (defers to `aside guide`).

## Measured
- repl: throw / ReferenceError / root escape -> exit 1; `--json` -> `{run:{content,error,elapsedMs}}`; stdin and `--file` work; `getTabs` undefined.
- exec: trivial run `--json --timeout 90s` -> exit 0, `{session:{id},outcome:"completed",answer:"OK",error:null}`, empty stderr.
- `aside mcp` tools: exec, repl, memory_search, browser_profiles (server aside 1.26.1115.1556).
- Guard: default-mode exec read /etc/hosts and wrote /tmp (exit 0) with outside-root policy `ask` -> do not rely on Guard as a fence.
- Windows desktop-c795oh4: CLI still 1.26.906.1630, Aside not running -> every repl call exit 1 before execution. Live-run exit codes on Windows not re-measured.
- codemode: npm latest 0.9.2; shell codemode 0.9.2, Aside's codemode MCP 0.9.1; no profile selection; `desktop.*` merged on main, unreleased.
- `aside skills list`: 9 names; builtin tree regenerated (added computer-use, google-people, nordpass, visualize; gone context-awareness, google-search).

## Doc drift found in Aside's own guide
`aside guide` still shows `settings save-sessions true` and `settings set-default-profile`; `--help` uses `enable|disable` and `account use`.

All probe sessions were deleted with `aside session delete <id> --yes`.
Work split: parent (SKILL/exec/repl/compat/host-macos) + 4 parallel lanes (Windows, codemode, permissions/credentials/scheduling/deep-research/visualizer, builtin/scripts/README/refskill).
