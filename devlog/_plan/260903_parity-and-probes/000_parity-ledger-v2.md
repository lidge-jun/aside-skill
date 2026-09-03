# Aside 공식 v2 패리티 원장

이 원장은 Aside 데몬 번들에서 추출한 공식 `aside-browser` v2를 처음부터 다시 읽고 규범 문장만 재분해한 결과이다. 공식 원문의 유효 범위는 `evidence/aside-browser-1.26.902.1713.md:4-103`이다. 103행 뒤에 붙은 번들 JavaScript는 집계에서 제외한다. 명령 예시는 줄 수가 아니라 서로 다른 기능 의미로 나눴다. 그 결과 공식 v2의 규칙은 77개이다.

현재 `aside-jun`은 47개를 직접 설명한다. 20개는 빠져 있고, 8개는 사용자 결정에 따라 의도적으로 반대로 운용한다. 잘못 충돌하는 항목은 2개이다. 첫째, 공식은 memory 파일을 직접 편집하지 말라고 하지만 `references/scheduling.md`는 `memory/projects/`에 직접 쓰도록 허용한다. 둘째, `SKILL.md`의 “daemon needs the GUI app”은 로컬 실행에는 맞지만 공식 원격 호스트 예외를 덮어쓴다.

의도적 차이는 결함이 아니다. `aside-jun`은 결정적 inspect-act-verify를 위해 repl을 넓게 쓰고, exec에는 모든 프롬프트의 첫 경계로 write fence를 붙인다. 또한 guard의 조용한 누락을 피하려고 `--permission full-access`를 exec 기본으로 삼는다. 이 세 선택은 `001_decisions.md:7-8`에 기록된 사용자 결정이며, 아래 원장에서 `CONTRADICTS-CORRECTLY`로 분리한다.

FOLD 권고는 모두 참조 문서에 넣을 수 있다. 따라서 499/500행인 `SKILL.md`를 늘리거나 줄여 비용을 만들 필요가 없다. 반대로 Remote Control과 MCP의 세부 계약은 현재 환경에서 실측하지 않았으므로 공식 문구만 복사하지 않고 DEFER한다.

---

## 집계

| verdict | count |
|---|---:|
| PRESENT | 47 |
| MISSING | 20 |
| CONTRADICTS-CORRECTLY | 8 |
| CONTRADICTS-WRONGLY | 2 |
| total | 77 |

## 전체 원장

아래 `official:N`은 `devlog/_plan/260902_aside-update-audit/evidence/aside-browser-1.26.902.1713.md:N`을 뜻한다. `001_decisions.md:N`은 같은 audit 디렉터리의 사용자 결정 기록이다.

