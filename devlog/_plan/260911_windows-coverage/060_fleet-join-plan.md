# 060 - 플릿 합류 계획 (Windows 를 허브 스포크로)

C4 데이터 조인이다. 실사용 메모리를 다루므로 되돌릴 수 없는 지점을 먼저 못 박는다.

> **자격증명 메모.** 사용자가 대화로 특정 기계의 비밀번호를 알려줬다. 이 문서에도,
> 커밋에도, 스케줄러 XML 에도, 명령줄 인자에도 적지 않는다. 그건 argv 와 셸 기록에 남는다.

## 실측된 플릿 상태

| 기계 | 메모리 | kim_wiki | 비고 |
|---|---|---|---|
| macbookpro2 | `u/0`, git, 116커밋, remote hub, clean | 있음, remote `clisu`, 243커밋 | launchd autosync 1개 |
| macmini | **`u/1`**, git, 63M | 있음, 243커밋 | 슬롯 7개 중 u/1 이 동기화 대상 |
| jun-macbookpro | 미확인 | 미확인 | BatchMode 거부. 사용자명 미확정 |
| **이 Windows** | `u/0`, **git 아님**, 스텁 5개 0.26MB | **없음** | 합류 대상 |

허브 `clisu-oracle:/home/ubuntu/git` 에 `aside-memory.git` 과 `kim_wiki.git` 둘 다 있다.
Windows 에서 `ubuntu@clisu-oracle` 은 Tailscale SSH 로 이미 붙는다.

**macmini 를 한 번 잘못 읽었다.** `u/0` 만 보고 "동기화 안 됨" 이라 적었는데,
실제 동기화 슬롯은 `u/1` 이고 repos.conf 도 정확히 거길 가리킨다. macmini 는 손댈 게 없다.

## 합류 방식 (D1)

`--allow-unrelated-histories` 를 쓰지 않는다. 로컬은 스텁이고 허브가 진짜다.
빈 저장소에서 허브로 fast-forward 하는 방식으로 간다.

1. `cp -a` 로 메모리 디렉터리 전체 백업
2. 허브와 **경로가 겹치는** 파일만 hold 로 이동
   (`MEMORY.md`, `USER.md`, `TAXONOMY.md`, `episodic/2026-09-10.md`, `episodic/2026-09-11.md`)
3. `git init -b main`, `core.autocrlf false`, `remote add hub`, `fetch`
4. `git checkout -B main hub/main`
5. `install.sh` 를 **반드시 명시 경로로** 실행. 인자 없이 돌리면 `find` 가 살아있는
   `u/0/memory` 를 유일 후보로 잡아 거기에 `git init` + 첫 커밋을 만든다. 그게 바로
   우리가 피하려는 Windows 루트다.
   **정정:** 명시 경로를 줘도 첫 커밋을 건너뛰지 않는다 (`install.sh:148-157` 에 skip 이 없다).
   체크아웃 뒤에 돌리면 워크트리가 허브와 같으므로 커밋할 변경이 없어 조용히 지나가지만,
   그건 "스킵" 이 아니라 "차이가 없어서" 다. 실행 후 `git log` 로 새 루트가 없는지 확인한다.
6. hold 의 Windows 고유 episodic 을 **후손 커밋으로 합집합**. 덮어쓰지 않는다.

gitignore 대상(`.history.jsonl`, `.moss-cache/`, `memory-index.json`, `.dream-state.json`)은
전 단계에서 그대로 남는다. `git checkout` 은 무시된 미추적 파일을 지우지 않는다.

기각: `hub-setup.sh` (내부에 unrelated 병합 + 무조건 push 가 있다),
`install.sh` 먼저 실행 (Windows 루트 커밋을 만든다),
임시 클론 후 디렉터리 교체 (Aside 가 바인딩한 경로가 잠시 사라진다).

## 되돌릴 수 없는 지점 (D5)

**허브로의 첫 `push`.** 체크아웃은 로컬 파괴이고 백업과 hold 로 복구된다.
잘못된 push 는 허브 히스토리를 다시 쓰지 않으면 못 되돌린다.

push 직전 확인할 것: `merge-base --is-ancestor hub/main HEAD`,
`git log hub/main..HEAD` 가 의도한 episodic 커밋 하나뿐,
status 에 스텁 L1 파일 없음, 드라이버 등록 형태, `core.autocrlf=false`,
백업과 hold 가 아직 존재.

## 나머지 결정 요약

- **D3 원격 형태**: Windows `~/.ssh/config` 에 `Host clisu-oracle / User ubuntu` 를 추가하고
  리모트는 별칭 형태로 쓴다. `IdentityFile` 은 넣지 않는다 (Windows 엔 그 키가 없고
  Tailscale SSH 가 인증한다). 계정명이 `super` 라 User 를 안 박으면 무인 autosync 가 깨진다.
