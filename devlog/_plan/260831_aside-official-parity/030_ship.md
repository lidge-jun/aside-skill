# 030 - Ship

1. `quick_validate.py` against `aside-jun/` with `/usr/local/bin/python3` (the
   default `python3` has no PyYAML; do not install anything).
2. PII scan over tracked files: usernames seen during the live runs, the 6-digit
   PIN, and the vault id must all return nothing. Masked placeholders only.
3. Line budget check. SKILL.md stays under the 500-line guidance; overflow goes to
   references.
4. Commit, push to `lidge-jun/aside-skill`, confirm the remote ref update line.
5. Mirror with `rsync -a --delete` to `~/.codex/skills/aside-jun/` and
   `~/.claude/skills/aside-jun/`, then `diff -r` both against the repo.
6. Add the parity ledger counts to the README so a reader knows the skill was
   checked against the official text rather than written beside it.
