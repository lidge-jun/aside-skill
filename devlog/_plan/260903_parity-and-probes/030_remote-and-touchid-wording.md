# 030 - wp3: Remote Control 과 Touch ID 문구를 프로브에 맞춘다 (diff-level)

대상: `aside-jun/SKILL.md` L351-354, `aside-jun/references/credentials.md` L74-76. 근거는 001_probe-remote-and-touchid.md 의 S9-R1..R4, S9-T1..T2.

## 왜 고쳐야 하나

두 문단 모두 "미검증" 을 근거로 쓰였는데, 이제 근거가 생겼다. Remote Control 쪽은 서술이 틀렸다: 403 을 "Pro/Max 플랜이라서" 로 읽었는데 그건 프로브가 뒷받침하지 않는다. 오늘 데몬 1.26.903.1631 에서 같은 명령이 성공하고, 실패 사유가 무엇이었는지는 미상으로 남는다. Touch ID 쪽은 결론이 옳지만 근거가 약했다 — 이제 데몬 술어를 인용할 수 있다.

---

## 편집 1 — SKILL.md L351-354 (S9-R1..R4)

```diff
-Remote Control exists on the same surface: `--host <id>`, `aside host list|use|status`,
-and `aside login --email` route a run to another machine on Pro and Max plans. On this
-account `aside host list` returned 403, so they are recorded here as present and
-unverified.
+Remote Control routes a run to another machine: `aside host list|use|status`, `--host <id>`
+on `exec` and `repl`, and `aside login` once, after which the local GUI app need not be
+running. `aside host list` answers locally here - `{"defaultHost":"local","hosts":[]}` - because no
+host is enrolled; the daemon reads that from `<account-root>/remote-control.json`, absent on
+this machine. Enrolling registers this desktop with Aside's API, so this skill has not
+tried it; whether a paid plan gates it is unknown.
```

4줄 → 6줄, 순증 2줄. SKILL.md 는 020 편집 후 499 이므로 2줄을 회수해야 한다. 회수 대상은 같은 파일의 verify 절(현재 L455-460, 위 hunk 적용 후 L457-462) 6줄을 4줄로 압축:

```diff
-The agent narrates its own success and is sometimes wrong. Confirm independently
-before reporting: re-open the page and read the status line, check the file
-yourself, run `dig` against the DNS record it claims to have set. Screenshots land
-under `~/.aside/u/<account>/sessions/<session>/tmp/` and are real files you can
-open. A first attempt can fail and a retry succeed, so ask for the final state
-rather than trusting the first report.
+The agent narrates its own success and is sometimes wrong. Confirm independently:
+re-open the page, check the file, run `dig` against the record it claims to have set.
+Screenshots land under `~/.aside/u/<account>/sessions/<session>/tmp/` as real files.
+A retry can succeed after a failure, so ask for the final state, not the first report.
```

원격 문단이 +2, verify 절이 -2 이므로 순증 0, SKILL.md 는 499 를 유지한다. 위 두 hunk 는 문자 그대로 적용 가능한 최종 형태이며, B 단계에서 실제 `wc -l` 로 확인한다.

## 편집 2 — credentials.md L72-77 (S9-T1, S9-T2)

"every unlock demands a live fingerprint" 도 함께 바꾼다: 프로브가 증명한 것은 매 unlock 이 아니라 `accountPasswordVerificationInterval` 주기의 비밀번호 재확인이다.

```diff
-agent-driven sign-in works normally. Turn it on and every unlock demands a live
-fingerprint, which an agent cannot supply, so a once-per-setup ceremony becomes a
-prompt that blocks every future run. Aside 1.26.822 notes that Touch ID is skipped
-after a passkey dialog; whether that removes the first-run handshake described here
-is unverified on 1.26.902, so keep the setting off until a probe shows otherwise.
+agent-driven sign-in works normally. Turning it on re-arms a gate an agent cannot pass.
+The daemon makes the mechanism concrete: `checkPasswordVerificationRequired` returns
+false immediately while `biometricUnlockEnabled` is false, and once the setting is on it
+re-arms a password re-verification every `accountPasswordVerificationInterval` days
+(30 on this account) - a prompt no non-interactive run can answer. Verified against
+daemon 1.26.903.1631. Aside 1.26.822 notes that Touch ID is skipped after a passkey
+dialog, but that is the OS passkey sheet, not the Apple Passwords first-run handshake
+described here, and no Touch-ID symbol survives in the daemon bundle, so it stays
+unverified and the setting stays off.
```

## 편집 3 — credentials.md, 프로브 포인터 한 줄

`PIN is a one-time setup. Biometrics is a permanent gate. Off is the working configuration.` 문단 **뒤**에 근거 경로를 남긴다(줄번호는 편집 2 로 이동하므로 텍스트 앵커를 쓴다).

```markdown
The reasoning behind that instruction, including the daemon predicate it rests on, is
in `devlog/_plan/260903_parity-and-probes/001_probe-remote-and-touchid.md`.
```

## 하지 않는 것

- `biometricUnlockEnabled` 를 켜서 실측하는 것: 사용자 금고 설정 변경이라 범위 밖. 사용자가 원하면 NEEDS_HUMAN.
- `POST /remote/hosts/enroll` 호출: 이 데스크톱을 원격 호스트로 서버에 등록하는 외부 상태 변경.
- 데몬 버전 핀 일괄 교체: 스킬 본문은 CLI 1.26.902.1732 기준이 맞고, 903 은 이 두 문단에서만 명시한다.

## 검증 (C)

- `wc -l aside-jun/SKILL.md` == 499.
- `rg -c '403' aside-jun/SKILL.md` == 0.
- `rg -c 'remote-control.json' aside-jun/SKILL.md` == 1.
- `rg -c 'checkPasswordVerificationRequired' aside-jun/references/credentials.md` == 1.
- `rg -c '1.26.903.1631' aside-jun/references/credentials.md` == 1.
- `rg -c 'is unverified on 1.26.902' aside-jun/references/credentials.md` == 0.
- `rg -c 'every unlock demands a live fingerprint' aside-jun/references/credentials.md` == 0.
- `rg -c 'the local GUI app need not be' aside-jun/SKILL.md` == 1.
- 설정 무변경 증거: `biometricUnlockEnabled` 가 여전히 false, `remote-control.json` 여전히 부재.
