# check-fleet.ps1 - one command that answers "is the whole Aside fleet aligned?"
# ASCII only: a BOM-less non-ASCII .ps1 is reparsed as CP949 by Windows PowerShell 5.1.
# Read-only. Every remote call is a query; nothing is fetched, committed or pushed.
#
# Slot numbers differ per machine on purpose. They are pinned here from measurement,
# not guessed, because matching on the number instead of the account has already
# nearly attached a stranger's stub account to the hub.

$ErrorActionPreference = 'Continue'
$fail = 0
$TOOL = '74c7b24'

function Check($label, $ok, $detail) {
  if ($ok) { Write-Output ("PASS  " + $label) }
  else {
    $msg = "FAIL  " + $label
    if ($detail) { $msg = $msg + "  :: " + $detail }
    Write-Output $msg
    $script:fail = $script:fail + 1
  }
}

function Remote($host_, $cmd) {
  $out = ssh -T -o BatchMode=yes -o ConnectTimeout=15 $host_ $cmd 2>&1
  return ($out | Out-String).Trim()
}

# name, ssh host, memory slot, expected wiki strategy
$machines = @(
  @('macbookpro2',    'macbookpro2',    '0', 'manual'),
  @('macmini',        'macmini',        '1', 'manual'),
  @('jun-macbookpro', 'jun-macbookpro', '1', 'manual')
)

Write-Output '--- hub ---'
$hubMem  = Remote 'clisu' 'git --git-dir=/home/ubuntu/git/aside-memory.git rev-parse --short main'
$hubWiki = Remote 'clisu' 'git --git-dir=/home/ubuntu/git/kim_wiki.git rev-parse --short main'
Check 'hub memory head is readable' ($hubMem -match '^[0-9a-f]{7,}$') $hubMem
Check 'hub wiki head is readable' ($hubWiki -match '^[0-9a-f]{7,}$') $hubWiki
Write-Output ("      memory " + $hubMem + "   wiki " + $hubWiki)

Write-Output ''
Write-Output '--- this Windows machine ---'
$winTool = (git -C 'C:\Users\super\.aside\tools\aside-memory-sync' rev-parse --short HEAD)
Check 'windows tool clone is current' ($winTool -eq $TOOL) ("got " + $winTool + " want " + $TOOL)
$winMem = (git -C 'C:\Users\super\.aside\u\0\memory' rev-parse --short HEAD)
Check 'windows memory matches the hub' ($winMem -eq $hubMem) ("local " + $winMem + " hub " + $hubMem)
$winWiki = (git -C 'C:\Users\super\kim_wiki' rev-parse --short HEAD)
Check 'windows wiki matches the hub' ($winWiki -eq $hubWiki) ("local " + $winWiki + " hub " + $hubWiki)
$winConf = (Get-Content -LiteralPath 'C:\Users\super\.aside\tools\aside-memory-sync\repos.conf' -Raw)
Check 'windows pins memory slot u/0' ($winConf -match 'memory\|[^|]*u/0/memory\|hub\|driver') 'memory line wrong'
Check 'windows wiki is pull, so it cannot push the wiki' ($winConf -match 'wiki\|[^|]*\|clisu\|pull') 'wiki line is not pull'
$task = schtasks.exe /Query /TN 'AsideAutosync' 2>&1
Check 'windows autosync task is registered' ($LASTEXITCODE -eq 0) 'schtasks query failed'

foreach ($m in $machines) {
  $name = $m[0]; $h = $m[1]; $slot = $m[2]; $strategy = $m[3]
  Write-Output ''
  Write-Output ('--- ' + $name + ' ---')

  $tool = Remote $h 'git -C ~/.aside/tools/aside-memory-sync rev-parse --short HEAD'
  Check ($name + ': tool clone is current') ($tool -eq $TOOL) ("got " + $tool + " want " + $TOOL)

  $mem = Remote $h ('git -C ~/.aside/u/' + $slot + '/memory rev-parse --short HEAD')
  Check ($name + ': memory matches the hub') ($mem -eq $hubMem) ("local " + $mem + " hub " + $hubMem)

  $wiki = Remote $h 'git -C ~/kim_wiki rev-parse --short HEAD'
  Check ($name + ': wiki matches the hub') ($wiki -eq $hubWiki) ("local " + $wiki + " hub " + $hubWiki)

  $conf = Remote $h 'cat ~/.aside/tools/aside-memory-sync/repos.conf'
  Check ($name + ': pins memory slot u/' + $slot) ($conf -match ('memory\|[^|]*u/' + $slot + '/memory\|hub\|driver')) 'memory line wrong'
  Check ($name + ': wiki strategy is ' + $strategy) ($conf -match ('wiki\|[^|]*\|' + $strategy)) 'wiki line wrong'

  $acct = Remote $h 'grep -c a291c31e-f7a3-4f57-a143-627c85cab7e6 ~/.aside/accounts.json'
  Check ($name + ': carries the fleet account') ($acct -match '[1-9]') ("matches " + $acct)
}

Write-Output ''
if ($fail -gt 0) {
  Write-Output ("fleet checks: " + $fail + " FAILED")
  exit 1
}
Write-Output 'fleet checks: all four machines agree with the hub'
exit 0
