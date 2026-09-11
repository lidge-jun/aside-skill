# 030 - 두 계획의 합류점

> **개정 (2026-09-11, `002_decisions-dual-shell.md`).** 사용자 요구가 "PowerShell 도 호환하되
> bash 를 1급으로" 로 바뀌어 분리 축이 OS×셸 2축이 됐다. 아래 표의 "전략" 칸이 그에 맞게 갱신됐다.

## 두 계획의 관계

서로 독립이다. 저장소가 다르고 파일이 겹치지 않는다. 동시에 진행해도 된다.

| | A. aside-jun 스킬 | B. aside-memory-sync |
|---|---|---|
| 저장소 | `aside-skill` | `aside-memory-sync` |
| 성격 | 문서 - 에이전트가 읽는 지침 | 코드 - bash + python + 스케줄러 |
| 전략 | 호스트 레이어를 **OS 파일**로 추출하고, 각 OS 파일 안에 bash/PowerShell 을 둘 다 1급으로 수록 | `.sh` 단일 구현 유지 + 얇은 PowerShell **진입점**을 1급으로 추가 |
| 크기 | 수정 10개 + 신규 2개(host-macos/host-windows), SKILL.md 499 → 약 468줄 | 수정 10개 + 신규 7개(`.gitattributes` + `.ps1` 6개) |
| 위험 | 조용히 틀린 지침이 그대로 굳는 것 | 줄바꿈 오염으로 메모리 파일이 깨지는 것 |

## 작업 순서 (work-phase)

| id | 내용 | 선행 |
|---|---|---|
| wp1 | 이 문서 묶음의 개정 (문서 전용) | - |
| wp2 | aside-jun 스킬 구현 (010) | wp1 |
| wp3 | aside-memory-sync 구현 (020) | wp1 |
| wp4 | 검증 후 양쪽 push + 상위 저장소 포인터 갱신 | wp2, wp3 |

wp2 와 wp3 는 저장소가 다르고 파일이 겹치지 않아 순서를 바꿔도 된다.

선후 관계가 하나 있다. B의 WP1(줄바꿈)은 B 안에서 반드시 선행이다.
A는 어디서 시작해도 된다.

## 공통 근거

두 계획 모두 아래 실측 위에 서 있다. 재확인 없이 인용해도 되는 값들이다.

- Aside CLI는 양 플랫폼 모두 `1.26.906.1630`, GUI `1.0.910.1`, 데몬 `1.26.910.1749`.
- 계정 루트 구조는 동일하다. Windows는 `C:\Users\super\.aside\u\0\`.
- 파일 도구 권한 거부 문구가 양 플랫폼 동일하고 둘 다 exit 0으로 fail-fast 한다.
- Windows에는 `perl`/`shlock`/`flock`/`crontab`/`launchctl` 이 없고, PATH의 `python3` 은 Store 스텁이다.
- Windows에 Git Bash 5.3.15, git 2.55.0, pwsh 7.6.6, schtasks가 있다.

## 착수 전 확인할 것

1. **`aside update` 를 돌릴지 결정한다.** 이 기계는 1.26.906.1630, 공개 최신은 1.26.908.1846이다.
   Windows CLI 관련 공식 수정이 1.26.907에 들어 있다. 다만 갱신하면 이번 실측의 기준선이 이동한다.
   문서를 먼저 쓰고 그다음 갱신 후 재검증하는 순서를 권한다.
2. **guard의 `bash` 교착을 Aside 쪽에 신고할지 결정한다.** 001 §2는 제품 결함으로 보인다.
   문서로 우회(full-access 필수 명시)는 가능하지만 근본 해결은 아니다.
3. **junction print name 결함도 같은 성격이다.** 설치관리자가 고치면 WP0의 버전 경로 해석 분기는
   무해하게 남는다. (문서 본문에서 `fallback` 이라는 낱말은 셸 서열을 암시하므로 쓰지 않는다.)
4. 원격 제어는 양쪽 호스트가 disabled라 실측이 없다. 이번 범위에서 제외한다.

## 최종 인수 조건

A: `010_patch-plan-aside-skill.md` 인수 조건 11항.
B: `020_patch-plan-memory-sync.md` 인수 조건 8항.

공통: macOS 회귀 없음. A는 `host-macos.md` 로 기존 내용을 온전히 이관하고,
B는 `.sh` 문법과 launchd 분기를 건드리지 않는다.
