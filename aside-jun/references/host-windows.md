# Windows 호스트 레이어

Aside 제품 계약은 macOS와 같다. 이 파일이 적는 것은 Windows가 소유한 프리미티브다.
CLI 위치, junction, 데드라인, 락, 경로, python, 스케줄러.
bash와 PowerShell은 둘 다 1급이다. 예시를 맞추려고 셸을 번역하지 않는다.
근거는 `devlog/_plan/260911_windows-coverage/000_research.md`,
`001_parity-ledger-windows.md`, `002_decisions-dual-shell.md` 다.

## CLI 해석과 junction 결함

## 앱은 끌 수는 있어도 켤 수는 없다

에이전트 컨텍스트에서 `Aside.exe` 를 띄우면 즉시 `0xC000027B` 로 죽는다.
`Start-Process` 도, stdio 리다이렉트를 떼도, `cmd /c start` 로 분리해도 같다.
Chromium 기반이라 진짜 대화형 데스크톱 세션이 필요한데 에이전트가 띄운 프로세스는
그 세션에 있지 않다. 종료는 `taskkill /PID <id> /T /F` 로 잘 된다. 그래서 아무 생각 없이
내리면 사용자가 직접 아이콘을 눌러야 하는 상태로 남는다.

**일회용 스케줄 작업으로 우회한다.** `InteractiveToken` 이 사용자 세션을 물려준다.

```powershell
# XML 은 UTF-16 이어야 schtasks 가 받는다. Principal 이 핵심이다.
#   <Principal id="Author"><LogonType>InteractiveToken</LogonType></Principal>
#   <Actions Context="Author"><Exec><Command>C:\Program Files\Aside\Application\Aside.exe</Command></Exec></Actions>
[IO.File]::WriteAllText($utf16Path, [IO.File]::ReadAllText($utf8Path), [Text.Encoding]::Unicode)
schtasks.exe /Create /TN "AsideRelaunchOneShot" /XML $utf16Path /F
schtasks.exe /Run    /TN "AsideRelaunchOneShot"
schtasks.exe /Delete /TN "AsideRelaunchOneShot" /F   # 끝나면 지운다
```

```bash
# Git Bash: schtasks 스위치가 /Create -> C:/Create 로 바뀌므로 변환을 꺼야 한다.
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' schtasks.exe /Run /TN "AsideRelaunchOneShot"
```

2026-09-12 확인: 이 방법으로 `Aside` 16개 + `aside-daemon` 1개가 정상 기동했다.

## 빈 문자열 인자를 PowerShell 로 넘기지 마라

`ssh-keygen -t ed25519 -N "" -f <경로>` 를 PowerShell 에서 돌리면 `-N` 에 빈 문자열이
들어가지 않는다. 암호 없는 키를 만들려다 **암호가 걸린 키**가 만들어지고, 파일도 권한도
멀쩡해 보여서 원인이 안 보인다.

증상은 서버가 아니라 클라이언트에서 난다.

```
debug1: Server accepts key: ... ED25519 SHA256:...
debug3: sign_and_send_pubkey: signing using ssh-ed25519 ...
debug2: we did not send a packet, disable method     <- 서명 실패. 클라이언트 문제다
```

`Server accepts key` 다음에 `we did not send a packet` 이 오면 `authorized_keys` 나
원격 권한을 뒤지지 마라. 개인키를 못 읽거나 못 푸는 것이다.

```bash
# Git Bash 에서 만든다. 인용이 예측 가능하다.
ssh-keygen -t ed25519 -N '' -C 'super@MINI-to-<host>' -f /c/Users/super/.ssh/id_ed25519_<host>
ssh-keygen -y -P '' -f /c/Users/super/.ssh/id_ed25519_<host>   # 즉시 답하면 암호 없음
```

## known_hosts 는 이름과 IP 를 따로 기억한다

`ssh <name>` 이 되는데 `~/.ssh/config` 에 `HostName <IP>` 를 넣는 순간 깨질 수 있다.
`known_hosts` 에 이름만 있고 IP 가 없으면 `Host key verification failed` 가 난다.
Tailscale MagicDNS 이름으로 신뢰가 잡힌 호스트에서 자주 겪는다.

