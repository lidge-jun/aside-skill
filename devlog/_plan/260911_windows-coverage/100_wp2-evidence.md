# wp2 증거 — Windows 가 허브에 붙었다

푸시는 하지 않았다. 로컬 합류까지다.

## 게이트

```
Aside 프로세스 13개 -> taskkill /T /F -> 0개
.moss-cache 최신 LastWriteTime  t1 == t2 (6초 간격)  -> 정지 확인
라이브 디렉터리 19파일 274007바이트 (wp1 백업과 동일, 그 사이 변화 없음)
```

정지 상태에서 백업을 하나 더 떴다. 둘 다 남아 있다.

```
~/.aside/memory-backup-u0-20260912-002905          (데몬 가동 중)
~/.aside/memory-backup-u0-stopped-20260912-005914  (데몬 정지 후)
~/.aside/memory-hold-20260912-005914               (충돌 5개 + install 이 남긴 .bak 2개)
```

## 결과

```
status          : 0 줄
hub/main..HEAD  : 커밋 2개 (계획대로)
is-ancestor(hub/main, HEAD) : 0
core.autocrlf   : false
tracked         : 121, commits 122
MEMORY.md / USER.md / TAXONOMY.md : 허브와 동일
추적되지도 무시되지도 않는 파일 : 없음
```

커밋 둘:

```
566d84e windows 합류: 공용 gitignore 에 Windows 부산물, gitattributes 에 명시적 LF
cba8137 windows 합류: 이 기기에만 있던 episodic 기록을 허브에 합집합
```

episodic 합집합 실측:

```
2026-09-10  hub=146901 + win=2212 -> 149095  CRLF=0  마커 없음
2026-09-11  hub=111647 + win=2751 -> 114391  CRLF=0  마커 없음
양쪽 고유 문자열 전부 생존
```

## 드라이버 등록 (c-3)

```
merge.aside.driver =
  "C:/Users/super/.aside/runtime/bin/python3.cmd"
  "C:/Users/super/.aside/tools/aside-memory-sync/bin/aside-memory-merge" %O %A %B %P

git check-attr merge -- TAXONOMY.md            -> merge: aside
git check-attr merge -- episodic/2026-09-12.md -> merge: aside
```

**c-3 의 뒷부분은 성립하지 않는 기준이라 그대로 만족시킬 수 없다.** "실제
`TAXONOMY.md` 병합이 충돌 마커 없이 해결된다" 는 드라이버가 정상일 때도 거짓이다.
`classify()` 가 `TAXONOMY.md` 를 `other` 로 보고 핸들러를 두지 않기 때문이다.
대신 증명된 것은 이것이다.

- 등록 형태가 인용 + 슬래시 + Aside 런타임 파이썬 (Store 스텁 아님)
- `check-attr` 이 `aside` 를 돌려준다
- wp1 의 일회용 저장소 실병합에서 `ours (this machine)` / `theirs (other machine)`
  라벨이 나왔다. 기본 병합의 `HEAD` 라벨이 아니다 = 드라이버가 실제로 실행됐다
- 그리고 여기서 `episodic` 실병합이 마커 없이 끝났다. 이건 핸들러가 있는 종류라
  마커 부재가 실제로 의미를 갖는 유일한 경우다

## 계획대로 안 된 것 둘

**install 이 `.bak` 파일까지 추적했다.** `install.sh` 가 `.gitignore` 를
`.gitignore.bak.1789142372` 로 백업한 뒤 `git add -A` 로 **그 백업까지** 커밋에
넣었다. 계획은 덮어쓰기까지만 예상했고 `.bak` 이 추적된다는 건 놓쳤다.
`git reset --mixed hub/main` 으로 인덱스만 되돌리고 (워킹트리 보존),
`.bak` 둘을 hold 로 옮긴 뒤, 공용 파일 변경만 이름 있는 커밋으로 다시 남겼다.

**첫 합집합 시도에서 인자가 밀렸다.** PowerShell 변수 `$mem` 을 정의하지 않은 채
`Join-Path $mem ...` 을 써서 `$target` 이 null 이 됐고, PowerShell 이 null 인자를
빼면서 드라이버가 `base=빈파일, ours=hold판, theirs=저장소판` 으로 돌았다.
결과가 **hold 쪽에** 쓰였다. 저장소는 `git status` 가 깨끗해서 손대지 않았음이
확인됐고, hold 의 원본은 정지 후 백업에서 되살렸다 (2212 / 2751 바이트 복구).
백업을 두 벌 떠둔 게 여기서 값을 했다.

## 데몬은 아직 내려둔다

계획 8절은 검증 후 재기동이었는데, 순서를 바꿔 **푸시 뒤로 미룬다.** 지금 올리면
데몬이 추적 파일을 만지기 시작하고, 그 상태에서 첫 푸시를 하게 된다. 허브에 우리
커밋이 안착한 뒤에 올리는 쪽이 되돌리기 쉽다. wp3 에서 푸시 직후 올린다.
