---
created: 2026-09-03
tags: [Aside-CLI, save-sessions, session-persistence, SQLite, permission-guard]
aliases: [Aside save-sessions 조사, Aside CLI 세션 저장, Aside 세션 가시성]
---

# Aside CLI `save-sessions` 라이브 프로브

`aside settings save-sessions true`는 CLI 실행을 별도 형식으로 복사해 저장하는 옵션이 아니다. 계정 설정 파일의 `cli.ephemeral` 값을 `true`에서 `false`로 뒤집는다. 그 뒤 새로 생성되는 CLI 세션은 `state.db`에서 비휘발 세션이 되고, Aside의 Chats 목록과 `aside.sessions.list()`에 나타난다. 기존 휘발 세션의 SQLite 분류를 일괄 변환하지는 않는다. 다만 설정을 켠 뒤 앱 사이드바에는 직전에 만든 휘발 기준 세션도 함께 노출되었다. API는 그 기준 세션을 계속 제외했다. 즉 디스크의 보존 분류와 앱의 현재 노출 정책은 같은 개념이 아니다. 이 결론은 2026-09-03의 CLI 1.26.902.1732와 데몬 1.26.902.1713에서 직접 측정한다. [S8-Q1][S8-Q2][S8-Q3]

이 설정은 긴 조사나 나중에 다시 열어야 하는 CLI 작업에서 중요하다. 기본값인 `false`에서는 CLI 세션이 `ephemeral=1`로 생성된다. 데몬은 종료된 휘발 세션을 15분 보존 시간 뒤 정리한다. 저장 모드의 새 세션은 `ephemeral=0`이므로 그 정리 쿼리에 들어가지 않는다. `save-sessions=true`는 단순한 사이드바 표시 옵션을 넘어 CLI 세션의 보존 분류를 바꾸는 설정이다. [S8-Q2][S8-Q5]

사용법은 단순하다. `aside settings save-sessions true`를 실행한 다음 `aside.settings.getAll()`의 `cli.ephemeral`이 `false`인지 확인한다. 새 CLI 실행은 `aside session list`에서 `persistent`로 표시된다. 이번 프로브의 최종 상태도 이 값으로 유지한다. [S8-Q1][S8-Q6]

승인 대기 세션에는 주의가 필요하다. 현재 CLI 도움말은 `--permission ask`와 `--permission guard`가 같은 Guard 모드라고 명시한다. 실제로 `/etc/hosts`를 `read_file`로 읽는 두 번의 시도는 승인 대기 상태로 멈추지 않았다. 둘 다 `blocked by policy`로 즉시 거부된 뒤 `idle`로 끝났다. 따라서 이번 빌드에서는 새 승인 카드를 만들거나 Deny 동작을 검증할 수 없었다. [S8-Q4]

과거 승인 대기 행은 여전히 데이터베이스에 남아 있었다. `aside session list`와 `aside.sessions.list()`는 그 행을 숨겼지만 `aside.sessions.get(id)`는 `suspension.kind=approval`을 반환했다. REPL의 `aside.sessions` 객체에는 승인이나 응답 메서드가 없었다. CLI의 `resume`과 `steer`도 해당 과거 행에 `Session is pending purge`를 반환했다. 새 중단 세션의 UI Deny 흐름은 재현 가능한 빌드가 필요하므로 `NEEDS_HUMAN`으로 남긴다. 어떤 외부 경로 승인도 누르지 않았다. [S8-Q4]

---

## 기술 참조

### S8 근거 원장

