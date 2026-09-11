# 020 - 패치 계획 B: aside-memory-sync Windows 커버리지

대상 저장소: `../aside-memory-sync` (형제 서브모듈). 근거는 Windows 실기 감사이며
파일:줄 인용은 해당 저장소 기준이다.

> **개정 (2026-09-11, `002_decisions-dual-shell.md`).** 안 A(단일 bash 코드베이스)는 유지한다.
> 다만 아래 WP5 의 "Windows 는 `bash <경로>/sync.sh` 로 부른다" 는 문장을 폐기한다.
> 그 문장이 PowerShell 을 2등으로 만든다. `.sh` 가 유일한 구현이라는 점은 그대로 두고,
> **얇은 PowerShell 진입점을 1급으로 추가**한다 (WP6). 아래 "하지 않는 것" 의
> `.ps1` 항목은 "두 번째 오케스트레이터를 만들지 않는다" 로 한정된다.
> WP2-3 의 머지 드라이버 근거도 코퍼스 #57 로 교체됐다 (CreateProcess 가 아니라 `sh`).

## 전략 결정: Git Bash 단일 코드베이스 + 얇은 Windows 심 (안 A)

두 안을 놓고 골랐다.

| | A. Git Bash + 심 | B. `.ps1` 병행 포팅 |
|---|---|---|
| 공수 | 1~2일 | 4~6일 + 영구 이중 유지 |
| 드리프트 | 머지 정책 1벌 | 오케스트레이터 2벌이 갈라진다 |
| 위험 | PATH의 `bash`/`python3` 스텁 | 락·병렬·머지중단 재구현 |

**A를 채택한다.** 이 저장소의 두뇌는 이미 Python 머지 드라이버이고 셸은 git/ssh 오케스트레이터다.
Windows 실기의 Git Bash 5.3.15는 배열, `[[ ]]`, 프로세스 치환, `trap RETURN/EXIT`,
`mktemp -d`, GNU `find -newermt`, mkdir 락까지 이미 다 돌린다. 실패는 다섯 군데에 몰려 있다.
`sync.sh`/`autosync.sh`/`hub-setup.sh` 를 PowerShell로 복제하면 앞으로 머지 정책을 바꿀 때마다
두 번 고쳐야 하는데, 얻는 것은 `bash.exe` 경유를 안 써도 된다는 편의뿐이다.

단, 안 A는 "Git Bash만 깔면 된다"가 아니다. **Git Bash 안에서도 여전히 깨지는 것**이 있고
그게 실제 블로커다. 아래 WP1~WP3이 그 부분이다.

## WP1 - 줄바꿈 위생 (선행 필수)

가장 조용하고 가장 파괴적인 항목이라 먼저 닫는다.

실측: 전역 `core.autocrlf=true` 인데 이 저장소에 `.gitattributes` 가 **없다**.
그래서 Windows 체크아웃이 모든 파일을 CRLF로 바꾸고, `install.sh` 는 그 CRLF 사본을
메모리 저장소에 `templates/gitattributes` 로 심는다. 현재 Aside가 쓰는
`C:\Users\super\.aside\u\0\memory\*.md` 는 전부 LF다.

파손 경로: Windows가 CRLF 블롭을 커밋 → macOS는 LF 블롭 → 드라이버 1단계인
`git merge-file` 이 **모든 줄을 상이**로 판정한다. `MEMORY.md`/`USER.md`/`episodic/` 은
`splitlines()` 휴리스틱이 구제하지만 `TAXONOMY.md` 는 분류가 `other` 라
`merge-file` 충돌 마커가 파일 전체에 박힌다.

작업:

1. 저장소 루트에 `.gitattributes` 신규: `* text=auto eol=lf`, `*.sh text eol=lf`,
   `bin/aside-memory-merge text eol=lf`.
2. `git add --renormalize .` 로 인덱스 정규화.
3. `templates/gitattributes` 에 `*.md text eol=lf` 추가(현재 `* text=auto eol=lf` 는 유지).
4. `install.sh` 가 메모리 저장소에 `git config core.autocrlf false` 를 박도록 추가.

검증 (C): Windows 체크아웃에서 `git ls-files --eol` 이 전부 `i/lf w/lf`.
메모리 저장소에서 `git config core.autocrlf` → `false`.

