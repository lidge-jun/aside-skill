# macOS 호스트 레이어

Aside 제품 계약은 Windows와 같다. 이 파일이 적는 것은 Darwin이 소유한 프리미티브다.
CLI 위치, perl alarm, shlock, LaunchAgent, Seatbelt.
bash와 PowerShell은 둘 다 1급이다. 예시를 맞추려고 셸을 번역하지 않는다.
실측 Mac에는 pwsh가 없다. PowerShell 칸은 문서상 계약이며 프리미티브는 bash 칸과 같다.
근거는 SKILL.md에서 이관한 실측과
`devlog/_plan/260911_windows-coverage/001_parity-ledger-windows.md`,
`evidence/probe-mac-parity.md` 다.

## CLI 해석

`~/.aside/cli` 에는 `Aside CLI.app` 과 `update-check.json` 만 있다. `bin/` 은 없다.
PATH 진입은 `~/.local/bin/aside` 심볼릭이고, 대상은 CLI 앱 번들
`~/.aside/cli/Aside CLI.app/Contents/MacOS/aside` 다.
로그인 셸이 zshrc/zprofile에서 `$HOME/.local/bin` 을 PATH 선두에 넣는다.
비로그인 SSH bash는 `aside` 를 이름으로 해석하지 못한다.

```
$ which -a aside
/Users/jun/.local/bin/aside

$ ls -l "$(which aside)"
lrwxr-xr-x@ 1 jun staff 56 Sep 9 14:25 /Users/jun/.local/bin/aside
  -> /Users/jun/.aside/cli/Aside CLI.app/Contents/MacOS/aside

~/.zshrc:61    export PATH="$HOME/.local/bin:$PATH"
~/.zprofile:26 export PATH="$HOME/.local/bin:$PATH"
```

`aside version` (대시 없음)은 버전 명령이 아니라 에이전트 세션을 연다.
`--version` 만 쓴다. 버전 문자열을 문서에 고정하지 않는다.

```bash
# macOS / bash
ASIDE="${ASIDE:-$HOME/.local/bin/aside}"
"$ASIDE" --version
```

```powershell
# macOS / PowerShell
$aside = "$HOME/.local/bin/aside"
& $aside --version
```

## 데드라인

센티넬은 양 OS 공통으로 **142** 다. 발화하면 142, 아니면 자식 종료코드를 그대로 통과시킨다.
프리미티브는 `/usr/bin/perl -e 'alarm shift; exec @ARGV'` 다.
`exec` 가 셸을 `aside` 로 같은 프로세스에서 바꾸므로 alarm 타이머가 CLI 자체에 남는다.

맨 `timeout` 철자는 쓰지 않는다. **기본 시스템에는 `timeout` 이 없다.**
실측 기계는 Homebrew coreutils가 로그인 PATH에 있어 `timeout`/`gtimeout` 이 해석된다.
`flock` 은 brew를 켜도 없다.
`perl` 을 고르는 이유는 어디서나 있고 종료코드가 142로 구분되기 때문이다.
로그인 PATH에만 있는 철자를 쓰면, 없는 셸에서 `command not found` 가 127로 끝나
`aside` 가 한 번도 뜨지 않는다.

프롬프트 앞에 `--` 를 넣는다.

```bash
# macOS / bash
/usr/bin/perl -e 'alarm shift; exec @ARGV' 300 "$ASIDE" exec --permission full-access -- "$PROMPT"
```

| Property | Measured |
|---|---|
| Fires at the deadline | `alarm 2` on `sleep 30` returned at 2.009s |
| Reports the kill distinctly | exit `142`, which is `128 + SIGALRM` |
| Passes a normal exit through | child `exit 7` surfaced as `7` |

원격 실측 재확인 (`evidence/probe-mac-parity.md`):

```
10116 Alarm clock: 14   perl -e 'alarm shift; exec @ARGV' 2 sleep 30
ALARM_STATUS=142
```

PowerShell 칸은 `Start-Process -PassThru` + `WaitForExit(ms)` 다.
발화 시 `$p.Kill()` 후 `exit 142`. `taskkill` 은 Windows 전용이라 여기서 쓰지 않는다.
`Start-Process` 는 `$LASTEXITCODE` 를 건드리지 않는다. `.ExitCode` 를 읽는다.
리다이렉트하지 않으면 `.StandardOutput` 은 빈 문자열이다.
`-ArgumentList` 는 문자열 배열이다. 조각을 세미콜론으로 조인하지 않는다.

