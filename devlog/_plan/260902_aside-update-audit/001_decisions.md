# 001 - 사용자 결정과 override 근거 (2026-09-03)

010 권고안을 사용자에게 보고한 뒤 받은 결정. 이 문서가 020~040 decade doc 의 상위 근거이고, 여기 없는 방향 변경은 P 단계 amendment 로만 들어온다.

## 결정

1. 표면 분리 유지. repl 은 에이전트(Codex) 자신의 도구, exec 은 Aside 에이전트에게 위임하는 서브에이전트 방식. 공식 aside-browser v2 스킬(S5)이 "Default: hand the work to Aside. Skip JavaScript unless the user named Playwright" 로 exec-우선으로 돌아섰지만, 우리는 이를 **의도적 override** 로 명시한다. 근거: 한 repl 호출이 한 세션이라 inspect-act-verify 가 결정적으로 닫히고, 바깥 경로는 즉시 throw 하며, 증거(snapshot/screenshot) 캡처가 Codex 손에 남는다. exec 은 판단·로그인·CAPTCHA·builtin 스킬이 필요한 일에만 쓴다.
2. `--permission full-access` 를 exec 의 **기본 권고** 로 올린다. `ask` / `guard` 와 settings.json 의 grant-run-restore 절차는 대안으로 남긴다. 기본을 바꾸는 이유: 1.26.902 에서 guard 는 바깥 경로를 즉시 deny 하고 에이전트가 그 경로를 조용히 포기하므로, 결과가 "행" 이 아니라 "누락" 이 됐다. 읽기 전용 작업이라도 누락은 오답이므로 세션을 여는 편이 낫고, 그 대신 프롬프트에서 무엇을 건드리면 안 되는지 명시한다.
3. `aside settings save-sessions true` 를 **기본 권고** 로 한다. CLI 세션이 Aside 채팅 목록에 보이면 suspended 세션을 사람이 UI 에서 처리할 수 있는지, purge 와 어떻게 상호작용하는지 002 프로브로 확정한다. 프로브 후에도 설정은 true 로 둔다.
4. 완료 후 origin/main 푸시 허용 (이 goal 범위에 한함). 커밋 접두는 `[agent]`.
5. 서브에이전트: gpt-5.6-sol high. save-sessions 프로브와 리뷰 레인에 사용.
6. 공식 `aside skills install` 은 실행하지 않는다. aside-jun 이 aside-browser 를 대체하며, 같은 트리거 공간에 두 스킬이 공존하면 라우팅이 흔들린다.

## 010 항목과의 매핑

| 010 # | 결정 | 적용 decade |
|---|---|---|
| 1, 2, 8, 19 | 행 표 → fail-fast deny, 버전 핀 | 020 |
| 3, 13 | `--permission` 기본 full-access + 대안 | 020 (SKILL) / 030 (permissions.md) |
| 4, 10 | `--session` → `aside session resume/steer/queue` | 020 / 030 (scheduling.md) |
| 5, 15 | suspended 가시성, save-sessions | 002 프로브 → 030 (scheduling.md) |
| 6, 12 | builtin 스킬 read 경로, install 금지 정책 | 020 / 030 (builtin-skills.md, 스크립트) |
| 7 | `-m` 슬래시 형식 | 020 |
| 9 | repl 우선 override 명시 | 020 |
| 11, 14, 21 | memory CLI, Remote Control 미검증, mcp 도구 2종 | 020 / 030 |
| 16, 17, 18, 20 | builtin 34, Touch ID 재검증 항목, getTabs 오기, 글로벌 표 주석 | 030 |
| 22, 23 | refresh 스크립트, parity ledger 재대조 | 030 (스크립트) / 후속 work-phase 후보 |

## 남겨둔 것

- parity ledger(260831) 77행 재대조는 이 goal 의 범위 밖. 필요하면 wp5 로 append.
- Remote Control(`aside host`, 403), Touch ID 완화(.822) 는 "있음, 미검증" 으로만 기록.

