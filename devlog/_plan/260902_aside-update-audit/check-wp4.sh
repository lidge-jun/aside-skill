#!/usr/bin/env bash
# wp4 ship check: clean tree, HEAD on origin/main, mirror identical, no PII, all prior checks
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../../.."
fail=0
[ -z "$(git status --short)" ] || { echo "dirty tree"; fail=1; }
git fetch -q origin
git merge-base --is-ancestor HEAD origin/main || { echo "HEAD not on origin/main"; fail=1; }
diff -rq aside-jun "$HOME/.codex/skills/aside-jun" || { echo "mirror drift"; fail=1; }
if rg -n -i '\bsk-[a-z0-9]{10,}|bearer [a-z0-9]{20,}|"password"\s*:\s*"|xoxb-|ghp_[a-z0-9]{20,}|[a-z0-9._-]+@[a-z0-9-]+\.(ac\.kr|com|net|org)\b' aside-jun README.md devlog/_plan/260902_aside-update-audit --glob '!*.png' --glob '!check-wp4.sh'; then echo "PII"; fail=1; fi
ls devlog/_plan/260902_aside-update-audit/evidence/*.jpeg >/dev/null 2>&1 && { echo "withheld screenshot present"; fail=1; }
bash devlog/_plan/260902_aside-update-audit/check-wp1.sh >/dev/null || fail=1
bash devlog/_plan/260902_aside-update-audit/check-wp2.sh >/dev/null || fail=1
bash devlog/_plan/260902_aside-update-audit/check-wp3.sh >/dev/null || fail=1
[ $fail -eq 0 ] && echo "wp4 ship check: OK at $(git rev-parse --short HEAD)"
exit $fail
