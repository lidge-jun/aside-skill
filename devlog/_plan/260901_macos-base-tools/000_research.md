# 000 - macOS base tools

Aside is macOS-only, and the skill's one mandatory safeguard was written in GNU
coreutils. Probed a stock machine, macOS 27.0 arm64 with Homebrew present but
without `coreutils`:

| Tool | Present |
|---|---|
| `timeout` | no |
| `gtimeout` | no |
| `flock` | no |
| `perl` | yes, `/usr/bin/perl` |
| `shlock` | yes, `/usr/bin/shlock` |

`aside` is `Mach-O 64-bit executable arm64`, symlinked from
`~/.local/bin/aside` into `~/.aside/cli/Aside CLI.app`, so there is no other
platform on which the GNU spellings would have applied.

The failure is not loud. `timeout 300 aside exec ...` exits 127 with
`command not found` before `aside` is invoked, so the guard against a silent hang
is itself silently missing, and the run it was supposed to bound never starts.

## Replacements, measured

`perl -e 'alarm shift; exec @ARGV' <secs> <cmd>`:

| Property | Result |
|---|---|
| Fires at deadline | `alarm 2` on `sleep 30` returned at 2.009s |
| Distinct kill code | `142`, `128 + SIGALRM` |
| Passes child exit through | `exit 7` surfaced as `7` |

`exec` replaces the shell in-process and the kernel timer survives, so the
deadline lands on the CLI itself.

Verified against a real hang rather than only `sleep`: an exec run told to
`read_file /etc/hosts` with the three clauses removed printed its tool-call line,
went silent, and was killed at 30.2s. Suspended sessions went 4 to 5 across that
run, matching the mechanism in `references/permissions.md`.

`shlock -p $$ -f <lock>`:

| Case | Result |
|---|---|
| Holder pid alive | refuses, so `|| exit 0` skips the tick |
| Holder pid dead | reclaims the stale lock and proceeds |

Both cases passed 2/2. `shlock` validates the recorded pid rather than testing
file existence, so a run killed by the deadline does not wedge the job the way a
`mkdir` guard would. It writes an unpadded `<pid>\n`; a hand-written padded pid
file is not recognised, which is only a concern if something other than `shlock`
creates the lock.

## Scope

Six command sites: `SKILL.md` x4 including the `exec_command` polling recipe,
`references/permissions.md`, `references/deep-research.md`, plus the
`references/scheduling.md` script and its two prose claims. `repl-api.md:92`
mentions a Playwright `timeout` option and is unrelated.
