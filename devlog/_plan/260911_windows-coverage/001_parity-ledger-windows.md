# 001 - macOS/Windows 패리티 원장과 Windows 전용 결함 2건

양쪽 실기를 같은 날 같은 프로브로 측정했다. macOS는 `ssh macbookpro2` 원격 측정이다.
원문은 `evidence/probe-mac-parity.md`, `evidence/probe-win-followups.md`.

**두 기계의 CLI 버전이 같다: `1.26.906.1630`.** 즉 아래 차이는 버전 격차가 아니라 플랫폼 차이다.

## 패리티 원장

| 항목 | macOS 27.0 arm64 | Windows 11 (26200) |
|---|---|---|
| CLI 버전 | 1.26.906.1630 | 1.26.906.1630 |
| CLI 바이너리 | Mach-O arm64 | PE `aside.exe` |
| GUI / 데몬 | 1.0.910.1 / 1.26.910.1749 | 1.0.910.1 / 1.26.910.1749 |
| PATH 진입 | `~/.local/bin/aside` 심볼릭 → `~/.aside/cli/Aside CLI.app/Contents/MacOS/aside`, zshrc/zprofile가 PATH 선두 삽입 | `%LOCALAPPDATA%\Aside\CLI\current` junction이 **탐색 불가**, 이름 호출 실패 |
| `~/.aside/cli` | `Aside CLI.app` + `update-check.json`, **`bin/` 없음** | `update-check.json` 뿐 |
| `permission.sandbox.enabled` | **false** | **true** |
| file roots | `readableRoots/writableRoots=[]`, `outsideRead/Write=ask` | 동일 형태 |
| guard `read_file` 루트 밖 | `Permission denied: read '<path>' is blocked by policy`, ~4.9s, exit 0 | **동일 문구**, exit 0 |
| full-access 같은 읽기 | 성공 | 성공 |
| `ask_user_question` | 카탈로그에 없음 | 카탈로그에 없음 |
| 도구 카탈로그 | repl, write_todos, read_file, bash, webfetch, websearch, get_time, write_file, edit_file, history_search, memory_search, subagent, subagent_wait, routine_update, notification | 동일 + `multi_tool_use.parallel` |
| `bash` 도구 **실체** | 진짜 bash (`uname -s` → `Darwin`) | **PowerShell** (ParserError 반환) |
| guard에서 `bash` 호출 | (미측정) | **무한 교착** - 아래 §2 |
| `~` 확장 | (미측정) | **확장 안 됨** - 아래 §1 |
| 빌트인 스킬 차이 | `apple-passwords`, `imessage`, `site-specific` 추가 | 위 3종 없음 |
| 데드라인 | `/usr/bin/perl` `alarm`, exit **142** 확인 | `Start-Process`+`WaitForExit`, 2000ms에 2.099s |
| `shlock` | `/usr/bin/shlock` 존재 | 없음 → 명명 뮤텍스 |
| `timeout`/`flock` | 기본 시스템에 없음. 단 이 사용자는 Homebrew coreutils가 깔려 로그인 PATH에 `timeout`/`gtimeout` 이 **잡힌다**. `flock` 은 여전히 없음 | System32 `timeout` 은 sleep. Git GNU `timeout` 은 PATH 우선순위 의존 |
| `aside host list` | `* local`, `remote:c7aa3cd2-... MINI disabled` | 동일 |

결론: **Aside 제품 계약은 두 플랫폼이 거의 같다.** 파일 도구 권한 의미론, 거부 문구,
exit 0 fail-fast, 카탈로그 구성, 세션/메모리 명령이 모두 일치한다.
갈라지는 것은 셸 실체, 경로 표기, 그리고 호스트 레이어(데드라인/락/스케줄러/PATH)다.

## 1. Windows 결함: `~` 가 확장되지 않는다 (silent corruption)

현행 SKILL.md는 모든 exec 프롬프트에 write fence로 `~/.aside/u/0/` 를 박는다.
Windows에서 이 문장은 **조용히 틀린 곳에 쓴다**.

repl `fs.resolvePath` 로 경로 레이어를 직접 물어본 결정적 증거:

```
pwd:    C:\Users\super\.aside\u\0\sessions\2026-09-11_ZjIdIpw0LfSSidzK
tilde:  C:\Users\super\.aside\u\0\sessions\2026-09-11_ZjIdIpw0LfSSidzK\~\.aside\u\0\x.txt
rel:    C:\Users\super\.aside\u\0\sessions\2026-09-11_ZjIdIpw0LfSSidzK\x.txt
```

`~` 는 홈이 아니라 **이름이 `~` 인 디렉터리**가 된다. 그리고 write_file은 성공을 보고한다.

```
write_file(file_path: '~/.aside/u/0/tmp-probe-two.txt', ...)
 > Successfully wrote '~/.aside/u/0/tmp-probe-two.txt'
```

실제 파일은 `C:\Users\super\.aside\u\0\~\.aside\u\0\tmp-probe-two.txt` 에 있었고
`Test-Path 'C:\Users\super\.aside\u\0\tmp-probe-two.txt'` 는 `False` 였다.

3회 중 2회는 "잘 되는 것처럼" 보였는데, 그건 Aside가 아니라 **모델이 프롬프트를 읽고 먼저 절대경로로
바꿔서 호출했기 때문**이다. 비결정적이다. 문서가 기대면 안 된다.