- **D4 도구 위치**: `~/.aside/tools/aside-memory-sync` 로 GitHub 에서 클론. 맥과 같은 상대 경로.
  드라이버 경로와 스케줄러 명령줄에 이 경로가 박히므로 나중에 옮기면 둘 다 깨진다.
- **D6 슬롯 함정**: 슬롯 번호는 기계마다 다르다 (macbookpro2 u/0, macmini u/1, Windows u/0).
  `repos.conf` 에 경로로 고정하고 주석에 `userId` 를 남긴다. 슬롯 번호는 조인 키가 아니다.
- **D7 kim_wiki**: `C:/Users/super/kim_wiki` (Git Bash 의 `~/kim_wiki`), 리모트 이름은 `clisu`.
  `origin` 으로 남기면 autosync 가 건너뛴다.

## 사람이 필요한 두 지점

> **해소됨 (사용자 승인).** 1번은 "그냥 죽여도 된다, 재시작해도 됨" 으로 승인받았다.
> 2번의 사용자명은 `jun` 으로 확정됐다. 아래 내용은 근거 기록으로 남긴다.

### 1. Aside 데몬 정지 (D2)

합류는 데몬이 열고 있는 디렉터리의 추적 파일을 바꾼다. hold 창 동안 데몬이 스텁을
다시 만들면 체크아웃이 거부되거나 더러운 트리가 된다.

문제는 **안전하게 멈추는 공식 방법이 없다는 것**이다. `aside daemon stop` 같은 명령이 없고,
`Stop-Process` 가 깨끗하다는 근거도 없다. 지금 `Aside.exe`, `aside-daemon.exe`,
그리고 CLI 세션 하나가 떠 있다.

사용자가 앱에서 종료하는 것이 유일하게 근거 있는 경로다. 그 다음 게이트:
`Aside`/`aside-daemon`/`aside` 프로세스 부재 + `.moss-cache` 수정시각 정지.

### 2. jun-macbookpro 자격증명 (D8)

`super@` 와 `jun@` 둘 다 BatchMode 거부. 사용자명이 확정되지 않았다.
비밀번호를 명령줄로 넘기지 않는다 — argv 와 셸 기록에 남는다.
올바른 경로는 전용 키를 만들고 **사람이 한 번 프롬프트에 직접 입력**해서
`authorized_keys` 에 공개키를 넣는 것이다.

## 데몬과 무관해서 지금 해도 되는 것

**정정 (wp1 감사).** 이 문단은 뭉뚱그려 썼고 두 군데가 틀렸다.

- 백업은 메모리 디렉터리를 **읽는다.** "건드리지 않는다" 는 과장이고, 데몬이 떠 있으면
  `.history.jsonl` 이나 `.moss-cache` 가 찢어진 채로 복사될 수 있다. gitignore 대상이라
  허브 합류에는 무해하지만, 이 백업이 체크아웃의 롤백 원본이므로 공짜는 아니다.
- `install.sh` 는 **인자 없이 돌리면 위험하다.** 위 5번 참조.

백업은 `cp -a` 로 뜨되 Git Bash 에서 실행한다. PowerShell 의 `cp` 는 `Copy-Item` 이고
아카이브 모드가 아니다. 백업 위치는 `u/0` **밖**의 형제 경로로 둔다.

## 드라이버 증명의 올바른 단언 (wp1 감사)

`020` 에 적었던 "`TAXONOMY.md` 가 충돌 마커 없이 병합된다" 는 **틀렸다.**
`aside-memory-merge` 의 `classify` 는 L1 을 `MEMORY.md`/`USER.md` 로만 본다.
`TAXONOMY.md` 는 `other` 로 분류되고 핸들러가 없어서, 드라이버가 **정상 동작해도**
같은 줄 충돌이면 마커를 남긴다. 마커 유무로는 아무것도 증명되지 않는다.

드라이버가 실제로 돌았다는 증거는 **충돌 라벨**이다. 드라이버는
`ours (this machine)` / `theirs (other machine)` 라벨을 쓴다 (`aside-memory-merge:43-44`).
기본 병합은 `HEAD` 라벨을 쓴다. 라벨이 유일한 식별자다.

증명 절차: 도구를 먼저 클론하고, `mktemp -d` 로 만든 일회용 저장소에
`TAXONOMY.md` 를 복사한 뒤 `install.sh <일회용경로>` 로 드라이버를 등록한다.
`git check-attr merge -- TAXONOMY.md` 가 `merge: aside` 여야 하고,
같은 줄을 서로 다르게 고친 두 브랜치를 `git merge` 한 결과에 양쪽 고유 문자열과
`ours (this machine)` 라벨이 함께 있어야 한다.
