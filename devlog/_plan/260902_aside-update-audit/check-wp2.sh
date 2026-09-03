#!/usr/bin/env bash
# wp2 check: 020 C-checks against aside-jun/SKILL.md
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../../.."
f=aside-jun/SKILL.md; fail=0
n=$(wc -l < $f); [ "$n" -lt 500 ] || { echo "LINES $n"; fail=1; }
[ "$(rg -c -- '--session' $f)" = "1" ] || { echo "--session count"; fail=1; }
rg -q '1\.26\.(810|829)' $f && { echo "old pin"; fail=1; }
[ "$(rg -c '1\.26\.831' $f)" = "2" ] || { echo "831 count"; fail=1; }
[ "$(rg -c 'full-access' $f)" -ge 6 ] || { echo "full-access count"; fail=1; }
rg -q 'Hangs\.' $f && { echo "Hangs."; fail=1; }
rg -q 'Only exec can load' $f && { echo "Only exec"; fail=1; }
[ "$(rg -c 'Write and edit files only under ~/.aside/u/0/' $f)" = "3" ] || { echo "clause copies"; fail=1; }
rg -q '1\.26\.902\.1732' $f && rg -q '1\.26\.902\.1713' $f || { echo "new pins"; fail=1; }
git diff --check -- $f || fail=1
[ $fail -eq 0 ] && echo "wp2 check: OK ($n lines)"
exit $fail
