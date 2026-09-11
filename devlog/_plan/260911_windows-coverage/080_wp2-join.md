# wp2 계획 — Windows 를 허브에 붙인다

`060_fleet-join-plan.md` 의 D1 을 실제 명령 순서로 내린 것이다. 그 사이에 측정한 값으로
전제 두 개가 바뀌었으니 그것부터 적는다.

## 바뀐 전제

**허브 호스트 신뢰는 이미 있다.** 목표 기술문에 적힌 `Host key verification failed` 는
지금 재현되지 않는다. `ssh -o BatchMode=yes ubuntu@clisu-oracle` 이 종료 코드 0 으로
`git ls-tree` 까지 돌려준다. wp2 t1 은 "신뢰를 만든다" 가 아니라 "신뢰를 확인하고
기록한다" 로 줄어든다.

**허브는 지금도 움직인다.** `main = f69e724`, 119 커밋, 마지막 커밋 2026-09-12 00:40 KST.
맥북 autosync 가 살아 있다. 그래서 아래 `fetch` 는 반드시 합류 **직전에** 다시 돌린다.
미리 받아둔 참조로 체크아웃하면 그 사이 맥이 올린 내용을 덮는 커밋을 만들 수 있다.

## 충돌 대상은 정확히 5개

허브 `.gitignore` 가 `.moss-cache/`, `.moss-cache-schema`, `memory-index*.json`,
`.dream-state.json`, `.history.jsonl` 을 전부 제외한다. Windows 로컬 산출물 14개는
추적 대상이 아니고 그대로 남는다. 겹치는 것은 이것뿐이다.

| 파일 | Windows | 허브 | 판단 |
|---|---:|---:|---|
| `MEMORY.md` | 74 | 5,434 | 허브 권위. Windows 는 스텁 |
| `USER.md` | 67 | 20,895 | 허브 권위. Windows 는 스텁 |
| `TAXONOMY.md` | 5,521 | 314,711 | 허브 권위 |
| `episodic/2026-09-10.md` | 2,212 | 146,901 | **합집합.** Windows 쪽이 고유 |
| `episodic/2026-09-11.md` | 2,751 | 111,647 | **합집합.** Windows 쪽이 고유 |

Windows 의 episodic 두 개는 다른 데 없는 기록이다. 09-10 은 고려대 승인 고정 IP
(`163.152.22.106/24`, 게이트웨이 `163.152.22.1`, DNS `163.152.1.1`/`163.152.11.6`) 를
실제로 적용한 경위고, 09-11 은 OpenCode/Zen 이슈 조사 결과다. 덮어쓰면 사라진다.

## 줄바꿈

허브 `.gitattributes` 는 `* text=auto eol=lf` 다. 체크아웃 시 워킹트리가 LF 로 쓰인다.
`core.autocrlf=false` 와 함께면 왕복에서 변형이 없다. wp1 에서 Windows Aside 도 LF 로
쓴다는 걸 바이트로 확인했으니 (CRLF 0) 함대 전체가 LF 하나로 맞는다.

## 순서

### 0. 데몬과 무관한 준비

- `~/.ssh/config` 에 `clisu-oracle` 항목 추가 (`HostName 100.100.245.81`, `User ubuntu`,
  `IdentityFile` 없음). 리모트 URL 에도 `ubuntu@` 를 명시해서 이중으로 건다. 설정 항목이
  없으면 무인 autosync 가 `super@` 로 붙어 실패한다.
- 배포 클론 `~/.aside/tools/aside-memory-sync` 를 `fbfb08d` 로 올린다 (wp1 드라이버 수정본).

### 1. 데몬 정지

지금 `Aside.exe` 12개 + `aside-daemon.exe` 1개가 떠 있다.
`taskkill /PID <id> /T /F` 로 내린다 — PowerShell 5.1 에 `Kill($true)` 오버로드는 없다.

게이트: 이름에 `aside` 가 들어가는 프로세스 0개, 그리고 `.moss-cache` 의
`LastWriteTime` 이 5초 간격 두 번 측정에서 동일. 둘 다 만족해야 다음으로 간다.

### 2. 정지 후 새 백업

기존 백업(`memory-backup-u0-20260912-002905`)은 데몬이 살아 있을 때 떴다. gitignore
대상이라 합류에는 무해하지만 롤백 원본으로는 `.history.jsonl` 이 찢어져 있을 수 있다.
정지 상태에서 하나 더 뜨고 **둘 다 남긴다.** Git Bash 의 `cp -a` 를 쓴다.

### 3. hold

