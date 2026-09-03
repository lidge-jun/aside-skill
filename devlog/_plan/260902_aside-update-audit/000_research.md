# 000 - Research: Aside 업데이트 감사 (2026-09-02)

## 버전 3종 (증거: 명령 출력)

| 컴포넌트 | 이전 | 현재 | 증거 |
|---|---|---|---|
| Aside CLI | 1.26.810.1915 | **1.26.902.1732** | `aside --update` (y) → `aside --version` |
| 데몬(Background service) | 1.26.829.1514 (스킬 기록) / 1.26.831.1513 (디스크) | **1.26.902.1713** | `curl 127.0.0.1:21420/` → `"version":"1.26.902.1713"`; PID 9972, started 2026-09-02T08:23Z |
| Aside.app (native) | 1.0.825.1 | **1.0.825.1 (최신)** | `defaults read Info.plist`; docs.aside.com/changelog/native 최상단 = v1.0.825.1; AsideUpdater prefs `updateclientlastupdatecheckerror: 502` 는 서버측 일시 오류, 새 버전 없음 |

Chromium 151.0.7922.171.

## 릴리스 노트 출처 (claim ledger)

| # | 출처 | 표면 | 범위 |
|---|---|---|---|
| S1 | Discord `Aside` 서버 `#announcements` (guild 1518417473043693608 / ch 1518420346057785444) | `aside exec` (grok-4.6 via opencodex, 서버 미가입 → aside.com footer 초대 2h4cNW6ayc 로 가입, captcha 자동 해결) | 2026-08-10 ~ 09-02, 24 포스트 → `evidence/aside-discord-changelog-260902.md` |
| S2 | https://docs.aside.com/changelog/components.md | curl | v1.26.721 ~ v1.26.829 (902 미게시) |
| S3 | https://docs.aside.com/changelog/native.md | curl | v1.0.825.1 최신 |
| S4 | https://docs.aside.com/help/developers.md | curl | CLI/MCP/REPL 공식 도움말 |
| S5 | 데몬 바이너리 `ASIDE_BROWSER_SKILL` 문자열 (831 vs 902) | python 추출 | `evidence/aside-browser-1.26.{831.1513,902.1713}.md` |
| S6 | `aside <cmd> --help` 1.26.902.1732 | 로컬 | 새 서브커맨드 표면 |
| S7 | 라이브 프로브 4종 (`evidence/probe-*.log`) | `aside exec` | 가드 동작 재검증 |

## 1.26.810 → 1.26.902 사이 스킬에 영향 주는 변경 (S1/S2/S5/S6)

1. **Sep 2 (v1.26.902.1713 / CLI .1732)** — "Revamped Aside CLI / MCP and Skills": `/aside-browser` 스킬 전면 재작성(v2, 165줄→103줄), `aside skills list|show|install`, `aside memory search|list|show|path`, `aside session list|resume|stop|steer|queue|archive|delete`, **"permission / ask user question tool / final confirm won't throw an error"**, MCP가 agent task 생성/실행 가능, Remote Control (`--host`, Pro/Max), `aside login|logout`, `aside settings save-sessions|set-default-profile`, `--permission ask|guard|full-access`, `aside update`.
2. **Aug 31 (.831)** — Cmd+Q/크래시 후 Agent Tabs 정리, 채널 텔레그램 음성 전사, rate limit 후 compaction 재시도 안 함.
3. **Aug 29 (.829)** — 사이드패널 chat 유지, 세션 공유 링크(실험), 채널 슬래시 커맨드.
4. **Aug 24 (.824)** — Screen Capture, **iMessage 스킬**, Mini popup, clipboard clear after credential copy.
5. **Aug 22 (.822)** — Command Code provider, Gatekeeper 격리 런타임 수정, passkey dialog 후 Touch ID skip.
6. **Aug 20 (.820)** — `/imagegen` 스킬, Grok 4.6 Aside provider.
7. **Aug 18 (.818)** — Pro Channels, "Ephemeral session cleanup is safer so live work isn't wiped".
8. **Aug 13 (.813)** — Password Manager 재설계, Proton Pass import, Grok 4.6.
9. **Aug 10 (.810)** — "Idle ephemeral CLI sessions are purged after 15 minutes" (스킬 scheduling.md 근거 확인), CLI/MCP 계정 고정.
10. **Aug 12/13/25 native** — v1.0.811.1 / 813.1 / 825.1.

