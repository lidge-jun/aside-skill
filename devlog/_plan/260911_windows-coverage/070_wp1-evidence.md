# wp1 증거 — Windows 에 도구를 깔고 메모리를 백업한다

범위: 허브에 붙기 전, 오프라인에서 끝낼 수 있는 것만. 리모트 없음, 풀 없음.

## 1. 도구 배치

```
~/.aside/tools/aside-memory-sync   HEAD 57cc7df
u/0/memory 가 git 저장소인가        False   (아직 합류 전, 의도된 상태)
```

## 2. 백업 (c-1)

```
BACKUP  C:\Users\super\.aside\memory-backup-u0-20260912-002905   files=19 bytes=274007
LIVE    C:\Users\super\.aside\u\0\memory                        files=19 bytes=274007
```

`u/0` **밖**의 형제 경로다. 파일 수와 총 바이트가 양쪽 같고, L1 두 파일은 바이트 단위로
동일하다. 백업은 Git Bash 의 `cp -a` 로 떴다 — PowerShell 의 `cp` 는 `Copy-Item` 이라
아카이브 모드가 아니다.

## 3. 드라이버 등록 형태 (c-3)

일회용 저장소에 `install.sh` 를 명시 경로로 돌린 결과, `merge.aside.driver` 가 이렇게 잡혔다.

```
"C:/Users/super/.aside/runtime/bin/python3.cmd" \
"C:/Users/super/.aside/tools/aside-memory-sync/bin/aside-memory-merge" %O %A %B %P
```

인용 + 슬래시 + Aside 런타임 파이썬. Store 스텁(`WindowsApps\python.exe`, 0바이트) 이 아니다.
`core.autocrlf=false`, `git check-attr merge -- TAXONOMY.md` → `merge: aside`.
실제 병합 결과에 `ours (this machine)` / `theirs (other machine)` 라벨이 나왔고
`<<<<<<< HEAD` 는 없었다 — 드라이버가 확실히 실행됐다는 뜻이다.

> **c-3 문구 정정.** "`TAXONOMY.md` 가 충돌 마커 없이 병합된다" 는 성립하지 않는 기준이다.
> `classify()` 는 L1 을 `MEMORY.md`/`USER.md` 로만 보고 `TAXONOMY.md` 는 `other` 라
> 드라이버가 정상 동작해도 마커를 남긴다. 증거는 마커 유무가 아니라 **라벨**이다.
> 자세한 근거는 `060_fleet-join-plan.md` 의 같은 항목.

## 4. 줄바꿈 — 이전 측정은 허수였다

감사 중에 "라이브 `TAXONOMY.md` 에 CRLF 154줄", "순수 LF 입력인데 드라이버 출력에 CRLF 7줄"
이라는 수치가 나왔다. **둘 다 틀렸다.** JS → PowerShell → bash 3중 인용 스택을 통과한
`grep -c $'\r'` 이 망가진 결과였다.

바이트로 다시 셌다 (`measure-crlf.py`, 셸 인용 없이 파이썬이 직접 읽는다).

```
~/.aside/u/0/memory/MEMORY.md     bytes=74     CRLF=0  bareLF=3
~/.aside/u/0/memory/USER.md       bytes=67     CRLF=0  bareLF=3
~/.aside/u/0/memory/TAXONOMY.md   bytes=5521   CRLF=0  bareLF=154
드라이버 출력 (순수 LF 3-way)      bytes=41     CRLF=0  bareLF=5
```

Windows 의 Aside 는 LF 로 쓴다. LF 허브에 붙어도 줄바꿈 때문에 함대가 흔들릴 일은 없다.
"154 CRLF" 는 실제로는 "154 LF" 였다.

## 5. 드라이버 실결함 — 머리말이 사라진다

위 프로브를 돌리다 드라이버가 상대편 내용을 조용히 버리는 걸 발견했다.

`split_blocks` 는 H2 이상만 제목으로 본다 (`HEADING_RE = ^#{2,6}\s+\S`). H1 과 그 아래
도입부는 전부 **머리말**로 빠진다. 그런데 `merge_l1` / `merge_episodic` / `merge_semantic`
이 머리말을 `pre_o if pre_o.strip() else pre_t` 로 골랐다 — 이쪽 게 비어있지 않으면
저쪽 머리말은 통째로 버린다.

지금 상황에 정확히 걸린다. 맥의 `MEMORY.md` 머리말에는
`> Reconstructed 2026-09-09 after this file was found empty...` 인용문이 있고,
Windows 는 스텁이다. 스텁 쪽이 `ours` 가 되는 순간 그 줄이 사라진다.

수정 전 드라이버로 확인한 컨트롤 결과:

```
FAIL  1c 저쪽 줄이 남는다  -- '# Memory\n\n- alpha\n- bravo\n- windows-only\n'
FAIL  2b 상대 기기 머리말이 살아남는다  -- (Reconstructed 줄 없음)
```

`union_preamble()` 을 넣어 머리말도 줄 단위 합집합으로 바꿨다. 세 핸들러 모두 적용.
수정 후 `tests/merge-driver-probe.py` 10개 항목 전부 통과.

조인 자체는 영향받지 않는다 — D1 은 겹치는 파일을 hold 로 빼고 허브를 그대로 체크아웃하므로
드라이버가 이 충돌을 볼 일이 없다. 하지만 합류 **이후** 첫 양방향 동기화에서 터졌을
결함이라, 붙기 전에 고치는 게 맞다.

## 6. 남은 것

`u/0/memory` 는 아직 git 이 아니다. 리모트도 없다. wp1 은 여기서 멈추는 게 설계다.
실제 합류는 wp2 에서 데몬을 내리고 진행한다.
