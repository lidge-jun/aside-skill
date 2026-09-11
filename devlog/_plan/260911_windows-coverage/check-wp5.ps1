# check-wp5.ps1 - open-issue documentation checks. ASCII only; paths from $PSScriptRoot.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$fail = 0
function Check([string]$n, [bool]$ok, [string]$d) {
  if ($ok) { Write-Output ('PASS  ' + $n) } else { Write-Output ('FAIL  ' + $n + '  :: ' + $d); $script:fail++ }
}
$repl = Get-Content -LiteralPath (Join-Path $repo 'aside-jun/references/repl-api.md') -Raw -Encoding utf8
$skill = Get-Content -LiteralPath (Join-Path $repo 'aside-jun/SKILL.md') -Raw -Encoding utf8

# issue 1 - locator.screenshot must not be listed as an ordinary locator read
$readsLine = (Select-String -LiteralPath (Join-Path $repo 'aside-jun/references/repl-api.md') -Pattern 'Reads and chaining').Line
Check 'issue1 screenshot removed from the locator reads list' ($readsLine -notmatch 'screenshot') ('line still reads: ' + $readsLine)
Check 'issue1 the defect is named' ($repl -match 'Invalid parameters') 'the failure string is not documented'
Check 'issue1 the clip workaround is present' (($repl -match 'boundingBox\(\)') -and ($repl -match 'clip: box')) 'no runnable workaround'
Check 'issue1 the working screenshot APIs are named' ($repl -match 'annotatedScreenshot') 'reader cannot tell what still works'

# issue 2 - the session dirs start empty
Check 'issue2 empty session dir documented' ($repl -match 'do not exist yet') 'not stated'
Check 'issue2 ENOENT shown' ($repl -match 'ENOENT') 'the actual error is not shown'
Check 'issue2 mkdir remedy present' ($repl -match 'recursive: true') 'no remedy'
Check 'issue2 page.screenshot path named as an exception' ($repl -match 'page\.screenshot\(\{ path \}\)') 'measured exception missing'
Check 'issue2 page.pdf path named as an exception' ($repl -match 'page\.pdf\(\{ path \}\)') 'measured exception missing'

# the unmeasured call must NOT be sold as an exception
$saveAsOk = $true
foreach ($m in [regex]::Matches($repl, '(?m)^.*saveAs.*$')) {
  if ($m.Value -match 'not been measured') { continue }
  if ($m.Value -match 'exception') { $saveAsOk = $false }
}
Check 'download.saveAs is not claimed as a measured exception' $saveAsOk 'unmeasured behaviour presented as fact'

# SKILL.md carries the same warning at the repl session-files seam, and stays in budget
Check 'SKILL.md warns that the session dir starts empty' ($skill -match 'starts \*\*empty\*\*') 'warning missing'
Check 'SKILL.md names the two self-creating calls' (($skill -match 'page\.screenshot') -and ($skill -match 'page\.pdf')) 'exceptions missing'
$n = (Get-Content -LiteralPath (Join-Path $repo 'aside-jun/SKILL.md')).Count
Check ('SKILL.md under 500 (actual ' + $n + ')') ($n -lt 500) ('actual ' + $n)

# evidence is recorded
$evi = Join-Path $PSScriptRoot 'evidence/probe-open-issues.md'
Check 'probe evidence recorded' ((Test-Path -LiteralPath $evi) -and ((Get-Item -LiteralPath $evi).Length -gt 0)) 'missing or empty'

# deployment: the Codex skills copy must match the repo copy file for file
$dest = Join-Path $env:USERPROFILE '.codex\skills\aside-jun'
if (Test-Path -LiteralPath $dest) {
  $srcRoot = (Resolve-Path (Join-Path $repo 'aside-jun')).Path
  $dstRoot = (Resolve-Path $dest).Path
  $src = @(Get-ChildItem -Recurse -File -LiteralPath $srcRoot | ForEach-Object { $_.FullName.Substring($srcRoot.Length) } | Sort-Object)
  $dst = @(Get-ChildItem -Recurse -File -LiteralPath $dstRoot | ForEach-Object { $_.FullName.Substring($dstRoot.Length) } | Sort-Object)
  Check ('deploy: same file set (' + $src.Count + ' files)') ((Compare-Object $src $dst | Measure-Object).Count -eq 0) 'file sets differ'
  # .NET directly: Get-FileHash lives in Microsoft.PowerShell.Utility and is not
  # always autoloaded in a restricted host, which made this check fail under the
  # receipt runner while passing in an interactive shell.
  $bad = 0
  $sha = [System.Security.Cryptography.SHA256]::Create()
  foreach ($rel in $src) {
    if (-not (Test-Path -LiteralPath ($dstRoot + $rel))) { $bad++; continue }
    $h1 = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($srcRoot + $rel)))
    $h2 = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($dstRoot + $rel)))
    if ($h1 -ne $h2) { $bad++ }
  }
  $sha.Dispose()
  Check 'deploy: every file matches by SHA256' ($bad -eq 0) ('mismatched files ' + $bad)
} else {
  Check 'deploy: aside-jun is installed in the Codex skills directory' $false ('not found at ' + $dest)
}

# skill routing: aside-browser must be out of every skill root, and its backup must
# still exist unchanged outside them. Hash is the file's known SHA256.
$KNOWN = 'DC9166286989DE01F4D6087D4A21DFD91C5E6E0089B39589B555601754ABD3C6'
$skillRoots = @((Join-Path $env:USERPROFILE '.codex\skills'), (Join-Path $env:USERPROFILE '.agents\skills'))
$stray = 0
foreach ($r in $skillRoots) {
  if (Test-Path -LiteralPath $r) {
    $stray += @(Get-ChildItem -LiteralPath $r -Recurse -Directory -Filter 'aside-browser' -ErrorAction SilentlyContinue).Count
  }
}
Check 'routing: aside-browser is absent from every skill root' ($stray -eq 0) ('copies found ' + $stray)
$bkRoot = Join-Path $env:USERPROFILE '.codex\backups\skills'
$bkFile = $null
if (Test-Path -LiteralPath $bkRoot) {
  $bkFile = @(Get-ChildItem -LiteralPath $bkRoot -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue |
               Where-Object { $_.FullName -like '*aside-browser*' }) | Select-Object -First 1
}
if ($bkFile) {
  $s2 = [System.Security.Cryptography.SHA256]::Create()
  $h = [BitConverter]::ToString($s2.ComputeHash([IO.File]::ReadAllBytes($bkFile.FullName))).Replace('-','')
  $s2.Dispose()
  Check 'routing: the aside-browser backup is byte-identical' ($h -eq $KNOWN) ('hash ' + $h)
} else {
  Check 'routing: an aside-browser backup exists outside the skill roots' $false ('nothing under ' + $bkRoot)
}

$sb = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'check-wp5.ps1'))
$sn = 0
foreach ($b in $sb) { if ($b -gt 127) { $sn++ } }
Check 'check-wp5.ps1 is ASCII-only' ($sn -eq 0) ('non-ascii bytes ' + $sn)

Write-Output ''
if ($fail -eq 0) { Write-Output 'wp5 checks: ALL PASS'; exit 0 }
Write-Output ('wp5 checks: ' + $fail + ' FAILED'); exit 1
