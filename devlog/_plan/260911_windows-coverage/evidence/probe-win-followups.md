# Windows 후속 프로브 원문

exe: `C:\Users\super\AppData\Local\Aside\CLI\versions\1.26.906.1630\aside.exe`.
에이전트 모델은 전사 기준 `gpt-5.6-luna`. 임시 파일은 전부 제거됨.

`aside exec` 는 `created new session: <id>` 를 **stderr**, 전사를 stdout으로 낸다.
`Start-Process -ArgumentList` 로 프롬프트를 넘기면 commander가 선행 대시 토큰을 옵션으로 먹는다
(`error: unknown option '-TotalCount'`, exit 1). 프롬프트 앞에 `--` 필요.

## 1. `~` 확장 - 되지 않는다

경로 레이어에 직접 물은 결정적 증거 (0.307s, exit 0):

```
pwd:    C:\Users\super\.aside\u\0\sessions\2026-09-11_ZjIdIpw0LfSSidzK
tilde:  C:\Users\super\.aside\u\0\sessions\2026-09-11_ZjIdIpw0LfSSidzK\~\.aside\u\0\x.txt
rel:    C:\Users\super\.aside\u\0\sessions\2026-09-11_ZjIdIpw0LfSSidzK\x.txt
```

guard 실행에서 모델이 `~` 를 그대로 넘긴 경우:

```
write_file(file_path: '~/.aside/u/0/tmp-probe-two.txt', content: "...")
 > Successfully wrote '~/.aside/u/0/tmp-probe-two.txt'
```

실제 위치는 `C:\Users\super\.aside\u\0\~\.aside\u\0\tmp-probe-two.txt`.
`Test-Path 'C:\Users\super\.aside\u\0\tmp-probe-two.txt'` → `False`.

full-access 실행 2회(9.891s / 9.358s, 둘 다 exit 0)는 정상 경로에 썼는데, 전사를 보면
**모델이 먼저 절대경로로 바꿔서 호출**했다.

```
write_file(file_path: 'C:\\Users\\super\\.aside\\u\\0\\tmp-probe-tilde.txt', content: 'PROBE')
 > Successfully wrote 'C:\Users\super\.aside\u\0\tmp-probe-tilde.txt'
WROTE=C:\Users\super\.aside\u\0\tmp-probe-tilde.txt
```

즉 "되는 것처럼 보이는" 동작은 모델 재량이고 비결정적이다.

## 2. guard의 `bash` 도구 - 거부가 아니라 교착

guard(기본), 파일 1줄 읽기:

```
--- STDOUT ---
bash(title: 'Read README first line',
     command: 'Get-Content -TotalCount 1 C:\\Users\\super\\Developers\\aside\\README.md')
--- STDERR ---
created new session: X0gol2MDSg8i4O16
```

`RESULT=TIMEOUT_KILLED SECONDS=150.0230356`. 4회 재현(수동 130s·75s, 데드라인 150s·90s).

대조군 - 파일을 전혀 안 건드리는 명령도 동일하게 교착:

```
bash(title: 'Run exact stdout probe', command: 'Write-Output HELLOPROBE')
RESULT=TIMEOUT_KILLED SECONDS=90.0155613
```

교착 중 진단: CPU 0.20~0.22s(스핀 아님), `Responding=True`,
`AsideWindowsSandboxHelper.exe` 자식 프로세스 미생성, PTY 포함 어디에도 승인 프롬프트 없음,
데스크톱 앱에 대화상자 없음. 세션 `messages.jsonl` 에 `toolCall` 만 있고 tool result가 없다.

full-access 동일 명령 - `EXITCODE=0 SECONDS=9.6024865`:

```
bash(title: 'Read first README line',
     command: 'Get-Content -TotalCount 1 C:\\Users\\super\\Developers\\aside\\README.md')
 > # aside
[powershell] current cwd changed to C:\Users\super\.aside\u\0\
RAW=# aside
```

## 3. `aside repl`

