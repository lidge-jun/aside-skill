# 030 - Ship (wp1, docs-only)

## 산출물
- 000_research.md — 버전 3종, claim ledger S1~S7, 라이브 프로브 표
- 010_skill-recommendations.md — P0 9건 / P1 9건 / P2 5건, 적용 순서 wp2~wp4
- evidence/ — Discord #announcements 24포스트 원문, docs.aside.com components/native changelog, 데몬 aside-browser 스킬 문자열(831/902), probe 로그 6건, Discord 스크린샷
- aside-jun/references/builtin-skills.md 재생성 (33→34, +context-awareness) — 워크트리 변경, 미커밋

## 하지 않은 것 (scope OUT)
- SKILL.md / references 본문 수정 없음 (권고만)
- Discord 포스트/반응 없음 (서버 가입은 발생 — 부수효과 기록)
- git commit/push 없음
- Aside.app 은 이미 최신(1.0.825.1)이라 재시작 불필요

## 검증 명령 (C)
- `aside --version` == 1.26.902.1732
- `curl -s 127.0.0.1:21420/` version == 1.26.902.1713
- evidence/ 파일 존재 + 000/010 에 S1~S7 라벨 존재
- refresh-builtin-summary.sh 재실행 시 idempotent (diff 없음)

## FSM 메모
- 처음 700_projects(부모 cwd)에서 arm 했으나 aside-skill 이 중첩 git 저장소라 SOURCE-DELTA-01 이 devlog 변경을 못 봄 → reset 후 aside-skill cwd 로 재-arm (Phase 3 rule: 독립 프로젝트로 취급).
- goalplan slug: aside-cli-aside-jun-2026-09-02-cli-3-discord-ann

## evidence/ 목록
| 파일 | 출처 |
|---|---|
| aside-discord-changelog-260902.md | S1 aside exec (grok-4.6) Discord #announcements |
| (discord-announcements-sep2.jpeg) | S1 스크린샷 — PII 로 커밋 제외, /tmp/aside-audit/withheld/ |
| docs-aside-com-components-changelog.md | S2 curl |
| aside-browser-1.26.831.1513.md / -1.26.902.1713.md | S5 데몬 바이너리 |
| probe-{A,B,C,D,Q,W}-*.log | S7 라이브 프로브 |
