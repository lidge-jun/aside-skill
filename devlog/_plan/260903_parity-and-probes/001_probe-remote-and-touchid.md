# 001 - Remote Control 과 Touch ID 라이브 프로브 (S9)

2026-09-03 기준 CLI 1.26.902.1732 / 데몬 **1.26.903.1631**. 어제(09-02) 감사에서 "있음, 미검증" 으로만 적어둔 두 항목을 읽기 전용으로 확인했다. 설정은 하나도 바꾸지 않았다.

## Remote Control: 403 은 사라졌다, 그리고 그 사이 데몬이 바뀌었다

어제 `aside host list` 가 403 을 뱉었다. 오늘 같은 명령이 exit 0 으로 `* local (this machine)` 한 줄을 돌려준다. 두 관측 사이에 확실히 달라진 것 하나는 데몬이다. `~/Library/Application Support/Aside/AsideDaemon/mac-arm64/` 에는 이제 `1.26.903.1631` 하나만 남아 있고, `/health` 가 그 버전으로 07:41 에 새로 뜬 프로세스를 보고한다. 다만 프로브가 증명하는 것은 버전 변화와 현재 동작까지다. 어제의 403 이 서버의 어떤 판단이었는지, 그리고 새 빌드가 그 호출 자체를 하지 않게 된 것인지 서버 응답이 달라진 것인지는 이 프로브로 가릴 수 없다. 확실한 것은 지금 이 명령이 원격 API 없이 로컬로 답한다는 사실이다.

`--json` 으로 보면 더 분명하다. `{"defaultHost":"local","hosts":[]}` — 목록에 찍히는 `local` 은 서버에서 받아온 항목이 아니라 합성된 행이고, 원격 호스트는 0개다. 즉 "Remote Control 이 켜졌다" 가 아니라 "물어볼 원격 호스트가 없어서 로컬만 답한다" 가 맞는 서술이다.

등록 경로는 데몬 바이너리에 그대로 있다. 상태는 계정 루트의 `remote-control.json` 에 `{enabled, hostId?}` 로 저장되고, 파일이 없으면 `readRemoteControlState()` 가 `{enabled:false}` 를 돌려준다. 이 머신에는 그 파일이 **없다** — Remote Control 을 한 번도 켠 적이 없다는 뜻이다. 켜는 순간 `POST /remote/hosts/enroll` 이 이 데스크톱을 원격 호스트로 등록하는데, 그건 외부 상태 변경이라 이번 범위(읽기 전용)에서 하지 않았다. 그래서 **플랜 등급이 추가로 필요한지는 이 프로브로 결정되지 않는다**. 데몬 쪽에는 플랜을 검사하는 로컬 술어가 없고, 게이팅이 있다면 서버의 enroll 뒤에 있다.

## Touch ID: 현재 지침이 맞다, 근거는 술어 그 자체

`references/credentials.md` 는 "Unlock with Touch ID 를 꺼두라" 고 말하면서 1.26.822 릴리스 노트("passkey 다이얼로그 뒤 Touch ID 생략")를 미검증으로 남겨뒀다. 데몬을 열어보니 지침이 옳다는 근거가 코드에 있다:

```js
if (settings.accountPasswordVerificationInterval <= 0 || !settings.biometricUnlockEnabled) return false;
```

`biometricUnlockEnabled` 가 첫 번째 술어다. 꺼져 있는 동안 데몬은 즉시 빠져나가고 비밀번호 재확인을 요구하지 않는다. 켜면 `accountPasswordVerificationInterval` (이 계정은 30일) 마다 재확인이 되살아나는데, 그 재확인이야말로 비대화형 exec 이 답할 수 없는 프롬프트다. 현재 설정은 `biometricUnlockEnabled=false`, `agentAccessPolicy=always` 로 확인했고 건드리지 않았다.

1.26.822 노트 자체는 이 빌드에서 확인도 반박도 안 된다. `Touch ID`, `touchId`, `LAContext`, `skipBiometric` 모두 0 히트라 대응하는 심볼이 남아 있지 않다. 게다가 그 노트가 말하는 순간(OS passkey 시트)과 credentials.md 가 경고하는 순간(Apple Passwords 최초 credential-exchange 핸드셰이크)은 서로 다른 지점이다. 후자의 헬퍼는 여전히 번들에 들어 있다.

