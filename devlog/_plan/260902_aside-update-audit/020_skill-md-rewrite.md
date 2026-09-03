# 020 - wp2: SKILL.md 핵심 재작성 (diff-level)

대상 파일: `aside-jun/SKILL.md` (423줄, 상한 500). 줄 번호는 2026-09-03 HEAD 959d7da 기준. B 단계에서 아래 블록을 순서대로 치환한다. 근거 라벨 S1~S7 은 000_research.md, S8 은 002_save-sessions-probe.md.

## 왜 이렇게 자르나

1.26.902 에서 CLI 의 실패 양상이 "행" 에서 "즉시 deny 후 조용한 누락" 으로 바뀌었다(S7 probe A/W/C). 제1 규칙 절은 이 사실을 중심으로 다시 쓰고, 새 `--permission full-access` 를 기본으로 올린다(001 결정 2). `--session` 플래그는 사라졌으므로 `aside session resume|steer|queue|stop` 로 바꾼다(S6). 표면 선택 절은 공식 v2 와 반대라는 점을 override 로 명시한다(001 결정 1).

---

## 편집 1 — L13-110 "The one rule that matters" 전체 교체

교체 후 텍스트:

```markdown
## The rule that matters

An `aside exec` run is non-interactive: an approval prompt, a question, or a Touch
ID gesture has no one to answer it. What that costs changed in CLI `1.26.902`.

Through `1.26.831` the daemon suspended the run and waited. The tool-call line
printed, then silence until an external timeout killed the process. On
`1.26.902.1732` (daemon `1.26.902.1713`) the same calls fail fast, measured
rather than assumed:

| Cause | through 1.26.831 | 1.26.902, default `guard` |
|---|---|---|
| `write_file` outside `~/.aside/u/0/` | hung indefinitely | `Permission denied: write '<path>' is blocked by policy` in ~5s; run continues |
| `read_file` outside the allowed roots | hung the same way | `Permission denied: read '<path>' is blocked by policy` in ~5s; run continues |
| `ask_user_question` | rendered, then hung | tool absent from the CLI catalog; the agent reports "no such tool" and exits 0 |

Evidence: `devlog/_plan/260902_aside-update-audit/evidence/probe-{A,W,C}-*.log`.

The failure changed shape, not severity. A deny is an error the agent reads and
routes around: in one probe it "did not try other tools", in another it wrote the
inside file and skipped the outside one, and both runs exited 0. Nothing in the
exit status says a step was skipped. The risk is now **silently incomplete
work**, and the prompt clauses below exist so the agent never picks a path that
gets denied.

The guard config itself is unchanged:

```json
{"readableRoots":[],"writableRoots":[],"outsideRead":"ask","outsideWrite":"ask"}
```

`ask` is what the Aside window is configured with; whether it still suspends there
was not probed. A CLI session downgrades it to deny.

`bash` never went through that check. It runs under a `sandbox-exec` Seatbelt
profile that prints `Operation not permitted` when it blocks. With `sandbox.enabled`
false on this install, `bash` read a workspace file and `/etc/hosts` in one probe,
so treat its reach as configuration-dependent rather than as a rule.

### Open the session instead of fencing the prompt

`1.26.902` added `--permission ask|guard|full-access`. **Use `full-access` by default
for exec runs:**

```bash
timeout 300 aside exec --permission full-access "<prompt>"
```

With it the file tools reach paths that `guard` denies (probe B: `read_file` on
the same workspace file that probe A had blocked returned its contents in 4.2s),
so the skipped-step failure goes away for the paths a task names. It opens the
session to whatever the daemon process can reach, so a read-only task has to say
in the prompt what it must not touch, and the clause that keeps Aside's own output
under `~/.aside/u/0/` stays.

`guard`, the default when the flag is omitted, fits a task that must not be able
to touch the workspace at all and can afford a skipped step. `ask` is accepted by
CLI 1.26.902 but normalizes to `guard` (the help text says so, and two probes with
it were denied the same way, S8-Q4); it does not suspend from a CLI. The older
recipe that widens the roots in settings for one directory still works and remains
the narrow alternative in [references/permissions.md](references/permissions.md).

### Timeouts still matter

There is no timeout option. A run can still park on a passkey gesture or a
credential-manager handshake, and it can simply take long.
Always run under a host deadline:

```bash
timeout 300 aside exec --permission full-access "<prompt>"
```

A fired timeout kills the CLI, not the work already done: files written,
downloads, form submissions, messages sent all stand. **Inspect the real state
before retrying**, or a rerun duplicates a side effect.

Before letting the timeout fire, reach the run. The id is on the first line the
CLI prints (`created new session: <id>`). `aside session steer <id> "report what is blocking you and stop"`
injects an instruction into a running session and `aside session stop <id>`
ends it cleanly.

A run that did suspend survives as `status: suspended` with `suspension.kind` of
`approval` or `ask-user-question`. `aside session list` does not show those: on
2026-09-02 it listed the idle, interrupted, and aborted CLI sessions and none of
the suspended rows present in `state.db` (S7). Read the database directly:

```bash
python3 -c "import sqlite3,json;c=sqlite3.connect('file:$HOME/.aside/u/0/state.db?mode=ro',uri=True);\
print([(r[0], json.loads(r[1])['kind']) for r in c.execute(\
\"select id,suspension from sessions where status='suspended'\")])"
```

A growing count means prompts are still tripping the approval path. On 1.26.902
the CLI cannot create a new one: `--permission ask` is documented as the same
mode as `guard` and denies instead of parking (S8-Q4). The rows that remain are
older builds' leftovers; `aside session resume` and `steer` refuse them with
`Session is pending purge`, and `aside.sessions` in repl has no approve or answer
method, so clear them yourself when they matter.

Set `aside settings save-sessions true` once. It flips `cli.ephemeral` in
`~/.aside/u/0/settings.json` to `false`, so every later CLI session is created
persistent: it appears in `aside session list` as `persistent`, in
`aside.sessions.list()`, and in the Aside window's Chats list, and it is exempt from
the 15-minute purge (S8-Q1..Q5). Details in
[references/scheduling.md](references/scheduling.md).

Read [references/permissions.md](references/permissions.md) for the mechanism,
the exact roots, and the settings-level grant.
```