```powershell
# macOS / PowerShell
$out = Join-Path ([System.IO.Path]::GetTempPath()) 'aside-out.txt'
$err = Join-Path ([System.IO.Path]::GetTempPath()) 'aside-err.txt'
$p = Start-Process -FilePath $aside -PassThru `
     -RedirectStandardOutput $out -RedirectStandardError $err `
     -ArgumentList @('exec','--permission','full-access','--',$prompt)
if (-not $p.WaitForExit(300000)) {
  $p.Kill()
  exit 142
}
exit $p.ExitCode
```

발화는 CLI만 죽인다. 이미 쓴 파일, 다운로드, 제출, 보낸 메시지는 남는다.
재시도 전에 실제 상태를 본다.

## 락

`/usr/bin/shlock` 은 기본 시스템에 있다. pid 파일을 쓰고, 살아 있는 pid는 유지하고
죽은 pid는 회수한다. `flock` 은 기본 시스템에 없고 brew를 켜도 없다.

| Case | Behaviour |
|---|---|
| Previous tick still running | Refuses the lock, so `|| exit 0` skips the tick |
| Previous tick crashed | Sees the dead pid, reclaims the stale lock, proceeds |

`trap` 은 정상 종료에서 락 파일을 지운다. pid 검사는 종료가 없을 때의 안전망이다.

```bash
# macOS / bash
LOCK=/tmp/aside-job.lock
/usr/bin/shlock -p $$ -f "$LOCK" || exit 0
trap 'rm -f "$LOCK"' EXIT
```

PowerShell 칸은 같은 `/usr/bin/shlock` 을 `&` 로 호출한다.

```powershell
# macOS / PowerShell
$lock = '/tmp/aside-job.lock'
& /usr/bin/shlock -p $PID -f $lock
if ($LASTEXITCODE -ne 0) { exit 0 }
try {
  # ... 잡 본문 ...
} finally {
  Remove-Item -LiteralPath $lock -ErrorAction SilentlyContinue
}
```

여기의 `$LASTEXITCODE` 는 `& /usr/bin/shlock` 직후다. `Start-Process` 뒤가 아니다.

## 셸 도구와 Seatbelt

`bash` 도구는 진짜 bash 다. `uname -s` → `Darwin`. 파일 도구 권한 검사를 타지 않는다.
`sandbox-exec` Seatbelt 프로파일 아래에서 돌고, 막히면 `Operation not permitted` 를 찍는다.
이 설치의 `sandbox.enabled` 는 **false** 였고, 한 프로브에서 `bash` 가 워크스페이스 파일과
`/etc/hosts` 를 읽었다. 도달 범위는 규칙이 아니라 설정에 의존한다.

```
bash: head -1 <workspace>/AGENTS.md ; head -2 /etc/hosts
  -> stderr: head: .../AGENTS.md: Operation not permitted
  -> stdout: ##
             # Host Database
  -> run continued normally, no suspend
```

## 스케줄러

잡 본문은 [scheduling.md](scheduling.md) 다.
`cron` 은 PATH가 얇고 GUI 세션 밖에서 돈다. Aside는 앱과 실제 브라우저가 필요하다.
`~/Library/LaunchAgents/` 의 사용자 LaunchAgent가 로그인 GUI 컨텍스트에서 돌므로 맞다.
`aside` 는 어느 쪽이든 절대 경로로 부른다. `/Users/<you>/.aside/cli/bin/aside` 는 없다.

각 틱은 데드라인과 락으로 감싼 완전 실행이다. 세션 id를 디스크에 저장할 이유는 적다.

```bash
# macOS / bash — cron 한 줄
0 9 * * * /usr/bin/perl -e 'alarm shift; exec @ARGV' 300 "$HOME/.local/bin/aside" exec --permission full-access -- "<prompt>" >> "$HOME/.aside/u/0/jobs/digest/run.log" 2>&1
```

LaunchAgent `ProgramArguments` 는 bash 스크립트이거나 `pwsh -File` 이다.
실측 Mac에는 pwsh가 없어 아래 칸은 문서상 계약이다. 0번 토큰은 pwsh 절대 경로다.

```xml
# macOS / bash — LaunchAgent ProgramArguments
<key>ProgramArguments</key>
<array>
  <string>/bin/bash</string>
  <string>--noprofile</string>
  <string>--norc</string>
  <string>/Users/jun/.aside/u/0/jobs/digest/run.sh</string>
</array>
```

```xml
# macOS / PowerShell — LaunchAgent ProgramArguments
<key>ProgramArguments</key>
<array>
  <string>/path/to/pwsh</string>
  <string>-NoProfile</string>
  <string>-File</string>
  <string>/Users/jun/.aside/u/0/jobs/digest/run.ps1</string>
</array>
```

LaunchAgent 액션의 인터프리터도 절대 경로다. 맨 `pwsh` 철자는 PATH에 없을 수 있다.