IP 를 고정하고 싶으면 먼저 지문을 대조하고 등록해라. **신뢰 채널은 기존 구성원이다** —
이미 그 호스트에 붙는 다른 기기의 `known_hosts` 와 같은 지문인지 확인한다.

```powershell
ssh-keyscan -t ed25519 <ip> | Set-Content -LiteralPath $scan -Encoding ascii
ssh-keygen -lf $scan                       # 이 지문과
ssh <다른기기> 'ssh-keygen -F <ip> -f ~/.ssh/known_hosts'   # 저 기기가 가진 것이 같은가
```

사용자 PATH에 `%LOCALAPPDATA%\Aside\CLI\current` 가 들어 있다.
설치관리자가 만든 junction의 print name이 NT 네임스페이스 형식 `\??\C:\...` 이라
디렉터리가 빈 것으로 보이고, 설치 직후 `aside` 는 이름으로 해석되지 않는다.

```
PS> Get-Command aside -All          # 출력 없음
PS> Test-Path "...\CLI\current\aside.exe"
False
PS> cmd /c dir "...\CLI\current"
 Directory of C:\Users\super\AppData\Local\Aside\CLI\current
File Not Found

PS> cmd /c dir /AL "...\Aside\CLI"
09/10/2026  08:46 PM    <JUNCTION>   current [\??\C:\Users\super\AppData\Local\Aside\CLI\versions\1.26.906.1630]
```

같은 대상에 `mklink /J` 로 손으로 만든 junction은 print name이 `[C:\...]` 이고 통과한다.
000 §2 대조 실험. 사용자 조작 결과가 아니라 설치 직후 상태이므로, 모든 명령보다 먼저
버전 경로로 해석한다.

`aside version` (대시 없음)은 버전 명령이 아니라 에이전트 세션을 연다.
`--version` 만 쓴다. 버전 문자열을 문서에 고정하지 않는다.

```powershell
# Windows / PowerShell (5.1 과 7 공통)
$aside = Join-Path $env:LOCALAPPDATA 'Aside\CLI\current\aside.exe'
if (-not (Test-Path -LiteralPath $aside)) {
  $aside = Get-ChildItem "$env:LOCALAPPDATA\Aside\CLI\versions\*\aside.exe" |
           Sort-Object FullName | Select-Object -Last 1 -ExpandProperty FullName
}
& $aside --version
```

```bash
# Windows / Git Bash
ASIDE="$LOCALAPPDATA/Aside/CLI/current/aside.exe"
[ -x "$ASIDE" ] || ASIDE=$(ls -1 "$LOCALAPPDATA"/Aside/CLI/versions/*/aside.exe | sort | tail -1)
"$ASIDE" --version
```

`Get-Command bash` 는 쓰지 않는다. WindowsApps 의 `bash.exe` 는 0바이트 WSL 스텁이다.

## 데드라인

센티넬은 양 OS 공통으로 **142** 다. 발화하면 142, 아니면 자식 종료코드를 그대로 통과시킨다.
GNU timeout의 124/137은 bash 래퍼 안에서 142로 재사상한다. 공개 계약에 124를 노출하지 않는다.

`Start-Process` 는 `$LASTEXITCODE` 를 건드리지 않는다. `-PassThru` 의 `.ExitCode` 를 읽는다.
`.StandardOutput` 은 리다이렉트하지 않으면 빈 문자열이다.
`$p.Kill($true)` 는 Windows PowerShell 5.1 에 없다. 실측: `Kill` 오버로드는 인자 0개 하나뿐.
트리 킬은 `taskkill /PID <id> /T /F` 다.

프롬프트 앞에 `--` 를 넣는다. 인라인 산문은 argv 재구성으로 깨지고, 실측
`unknown option '-TotalCount'` (exit 1).
`-ArgumentList` 는 문자열 배열이다. 조각을 세미콜론으로 조인하지 않는다.
`created new session: <id>` 는 stderr, 전사는 stdout.

