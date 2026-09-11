# 010 - 패치 계획 A: aside-jun 스킬 Windows 커버리지

근거는 `000_research.md` (Windows 실측)와 `001_parity-ledger-windows.md` (양 플랫폼 대조)다.

> **개정 (2026-09-11, `002_decisions-dual-shell.md`).** 사용자가 "PowerShell도 호환하되 bash를
> 1급으로" 를 요구해서 분리 축이 바뀌었다. 아래 결정 1~4는 그대로지만, WP0/WP2의
> **플랫폼당 한 셸** 레시피는 폐기한다. OS 파일 안에 bash와 PowerShell을 둘 다 1급으로 싣는다.
> `Kill($true)` 는 5.1에 없으므로 `taskkill /T /F` 로 대체한다.

## 설계 결정

### 결정 1. Windows용 별도 스킬을 만들지 않는다

패리티 원장이 이유다. Aside 제품 계약 — 파일 도구 권한 의미론, 거부 문구,
exit 0 fail-fast, 도구 카탈로그, `session`/`memory`/`host` 명령 — 은 두 플랫폼이 같다.
갈라지는 건 **우리가 Aside를 감싼 호스트 레이어**뿐이다. 스킬을 쪼개면 공통 계약이 두 벌이 되고
260902/260903에서 쌓은 권한 판정이 한쪽에서만 갱신되는 드리프트가 확정된다.

### 결정 2. SKILL.md에 플랫폼 분기를 인라인하지 않는다. 호스트 레이어를 추출한다

`SKILL.md` 는 499/500줄이다. 양쪽 레시피를 나란히 적을 공간이 없고, 적어도 안 된다.
구조를 이렇게 바꾼다.

```
SKILL.md                      플랫폼 중립 계약 + "호스트 레이어는 아래 둘 중 하나를 읽어라"
references/host-macos.md      Darwin 프리미티브(perl alarm / shlock / LaunchAgent / Seatbelt /
                              Apple Passwords)를 bash 와 PowerShell 양쪽 호출로 수록
references/host-windows.md    Windows 프리미티브(junction / 데드라인 / 명명 뮤텍스 /
                              Task Scheduler / AppContainer)를 bash 와 PowerShell 양쪽 호출로 수록
```

지금 SKILL.md에서 macOS 호스트 세부(perl alarm 표, shlock, cron/LaunchAgent 문단,
Seatbelt 문단)를 빼내면 **줄이 줄어든다.** 그 자리에 약 24줄짜리 선택 블록을 넣는다
(빼는 55줄, 넣는 24줄, 499 → 468. 상세는 `002` §D2).
500줄 제약을 늘리지 않고 커버리지가 두 배가 된다.

### 결정 3. `--permission full-access` 기본 유지. Windows에서는 근거가 하나 더 늘었다

260902 결정은 "guard의 조용한 누락을 피하려고 full-access를 exec 기본으로 둔다"였다.
Windows에서는 여기에 **guard의 `bash` 무한 교착**(001 §2)이 추가된다. 되돌릴 이유가 없다.

### 결정 4. 프롬프트의 `~` 표기를 전면 폐기한다

001 §1. Windows에서 `~` 는 확장되지 않고 리터럴 디렉터리가 되며 "Successfully wrote"를 보고한다.
macOS에서는 지금까지 문제가 없었지만, 같은 문장을 두 플랫폼이 공유하는 이상 **한쪽에서 조용히
틀리는 표기는 공용 문서에서 퇴출**한다. 대신 플랫폼별 계정 루트 절대경로를 변수로 잡아 쓴다.

## 작업 패키지

### WP0 - 진입점: 플랫폼 판정과 CLI 해석 (신규, SKILL.md 상단)

모든 명령보다 먼저 오는 블록이다. **설치 직후부터 `aside` 가 이름으로 안 잡히는 Windows 결함**
(000 §2)을 여기서 흡수한다. 사용자 조작 결과가 아니라 설치관리자가 junction print name을
`\??\C:\...` 로 써서 생기는 문제이므로, 스킬이 첫 단계에서 항상 해소하고 들어가야 한다.

네 칸을 모두 싣는다. 어느 쪽도 fallback 이라고 적지 않는다.

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

```bash
# macOS / bash - 비로그인 셸(SSH 등)은 ~/.local/bin 이 PATH에 없다
ASIDE="${ASIDE:-$HOME/.local/bin/aside}"
"$ASIDE" --version
```

```powershell
# macOS / PowerShell
$aside = "$HOME/.local/bin/aside"
& $aside --version
```

