# 260911 Windows 커버리지 - 실측 연구

`aside-jun`과 `aside-memory-sync`는 둘 다 "Aside는 macOS 전용"을 전제로 쓰였다. 그 전제는 깨졌다.
이 문서는 Windows 실기에서 직접 측정한 값만 담는다. 추정은 별도로 표시한다.

측정 호스트: Windows 11 (빌드 26200), hostname `MINI`, 로캘 ko-KR, 콘솔 CP65001.
측정일 2026-09-11.

## 1. 설치 실태

| 구성요소 | 경로 | 버전 |
|---|---|---|
| GUI 앱 | `C:\Program Files\Aside\Application\Aside.exe` | 1.0.910.1 (1.0.907.1 잔존) |
| CLI | `C:\Users\super\AppData\Local\Aside\CLI\versions\1.26.906.1630\aside.exe` | 1.26.906.1630 |
| 데몬 | `...\Application\1.0.910.1\AsideDaemon\win-x64\aside-daemon.exe` | 1.26.910.1749 |
| 계정 루트 | `C:\Users\super\.aside\u\0\` | - |
| 브라우저 프로필 | `C:\Users\super\AppData\Local\Aside\User Data\` | - |
| 런타임 | `C:\Users\super\.aside\runtime\` (`platform: windows`) | node/python 3.13.12/pwsh/rg 동봉 |
| 설치 파일 | `C:\Users\super\Downloads\AsideInstaller-1.0.907.1-win-x64.exe` | - |

계정 루트 구조는 macOS와 같다. `u\0\` 아래 `state.db`, `settings.json`, `models.json`,
`credentials.json`, `sessions\`, `memory\`, `skills\`, `passwords\`가 모두 있다.
`accounts.json`은 `u\0\` 이 아니라 데이터 루트 `C:\Users\super\.aside\accounts.json` 에 있다.

## 2. PATH 진입점이 설치 직후부터 깨져 있다 (신규 결함)

사용자 PATH에 `C:\Users\super\AppData\Local\Aside\CLI\current` 가 들어 있는데
`aside` 는 이름으로 호출되지 않는다.

```
PS> Get-Command aside -All          # 출력 없음
PS> Test-Path "...\CLI\current\aside.exe"
False
PS> cmd /c dir "...\CLI\current"
 Directory of C:\Users\super\AppData\Local\Aside\CLI\current
File Not Found
```

junction 자체는 존재하고 대상도 실재한다. 문제는 기록된 이름이다.

```
PS> cmd /c dir /AL "...\Aside\CLI"
09/10/2026  08:46 PM    <JUNCTION>   current [\??\C:\Users\super\AppData\Local\Aside\CLI\versions\1.26.906.1630]
```

대조군을 직접 만들어 확인했다. `mklink /J` 로 같은 대상에 junction을 만들면 print name이
NT 네임스페이스 접두사 없이 찍히고 통과도 된다.

```
PS> cmd /c mklink /J "$env:TEMP\aside-junc-probe" "...\CLI\versions\1.26.906.1630"
09/11/2026  06:31 PM    <JUNCTION>   aside-junc-probe [C:\Users\super\AppData\Local\Aside\CLI\versions\1.26.906.1630]
PS> Test-Path "$env:TEMP\aside-junc-probe\aside.exe"
True
```

즉 Aside Windows 설치관리자가 junction의 print name을 `\??\C:\...` 형태로 써서
탐색이 실패한다. 사용자 조작 결과가 아니라 설치 직후 상태이므로 스킬 문서에
"설치 후 첫 단계"로 박아야 한다. 회피책은 버전 경로 직접 호출이다.

```powershell
$aside = Join-Path $env:LOCALAPPDATA 'Aside\CLI\current\aside.exe'
if (-not (Test-Path -LiteralPath $aside)) {
  $aside = Get-ChildItem "$env:LOCALAPPDATA\Aside\CLI\versions\*\aside.exe" |
           Sort-Object FullName | Select-Object -Last 1 -ExpandProperty FullName
}
```

## 3. CLI 표면은 macOS와 동일하다

`aside guide` 는 Windows에서 그대로 동작하고 `Aside CLI 1.26.906.1630 · Skill version 3` 을 찍는다.
공식 guide 본문에 OS 분기는 없다. `--help` 기준 명령/플래그도 macOS 기록과 같다:
`account login logout host memory skills exec repl mcp guide update session settings`,
`--permission ask|guard|full-access`, `--host`, `--effort`, `--account`.
`memory path` → `C:\Users\super\.aside\u\0\memory`. `skills list` 정상. `host list` 는
`local` 과 `remote:c7aa3cd2-... MINI disabled` 를 반환한다.

## 4. 권한 의미론은 Windows에서도 같다 (프로브 4건)

모두 `1.26.906.1630`, exit 0. 원문은 `evidence/probe-win-permission.md`.

| 프로브 | 조건 | 결과 |
|---|---|---|
| A | guard(기본), `read_file` 계정 루트 밖 | `Permission denied: read 'C:\Users\super\Developers\aside\README.md' is blocked by policy` |
| B | `--permission full-access`, 같은 읽기 | 성공, 첫 줄 `# aside` 반환 |
| W | guard, `write_file` → `%TEMP%` | `Permission denied: write '...\aside-probe-w.txt' is blocked by policy` |
| C | full-access, 도구 카탈로그 자기보고 | 아래 |

