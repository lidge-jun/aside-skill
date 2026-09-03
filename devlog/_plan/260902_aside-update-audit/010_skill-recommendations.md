# 010 - aside-jun 스킬 갱신 권고 (drift 목록)

대상: `/Users/jun/.codex/skills/aside-jun` (= `700_projects/aside-skill/aside-jun`, diff -rq 동일 확인).
근거 라벨은 000_research.md 의 S1~S7. 우선순위 P0 = 현재 문장이 틀림, P1 = 누락된 새 기능, P2 = 표현/핀 갱신.

## P0 — 현재 서술이 실측과 다름

| # | 파일:줄 | 현재 문장 | 실측 (S7) | 권고 |
|---|---|---|---|---|
| 1 | SKILL.md:13-30 "The one rule that matters" 표 | 바깥 read/write, 질문 → "Hangs" | guard 모드에서 `read_file`/`write_file` 바깥 경로는 **즉시 `Permission denied: … blocked by policy`** 로 실패하고 런은 계속됨. `ask_user_question` 은 CLI 세션 도구 카탈로그에 **없음**. Discord Sep 2: "permission / ask user question tool / final confirm won't throw an error" (S1) | 표를 "이전(≤.831): 행 / 현재(≥.902): 즉시 deny" 두 열로 바꾸고, 새 실패 양상 = "deny 후 agent가 경로를 포기하고 불완전하게 종료" 로 재정의. 세 클로즈는 유지하되 이유를 "행 방지"에서 "deny로 인한 작업 누락 방지"로 수정 |
| 2 | SKILL.md:32-36 "Still true on CLI 1.26.810.1915 with daemon 1.26.829.1514" | 버전 핀 | CLI 1.26.902.1732 / 데몬 1.26.902.1713 / app 1.0.825.1 | 핀 갱신 + "1.26.902 에서 동작이 바뀜" 명시 |
| 3 | SKILL.md:56-66, references/permissions.md:155-190 grant-run-restore | 루트를 넓혀야만 바깥 경로 가능 | `--permission full-access` 플래그 하나로 read_file 바깥 경로 성공 (probe B). settings.json 편집 불필요 | grant 절차를 "레거시/세밀 제어용"으로 강등, 기본 권고를 `--permission full-access` (단, 세션 전체가 열리므로 읽기 전용 작업엔 쓰지 말 것) 로 교체 |
| 4 | SKILL.md:263-270, references/scheduling.md:21-45 `--session <id>` | "`--session` continues a healthy run" | 1.26.902 에서 `--session` 플래그 **제거** (help 미표시, 사용 시 help 출력). 대체: `aside session resume <id> [prompt]`, `steer`, `queue`, `stop`, `list` (S6). 15분 ephemeral purge 상수(`9e5`)와 "Session is pending purge" 문자열은 데몬에 그대로 존재 | `--session` 언급 전부 `aside session resume` 로 치환. resume 시 `-m` 없이 재개하면 세션에 저장된 모델 id로 provider 오류가 날 수 있음(실측: `xai/grok-4.6 is not available`) — resume 에도 `-m provider/model` 재지정 권고 |
| 5 | SKILL.md:92-99, scheduling.md:49-62 suspended 세션 조회 | "CLI runs are created ephemeral… read the database directly" | `aside session list` 는 ephemeral 을 나열하지만(42건: idle 36 / interrupted 5 / aborted 1) **suspended 8건은 한 건도 안 보임** (sqlite 에는 존재). 실측 S7 | sqlite 조회 문장은 **유지** (여전히 유일한 suspended 가시성). `aside session list` 는 "running/idle 확인용" 으로만 추가 |
| 6 | SKILL.md:353-360 "Only exec can load them. You cannot invoke one directly" | builtin 스킬은 exec 전용 | `aside skills list` / `aside skills show <name>` 로 Codex가 스킬 본문을 직접 읽을 수 있음 (S6). 단 list 출력은 11개(repl-backed만)로 builtin 34개 전부는 아님 | "exec 만 load" → "exec 가 자동 load; Codex 는 `aside skills show` 로 본문을 읽고 repl 글로벌을 직접 구동 가능" 으로 수정. builtin-skills.md 의 Backing 열 근거를 `aside skills list` 출력으로 교체 |
| 7 | SKILL.md:244-246 "Omit `-m`" | 모델 플래그 생략 권고 | 사용자 지시(xai/grok-4.6 무제한)로 `-m` 필요. `-m xai/grok-4.6 -p opencodex` 는 실패, **`-m opencodex/xai/grok-4.6`** (slash form, provider 포함) 만 동작 (S7) | "Omit -m" 을 "기본은 생략, 지정 시 반드시 `provider/model` 슬래시 형식, 다중 슬래시 모델은 `opencodex/xai/grok-4.6`" 으로 |
| 8 | SKILL.md:393 `--log-dump` "undocumented" | 존재 | 1.26.902 에서도 동작 확인: `--log-dump /tmp/aside-audit/ld.jsonl` → 14KB JSONL (agent_start/turn_start/message_* 이벤트) 생성 | 문장 유지, "1.26.902 재확인" 핀만 추가 |
| 9 | SKILL.md:116-135 "Choosing a surface" | repl-우선 | 공식 aside-browser v2 (S5): "Default: hand the work to Aside. Skip JavaScript unless the user named Playwright…" — 방향 정반대 | 우리 선택(결정적 작업은 repl)을 **의도적 override** 로 명시하고 근거(한 호출=한 세션, 즉시 예외, 증거 캡처) 기재. parity ledger(260831) 에 행 추가 |

