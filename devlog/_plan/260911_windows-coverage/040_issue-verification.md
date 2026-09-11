# 040 - 공개 이슈 2건 실측 검증과 반영 계획

`lidge-jun/aside-skill` 의 열린 이슈 두 건이 해결됐는지 확인했다. **둘 다 아직 살아 있다.**
원래 `mac-arm64` 로 신고됐는데 Windows CLI `1.26.906.1630` 에서도 재현되므로
macOS 특유의 문제가 아니라 플랫폼 무관 데몬 결함이다.

다만 "같은 결과" 는 아니다. 이슈 2 는 `page.screenshot({ path })` 도 ENOENT 로 죽는다고 적었는데
Windows 에서는 그 호출이 **성공한다.** 아래 4절이 그 경계다.

## 이슈 1 - `locator.screenshot()` 가 `Invalid parameters` 를 던진다

```
const p = await openTab("https://example.com");
const loc = p.locator("h1");
await loc.screenshot({ type: "png" });      -> LOCATOR_SHOT_ERR=Invalid parameters
const bb = await loc.boundingBox();
await p.screenshot({ type: "png", clip: bb }); -> CLIP_SHOT=ok bytes=241
```

우회 경로가 실제로 동작한다. 즉 "요소 스크린샷을 못 찍는다" 가 아니라
"locator 경유 호출만 깨진다" 이다.

## 이슈 2 - 세션 디렉터리가 미리 만들어지지 않는다

신고서는 `tmp/` 가 없다고 적었는데, 실측은 그보다 넓고 동시에 **좁다.**

```
PWD=C:\Users\super\.aside\u\0\sessions\2026-09-11_0wIMAK9qtIq9mP8v
ENTRIES=[]
TMP_WRITE_ERR=ENOENT: ... \tmp\probe.txt
ART_WRITE_ERR=ENOENT: ... \artifacts\probe.txt
```

넓은 쪽: 세션 디렉터리가 **완전히 비어 있다.** `tmp/` 뿐 아니라 `artifacts/` 도 없다.

좁은 쪽: **모든 쓰기가 실패하는 게 아니다.** 두 번째 프로브가 그 경계를 확정했다.

첫 프로브는 `tmp` 와 `artifacts` 를 한 번에 써서 무엇이 무엇을 만들었는지 교란돼 있었다.
감사 지적을 받아 하나만 건드리는 격리 프로브를 다시 돌렸다.

```
const p = await openTab("https://example.com");
AFTER_OPENTAB=[]
await p.screenshot({ path: "./tmp/only.png" });
AFTER_PATHSHOT=["tmp"]
```

`openTab` 만으로는 아무것도 생기지 않고, 경로 지정 스크린샷 하나가 자기 부모를 만든다.
이제 교란이 없다.

측정된 예외는 두 개다. `page.screenshot({ path })` 와 `page.pdf({ path })`
(`PDF_PATH=ok entries=["tmp2"]`). 둘 다 없는 부모를 만든다.
`download.saveAs` 는 **측정하지 않았다.** Playwright 상류 동작을 근거로 추측하지 않고
문서에도 예외로 적지 않는다.

그러므로 규칙은 "`fs.writeFile` 만 깨진다" 가 아니라
**"자기 부모를 만들지 않는 호출이 깨진다. 부모를 만드는 것으로 확인된 건 위 둘뿐이다"** 이다.

`SKILL.md:450` 에 대한 판단도 정정한다. 그 문장이 주장하는 것은
"경로를 주면 만들어진다" 가 아니라 "스크린샷이 세션 `tmp/` 에 **알아서** 떨어진다" 이고,
그건 이번 프로브가 증명한 명제가 아니다. 경로 없는 `screenshot()` 은 파일을 안 만든다.
따라서 450 은 이 변경의 자리가 아니다. repl 세션 파일을 설명하는 `SKILL.md:409-413` 이 자리다.

## 반영 (diff 수준)

| 파일 | 줄 | 조치 |
|---|---|---|
| `references/repl-api.md` | 92 | `screenshot` 을 "Reads and chaining" 목록에서 떼어내고, locator 경유가 깨진다는 사실과 `boundingBox` + `clip` 우회를 명시 |
| `references/repl-api.md` | 160-163 | 경로 해석 문단 뒤에 세션 디렉터리가 비어서 시작한다는 사실, `fs.writeFile` 의 ENOENT, `mkdir` 선행, 그리고 부모를 만드는 것으로 **측정된** 예외가 `page.screenshot({path})` 와 `page.pdf({path})` 둘뿐이라는 경계 |
| `SKILL.md` | 409-413 | repl 세션 파일 문단에 `mkdir` 선행을 덧붙인다. 450 은 건드리지 않는다 (다른 명제다) |

## 하지 않는 것

- GitHub 이슈에 댓글을 달거나 닫는 것. 공개 저장소 외부 쓰기이고 사용자가 승인하지 않았다.
  Windows 재현 근거는 이 문서에 남겨 두고, 올릴지는 사용자가 정한다.
- Aside 자체를 고치는 것. 데몬 결함이라 우리 쪽에서 할 수 있는 건 우회 문서화뿐이다.

## 인수 조건

1. `references/repl-api.md` 에서 `screenshot` 이 더 이상 평범한 locator 메서드로 나열되지 않는다.
2. 같은 파일에 `boundingBox` + `clip` 우회가 실행 가능한 형태로 있다.
   우회 결과가 진짜 PNG 임을 확인했다: `FIRST8=137,80,78,71,13,10,26,10`, 241바이트,
   `BOX={"x":288,"y":135,"width":864,"height":32}`. 같은 세션의 전체 스크린샷은 13733바이트다.
3. 세션 디렉터리가 비어서 시작한다는 사실과 `mkdir` 선행이 문서에 있다.
4. 부모를 만드는 예외가 같이 적혀 있고, **측정된 것만** 적혀 있다. 이게 없으면 다음 독자가
   모든 쓰기를 `mkdir` 으로 감싼다. 반대로 미측정을 예외로 적으면 조용히 깨진다.
5. `download.saveAs` 는 예외 목록에 없다.
6. `SKILL.md` 500줄 미만 유지.
6. `check-wp5.ps1` 이 exit 0 이고 ASCII 전용이다.
