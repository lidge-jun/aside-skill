#!/usr/bin/env bash
# wp1 docs-only check: every roadmap doc exists, every evidence file cited in the
# docs exists, and no credential-shaped string or raw log-dump leaked into evidence/.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

fail=0
for f in 000_research.md 001_decisions.md 002_save-sessions-probe.md 003_audit-synthesis.md \
         010_skill-recommendations.md 020_skill-md-rewrite.md 030_references-update.md 040_ship.md; do
  [ -s "$f" ] || { echo "MISSING $f"; fail=1; }
done

# evidence files cited as evidence/<name> in any doc must exist (skip brace/glob
# patterns and 040's ship log, which is produced at wp4)
while read -r ref; do
  case "$ref" in *'{'*|*-|*.|evidence/ship-checks.log) continue;; esac
  [ -e "$ref" ] || { echo "DANGLING $ref"; fail=1; }
done < <(rg -o 'evidence/[A-Za-z0-9._-]+' -N --no-filename *.md | sort -u)

# S8 probe set is complete
for q in S1 S2 S3 S4 S5 S6; do
  ls evidence/probe-$q-*.log >/dev/null 2>&1 || { echo "MISSING probe $q"; fail=1; }
done
[ -e evidence/probe-S3-aside-chat-list.png ] || { echo "MISSING S3 screenshot"; fail=1; }

# no raw log-dump and no credential-shaped strings
if ls evidence/*.jsonl >/dev/null 2>&1; then echo "RAW JSONL present"; fail=1; fi
if rg -n -i '\bsk-[a-z0-9]{10,}|api[_-]?key["'"'"']?\s*[:=]|bearer [a-z0-9]{20,}|"password"\s*:\s*"' evidence/ *.md; then
  echo "CREDENTIAL-SHAPED STRING"; fail=1
fi

# placeholders left from P must be gone
if rg -n '\[S8[^]]*삽입|\[S8 결과' *.md; then echo "PLACEHOLDER left"; fail=1; fi

[ "$fail" -eq 0 ] && echo "wp1 check: OK"
exit $fail
