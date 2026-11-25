#!/usr/bin/env bash
# Regenerate references/builtin-skills.md from the Aside account's installed builtin skills.
# Aside ships these and updates them with the app, so the summary drifts. Re-run after an update:
#   scripts/refresh-builtin-summary.sh [account-root]
#
# Account root defaults per OS. Do not assume a macOS home layout.
#   Darwin:             $HOME/.aside/u/0
#   Windows (Git Bash): $USERPROFILE/.aside/u/0
#
# Layout note: builtin/ holds top-level skill directories, each with its own SKILL.md,
# plus one container directory (site-specific/) that has NO SKILL.md of its own and
# instead holds per-site skills one level deeper. Both are emitted, and the container
# itself is never listed as a loadable skill.
set -euo pipefail

default_account_root() {
  case "$(uname -s)" in
    Darwin) printf '%s\n' "$HOME/.aside/u/0" ;;
    MINGW*|MSYS*|CYGWIN*) printf '%s\n' "${USERPROFILE:-$HOME}/.aside/u/0" ;;
    *) printf '%s\n' "${USERPROFILE:-$HOME}/.aside/u/0" ;;
  esac
}

ACCOUNT_ROOT="${1:-$(default_account_root)}"
BUILTIN_DIR="$ACCOUNT_ROOT/skills/builtin"
OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/references/builtin-skills.md"

if [ ! -d "$BUILTIN_DIR" ]; then
  echo "no builtin skills at $BUILTIN_DIR" >&2
  exit 1
fi

# Platform labels are historical. Measured 2026-09-11 (Windows CLI 1.26.906): the
# Windows tree had no apple-passwords, imessage, or context-awareness, and had every
# other name in WIN_906 below. Names not in either list appeared later and have not
# been measured on Windows, so they are labelled "unmeasured" rather than guessed.
WIN_906=" 1password aside bitwarden captcha-solver channel chrome dashlane docx draft-preview google-accounts google-docs google-gmail google-search google-sheets image-search imagegen kakaotalk lastpass notification-activation notion onboarding password-manager pdf pptx proton-pass skill-creator slack visual-browse x-twitter xlsx youtube airtable amazon asana clickup confluence discord github google-calendar google-drive google-forms google-slides jira linear linkedin trello "
platform_of() {
  case "$1" in
    apple-passwords|imessage|context-awareness) printf '%s\n' "macOS" ;;
    *) if [[ "$WIN_906" == *" $1 "* ]]; then printf '%s\n' "both"; else printf '%s\n' "unmeasured"; fi ;;
  esac
}

desc_of() {
  awk '/^description:/{sub(/^description:[[:space:]]*/,""); gsub(/^["'"'"']|["'"'"']$/,""); print; exit}' "$1" 2>/dev/null || true
}

# A skill is repl-backed when a JS global of the same shape exists in the repl scope.
REPL_BACKED=" chrome twitter x-twitter gmail google-gmail google-accounts google-docs google-sheets google-search notion slack linkedin youtube image-search imagegen apple-passwords captcha-solver aside "

# Resolve the CLI without relying on a login PATH (non-login shells miss ~/.local/bin).
ASIDE="${ASIDE:-$(command -v aside 2>/dev/null || true)}"
[ -z "$ASIDE" ] && [ -x "$HOME/.local/bin/aside" ] && ASIDE="$HOME/.local/bin/aside"
[ -z "$ASIDE" ] && ASIDE=aside
export NO_UPDATE_NOTIFIER=1

# `aside skills list` prints a subset of the tree. It is not the repl-backed set, so it
# gets its own column. 1.26.1115 supports `--json` ([{name,description}]); older builds
# print name<TAB>description, and 1.26.1115's text form adds a NAME/DESCRIPTION header
# and a trailing "Read a skill before using it" line, so the text fallback skips both.
# Names are lowercased; 1.26.906 listed the iMessage skill as "Messages" while its
# builtin directory is "imessage".
cli_listed_names() {
  local json
  if json=$("$ASIDE" skills list --json 2>/dev/null) && [ "${json:0:1}" = "[" ]; then
    printf '%s' "$json" | python3 -c 'import json,sys; [print(s["name"]) for s in json.load(sys.stdin)]' 2>/dev/null && return
  fi
  "$ASIDE" skills list 2>/dev/null | awk -F'\t' 'NF>=2 && $1!="NAME"{print $1}'
}
CLI_LISTED=" $(cli_listed_names | awk '{n=tolower($0); if(n=="messages") n="imessage"; print n}' | tr '\n' ' ') "
CLI_COUNT=$(printf '%s' "$CLI_LISTED" | wc -w | tr -d ' ')
CLI_VERSION="$("$ASIDE" --version 2>/dev/null || echo unknown)"

