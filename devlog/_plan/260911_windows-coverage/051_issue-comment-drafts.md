# 051 - 이슈 댓글 초안 (감사 FAIL 후 재작성)

첫 초안은 감사에서 FAIL 났다. 이유가 둘 다 중요하다.

1. **월권.** 저자는 mac-arm64 에서 **절대 POSIX 경로**로 ENOENT 를 봤는데,
   나는 Windows 에서 **상대 경로**로 성공한 걸 근거로 "보고가 틀렸다" 고 쓰려 했다.
   경로 형태가 다르면 다른 현상일 수 있고, mac 은 재측정하지도 않았다.
2. **유출.** PWD 줄에 사용자명과 전체 세션 id 가 그대로 있었다. 원 이슈는 세션 id 를 가렸는데.

경로 형태 가설은 이번에 직접 죽였다. Windows 에서는 절대 경로도 성공한다.

```
AFTER_OPENTAB=[]
ABS_PATHSHOT=ok          (path = <pwd>/tmp/abs.png, 절대 경로)
ENTRIES=["tmp"]
ABS_FILE_BYTES=13733     (디렉터리 목록이 아니라 파일 크기)
REL_FILE_BYTES=13733     (상대 경로도 동일)
```

그러니 남는 차이는 경로 형태가 아니라 **플랫폼 또는 버전**이다.
댓글은 거기까지만 말하고 저자를 부정하지 않는다.

데몬 버전도 같이 적는다. 이슈 1 은 CDP 래퍼 실패라 CLI 버전만으로는 부족하다.
`aside-daemon` manifest: `1.26.910.1749`, platform `win`.

## 이슈 #1 초안

~~~markdown
Also reproduces on Windows, so this does not look mac-specific.

**Environment:** Aside CLI `1.26.906.1630`, daemon `1.26.910.1749` (win-x64),
Windows 11, driven through `aside repl`.

```js
const p = await openTab("https://example.com");
await p.locator("h1").screenshot({ type: "png" });
// Error: Invalid parameters
```

The `boundingBox` + `clip` workaround from the issue produces a valid image here:

```js
const box = await p.locator("h1").boundingBox();
// box = { x: 288, y: 135, width: 864, height: 32 }
const png = await p.screenshot({ type: "png", clip: box });
// 241 bytes, first 8 bytes 137,80,78,71,13,10,26,10 -> valid PNG signature
```

For scale, capturing the same page without a clip in that run gave 13733 bytes.

Among the screenshot APIs I measured, only the locator-mediated call throws.
`page.screenshot()` works, and in a follow-up run `annotatedScreenshot()` returned
without throwing and `cua.getVisibleScreenshot()` returned 18312 bytes. I did not
test `elementHandle.screenshot()`.
~~~

## 이슈 #2 초안

~~~markdown
Also reproduces on Windows. One observation differs, and I want to be careful about
how much it means, since I did not retest macOS.

**Environment:** Aside CLI `1.26.906.1630`, daemon `1.26.910.1749` (win-x64),
Windows 11, driven through `aside repl`.

**Confirmed.** A fresh session's directory is empty, so `artifacts/` is missing
alongside `tmp/`, and an `fs` write to either throws:

```
ENTRIES=[]
ENOENT: no such file or directory, open '...\sessions\<id>\tmp\probe.txt'
ENOENT: no such file or directory, open '...\sessions\<id>\artifacts\probe.txt'
```

**Where Windows differs.** The issue body lists `page.screenshot({ path })` among
the calls that fail. On this Windows build that call succeeds and creates its own
parent directory. An isolating probe, touching one path only:

```
const p = await openTab("https://example.com");
AFTER_OPENTAB=[]
await p.screenshot({ path: "./tmp/only.png" });
AFTER_PATHSHOT=["tmp"]
```

I checked whether the path shape explained it, since your traceback shows an
absolute POSIX path while my first probe used a relative one. It does not: an
absolute path behaves the same here, and the file really lands, 13733 bytes rather
than just a directory appearing. `page.pdf({ path })` also creates its parent.
`openTab` alone creates nothing.

So on Windows the failing set is the calls that do not create their own parent;
`fs.writeFile` is the one I measured. I did not test `download.saveAs`.

Since macOS was not retested, this is a platform or version difference to look at
rather than a correction of your report. The ask itself is unchanged: creating
`tmp/` and `artifacts/` when the session directory is allocated removes the retry
turn on both platforms.
~~~

## 근거 대응표

| 주장 | 근거 |
|---|---|
| `Invalid parameters` | `evidence/probe-open-issues.md` 이슈 1 절 |
| 241바이트, PNG 시그니처, box 좌표 | 같은 파일, `FIRST8=137,80,78,71,13,10,26,10` |
| clip 없는 캡처 13733바이트 | 같은 파일, `FULL_BYTES=13733` |
| annotated / cua 정상 (후속 실행) | 같은 파일, `ANNOTATED=ok`, `CUA=ok len=18312` |
| 세션 디렉터리 `[]` + 두 ENOENT | 같은 파일, 이슈 2 절 |
| 격리 프로브 `[]` -> `["tmp"]` | 같은 파일 |
| 절대 경로도 성공, 파일 13733바이트 | 같은 파일, `ABS_PATHSHOT=ok` / `ABS_FILE_BYTES=13733` |
| `page.pdf({path})` -> `["tmp2"]` | 같은 파일 |
| 데몬 `1.26.910.1749` | win-x64 manifest.json |
| `download.saveAs`, `elementHandle.screenshot` 미측정 | 댓글 본문에 명시 |

## 하지 않는 것

- 이슈를 닫거나 라벨을 바꾸지 않는다.
- 저자의 mac 관측을 부정하지 않는다. 재측정하지 않았다.
- PWD 전체 경로와 세션 id 를 올리지 않는다. 원 이슈와 같은 수준으로 가린다.
- 측정하지 않은 API 를 사실처럼 적지 않는다.

## 게시 기록

| 이슈 | 댓글 id | 확인 |
|---|---|---|
| #1 | `5636384574` | API 재조회로 본문 선두 일치 |
| #2 | `5636384769` | API 재조회로 본문 선두 일치 |

둘 다 열린 상태 그대로 두었다. 라벨도 건드리지 않았다.
