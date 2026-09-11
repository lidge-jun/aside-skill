# check-wp2.ps1 - wp2 acceptance checks. ASCII only; paths from $PSScriptRoot.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$fail = 0
function Check([string]$n, [bool]$ok, [string]$d) {
  if ($ok) { Write-Output ('PASS  ' + $n) } else { Write-Output ('FAIL  ' + $n + '  :: ' + $d); $script:fail++ }
}
function Body([string]$rel) { Get-Content -LiteralPath (Join-Path $repo $rel) -Raw -Encoding utf8 }
# Fenced code only. Prose is ALLOWED - required, even - to name a banned construct
# in order to ban it. Checking raw text here is the false-green trap wp1 already hit.
function Fences([string]$rel) {
  $t = Body $rel
  $out = ''
  foreach ($m in [regex]::Matches($t, '(?s)\x60\x60\x60[a-zA-Z]*(.*?)\x60\x60\x60')) { $out += $m.Groups[1].Value }
  return $out
}

# AC4 - the two host files exist
$hostFiles = @('aside-jun/references/host-macos.md','aside-jun/references/host-windows.md')
foreach ($h in $hostFiles) { Check ('AC4 exists: ' + $h) (Test-Path -LiteralPath (Join-Path $repo $h)) 'missing' }

# AC1 - no macOS-only claim and no perl alarm recipe in SKILL.md
$skill = Body 'aside-jun/SKILL.md'
Check 'AC1 no macOS-only claim' ($skill -notmatch 'macOS-only') 'still present'
Check "AC1 no perl alarm recipe" ($skill -notmatch "perl -e 'alarm") 'still present'

# AC2 - no tilde account root anywhere in SKILL.md
Check 'AC2 no tilde account root' ($skill -notmatch '~/\.aside/u/0/') 'still present'

# AC3 - under 500 lines
$n = (Get-Content -LiteralPath (Join-Path $repo 'aside-jun/SKILL.md')).Count
Check ('AC3 SKILL.md under 500 (actual ' + $n + ')') ($n -lt 500) ('actual ' + $n)

# AC5 - each host file carries BOTH shells, and no shell is called a fallback
foreach ($h in $hostFiles) {
  $b = Body $h
  $bash = ([regex]::Matches($b, '```bash')).Count
  $ps   = ([regex]::Matches($b, '```powershell')).Count
  Check ($h + ': has bash cells') ($bash -ge 1) ('count ' + $bash)
  Check ($h + ': has PowerShell cells') ($ps -ge 1) ('count ' + $ps)
  Check ($h + ': no shell called a fallback') ($b -notmatch '(?i)fallback') 'the word fallback appears'
}

# AC9 - no bare timeout spelling as a recipe; GNU timeout is absolute
$win = Body 'aside-jun/references/host-windows.md'
Check 'AC9 GNU timeout is /usr/bin/timeout' ($win -match '/usr/bin/timeout') 'absolute GNU path missing'

# AC10 - no 5.1-invalid tree kill, no LASTEXITCODE gate after Start-Process
$winCode = Fences 'aside-jun/references/host-windows.md'
Check 'AC10 no Kill-bool overload in any host-windows recipe' ($winCode -notmatch 'Kill\(\$true\)') 'a recipe uses an overload 5.1 does not have'
Check 'AC10 taskkill tree kill present' ($win -match 'taskkill') 'tree kill missing'

# AC11 - scheduled interpreter is absolute, never a bare pwsh.exe
$sched = Body 'aside-jun/references/scheduling.md'
Check 'AC11 absolute PowerShell in scheduled action' ($sched -match 'WindowsPowerShell.v1\.0.powershell\.exe') 'absolute interpreter missing'

# AC7 - the bash tool is branched and the Windows deadlock is named
# ASCII-only probe for the guard/shell-tool section: it must name guard and require
# full-access. The prose around it is Korean, so do not match on Korean here - a
# BOM-less .ps1 with non-ASCII is reparsed as the ANSI code page by 5.1.
Check 'AC7 guard vs full-access for the shell tool' (($win -match 'guard') -and ($win -match 'full-access')) 'guard/full-access contract not stated'
$perm = Body 'aside-jun/references/permissions.md'
Check 'AC7 permissions.md branches the sandbox' (($perm -match 'AppContainer') -and ($perm -match 'sandbox-exec')) 'not branched'

# AC8 - macOS regression: perl alarm and shlock survive in host-macos.md
$mac = Body 'aside-jun/references/host-macos.md'
Check 'AC8 perl alarm preserved' ($mac -match "perl -e 'alarm") 'lost in the move'
Check 'AC8 shlock preserved' ($mac -match 'shlock') 'lost in the move'
Check 'AC8 exit 142 evidence preserved' ($mac -match '142') 'lost in the move'

# never Get-Command bash anywhere
foreach ($f in @('aside-jun/references/host-windows.md','aside-jun/references/scheduling.md')) {
  Check ($f + ': no Get-Command bash in a recipe') ((Fences $f) -notmatch 'Get-Command bash') 'WindowsApps stub would win'
  Check ($f + ': the stub is called out in prose') ((Body $f) -match 'WindowsApps') 'the 0-byte stub is not warned about'
}

# this script must itself be ASCII-only, by bytes
$selfBytes = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'check-wp2.ps1'))
$nonAscii = 0
foreach ($b in $selfBytes) { if ($b -gt 127) { $nonAscii++ } }
Check 'check-wp2.ps1 is ASCII-only' ($nonAscii -eq 0) ('non-ascii bytes ' + $nonAscii)

Write-Output ''
if ($fail -eq 0) { Write-Output 'wp2 checks: ALL PASS'; exit 0 }
Write-Output ('wp2 checks: ' + $fail + ' FAILED'); exit 1
