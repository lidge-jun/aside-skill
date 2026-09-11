# 함대 현황 (실측 2026-09-12)

전부 직접 ssh 로 조회한 값이다. 서브에이전트 보고는 쓰지 않았다 — 두 대 모두 인용에
갇혀 헛돌거나 수치를 지어냈다.

## 계정

네 기기 전부 같은 Aside 계정이다.

```
userId = a291c31e-f7a3-4f57-a143-627c85cab7e6
```

**슬롯 번호는 기기마다 다르다.** 번호로 짝을 맞추면 틀린다. `userId` 로 맞춘다.

| 기기 | 로그인 | 슬롯 | 메모리 | kim_wiki | 도구 클론 | autosync |
|---|---|---|---|---:|---|---|
| macbookpro2 (100.107.184.60) | `jun` | **u/0** | git, main, 클린 | 243커밋, 클린 | `74c7b24` | `com.aside.autosync` |
| macmini (100.76.170.81) | `junny` | **u/1** | git, main, 클린 | 243커밋, 클린 | `74c7b24` | `com.aside.autosync` |
| jun-macbookpro (100.82.193.126) | `jun` | **u/1** | git, main, 클린 | 243커밋 | `74c7b24` | `com.aside.autosync` |
| **이 Windows** (MINI) | `super` | **u/0** | git, main, 클린 | 243커밋 | `74c7b24` | `AsideAutosync` (작업 스케줄러) |

> 2026-09-12 갱신. 처음 이 표를 쓸 때 jun-macbookpro 는 UNKNOWN 이었는데, 접근 경로를
> 뚫고 보니 **이미 함대 구성원**이었다. 자세한 건 `140_wp5-evidence.md`.

슬롯 번호는 정말로 제각각이다.

- macmini: 슬롯 7개(u/0~u/6), 그중 **u/1 만** 저장소. u/0 은 md 5개짜리 미끼다.
- macbookpro2: 슬롯 3개, u/0 이 저장소.
- jun-macbookpro: u/0 은 memory 디렉터리 자체가 없고, u/1 이 저장소,
  **u/2 는 아예 다른 계정**(`deb87045-e4bd-41e3-9c36-619dd7489b32`)의 스텁이다.
- Windows: u/0 하나뿐.

번호로 짝을 맞췄으면 jun-macbookpro 에서 남의 계정 스텁을 허브에 붙일 뻔했다.

## 허브

```
ubuntu@clisu-oracle:/home/ubuntu/git/aside-memory.git   main = f69e724, 119 커밋
ubuntu@clisu-oracle:/home/ubuntu/git/kim_wiki.git       main = 80a3d2f, 태그 pre-merge-20260909-185933
```

호스트 키 `SHA256:J+BXcSo8Ovbz4r2R3gZZ66v9IJMysNSCxUltNUknZDA` (ED25519).
Windows 의 `known_hosts` 가 이름으로, macbookpro2 의 것이 IP 로 같은 키를 갖고 있다.
기존 함대 구성원을 신뢰 채널로 삼아 교차 확인한 셈이다. 확인 후 Windows 에 IP 항목도
추가해서 이름/IP 어느 쪽으로 붙어도 통하게 했다.

## 병합 드라이버 등록 형태가 기기마다 다르다

맥 두 대:

```
/Users/<user>/.aside/tools/aside-memory-sync/bin/aside-memory-merge %O %A %B %P
```

shebang 으로 실행되니 인터프리터가 필요 없다. Windows 는 그게 안 되므로:

```
"C:/Users/super/.aside/runtime/bin/python3.cmd" "C:/.../bin/aside-memory-merge" %O %A %B %P
```

같은 저장소를 공유하지만 `merge.<name>.driver` 는 `.git/config` 에 있어서 기기 로컬이다.
형태가 달라도 문제되지 않는다.

## kim_wiki 리모트 이름

두 맥 모두 `clisu` (허브) 와 `origin` (GitHub `lidge-jun/kim_wiki`) 두 개를 갖는다.
autosync 는 `clisu` 를 본다. macmini 는 `clisu-oracle:...` 로, macbookpro2 는
`ubuntu@clisu-oracle:...` 로 적혀 있다 — 전자는 ssh config 의 `User ubuntu` 에 기댄다.
Windows 는 **`ubuntu@` 를 명시한 쪽**을 따른다. 무인 실행에서 설정 누락이 곧 실패라서다.

## 즉시 해야 할 것

맥 두 대의 도구 클론이 `e7b39a2` 로 묶여 있다. 그 버전에는 Windows 지원도, wp1 에서
고친 머리말 합집합도 없다. `fbfb08d` 로 올려야 한다 (c-6). 도구 클론은 메모리 저장소가
아니므로 이건 데몬과 무관하게 언제든 가능하다.
