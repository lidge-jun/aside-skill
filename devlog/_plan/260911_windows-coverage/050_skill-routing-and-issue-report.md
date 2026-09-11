# 050 - 트리거 겹침 해소와 이슈 보고

앞 사이클이 사용자 결정으로 남겨둔 두 건을 닫는다.

## 1. 왜 겹침이 문제인가

`aside-jun` 을 `~/.codex/skills` 에 배포했는데 공식 `aside-browser` 가
`~/.agents/skills` 에 그대로 있다. 두 설명이 같은 일을 가리킨다.

| 스킬 | 발동 조건 |
|---|---|
| `aside-browser` | 브라우저가 필요할 때, 로그인된 사이트를 다룰 때 |
| `aside-jun` | 진짜 로그인된 브라우저, 로그인 뒤의 페이지, 세션/쿠키가 필요할 때 |

`aside-jun` 의 "공개 페이지 단순 조회는 제외" 라는 단서로는 갈라지지 않는다.
로그인 케이스가 양쪽 모두에 걸린다. 그리고 본문이 서로 다른 절차를 지시하므로
**잘못 고르면 잘못된 절차를 밟는다.**

처음에는 "Windows 에서 그 스킬이 뽑히면 첫 지시부터 막힌다" 고 적었는데 **그건 과장이었다.**
감사가 짚었다. 이 호스트에는 Aside 가 이미 설치돼 있고, 스텁의 실제 첫 단계는 `aside guide` 이며
그건 정상 동작한다. `curl | bash` 는 "설치돼 있지 않을 때" 분기일 뿐이다.
(`aside guide` 안의 Settings > Developers 도 CLI 설치가 아니라 원격 제어 등록 얘기다.)

진짜 해악은 설치가 막히는 게 아니라 **절차가 갈리는 것**이다. `aside guide` 는 exec 우선으로
안내하고 `aside-jun` 은 repl 우선으로 안내한다. 어느 쪽이 뽑히느냐에 따라 같은 작업이
다른 방법으로 굴러간다. 그게 "두 스킬이 한 트리거 공간에 있으면 라우팅이 불안정하다" 의 실체다.

`aside-jun/SKILL.md` 는 이미 "this skill replaces it" 이라고 적고 있다.
그 문장대로 정리한다.

## 2. 제거는 되돌릴 수 있게 한다

대상은 정확히 하나다.

```
FOUND=C:\Users\super\.agents\skills\aside-browser
  -a---  975  ...\aside-browser\SKILL.md
```

순서를 지킨다. 백업 -> 해시 대조 -> 제거 -> 부재 확인.
백업 위치는 두 스킬 루트 **밖**이어야 한다. 안에 두면 제거한 스킬이 다시 잡힌다.

```
BACKUP_ROOT=C:\Users\super\.codex\backups\skills
INSIDE_SKILL_ROOT=0
```

백업이 유일한 복구 수단도 아니다. 감사가 확인했다: `aside skills install --target codex` 로
공식 스텁을 다시 받을 수 있다. 그러니 이 제거는 이중으로 되돌릴 수 있다.
다만 `--target general` 은 쓰지 않는다. 그건 `~/.agents/skills` 에 다시 심어서 겹침을 복원한다.

대안으로 `aside-jun` 의 description 을 좁히는 방법도 검토했으나 기각한다.
`aside-browser` 쪽이 "브라우저가 필요할 때 / 로그인된 사이트" 로 계속 발동하므로
aside-jun 을 아무리 좁혀도 겹침이 남는다. 공식 스텁을 직접 고치는 것도 무의미하다.
`aside skills install` 이 덮어쓴다.

## 3. 이슈 보고

`lidge-jun/aside-skill` 이슈 1, 2 는 둘 다 열려 있고 `mac-arm64` 로만 신고돼 있다.
이번 세션이 Windows `1.26.906.1630` 에서 둘 다 재현했으므로 플랫폼 무관임을 덧붙인다.

이슈 2 에는 **정정**이 하나 들어간다. 신고서는 `page.screenshot({ path })` 도 ENOENT 로
죽는다고 적었는데 그 호출은 성공하고 부모를 만든다. `page.pdf({ path })` 도 같다.
깨지는 것은 자기 부모를 안 만드는 호출이다. `download.saveAs` 는 측정하지 않았으므로
예외로 적지 않는다.

## 하지 않는 것

- 이슈를 닫거나 라벨을 바꾸는 것. 보고만 한다.
- `aside-browser` 외의 스킬을 건드리는 것.
- 백업 없이 지우는 것.

## 실행 기록 - 무엇을 어디로 옮겼나

삭제하지 않고 **이동**했다. 복사 후 삭제보다 안전하고 되돌리기도 한 줄이다.
(`Remove-Item -Recurse -Force` 는 이 환경 정책에서 거부되기도 한다. 우회하지 않고
애초에 더 안전한 연산을 골랐다.)

```
SRC  = C:\Users\super\.agents\skills\aside-browser
DEST = C:\Users\super\.codex\backups\skills\20260911-234718-aside-browser
HASH_BEFORE = DC9166286989DE01F4D6087D4A21DFD91C5E6E0089B39589B555601754ABD3C6
HASH_AFTER  = DC9166286989DE01F4D6087D4A21DFD91C5E6E0089B39589B555601754ABD3C6
HASH_MATCH  = True
SOURCE_GONE = True
ROOT ...\.codex\skills  aside-browser_count=0
ROOT ...\.agents\skills aside-browser_count=0
ASIDE_JUN_INTACT = True
BACKUP_FILE = ...\20260911-234718-aside-browser\SKILL.md  bytes=975
```

### 되돌리는 법

둘 중 아무거나 쓰면 된다.

```powershell
# 1) 옮겨둔 것을 그대로 되돌린다
Move-Item -LiteralPath "$env:USERPROFILE\.codex\backups\skills\20260911-234718-aside-browser" `
          -Destination "$env:USERPROFILE\.agents\skills\aside-browser"
```

```powershell
# 2) 공식 스텁을 다시 받는다. --target general 은 쓰지 않는다 (겹침이 되살아난다)
aside skills install --target codex
```
