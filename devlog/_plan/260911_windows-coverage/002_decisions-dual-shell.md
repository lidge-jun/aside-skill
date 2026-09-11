# 002 - 이중 셸 결정 기록

사용자 요구가 바뀌었다. "앱 CLI 둘 다 PowerShell도 호환하되 bash를 1급으로 지원하라."
`010`/`020`은 플랫폼 분할(맥=bash, 윈도우=PowerShell)을 전제로 썼으므로 그 전제만 갈아낀다.
owner 파일과 work package 구성은 유지한다.

architect 컨설테이션(읽기 전용, grok-4.6)을 거쳐 D1~D6을 받았고, 아래는 main의 처분과
그 처분을 뒷받침하려고 **이 턴에 직접 측정한 값**이다.

## D1 - 분리 축은 OS다. 셸은 그 위의 1급 호출이다. (채택)

OS가 프리미티브를 소유한다: CLI 위치와 junction, 데드라인, 락, 스케줄러, 샌드박스, python, 경로 루트.
셸은 그 프리미티브를 부르는 방법이다. 따라서 문서는 OS로 나누고, **각 OS 문서 안에 bash와
PowerShell 스니펫을 나란히** 둔다. 넷으로 쪼개지 않는다.

셸로 나누면 launchd와 schtasks, junction과 `~/.local/bin`, Seatbelt와 AppContainer를 놓을 자리가 없다.
OS로만 나누면 Windows에서 실제로 도는 Git Bash 5.3.15가 2등 시민이 된다. 둘 다 틀렸다.

| | bash | PowerShell |
|---|---|---|
| macOS | `/usr/bin/perl` alarm + `shlock` + LaunchAgent | 같은 OS 바이너리를 `&`/`Start-Process`로 호출 |
| Windows | Git Bash `/usr/bin/timeout` + mkdir 락 + schtasks 액션이 `bash.exe` | `Start-Process` 데드라인 + 명명 뮤텍스 + schtasks 액션이 `pwsh -File` |

SKILL.md에는 선택 블록만 남긴다. "OS 파일 하나만 읽어라. 그 파일은 bash와 PowerShell을
둘 다 1급으로 적는다. 예시를 맞추려고 셸을 번역하지 마라."

## D2 - SKILL.md 줄 예산 (채택)

현재 499줄. 호스트 레시피와 OS 정당화 55줄을 빼고 선택 블록 24줄을 넣는다. **499 - 55 + 24 = 468.**
여유 32줄은 두 번째 셸 레시피에 쓰지 않는다.

빼는 블록: L13-16(macOS 전용 선언), L54-57(Seatbelt), L64-66, L88-109(perl 근거표),
L247-254(조립된 exec), L302, L335-338(cron/LaunchAgent), L435-443.

## D3 - 데드라인 계약: 센티넬 142로 통일 (채택)

네 칸 모두 하나의 계약을 따른다. 데드라인이 터지면 **142**, 아니면 자식 종료코드를 그대로 통과시킨다.
142를 고른 이유는 macOS에서 이미 측정된 계약이고(`128 + SIGALRM`), 바꾸면 기존 독자가 깨지기 때문이다.
GNU timeout의 124/137은 bash 래퍼 안에서 142로 재사상한다. 공개 계약에 124를 노출하지 않는다.

| OS | 셸 | 프리미티브 | 데드라인 판별 |
|---|---|---|---|
| macOS | bash | `/usr/bin/perl -e 'alarm shift; exec @ARGV'` | SIGALRM -> 142 |
| macOS | PowerShell | `Start-Process -PassThru` + `WaitForExit(ms)` | 반환값 false -> kill -> 142 |
| Windows | Git Bash | **`/usr/bin/timeout` 절대 경로만** | 124/137 -> 142로 재사상 |
| Windows | PowerShell | `Start-Process -PassThru` + `WaitForExit(ms)` | 반환값 false -> `taskkill /T /F` -> 142 |