## 라이브 프로브 결과 (S7, 모두 CLI 1.26.902.1732 + 데몬 1.26.902.1713, guard 설정 `outsideRead/Write: ask` 그대로)

| 프로브 | 프롬프트 | 결과 | 스킬 주장과의 차이 |
|---|---|---|---|
| A guard + `read_file` 워크스페이스 경로 | read_file /…/700_projects/AGENTS.md | **4.7초 만에 `Permission denied: read '…' is blocked by policy` 후 정상 종료** | SKILL.md L25-27 "Hangs" 표 **깨짐** — 더 이상 행 걸리지 않음 |
| B `--permission full-access` + read_file | 동일 | 4.2초, 파일 읽힘 | 새 플래그. 스킬에 없음 |
| W guard + `write_file` 바깥/안 | /tmp + ~/.aside/u/0 | 바깥 = blocked by policy 즉시, 안 = 성공 | L25 "Writing outside hangs" 깨짐 |
| C/Q ask_user_question | 질문해라 | 도구 카탈로그에 **ask_user_question 없음** (agent가 "no such tool" 보고, 채팅으로 질문 후 종료 exit 0, 10초) | L27 "Asking hangs" 깨짐 — 도구 자체가 CLI 세션에서 빠짐 |
| D bash 바깥 경로 | head AGENTS.md; cat /etc/hosts | 둘 다 성공 | 이전 "bash Seatbelt가 워크스페이스 head 거부" 관찰과 다름 (sandbox.enabled=false 설정 확인) |
| state.db suspended | 조회 | suspended 8건은 전부 8/27~8/31 이전 것. 오늘 프로브는 전부 `idle` | 새 suspended 미발생 |
| `--session` 재개 | weIhZ1WKvbeE0rBD (idle ephemeral, 12분 전) | `aside --session`/`exec --session` 은 이제 **help 출력**(플래그 제거됨). `aside session resume <id>` 가 대체. resume 시 모델 오류(`xai/grok-4.6 not available`)는 -m 없이 재개하면 세션에 저장된 provider-less id를 씀 → -m opencodex/xai/grok-4.6 형태로 다시 지정 필요 | L263-269 `--session` 서술 stale |
| repl 글로벌 | typeof | `getTabs` **undefined** (help 텍스트는 getTabs 안내 — 문서 오류), `listBrowserTabs` function, `page` null, `applePasswords` object(prototype 열거 안 됨 → `UNDEF` 로 보일 수 있음), `passwordManager` undefined, `googleAccounts/googlePeople/imageSearch` object, `fs/chrome` 은 plain object | 표 L171-176 대부분 유효, `aside` 글로벌 keys = pdf,settings,projects,sessions,routines,channels |
| builtin skills | refresh 스크립트 | 33→**34** top-level (+`context-awareness`), site-specific 16 동일 | builtin-skills.md 재생성 diff |
| 데몬 문자열 | strings | `ask_user_question` 8, `final_confirm` 2, `ASK USER AS THE LAST RESORT` 1 (**831 잔존 v1 문자열**; 902 v2 스킬 텍스트에는 없음), `EPHEMERAL_SESSION_RETENTION_MS=9e5` 유지, `Session is pending purge` 유지 | purge 15분은 그대로 |

## 해석

- 가드 모드의 "ask" 가 CLI(non-interactive) 세션에서는 **deny로 다운그레이드**된 것으로 보임 (S1 Sep 2 "permission / ask user question tool / final confirm won't throw an error" 와 일치). 프롬프트 클로즈(파일 도구 금지 + 질문 금지)는 여전히 좋은 습관이지만 "무한 행"은 더 이상 사실이 아니며, 대신 **deny 후 agent가 그 경로를 포기하고 진행**한다는 새 실패 양상(작업 미완)이 됨.
- 공식 aside-browser v2 스킬은 "Default: hand the work to Aside. Skip JavaScript unless…" 로 exec-우선 방향으로 바뀜. 우리 스킬은 repl-우선(결정적 작업)인데 이 차이는 의도적 override로 문서화해야 함.
- 새 1급 표면: `aside skills show <name>` (exec 없이 스킬 본문을 Codex가 직접 읽을 수 있음 → "Only exec can load them" 완화), `aside memory search`, `aside session steer|queue` (실행 중 세션에 개입 가능 → 폴링 루프에 "행 의심 시 steer" 옵션).
- `--host` Remote Control: `aside host list` 는 403 (Pro/Max 미가입 또는 미활성) → 스킬에 "있음, 미검증" 으로만 기록.

