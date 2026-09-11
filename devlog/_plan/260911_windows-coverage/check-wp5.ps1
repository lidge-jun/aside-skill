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

$sb = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'check-wp5.ps1'))
$sn = 0
foreach ($b in $sb) { if ($b -gt 127) { $sn++ } }
Check 'check-wp5.ps1 is ASCII-only' ($sn -eq 0) ('non-ascii bytes ' + $sn)

Write-Output ''
if ($fail -eq 0) { Write-Output 'wp5 checks: ALL PASS'; exit 0 }
Write-Output ('wp5 checks: ' + $fail + ' FAILED'); exit 1