## WP2 - install.sh: Git Bash에서도 죽는 3곳

### 2-1. `hostname -s` (install.sh:116,117,129 / sync.sh:38 / autosync.sh:99)

MSYS `hostname` 에는 `-s` 가 없다(`unknown option -- s`). `install.sh` 는 `set -e` 라
여기서 **설치가 중단**된다. 이 호스트에는 전역 `user.email` 도 없어서 반드시 이 분기를 탄다.

수정: `HOST=$(hostname); HOST=${HOST%%.*}` 공용 함수로 3개 파일 통일.

### 2-2. python3 오탐 (install.sh:100)

`command -v python3` 이 Microsoft Store 리다이렉터를 잡아 **통과**한다. 그리고 실행하면 exit 49로 죽는다.
가드가 거짓 초록이라 더 나쁘다.

수정: 존재 확인이 아니라 실행 확인으로 바꾼다.

```bash
PY=$(command -v python3 || command -v python) || die "python 없음"
case "$PY" in *WindowsApps*) die "Store python 스텁이다. python.org CPython 또는 Aside 동봉 런타임을 써라" ;; esac
"$PY" -c "import sys; sys.exit(sys.version_info < (3,8))" || die "python 3.8+ 필요"
```

대안 경로: Aside가 `C:\Users\super\.aside\runtime\bin\python3.cmd` (3.13.12)를 이미 동봉한다.
별도 설치를 강요하지 않으려면 이걸 fallback 후보에 넣는다.

### 2-3. 머지 드라이버 등록 (install.sh:104) — 가장 중요한 한 줄

현재:

```bash
git config merge.aside.driver "$DRIVER %O %A %B %P"
```

실기 재현으로 원인을 확정했다. 감사 단계의 추정("git.exe가 첫 토큰을 Win32로 스폰한다")은 **틀렸다.**
git은 드라이버 명령을 Win32로 스폰하지 않고 **번들 sh에 넘긴다.** 그래서 이 설정값은 argv 벡터가 아니라
셸 명령줄이고, Windows 경로의 백슬래시가 이스케이프로 먹힌다. 3단 대조:

| 등록 형태 | 결과 |
|---|---|
| `C:\\Users\\...\\mydriver %O %A %B %P` | `line 1: C:UserssuperAppData...: command not found` → CONFLICT, exit 1 |
| `C:/Users/.../mydriver %O %A %B %P` | 경로는 풀리고 shebang이 Store python 스텁에 걸림 → CONFLICT, exit 1 |
| `"<python>" "C:/Users/.../mydriver" %O %A %B %P` | `Merge made by the 'ort' strategy`, exit 0, 내용이 드라이버 출력 |

