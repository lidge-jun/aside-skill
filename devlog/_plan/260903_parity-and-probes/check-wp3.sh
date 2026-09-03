#!/usr/bin/env bash
# wp3 check: 030's C-checks — probe-matched wording, nothing changed on the live install
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../../.."
fail=0
n=$(wc -l < aside-jun/SKILL.md | tr -d ' '); [ "$n" -eq 499 ] || { echo "SKILL.md $n lines, expected 499"; fail=1; }
rg -q '403' aside-jun/SKILL.md && { echo "403 claim survives"; fail=1; }
[ "$(rg -c 'remote-control.json' aside-jun/SKILL.md)" = "1" ] || { echo "remote-control.json"; fail=1; }
[ "$(rg -c "Aside's own skill documents the surface" aside-jun/SKILL.md)" = "1" ] || { echo "attribution split"; fail=1; }
[ "$(rg -c 'What was measured here is narrower' aside-jun/SKILL.md)" = "1" ] || { echo "measurement split"; fail=1; }
[ "$(rg -c 'the local GUI app need not be' aside-jun/SKILL.md)" = "1" ] || { echo "v2-60 wording"; fail=1; }
[ "$(rg -c 'checkPasswordVerificationRequired' aside-jun/references/credentials.md)" = "1" ] || { echo "touchid predicate"; fail=1; }
[ "$(rg -c '1.26.903.1631' aside-jun/references/credentials.md)" = "1" ] || { echo "daemon version cite"; fail=1; }
rg -q 'is unverified on 1.26.902' aside-jun/references/credentials.md && { echo "stale unverified"; fail=1; }
rg -q 'every unlock demands a live fingerprint' aside-jun/references/credentials.md && { echo "per-unlock claim"; fail=1; }
rg -q '260903_parity-and-probes/001_probe' aside-jun/references/credentials.md || { echo "probe pointer"; fail=1; }
# no prose line the reviewer would flag in the two edited paragraphs
long=$(awk 'NR>=349 && NR<=358 && length>95 {c++} END{print c+0}' aside-jun/SKILL.md)
[ "$long" -eq 0 ] || { echo "$long long lines in the remote paragraph"; fail=1; }
# the probes must have left the install untouched
[ ! -f "$HOME/.aside/u/0/remote-control.json" ] || { echo "remote-control.json appeared"; fail=1; }
python3 -c "import json,sys;d=json.load(open('$HOME/.aside/u/0/passwords/settings.json'));sys.exit(0 if d['biometricUnlockEnabled'] is False else 1)" || { echo "biometricUnlockEnabled changed"; fail=1; }
git diff --check || fail=1
[ $fail -eq 0 ] && echo "wp3 check: OK"
exit $fail