| 프롬프트의 경로 표기 | Aside 해석 | 결과 |
|---|---|---|
| `~/.aside/u/0/f.txt` | `<cwd>\~\.aside\u\0\f.txt` | 잘못된 위치, 성공 보고 |
| `C:/Users/super/.aside/u/0/f.txt` | `C:\Users\super\.aside\u\0\f.txt` | 정상 |
| `C:\Users\super\.aside\u\0\f.txt` | 동일 | 정상 |

슬래시 방향은 상관없다. 문제는 오직 `~` 다.

## 2. Windows 결함: guard에서 `bash` 도구가 무한 교착한다

macOS 스킬은 "bash는 Seatbelt가 관장하고 막히면 `Operation not permitted` 를 찍는다"고 적는다.
Windows에는 **거부 문구가 없다.** 세션이 그냥 안 돌아온다.

```
--- STDOUT ---
bash(title: 'Read README first line',
     command: 'Get-Content -TotalCount 1 C:\\Users\\super\\Developers\\aside\\README.md')
--- STDERR ---
created new session: X0gol2MDSg8i4O16
```

여기서 멈춘다. 4회 재현(수동 킬 130s·75s, 데드라인 킬 150s·90s).
**파일을 전혀 건드리지 않는 `Write-Output HELLOPROBE` 도 똑같이 90초 교착**했으므로
파일 정책 문제가 아니다. 교착 중 진단:

- CPU 0.20s (스핀 아님), `Responding=True`
- `AsideWindowsSandboxHelper.exe` 자식 프로세스가 **한 번도 생성되지 않음**
- stdout/stderr/PTY 어디에도 승인 프롬프트 없음, 데스크톱 앱에 대화상자 없음
- 세션 `messages.jsonl` 에 `toolCall` 레코드만 있고 대응하는 tool result가 없음

같은 명령을 `--permission full-access` 로 돌리면 9.6초에 exit 0으로 정상 완료된다.

```
 > # aside
[powershell] current cwd changed to C:\Users\super\.aside\u\0\
```

이건 260902 감사가 "1.26.902에서 사라졌다"고 기록한 **행 걸림 실패 모드가 Windows의 셸 도구에서
되살아난 것**이다. 파일 도구(read_file/write_file)는 fail-fast로 정상 동작하므로 증상이 도구별로 갈린다.

따라서 Windows에서 `bash` 를 쓰려면 `--permission full-access` 가 사실상 필수이고,
호스트 데드라인은 선택이 아니라 필수다. 데드라인이 없으면 턴 하나가 통째로 증발한다.

## 3. 부수 확인

- **exit code는 신호가 아니다.** guard 파일 거부, repl `ReferenceError`, repl 루트 이탈이 전부 exit 0이다.
  0이 아닌 값은 commander가 argv를 거부한 `1` 뿐이었다. 성공 판정은 stdout에서
  `Permission denied:` / `is blocked by policy` 를 찾고, 기록했다는 파일을 `Test-Path` 로 직접 확인해야 한다.
- **repl 세션 디렉터리는 날짜 접두사가 붙는다.** CLI가 찍는 id는 `UjG8v8ehj3KUOslU` 인데
  실제 디렉터리는 `2026-09-11_UjG8v8ehj3KUOslU` 다. `pwd` 는 역슬래시 문자열이다.
- **repl 호출마다 새 세션 디렉터리**가 생긴다. 상대경로 artifacts는 호출 간 보존되지 않는다.
- repl에 `process` 전역은 없다. `fs.readFile` 은 Buffer를 반환한다.
  repl 실패는 exit code가 아니라 끝줄의 `[error | Nms]` / `[ok | Nms]` 마커로 판정해야 한다.
- 스크린샷은 `...\sessions\<YYYY-MM-DD>_<id>\tmp\` 에 떨어지고 `tmp\` 는 지연 생성된다.
  `artifacts\` 와 `messages.jsonl` 이 형제다. macOS 문서의 구조 설명은 맞고 표기만 다르다.
- `aside exec` 는 `created new session: <id>` 를 **stderr** 로 낸다. 전사는 stdout이다.
- `Start-Process -ArgumentList` 로 프롬프트를 넘기면 commander가 선행 대시 토큰을 옵션으로 먹는다
  (`unknown option '-TotalCount'`). 프롬프트 앞에 `--` 를 넣어야 한다.

## 4. macOS 쪽에서도 낡은 서술

- "Aside는 macOS 전용" — 같은 CLI 버전이 양쪽에 있다. 폐기.
- 고정 버전 `1.26.902.1732` / 데몬 `1.26.902.1713` — 실측은 CLI 1.26.906.1630,
  GUI 1.0.910.1, 데몬 1.26.910.1749. CLI와 데몬은 더 이상 같은 열차가 아니다.
- "macOS에는 `timeout` 이 없다"를 기계 사실로 쓰면 안 된다. 기본 시스템 기준으로는 맞지만
  이 사용자의 로그인 PATH에는 Homebrew coreutils의 `timeout`/`gtimeout` 이 잡힌다.
  `flock` 은 brew를 켜도 없다. `perl alarm` 을 고르는 근거 자체는 유효하다.
- `aside version` (대시 없음)은 버전 명령이 아니라 **에이전트 세션을 연다.** `aside --version` 만 쓴다.
