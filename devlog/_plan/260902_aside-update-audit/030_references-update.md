# 030 - wp3: references 와 스크립트 갱신 (diff-level)

대상: `aside-jun/references/permissions.md`, `scheduling.md`, `repl-api.md`, `credentials.md`, `builtin-skills.md`, `scripts/refresh-builtin-summary.sh`. 줄 번호는 HEAD 959d7da 기준. 020 이 SKILL.md 에서 바꾼 주장을 references 가 반박하지 않도록 맞추는 단계다.

## 왜 이 순서인가

SKILL.md 가 "guard 는 즉시 deny, 기본은 full-access, save-sessions 는 true" 라고 말하는데 permissions.md 가 "There is no escape flag" 를, scheduling.md 가 "`--session` works for a quick follow-up" 을 유지하면 독자가 어느 쪽을 믿을지 정해야 한다. references 는 메커니즘 설명이 길어 SKILL 보다 늦게 고치되, 같은 goal 안에서 닫는다.

---

## permissions.md

### 편집 1 — L1-5 도입

"Why Aside CLI hangs, and what actually prevents it" → "Why Aside CLI denies or parks, and what actually prevents it". L3-4 의 "when a session hangs and you need to know whether a retry can help. It cannot." → "when a run skipped a step or parked, and you need to know whether a retry can help. Under `guard` it cannot; under `full-access` the step runs."

### 편집 2 — L6-27 "The mechanism" 뒤에 새 절 삽입

```markdown
## What changed in 1.26.902

The suspend path above is still in the daemon bundle (its strings are present in
1.26.902.1713); whether the Aside window still uses it was not probed. A CLI
session no longer reaches it under any `--permission` value. Measured on CLI
`1.26.902.1732` with daemon `1.26.902.1713`, guard config untouched
(`outsideRead`/`outsideWrite` both `ask`):

| Probe | Result | Log |
|---|---|---|
| `read_file` on a workspace file, default mode | `Permission denied: read '<path>' is blocked by policy` after 4.7s, run exits 0 | `evidence/probe-A-guard-readfile.log` |
| `write_file` to `/tmp` and to `~/.aside/u/0` in one run | outside denied by policy, inside `Successfully wrote`, run exits 0 | `probe-W-writefile.log` |
| `ask_user_question` | not in the session's tool catalog; the agent says so and exits 0 | `probe-C-askuser.log`, `probe-Q-askuser2.log` |
| `read_file` on the same workspace file with `--permission full-access` | contents returned in 4.2s | `probe-B-full-readfile.log` |
| `bash head` on the workspace file and `cat /etc/hosts` | both succeeded (`sandbox.enabled` false on this install) | `probe-D-bash-outside.log` |

The Sep 2 release note says it plainly: "permission / ask user question tool /
final confirm won't throw an error" (`evidence/aside-discord-changelog-260902.md`).
For a CLI session `ask` is downgraded to deny and the question tool is removed.

The new failure is quieter than the old one. A denied call returns an error string
the agent reads; it then either stops ("I did not try other tools") or finishes the
parts it could. Exit status is 0 either way, so a skipped step is visible only in
the transcript. That is why SKILL.md now opens the session instead of fencing the
prompt.

## The permission flag

```bash
aside exec --permission full-access "<prompt>"   # default recommendation
aside exec --permission guard "<prompt>"         # same as omitting the flag
aside exec --permission ask "<prompt>"           # accepted, but normalizes to guard on 1.26.902
```

`full-access` is the mode name GUI sessions carry in `state.db`
(`permission_mode`). From the CLI it let `read_file` reach a workspace path that
`guard` had denied (probe B); other tools and paths were not exercised, so treat
it as "the file tools are no longer fenced" rather than as a proof of parity with
the window. Say in the prompt what a read-only task must not touch and keep
Aside's own output under `~/.aside/u/0/`.

`guard` fits a task that must not be able to reach the workspace and can afford
a skipped step; check the transcript for `blocked by policy` afterwards.

`ask` is accepted by CLI 1.26.902 but normalizes to Guard, exactly like `guard`:
the help text says "--permission ask and --permission guard are the same", and
outside-root file calls fail fast with `blocked by policy` and do not suspend
(`evidence/probe-S4-suspension.log`). Genuine approval behaviour in the Aside window
was not verified by this probe. If a run does park on something else (a
credential handshake, a passkey), `aside session steer <id>` or `stop <id>` is the
way out.
```