더 확정하려면 사용자 금고에서 `biometricUnlockEnabled` 를 실제로 켜봐야 하는데 이건 사용자 결정 사항이라 **NEEDS_HUMAN** 으로 남긴다.

---

## 기술 참조

### 근거 원장 (S9)

| 라벨 | 질문 | 명령 / 조사 | 증거 파일 | 결론 |
|---|---|---|---|---|
| S9-R1 | `aside host` 표면은 무엇인가 | `aside host --help|list|status|list --json` | `evidence/probe-R1-host.log` | 하위 명령 list/use/status. list 는 exit 0, `hosts:[]` 에 `defaultHost:local`. |
| S9-R2 | 어제 403 과 오늘 성공 사이에 무엇이 달라졌나 | 데몬 버전 비교 + `/health` + 바이너리 심볼 | `evidence/probe-R2-remote-control.log` | 데몬이 1.26.902.1713 → 1.26.903.1631 로 자동 갱신(오늘 07:41)됐고, 현재 `host list` 는 로컬로 답한다. 403 의 서버측 사유는 **미상**. |
| S9-R3 | 이 머신에 Remote Control 이 켜져 있나 | `<accountRoot>/remote-control.json` 존재 확인 | 같은 로그 | 파일 없음 → `{enabled:false}`. 한 번도 활성화된 적 없음. |
| S9-R4 | 플랜(Pro/Max) 게이팅이 있나 | 데몬 바이너리에서 플랜 술어 탐색 | 같은 로그 | 로컬 술어 없음. enroll 은 서버 호출이라 미실행 → **미결정**. |
| S9-T1 | Touch ID 를 꺼두라는 지침이 아직 맞나 | `checkPasswordVerificationRequired` 술어 + 설정 읽기 | `evidence/probe-T1-touchid.log` | 맞다. `biometricUnlockEnabled` 가 재확인 프롬프트의 첫 술어. 현재 false. |
| S9-T2 | 1.26.822 완화가 실효인가 | Touch ID 계열 심볼 검색 | 같은 로그 | 심볼 0 히트, 게다가 다른 지점(passkey 시트 vs credential-exchange 핸드셰이크). 미검증 유지. |

### Remote Control 내부 경로 (1.26.903.1631)

```text
remoteControlStatusSchema = enum[disabled, connecting, connected, errored]
remoteControlStateSchema  = { enabled: boolean, hostId?: uuid }
state file                = <accountRoot>/remote-control.json
readRemoteControlState()  -> { enabled: false } when absent
enroll                    -> POST <ASIDE_API>/remote/hosts/enroll   { localAccountId, device }
refresh                   -> POST <ASIDE_API>/remote/hosts/refresh  { hostId, localAccountId, device }
disable                   -> POST <ASIDE_API>/remote/hosts/disable  { hostId }
connect                   -> wss <ASIDE_API>/remote/hosts/<hostId>/connect
requireDevice()           -> Error "Remote Control requires a registered desktop device"
assertLoopbackOrHttps()   -> Error "Remote Control relay must be HTTPS outside loopback"
```

### 스킬에 반영할 문장

- SKILL.md 의 "`aside host list` 가 403 을 냈으므로 present-and-unverified" 문단은 사실이 아니게 됐다. 데몬 1.26.903 에서 `host list` 는 성공하고 원격 호스트가 0개라고 답한다. 등록 전에는 `local` 만 나오며, 등록(enroll)은 이 데스크톱을 원격 호스트로 서버에 올리는 외부 상태 변경이라 시도하지 않았다고 적는다.
- credentials.md 의 Touch ID 문단은 유지하되, "미검증" 대신 데몬 술어를 근거로 제시하고 1.26.822 노트는 범위가 다른 별건으로 분리한다.

### 버전 주의

데몬이 하루 만에 902 → 903 으로 올라갔다. 스킬 본문의 버전 핀은 CLI `1.26.902.1732` 기준으로 쓰여 있고 동작 규칙은 그대로 유효하지만, 이번 두 문단만 데몬 `1.26.903.1631` 로 명시한다.