| 라벨 | 질문 | 핵심 명령 | 증거 파일 | 결론 |
|---|---|---|---|---|
| S8-Q1 | 설정은 어디에 저장되며 디스크에서 무엇이 바뀌는가 | `aside settings save-sessions true`; `aside.settings.getAll()`; 전후 JSON 해시와 `diff -u` | `evidence/probe-S1-persistence.log` | `~/.aside/u/0/settings.json`의 `cli.ephemeral`만 `true → false`로 바뀐다. 다른 최상위 JSON과 settings 계열 파일의 해시는 그대로다. |
| S8-Q2 | 새 세션이 비휘발로 생성되는가 | 전후 `timeout 120 aside exec ...`; 읽기 전용 SQLite 조회; `aside session list` | `evidence/probe-S2-ephemeral-comparison.log` | 설정 전 세션은 `ephemeral=1`, 설정 후 세션은 `ephemeral=0`이다. CLI 표시는 각각 `ephemeral`, `persistent`이다. 별도 purge 시각 열은 없고 두 행의 `archived_at`은 `NULL`이다. |
| S8-Q3 | 새 세션이 채팅 목록에 보이는가 | `aside.sessions.list()` 필터; Aside 창 영역 `screencapture` | `evidence/probe-S3-chat-list.log`, `evidence/probe-S3-aside-chat-list.png` | 저장 모드 세션은 API 결과와 Aside Chats 목록 모두에 보인다. 앱은 직전 휘발 기준 세션도 노출했지만 API는 제외했다. |
| S8-Q4 | 승인 대기 세션을 만들고 CLI/UI에서 처리할 수 있는가 | `timeout 90 aside exec --permission ask ...`; SQLite; `aside session list`; `aside.sessions.get/list`; `resume`; `steer` | `evidence/probe-S4-suspension.log` | 새 세션은 중단되지 않고 정책 거부 후 `idle`이 된다. 과거 `approval` 행은 list 계열에서 숨고 get으로만 보인다. REPL 승인 API가 없고 `resume`·`steer`는 purge-pending 오류다. UI Deny 검증은 `NEEDS_HUMAN`이다. |
| S8-Q5 | 저장 세션은 15분 purge에서 제외되는가 | 실행 데몬 바이너리의 `EPHEMERAL_SESSION_RETENTION_MS`, `purgeEphemeralSessions` 추출 | `evidence/probe-S5-purge-logic.log` | 보존 시간은 `9e5 ms`다. 삭제 쿼리는 `ephemeral=true`인 종료 세션만 선택하므로 저장 세션은 제외된다. |
| S8-Q6 | 최종 상태와 남은 세션은 무엇인가 | `aside settings save-sessions true`; REPL 설정 조회; SQLite 상태 조회 | `evidence/probe-S6-final-state.log` | 최종 값은 TRUE다. 이번 프로브 세션은 모두 `idle`이며 새 중단 세션은 없다. 과거 purge-pending 행은 삭제하거나 승인하지 않았다. |

### 설정 표현

| 사용자 명령 | `settings.json` 값 | 새 세션의 SQLite 값 | 기본 목록 동작 |
|---|---:|---:|---|
| `aside settings save-sessions false` | `cli.ephemeral=true` | `ephemeral=1` | `aside.sessions.list()` 기본 결과에서 제외 |
| `aside settings save-sessions true` | `cli.ephemeral=false` | `ephemeral=0` | `aside.sessions.list()`와 Chats 목록에 포함 |

### 세션 스키마와 purge 조건

`sessions` 테이블에는 `ephemeral`, `status`, `suspension`, `archived_at`, `created_at`, `updated_at`이 있다. 별도의 `visible` 또는 `purge_at` 열은 없다. 데몬의 purge 선택 조건은 아래와 같다. [S8-Q2][S8-Q5]

```text
ephemeral = true
AND status IN (idle, errored, interrupted, aborted)
AND archived_at IS NULL
AND updated_at < now - 900000 ms
```

중단 상태는 종료 상태 목록에 포함되지 않는다. 다만 과거 휘발 중단 행은 `archived_at`이 채워진 purge-pending 상태로 남을 수 있다. 이때 `resume`과 `steer`는 `Session is pending purge`를 반환한다. [S8-Q4][S8-Q5]

### 운영 체크리스트

- [x] 최종 `save-sessions` 값을 TRUE로 유지한다.
- [x] `aside.settings.getAll().cli.ephemeral === false`를 확인한다.
- [x] 새 persistent 세션의 SQLite `ephemeral=0`을 확인한다.
- [x] API와 앱 Chats 목록의 가시성을 각각 확인한다.
- [x] 외부 파일 접근을 승인하지 않는다.
- [ ] 재현 가능한 승인 대기 세션이 생기는 빌드에서 Deny UI를 검증한다. `NEEDS_HUMAN`이다.

## 변경 기록

- 2026-09-03: S8 라이브 프로브를 작성한다. 설정 저장 위치, SQLite 플래그, 채팅 목록 가시성, 중단 세션 제어 한계, purge 면제, 최종 TRUE 상태를 기록한다.