macOS 1.26.902에서 측정된 fail-fast 의미론이 Windows 1.26.906에서도 동일하다.
`ask_user_question` 은 여전히 카탈로그에 없다. 따라서 `--permission full-access` 를
exec 기본으로 두는 기존 결정(`260902_aside-update-audit/001_decisions.md`)은 Windows에서도 유효하다.

## 5. `bash` 도구는 Windows에서 PowerShell을 실행한다 (핵심 차이)

프로브 C가 보고한 Windows 도구 카탈로그:

```
repl, write_todos, read_file, bash, write_file, edit_file, webfetch, websearch,
get_time, history_search, memory_search, subagent, subagent_wait, routine_update,
notification, multi_tool_use.parallel
Shell: powershell
```

도구 이름은 `bash` 그대로다. 실제 인터프리터는 PowerShell이다. `echo SHELLPROBE` 와
PowerShell 표현식을 한 번에 넘긴 프로브에서 `SHELLPROBE` 가 출력되고 동시에
PowerShell `ParserError` 가 돌아왔다. bash 문법을 넣으면 조용히 실패한다.

데몬 번들에는 `SEATBELT_BASE_POLICY`/`sandbox-exec` 와
`AsideWindowsSandboxHelper.exe`(AppContainer + JobObject) 문자열이 함께 들어 있다.
Windows 설치의 `permission.sandbox.enabled` 는 **true** 로, macOS 프로브 당시의 false와 다르다.
따라서 SKILL.md의 "bash는 Seatbelt 아래에서 돌고 `Operation not permitted` 를 찍는다" 단락은
Windows에서 그대로 쓰면 안 된다.

**후속 실측으로 더 나쁜 사실이 나왔다.** guard 모드에서 Windows의 `bash` 도구는 거부되는 게 아니라
**무한 교착**한다. 파일을 건드리지 않는 명령도 마찬가지고, 샌드박스 헬퍼 프로세스가 아예 생성되지 않는다.
`--permission full-access` 에서는 9.6초에 정상 완료된다. 전문은 `001_parity-ledger-windows.md` §2.

## 6. 데드라인 프리미티브: `perl alarm` 은 Windows에서 성립하지 않는다

기존 스킬은 `perl -e 'alarm shift; exec @ARGV' 300 aside exec ...` 를 모든 exec 앞에 강제한다.
Windows 실측 결과 대체가 필요하다.

| 후보 | 판정 |
|---|---|
| System32 `timeout.exe` | 기각. 명령을 감싸지 않고 N초 대기만 한다. macOS에서 금지한 함정의 더 나쁜 버전이다. |
| Git GNU `timeout.exe` | 기본값 불가. PATH 우선순위에 따라 System32와 갈린다. 종료코드도 124다. |
| Git/Cygwin `perl` | 기각. 기본 Windows 구성요소가 아니고, 측정 종료코드가 142가 아니라 3584(`14<<8`)다. PowerShell 파싱에도 안전하지 않다. |
| `Start-Process` + `WaitForExit(ms)` + 트리 kill | **채택.** |

채택안 실측: 2000ms 데드라인에 30초 프로세스를 걸었더니 2.099초에 종료됐고
타임아웃 여부가 `WaitForExit` 반환값으로 분리된다.