# Hand-written dated notes live between these markers and survive regeneration.
NOTES_START='<!-- manual-notes:start -->'
NOTES_END='<!-- manual-notes:end -->'
MANUAL_NOTES=""
if [ -f "$OUT" ]; then
  MANUAL_NOTES=$(awk -v s="$NOTES_START" -v e="$NOTES_END" '$0==s{f=1;next} $0==e{f=0} f' "$OUT")
fi
HOST_OS="$(uname -s)"

listed_of() {
  local lname
  lname=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  if [[ "$CLI_LISTED" == *" $lname "* ]]; then echo "yes"; else echo "-"; fi
}

top_count=0
site_count=0

top_rows=""
for f in "$BUILTIN_DIR"/*/SKILL.md; do
  [ -e "$f" ] || continue
  name=$(basename "$(dirname "$f")")
  d=$(desc_of "$f"); [ -z "$d" ] && d="(no description)"
  d=$(printf '%s' "$d" | cut -c1-130 | tr -d '|')
  if [[ "$REPL_BACKED" == *" $name "* ]]; then kind="repl global"; else kind="instructions"; fi
  top_rows+="| \`$name\` | $kind | $(listed_of "$name") | $(platform_of "$name") | $d |"$'\n'
  top_count=$((top_count+1))
done

site_rows=""
if [ -d "$BUILTIN_DIR/site-specific" ]; then
  for f in "$BUILTIN_DIR"/site-specific/*/SKILL.md; do
    [ -e "$f" ] || continue
    name=$(basename "$(dirname "$f")")
    d=$(desc_of "$f"); [ -z "$d" ] && d="(no description)"
    d=$(printf '%s' "$d" | cut -c1-130 | tr -d '|')
    if [[ "$REPL_BACKED" == *" $name "* ]]; then kind="repl global"; else kind="instructions"; fi
    site_rows+="| \`$name\` | $kind | $(listed_of "$name") | $(platform_of "$name") | $d |"$'\n'
    site_count=$((site_count+1))
  done
fi

{
  echo "# Aside builtin skills"
  echo
  echo "Generated by \`scripts/refresh-builtin-summary.sh\` from \`$BUILTIN_DIR\` (\`uname\` $HOST_OS) with CLI $CLI_VERSION on $(date +%Y-%m-%d)."
  echo "Pass the account root as argument 1; the default is per-OS, not a macOS path."
  echo "Aside owns these and ships updates with the app; re-run the script after an Aside update."
  echo
  echo "$NOTES_START"
  [ -n "$MANUAL_NOTES" ] && printf '%s\n' "$MANUAL_NOTES"
  echo "$NOTES_END"
  echo
  echo "\`aside skills list\` printed $CLI_COUNT names on this run."
  echo
  echo "\`aside exec\` loads them on its own when the prompt names one. Codex can read any skill"
  echo "body with \`aside skills show <name>\`; \`aside skills list\` prints the subset marked"
  echo "\`CLI listed\` below."
  echo
  echo "Check this list before driving a site by hand with \`snapshot()\`: a matching skill usually"
  echo "reaches an API and skips the DOM entirely. When you use one, tell the user which skill"
  echo "and why."
  echo
  echo "$top_count top-level skills and $site_count site-specific skills in this tree."
  echo
  echo "The \`Backing\` column says how the skill works. A \`repl global\` skill documents a JavaScript"
  echo "object you can also drive yourself from \`aside repl\`; several of those reach an API and never"
  echo "open a tab. An \`instructions\` skill is guidance for the agent with no matching global."
  echo "The \`Platform\` column is historical (Windows CLI 1.26.906 tree, 2026-09-11): \`macOS\`"
  echo "for names measured absent there (\`apple-passwords\`, \`imessage\`, \`context-awareness\`),"
  echo "\`both\` for names present in both trees then, and \`unmeasured\` for names that"
  echo "appeared later and were not checked on Windows."
  echo
  echo "## Top-level"
  echo
  echo "| Skill | Backing | CLI listed | Platform | Purpose |"
  echo "|---|---|---|---|---|"
  printf '%s' "$top_rows"
  echo
  echo "## Site-specific"
  echo
  echo "Nested under \`site-specific/\`. The container directory has no SKILL.md and is not itself"
  echo "loadable; name the individual site skill instead."
  echo
  echo "| Skill | Backing | CLI listed | Platform | Purpose |"
  echo "|---|---|---|---|---|"
  printf '%s' "$site_rows"
} > "$OUT"

echo "wrote $OUT ($top_count top-level, $site_count site-specific)"
