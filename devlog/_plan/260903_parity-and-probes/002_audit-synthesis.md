# 002 - A 단계 감사 종합 (round 1, reviewer Archimedes / gpt-5.6-sol high)

판정 FAIL, 블로커 6. 전부 수용. 두 갈래로 갈린다: (a) 프로브가 증명한 것보다 강하게 쓴 문장 3건(#1 #2 #3), (b) 실행하면 실패하거나 앵커가 어긋나는 검증·앵커 4건(#4 #5 #6, +NIT 7).

| # | 블로커 | 처리 |
|---|---|---|
| 1 | 403 의 원인을 "미등록 계정에 대한 서버 거절 + 데몬 업데이트" 로 단정. probe-R2 는 버전 변화와 현재 동작만 증명 | 수용. 001 과 030 의 인과 문장을 "무엇이 관찰됐는지" 로 낮춘다: 두 관측(어제 403, 오늘 성공) 사이에 데몬이 바뀌었다는 사실만 진술하고, 403 의 서버측 사유는 미상으로 남긴다. 플랜 게이팅은 이미 미결정 |
| 2 | credentials.md L72-74 "every unlock demands a live fingerprint" 가 남음. 프로브는 30일 주기 password 재확인만 증명 | 수용. 030 의 교체 범위를 L72-77 로 넓혀 그 문장까지 데몬 술어에 맞게 바꾼다 |
| 3 | "remote host does not need the GUI app" / "without the local app" 이 공식(`not running locally`)보다 강함 | 수용. "the local GUI app need not be running" 으로 한정 |
| 4 | `rg -c 'session archive|session delete|/exit'` >= 3 는 실패 (제안 문단에서 2줄) | 수용. 항목별 검사로 분해 |
| 5 | `rg -c 'can write durable facts into'` == 0 는 지금도 0 (원문이 줄바꿈돼 있음) → 회귀를 못 잡음 | 수용. `rg -U` 다중행 패턴으로 교체 |
| 6 | 030 의 credentials.md L80 앵커가 빈 줄이고, 앞 교체 후 이동함 | 수용. 줄번호 대신 텍스트 앵커("PIN is a one-time setup.")로 지정 |

NIT 처리: #7 줄 산술은 맞으나 030 의 diff 를 문자 그대로 적용하면 500 이 되므로 최종 hunk 를 코드블록에 확정 형태로 적는다(수용). #9 v2-03 인용에 `SKILL.md:225-231` 추가(수용). #11 040 에 check-wp4.sh 본문을 diff-level 로 명시(수용). #8 #10 은 확인 결과 보고이므로 조치 없음.

재감사는 같은 리뷰어에게 이 문서와 변경 요약을 넘겨 진행한다.

## round 2 (FAIL, 잔여 3)

| # | 잔여 | 처리 |
|---|---|---|
| 1 | credentials 교체가 L73 에서 시작해 "Turn it on and every unlock demands a live" 를 남기고 문장이 깨짐 | 수용. 제거 범위를 현재 L72 부터로 넓혀 문장을 통째로 교체 |
| 2 | 020 의 "a remote host does not [need the GUI app]" 이 원격 호스트 자체를 오해시킬 수 있음 | 수용. "for remote-host commands it need not be" 로 한정 |
| 3 | check-wp4.sh 가 020/030 검사를 다 담지 못함 (`<=499`, credentials 버전 인용 누락, builtin 재생성 미실행, 설정 무변경 미확인) | 수용. `==499`, 데몬 버전 인용 카운트, 재생성 후 동일성 diff, `remote-control.json` 부재 + `biometricUnlockEnabled=false` 확인 추가 |

확인 사항: 줄 산술 020 (+1-1), 030 (+2-2) 로 499 유지, 403 인과 제거, session/memory/앵커/v2-03 인용 수정은 모두 통과.