### 편집 3 — L29-38 "The three proven classes" 표

제목을 "The three classes, as they behaved through 1.26.831" 로 바꾸고 표는 유지. 표 아래 한 문장 추가: "On 1.26.902 each of these returns an error instead; see above."

### 편집 4 — L57-70 "There is no escape flag"

제목 "There is no escape flag" → "Flags, then and now". 본문 첫 문장 앞에 "Through 1.26.831:" 를 붙이고, 문단 끝에 추가:

```markdown
1.26.902 added `--permission` (above) and removed `--session`. There is still no
timeout, no JSON output mode, and no auto-answer for a genuine approval prompt.
```

### 편집 5 — L155-237 "Granting a path on purpose"

절 머리 아래 한 문단 추가: "This is the narrow alternative to `--permission full-access`: use it when one directory must be reachable and the rest of the filesystem must not be. The steps are unchanged on 1.26.902." 그 외 유지. L228-233 "ask first when the scope is broad" 유지.

## scheduling.md

### 편집 1 — L21-45 "Sessions expire after 15 minutes"

- L21 제목 "Sessions expire after 15 minutes" → "Sessions expire after 15 minutes unless saved". L23 "CLI-created sessions are ephemeral." → "CLI-created sessions are ephemeral while `save-sessions` is off (the shipped default; this skill turns it on, below)."
- L41-42 "So `--session` works for a quick follow-up within the window and not for scheduling." → "So `aside session resume <id>` works for a quick follow-up within the window and not for scheduling. The `--session` flag itself was removed in 1.26.902."
- L65-69 "There is also nothing useful to stash… session ids are not." 문단: 첫 문장 앞에 "With `save-sessions` off," 를 붙이고 마지막 문장을 "Scripts and state files there are worth keeping; session ids are only worth keeping once the setting is on, and even then a fresh run per tick is simpler." 로.
- L36-39 검증 문단 뒤에 추가: "Re-verified on 1.26.902: the `9e5` constant and the `Session is pending purge` string are still in the daemon bundle."

### 편집 2 — L48-63 purge 쿼리 문단 뒤에 새 절

```markdown
## Keep CLI sessions on the chat list

`aside settings save-sessions true` puts CLI runs on the Aside chat list. Set it once
and leave it on; it is the default recommendation of this skill.

Measured on 1.26.902 (002_save-sessions-probe.md, S8):

| What | `save-sessions false` (shipped default) | `save-sessions true` |
|---|---|---|
| `~/.aside/u/0/settings.json` | `"cli": {"ephemeral": true}` | `"cli": {"ephemeral": false}` - the only file that changes |
| new CLI session row in `state.db` | `ephemeral = 1` | `ephemeral = 0` |
| `aside session list` | `ephemeral` | `persistent` |
| `aside.sessions.list()` | excluded | included |
| Aside window, Chats | not listed by policy, though the run made right before the flip was still showing after it | listed, with an unread dot (`evidence/probe-S3-aside-chat-list.png`) |
| 15-minute purge | applies once the session is terminal | never: the purge query has an explicit `ephemeral = true` predicate |

Existing rows are not rewritten, so sessions created before the flip keep their
ephemeral flag and their purge deadline. API and window do not agree on those:
`aside.sessions.list()` excluded the pre-flip baseline while the Chats list showed
it (`evidence/probe-S3-chat-list.log`), so the database flag is the persistence
classification and the sidebar is a separate exposure policy.

Whether a parked approval can be answered from the Chats list is still open. On
1.26.902 an outside-root file approval cannot park a CLI run through
`--permission ask`: it is the same mode as `guard` and denies, so no fresh
approval card could be produced (S8-Q4). The older
suspended rows are purge-pending and refuse `resume` and `steer`.

`aside session list` shows running, idle, interrupted, and aborted CLI sessions and
hides suspended ones regardless of this setting, so the `state.db` query in SKILL.md
stays the way to count parked runs.
```

