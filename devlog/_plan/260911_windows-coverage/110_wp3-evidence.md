# wp3 증거 — 첫 푸시, autosync, 왕복

## 푸시 전 점검 (D5)

```
git fetch hub            -> hub/main = 6646fb7  (작업 중 맥이 한 커밋 더 올렸다)
is-ancestor(hub/main, HEAD) = 0
올릴 것 = 커밋 2개, 4파일, +127 / -67
dirty = 0,  MEMORY.md 5434 / USER.md 20895 (스텁 아님)
백업 2벌 + hold 전부 저장소 밖에 존재
```

**삭제 67줄에서 한 번 멈췄다.** 합집합인데 삭제가 나오면 안 된다. 시간순 재정렬 때문인지
실제 손실인지 diffstat 으로는 구분이 안 되므로 `verify-union.py` 를 써서 양쪽 원본의
공백 아닌 줄이 결과에 전부 있는지 셌다.

```
episodic/2026-09-10.md   hub 476줄 전부 생존, windows 16줄 전부 생존, 결과 491줄
episodic/2026-09-11.md   hub 439줄 전부 생존, windows 12줄 전부 생존, 결과 450줄
```

476+16=492 인데 491 인 이유는 양쪽 공통인 H1 한 줄이 중복 제거돼서다. 손실 아님.

## 푸시

```
6646fb7..cba8137  main -> main      (허브 122 커밋)
```

## Aside 재기동 — 에이전트는 끌 수는 있어도 켤 수는 없다

`Aside.exe` 를 에이전트 프로세스에서 띄우면 즉시 `0xC000027B` 로 죽는다.
`Start-Process` 도, stdio 리다이렉트를 떼도, `cmd /c start` 로 분리해도 마찬가지다.
Chromium 기반 앱이라 진짜 대화형 데스크톱 세션이 필요하다.

통한 방법: **`InteractiveToken` 일회용 스케줄 작업**.

```
schtasks /Create /TN AsideRelaunchOneShot /XML <Principal LogonType=InteractiveToken>
schtasks /Run    /TN AsideRelaunchOneShot      -> Aside x16 + aside-daemon x1 기동
schtasks /Delete /TN AsideRelaunchOneShot /F   -> 흔적 제거
```

데몬이 올라온 뒤에도 저장소는 깨끗했다. 데몬이 추적 파일을 건드리지 않았다.

## autosync (c-4)

```
TaskName        \AsideAutosync
Status          Ready
Task To Run     C:\Program Files\Git\bin\bash.exe --noprofile --norc
                "C:/Users/super/.aside/tools/aside-memory-sync/autosync.sh" --quiet
Start In        C:\Program Files\Git\cmd
Run As User     super
Repeat Every    15분
```

해제는 `install-autosync.ps1 --remove AsideAutosync`.
`repos.conf` 에는 메모리 한 줄만 넣었고, 슬롯을 경로로 못박고 `userId` 를 주석에 남겼다.
kim_wiki 줄은 wp4 에서 추가한다.

## 왕복 (c-5)

Windows 에서 `episodic/2026-09-12.md` 에 이번 합류 기록을 실제로 한 블록 썼다.
빈 테스트 문자열이 아니라 다음 세션이 읽을 값이 있는 내용이다 — 슬롯이 기기마다 다르다는
것, 빈 base 가 필요한 이유, LF 측정, Aside 재기동 방법, `install.sh` 의 `.bak` 함정.

```
Windows  autosync.ps1        -> f4823ed "autosync: MINI 2026-09-12 01:08 (파일 1개)"
허브     log                 -> f4823ed 최상단, 본문 grep 1
macbookpro2                  -> hub/main 에서 f4823ed 확인, 본문 grep 1
macbookpro2 autosync.sh      -> 99fe2ac 로 수렴, 보낼 0 받을 0 미커밋 0
macbookpro2 워킹트리          -> Windows 고유 내용 도착 (0xC000027B 1건, 163.152.22.106 2건)
                                공용 .gitignore 에 Thumbs.db 반영됨
Windows  autosync.ps1        -> 99fe2ac 로 수렴, 보낼 0 받을 0 미커밋 0
```

양방향이 닫혔다.

## 맥 도구 클론 갱신 (c-6) — 여기서 걸릴 뻔했다

두 맥 다 `e7b39a2` 였고 `git merge --ff-only` 가 거부했다.

```
error: Your local changes to the following files would be overwritten by merge: repos.conf
```

`repos.conf` 는 `e7b39a2` 시점에 **추적 파일**이었고 두 기기 다 자기 경로로 고쳐 쓰고
있었다. 지금은 `.gitignore` 에 들어가 있지만, 옛 버전에서 올라오는 기기는 이 지점을
반드시 통과해야 한다. 그냥 `reset --hard` 로 밀었으면 각 기기의 슬롯 설정이 날아갔다.

순서: `repos.conf` 를 저장소 **밖**으로 백업 → `git checkout -- repos.conf` →
`merge --ff-only` → 백업을 되돌려 놓기. 되돌린 뒤에는 `.gitignore` 가 잡아주므로
다시는 걸리지 않는다.

```
macbookpro2  e7b39a2 -> fbfb08d  repos.conf: memory|~/.aside/u/0/memory|hub|driver  (보존)
macmini      e7b39a2 -> fbfb08d  repos.conf: memory|~/.aside/u/1/memory|hub|driver  (보존)
양쪽 git status 비어 있음, check-ignore 가 repos.conf 를 잡는다
양쪽 merge-driver-probe.py 10/10 통과 (macOS 에서도 머리말 합집합 동작)
양쪽 autosync --status 정상
```
