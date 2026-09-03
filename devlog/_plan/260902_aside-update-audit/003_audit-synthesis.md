# 003 - A 단계 감사 종합 (round 1, reviewer Erdos / gpt-5.6-sol high)

판정 FAIL, 블로커 11. 전부 수용. 원인은 두 갈래: (a) 002 프로브가 020/030 초안 뒤에 끝나서 `ask` 동작과 Chats 가시성이 프로브 이전 가정으로 남아 있었음, (b) C 검증 조건을 치환 텍스트와 대조하지 않고 씀.

| # | 블로커 | 처리 | 위치 |
|---|---|---|---|
| 1 | `ask` 가 suspend-and-wait 라는 서술 vs S8-Q4 (guard 로 정규화) | 수용. 리뷰어 문장 채택 | 020 §편집1, 030 permissions §flag |
| 2 | save-sessions 후에도 "IDs expire" 보편 서술 잔존 | 수용. SKILL L275-281, scheduling L21/23/65-69 를 "save-sessions off 일 때" 로 한정 | 020 §편집3, 030 scheduling §편집1 |
| 3 | Chats 표 "hidden" vs S3 로그(UI 는 baseline 도 노출, API 는 제외) | 수용. API/UI 분리 서술 | 030 scheduling 표 + 문단 |
| 4 | README L3-10, L121-129, credentials L252-254 의 "waits forever / No flag disables" 잔존 | 수용. 세 곳 치환 추가 | 030 §README, §credentials |
| 5 | site 루프가 `top_rows+=` | 수용. 루프별 변수명 명시 | 030 §스크립트 |
| 6 | `Messages` → 디렉터리는 `imessage` | 수용. awk 별칭 | 030 §스크립트 |
| 7 | "repl-backed subset (11 of 34)" vs 030 의 "같은 집합 아님" | 수용. "CLI-listed subset, not identical" | 020 §편집4 |
| 8 | references `--session` C-check 1건 불가능 (permissions/scheduling/refskill 3건) | 수용. "removed 문맥 외 0건" 으로 조건 변경, refskill:41 주석 | 030 §검증 |
| 9 | SKILL `1.26.831` C-check 1건 불가능 (문단 + 표 헤더 2건) | 수용. 810/829 0건 + 831 2건 | 020 §검증 |
| 10 | ship-checks.log 커밋 후 push 출력 append → dirty | 수용. push 로그는 `.codexclaw/evidence/` (gitignore) | 040 §5 |
| 11 | 과장 주장 7건 (any path, GUI parity, 42/8, 14KB, MCP 2종, 11행, resume keeps working) | 수용. 각각 프로브 범위로 좁히거나 S 라벨 붙임 | 020/030 해당 문장 |

NIT 12(L93-95 → L95-96) 수용. NIT 13(SKILL 예상 462-466줄) 기록. NIT 14 결정 보존 확인.

재감사는 같은 리뷰어(Erdos)에게 이 문서 + 변경 요약을 넘겨 진행한다.

## round 2 (FAIL, 잔여 4)

| # | 잔여 | 처리 |
|---|---|---|
| 1 | `ask` 가 창에서는 suspend 한다는 단정 (020:47, 030:22), `--permission ask` 가 park 한다는 문장 (020:79, 020:225) | 수용. "창에서의 approval 동작은 미검증", CLI 는 모든 값에서 deny. park 원인 목록에서 `--permission ask` 제거 |
| 2 | "a CLI run cannot park" 과장 (030:123) | 수용. "outside-root file approval cannot park through --permission ask" 로 좁힘 |
| 3 | log-dump 이벤트, 11개 이름 근거 없음 | 수용. `evidence/probe-L-log-dump-summary.log` (+summary), `evidence/probe-K-skills-list.log` 추가 후 인용 |
| 4 | MCP "exec/repl" 를 릴리스 노트가 뒷받침하지 않음 | 수용. "(S1)" 까지만 |

NIT README L121 수용.

## wp2 B 리뷰 (reviewer Heisenberg / gpt-5.6-sol high, FAIL 2 blockers)

| # | 블로커 | 처리 |
|---|---|---|
| 1 | 첫 클로즈("file tools only under root, else bash")가 full-access 기본과 모순 — 플래그의 이점을 프롬프트가 무효화 | 수용. 클로즈를 write-fence 로 재정의: "Write and edit files only under ~/.aside/u/0/. Read other local paths only when this prompt names them, and never modify them." 설명 문단 재작성, guard 용 옛 클로즈는 대안으로 보존. Boundaries 절에 "full-access 에서는 이 클로즈가 유일한 경계" 명시. references 사본 3곳은 wp3 로 이월(030 검증 항목 추가) |
| 2 | 편집 4 에서 probe-K 인용 누락 | 수용. 인용 복원 |

NIT: "hangs" → "parks" (L144), 긴 줄 정리, 표 셀 축약 + 오류 전문은 표 아래 문장으로.

wp2 결과: 28b0ab5, 361b309 (SKILL.md 485줄), 04c7857 (check-wp2.sh). 첫 D 시도는 receipt 이후 check 스크립트를 커밋해 CHECK-BINDING-01 로 거부됨 → 같은 work-phase 를 P 부터 재진입해 receipt 를 다시 뜸.

## wp3 B 리뷰 (reviewer Raman / gpt-5.6-sol high, FAIL 3 blockers)

C-check·스크립트·클로즈 사본 SHA 는 통과. 블로커는 전부 "030 이 겨냥하지 않은 줄에 남은 현재형 구버전 서술": permissions.md L97/110/137/199/260/267, credentials.md L28, README L24, repl-api.md L166. 전부 수용해 "through 1.26.831 / on 1.26.902" 로 범위를 달거나 deny 계약으로 고쳐 씀. 추가로 스스로 잡은 README L3-4, credentials L239, permissions L171/L204/L289. NIT(030 literal 과의 미세 차이 2곳)는 의미 동일로 수용 안 함.
