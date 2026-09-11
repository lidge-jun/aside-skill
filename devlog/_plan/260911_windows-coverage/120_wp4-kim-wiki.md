# wp4 — Windows 에 kim_wiki 를 붙인다

메모리와 달리 이쪽은 충돌 위험이 거의 없다. Windows 에 kim_wiki 가 **아예 없었기** 때문에
합칠 것이 없다. 새로 받아서 함대와 같은 모양으로 맞추기만 하면 된다.

## 함대가 쓰는 모양

```
경로     ~/kim_wiki            (맥 둘 다 홈 바로 아래)
리모트   clisu   = ubuntu@clisu-oracle:/home/ubuntu/git/kim_wiki.git
         origin  = https://github.com/lidge-jun/kim_wiki.git
브랜치   main, 243 커밋, HEAD 80a3d2f
전략     repos.conf 에서 manual  (충돌 시 되돌리고 사람을 부른다)
```

`origin` 은 GitHub 백업이다. autosync 는 `clisu` 를 하드코딩하지 않는다 —
`repos.conf` 네 필드 중 세 번째에 적힌 이름을 그대로 쓰고, 그 이름의 리모트가 없으면
`SKIP` 한다 (`autosync.sh:83`). 그래서 필요한 건 "이름이 `clisu` 일 것" 이 아니라
"`repos.conf` 와 실제 리모트 이름이 같을 것" 이다. 함대와 맞추려고 `clisu` 를 쓴다.

## `manual` 이 아니라 `pull` 이다 — 감사에서 뒤집힌 결정

처음에는 맥과 똑같이 `manual` 로 쓰려 했다. 감사가 이걸 뒤집었고, 확인해보니 맞았다.

**`manual` 은 push 를 막지 않는다.** `repos.conf` 의 네 번째 필드는 *충돌이 났을 때*
무엇을 할지만 정한다. 평상시 흐름은 전략과 무관하다.

- 워킹트리가 더러우면 `git add -A` + `--no-verify` 로 자동 커밋 (`autosync.sh:97-104`)
- `ahead > 0` 이면 무조건 push (`autosync.sh:146-156`)
- `driver` 와 `manual` 의 충돌 분기는 메시지만 다르고 둘 다 `git merge --abort` 다
  (`autosync.sh:132-142`)

사용자는 kim_wiki 를 명시 승인 없이 커밋/푸시하지 말라고 해뒀다. `manual` 로 등록하면
Windows 의 kim_wiki 폴더에 뭐가 떨어지는 순간 15분 안에 커밋돼서 함대로 나간다.
이름만 보고 넘어갔으면 그대로 위반했을 것이다.

그래서 도구에 `pull` 전략을 새로 넣었다.

| 전략 | 로컬 변경 | 충돌 | push |
|---|---|---|---|
| `driver` | 자동 커밋 | 드라이버가 처리, 남으면 abort | 한다 |
| `manual` | 자동 커밋 | abort 하고 사람을 부른다 | 한다 |
| `pull` | **건드리지 않는다** | fast-forward 만 받고 아니면 보류 | **안 한다** |

맥 두 대는 `manual` 그대로 둔다. 그쪽이 사용자가 실제로 위키를 쓰는 기기고, 이미 그렇게
돌고 있었다. Windows 만 `pull` 이다. 읽기는 되고, 상류는 못 바꾼다.

### 증명

`tests/pull-strategy-probe.sh` 가 임시 bare 저장소로 확인한다. 라이브 위키로 시험하면
실패할 때 함대가 오염되므로 일회용에서만 돌린다.

```
PASS  pull: 상류가 그대로다
PASS  pull: 로컬 커밋을 만들지 않았다
PASS  pull: 로컬 변경을 그대로 남겨뒀다
PASS  manual 컨트롤: 상류가 움직였다 (판별력 확인)
PASS  manual 컨트롤: 로컬 커밋을 만들었다
PASS  pull: 상류 변경은 받아온다
PASS  pull: 받아온 내용이 실제로 들어왔다
```

`manual` 컨트롤이 핵심이다. 같은 시나리오에서 상류가 **움직여야** 이 테스트가 두 전략을
구분한다는 뜻이다. 그게 없으면 전부 PASS 여도 아무것도 증명하지 못한다.

## 줄바꿈

kim_wiki 에는 `.gitattributes` 가 없다. Git for Windows 는 시스템 설정으로
`core.autocrlf=true` 를 깔아두기 때문에, 아무 생각 없이 클론하면 워킹트리가 CRLF 가 된다.
맥 두 대는 LF 다. 섞이면 `manual` 전략에서 파일 전체가 변경으로 잡혀 동기화가 매번 멈춘다.

그래서 `git -c core.autocrlf=false clone` 으로 받고, 저장소 로컬 설정에도 `false` 를
박는다. 시스템 기본값이 나중에 새 파일에 끼어들지 않게 하려는 것이다.

확인은 바이트로 한다. 맥의 `wc -c` 와 Windows 의 `ReadAllBytes().Length` 가 같아야 한다.

## 순서

1. `git -c core.autocrlf=false clone --origin clisu ubuntu@clisu-oracle:/home/ubuntu/git/kim_wiki.git C:/Users/super/kim_wiki`
2. 저장소 로컬에 `core.autocrlf=false` 고정
3. `origin` 으로 GitHub 리모트 추가 (함대 일치)
4. `repos.conf` 에 `wiki|~/kim_wiki|clisu|pull` 추가
5. 검증: 243 커밋, HEAD 가 맥과 동일, 대표 파일 바이트가 맥과 동일, `autosync --status` 에
   두 저장소가 다 뜨고 보낼/받을 0

**푸시하지 않는다.** 사용자가 kim_wiki 는 명시 승인 없이 커밋/푸시하지 말라고 해뒀다.
받기만 한다.