위 5개 파일을 `~/.aside/memory-hold-<타임스탬프>/` 로 **옮긴다.** 지우지 않는다.
`Remove-Item -Recurse -Force` 는 정책상 막혀 있고, 어차피 되돌릴 수 있는 쪽이 맞다.

### 4. 저장소 만들고 허브를 받는다

```
git init -b main
git config core.autocrlf false
git remote add hub ubuntu@clisu-oracle:/home/ubuntu/git/aside-memory.git
git fetch hub          # 여기서 처음 받는다. 미리 받아둔 것 쓰지 않는다
git checkout -B main hub/main
```

`--allow-unrelated-histories` 는 쓰지 않는다. 로컬에 커밋이 하나도 없으므로 체크아웃이
곧 합류다.

### 5. 드라이버/템플릿 등록

```
install.ps1 C:/Users/super/.aside/u/0/memory
```

**슬래시로 준다.** `bin/invoke-git-bash.ps1` 은 **스크립트 경로만** `-replace '\\','/'` 로
바꾸고 (`invoke-git-bash.ps1:118` 근처) 나머지 인자는 `@forward` 로 그대로 넘긴다.
역슬래시 경로를 주면 MSYS argv 변환에 맡기는 꼴이 된다. 애초에 슬래시로 주면 그 문제가 없다.

**반드시 명시 경로.** 인자 없이 돌리면 `find` 가 살아있는 슬롯을 잡아 거기에 `git init`
과 첫 커밋을 만든다. 명시 경로를 줘도 첫 커밋 경로를 건너뛰지는 않는다 —
체크아웃 뒤라 커밋할 차이가 없어서 조용히 지나갈 뿐이다. 실행 후 `git log` 로 새 루트
커밋이 안 생겼는지 확인한다.

#### install.sh 는 공용 파일을 덮어쓴다 — 의도된 변경이지만 숨기면 안 된다

`install_template` (`install.sh:78-96`) 이 `templates/gitignore`, `templates/gitattributes`
를 저장소 루트에 복사한다. 다르면 기존 파일을 `.bak.<epoch>` 로 남기고 덮는다.
그리고 `install.sh:151,156` 이 `git add -A` + `git commit` 을 한다.

지금 템플릿은 허브 버전과 **실제로 다르다.** 해시가 다르고 내용은 이렇다.

```
.gitignore     + Thumbs.db / ehthumbs.db / desktop.ini     (Windows 부산물)
.gitattributes + *.md text eol=lf                          (명시적 LF 보장)
```

둘 다 이번 Windows 커버리지 작업에서 일부러 넣은 것이다. Windows 가 함대에 들어오는
지금이 반영될 자리가 맞다. 그래서 막지 않는다. 대신 **눈에 보이게** 처리한다.

- `install.ps1` 실행 직후 `git diff` 로 두 파일의 변경을 확인하고, 위 내용과 일치하는지 본다.
- `.gitignore.bak.*`, `.gitattributes.bak.*` 는 저장소 밖(hold 디렉터리)으로 옮긴다.
  추적되지도 무시되지도 않는 파일을 남기지 않는다.
- 이 변경은 `episodic` 합집합과 **별도 커밋**으로 남긴다. 함대 공용 파일을 바꾸는 커밋은
  이름이 있어야 한다.

따라서 7절의 "`hub/main..HEAD` 가 커밋 하나뿐" 은 **커밋 둘**로 고친다.

### 6. episodic 합집합

각 날짜에 대해 드라이버를 **직접** 부른다.

```
python3 aside-memory-merge <빈파일> <워킹트리의 허브판> <hold의 Windows판> episodic/<날짜>.md
```

base 를 **빈 파일**로 주는 게 핵심이다. base 에 허브판을 주면 `ours == base` 가 되어
표준 `git merge-file` 이 깨끗하게 성공하고 **theirs(Windows 스텁)로 통째 교체**된다.
허브 내용이 전부 날아간다. 빈 base 면 양쪽이 다 추가로 보여 충돌하고, 그래야
`merge_episodic` 의 블록 합집합 + 시간순 정렬 경로를 탄다.

검증: 결과 파일에 허브에만 있던 문자열(`LMS conversations heartbeat`)과 Windows 에만
있던 문자열(`163.152.22.106`)이 **둘 다** 있어야 하고, 크기가 허브판 이상이어야 한다.
그 다음 후손 커밋 하나로 묶는다.

**예행 완료 (2026-09-12).** 허브를 `$TEMP/aside-hub-ref` 로 통째 클론해서 바이트 정확한
원본을 놓고 돌렸다.