같이 명시할 것:
- `aside version` (대시 없음)은 버전 명령이 아니라 **에이전트 세션을 연다.** `--version` 만 쓴다.
- 버전을 문서에 고정하지 말 것. 실측 시점 양쪽 다 CLI `1.26.906.1630`, GUI `1.0.910.1`,
  데몬 `1.26.910.1749` 였고 CLI와 데몬은 더 이상 같은 번호 열차가 아니다.

### WP1 - SKILL.md 재구성 (대)

| 대상 | 조치 |
|---|---|
| L13 "Aside is macOS-only: the CLI is a `Mach-O` binary" | 교체. 양 플랫폼 지원, CLI는 macOS Mach-O / Windows PE. 로컬 실행에 GUI 앱 필요는 양쪽 공통 유지 |
| L16 "base-system `perl -e 'alarm ...'` and `shlock`" | 호스트 레이어 참조로 교체 |
| L54-57 Seatbelt 문단 | **삭제 후 이관.** macOS는 host-macos.md, Windows는 host-windows.md. Windows는 거부 문구가 없고 교착한다는 사실이 정반대라 한 문장으로 못 합친다 |
| L64-65, 88-89, 247-253, 302, 435 `perl alarm` 레시피 6곳 | 플랫폼 중립 문장 + 호스트 레이어 참조. "모든 exec는 호스트 데드라인 아래에서 돈다"는 규범만 SKILL.md에 남긴다 |
| L30, 73, 139, 238-240, 248-251, 264, 330 등 write fence `~/.aside/u/0/` | **절대경로화.** 결정 4 |
| L92-109 perl alarm 근거 표 | host-macos.md로 이관 |
| L20, 172, 276-277 Touch ID / Apple Passwords 6자리 | "생체/패스키/볼트 PIN 제스처"로 중립화, 구체는 credentials.md |
| L332-337 cron·LaunchAgent | "스케줄러에 넣기 전 확인할 것" 규범만 남기고 구체는 scheduling.md |
| L425 iMessage 언급 | macOS 한정 표시. Windows 빌트인에 없다 |
| L498 `~/.aside/u/0/models.json 와 accounts.json` | `accounts.json` 은 `u/0` 이 아니라 데이터 루트에 있다. 양 플랫폼 공통 오류 |
| 신규 | exit code는 성공 신호가 아니다 (001 §3). stdout에서 `is blocked by policy` 를 찾고 산출물을 직접 존재 확인한다 |

### WP2 - references/host-windows.md (신규, 핵심 산출물)

담을 것:

1. **CLI 해석과 junction 결함** (WP0 본문 + 대조 실험 요약).
2. **데드라인 (두 셸 모두).** 센티넬은 양 OS 공통으로 **142** 다.
   - PowerShell: `Start-Process -PassThru` + `WaitForExit(ms)`, 발화 시
     `taskkill /PID $p.Id /T /F` 후 `exit 142`. 통과 시 `exit $p.ExitCode`.
     `$p.Kill($true)` 는 **5.1에 없다** (실측: 5.1의 `Kill` 오버로드는 인자 0개 하나뿐).
     `$LASTEXITCODE` 는 `Start-Process` 뒤에서 의미가 없다.
   - Git Bash: `/usr/bin/timeout` 을 **절대 경로로** 부른다 (실측 GNU coreutils 8.32).
     124/137 을 142 로 재사상한다. 맨 `timeout` 철자는 System32 의 sleep 으로 갈 수 있어 금지한다.
   - 기각 근거표는 유지: System32 `timeout` 은 sleep, Cygwin `perl` 은 종료코드 3584.
3. **argv.** 프롬프트 앞에 `--` 를 넣는다. 인라인 산문은 argv 재구성으로 깨진다
   (실측 `unknown option '-TotalCount'`). `-ArgumentList` 는 배열이며 `; ` 로 조인하지 않는다.