## 편집 2 — L112-144 "Choosing a surface" 머리 교체

L114-117 코드블록과 L119 앞에 아래를 넣고, L136-141 의 버전 핀 문장을 갱신한다.

```markdown
## Choosing a surface

```
repl  -> your own tool: you drive the browser, one call, deterministic
exec  -> a subagent: hand Aside's agent a task and read its report
```

This is a deliberate departure from Aside's own `aside-browser` skill, which since
`1.26.902` says to hand work to Aside by default and reach for JavaScript only when
the user names Playwright. The split here stays because a repl call is one
session with a beginning and an end, it throws immediately on a bad path instead
of skipping, and every snapshot and screenshot lands in Codex's hands as evidence.
Delegation buys judgment and costs verifiability, so it is used where judgment is
the point.
```

L139-140: "verified against CLI `1.26.810.1915` with daemon `1.26.829.1514`" → "verified against CLI `1.26.902.1732` with daemon `1.26.902.1713` (signed-in discord.com and aside.com tabs on 2026-09-02)".

## 편집 3 — exec 절 (L191-287)

- L205-212 Assembled 예시: `timeout 300 aside exec "` → `timeout 300 aside exec --permission full-access "`.
- L214-219 첫 클로즈 설명 문단: "Reading is no safer than writing here" 유지, 마지막 문장 "which is precisely the move that deadlocks a CLI run" → "which under `guard` is denied and skipped, and under `full-access` is unnecessary".
- L221-233 세 번째 클로즈 인용문: "a deadlock in a non-interactive run: there is no last resort, only a parked process" → "in a non-interactive run there is no last resort: the tool is absent from the CLI catalog and a question typed into chat ends the run". 인용 블록의 "The CLI cannot answer `ask_user_question`, an approval prompt," → "The CLI has no `ask_user_question` tool and cannot answer an approval prompt,".
- L244-246 `-m` 문단 교체:

```markdown
Omit `-m` by default: passing a model flips `strictModelSelection` and Aside's own
settings pick the model. When a specific model is required, use the slash form
with the provider in front, `-m opencodex/xai/grok-4.6`. The split form
`-m xai/grok-4.6 -p opencodex` fails.
```

- L250-253 poll 예시: `timeout 300 aside exec '<prompt>'` → `timeout 300 aside exec --permission full-access '<prompt>'`.
- L255-256: "that is a hang rather than slow work" → "that is a parked run rather than slow work; `aside session steer` it before the timeout fires".
- L263-273 옵션 + `--session` 두 문단 교체:

