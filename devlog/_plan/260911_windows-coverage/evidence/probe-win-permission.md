# Windows 권한/셸 프로브 원문

호스트: Windows 11 build 26200, hostname MINI. CLI `1.26.906.1630`.
호출은 전부 버전 경로 직접 호출이다 (`CLI\current` junction 미탐색 - 000_research.md 2절).

```
$EXE = 'C:\Users\super\AppData\Local\Aside\CLI\versions\1.26.906.1630\aside.exe'
```

## probe A - guard(기본), 계정 루트 밖 read_file

명령:

```powershell
& $EXE exec "Use the read_file tool to read C:\Users\super\Developers\aside\README.md and print its first line verbatim. Do not use any other tool, do not browse the web. If a tool call is refused, report the EXACT error text and the tool name, then stop."
```

출력 (ANSI 제거):

```
created new session: CuGwFDHXWKqgPQXg

read_file(path: 'C:\\Users\\super\\Developers\\aside\\README.md', offset: 1, limit: 1)

 > Permission denied: read 'C:\Users\super\Developers\aside\README.md' is blocked by policy
`functions.read_file`: Permission denied: read 'C:\Users\super\Developers\aside\README.md' is blocked by policy
```

exit 0. 즉시 반환(행 걸림 없음). macOS 1.26.902 프로브 A와 문구까지 동일하다.

## probe B - --permission full-access, 같은 read_file

```
created new session: IsWKHF1NlyBP8Jko

read_file(path: 'C:\\Users\\super\\Developers\\aside\\README.md', offset: 1, limit: 1)

 > # aside

[26 more lines in file. Use offset=2 to continue.]
# aside
```

exit 0. guard가 막던 경로를 full-access가 연다. macOS 프로브 B와 같은 결론.

## probe W - guard, 계정 루트 밖 write_file

대상은 `%TEMP%` 로 잡았다. 저장소를 건드리지 않기 위해서다.

```
created new session: bmMwxEI0IX1M7wo7

write_file(file_path: 'C:\\Users\\super\\AppData\\Local\\Temp\\aside-probe-w.txt', content: 'PROBE')

 > Permission denied: write 'C:\Users\super\AppData\Local\Temp\aside-probe-w.txt' is blocked by policy
Permission denied: write 'C:\Users\super\AppData\Local\Temp\aside-probe-w.txt' is blocked by policy
```

exit 0. `%TEMP%` 는 guard의 기본 writableRoots 밖이다.

## probe C - full-access, 도구 카탈로그 자기보고

```
created new session: vfEtctV7kXxpdMqK
functions.repl
functions.write_todos
functions.read_file
functions.bash
functions.write_file
functions.edit_file
functions.webfetch
functions.websearch
functions.get_time
functions.history_search
functions.memory_search
functions.subagent
functions.subagent_wait
functions.routine_update
functions.notification
multi_tool_use.parallel
Shell: powershell
```

`ask_user_question` 없음 - macOS 1.26.902 관찰과 일치. 도구 이름은 `bash` 이나
에이전트 스스로 셸이 powershell이라고 보고한다.

## probe D - `bash` 도구의 실제 인터프리터

명령(프롬프트): `Call the bash tool exactly once with the command: echo SHELLPROBE; $PSVersionTable.PSVersion.ToString().`

```
created new session: yQWaKLlRqRAJO5rS

bash(title: 'Run shell probe',
     command: 'echo SHELLPROBE; \System.Management.Automation.PSVersionHashTable.PSVersion.ToString()')

 > [stderr]
ParserError:
Line |
   8 |  ... \System.Management.Automation.PSVersionHashTable.PSVersion.ToString()
     |                                                                         ~
     | An expression was expected after '('.

[exit code 1]
SHELLPROBE
```

`echo SHELLPROBE` 가 통과했고 PowerShell 파서가 오류를 냈다. `bash` 도구는 Windows에서
PowerShell을 실행한다. bash 문법을 담아 보내면 조용히 실패한다.
(프롬프트 전달 과정에서 `$PSVersionTable` 이 변형됐으나 파서 정체 판정에는 영향이 없다.)

## junction 대조 실험

```
PS> cmd /c dir /AL "C:\Users\super\AppData\Local\Aside\CLI"
09/10/2026  08:46 PM    <JUNCTION>  current [\??\C:\Users\super\AppData\Local\Aside\CLI\versions\1.26.906.1630]
PS> Test-Path "C:\Users\super\AppData\Local\Aside\CLI\current\aside.exe"
False

PS> cmd /c mklink /J "$env:TEMP\aside-junc-probe" "C:\Users\super\AppData\Local\Aside\CLI\versions\1.26.906.1630"
Junction created for C:\Users\super\AppData\Local\Temp\aside-junc-probe <<===>> C:\Users\super\AppData\Local\Aside\CLI\versions\1.26.906.1630
PS> cmd /c dir /AL $env:TEMP | Select-String "aside-junc-probe"
09/11/2026  06:31 PM    <JUNCTION>  aside-junc-probe [C:\Users\super\AppData\Local\Aside\CLI\versions\1.26.906.1630]
PS> Test-Path "$env:TEMP\aside-junc-probe\aside.exe"
True
PS> cmd /c rmdir "$env:TEMP\aside-junc-probe"   # 정리 완료
```

정상 junction은 print name에 `\??\` 접두사가 없고 통과된다. Aside 설치관리자가 만든
junction만 NT 네임스페이스 형태로 기록돼 탐색이 실패한다.

## 데드라인 프리미티브 실측

```powershell
$sw=[Diagnostics.Stopwatch]::StartNew()
$p=Start-Process powershell -ArgumentList "-NoProfile","-Command","Start-Sleep 30" -PassThru -WindowStyle Hidden
if(-not $p.WaitForExit(2000)){ $p.Kill($true); $killed=$true }
$sw.Stop(); "elapsed=$($sw.Elapsed.TotalSeconds) killed=$killed"
```

```
elapsed=2.0990948 killed=True
```