> **정정 (002 참조).** 이 절의 첫 초안은 `$p.Kill($true)` 를 썼고 프롬프트를 인라인 인자로 넘겼다.
> 둘 다 틀렸다. `Kill(bool)` 은 pwsh 7 전용이고 Windows PowerShell 5.1 의 `Process.Kill` 은
> 인자 0개짜리 하나뿐이며 (5.1.26100.8655 / CLR 4.0.30319 실측), 프롬프트를 인라인으로 넘기면
> argv 재구성으로 CLI 가 산문을 플래그로 읽는다. 아래가 정정된 형태다.

```powershell
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

`--` 가 프롬프트 앞에 있어야 선행 대시 토큰이 CLI 옵션으로 먹히지 않는다.
리다이렉트가 없으면 `.StandardOutput` 은 비어 있다. `$LASTEXITCODE` 는 읽지 않는다.

142를 "데드라인 발화" 센티넬로 유지하면 기존 macOS 문서와 종료코드 계약이 맞춰진다.
락은 `shlock` 대신 명명 뮤텍스 `Global\AsideJob-<job>` 를 쓴다. 프로세스가 죽으면
abandoned mutex로 자동 회수되어 `shlock` 의 "살아있는 pid는 유지, 죽은 pid는 회수" 성질을 그대로 얻는다.

## 7. 호스트 도구 실태

| 도구 | 상태 |
|---|---|
| git | 2.55.0.windows.3, `core.autocrlf=true` (전역) |
| Git Bash | GNU bash 5.3.15, `C:\Program Files\Git\bin\bash.exe` |
| `WindowsApps\bash.exe` | 0바이트 WSL 스텁. PATH에서 이기면 안 된다 |
| pwsh | 7.6.6 |
| python3 | **없음.** PATH의 것은 Microsoft Store 리다이렉터다. `command -v python3` 는 통과하고 실행은 exit 49로 죽는다 |
| Aside 동봉 python | `C:\Users\super\.aside\runtime\bin\python3.cmd` (3.13.12) - 사용 가능 |
| `flock` / `shlock` / `crontab` / `launchctl` | 전부 없음 |
| `hostname -s` | **실패** (`unknown option -- s`). 맨 `hostname` → `MINI` |
| schtasks | 있음 |

## 8. 공개 정보 대조

Windows는 2026-09-06부터 초대제 프라이빗 베타다. 공식 다운로드 페이지와 get-started는
아직 macOS만 안내하고, developers 문서는 여전히 `curl ... install.sh | bash` 만 적어둔다.
Windows CLI의 공식 설치 경로는 **Settings > Developers** 이며 components 체인지로그
`1.26.907.1712`(2026-09-07)에 "Windows Install from Settings > Developers downloads faster"로
처음 명시됐다. `%LOCALAPPDATA%\Aside\CLI\current` PATH 심은 공식 문서에 없고 실측으로만 확인된다.

공개 components 체인지로그에는 `1.26.904`/`1.26.905`/`1.26.906` 항목이 없다. 이 호스트의
1.26.906.1630은 공개 최신 1.26.908.1846보다 한 단계 뒤다. 1.26.902의 `--permission` 추가와
deny fail-fast는 공식 릴리스 노트에 **없고**, 우리 devlog의 macOS 실측이 유일한 근거다.
이번 Windows 실측이 그 근거를 플랫폼 하나 더 확장한 셈이다.

## 9. 판정

- Aside 본체는 Windows에서 CLI/권한/세션/메모리까지 macOS와 같은 계약으로 동작한다.
- 깨지는 것은 Aside가 아니라 **우리 문서가 감싼 호스트 레이어**다: 경로 표기, 데드라인, 락,
  스케줄러, 셸, python, 그리고 설치 직후 PATH junction.
- 따라서 포팅 방향은 "Windows용 별도 스킬"이 아니라 "호스트 레이어를 플랫폼 분기로 분리"다.

단, 후속 실측에서 호스트 레이어가 아닌 **Aside 자체의 Windows 결함 2건**이 추가로 나왔다.
둘 다 조용히 틀리는 종류라 문서가 반드시 흡수해야 한다.

- 프롬프트의 `~` 가 확장되지 않고 리터럴 `~` 디렉터리가 되는데 "Successfully wrote" 를 보고한다.
- guard 모드의 `bash` 도구가 거부 대신 무한 교착한다.

자세한 건 `001_parity-ledger-windows.md`.
후속: `010_patch-plan-aside-skill.md`, `020_patch-plan-memory-sync.md`, `030_ship.md`.