```markdown
Useful options: `--permission full-access` (above), `--effort ultrabrowse` for flows that
must recover from surprises on their own, and `--log-dump <path>` to record every
agent event as JSONL (re-verified on 1.26.902, `evidence/probe-L-log-dump-summary.log`:
`agent_start`, `turn_start`, `message_*`, `toolcall_*` and `tool_execution_*` events).

The `--session` flag is gone as of `1.26.902`; passing it prints the help text. A
healthy run continues with `aside session resume <id> "<prompt>"`, a running one is
redirected with `aside session steer <id> "<text>"` or handed a follow-up with
`aside session queue <id> "<text>"`. Re-pass `-m` on resume: without it the daemon
reads the model id stored in the session, which for a routed model comes back
provider-less and fails with `<model> is not available`.

Resume works for about 15 minutes. CLI sessions are created ephemeral and the
daemon purges them after that (`EPHEMERAL_SESSION_RETENTION_MS = 9e5`, unchanged in
1.26.902), so a later resume fails with `Session is pending purge`. That applies to
sessions created while `save-sessions` is off. With it on (above) new CLI sessions
are persistent and the purge query's `ephemeral = true` predicate skips them
(S8-Q5); a resume past 15 minutes on such a session has not been timed yet, so treat
it as expected rather than proven. For anything scheduled or
long-running, carry state in files under `~/.aside/u/0/` and let Aside's memory
store hold what is generally true; `aside memory search <query>`, `list`, `show`, and
`path` read that store from the CLI. See
[references/scheduling.md](references/scheduling.md) before putting `exec` in cron
or a LaunchAgent.
```

- L275-281 Scheduling 문단: "Session ids are not worth saving to disk, because they stop resolving after the purge window." → "Session ids are not worth saving to disk while `save-sessions` is off, because they stop resolving after the purge window; with it on they persist, but a fresh run per tick is still the simpler design."
- L283-287 계정 문단 뒤에 한 문단 추가:

```markdown
Remote Control exists on the same surface: `--host <id>`, `aside host list|use|status`,
and `aside login --email` route a run to another machine on Pro and Max plans. On this
account `aside host list` returned 403, so they are recorded here as present and
unverified.
```

## 편집 4 — L353-376 "What Aside already knows"

L358-359 "**Only exec can load them.** You cannot invoke one directly; name it in the prompt and the agent picks it up." → 

```markdown
**exec loads them on its own**: name the skill in the prompt and the agent picks it
up. Codex can also read one before delegating: `aside skills list` prints a
CLI-listed subset (11 names on 1.26.902, `evidence/probe-K-skills-list.log`; not
identical to the repl-backed set) and
`aside skills show <name>` prints any skill's body, which is how to learn what a
skill will do or to drive its repl global yourself.
```

L362 예시: `--permission full-access` 추가. L371-372 뒤에 추가:

```markdown
`aside skills install` copies Aside's own `aside-browser` skill into a Codex, Claude Code,
Cursor, or OpenCode skills directory. Do not run it here: this skill replaces it,
and two skills in one trigger space route unpredictably.
```

## 편집 5 — L389-408 "When something goes wrong"

- L391-394: "**Silence after a tool call.** That is a hang. Let the timeout end it, then check the prompt for a path outside…" → "**Silence after a tool call.** The run is parked, most often on a credential or passkey handshake. Try `aside session steer <id>` first, let the timeout end it otherwise, then check the prompt for a request that invites a question. Re-running with `--log-dump <path>` records every agent event as JSONL and shows which call parked."
- L401-403 mcp: 문장 뒤에 "Since `1.26.902` it can create and run agent tasks for a connected client (S1)." 추가.
- L396-399 401 오류: "Pass a working model once with `-m`" → "Pass a working model once with `-m provider/model`".

## 편집 6 — L410-423 Boundaries

L417-420 "Widening the roots is the exception…" → 

```markdown
`--permission full-access` is the normal way to let a run reach a workspace path;
tell the user a run was opened when the task touches anything outside Aside's root.
The settings-level root grant is the narrow alternative for one directory; keep it
to that directory, restore it in the same turn, and say what was granted.
```

## 검증 (C)

- `wc -l aside-jun/SKILL.md` < 500.
- `rg -n -- '--session' aside-jun/SKILL.md` 는 "The `--session` flag is gone" 한 곳만.
- `rg -n '1\.26\.(810|829)' aside-jun/SKILL.md` 0건. `rg -c '1\.26\.831' aside-jun/SKILL.md` 는 비교 표 절의 2건(문단 + 표 헤더).
- `rg -c 'full-access' aside-jun/SKILL.md` ≥ 6.
- `rg -n 'Hangs\.' aside-jun/SKILL.md` 0건.