## P1 — 새 기능 미반영

| # | 기능 | 출처 | 권고 위치 |
|---|---|---|---|
| 10 | `aside session steer|queue <id> "<prompt>"` — 실행 중 세션에 개입 | S1 Sep 2, S6 | SKILL.md "Runs take minutes… poll" 절에 "행 의심 시 `aside session steer <id> 'report what blocks you and stop'` 로 먼저 구출 시도, 그 다음 timeout" 추가 |
| 11 | `aside memory search|list|show|path` (read-only) | S1, S6 | scheduling.md "Aside remembers on its own" 절에 CLI 조회 예시 추가. 실측: `aside memory path` = ~/.aside/u/0/memory, search 동작 |
| 12 | `aside skills install` (Codex/Claude Code/Cursor/OpenCode 에 aside-browser 스킬 설치, 대상 `.agents/skills`, `.cursor/skills`, fallback `/etc/codex`) | S5, S6 | "What Aside already knows" 절: 공식 스킬과 aside-jun 이 같은 이름공간에 설치되면 충돌 — `~/.codex/skills/aside-browser` 현재 없음. "설치하지 말 것(aside-jun 이 대체)" 또는 "설치해도 aside-jun 이 우선" 정책 결정 필요 |
| 13 | `--permission ask|guard|full-access` | S6 | SKILL.md exec 옵션 목록 + permissions.md 새 절 |
| 14 | `--host <id>` Remote Control (Pro/Max), `aside host list|use|status`, `aside login --email` | S1, S6 | "있음, 미검증(`host list` → 403)" 로만 기록 |
| 15 | `aside settings save-sessions true` — CLI 세션을 chat list 에 노출 | S6 | scheduling.md: 디버깅 시 켜면 suspended 세션을 Aside UI 에서 답할 수 있는지 검증 가능 (SKILL.md:103 의 "unconfirmed" 해소 경로) |
| 16 | 새 builtin `context-awareness`, `imessage`(Aug 24), `imagegen` 스킬(Aug 20), Proton Pass import(Aug 13) | S1, refresh 스크립트 diff | references/builtin-skills.md 재생성본 채택 (이미 워크트리에 생성, 미커밋). credentials.md:189 provider 목록에 `proton-pass` 이미 있음 — OK |
| 17 | Password manager: 자격증명 복사 후 clipboard 자동 clear(.824/.902), passkey 다이얼로그 후 Touch ID skip(.822) | S1, S2 | credentials.md "Leave Unlock with Touch ID OFF" 절에 .822 이후 완화 여부 재검증 항목 추가 |
| 18 | repl help 가 `getTabs()` 안내하나 실제 `typeof getTabs === 'undefined'` | S6, S7 | repl-api.md "Getting a page" 에 "help 의 getTabs 는 오기, listBrowserTabs 사용" 한 줄 |

## P2 — 핀/표현

| # | 파일:줄 | 권고 |
|---|---|---|
| 19 | SKILL.md:139-141 "verified against CLI 1.26.810.1915 with daemon 1.26.829.1514" | 1.26.902.1732 / 1.26.902.1713 로 갱신 (repl openTab 이 signed-in 세션 상속하는 것은 오늘 Discord/aside.com 탭에서 재확인) |
| 20 | SKILL.md:167-178 repl 글로벌 표 | `applePasswords` 는 prototype 열거가 안 돼 probe 에서 UNDEF 로 보였음 — "typeof 로 확인" 주석. `aside` 글로벌 keys: pdf, settings, projects, sessions, routines, channels 추가 |
| 21 | SKILL.md:401-403 "`aside mcp` produces nothing" | Sep 2 부터 MCP 가 agent task 생성/실행 가능 (`exec`, `repl` 두 도구, S6). 문장은 여전히 참이나 "MCP 도구는 exec/repl 2종" 추가 |
| 22 | scripts/refresh-builtin-summary.sh REPL_BACKED 하드코딩 | `aside skills list` 출력을 파싱해 repl-backed 판정하도록 개선(하드코딩 제거) |
| 23 | 260831 parity ledger | 공식 스킬 v2 로 재작성됐으므로 77행 ledger 재대조 필요 — 별도 work-phase 후보 |

## 적용 순서 제안 (별도 work-phase, 사용자 승인 후)

1. wp2: P0 #1-#4 (행 표, 버전 핀, --permission, session 서브커맨드) — SKILL.md + permissions.md + scheduling.md
2. wp3: P0 #5-#9 + P1 #10-#15 — SKILL.md 표면 절, repl-api.md
3. wp4: P1 #16-#18 + P2, parity ledger 재대조, refresh 스크립트 개선

## 미해결 / 검증 필요

- (해결) `aside session list` 는 suspended 를 숨김 → sqlite 유지. (해결) `--log-dump` 동작함.
- Aside UI 에서 ephemeral suspended 세션에 답할 수 있는지 (`save-sessions true` 로 검증 가능)
- Touch ID 완화(.822) 실효
- Remote Control(403) — 플랜 문제인지 설정 문제인지