### 편집 3 — L71-95 cron 예시

`aside exec "$(cat <<EOF` → `aside exec --permission full-access "$(cat <<EOF`. L95-96 "because a hung run never exits on its own" → "because a parked run never exits on its own".

### 편집 4 — L97-140 "Aside remembers on its own"

L100-101 뒤에 추가: "The same store is readable from the CLI: `aside memory path` prints the directory (`~/.aside/u/0/memory` on this account), `aside memory list` and `show <id>` browse entries, and `aside memory search <query>` runs the recall the agent uses."

### 편집 5 — L152-158 "Why the clauses matter more here"

"A prompt that invites a question produces a process that waits forever" → "A prompt that invites a question ends the run with the question unanswered, and a denied path is skipped without an error exit". 나머지 유지.

## repl-api.md

- L22-30 "Getting a page" 코드블록 뒤에 추가: "The CLI's own repl help mentions `getTabs()`; it is `undefined` on 1.26.902. `listBrowserTabs()` is the call."
- 서비스 글로벌 절(파일 하단, `applePasswords` 언급 위치)에 추가: "`applePasswords` does not enumerate through `Object.getOwnPropertyNames(Object.getPrototypeOf(...))` on 1.26.902 and can look absent; `typeof applePasswords` returns `object`. The `aside` global exposes `pdf`, `settings`, `projects`, `sessions`, `routines`, `channels`."

## credentials.md

L252-254 "Without the no-questions clause the agent would have called `ask_user_question` and the run would have sat silent until the shell timeout. The clause converted an unrecoverable hang into a clean, informative failure." → "On the build this ran on, without the no-questions clause the agent would have called `ask_user_question` and the run would have sat silent until the shell timeout. On 1.26.902 the tool is absent from CLI sessions, so the clause now prevents a question typed into chat that ends the run unanswered; either way it converts a dead end into a clean, informative failure."

L68 "**2. Leave "Unlock with Touch ID" OFF.**" 문단 끝에 추가: "Aside 1.26.822 notes that Touch ID is skipped after a passkey dialog. Whether that removes the first-run handshake described here is unverified on 1.26.902; keep the setting off until a probe shows otherwise."

L193 passkey 문단은 유지. Sep 2 "clipboard cleared after credential copy" (.824/.902) 는 L256 부근 "It routed around a passkey by itself" 뒤에 한 줄: "Since 1.26.824 the agent clears the clipboard after copying a credential, so a run that copied a password leaves nothing behind."

## builtin-skills.md

워크트리에 이미 재생성된 파일(34 top-level, `context-awareness` 추가)을 채택. 헤더 문장 "Only `aside exec` can load them. Codex cannot invoke one directly" 는 스크립트에서 생성되므로 스크립트를 고친 뒤 재실행.

## scripts/refresh-builtin-summary.sh

실측: `aside skills list` 는 `name<TAB>description` 11행을 출력하며(aside, google-accounts, google-docs, google-gmail, google-search, google-sheets, linkedin, Messages, notion, slack, youtube) 이것은 "repl-backed" 와 정확히 같은 집합이 아니다(twitter, chrome, captcha-solver 는 repl 글로벌이 있지만 list 에 없고, Messages 는 대문자). 따라서 REPL_BACKED 하드코딩을 대체하지 않고 **세 번째 열 `CLI listed`** 를 추가한다.

변경:

```bash
# after REPL_BACKED=...
# Names are lowercased; the CLI lists the iMessage skill as "Messages" while its
# builtin directory is "imessage", so that one is aliased.
CLI_LISTED=" $(aside skills list 2>/dev/null | awk -F'\t' 'NF>=2{n=tolower($1); if(n=="messages") n="imessage"; print n}' | tr '\n' ' ') "
```