| # | v2 rule | in aside-jun | verdict | recommendation |
|---:|---|---|---|---|
| v2-01 | 모든 브라우저 필요 작업에 이 스킬을 사용한다 (`official:4`). | `aside-jun/SKILL.md:3`은 로그인 세션이 필요한 작업으로 한정하고 공개 페이지와 로컬 브라우저 QA를 제외한다. 이 범위 분리는 `001_decisions.md:7`의 표면 분리 원칙과 같은 방향이다. | CONTRADICTS-CORRECTLY | — |
| v2-02 | Aside는 AI 브라우저이다 (`official:9`). | `aside-jun/SKILL.md:8-11` | PRESENT | — |
| v2-03 | Aside의 에이전트는 사용자 credentials, cookies, browsing history, 여러 사이트를 걸친 복합 작업을 처리한다 (`official:9`). | 로그인 프로필과 cookies는 `aside-jun/SKILL.md:8-11,182-186`, credentials 경로는 `aside-jun/SKILL.md:225-231`, history 접근은 `aside-jun/references/deep-research.md:51-54`에 명시한다. | PRESENT | — |
| v2-04 | 기본값은 일을 Aside 에이전트에게 넘기는 것이다 (`official:10`). | `aside-jun/SKILL.md:150-161`은 repl을 Codex의 결정적 기본 도구로 두고 판단이 필요할 때만 exec에 위임한다. 근거는 `001_decisions.md:7`이다. | CONTRADICTS-CORRECTLY | — |
| v2-05 | 사용자가 Playwright를 지명했거나 특정 탭에 붙어 코드를 실행하라고 한 경우가 아니면 JavaScript를 건너뛴다 (`official:10`). | `aside-jun/SKILL.md:163-180`은 사용자가 Playwright를 말하지 않아도 기계적·결정적 작업에 repl을 선택한다. 근거는 `001_decisions.md:7`이다. | CONTRADICTS-CORRECTLY | — |
| v2-06 | 한 요청에서 Aside 위임과 JavaScript 직접 구동을 섞지 않는다 (`official:10`). | `aside-jun/SKILL.md:176-180`은 인증 단계만 exec로 처리하고 나머지를 repl로 처리하는 혼합을 허용한다. 검증 가능성을 지키는 표면 분리라는 근거는 `001_decisions.md:7`이다. | CONTRADICTS-CORRECTLY | — |
| v2-07 | `aside --help`와 `aside <command> --help`에서 현재 flags와 examples를 확인한다 (`official:12`). | `aside-jun/references/repl-api.md:10-12` | PRESENT | — |
| v2-08 | Slack·Gmail 같은 사이트의 research 또는 action에는 Aside 위임 경로를 쓴다 (`official:16`). | `aside-jun/SKILL.md:163-180,205-223`은 판단·로그인에는 exec, 구조화 API와 결정적 동작에는 repl을 쓴다. 이 의도적 축소의 근거는 `001_decisions.md:7`이다. | CONTRADICTS-CORRECTLY | — |
| v2-09 | 위임하면 Aside가 단계를 계획하고 브라우저를 제어한다 (`official:16`). | `aside-jun/SKILL.md:150-166` | PRESENT | — |
| v2-10 | 위임 입력은 plain text만 사용한다 (`official:16`). | `aside-jun/SKILL.md:235-253`의 exec 계약과 예시는 plain-text prompt이다. | PRESENT | — |
| v2-11 | 로컬 CLI 명령 전에 Aside Browser를 실행해 둔다 (`official:18`). | `aside-jun/SKILL.md:13`은 로컬 daemon에 GUI app이 필요하다고 명시한다. | PRESENT | — |
| v2-12 | 시작 방법은 `aside -h`에서 확인한다 (`official:18`). | 정확한 단축형 안내는 없다. `aside-jun/references/repl-api.md:10-12`는 더 일반적인 `aside --help`와 하위 명령 help를 안내한다. | MISSING | REJECT — 이미 더 포괄적인 현재-help 규칙이 있어 `-h` 별칭을 중복할 가치가 없다. |
| v2-13 | `aside "<prompt>"`로 기본 agent task를 시작할 수 있다 (`official:23`). | `aside-jun/references/refskill-aside.md:25-28` | PRESENT | — |
| v2-14 | `-m <provider/model>`로 모델을 선택할 수 있다 (`official:24`). | `aside-jun/SKILL.md:294-297` | PRESENT | — |
| v2-15 | `-s fast`로 speed를 선택할 수 있다 (`official:24`). | `aside-jun/references/refskill-aside.md:34-40` | PRESENT | — |
| v2-16 | `--effort high` 또는 `--effort ultrabrowse`로 effort를 선택할 수 있다 (`official:24-25`). | `aside-jun/SKILL.md:311-315`과 `aside-jun/references/refskill-aside.md:40,45-46` | PRESENT | — |
| v2-17 | `--account u1`로 한 작업의 profile을 선택할 수 있다 (`official:26`). | `aside-jun/references/refskill-aside.md:42`와 account-root 주의는 `aside-jun/SKILL.md:345-349` | PRESENT | — |
| v2-18 | `--permission full-access`로 설치처럼 넓은 권한이 필요한 작업을 실행할 수 있다 (`official:27`). | `aside-jun/SKILL.md:61-73`은 옵션과 효과를 설명한다. | PRESENT | — |
| v2-19 | 공식 예시는 `full-access`를 설치 작업에서만 명시해 일반 실행의 task-specific opt-in으로 다룬다 (`official:23-28`). | `aside-jun/SKILL.md:61-75,247-254,493-496`은 모든 exec의 기본 권고를 `full-access`로 올린다. guard에서 단계가 조용히 누락되는 것을 피하려는 사용자 결정은 `001_decisions.md:8`이다. | CONTRADICTS-CORRECTLY | — |
| v2-20 | URL 하나만 prompt로 넘겨도 task를 시작할 수 있다 (`official:28`). | `aside-jun/SKILL.md:235-287`은 URL·작업·보고 필드와 write-fence를 갖춘 prompt를 요구하며 bare URL을 허용하지 않는다. full-access에서도 첫 prompt clause를 경계로 삼는 사용자 결정은 `001_decisions.md:8`이다. | CONTRADICTS-CORRECTLY | — |
| v2-21 | task를 실행한 뒤 run을 지켜보고 약 60초마다 사용자에게 상태를 알린다 (`official:31`). | `aside-jun/SKILL.md:299-309` | PRESENT | — |
| v2-22 | `aside session resume <id>`는 prompt 없이 session을 재개할 수 있다 (`official:36`). | prompt 없는 형식과 의미를 설명하지 않는다. | MISSING | FOLD — `aside-jun/references/scheduling.md:44` 뒤에 “`aside session resume <id>` without a prompt opens the interactive session.”을 추가한다. SKILL.md는 0행 증가하므로 trim은 필요 없다. |
| v2-23 | `aside session resume <id> "<prompt>"`로 prompt를 붙여 재개할 수 있다 (`official:37`). | `aside-jun/SKILL.md:317-322` | PRESENT | — |
| v2-24 | `aside session steer <id> "<text>"`로 running turn을 redirect할 수 있다 (`official:38`). | `aside-jun/SKILL.md:317-320` | PRESENT | — |
| v2-25 | `aside session queue <id> "<text>"`로 follow-up을 예약할 수 있다 (`official:39`). | `aside-jun/SKILL.md:317-320` | PRESENT | — |
| v2-26 | `aside session stop <id>`로 session을 중지할 수 있다 (`official:40`). | `aside-jun/SKILL.md:115-118` | PRESENT | — |
| v2-27 | `aside session archive <id>`로 session을 archive할 수 있다 (`official:41`). | 설명이 없다. | MISSING | FOLD — `aside-jun/references/scheduling.md:44-46`의 control 문단에 “Use `aside session archive <id>` to archive a finished session”을 넣는다. v2-28과 한 문장으로 합치며 SKILL.md trim은 필요 없다. |
| v2-28 | `aside session delete <id>`로 session을 delete할 수 있다 (`official:42`). | 설명이 없다. | MISSING | FOLD — v2-27 문장 뒤를 “or `aside session delete <id>` to delete it.”으로 완성한다. SKILL.md trim은 필요 없다. |
| v2-29 | prompt를 붙인 resume은 single turn을 실행한다 (`official:45`). | resume 명령은 있으나 single-turn 의미는 없다. | MISSING | FOLD — `aside-jun/references/scheduling.md:44` 앞에 “Resume with a prompt runs one turn.”을 추가한다. SKILL.md trim은 필요 없다. |
| v2-30 | prompt 없는 resume은 `>`, `/session`, `/exit`를 제공하는 interactive session을 연다 (`official:45`). | interactive mode와 세 명령을 설명하지 않는다. | MISSING | FOLD — v2-22의 문장을 “...opens an interactive session with `>`, `/session`, and `/exit`.”로 확장한다. SKILL.md trim은 필요 없다. |
| v2-31 | `steer`는 running turn을 redirect한다 (`official:47`). | `aside-jun/SKILL.md:317-320` | PRESENT | — |
| v2-32 | `queue`는 현재 step 뒤에 instruction을 실행한다 (`official:47`). | `aside-jun/SKILL.md:319-320`은 follow-up으로 넘긴다고 명시한다. | PRESENT | — |
| v2-33 | `steer`와 `queue`는 `ok`를 출력하고 종료한다 (`official:47`). | 출력·종료 계약은 없다. | MISSING | FOLD — `aside-jun/references/scheduling.md:44-46`의 session-control 문단에 “`steer` and `queue` print `ok` and exit.”를 추가한다. SKILL.md trim은 필요 없다. |
| v2-34 | `aside session list`에는 chat list에 저장되지 않은 session도 나온다 (`official:49`). | `aside-jun/references/scheduling.md:76-83`은 ephemeral run이 session list에는 나오고 Chats에는 나오지 않는다고 구분한다. | PRESENT | — |
| v2-35 | session은 shipped default에서 chat list에 남지 않는다 (`official:53`). | `aside-jun/references/scheduling.md:23-24,76-83` | PRESENT | — |
| v2-36 | `aside settings save-sessions true`를 켜면 session을 chat list에 유지한다 (`official:53`). | `aside-jun/SKILL.md:138-143` | PRESENT | — |
| v2-37 | `aside settings set-default-profile u1`로 이후 CLI의 기본 profile을 정한다 (`official:54`). | `aside-jun/SKILL.md:345-349`은 account root가 바뀌면 고정 write-fence가 깨지므로 기본 profile 선택을 의도적으로 안내에서 뺀다. | MISSING | REJECT — command 자체는 유효하지만 현재 u0 고정 prompt 계약과 함께 권고하면 안전 경계를 조용히 무효화한다. account-parameterized fence가 먼저 생겨야 한다. |
| v2-38 | `--account u1`은 한 번만 적용되는 profile override이다 (`official:54`). | `aside-jun/SKILL.md:345-349`와 `aside-jun/references/refskill-aside.md:42` | PRESENT | — |
| v2-39 | Aside는 browsing을 plain-Markdown memory로 계속 distill한다 (`official:58`). | `aside-jun/references/scheduling.md:167-176,190-193` | PRESENT | — |
| v2-40 | 이전 context를 사용자에게 다시 묻기 전에 Aside memory를 recall한다 (`official:58`). | memory 저장소와 검색 명령은 있으나 이 우선순위는 없다. | MISSING | FOLD — `aside-jun/references/scheduling.md:167` 아래에 “Recall Aside memory before asking the user for prior browsing context.”를 추가한다. SKILL.md trim은 필요 없다. |
| v2-41 | `aside memory search "<query>" --json`으로 machine-readable 검색을 한다 (`official:61`). | `aside-jun/SKILL.md:329-331`과 `aside-jun/references/scheduling.md:174-176`은 search를 적지만 `--json`을 빠뜨린다. | MISSING | FOLD — `aside-jun/references/scheduling.md:174-176`의 search 표기를 정확히 ``aside memory search "<query>" --json``으로 바꾼다. SKILL.md trim은 필요 없다. |
| v2-42 | `aside memory list --json`으로 machine-readable 목록을 얻는다 (`official:62`). | `aside-jun/SKILL.md:329-331`과 `aside-jun/references/scheduling.md:174-176`은 list를 적지만 `--json`을 빠뜨린다. | MISSING | FOLD — 같은 문장에 ``aside memory list --json``을 적는다. SKILL.md trim은 필요 없다. |
| v2-43 | `aside memory show <id-or-file>`로 memory를 읽는다 (`official:63`). | `aside-jun/SKILL.md:329-331`과 `aside-jun/references/scheduling.md:174-176` | PRESENT | — |
| v2-44 | `aside memory path`로 memory 경로를 확인한다 (`official:64`). | `aside-jun/SKILL.md:329-331`과 `aside-jun/references/scheduling.md:174-176` | PRESENT | — |
| v2-45 | memory 파일을 직접 편집하지 않는다 (`official:67`). | `aside-jun/references/scheduling.md:190-193`은 scheduled job이 `memory/projects/`에 직접 durable facts를 쓸 수 있다고 말한다. | CONTRADICTS-WRONGLY | `aside-jun/references/scheduling.md:192-193`을 “Never edit memory files directly; let Aside maintain this store.”로 교체한다. |
| v2-46 | 사용자가 기억해 달라고 하면 `aside exec`를 통해 기록한다 (`official:67`). | 직접 쓰기를 허용하는 `aside-jun/references/scheduling.md:190-193` 외에 exec 경로 규칙이 없다. | MISSING | FOLD — v2-45 교정문 뒤에 “If the user wants Aside to remember something, delegate that request through `aside exec`.”를 추가한다. SKILL.md trim은 필요 없다. |
| v2-47 | `aside mcp`에서는 `memory_search` tool을 우선한다 (`official:67`). | `aside-jun/references/scheduling.md:169-176`은 exec agent의 tool만 설명하고 MCP tool 노출은 검증하지 않는다. | MISSING | DEFER — 현재 환경에서 MCP initialize와 tool list를 아직 실측하지 않았다. 노출 이름과 schema를 probe한 뒤 접는다. |
| v2-48 | `snapshot()`으로 사이트를 수동 구동하기 전에 matching Aside skill을 확인한다 (`official:71`). | `aside-jun/SKILL.md:427-431`은 읽을 수 있다고만 하고, `aside-jun/references/repl-api.md:288-295`도 service global 사용 전 읽기로 범위를 좁힌다. | MISSING | FOLD — `aside-jun/references/builtin-skills.md:6` 앞에 “Before driving a site manually with `snapshot()`, check for a matching Aside skill.”을 추가한다. SKILL.md trim은 필요 없다. |
| v2-49 | `aside skills list`로 CLI-listed skill을 찾는다 (`official:74`). | `aside-jun/SKILL.md:427-431` | PRESENT | — |
| v2-50 | `aside skills show <name>`으로 skill 본문을 읽는다 (`official:75`). | `aside-jun/SKILL.md:427-431` | PRESENT | — |
| v2-51 | matching skill을 먼저 읽고 따른다 (`official:78`). | `aside-jun/references/repl-api.md:288-295` | PRESENT | — |
| v2-52 | 어떤 Aside skill을 왜 쓰는지 사용자에게 알린다 (`official:78`). | 고지 규칙이 없다. | MISSING | FOLD — `aside-jun/references/builtin-skills.md:6-8` 뒤에 “Tell the user which Aside skill you are using and why.”를 추가한다. SKILL.md trim은 필요 없다. |
| v2-53 | `aside host list`로 remote host를 조회한다 (`official:83`). | `aside-jun/SKILL.md:351-354` | PRESENT | — |
| v2-54 | `aside exec --host <id-or-name>`으로 remote host에 agent task를 보낸다 (`official:84`). | `aside-jun/SKILL.md:351-354`은 `--host <id>`가 run을 원격으로 route한다고 설명한다. | PRESENT | — |
| v2-55 | `aside repl --host <id-or-name>`으로 remote host의 browser를 직접 구동한다 (`official:85`). | generic `--host` 언급만 있고 repl 조합은 검증·명시하지 않는다 (`aside-jun/SKILL.md:351-354`). | MISSING | DEFER — `aside host list`가 이 계정에서 403이므로 remote repl 연결을 probe하지 못했다. |
| v2-56 | `aside host use <host>`로 기본 remote host를 선택한다 (`official:86`). | `aside-jun/SKILL.md:351-354` | PRESENT | — |
| v2-57 | remote host는 같은 Aside account를 사용해야 한다 (`official:89`). | 이 account prerequisite를 설명하지 않고 plan 제약과 403만 기록한다 (`aside-jun/SKILL.md:351-354`). | MISSING | DEFER — 접근 가능한 remote account/host에서 account mismatch와 성공을 probe한 뒤 접는다. |
| v2-58 | remote host에서 Remote Control이 enabled여야 한다 (`official:89`). | 이 host prerequisite를 설명하지 않고 plan 제약과 403만 기록한다 (`aside-jun/SKILL.md:351-354`). | MISSING | DEFER — 접근 가능한 host에서 Remote Control off/on을 probe한 뒤 접는다. |
| v2-59 | `aside login`을 한 번 수행하면 remote host 인증을 재사용한다 (`official:89`). | `aside-jun/SKILL.md:351-354`은 `aside login --email` 존재만 적고 one-time 재사용 계약은 검증하지 않는다. | MISSING | DEFER — 로그인·host 권한 조합을 probe하지 않았다. |
| v2-60 | remote host를 쓸 때는 Aside가 로컬에서 실행 중이지 않아도 된다 (`official:89`). | `aside-jun/SKILL.md:13`은 예외 없이 daemon에 GUI app이 필요하다고 말한다. | CONTRADICTS-WRONGLY | `aside-jun/SKILL.md:13`을 “Local CLI runs need the GUI app; after `aside login`, remote-host commands do not require Aside to be running locally.”로 한 줄 교체한다. 행 수는 그대로다. |
| v2-61 | 사용자가 Playwright, snapshot/locator script, 또는 특정 tab attach+JS를 요구할 때 JavaScript 경로를 연다 (`official:93`). | `aside-jun/SKILL.md:155-180`은 이 조건이 없어도 결정적 작업에 repl을 사용한다. 근거는 `001_decisions.md:7`이다. | CONTRADICTS-CORRECTLY | — |
| v2-62 | JavaScript 경로에서는 Aside agent가 개입하지 않는다 (`official:93`). | `aside-jun/SKILL.md:150-153,176-178`은 repl을 Codex가 직접 구동하는 도구로 정의한다. | PRESENT | — |
| v2-63 | `aside repl "<javascript>"`로 JavaScript를 실행한다 (`official:96`). | `aside-jun/SKILL.md:356-363` | PRESENT | — |
| v2-64 | MCP `repl` tool은 `{ title, code }`를 받는다 (`official:99`). | `aside-jun/SKILL.md:476-478`은 MCP가 task를 실행한다고만 하고 tool schema를 적지 않는다. | MISSING | DEFER — MCP tool list와 input schema를 실제 initialize session에서 probe한 뒤 `references/repl-api.md`에 접는다. |
| v2-65 | repl 실행 timeout은 120초이다 (`official:99`). | `aside-jun/SKILL.md:362-363`과 `aside-jun/references/repl-api.md:7-8` | PRESENT | — |
| v2-66 | repl에서는 `import`와 `require`를 쓸 수 없다 (`official:99`). | `aside-jun/SKILL.md:362-363`과 `aside-jun/references/repl-api.md:7-8` | PRESENT | — |
| v2-67 | repl 결과는 `console.log()`로 출력한다 (`official:99`). | `aside-jun/SKILL.md:362`과 `aside-jun/references/repl-api.md:7-8` | PRESENT | — |
| v2-68 | fresh repl에서 `page`는 unset/null로 시작한다 (`official:101`). | `aside-jun/references/repl-api.md:36-37,172-175` | PRESENT | — |
| v2-69 | 먼저 `listBrowserTabs()`로 열린 tab을 조사한다 (`official:101`). | `aside-jun/references/repl-api.md:177-183` | PRESENT | — |
| v2-70 | active tab이 대상이면 `attachActiveBrowserTab()`을 쓴다 (`official:101`). | `aside-jun/references/repl-api.md:185-187` | PRESENT | — |
| v2-71 | 특정 target이면 `attachBrowserTab(targetId)`를 쓴다 (`official:101`). | `aside-jun/references/repl-api.md:185-187` | PRESENT | — |
| v2-72 | relevant tab이 없을 때만 `openTab(url)`을 호출한다 (`official:101`). | `aside-jun/references/repl-api.md:187-189` | PRESENT | — |
| v2-73 | `snapshot(page)`는 `{ tree, diff }`를 반환한다 (`official:103`). | 더 강한 shape인 `{tree, refs, diff}`를 `aside-jun/references/repl-api.md:97-113`에 명시한다. | PRESENT | — |
| v2-74 | ref click은 `page.locator('e12')`처럼 하고 CSS selector로 섞지 않는다 (`official:103`). | `aside-jun/references/repl-api.md:212-219` | PRESENT | — |
| v2-75 | 새 snapshot은 이전 ref를 모두 무효화한다 (`official:103`). | `aside-jun/references/repl-api.md:214-216` | PRESENT | — |
| v2-76 | 첫 읽기에는 `tree`, 다음 변화에는 `diff`를 출력한다 (`official:103`). | `aside-jun/SKILL.md:386-399` | PRESENT | — |
| v2-77 | tree만으로 부족하면 `annotatedScreenshot(page)`로 올린다 (`official:103`). | `aside-jun/references/repl-api.md:120-126,195-203` | PRESENT | — |