세 실패가 전부 **평범한 merge conflict로 위장된다.** 드라이버가 0이 아닌 값으로 끝나면 "충돌"이라는 게
git의 정의이므로, 실행조차 못 한 드라이버와 실행 후 충돌한 드라이버를 exit code로 구분할 수 없다.
재현 스크립트와 원문은 `fuck-powershell` 코퍼스의 케이스
`cases/args-quoting/git-merge-driver-sh-escapes.md` (issue #57)에 있다.

수정:

```bash
DRIVER_WIN=$(cygpath -m "$DRIVER" 2>/dev/null || printf '%s' "$DRIVER")
git config merge.aside.driver "\"$PY\" \"$DRIVER_WIN\" %O %A %B %P"
```

인터프리터 접두사와 따옴표가 둘 다 필수다. `Program Files` 나 공백 있는 사용자명에서 즉시 깨진다.
`%O %A %B %P` 는 git이 임시 경로를 넣으므로 따옴표 없이 둔다. 전체를 `bash -c` 로 감싸면 안 된다.
`chmod +x` (install.sh:98) 의존은 버린다. NTFS + `core.filemode=false` 에서 실행 비트는 남지 않고,
인터프리터를 명시하면 애초에 필요 없다.

검증 (C): `git config merge.aside.driver` 출력에 python 경로와 따옴표가 보인다.
양쪽 브랜치에서 `MEMORY.md` 를 서로 다르게 고친 뒤 머지해 충돌 마커 없이 구조 병합되는지 확인.
**exit code로 검증하지 말 것.** 드라이버가 아예 실행되지 않아도 git은 충돌로 보고한다.
병합 결과 파일의 내용을 직접 확인해야 한다.

## WP3 - bin/aside-memory-merge: Windows I/O 2곳

| 줄 | 현재 | 문제 | 수정 |
|---|---|---|---|
| 54-57 | `Path(path).write_text(text, encoding="utf-8")` | `newline=None` 이라 Windows에서 `\n`→`\r\n` 로 번역된다. `eol=lf` 를 약속한 저장소에 CRLF를 되돌려 쓴다 | `newline="\n"` 명시 |
| 62-70 | `subprocess.run([...], capture_output=True, text=True)` | `text=True` 가 프로세스 로캘로 디코드한다. 기본 ko-KR cp949 파이썬이면 한국어 마크다운이 휴리스틱 전에 깨진다. 이 호출은 try/except 밖이다 | `encoding="utf-8", errors="surrogateescape"` 명시 |

`classify()` 는 이미 `path.replace("\\", "/")` 를 하므로 Windows `%P` 는 문제없다.

## WP4 - install-autosync.sh: Windows 스케줄러 분기 (유일한 대형 신규 코드)

현재 분기는 Darwin → `launchctl`, 그 외 → `crontab` 이다. Windows의 `uname` 은
`MINGW64_NT-...` 라 cron 분기를 타고, `crontab` 이 없어서 죽는다.

**Task Scheduler를 고른다.** 서비스나 pwsh 무한루프가 아니다.
launchd의 대응물이 그것이고(사용자 모드, 주기, 재부팅 생존, 로그온 시에만 실행),
서비스는 LocalSystem으로 돌아 SSH 키와 Git Credential Manager가 끊긴다.
루프는 로그오프에 죽고 우선순위 제어가 없다.

`MINGW*|MSYS*|CYGWIN*` 분기를 추가하고:

- 트리거: 1회 + N분 간격 무한 반복
- 동작: `"C:\Program Files\Git\bin\bash.exe" -lc "<autosync.sh 경로> --quiet"`
- 로그온 시에만 실행 (`LogonType Interactive`)
- 우선순위 8~10 (launchd `Nice 10` / `LowPriorityIO` 대응)
- **이미 실행 중이면 새 인스턴스 시작 안 함** — 네이티브 락
- `--remove` → `schtasks /Delete /TN AsideAutosync /F`

락은 그대로 둔다. `autosync.sh:68-77` 의 mkdir 락은 Git Bash에서 원자적으로 동작함을 확인했고
(`두 번째 mkdir → File exists`), `find -mmin +30` 스테일 회수도 GNU find 4.10에서 돈다.
`flock` 은 원래 안 쓴다.

## WP5 - 문서/설정

- `README.md`: Windows 요구사항 절 신규. Git for Windows(Git Bash), 실제 CPython 3.8+ 또는
  Aside 동봉 런타임, Task Scheduler. `./sync.sh` 는 어느 OS에서도 메모리 저장소에 복사되지 않으므로
  `bash <경로>/sync.sh` 호출을 명시. `/tmp/ours` (README:227)는 `$(mktemp)` 로.
- `repos.conf.example`: 슬롯이 `u/1` 로 박혀 있는데 이 호스트는 `u/0` 이다. 경로에 역슬래시 금지 명시.
- `templates/gitignore`: `Thumbs.db`, `desktop.ini`, `ehthumbs.db` 추가.
- `AGENT.md`: 충돌 확인 예시에 `git diff --diff-filter=U` / `Get-Content` 병기.

## 하지 않는 것

### 근거가 이미 코퍼스에 있는 항목

WP3의 `text=True` 로캘 디코딩은 추정이 아니다. `fuck-powershell` 의 기존 케이스
`cases/encoding/python-subprocess-locale-encoding.md` (issue #47)가 같은 실패를 이미 문서화했다.
WP2-3(머지 드라이버)과 WP1(줄바꿈)은 이번 라운드에 `git-merge-driver-sh-escapes` (#57)로 추가됐다.

- `.ps1` 로 **두 번째 오케스트레이터**를 만드는 것 (안 B) — 머지 정책과 락이 갈라진다.
  WP6 의 얇은 진입점은 여기 해당하지 않는다.
- `flock`/`shlock` 도입 — 원래 안 쓴다.
- hub를 Windows로 옮기기 — `hub-setup.sh:39-55` 의 `chmod 700` 이 NTFS ACL 대응이 없다. hub는 Unix로 유지한다.

## WP6 - PowerShell 진입점 (1급, 신규)

구현은 늘리지 않고 **호출 경로만** 늘린다. 로직이 `.ps1` 로 새어 나가면 안 A 의 이점이 사라진다.

새 파일 (전부 **ASCII 전용**):

- `bin/invoke-git-bash.ps1` — bash 로케이터 + 실행 + 종료코드 전파. 나머지가 dot-source 한다.
- `install.ps1`, `sync.ps1`, `autosync.ps1`, `install-autosync.ps1`, `hub-setup.ps1` — `$args` 전달만.

로케이터 규칙:

1. `Get-Command bash` 금지. WindowsApps 의 0바이트 WSL 스텁이 이긴다.
   경로에 `WindowsApps` 세그먼트가 있으면 무조건 거부한다.
2. 탐색 순서: `$env:ASIDE_GIT_BASH` → `C:\Program Files\Git\bin\bash.exe` →
   `C:\Program Files (x86)\Git\bin\bash.exe` → 레지스트리 `HKLM:\SOFTWARE\GitForWindows`
   의 `InstallPath` + `\bin\bash.exe` → `(Get-Command git.exe).Source` 에서 `..\bin\bash.exe`.
3. 파일명이 `bash.exe` 이고 크기가 0보다 커야 한다.

호출 규칙:

```powershell
& $bash --noprofile --norc $scriptMixed @args
exit $LASTEXITCODE
```

`Start-Process` 를 쓰지 않는다. 종료코드도 stdout 도 잃는다. `$scriptMixed` 는 역슬래시를
슬래시로 바꾼 `C:/...` 형태다. 인자는 `bash -c "..."` 문자열에 보간하지 않고 argv 원소로 넘긴다.
`--noprofile --norc` 로 프로필 PATH 오염을 피하되, Windows PATH 는 그래도 상속되므로
WP2 의 python 실행 확인은 여전히 필요하다.

bash 가 없으면 ASCII 메시지로 실패하고 `exit 1`. WSL 로 넘어가지 않는다.

5.1 호환: `&&`/`||` 없음, `Kill($true)` 없음, 비ASCII 없음(넣으려면 UTF-8 BOM).

## 작업 순서

WP1 → WP2 → WP3 → WP4 → WP6 → WP5. WP1이 선행인 이유는, 줄바꿈을 고치기 전에 install을 돌리면
CRLF 템플릿이 메모리 저장소에 심어져 이후 검증이 전부 오염되기 때문이다.
WP5(문서)가 마지막인 이유는 WP6 의 진입점 이름이 확정돼야 README 의 두 줄을 같이 적을 수 있기 때문이다.

## 인수 조건

1. Windows Git Bash에서 `install.sh` 가 끝까지 통과한다 (현재는 `hostname -s` 에서 중단).
2. `git config merge.aside.driver` 의 token 0 이 실제 인터프리터 경로이고, 경로가 **정슬래시**이며
   양쪽이 따옴표로 감싸여 있고 `%O %A %B %P` 는 따옴표 없이 남아 있다. `WindowsApps` 경로가 아니다.
3. macOS에서 고친 `MEMORY.md` 와 Windows에서 고친 같은 파일이 충돌 마커 없이 병합된다.
   **판정은 git 의 exit code 가 아니라 병합 결과 파일 내용으로 한다** — 드라이버가 실행조차
   못 했을 때 git 은 그것을 평범한 충돌로 보고하기 때문이다 (코퍼스 #57).
4. 병합 결과 파일이 LF다.
5. `schtasks /Query /TN AsideAutosync` 가 등록을 보여주고, `--remove` 로 사라진다.
6. macOS 쪽 동작은 회귀 없음 — launchd 분기와 `.sh` 문법은 손대지 않는다.
7. `.\install.ps1` 과 `./install.sh` 가 같은 `install.sh` 에 도달한다. README 가 두 줄을 나란히 보여준다.
   로케이터가 `Get-Command bash` 를 쓰지 않는다.
8. 배포된 `.ps1` 이 전부 ASCII 전용이다 (바이트 확인). 비ASCII가 있으면 UTF-8 BOM 이 붙어 있다.