### 이 턴에 측정해서 뒤집은 것: `Kill($true)`는 5.1에 없다

`010`의 Windows 스니펫은 `$p.Kill($true)`를 썼다. 그건 pwsh 7에서만 된다.

```
powershell.exe -NoProfile  ->  5.1.26100.8655 / CLR 4.0.30319.42000
                               KillOverloadParamCounts=0
pwsh 7.6.6                 ->  KillOverloadParamCounts=0,1
```

5.1의 `Process.Kill`은 인자 0개짜리 하나뿐이다. `Kill(bool)`은 .NET Core 3.0 이후 API라
.NET Framework에는 없다. 그래서 문서에 싣는 트리 kill은 `taskkill /PID $p.Id /T /F`로 간다.
두 런타임에서 모두 동작하고, 5.1에서 조용히 죽지 않는다.

### Windows bash 칸: `timeout`을 이름으로 부르지 않는다

```
"C:\Program Files\Git\usr\bin\timeout.exe" --version  ->  timeout (GNU coreutils) 8.32
bash --noprofile --norc -c 'command -v timeout'        ->  /usr/bin/timeout
```

Git Bash 네임스페이스 안에서는 `/usr/bin/timeout`이 GNU다. 그러나 PowerShell에서 맨 `timeout`은
PATH 순서에 따라 System32의 `timeout.exe`(명령을 감싸지 않는 **sleep**)로 갈 수 있다.
그래서 bash 칸은 절대 경로로 고정하고, PowerShell 칸에서는 `timeout`이라는 철자를 아예 쓰지 않는다.
안전망으로 `--version` 출력에 `GNU coreutils`가 있는지 확인한다.

### PowerShell 구현 제약 (fuck-powershell 코퍼스 프리플라이트)

- `Start-Process`는 `$LASTEXITCODE`를 **건드리지 않는다**. 이전 값이 그대로 남아 게이트가 거짓 통과한다.
  `-PassThru`의 `.ExitCode`를 읽는다. (`start-process-no-lastexitcode`)
- `.StandardOutput`은 리다이렉트하지 않으면 비어 있다. 화면에 보이는 것과 잡히는 것이 다르다.
- 프롬프트를 인라인 인자로 넘기지 않는다. PowerShell이 argv를 재구성해서 CLI가 산문을 플래그로 읽는다.
  실측: `unknown option '-TotalCount'`. 프롬프트 앞에 `--`를 넣고, 7.2+에서는
  `$PSNativeCommandArgumentPassing = 'Standard'`. (`prose-as-unknown-flags`, `oss-native-arg-quoting`)
- `-ArgumentList`는 문자열 배열이다. `; `로 조인하지 않는다. (`join-semicolon-splits-startprocess`)
- 배포하는 `.ps1`은 ASCII 전용으로 한다. 비ASCII가 들어가면 UTF-8 **BOM**이 필수다.
  BOM 없는 `.ps1`을 5.1이 CP949로 파싱한다. (`bom-less-ps1-cp949`)
- 보안 주체를 `$env:USERNAME`으로 만들지 않는다. 토큰 SID를 쓴다.
- `command -v` 대신 `Get-Command`.

## D4 - aside-memory-sync: `.sh`가 유일한 구현, `.ps1`은 1급 진입점 (채택)

`020`의 "안 A 채택"은 유지하되 "Windows는 `bash <경로>/sync.sh`로 부른다"는 문장을 폐기한다.
그 문장이 PowerShell을 2등으로 만든다.

- `bin/invoke-git-bash.ps1` - 로케이터 + 실행 + 종료코드 전파. 나머지가 dot-source 한다.
- `install.ps1`, `sync.ps1`, `autosync.ps1`, `install-autosync.ps1`, `hub-setup.ps1` - `$args`를 그대로 전달.

진입점 계약:

1. **bash 찾기.** `Get-Command bash`를 쓰지 않는다. WindowsApps의 0바이트 WSL 스텁이 이긴다.
   경로에 `WindowsApps` 세그먼트가 있으면 무조건 거부한다. 순서는
   `$env:ASIDE_GIT_BASH` -> `C:\Program Files\Git\bin\bash.exe` -> `(x86)` ->
   레지스트리 `HKLM:\SOFTWARE\GitForWindows` InstallPath -> `(Get-Command git.exe).Source`에서 거슬러 올라가기.
   파일명이 `bash.exe`이고 길이가 0보다 커야 한다.
2. **호출.** `& $bash --noprofile --norc $scriptMixed @args` 뒤에 `exit $LASTEXITCODE`.
   여기서는 `Start-Process`를 쓰지 않는다. 종료코드도 stdout도 잃는다.
3. **인자.** 각 인자를 별개의 argv 원소로 넘긴다. `bash -c "..."` 문자열에 보간하지 않는다.
4. **bash 부재.** ASCII 메시지로 실패하고 `exit 1`. WSL로 넘어가지 않고, 재구현하지 않는다.
5. **스케줄러.** Task Scheduler 액션은 여전히 `bash.exe ... autosync.sh --quiet`이다.
   등록을 PowerShell로도 할 수 있게 하되, **도는 것은 언제나 같은 `.sh`** 이다.

한 줄 규칙: 이 저장소의 `.ps1`은 bash를 찾고, argv를 넘기고, 종료코드를 전파하고, schtasks를 등록해도 된다.
머지/락/python 정책은 `.sh`와 `aside-memory-merge`에 남는다.

## D5 - 머지 드라이버 등록 (채택, 위험 하나 실측으로 해소)

```bash
DRIVER_WIN=$(cygpath -m "$DRIVER" 2>/dev/null || printf '%s' "$DRIVER")
PY_WIN=$(cygpath -m "$PY" 2>/dev/null || printf '%s' "$PY")
git config merge.aside.driver "\"$PY_WIN\" \"$DRIVER_WIN\" %O %A %B %P"
```

첫 토큰은 진짜 `python.exe`여야 한다. `.cmd`는 CreateProcess가 직접 못 띄우고,
확장자 없는 셔뱅 스크립트는 Store 스텁으로 간다.

숨은 위험이 하나 있었다. `~/.aside/runtime/bin/python3.cmd`는 `PYTHONHOME`과 `VIRTUAL_ENV`를
세팅한 뒤에 `python.exe`를 부른다. 그 래퍼를 건너뛰고 맨 `python.exe`를 등록하면 표준 라이브러리를
못 찾을 수 있다. 측정했다.

```
$env:PYTHONHOME=''; $env:PYTHONPATH=''
& 'C:\Users\super\.aside\runtime\python\runtime\python.exe' -c "import sys,re,subprocess,pathlib;..."
3.13.12
imports-ok

& '...python.exe' "...\bin\aside-memory-merge"
usage: aside-memory-merge %O %A %B %P     (exit 2)
```

`PYTHONHOME` 없이도 stdlib이 잡히고, 확장자 없는 드라이버 파일도 정상 실행된다. D5는 성립한다.

### 정정: git 은 드라이버 줄을 CreateProcess 하지 않는다. `sh` 에 넘긴다