`process` 전역 없음:

```
ReferenceError: process is not defined
    at repl.js:1:13
[error | 18ms]
```

전역 목록:

```
fs, path, pwd, setTimeout, setInterval, clearTimeout, clearInterval, sleep, Buffer,
TextDecoder, TextEncoder, atob, btoa, console, display, tabs, getTabByTargetId, fetch,
openTab, closeTab, snapshot, annotatedScreenshot, installPageScript, page, cua, gmail,
googleAccounts, googleDocs, googlePeople, googleSearch, googleSheets, imageSearch,
imagegen, youtube, linkedin, twitter, notion, slack, blockToMarkdown,
markdownToBlockSpecs, listBrowserTabs, attachBrowserTab, attachActiveBrowserTab,
aside, applePasswords, captcha, chrome
```

```
typeof pwd: string
pwd: "C:\\Users\\super\\.aside\\u\\0\\sessions\\2026-09-11_2JbMs0Xc8bfYaxHZ"
fs keys: ["readFile","writeFile","mkdir","readdir","stat","lstat","unlink","rm","rename","copyFile","access","resolvePath"]
```

상대경로 artifacts 쓰기:

```
resolved: C:\Users\super\.aside\u\0\sessions\2026-09-11_cOnhnF7emED2kd74\artifacts\probe-repl.txt
readback: <Buffer 52 45 50 4c 50 52 4f 42 45>
listing: ["artifacts"]
```

루트 이탈: `Error: Path escapes Project and session roots: C:/Users/super/x.txt` - 그래도 **exit 0**.

## 4. `aside memory`

| 명령 | 시간 | exit | 결과 |
|---|---|---|---|
| `memory path` | 0.235s | 0 | `C:\Users\super\.aside\u\0\memory` |
| `memory list --json` | 0.231s | 0 | 5건 |
| `memory search "aside" --json` | ~0.3s | 0 | 점수 청크 |

`list` 는 상대 `path` + `absolutePath` 를 주고 `search` 는 절대 `path` 만 준다. 형태가 다르다.

## 5. 세션 디렉터리 구조

18개 세션 디렉터리의 자식 이름은 `artifacts`, `messages.jsonl`, `tmp` 세 종류뿐이다.

```
C:\Users\super\.aside\u\0\sessions\2026-09-10_8zTeZ5ktyFdkGLGF\tmp\korea-portal.png  189764
```

`tmp\` 는 지연 생성이라 스크린샷을 찍기 전에는 없다.

## 6. guard 부분 실패가 exit 0으로 끝난다

`EXITCODE=0 SECONDS=14.7787567`:

```
read_file(path: 'C:\\Windows\\System32\\drivers\\etc\\hosts', offset: 1, limit: 1)
 > Permission denied: read 'C:\Windows\System32\drivers\etc\hosts' is blocked by policy

write_file(file_path: '~/.aside/u/0/tmp-probe-two.txt', content: "Step 1 FAILED: ...")
 > Successfully wrote '~/.aside/u/0/tmp-probe-two.txt'

- Step 1: FAILED
- Step 2: SUCCEEDED
```

허용된 절반은 돌고 거부된 절반은 건너뛰며 exit status에는 아무 신호가 없다.
게다가 "SUCCEEDED" 쪽도 §1 때문에 엉뚱한 곳에 썼다.

## 정리

측정한 모든 실패 모드가 exit 0으로 끝났다. 0이 아닌 값은 commander가 argv를 거부한 `1` 뿐이다.
`aside` 의 exit code는 "CLI가 argv를 파싱했다" 이상의 의미가 없다.

임시 파일은 전부 제거됐다 (`tmp-probe-tilde*.txt`, 리터럴 `~` 트리, repl artifacts, `%TEMP%` 산출물).
프로브가 만든 교착 `aside.exe` 3개(PID 31584/34640/32640)는 경로 확인 후 종료했다.
데스크톱 앱 프로세스는 건드리지 않았다. 저장소는 쓰지 않았다.