3. **락.** `Global\AsideJob-<job>` 명명 뮤텍스. abandoned mutex가 `shlock` 의 스테일 회수를 대체한다.
4. **셸 도구.** 이름은 `bash`, 실체는 PowerShell. bash 문법을 넣으면 조용히 실패한다.
   **guard에서는 무한 교착**이므로 `bash` 를 쓸 계획이면 `--permission full-access` 가 필수.
   full-access에서 cwd는 `C:\Users\super\.aside\u\0\`.
5. **경로.** 계정 루트 `%USERPROFILE%\.aside\u\0`, 프로필 `%LOCALAPPDATA%\Aside\User Data`,
   데몬 로그 `%USERPROFILE%\.aside\logs\daemon-YYYY-MM-DD.log`, `/tmp`→`$env:TEMP`,
   `/etc/hosts`→`C:\Windows\System32\drivers\etc\hosts`.
   **`~/Documents` 를 `%USERPROFILE%\Documents` 로 가정하지 말 것** — 이 기계는 OneDrive 리디렉션으로
   `C:\Users\super\OneDrive\문서` 다. 셸 폴더 GUID로 해석한다.
6. **python.** PATH의 `python3` 은 Store 스텁이다. Aside 동봉 `%USERPROFILE%\.aside\runtime\bin\python3.cmd` (3.13.12)를 쓴다.
7. **repl 표기.** `pwd` 는 역슬래시, 세션 디렉터리는 `<YYYY-MM-DD>_<id>` 로 날짜 접두사가 붙는다.
   CLI가 찍는 id와 디렉터리명이 다르다. 호출마다 새 세션이라 상대 artifacts는 보존되지 않는다.
   `process` 전역 없음, `fs.readFile` 은 Buffer, 실패 판정은 끝줄 `[error | Nms]` 마커.
8. **argv 함정.** `Start-Process -ArgumentList` 로 프롬프트를 넘길 때 선행 대시 토큰이 옵션으로 먹힌다.
   프롬프트 앞에 `--` 를 넣는다. `created new session:` 은 stderr다.
9. **스케줄러.** Task Scheduler 요약(자세한 건 scheduling.md).

### WP3 - references/host-macos.md (신규, 기존 내용 이관)

SKILL.md와 scheduling.md에서 빼낸 macOS 호스트 레이어를 그대로 옮긴다.
`perl -e 'alarm shift; exec @ARGV'`, exit 142 근거표, `shlock`, cron/LaunchAgent, Seatbelt.

bash 칸만 옮기면 D1 위반이다. 같은 프리미티브를 PowerShell 에서 부르는 칸을 나란히 적는다.
데드라인은 `Start-Process -PassThru` + `WaitForExit(ms)` + `exit 142`,
락은 `shlock` 을 `&` 로 호출, LaunchAgent 의 `ProgramArguments` 는 `pwsh -File` 도 가능하다.
macOS 에 pwsh 가 없으면 그 칸은 문서상 계약이며 프리미티브는 동일하다고 명시한다.

이관하면서 한 문장만 고친다. "macOS에는 `timeout` 이 없다"는 **기본 시스템 기준**임을 명시한다.
실측 기계는 Homebrew coreutils가 깔려 로그인 PATH에서 `timeout`/`gtimeout` 이 잡힌다.
`flock` 은 brew를 켜도 없다. `perl` 을 고르는 근거(어디서나 있고 종료코드가 구분된다)는 그대로 유효하다.

### WP4 - references/permissions.md (대)

- L169-215 "bash는 다른 메커니즘이 관장한다" 절을 **플랫폼 분기**로 재작성.
  macOS: Seatbelt + `sandbox-exec`, `Operation not permitted`, `sandbox.enabled` **false**.
  Windows: `AsideWindowsSandboxHelper`(AppContainer+JobObject), `sandbox.enabled` **true**,
  그런데 guard에서는 헬퍼가 아예 안 뜨고 **교착**한다. 거부 문구가 존재하지 않는다.
- FILE_TOOL_CALLS 매핑은 공통이므로 유지.
- L228-251 grant-run-restore 스크립트를 PowerShell 판으로 병기.
- `/tmp`, `/etc/hosts`, `ls -la` 출력 예시를 플랫폼별로 교체.
- 파일 도구 거부 문구가 **양 플랫폼 동일**하다는 실측을 추가 (근거 강화).

### WP5 - references/scheduling.md (대)

- cron/LaunchAgent 절을 macOS 절로 명시하고, Windows Task Scheduler 절을 신규.
  트리거 N분 반복, 로그온 시에만 실행,
  **이미 실행 중이면 새 인스턴스 시작 안 함**(네이티브 락), `aside.exe` 절대경로.
  동작 줄은 **두 개를 나란히** 적는다.
  `pwsh.exe -NoProfile -File <run.ps1>` 와
  `"C:\Program Files\Git\bin\bash.exe" --noprofile --norc <run.sh> --quiet`.
  어느 쪽도 fallback 이 아니다.
- 잡 스크립트 예제를 두 벌로 병기한다. `.ps1` 은 뮤텍스 + `WaitForExit` + `taskkill /T /F`,
  `.sh` 는 `/usr/bin/timeout` + mkdir 락 + 124/137 → 142 재사상.
- `/Users/<you>/.aside/cli/bin/aside` 경로 폐기. 이 경로는 macOS에도 **없다**
  (실측: `~/.aside/cli` 에 `bin/` 없음, PATH는 `~/.local/bin/aside` 심볼릭).
- 세션 만료 관련 내용은 OS 무관이므로 유지.

### WP6 - references/credentials.md (중)

- Apple Passwords / PasswordImporter 컨테이너 / `com.apple.quarantine` / `open -a Aside` /
  `pgrep` 절을 **macOS 게이트**로 묶는다. Windows 빌트인에 `apple-passwords` 가 없다.
- Windows 진입은 Aside `passwordManager` + 1Password/Bitwarden/Dashlane/LastPass/Proton Pass.
- Touch ID → Windows Hello. 키 이름 `biometricUnlockEnabled` 는 양 플랫폼 공통이고
  실측상 **양쪽 다 false** 다. "꺼둬라" 지침은 유지.
- `python3 -c ...` 프로브를 `runtime\bin\python3.cmd` 로.

### WP7 - references/builtin-skills.md (중, 재생성)

헤더에 `/Users/jun/...` 가 박혀 있다. 플랫폼 열을 추가해 재생성한다.
실측 차이: macOS에만 `apple-passwords`, `imessage`, `site-specific`.
Windows에만 있는 건 없다. `scripts/refresh-builtin-summary.sh` 는 계정 루트를 인자로 받게 두고
`.ps1` 쌍을 **추가한다**. "Git Bash에서 실행하라" 로 끝내면 PowerShell 이 2등이 된다.
`.ps1` 은 020 WP6 과 같은 로케이터 규약을 따르는 얇은 진입점이다.

### WP8 - 소규모

- `repl-api.md`: `cua.keypress(['Meta','a'])` → Windows는 `Control`. `/etc/passwd` 예시 교체.
  Downloads 문구 중립화. 세션 cwd 표기와 `[error|ok]` 마커 추가.
- `deep-research.md`: `perl alarm 600` 1곳을 호스트 레이어 참조로.
- `refskill-aside.md`: `~/Library/Application Support/Aside/` 병기, mode 600 → NTFS 주석,
  "native macOS app UI" → "native OS app UI".
- `agents/openai.yaml`: 변경 없음.

### WP9 - README.md (중)

요구사항 절(L147-158)의 "macOS가 유일한 플랫폼", "Mach-O CLI만 배포", "macOS 27.0 arm64" 폐기.
양 플랫폼 요구사항과 설치 경로. Windows 설치는 `curl | bash` 가 아니라 **Settings > Developers**
(공식 components 체인지로그 1.26.907.1712에 명시). 스킬 설치 명령 `cp -R` 옆에 `Copy-Item -Recurse` 병기.

## 하지 않는 것

- 기존 `devlog/_plan/*` 재작성. macOS 시점의 역사적 근거다. 그대로 둔다.
- `--permission guard` 를 기본으로 되돌리기. Windows에서 근거가 더 강해졌다.
- Remote Control 세부 계약 작성. 양쪽 다 `MINI` 호스트가 **disabled** 라 실측이 없다. DEFER.
- 공식 릴리스 노트에 없는 1.26.904~906 동작을 공식으로 서술하기. 우리 실측으로만 표기한다.

## 작업 순서

WP0 → WP2 → WP3 → WP1 → WP4 → WP5 → WP6 → WP7 → WP8 → WP9.

host-windows.md / host-macos.md를 먼저 채우는 이유는, SKILL.md에서 잘라낼 대상이
어디로 가는지 확정돼야 500줄 예산 계산이 실측으로 잠기기 때문이다.

## 인수 조건

1. `rg -n "macOS-only|Mach-O|perl -e 'alarm" aside-jun/SKILL.md` → 0건.
2. `rg -n '~/\.aside/u/0/' aside-jun/SKILL.md` → 프롬프트 절 안에는 0건.
3. `wc -l aside-jun/SKILL.md` < 500.
4. `aside-jun/references/host-windows.md` 와 `host-macos.md` 존재.
5. 실행 가능한 모든 스니펫에 **OS와 셸이 둘 다** 라벨로 붙어 있고, 각 OS 파일 안에
   bash 와 PowerShell 이 모두 존재한다. 어느 쪽도 fallback 이라고 적혀 있지 않다.
6. Windows 실기에서 host-windows.md의 CLI 해석 스니펫이 `1.26.906.1630` 을 찍는다.
7. `bash` 도구 서술이 플랫폼별로 분기돼 있고, Windows 쪽에 guard 교착 경고와
   full-access 요구가 들어 있다.
8. macOS 회귀 없음 — `perl alarm`/`shlock`/LaunchAgent 절이 host-macos.md에 온전히 보존.
9. 맨 `timeout` 철자와 System32 `timeout.exe` 가 레시피로 등장하지 않는다.
   Git Bash 칸의 GNU timeout 은 `/usr/bin/timeout` 절대 경로다.
10. host-windows.md 의 데드라인 레시피가 `powershell.exe` 5.1 에서 파싱/실행된다.
    `Kill($true)` 가 등장하지 않고, `Start-Process` 뒤에서 `$LASTEXITCODE` 를 읽지 않는다.
