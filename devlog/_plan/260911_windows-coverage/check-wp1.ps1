# check-wp1.ps1 - wp1 (docs-only roadmap) acceptance checks.
# ASCII only on purpose: a BOM-less .ps1 containing non-ASCII is parsed as the
# ANSI code page by Windows PowerShell 5.1 (002 D6). Korean match text lives in
# check-wp1.patterns.tsv, which this script reads as UTF-8.
# Run from the aside-skill repo root:
#   powershell.exe -NoProfile -File devlog/_plan/260911_windows-coverage/check-wp1.ps1

$ErrorActionPreference = 'Stop'
$unit = 'devlog/_plan/260911_windows-coverage'
$fail = 0

function Check([string]$name, [bool]$ok, [string]$detail) {
  if ($ok) { Write-Output ('PASS  ' + $name) }
  else { Write-Output ('FAIL  ' + $name + '  :: ' + $detail); $script:fail++ }
}

$plans = @('000_research.md','001_parity-ledger-windows.md','002_decisions-dual-shell.md',
           '010_patch-plan-aside-skill.md','020_patch-plan-memory-sync.md','030_ship.md')
$docs  = $plans + @('evidence/probe-win-permission.md','evidence/probe-win-followups.md',
                    'evidence/probe-mac-parity.md')

# 1. every unit document exists and is non-empty
foreach ($d in $docs) {
  $p = Join-Path $unit $d
  $ok = (Test-Path -LiteralPath $p) -and ((Get-Item -LiteralPath $p).Length -gt 0)
  Check ('doc exists: ' + $d) $ok 'missing or empty'
}

# 2. Every fenced powershell block that launches the CLI must obey the deadline
#    contract. This observes the RECIPES, not the prose: the documents are allowed
#    - required, even - to name Kill($true) while forbidding it.
foreach ($d in $plans) {
  $p = Join-Path $unit $d
  $text = Get-Content -LiteralPath $p -Raw -Encoding utf8
  $blocks = [regex]::Matches($text, '(?s)```powershell(.*?)```')
  $i = 0
  foreach ($b in $blocks) {
    $i++
    $body = $b.Groups[1].Value
    if ($body -notmatch 'Start-Process') { continue }
    $where = $d + ' block#' + $i
    Check ($where + ': no Kill-bool overload') ($body -notmatch 'Kill\(\$true\)') 'Kill($true) does not exist on 5.1'
    Check ($where + ': argv separator before the prompt') ($body -match "'--'") 'prompt must be preceded by --'
    Check ($where + ': reads PassThru ExitCode') ($body -match '\$p\.ExitCode') 'Start-Process never sets LASTEXITCODE'
    Check ($where + ': no LASTEXITCODE gate') ($body -notmatch 'LASTEXITCODE') 'LASTEXITCODE is stale after Start-Process'
  }
}

# 3. retired instructions, matched from the UTF-8 sidecar
$patternFile = Join-Path $unit 'check-wp1.patterns.tsv'
if (-not (Test-Path -LiteralPath $patternFile)) {
  Write-Output ('FAIL  pattern file missing: ' + $patternFile); exit 1
}
$rows = 0
foreach ($line in (Get-Content -LiteralPath $patternFile -Encoding utf8)) {
  if ($line.Trim().Length -eq 0) { continue }
  if ($line.StartsWith('#')) { continue }
  $parts = $line -split "`t", 2
  if ($parts.Count -ne 2) { continue }
  $rows++
  $hits = @()
  foreach ($d in $plans) {
    $p = Join-Path $unit $d
    $m = Select-String -LiteralPath $p -Pattern $parts[1] -AllMatches -ErrorAction SilentlyContinue
    if ($m) { foreach ($x in $m) { $hits += ($d + ':' + $x.LineNumber) } }
  }
  Check ('retired: ' + $parts[0]) ($hits.Count -eq 0) ($hits -join ', ')
}
Check 'pattern sidecar was actually read' ($rows -ge 1) 'no usable rows; the check would be vacuous'

# 4. the merge oracle names TAXONOMY.md in both the work package and the criteria
$p20 = Join-Path $unit '020_patch-plan-memory-sync.md'
$tax = (Select-String -LiteralPath $p20 -Pattern 'TAXONOMY\.md' -AllMatches).Count
Check 'merge oracle names TAXONOMY.md at least twice' ($tax -ge 2) ('occurrences ' + $tax)

# 5. every target file named by the change maps exists
$targets = @('aside-jun/SKILL.md','aside-jun/references/permissions.md','aside-jun/references/scheduling.md',
             'aside-jun/references/credentials.md','aside-jun/references/builtin-skills.md',
             'aside-jun/references/repl-api.md','aside-jun/references/deep-research.md',
             'aside-jun/references/refskill-aside.md','aside-jun/scripts/refresh-builtin-summary.sh',
             'aside-jun/agents/openai.yaml','README.md')
foreach ($t in $targets) { Check ('target exists: ' + $t) (Test-Path -LiteralPath $t) 'not found' }
$syncTargets = @('install.sh','sync.sh','autosync.sh','install-autosync.sh','hub-setup.sh',
                 'bin/aside-memory-merge','templates/gitattributes','templates/gitignore',
                 'repos.conf.example','README.md','AGENT.md')
foreach ($t in $syncTargets) {
  $p = Join-Path '../aside-memory-sync' $t
  Check ('target exists: aside-memory-sync/' + $t) (Test-Path -LiteralPath $p) 'not found'
}

# 6. the baseline the 468-line budget is computed from
$lines = (Get-Content -LiteralPath 'aside-jun/SKILL.md').Count
Check 'SKILL.md baseline is 499 lines' ($lines -eq 499) ('actual ' + $lines)

# 7. wp1 is docs-only: the two host files are wp2's job
foreach ($h in @('aside-jun/references/host-macos.md','aside-jun/references/host-windows.md')) {
  Check ('wp2 target not yet created: ' + $h) (-not (Test-Path -LiteralPath $h)) 'already exists'
}

# 8. this script must stay ASCII-only, by bytes
$self = Join-Path $unit 'check-wp1.ps1'
$bytes = [IO.File]::ReadAllBytes($self)
$non = 0
foreach ($b in $bytes) { if ($b -gt 127) { $non++ } }
Check 'check-wp1.ps1 is ASCII-only' ($non -eq 0) ('non-ascii bytes ' + $non)

Write-Output ''
if ($fail -eq 0) { Write-Output 'wp1 checks: ALL PASS'; exit 0 }
Write-Output ('wp1 checks: ' + $fail + ' FAILED')
exit 1