두 루프의 `kind=` 판정 뒤에 (top 루프는 `top_rows+=`, site 루프는 `site_rows+=` — 아래는 top 루프 예시이고 site 루프도 같은 세 줄에서 변수명만 다르다):

```bash
  lname=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
  if [[ "$CLI_LISTED" == *" $lname "* ]]; then listed="yes"; else listed="-"; fi
  top_rows+="| \`$name\` | $kind | $listed | $d |"$'\n'
```

헤더 텍스트:

- "Only \`aside exec\` can load them. Codex cannot invoke one directly - name the skill in the exec prompt and let the Aside agent load it." → "\`aside exec\` loads them on its own when the prompt names one. Codex can read any skill body with \`aside skills show <name>\`; \`aside skills list\` prints the subset marked \`CLI listed\` below."
- 표 헤더 "| Skill | Backing | Purpose |" → "| Skill | Backing | CLI listed | Purpose |" (두 곳), 구분선 열 4개.
- "Generated by ... on $(date)" 줄에 `aside --version` 출력 추가: "from ... with CLI $(aside --version 2>/dev/null) on ...".

## README.md

L7-10 "and it also makes it easy to hang: a non-interactive `aside exec` cannot answer a permission prompt or a question, so it waits forever with no error output. This skill encodes the rules that avoid that." → "and it also makes it easy to lose work quietly: a non-interactive `aside exec` cannot answer a permission prompt or a question, so through 1.26.831 it waited forever, and since 1.26.902 it denies the call and moves on with exit 0. This skill encodes the rules that avoid both."

L121-129 "The skill leads with the failure mode, because it is silent and unrecoverable… No flag disables this, so the skill prevents it with a fixed prompt contract and a mandatory host timeout." → 두 문단을 "The skill leads with the failure mode, because it is silent either way. Through 1.26.831 a suspended run printed its tool-call line and then nothing; on 1.26.902 an outside-root file call is denied by policy and the run continues, so a skipped step shows only in the transcript. Both were verified against a live install. `--permission full-access` removes the deny for the paths a task names, and the fixed prompt contract plus a host timeout cover the rest." 로 교체.

L145-147 버전 핀 → "The skill was rebuilt against CLI `1.26.902.1732` and daemon `1.26.902.1713` on macOS (first built on 1.26.810 / 1.26.829)." L131-133 "it fails fast on a bad path instead of hanging" → "it throws on a bad path, where exec under `guard` skips it". L135-137 "the grant-run-restore sequence for the rare task that needs an outside path" → "the `--permission` flag and the narrower grant-run-restore sequence".

## 검증 (C)

- (wp2 B 리뷰에서 추가) SKILL.md 의 첫 클로즈가 full-access 기본과 맞도록 "Write and edit files only under ~/.aside/u/0/. Read other local paths only when this prompt names them, and never modify them." 으로 바뀌었다. 같은 클로즈 사본 3곳 — scheduling.md:87-88, deep-research.md:169-170, permissions.md:217(grant 변형은 guard 전용이므로 유지하되 "guard 에서만" 명시) — 를 동일하게 치환. `rg -n "never the file tools" aside-jun` 는 SKILL.md 의 guard 대체 클로즈와 permissions.md grant 절에만 남는다.
- `rg -n -- '--session' aside-jun/references`: 모든 hit 가 "removed" 문맥 — scheduling.md "flag itself was removed", permissions.md "removed `--session`", refskill-aside.md:41 은 공식 v1 help 사본이라 유지하고 같은 줄 주석을 `# removed in 1.26.902` 로 바꾼다. `rg -n -- '--session' aside-jun/references | rg -v 'removed'` 0건.
- `rg -n 'no escape flag' aside-jun` 0건.
- `bash aside-jun/scripts/refresh-builtin-summary.sh` 성공, 출력 파일에 "CLI listed" 열과 34/16 카운트.
- `rg -n 'save-sessions' aside-jun/references/scheduling.md` ≥ 2.
- `rg -n 'getTabs' aside-jun/references/repl-api.md` 1건(정정 문장).
