# 020 - wp2: v2 원장의 FOLD/교정을 반영 (diff-level)

대상: `aside-jun/references/scheduling.md`, `aside-jun/references/builtin-skills.md` (생성물이므로 `scripts/refresh-builtin-summary.sh` 를 고친 뒤 재생성), `aside-jun/SKILL.md` 한 줄. 근거는 000_parity-ledger-v2.md 의 v2-NN 번호.

## 왜 여기서 자르나

FOLD 8건과 CONTRADICTS-WRONGLY 2건 중 SKILL.md 를 건드리는 것은 v2-60 한 줄뿐이다(교체이므로 행 수 불변, 499 유지). 나머지는 전부 references 에 들어간다. 원장이 DEFER 로 분류한 Remote Control/MCP 세부는 여기서 손대지 않고, 그중 실측된 부분만 wp3(030) 이 처리한다.

---

## 편집 1 — SKILL.md L13 (v2-60, CONTRADICTS-WRONGLY)

현재 문장은 예외 없이 "데몬은 GUI 앱이 필요하다" 고 단정한다. 공식 v2 는 `aside login` 이후 원격 호스트는 로컬 Aside 없이도 동작한다고 말하고, 우리 프로브(001, S9-R2)도 그 경로가 데몬에 실재함을 확인했다.

```diff
-Aside is macOS-only: the CLI is a `Mach-O` binary and the daemon needs the GUI app.
+Aside is macOS-only: the CLI is a `Mach-O` binary and a local run needs the GUI app
+running; for remote-host commands it need not be (see Remote Control below).
```

한 줄이 두 줄이 되므로 같은 문단에서 한 줄을 회수한다: 바로 아래 "A stock macOS machine has neither ... see the deadline section for why that is load-bearing." 4줄을 3줄로 줄인다.

```diff
-A stock macOS machine has neither `timeout` nor `flock`, so every command here
-uses the base-system `perl -e 'alarm ...'` and `shlock` instead; see the deadline
-section for why that is load-bearing.
+A stock macOS machine has neither `timeout` nor `flock`, so every command here uses
+the base-system `perl -e 'alarm ...'` and `shlock`; the deadline section says why.
```

순증 0줄, SKILL.md 는 499 유지.

## 편집 2 — scheduling.md, session control 완성 (v2-22, v2-27, v2-28, v2-29, v2-30, v2-33)

현재 L44-46 은 resume 이 15분 창 안에서만 쓸모 있다는 것만 말한다. 공식이 정의하는 resume 의 두 형태와 archive/delete/steer/queue 의 출력 계약이 빠져 있다. 아래 문단을 L46 ("Do not build a cron job around resuming yesterday's session.") 뒤에 삽입한다.

```markdown
Inside that window the control verbs are worth knowing. `aside session resume <id> "<prompt>"`
runs one turn and exits; `aside session resume <id>` with no prompt opens an interactive
session with `>`, `/session`, and `/exit`, which is not something a script wants.
`aside session steer <id> "<text>"` redirects the running turn and `aside session queue <id> "<text>"`
schedules an instruction after the current step; both print `ok` and exit, so neither
waits for the run. `aside session archive <id>` and `aside session delete <id>` clear a
finished or unwanted session.
```

7줄 추가. references 에는 행 상한이 없다.

## 편집 3 — scheduling.md, memory 안전 계약 (v2-40, v2-41, v2-42, v2-45, v2-46)

v2-45 는 실제 결함이다. 현재 L190-193 은 "scheduled job 이 `projects/` 에 durable facts 를 직접 쓸 수 있다" 고 말하는데, 공식은 memory 파일 직접 편집을 금지한다. Aside 가 스스로 관리하는 저장소를 밖에서 쓰면 consolidation 과 충돌한다.

```diff
 The layout is `MEMORY.md` (briefing), `USER.md`, `TAXONOMY.md`, plus `agent/`,
 `projects/`, `routines/`, `sites/`, `users/`, `episodic/`. It is a real directory
-under the account root, so you can read it yourself, and a scheduled job can write
-durable facts into `projects/` for later runs to recall.
+under the account root, so you can read it yourself - but never write into it. Aside
+owns these files and consolidates them on its own schedule; an outside write fights
+that. When a run should remember something durably, say so in the exec prompt and let
+the agent record it. Keep your own job bookkeeping in `jobs/` instead, which is yours.
```

같은 절의 CLI 조회 문단(L174-176)에 recall-first 와 `--json` 을 더한다.

```diff
-The same store is readable from the CLI: `aside memory path` prints the directory
-(`~/.aside/u/0/memory` on this account), `aside memory list` and `show <id>` browse
-entries, and `aside memory search <query>` runs the recall the agent uses.
+The same store is readable from the CLI: `aside memory path` prints the directory
+(`~/.aside/u/0/memory` on this account), `aside memory list` and `show <id>` browse
+entries, and `aside memory search <query>` runs the recall the agent uses. Add
+`--json` to `search` and `list` when the output feeds a program rather than a reader.
+Aside's own guidance is to recall before asking: check this store for prior context
+before putting the question to the user.
```

## 편집 4 — builtin-skills.md, skill preflight 와 고지 (v2-48, v2-52)

이 파일은 `scripts/refresh-builtin-summary.sh` 의 생성물이므로 **스크립트의 헤더 echo 를 고치고 재생성**한다. 파일을 직접 편집하면 다음 재생성에서 사라진다.

```diff
   echo "\`aside exec\` loads them on its own when the prompt names one. Codex can read any skill"
   echo "body with \`aside skills show <name>\`; \`aside skills list\` prints the subset marked"
   echo "\`CLI listed\` below."
+  echo
+  echo "Check this list before driving a site by hand with \`snapshot()\`: a matching skill usually"
+  echo "reaches an API and skips the DOM entirely. When you use one, tell the user which skill and"
+  echo "why."
```

그 다음 `bash aside-jun/scripts/refresh-builtin-summary.sh` 로 재생성하고, 34/16 카운트와 `CLI listed` 열이 유지되는지 확인한다.

## REJECT 로 남기는 것 (원장 근거)

- v2-12 (`aside -h`): 이미 더 포괄적인 "help 를 먼저 확인하라" 규칙이 repl-api.md 에 있음.
- Remote Control/MCP 세부 계약: 원장이 DEFER. 실측된 부분만 030 이 다룬다.
- 나머지 REJECT 행은 원장의 recommendation 열에 사유가 적혀 있으며 여기서 반복하지 않는다.

## 검증 (C)

- `wc -l aside-jun/SKILL.md` == 499.
- `rg -c 'daemon needs the GUI app' aside-jun/SKILL.md` == 0.
- `rg -c 'session archive' aside-jun/references/scheduling.md` >= 1, `rg -c 'session delete' …` >= 1, `rg -c '/exit' …` >= 1 (한 줄에 둘이 겹칠 수 있으므로 항목별로 센다).
- `rg -c 'never write into it' aside-jun/references/scheduling.md` == 1, 그리고 회귀 검사는 다중행으로: `rg -U -c 'can write\s+durable facts into' aside-jun/references/scheduling.md` == 0 (원문이 줄바꿈돼 있어 단일행 패턴은 지금도 0 이라 회귀를 못 잡는다).
- `rg -c -- '--json' aside-jun/references/scheduling.md` >= 1.
- `bash aside-jun/scripts/refresh-builtin-summary.sh` 성공, 출력에 "tell the user which skill" 포함, 34/16 유지.
- `git diff --check` 통과.
