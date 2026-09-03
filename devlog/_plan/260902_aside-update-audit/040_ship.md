# 040 - wp4: 검증, 커밋, 푸시, 미러 (diff-level)

코드 변경 없음. 020/030 의 결과를 하나의 커밋 단위로 닫는다. 사용자가 이 goal 에 한해 push 를 사전 승인했다(001 결정 4).

## 순서

1. 검증. 020/030 의 "검증 (C)" 블록을 전부 실행하고 출력을 `evidence/ship-checks.log` 에 남긴다. `wc -l aside-jun/SKILL.md` < 500.
2. PII 스캔. `rg -n 'sk-|api[_-]?key|Bearer |password.*=|accounts\.json|models\.json' aside-jun devlog/_plan/260902_aside-update-audit` 결과에서 파일명 언급(허용) 외에 실제 값이 없어야 한다. 실행 결과: 자격증명 형태 0건. `evidence/aside-discord-changelog-260902.md` 의 계정 핸들/이메일 줄은 redact. Discord 창 스크린샷(`discord-announcements-sep2.jpeg`)은 사용자 핸들과 다른 서버 아이콘이 보여 **커밋에서 제외**하고 `/tmp/aside-audit/withheld/` 에 보관; 텍스트 전사본이 같은 근거를 담는다.
3. devlog 이동은 하지 않는다. 이 유닛(260902_aside-update-audit)은 `_plan/` 에 남기고, 후속 parity ledger 재대조가 붙을 수 있다.
4. 커밋. 두 개로 나눈다:
   - `[agent] docs: aside-jun follows Aside CLI 1.26.902 (deny semantics, --permission, session subcommands, save-sessions)` — aside-jun/ 과 README.md.
   - `[agent] docs: audit unit 260902 with Discord/docs evidence and save-sessions probe` — devlog/_plan/260902_aside-update-audit/.
5. 푸시. `git push origin main`. 결과(`main -> main`, 새 SHA)는 tracked 트리 밖 `.codexclaw/evidence/<session>/push.log` 에 남긴다(.codexclaw 는 gitignore). 거부되면 BLOCKED 로 보고하고 재시도하지 않는다.
6. 미러. `rsync -a --delete aside-jun/ ~/.codex/skills/aside-jun/` 후 `diff -rq aside-jun ~/.codex/skills/aside-jun` 가 빈 출력. `/Users/jun/Developer/new/.agents/skills` 에 aside-jun 이 없음을 확인(있으면 같은 rsync).
7. goalplan. `cxc loop meet-criterion` c-2/c-3/c-4 에 위 로그 경로를 evidence 로 기록. c-1 은 wp1 D 에서 이미 met.

## 검증 (C)

- `git status --short` 빈 출력 (builtin-skills.md 의 미커밋 변경 포함해 전부 커밋됨).
- `git log origin/main -1 --format=%H` == `git rev-parse HEAD`.
- `diff -rq aside-jun ~/.codex/skills/aside-jun` 빈 출력.
- `cxc loop validate --slug update-the-aside-jun-skill-repo-users-jun-develo` 통과.
