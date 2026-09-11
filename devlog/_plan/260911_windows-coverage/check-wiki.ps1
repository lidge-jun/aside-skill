# check-wiki.ps1 - verify the Windows kim_wiki clone matches the fleet and cannot push.
# ASCII only: a BOM-less non-ASCII .ps1 is reparsed as CP949 by Windows PowerShell 5.1.
# Read-only. The only network call is a read-only ls-remote.

$ErrorActionPreference = 'Continue'
$wiki = 'C:\Users\super\kim_wiki'
$conf = 'C:\Users\super\.aside\tools\aside-memory-sync\repos.conf'
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

Check 'kim_wiki is a git repository' (Test-Path -LiteralPath (Join-Path $wiki '.git')) $wiki
if (-not (Test-Path -LiteralPath (Join-Path $wiki '.git'))) { exit 1 }

Push-Location $wiki

$branch = (git rev-parse --abbrev-ref HEAD)
Check 'on branch main' ($branch -eq 'main') $branch

$clisu = (git config remote.clisu.url)
Check 'remote clisu exists' (-not [string]::IsNullOrEmpty($clisu)) 'missing'
Check 'remote clisu names the ubuntu user' ($clisu -match '^ubuntu@') $clisu
Check 'remote clisu points at the hub wiki' ($clisu -match 'kim_wiki\.git$') $clisu
$origin = (git config remote.origin.url)
Check 'remote origin points at GitHub' ($origin -match 'github\.com/lidge-jun/kim_wiki') $origin

$autocrlf = (git config --local core.autocrlf)
Check 'core.autocrlf is pinned to false locally' ($autocrlf -eq 'false') $autocrlf

# Line endings must match the Macs byte for byte, or every sync sees a whole-file diff.
foreach ($pair in @(@('README.md',1663), @('index.md',2575), @('AGENTS.md',3896))) {
  $p = Join-Path $wiki $pair[0]
  if (Test-Path -LiteralPath $p) {
    $bytes = [System.IO.File]::ReadAllBytes($p)
    Check ('byte size matches the Macs: ' + $pair[0]) ($bytes.Length -eq $pair[1]) ("got " + $bytes.Length + " want " + $pair[1])
    $crlf = ([regex]::Matches([System.Text.Encoding]::UTF8.GetString($bytes), "`r`n")).Count
    Check ('no CRLF in ' + $pair[0]) ($crlf -eq 0) ("CRLF " + $crlf)
  } else {
    Check ('file exists: ' + $pair[0]) $false 'missing'
  }
}

# The hub must be exactly where we left it: this machine is not allowed to push the wiki.
$remoteHead = (git ls-remote clisu refs/heads/main)
$localHead = (git rev-parse HEAD)
$remoteSha = ''
if ($remoteHead -match '^([0-9a-f]{40})') { $remoteSha = $Matches[1] }
Check 'could read the hub wiki head' ($remoteSha.Length -eq 40) $remoteHead
Check 'local head equals the hub head' ($localHead -eq $remoteSha) ("local " + $localHead.Substring(0,7) + " hub " + $remoteSha)
$ahead = @(git rev-list --count ('clisu/main..HEAD') 2>$null)

Pop-Location

# repos.conf must use the pull strategy. manual would auto-commit and auto-push.
Check 'repos.conf exists' (Test-Path -LiteralPath $conf) $conf
if (Test-Path -LiteralPath $conf) {
  $text = Get-Content -LiteralPath $conf -Raw
  $line = ($text -split "`n" | Where-Object { $_ -match '^\s*wiki\|' })
  Check 'repos.conf has a wiki entry' ($line) 'no wiki line'
  if ($line) {
    Check 'wiki uses the pull strategy, not manual' ($line -match '\|pull\s*$') $line.Trim()
    Check 'wiki entry names the clisu remote' ($line -match '\|clisu\|') $line.Trim()
    Check 'wiki path uses forward slashes' ($line -notmatch '\\') $line.Trim()
  }
}

Write-Output ''
if ($fail -gt 0) {
  Write-Output ("wiki checks: " + $fail + " FAILED")
  exit 1
}
Write-Output 'wiki checks: all passed'
exit 0
