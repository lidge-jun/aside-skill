# check-join.ps1 - verify the Windows memory directory really joined the hub.
# ASCII only: a BOM-less non-ASCII .ps1 is reparsed as CP949 by Windows PowerShell 5.1.
# Read-only. Runs no fetch, no push, no checkout.

$ErrorActionPreference = 'Continue'
$mem = 'C:\Users\super\.aside\u\0\memory'
$fail = 0

function Check($label, $ok, $detail) {
  if ($ok) { Write-Output ("PASS  " + $label) }
  else {
    $msg = "FAIL  " + $label
    if ($detail) { $msg = $msg + "  :: " + $detail }
    Write-Output $msg
    $script:fail = $script:fail + 1
  }
}

if (-not (Test-Path -LiteralPath (Join-Path $mem '.git'))) {
  Write-Output 'FAIL  memory directory is not a git repository'
  exit 1
}

Push-Location $mem

$status = @(git status --porcelain)
Check 'working tree is clean' ($status.Count -eq 0) ("dirty lines: " + $status.Count)

$autocrlf = (git config core.autocrlf)
Check 'core.autocrlf is false' ($autocrlf -eq 'false') $autocrlf

$driver = (git config merge.aside.driver)
Check 'merge driver is registered' (-not [string]::IsNullOrEmpty($driver)) 'empty'
Check 'driver path uses forward slashes' ($driver -notmatch '\\') $driver
Check 'driver arguments are quoted' ($driver -match '^"') $driver
Check 'driver uses the Aside runtime python' ($driver -match 'aside/runtime/bin/python3') $driver
Check 'driver does not use the WindowsApps stub' ($driver -notmatch 'WindowsApps') $driver

$attr = (git check-attr merge -- TAXONOMY.md)
Check 'TAXONOMY.md maps to the aside merge driver' ($attr -match 'merge: aside') $attr
$attr2 = (git check-attr merge -- episodic/2026-09-12.md)
Check 'episodic markdown maps to the aside merge driver' ($attr2 -match 'merge: aside') $attr2

$remote = (git config remote.hub.url)
Check 'hub remote is configured' (-not [string]::IsNullOrEmpty($remote)) 'missing'
Check 'hub remote names the ubuntu user' ($remote -match '^ubuntu@') $remote

git merge-base --is-ancestor hub/main HEAD 2>$null
Check 'hub/main is an ancestor of HEAD' ($LASTEXITCODE -eq 0) ("exit " + $LASTEXITCODE)

$ahead = @(git log --oneline hub/main..HEAD)
Check 'local commits ahead of hub are accounted for' ($ahead.Count -le 2) ("ahead " + $ahead.Count)

foreach ($f in @('MEMORY.md','USER.md','TAXONOMY.md')) {
  $d = @(git diff --name-only hub/main -- $f)
  Check ("L1 matches the hub: " + $f) ($d.Count -eq 0) 'differs from hub/main'
}

foreach ($pair in @(@('episodic/2026-09-10.md','163.152.22.106','LMS conversations heartbeat'), @('episodic/2026-09-11.md','FreeUsageLimitError','2026-09-11 07:13 KST'))) {
  $p = Join-Path $mem ($pair[0] -replace '/','\')
  if (Test-Path -LiteralPath $p) {
    $t = [System.IO.File]::ReadAllText($p)
    Check ("windows-only content survived in " + $pair[0]) ($t.Contains($pair[1])) $pair[1]
    Check ("hub-only content survived in " + $pair[0]) ($t.Contains($pair[2])) $pair[2]
    $bytes = [System.IO.File]::ReadAllBytes($p)
    $crlf = ([regex]::Matches([System.Text.Encoding]::UTF8.GetString($bytes), "`r`n")).Count
    Check ("no CRLF in " + $pair[0]) ($crlf -eq 0) ("CRLF " + $crlf)
  } else {
    Check ("episodic file exists: " + $pair[0]) $false 'missing'
  }
}

$bak = @(Get-ChildItem -LiteralPath $mem -File -Filter '*.bak.*' -ErrorAction SilentlyContinue)
Check 'no install backup files left in the repository' ($bak.Count -eq 0) ("found " + $bak.Count)

$backups = @(Get-ChildItem -LiteralPath 'C:\Users\super\.aside' -Directory -Filter 'memory-backup-u0-*' -ErrorAction SilentlyContinue)
Check 'pre-join backups exist outside the repository' ($backups.Count -ge 1) ("found " + $backups.Count)
$holds = @(Get-ChildItem -LiteralPath 'C:\Users\super\.aside' -Directory -Filter 'memory-hold-*' -ErrorAction SilentlyContinue)
Check 'hold directory still exists outside the repository' ($holds.Count -ge 1) ("found " + $holds.Count)

Pop-Location

Write-Output ''
if ($fail -gt 0) {
  Write-Output ("join checks: " + $fail + " FAILED")
  exit 1
}
Write-Output 'join checks: all passed'
exit 0
