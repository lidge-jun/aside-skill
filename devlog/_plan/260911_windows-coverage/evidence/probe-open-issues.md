# 공개 이슈 2건 재현 프로브 원문

호스트: Windows 11, Aside CLI `1.26.906.1630`. 전부 `aside repl` 일회성 호출이다.

## 이슈 1 - locator.screenshot

```
LOCATOR_SHOT_ERR=Invalid parameters
CLIP_SHOT=ok bytes=241
```

우회 결과가 진짜 PNG 인지 확인:

```
TYPE=Buffer LEN=241
FIRST8=137,80,78,71,13,10,26,10
SIG=PNG
BOX={"x":288,"y":135,"width":864,"height":32}
FULL_BYTES=13733
```

`137,80,78,71,13,10,26,10` 은 PNG 시그니처다. 864x32 짜리 거의 흰 띠라서 241바이트가 나온다.
같은 세션의 전체 페이지 스크린샷은 13733바이트다.

첫 확인 때 매직 넘버가 `184,131,24,172` 로 나왔는데 그건 Aside 문제가 아니라
`new Uint8Array(b.buffer)` 로 읽어서 Node Buffer 풀의 오프셋 0 을 본 내 실수였다.
`b[0]` 으로 직접 읽으면 정상이다.

## 이슈 2 - 세션 디렉터리

```
PWD=C:\Users\super\.aside\u\0\sessions\2026-09-11_0wIMAK9qtIq9mP8v
ENTRIES=[]
TMP_WRITE_ERR=ENOENT: no such file or directory, open '...\tmp\probe.txt'
ART_WRITE_ERR=ENOENT: no such file or directory, open '...\artifacts\probe.txt'
```

격리 프로브. 첫 시도는 `tmp` 와 `artifacts` 를 한 번에 건드려서 무엇이 무엇을 만들었는지
구분이 안 됐다. 하나만 건드리게 다시 돌렸다.

```
const p = await openTab("https://example.com");
AFTER_OPENTAB=[]
await p.screenshot({ path: "./tmp/only.png" });
AFTER_PATHSHOT=["tmp"]
```

`openTab` 은 아무것도 만들지 않고, 경로 지정 스크린샷 하나가 자기 부모를 만든다.

`page.pdf({ path })` 도 같다:

```
PDF_PATH=ok entries=["tmp2"]
```

`download.saveAs` 는 측정하지 않았다. 그래서 예외 목록에 넣지 않았다.
