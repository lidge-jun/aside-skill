# 010 - Ship

1. Replace every `timeout N aside exec` with the `perl alarm` form, and the
   scheduling `flock` with `shlock` plus a `trap` cleanup.
2. State the macOS-only premise in the SKILL preamble, the frontmatter
   description, and the README requirements.
3. Keep `coreutils` as an explicitly optional way back to the GNU spellings.
4. Verify by running the edited commands verbatim, not by reading them.
5. Sync to the install dir and `diff -r` it.

## Verification run

| Check | Result |
|---|---|
| Assembled exec command from SKILL.md | 7.1s, `HOSTEXIT=0`, reported the H1 |
| Scheduling script, end to end | `SCRIPT_EXIT=0`, wrote `READY` to `state.md` |
| Lock released on clean exit | `trap` removed it |
| Second tick while holder alive | skipped at 0s, never invoked `aside` |

The scheduling probe ran under `~/.aside/u/0/jobs/skilltest/`, inside the
writable root, so it needed no permission detour.
