#!/usr/bin/env bash
# wp1 docs check: roadmap docs exist, cited evidence exists, ledger counts match rows,
# no unclassified row, no credential-shaped strings, probes changed nothing live.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
fail=0
for f in 000_parity-ledger-v2.md 001_probe-remote-and-touchid.md 002_audit-synthesis.md \
         020_fold-and-fixes.md 030_remote-and-touchid-wording.md 040_ship.md; do
  [ -s "$f" ] || { echo "MISSING $f"; fail=1; }
done
for q in R1 R2 T1; do ls evidence/probe-$q-*.log >/dev/null 2>&1 || { echo "MISSING probe $q"; fail=1; }; done

# ledger integrity: every v2-NN row carries exactly one verdict, counts match the table
rows=$(rg -c '^\| v2-[0-9]+ \|' 000_parity-ledger-v2.md)
[ "$rows" = "77" ] || { echo "ledger rows=$rows expected 77"; fail=1; }
for v in "PRESENT 47" "MISSING 20" "CONTRADICTS-CORRECTLY 8" "CONTRADICTS-WRONGLY 2"; do
  set -- $v
  n=$(rg -c "^\| v2-[0-9]+ \|.*\| $1 \|" 000_parity-ledger-v2.md || true); n=${n:-0}
  [ "$n" = "$2" ] || { echo "$1 rows=$n expected $2"; fail=1; }
done
unclassified=$( { rg '^\| v2-[0-9]+ \|' 000_parity-ledger-v2.md || true; } | { rg -v 'PRESENT|MISSING|CONTRADICTS-CORRECTLY|CONTRADICTS-WRONGLY' || true; } | wc -l | tr -d ' ')
[ "$unclassified" = "0" ] || { echo "unclassified rows: $unclassified"; fail=1; }
# every MISSING row carries FOLD, REJECT or DEFER
undecided=$( { rg '^\| v2-[0-9]+ \|.*\| MISSING \|' 000_parity-ledger-v2.md || true; } | { rg -v 'FOLD|REJECT|DEFER' || true; } | wc -l | tr -d ' ')
[ "$undecided" = "0" ] || { echo "MISSING rows without a recommendation: $undecided"; fail=1; }

if rg -n -i '\bsk-[a-z0-9]{10,}|bearer [a-z0-9]{20,}|"password"\s*:\s*"|[a-z0-9._-]+@[a-z0-9-]+\.(ac\.kr|com|net|org)\b' . --glob '!check-wp1.sh'; then echo "CREDENTIAL/EMAIL SHAPE"; fail=1; fi

# the probes must have left the install untouched
[ ! -f "$HOME/.aside/u/0/remote-control.json" ] || { echo "remote-control.json appeared"; fail=1; }
python3 -c "import json,sys;d=json.load(open('$HOME/.aside/u/0/passwords/settings.json'));sys.exit(0 if d['biometricUnlockEnabled'] is False else 1)" || { echo "biometricUnlockEnabled changed"; fail=1; }

[ $fail -eq 0 ] && echo "wp1 check: OK ($rows ledger rows)"
exit $fail
