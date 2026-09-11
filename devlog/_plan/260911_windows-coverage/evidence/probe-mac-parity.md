# macOS 원격 실측 원문 (ssh macbookpro2)

측정일 2026-09-11. 읽기 전용. `aside update` 및 설정 변경 없음.

```
Darwin gimbyeongjun-ui-MacBookPro-2.local 27.0.0 ... RELEASE_ARM64_T6050 arm64
ProductName:    macOS
ProductVersion: 27.0
BuildVersion:   26A5378n
```

## 버전과 PATH

```
$ aside --version
1.26.906.1630

$ which -a aside
/Users/jun/.local/bin/aside

$ ls -l "$(which aside)"
lrwxr-xr-x@ 1 jun staff 56 Sep 9 14:25 /Users/jun/.local/bin/aside
  -> /Users/jun/.aside/cli/Aside CLI.app/Contents/MacOS/aside

$ file "$(which aside)"
Mach-O 64-bit executable arm64
```

CLI app plist: `CFBundleShortVersionString=1.26.906`, `CFBundleVersion=1.26.906.1630`.
GUI `/Applications/Aside.app` → `1.0.910.1`.
데몬 `.../AsideDaemon/mac-arm64/Aside Daemon.app/Contents/MacOS/aside-daemon` → plist `1.26.910.1749`,
live pid 85153.

`~/.aside/cli` 에는 `Aside CLI.app` 과 `update-check.json` 만 있다. **`bin/` 이 없다.**
PATH 진입은 `/usr/local/bin` 이 아니라 로그인 셸이 `~/.local/bin` 을 선두에 넣는 방식이다.

```
~/.zshrc:61    export PATH="$HOME/.local/bin:$PATH"
~/.zprofile:26 export PATH="$HOME/.local/bin:$PATH"
~/.profile:11  export PATH="/Users/jun/.local/bin:$PATH"
```

비로그인 SSH bash는 `aside` 를 해석하지 못한다.

## settings.json 권한 블록

```json
"permission": {
  "rules": { "allow": [], "approved": [], "deny": [], "ask": [], "default": "allow" },
  "files": { "readableRoots": [], "writableRoots": [], "outsideRead": "ask", "outsideWrite": "ask" },
  "sandbox": { "enabled": false }
}
```

`passwords/settings.json` → `biometricUnlockEnabled: false`, `agentAccessPolicy: "always"`.

## 빌트인 스킬

```
1password, apple-passwords, aside, bitwarden, captcha-solver, channel, chrome,
dashlane, docx, draft-preview, google-accounts, google-docs, google-gmail,
google-search, google-sheets, image-search, imagegen, imessage, kakaotalk,
lastpass, notification-activation, notion, onboarding, password-manager, pdf,
pptx, proton-pass, site-specific, skill-creator, slack, visual-browse,
x-twitter, xlsx, youtube
```

Windows에 없는 것: `apple-passwords`, `imessage`, `site-specific`. 반대 방향은 없음.

## 권한 프로브 (데드라인 `perl -e 'alarm shift; exec @ARGV' 180`)

**5a. guard, `read_file /etc/hosts`** - 4.917s, exit 0

```
created new session: h5wxM0hzZqAyCC7i
read_file(limit: 1, path: '/etc/hosts')
 > Permission denied: read '/etc/hosts' is blocked by policy
```

**5b. full-access, 같은 읽기** - 8.806s, exit 0. 첫 줄 `##` 반환. 성공.

**5c. 도구 카탈로그** - 3.180s, exit 0

```
repl, write_todos, read_file, bash, webfetch, websearch, get_time, write_file,
edit_file, history_search, memory_search, subagent, subagent_wait,
routine_update, notification

Shell tool: bash
```

Windows와 달리 `multi_tool_use.parallel` 이 없다. `ask_user_question` 은 양쪽 다 없다.

**5d. 셸 정체** - 4.411s, exit 0

```
bash(command: 'echo SHELLPROBE; uname -s', title: 'Running shell probe')
 > SHELLPROBE
Darwin
```

macOS의 `bash` 도구는 진짜 bash다. Windows에서는 같은 이름이 PowerShell을 돌렸다.

## 기본 시스템 도구

```
$ which perl timeout gtimeout flock shlock
/usr/bin/perl
/usr/bin/shlock
WHICH_EXIT=1

$ perl -v
This is perl 5, version 34, subversion 1 (v5.34.1) built for darwin-thread-multi-2level
```

기본 시스템에는 `timeout`/`gtimeout`/`flock` 이 없다. 다만 이 사용자는 Homebrew coreutils가
설치돼 있어 로그인 zsh PATH에서는 `timeout`/`gtimeout` 이 해석된다. `flock` 은 brew에도 없다.

```
/opt/homebrew/bin/timeout  -> ../Cellar/coreutils/9.7/bin/timeout
/opt/homebrew/bin/gtimeout -> ../Cellar/coreutils/9.7/bin/gtimeout
flock not found
```

데드라인 종료코드:

```
10116 Alarm clock: 14   perl -e 'alarm shift; exec @ARGV' 2 sleep 30
ALARM_STATUS=142
```

스킬이 주장하는 142 확인.

## 원격 제어

```
$ aside host list
* local                                        (this machine)
  remote:c7aa3cd2-9b9a-412f-8158-6543e2335aa3  MINI   disabled
```

양쪽 기계가 서로를 같은 id로 보고 있고 둘 다 disabled다. 원격 제어 계약은 실측 불가.

## 측정 안 한 것

- `sandbox.enabled` 가 false일 때 macOS `bash` 가 파일 정책을 우회하는지 재측정하지 않았다.
- `multi_tool_use.parallel` 이 실제로 없는 것인지 에이전트가 목록에서 뺀 것인지 구분 못 함.
- `aside-daemon --version` 은 아무것도 출력하지 않는다.