```powershell
# Windows / PowerShell (5.1 과 7 공통)
$out = Join-Path $env:TEMP 'aside-out.txt'
$err = Join-Path $env:TEMP 'aside-err.txt'
$p = Start-Process -FilePath $aside -PassThru -NoNewWindow `
     -RedirectStandardOutput $out -RedirectStandardError $err `
     -ArgumentList @('exec','--permission','full-access','--',$prompt)
if (-not $p.WaitForExit(300000)) {
  & "$env:SystemRoot\System32\taskkill.exe" /PID $p.Id /T /F | Out-Null
  exit 142
}
exit $p.ExitCode
```

```bash
# Windows / Git Bash
/usr/bin/timeout --kill-after=5 300 "$ASIDE" exec --permission full-access -- "$PROMPT"
rc=$?; [ $rc -eq 124 ] || [ $rc -eq 137 ] && rc=142
exit $rc
```

Git Bash 칸의 GNU timeout은 `/usr/bin/timeout` 절대 경로만 쓴다. 실측 GNU coreutils 8.32.

| 후보 | 판정 | 근거 |
|---|---|---|
| System32 timeout (sleep) | 기각 | 명령을 감싸지 않고 N초 대기만 한다 |
| PowerShell PATH에서 이름만으로 부르는 Git GNU timeout | 기각 | PATH 우선순위에 따라 System32 쪽과 갈린다 |
| Cygwin perl | 기각 | 종료코드 3584 (`14<<8`), 142가 아니다 |

## 락

Windows의 락 프리미티브는 명명 뮤텍스 `Global\AsideJob-<job>` 다.
홀더 프로세스가 죽으면 abandoned mutex가 되고, 다음 `WaitOne` 이
`AbandonedMutexException` 을 받은 뒤 소유권을 가져간다.
macOS `shlock` 의 "살아있는 pid는 유지, 죽은 pid는 회수"와 같다.
보안 주체는 토큰 SID 다. `$env:USERNAME` 으로 NTAccount 를 만들지 않는다.

```powershell
# Windows / PowerShell (5.1 과 7 공통)
$job = 'digest'
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
$rule = New-Object System.Security.AccessControl.MutexAccessRule(
  $sid,
  [System.Security.AccessControl.MutexRights]::Synchronize -bor [System.Security.AccessControl.MutexRights]::Modify,
  [System.Security.AccessControl.AccessControlType]::Allow
)
$sec = New-Object System.Security.AccessControl.MutexSecurity
$sec.AddAccessRule($rule)
$created = $false
$mutex = New-Object System.Threading.Mutex($false, "Global\AsideJob-$job", [ref]$created, $sec)
$owned = $false
try {
  try {
    $owned = $mutex.WaitOne(0)
  } catch [System.Threading.AbandonedMutexException] {
    $owned = $true
  }
  if (-not $owned) { exit 0 }
  # ... 잡 본문 ...
} finally {
  if ($owned) { $mutex.ReleaseMutex() | Out-Null }
  $mutex.Dispose()
}
```

```bash
# Windows / Git Bash
JOB=digest
LOCKDIR="${TEMP}/AsideJob-${JOB}.lock"
if [ -d "$LOCKDIR" ]; then
  find "$LOCKDIR" -maxdepth 0 -mmin +30 -exec rmdir {} \;
fi
mkdir "$LOCKDIR" || exit 0
trap 'rmdir "$LOCKDIR"' EXIT
```

## 셸 도구

도구 이름은 `bash` 다. Windows에서 실체는 PowerShell 이다.
한 프로브에서 `echo SHELLPROBE` 와 PowerShell 표현식을 같이 넣었더니
`SHELLPROBE` 가 출력되고 동시에 PowerShell `ParserError` 가 돌아왔다.
bash 문법을 넣으면 조용히 실패한다.

guard 에서는 거부 문구가 없다. 세션이 무한 교착한다. 4회 재현
(수동 킬 130s·75s, 데드라인 킬 150s·90s).
파일을 전혀 건드리지 않는 `Write-Output HELLOPROBE` 도 90초에 동일했다.
교착 중 CPU 0.20s, `Responding=True`,
`AsideWindowsSandboxHelper.exe` 자식이 한 번도 생성되지 않았고,
PTY·데스크톱에 승인 프롬프트가 없으며,
세션 `messages.jsonl` 에 `toolCall` 만 있고 tool result가 없다. 001 §2.