## v1 대비 변화

| verdict | v1 | v2 재도출 | 변화 |
|---|---:|---:|---:|
| PRESENT | 26 | 47 | +21 |
| MISSING | 47 | 20 | -27 |
| CONTRADICTS-CORRECTLY | 1 | 8 | +7 |
| CONTRADICTS-WRONGLY | 3 | 2 | -1 |
| total | 77 | 77 | 0 |

두 원장이 우연히 모두 77행이지만 같은 77행을 업데이트한 결과는 아니다. 공식 v2는 v1의 상세 snapshot·download playbook을 크게 줄이고 session, memory, skills, remote host 계약을 새 중심으로 삼았다. 분모의 수만 같고 구성은 크게 달라졌다.

PRESENT가 늘어난 이유는 1.26.902 audit에서 `session resume|steer|queue`, `save-sessions`, memory CLI, `skills list|show`, repl tab/ref 규칙이 이미 본문과 references에 반영됐기 때문이다. MISSING 감소에는 공식 v2 자체의 축약도 포함되므로 단순히 27개를 구현했다고 읽으면 안 된다.

의도적 충돌은 v1의 1개에서 8개로 늘었다. 이번 원장은 하나의 “표면 선택 차이”를 broad trigger, default delegation, JavaScript gate, 혼합 금지, research/action routing으로 각각 추적하고, 사용자 결정인 full-access 기본과 write-fenced prompt도 별도 규칙으로 드러냈다. 이는 결함 증가가 아니라 override의 추적 가능성 증가이다.

잘못된 충돌은 3개에서 2개로 줄었다. v1에서 잘못됐던 repl persistence, snapshot truncation, Downloads jail은 현재 `aside-jun`에 교정됐다. v2에서 새로 드러난 실제 결함은 memory 직접 편집 허용과 remote-host의 로컬 GUI 예외 누락이다.

## FOLD 우선순위

1. memory 안전 계약: v2-40~42와 v2-46을 `references/scheduling.md`에 합쳐 recall-first, JSON 출력, 직접 편집 금지, remember-via-exec를 한 묶음으로 만든다.
2. session control 완성: v2-22, v2-27~30, v2-33을 `references/scheduling.md`의 resume 문단에 두세 문장으로 접는다.
3. skill preflight와 사용자 고지: v2-48과 v2-52를 `references/builtin-skills.md` 도입부에 두 문장으로 접는다.

모든 FOLD는 references만 바꾸므로 `SKILL.md` 499행 제한의 대가가 없다. `SKILL.md`에서 고쳐야 하는 v2-60도 기존 13행을 한 줄 교체하면 된다.
