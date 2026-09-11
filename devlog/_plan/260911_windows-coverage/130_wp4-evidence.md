# wp4 증거 — Windows 에 kim_wiki

```
경로       C:/Users/super/kim_wiki      (맥은 ~/kim_wiki, 함대 위치 일치)
커밋       243                          (맥 두 대와 동일)
HEAD       80a3d2f                      (맥 두 대와 동일)
브랜치     main,  dirty 0
리모트     clisu  = ubuntu@clisu-oracle:/home/ubuntu/git/kim_wiki.git
           origin = https://github.com/lidge-jun/kim_wiki.git
크기       284.5 MB
autocrlf   저장소 로컬에 false 고정
```

## 줄바꿈 — 클론 한 줄에 달려 있었다

kim_wiki 에는 `.gitattributes` 가 없다. Git for Windows 는 시스템 설정에
`core.autocrlf=true` 를 깔아두므로 아무 생각 없이 클론했으면 워킹트리 전체가 CRLF 가
되고, 맥 두 대(LF)와 매 파일이 다르게 잡혔을 것이다.

`git -c core.autocrlf=false clone` 으로 받고 바이트로 확인했다.

```
                Windows(ReadAllBytes)   macbookpro2(wc -c)
README.md       1663                    1663
index.md        2575                    2575
AGENTS.md       3896                    3896
CRLF 개수       0
```

그 다음 저장소 로컬 설정에도 `false` 를 박았다. 앞으로 생길 파일에 시스템 기본값이
끼어들지 않게 하려는 것이다.

## 전략은 `pull` 이다 (c-7)

```
memory|~/.aside/u/0/memory|hub|driver
wiki|~/kim_wiki|clisu|pull
```

맥 두 대는 `manual` 그대로다. 이유와 증명은 `120_wp4-kim-wiki.md` 에 있다.
짧게: `manual` 은 이름과 달리 push 를 막지 않고, 사용자는 kim_wiki 를 승인 없이
커밋/푸시하지 말라고 해뒀다. 그래서 도구에 `pull` 전략을 새로 넣고 일회용 저장소에서
7개 항목으로 증명했다 (`manual` 컨트롤 포함).

## 실행 확인

```
autosync            memory: 변경 없음 / wiki: 변경 없음   exit 0
autosync --status   memory e165c85  보낼 0 받을 0 미커밋 0
                    wiki   80a3d2f  보낼 0 받을 0 미커밋 0
```

메모리 쪽 HEAD 가 `99fe2ac` 에서 `e165c85` 로 올라가 있다. 등록해둔 15분 주기 작업이
실제로 돌아서 데몬이 쓴 오늘 기록을 가져간 것이다. 스케줄이 살아 있다는 증거이기도 하다.

## 푸시하지 않았다

kim_wiki 는 받기만 했다. 커밋도 푸시도 없다.