같은 명령을 `--permission full-access` 로 돌리면 9.6초에 exit 0으로 끝난다.
`bash` 를 쓸 계획이면 `--permission full-access` 가 필요하고, 호스트 데드라인은 필수다.
full-access에서 cwd는 `C:\Users\super\.aside\u\0\` .

```
 > # aside
[powershell] current cwd changed to C:\Users\super\.aside\u\0\
```

## 경로

| 역할 | Windows |
|---|---|
| 계정 루트 | `%USERPROFILE%\.aside\u\0` |
| 데이터 루트 | `%USERPROFILE%\.aside` |
| `accounts.json` | 데이터 루트. `u\0` 아래가 아니다 |
| 브라우저 프로필 | `%LOCALAPPDATA%\Aside\User Data` |
| 데몬 로그 | `%USERPROFILE%\.aside\logs\daemon-YYYY-MM-DD.log` |
| `/tmp` | `$env:TEMP` |
| `/etc/hosts` | `C:\Windows\System32\drivers\etc\hosts` |

`%USERPROFILE%\Documents` 로 가정하지 않는다. 이 호스트의 Documents는
OneDrive 리디렉션으로 `C:\Users\super\OneDrive\문서` 다. 셸 폴더 GUID로 해석한다.

```powershell
# Windows / PowerShell (5.1 과 7 공통)
$accountRoot = Join-Path $env:USERPROFILE '.aside\u\0'
$dataRoot    = Join-Path $env:USERPROFILE '.aside'
$accounts    = Join-Path $dataRoot 'accounts.json'
$profile     = Join-Path $env:LOCALAPPDATA 'Aside\User Data'
$daemonLog   = Join-Path $env:USERPROFILE ('.aside\logs\daemon-{0}.log' -f (Get-Date -Format 'yyyy-MM-dd'))
$tmp         = $env:TEMP
$hostsFile   = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$documents   = [Environment]::GetFolderPath('MyDocuments')
```

```bash
# Windows / Git Bash
ACCOUNT_ROOT="$USERPROFILE/.aside/u/0"
DATA_ROOT="$USERPROFILE/.aside"
ACCOUNTS="$DATA_ROOT/accounts.json"
PROFILE="$LOCALAPPDATA/Aside/User Data"
DAEMON_LOG="$USERPROFILE/.aside/logs/daemon-$(date +%F).log"
TMP="$TEMP"
HOSTS="$SYSTEMROOT/System32/drivers/etc/hosts"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Personal
```

## 물결표 결함

Aside의 경로 레이어는 선행 `~` 를 확장하지 않는다. 이름이 `~` 인 디렉터리를 만들고
`Successfully wrote` 를 보고한다. 001 §1, `fs.resolvePath` 출력:

```
pwd:    C:\Users\super\.aside\u\0\sessions\2026-09-11_ZjIdIpw0LfSSidzK
tilde:  C:\Users\super\.aside\u\0\sessions\2026-09-11_ZjIdIpw0LfSSidzK\~\.aside\u\0\x.txt
rel:    C:\Users\super\.aside\u\0\sessions\2026-09-11_ZjIdIpw0LfSSidzK\x.txt
```

`write_file(file_path: '~/.aside/u/0/tmp-probe-two.txt', ...)` →
`Successfully wrote '~/.aside/u/0/tmp-probe-two.txt'`.
실제 파일은 `C:\Users\super\.aside\u\0\~\.aside\u\0\tmp-probe-two.txt`.
`Test-Path 'C:\Users\super\.aside\u\0\tmp-probe-two.txt'` 는 `False`.

프롬프트에는 절대경로만 넣는다. 정슬래시 `C:/Users/...` 도 정규화된다. 문제는 오직 `~` 다.

```powershell
# Windows / PowerShell (5.1 과 7 공통)
$root = Join-Path $env:USERPROFILE '.aside\u\0'
# 프롬프트에 넣을 경로: $root 또는 $root.Replace('\','/')
```

```bash
# Windows / Git Bash
ROOT="$USERPROFILE/.aside/u/0"
# 프롬프트에 넣을 경로: $ROOT  (정슬래시 유지)
```

## python

PATH의 `python3` 는 Microsoft Store 스텁이다. `command -v python3` 는 통과하고 실행은 exit 49로 죽는다.
Aside 동봉 `%USERPROFILE%\.aside\runtime\bin\python3.cmd` 또는 그 안의 `python.exe` 를 쓴다.
실측 3.13.12. `WindowsApps` 경로는 거부한다.

```powershell
# Windows / PowerShell (5.1 과 7 공통)
$py = Join-Path $env:USERPROFILE '.aside\runtime\bin\python3.cmd'
if (-not (Test-Path -LiteralPath $py)) {
  $py = Join-Path $env:USERPROFILE '.aside\runtime\python\runtime\python.exe'
}
& $py -c "import sys; print(sys.version)"
```

```bash
# Windows / Git Bash
PY="$USERPROFILE/.aside/runtime/bin/python3.cmd"
[ -f "$PY" ] || PY="$USERPROFILE/.aside/runtime/python/runtime/python.exe"
case "$PY" in *WindowsApps*) echo "Store python stub"; exit 1 ;; esac
"$PY" -c "import sys; print(sys.version)"
```

## repl

Windows에서 `pwd` 는 역슬래시 문자열이다.
세션 디렉터리는 날짜 접두사 `<YYYY-MM-DD>_<id>` 이고, CLI가 찍는 id는 접두사 없는 값이다.
예: CLI `UjG8v8ehj3KUOslU`, 디렉터리 `2026-09-11_UjG8v8ehj3KUOslU`.

호출마다 새 세션 디렉터리가 생긴다. 상대 artifacts는 호출 간에 보존되지 않는다.
`process` 전역은 없다. `fs.readFile` 은 Buffer를 반환한다.
실패는 끝줄 `[error | Nms]` / `[ok | Nms]` 마커로 판정한다. exit code는 0으로 남는다.

```
ReferenceError: process is not defined
    at repl.js:1:13
