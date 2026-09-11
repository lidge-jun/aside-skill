# wp5 증거 — jun-macbookpro

## 전제가 틀렸다

목표 기술문은 이 기기를 "자격 증명 때문에 막힌 온보딩 대상" 으로 잡았다. 실제로는
**이미 함대 구성원이었다.** 막혀 있던 건 온보딩이 아니라 Windows 에서 이 기기로 가는
접근 경로였다.

```
~/.aside/u/1/memory   git, main, 126 커밋, HEAD e165c85, dirty 0
                      hub 와 ahead 0 / behind 0 = 완전 동기
                      MEMORY.md 5434 / USER.md 20895 (허브와 동일)
~/kim_wiki            243 커밋
autosync              com.aside.autosync 등록됨
/Applications/Aside.app  설치됨
```

우리가 Windows 에서 올린 내용도 이미 도착해 있었다.

```
episodic/2026-09-12.md  '0xC000027B'      1건
episodic/2026-09-10.md  '163.152.22.106'  2건
.gitignore              'Thumbs.db'       1건
```

슬롯은 `u/1` 이다. `u/0` 은 메모리 디렉터리 자체가 없고, `u/2` 는 md 5개짜리 스텁인데
**다른 계정**이다 (`deb87045-e4bd-41e3-9c36-619dd7489b32`). 함대 계정은
`a291c31e-f7a3-4f57-a143-627c85cab7e6` 이고 그게 `u/1` 이다. 슬롯 번호로 짝을 맞췄으면
다른 사람 계정의 스텁을 허브에 붙일 뻔했다.

## 접근 경로를 만든 과정

### 호스트 키

`Host key verification failed`. Windows 는 이 기기를 몰랐다.

```
Windows ssh-keyscan   SHA256:vUE+sgquUZoO4PFZ0YxMnt+A3WC+gzA/e/UEPWMdR0s
macbookpro2 known_hosts  같은 지문
macmini known_hosts      같은 지문
```

기존 함대 구성원 두 대가 같은 키를 기록하고 있다. 셋이 일치하는 걸 확인하고 등록했다.

### 키 설치 — 여기서 한 번 헛돌았다

비밀번호 인증만 열려 있어서 PTY 로 로그인해 공개키를 넣었다. 비밀번호는 argv 에 넣지
않고 `write_stdin` 으로만 보냈다.

그런데 키 인증이 계속 거부됐다. `ssh -vvv` 가 답을 줬다.

```
debug1: Server accepts key: ... ED25519 SHA256:JuNxl...
debug3: sign_and_send_pubkey: signing using ssh-ed25519 ...
debug2: we did not send a packet, disable method
```

서버가 거부한 게 아니라 **클라이언트가 서명을 못 보냈다.** 원인은 키 생성 명령이었다.
PowerShell 에서 `ssh-keygen -t ed25519 -N """" ...` 로 만들었는데 `-N` 에 빈 문자열이
들어가지 않아 키에 암호가 걸렸다. 그래서 서명 단계에서 조용히 죽었다.

`authorized_keys` 도 권한도 전부 정상이었기 때문에 서버 쪽만 뒤졌으면 못 찾았다.
`Server accepts key` 다음에 `we did not send a packet` 이 오면 그건 클라이언트 문제다.

Git Bash 에서 `ssh-keygen -t ed25519 -N '' -f ...` 로 다시 만들어 해결했다.
**PowerShell 에서 네이티브 명령에 빈 문자열 인자를 넘기지 마라.**

## 도구 클론 정렬

```
jun-macbookpro  8033c70 -> 74c7b24   repos.conf 보존 (u/1)
macbookpro2     e7b39a2 -> 74c7b24   repos.conf 보존 (u/0)
macmini         e7b39a2 -> 74c7b24   repos.conf 보존 (u/1)
Windows         74c7b24              repos.conf 신규 (u/0, wiki 는 pull)
```

jun-macbookpro 는 `8033c70` 으로 셋 중 가장 오래됐다. 세 대 모두 `repos.conf` 를 백업 후
복원하는 순서를 탔다. 갱신 후 `merge-driver-probe.py` 와 `pull-strategy-probe.sh` 를
각 기기에서 돌려 전부 통과를 확인했다.

## 손대지 않은 것

jun-macbookpro 의 위키 전략은 `manual` 그대로 뒀다. 사용자가 실제로 위키를 쓰는 기기고
이미 그렇게 돌고 있었다. `pull` 은 Windows 에만 적용했다.

이 기기의 kim_wiki `origin` 은 다른 두 맥과 다르다 — GitHub 이 아니라
`ssh://clisu-oracle/home/ubuntu/kim_wiki` 를 가리킨다. autosync 는 `clisu` 만 보므로
동작에는 영향이 없다. 건드리지 않고 기록만 남긴다.
