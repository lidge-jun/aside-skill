# check-wp1.ps1 - wp1 (docs-only roadmap) acceptance checks.
# ASCII only on purpose: a BOM-less .ps1 with non-ASCII is parsed as the ANSI
# code page by Windows PowerShell 5.1. See 002 D6.
# Run from the aside-skill repo root:  powershell.exe -NoProfile -File devlog/_plan/260911_windows-coverage/check-wp1.ps1

$ErrorActionPreference = 'Stop'
$unit = 'devlog/_plan/260911_windows-coverage'
$fail = 0

function Check([string]$name, [bool]$ok, [string]$detail) {
  if ($ok) { Write-Output ("PASS  " + $name) }
  else { Write-Output ("FAIL  " + $name + "  :: " + $detail); $script:fail++ }
}

# 1. every unit document exists and is non-empty
$docs = @('000_research.md','001_parity-ledger-windows.md','002_decisions-dual-shell.md',
          '010_patch-plan-aside-skill.md','020_patch-plan-memory-sync.md','030_ship.md',
          'evidence/probe-win-permission.md','evidence/probe-win-followups.md','evidence/probe-mac-parity.md')
foreach ($d in $docs) {
  $p = Join-Path $unit $d
  $ok = (Test-Path -LiteralPath $p) -and ((Get-Item -LiteralPath $p).Length -gt 0)
  Check ("doc exists: " + $d) $ok "missing or empty"
}

# 2. retired instructions must be gone from the plan documents (evidence/ is a raw
#    transcript and is deliberately excluded - see the NB2 rebuttal in the A phase)
$plans = @('000_research.md','001_parity-ledger-windows.md','002_decisions-dual-shell.md',
           '010_patch-plan-aside-skill.md','020_patch-plan-memory-sync.md','030_ship.md')
$retired = @{
  'Kill($true) as a recipe'      = 'Kill($true)'
  'login-shell -lc scheduled job'= 'bash.exe" -lc'
  'MEMORY.md as the merge oracle'= 'MEMORY.md . 를 서로 다르게 고친'
}
foreach ($k in $retired.Keys) {
  $hits = @()
  foreach ($d in $plans) {
    $p = Join-Path $unit $d
    $m = Select-String -LiteralPath $p -Pattern $retired[$k] -AllMatches -ErrorAction SilentlyContinue
    if ($m) { $hits += ($d + ':' + ($m | ForEach-Object { $_.LineNumber } | Select-Object -First 1)) }
  }
  # the 000 correction banner is allowed to quote the retired form once
  $hits = $hits | Where-Object { $_ -notlike '000_research.md*' }
  Check ("retired: " + $k) ($hits.Count -eq 0) ($hits -join ', ')
}

# 3. every target file named by the change maps actually exists
$targets = @('aside-jun/SKILL.md','aside-jun/references/permissions.md','aside-jun/references/scheduling.md',
             'aside-jun/references/credentials.md','aside-jun/references/builtin-skills.md',
             'aside-jun/references/repl-api.md','aside-jun/references/deep-research.md',
             'aside-jun/references/refskill-aside.md','aside-jun/scripts/refresh-builtin-summary.sh',
             'aside-jun/agents/openai.yaml','README.md')
foreach ($t in $targets) { Check ("target exists: " + $t) (Test-Path -LiteralPath $t) "not found" }

$sync = '../aside-memory-sync'
$syncTargets = @('install.sh','sync.sh','autosync.sh','install-autosync.sh','hub-setup.sh',
                 'bin/aside-memory-merge','templates/gitattributes','templates/gitignore',
                 'repos.conf.example','README.md','AGENT.md')
foreach ($t in $syncTargets) {
  $p = Join-Path $sync $t
  Check ("target exists: aside-memory-sync/" + $t) (Test-Path -LiteralPath $p) "not found"
}

# 4. the SKILL.md baseline the 468-line budget is computed from
$lines = (Get-Content -LiteralPath 'aside-jun/SKILL.md').Count
Check "SKILL.md baseline is 499 lines" ($lines -eq 499) ("actual " + $lines)

# 5. the two new host files must NOT exist yet - wp2 creates them.
#    This keeps wp1 honest about being docs-only.
foreach ($h in @('aside-jun/references/host-macos.md','aside-jun/references/host-windows.md')) {
  Check ("wp2 target not yet created: " + $h) (-not (Test-Path -LiteralPath $h)) "already exists"
}

Write-Output ""
if ($fail -eq 0) { Write-Output "wp1 checks: ALL PASS"; exit 0 }
Write-Output ("wp1 checks: " + $fail + " FAILED")
exit 1
