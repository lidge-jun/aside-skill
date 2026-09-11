# check-wp3.ps1 - wp3 acceptance checks. ASCII only; paths from $PSScriptRoot.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../../../../aside-memory-sync')).Path
$fail = 0
function Check([string]$n, [bool]$ok, [string]$d) {
  if ($ok) { Write-Output ('PASS  ' + $n) } else { Write-Output ('FAIL  ' + $n + '  :: ' + $d); $script:fail++ }
}
function Body([string]$rel) { Get-Content -LiteralPath (Join-Path $repo $rel) -Raw -Encoding utf8 }

# WP1 - attributes present and the INDEX is lf. The worktree legitimately stays crlf
# in an existing checkout, so never gate on the w/ column.
Check 'WP1 .gitattributes exists' (Test-Path -LiteralPath (Join-Path $repo '.gitattributes')) 'missing'
Check 'WP1 eol=lf declared' ((Body '.gitattributes') -match 'eol=lf') 'not declared'
Push-Location $repo
$eol = & git ls-files --eol
Pop-Location
$badIndex = @($eol | Where-Object { $_ -notmatch 'i/lf' })
Check ('WP1 every tracked file is i/lf (' + $eol.Count + ' files)') ($badIndex.Count -eq 0) (($badIndex | Select-Object -First 3) -join '; ')

# WP2 - the silent-identity bug and the sh-safe driver registration
foreach ($f in @('install.sh','sync.sh','autosync.sh')) {
  Check ($f + ': no hostname -s') ((Body $f) -notmatch 'hostname -s') 'silently yields an empty host'
}
$ins = Body 'install.sh'
Check 'WP2 driver: cygpath on the driver path' ($ins -match 'cygpath -m .\$DRIVER') 'sh eats the backslashes'
Check 'WP2 driver: cygpath on the interpreter too' ($ins -match 'cygpath -m .\$PY') 'sh eats these backslashes as well'
Check 'WP2 driver: placeholders stay bare' ($ins -match '%O %A %B %P') 'git substitutes them before sh sees them'
Check 'WP2 python probe rejects the Store stub' ($ins -match 'WindowsApps') 'command -v passes on a stub that exits 49'

# WP3 - merge driver Windows IO
$drv = Body 'bin/aside-memory-merge'
Check 'WP3 merge result is written LF' ($drv -match 'newline=') 'write_text would emit CRLF on Windows'
Check 'WP3 merge-file decoded as utf-8' ($drv -match 'encoding=.utf-8.') 'cp949 would mojibake Korean markdown'

# WP4 - the Windows scheduler branch, with the argv shape the locator contract requires
$ias = Body 'install-autosync.sh'
Check 'WP4 Windows branch exists' ($ias -match 'MINGW') 'Windows falls into the cron branch and dies'
Check 'WP4 no login-shell -lc action' ($ias -notmatch 'bash.exe. -lc') 'the -lc string form is banned'
Check 'WP4 argv uses --noprofile --norc' ($ias -match '--noprofile') 'profile PATH pollution'
Check 'WP4 launchd branch untouched' ($ias -match 'launchctl') 'macOS regression'

# WP6 - the PowerShell entry points
$ps1 = @('bin/invoke-git-bash.ps1','install.ps1','sync.ps1','autosync.ps1','install-autosync.ps1','hub-setup.ps1')
foreach ($f in $ps1) {
  $p = Join-Path $repo $f
  Check ($f + ': exists') (Test-Path -LiteralPath $p) 'missing'
  if (Test-Path -LiteralPath $p) {
    $bytes = [IO.File]::ReadAllBytes($p)
    $non = 0
    foreach ($b in $bytes) { if ($b -gt 127) { $non++ } }
    Check ($f + ': ASCII-only') ($non -eq 0) ('non-ascii bytes ' + $non)
    $ok = $true
    try { [void][ScriptBlock]::Create((Get-Content -LiteralPath $p -Raw)) } catch { $ok = $false }
    Check ($f + ': parses under 5.1') $ok 'syntax error'
  }
}
$hlp = Body 'bin/invoke-git-bash.ps1'
Check 'WP6 locator rejects WindowsApps' ($hlp -match 'WindowsApps') 'the 0-byte WSL stub would win'
Check 'WP6 locator never uses Get-Command bash' ($hlp -notmatch 'Get-Command bash') 'that resolves the stub'
Check 'WP6 exit code is propagated' ($hlp -match 'LASTEXITCODE') 'the caller cannot tell success from failure'
Check 'WP6 no Start-Process in the shim' ($hlp -notmatch 'Start-Process') 'it drops stdout and never sets LASTEXITCODE'

# WP5 - both invocations documented side by side
$rd = Body 'README.md'
Check 'WP5 README shows the bash entry' ($rd -match 'install\.sh') 'missing'
Check 'WP5 README shows the PowerShell entry' ($rd -match 'install\.ps1') 'PowerShell is not documented'
Check 'WP5 neither shell called a fallback' ($rd -notmatch '(?i)fallback') 'the word fallback appears'

$self = Join-Path $PSScriptRoot 'check-wp3.ps1'
$sb = [IO.File]::ReadAllBytes($self)
$sn = 0
foreach ($b in $sb) { if ($b -gt 127) { $sn++ } }
Check 'check-wp3.ps1 is ASCII-only' ($sn -eq 0) ('non-ascii bytes ' + $sn)

Write-Output ''
if ($fail -eq 0) { Write-Output 'wp3 checks: ALL PASS'; exit 0 }
Write-Output ('wp3 checks: ' + $fail + ' FAILED'); exit 1