[error | 18ms]
```

```powershell
# Windows / PowerShell (5.1 과 7 공통)
& $aside repl "console.log(pwd); console.log(typeof process)"
```

```bash
# Windows / Git Bash
"$ASIDE" repl "console.log(pwd); console.log(typeof process)"
```

스크린샷은 `...\sessions\<YYYY-MM-DD>_<id>\tmp\` 에 떨어지고 `tmp\` 는 지연 생성된다.
`artifacts\` 와 `messages.jsonl` 이 형제다.

## 종료코드는 성공 신호가 아니다

측정한 실패 모드가 전부 exit 0이었다. guard 파일 거부, repl `ReferenceError`,
repl 루트 이탈. 0이 아닌 값은 commander가 argv를 거부한 `1` 뿐이었다.
성공 판정은 stdout에서 `is blocked by policy` 를 찾고, 기록했다는 파일을 직접 확인한다.

```powershell
# Windows / PowerShell (5.1 과 7 공통)
Select-String -LiteralPath $out -Pattern 'is blocked by policy' -SimpleMatch
Test-Path -LiteralPath $claimedFile
```

```bash
# Windows / Git Bash
grep -F 'is blocked by policy' "$out" || true
test -e "$claimed_file"
```

## 스케줄러

잡 본문은 [scheduling.md](scheduling.md) 다. 여기서 필요한 한 줄은 이것이다.
스케줄된 동작의 인터프리터는 절대 경로다. schtasks 기본 PATH 에는 pwsh 7 이 없고
`%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe` 만 있다.
맨 `pwsh.exe` 를 액션에 두지 않는다. Git Bash 액션도 `Program Files\Git` 을 하드코딩하지 않고
로케이터가 찾은 `bash.exe` 절대 경로를 쓴다. 트리거는 N분 반복, 로그온 시에만 실행,
이미 실행 중이면 새 인스턴스를 시작하지 않는다.

```powershell
# Windows / PowerShell (5.1 과 7 공통) — 액션 인터프리터
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -File $runPs1
```

```bash
# Windows / Git Bash — 액션 인터프리터
"$BASH_EXE" --noprofile --norc "$RUN_SH" --quiet
```