```
2026-09-10  hub=146901  win=2212  merged=149095  CRLF=0  충돌마커=없음
2026-09-11  hub=111647  win=2751  merged=114391  CRLF=0  충돌마커=없음
양쪽 고유 문자열 모두 생존 (LMS conversations heartbeat / 163.152.22.106 / FreeUsageLimitError)
```

그리고 반대 컨트롤도 돌렸다. base 에 허브판을 주면:

```
CONTROL base=hub : exit=0  result_bytes=2212   <- Windows 스텁만 남는다
   hub-only string survives: False              <- 허브 144KB 가 전부 사라진다
```

빈 base 는 취향이 아니라 필수다.

### 7. 검증. 푸시는 하지 않는다

- `git status` 깨끗
- `MEMORY.md`/`USER.md`/`TAXONOMY.md` 가 허브 blob 과 해시 일치
- `git config merge.aside.driver` 가 인용 + 슬래시 + Aside 런타임 파이썬 형태
- `git check-attr merge -- TAXONOMY.md` → `aside`
- `git merge-base --is-ancestor hub/main HEAD` 성공
- `git log hub/main..HEAD` 가 **커밋 둘** — 공용 gitignore/gitattributes 갱신, episodic 합집합
- 추적되지도 무시되지도 않는 파일 없음 (`git status --porcelain` 이 비어 있음)
- `core.autocrlf` = `false`

첫 푸시는 wp3 다. D5 가 말한 되돌릴 수 없는 지점이라, 합류가 로컬에서 전부 검증된 뒤에
별도 사이클로 넘긴다.

### 8. 데몬 재기동

사용자가 재시작을 승인했다. 검증이 끝나면 Aside 를 다시 띄우고, 데몬이 인덱스를 새로
만드는지 (`.moss-cache` 갱신) 확인한다.

## 롤백

어느 단계든 실패하면 두 갈래다.

- 가벼운 경우: 아직 `.git` 이 살아 있으므로 **git 으로 되돌린다.**
  `git checkout -B main <빈상태>` 같은 재주를 부리지 말고,
  `git rm -r --cached . ` 후 추적 파일을 `git clean -fd` 로 치운다.
  순서가 중요하다 — `.git` 을 먼저 옮기면 허브에서 들어온 파일 100여 개가 **추적 정보 없이**
  워킹트리에 남아 손으로 골라내야 한다. git 이 살아 있을 때 치우는 게 유일하게 안전한 순서다.
  그 다음 `.git` 을 옆으로 옮기고 hold 의 5개 파일을 제자리로 되돌린다.
- 무거운 경우: `u/0/memory` 를 통째로 옆으로 밀고 정지 후 백업에서 `cp -a` 로 복원한다.

백업 2개와 hold 는 전부 `u/0` **밖**에 둔다. 허브는 이 사이클에서 한 번도 쓰지 않으므로
다른 기기는 어떤 경우에도 영향받지 않는다.

## 안전 장치 하나 — 체크아웃은 덮어쓰지 않는다

hold 목록이 혹시 불완전해도 `git checkout -B main hub/main` 은 추적되지 않은 로컬 파일을
**말없이 덮지 않는다.** `would be overwritten by checkout` 으로 멈춘다. 그래서 체크아웃
실패는 사고가 아니라 신호다. 멈추면 그 파일을 hold 에 추가하고 다시 시도한다.

## 감사 기록 (2026-09-12)

grok 서브에이전트 한 대를 적대적 감사로 파견했다. 건진 것과 버린 것을 같이 적는다.

**건진 것 셋.** `install.ps1` 의 인자 무변환, `install.sh` 의 공용 템플릿 덮어쓰기,
롤백 절차의 모호함. 전부 위 본문에 반영했다.

**버린 것 하나.** 감사가 "빈 base 병합에서 23KB 손실" 을 [치명] 으로 올렸다. 틀렸다.
그쪽은 허브 원본을 `ssh ... | PowerShell -join` 파이프로 만들어서 이미 손상시킨 뒤,
결과를 `.Length` 로 쟀다. `.Length` 는 **문자 수**고 한국어 UTF-8 은 문자당 3바이트다.
123775자 vs 146901바이트는 손실이 아니라 단위가 다른 것이다. 클론으로 뜬 바이트 정확한
원본에 `ReadAllBytes().Length` 로 다시 재니 149095바이트로 늘었다.

정찰용으로 파견한 두 번째 grok 은 PowerShell 인용에 갇혀 자기 ssh 프로세스를 죽이고
근거 없는 수치("슬롯 3개, 커밋 47")를 추론에 적었다. 폐기하고 직접 조회했다.
**서브에이전트의 측정값은 단위와 수집 경로까지 보기 전에는 쓰지 않는다.**
