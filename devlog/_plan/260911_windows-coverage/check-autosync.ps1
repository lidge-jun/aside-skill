# check-autosync.ps1 - verify the Windows spoke is registered and round-tripping.
# ASCII only: a BOM-less non-ASCII .ps1 is reparsed as CP949 by Windows PowerShell 5.1.
# Read-only except for one 'git fetch', which does not change the working tree.

$ErrorActionPreference = 'Continue'
$mem  = 'C:\Users\super\.aside\u\0\memory'
$tool = 'C:\Users\super\.aside\tools\aside-memory-sync'
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

# --- the scheduled task exists, repeats, and is removable by name ---------
$q = schtasks.exe /Query /TN 'AsideAutosync' /V /FO LIST 2>&1
$qText = ($q | Out-String)
Check 'scheduled task AsideAutosync exists' ($LASTEXITCODE -eq 0) 'schtasks query failed'
Check 'task repeats every 15 minutes' ($qText -match '15 Minute') 'no 15-minute repetition'
Check 'task runs Git for Windows bash' ($qText -match 'Git\\bin\\bash.exe') 'unexpected command'
Check 'task runs autosync.sh quietly' ($qText -match 'autosync\.sh.*--quiet') 'unexpected arguments'
Check 'task does not use the WindowsApps bash stub' ($qText -notmatch 'WindowsApps') 'WindowsApps in the action'

# --- repos.conf pins the slot by path, not by number ----------------------
$confPath = Join-Path $tool 'repos.conf'
Check 'repos.conf exists' (Test-Path -LiteralPath $confPath) $confPath
if (Test-Path -LiteralPath $confPath) {
  $conf = Get-Content -LiteralPath $confPath -Raw
  Check 'repos.conf has the memory entry' ($conf -match 'memory\|.*u/0/memory\|hub\|driver') 'memory line missing or malformed'
  Check 'repos.conf records the account id' ($conf -match 'a291c31e-f7a3-4f57-a143-627c85cab7e6') 'no userId comment'
  Check 'repos.conf uses forward slashes only' ($conf -notmatch '\\\\') 'backslash in a path'
}

# --- the spoke is actually in sync with the hub ---------------------------
Push-Location $mem
git fetch hub 2>&1 | Out-Null
$head = (git rev-parse HEAD)
$hub  = (git rev-parse hub/main)
Check 'HEAD equals hub/main' ($head -eq $hub) ("HEAD " + $head.Substring(0,7) + " hub " + $hub.Substring(0,7))
# A live machine is SUPPOSED to have pending changes: the Aside daemon writes to
# today's episodic file continuously and autosync picks them up on the next run.
# So "clean tree" is the wrong invariant here. What must hold is that nothing is
# stuck in a conflicted state and no conflict marker leaked into tracked markdown.
$unmerged = @(git diff --name-only --diff-filter=U)
Check 'no unmerged paths' ($unmerged.Count -eq 0) ("unmerged " + $unmerged.Count)
$markers = @(git grep -l -E '^<<<<<<< ' -- '*.md' 2>$null)
Check 'no conflict markers in tracked markdown' ($markers.Count -eq 0) ("files " + $markers.Count)
$ahead = @(git log --oneline hub/main..HEAD)
Check 'nothing committed but unpushed' ($ahead.Count -eq 0) ("ahead " + $ahead.Count)

# --- the round trip really happened: our commit is in the hub history -----
$mine = @(git log hub/main --format='%s' -40 | Select-String -Pattern 'autosync: MINI')
Check 'a Windows autosync commit reached the hub' ($mine.Count -ge 1) 'no MINI commit in the last 40'

# --- and the hub content is a superset, not a replacement -----------------
$before = 'cba8137'
$lostTotal = 0
foreach ($rel in @('episodic/2026-09-10.md','episodic/2026-09-11.md')) {
  $oldText = (git show ($before + ':' + $rel) 2>$null | Out-String)
  $newText = (git show ('hub/main:' + $rel) 2>$null | Out-String)
  if ([string]::IsNullOrEmpty($oldText) -or [string]::IsNullOrEmpty($newText)) {
    Check ('could read both revisions of ' + $rel) $false 'git show returned nothing'
    continue
  }
  $newSet = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach ($ln in ($newText -split "`n")) {
    $t = $ln.Trim()
    if ($t.Length -gt 0) { [void]$newSet.Add($t) }
  }
  $lost = 0
  foreach ($ln in ($oldText -split "`n")) {
    $t = $ln.Trim()
    if ($t.Length -gt 0) { if (-not $newSet.Contains($t)) { $lost = $lost + 1 } }
  }
  $lostTotal = $lostTotal + $lost
  Check ('hub kept every line of ' + $rel) ($lost -eq 0) ("lost " + $lost + " lines")
}

Pop-Location

Write-Output ''
if ($fail -gt 0) {
  Write-Output ("autosync checks: " + $fail + " FAILED")
  exit 1
}
Write-Output 'autosync checks: all passed'
exit 0
