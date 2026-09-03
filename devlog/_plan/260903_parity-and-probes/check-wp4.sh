#!/usr/bin/env bash
# wp4 ship check: all prior checks + clean tree + on origin/main + mirror + PII + old-ledger note
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../../.."
fail=0
bash devlog/_plan/260903_parity-and-probes/check-wp1.sh >/dev/null || { echo "wp1 check"; fail=1; }
bash devlog/_plan/260903_parity-and-probes/check-wp2.sh >/dev/null || { echo "wp2 check"; fail=1; }
bash devlog/_plan/260903_parity-and-probes/check-wp3.sh >/dev/null || { echo "wp3 check"; fail=1; }
[ "$(rg -c 'Superseded \(2026-09-03\)' devlog/_plan/260831_aside-official-parity/001_parity-ledger.md)" = "1" ] || { echo "old ledger note"; fail=1; }
if rg -n -i '\bsk-[a-z0-9]{10,}|bearer [a-z0-9]{20,}|"password"\s*:\s*"|xoxb-|ghp_[a-z0-9]{20,}|[a-z0-9._-]+@[a-z0-9-]+\.(ac\.kr|com|net|org)\b' aside-jun README.md devlog/_plan/260903_parity-and-probes --glob '!check-wp4.sh'; then echo "PII"; fail=1; fi
[ -z "$(git status --short)" ] || { echo "dirty tree"; fail=1; }
git fetch -q origin
git merge-base --is-ancestor HEAD origin/main || { echo "HEAD not on origin/main"; fail=1; }
diff -rq aside-jun "$HOME/.codex/skills/aside-jun" || { echo "mirror drift"; fail=1; }
[ $fail -eq 0 ] && echo "wp4 ship check: OK at $(git rev-parse --short HEAD)"
exit $fail