architect 는 "git 이 token 0 을 CreateProcess 한다" 를 가정으로 남겼다. 그 가정은 틀렸고,
병행 세션이 같은 날 `fuck-powershell` 코퍼스에 검증 케이스로 등록했다
(`cases/args-quoting/git-merge-driver-sh-escapes.md`, issue #57).

git 은 `merge.<name>.driver` 값을 **셸 명령줄**로 취급하고 Windows 에서는 Git 번들 `sh` 를 쓴다.
결과가 세 가지로 갈린다.

| 등록 형태 | 결과 |
|---|---|
| 역슬래시 Windows 경로 | `C:UssuperAppData...: command not found` - 역슬래시가 이스케이프로 먹힌다 |
| 정슬래시 + 확장자 없는 셔뱅 파일 | 셔뱅이 `python3` 를 PATH 에서 찾아 Store 스텁으로 간다 |
| **인터프리터 명시 + 정슬래시 + 양쪽 따옴표** | `Merge made by the 'ort' strategy`, exit 0 |

결론은 바뀌지 않는다. `cygpath -m` 과 따옴표는 그대로 필요하다. 다만 **이유가 다르다.**
CreateProcess 의 공백 문제가 아니라 `sh` 의 역슬래시 이스케이프 문제이고,
`cygpath -m` 은 그 문제를 우회하는 게 아니라 원천에서 없앤다.
그리고 `%O %A %B %P` 는 git 이 셸보다 먼저 치환하므로 **따옴표 없이 두는 것이 맞다** (A5 해소).

파생 정정이 하나 더 있다. `.cmd` 를 token 0 으로 쓰면 안 된다는 근거("CreateProcess 가 못 띄운다")도
무효다. 케이스의 검증된 성공 사례가 `"...\python3.cmd"` 였다. 따라서 Aside 동봉 래퍼
`~/.aside/runtime/bin/python3.cmd` 와 맨 `python.exe` 둘 다 token 0 으로 쓸 수 있다.
우리는 `$PY` 가 해석한 것을 그대로 쓰되 `WindowsApps` 경로만 거부한다.

**검증 방법도 바뀐다.** 드라이버가 실행조차 못 됐을 때 git 은 그것을 평범한 충돌로 보고한다.
실행 실패와 "드라이버가 돌았지만 판단을 못 했다" 가 exit code 상 구분되지 않는다.
원인 줄은 `Auto-merging` **앞에** 찍히므로 로그 꼬리만 보면 놓친다.
따라서 인수 조건은 exit code 가 아니라 **병합 결과 파일 내용**으로 판정한다.

## D6 - 배포 `.ps1`은 5.1과 7 양쪽에서 돈다 (채택)

Task Scheduler와 다른 도구가 띄우는 것은 `powershell.exe` 5.1이다. 7 전용으로 쓰면
정작 스케줄된 잡에서 깨진다. ASCII 전용, `&&`/`||` 없음, `Kill($true)` 없음.

## 010/020/030에 대한 처분

| 항목 | 처분 |
|---|---|
| 010 결정 1 (Windows 전용 스킬 안 만듦) | 유지 |
| 010 결정 2 (호스트 레이어 추출) | 유지. 추출 대상 파일 안에 두 셸이 공존하도록 조인다 |
| 010 결정 3 (`full-access` 기본) | 유지 |
| 010 결정 4 (프롬프트에서 `~` 폐기) | 유지 |
| 010 WP0/WP2의 PowerShell 전용 Windows 레시피 | **대체** (D1/D3) |
| 010 WP2의 `Kill($true)` + 인라인 `$prompt` | **대체** (D3/D6, 5.1 실측) |
| 020 안 A (단일 bash 코드베이스) | 유지 |
| 020 "하지 않는 것: .ps1 병행 포팅" | "두 번째 오케스트레이터를 만들지 않는다"로 한정. 얇은 진입점은 허용 |
| 020 WP5의 bash 전용 Windows 호출 | **대체** (D4) |
| 030 "얇은 심" | 유지하되 편의가 아니라 1급 진입점으로 승격 |
| 260830~260903 이력 | 손대지 않음 |

## 남은 가정

- `aside exec`에는 `--prompt-file`이 없다. `--help` 기준이며 `--` 구분자로 간다.
- `%O %A %B %P`를 따옴표 없이 두는 것이 안전하다. git 임시 경로는 보통 공백이 없지만 `%P`는 작업트리 경로다.
  공백 경로에서 실패하면 그때 따옴표를 씌운다. 지금 추측해서 바꾸지 않는다.
- macOS에 pwsh가 설치돼 있지 않아 macOS PowerShell 칸은 문서상 계약이다. 프리미티브 자체는 동일하므로 위험은 낮다.
- Remote Control은 양쪽 호스트가 disabled라 여전히 DEFER.
