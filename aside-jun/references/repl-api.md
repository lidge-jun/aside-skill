# repl API reference

`aside repl` runs JavaScript against the live Aside browser. The surface is
Playwright-shaped: if you know Playwright, you already know most of it. Signatures
below were recovered from the daemon bundle.

Scope persists within one repl session. No `import`/`require`. Use `console.log()`
to see values; a bare expression prints nothing. Execution timeout is 120 seconds.

## Getting a page

```js
const p = await openTab('example.com');   // adds https:// when missing, waits for stable
const all = await listBrowserTabs();      // {id,targetId,url,title,faviconUrl,active,windowId}[]
const borrowed = await attachBrowserTab(targetId);
const active = await attachActiveBrowserTab();
await closeTab(p);                        // closes owned tabs, detaches borrowed ones
```

`page` is a getter for the active page and starts `null` in a fresh CLI repl.
`tabs` lists session-attached pages. `openTab` waits up to 5 seconds for stability.

## Page

Navigation and reads:

```js
await p.goto(url, { waitUntil });  // commit|interactive|stable|networkidle|load|domcontentloaded
await p.goBack(); await p.goForward(); await p.reload();
await p.waitForLoadState('interactive', 30000);
await p.waitForURL(/dashboard/, { timeout });
await p.waitForSelector('h1', { state: 'visible', timeout: 3000 });
await p.title(); await p.content(); p.url(); p.viewportSize();
await p.screenshot(opts); await p.pdf(opts);
```

Selectors:

```js
p.locator(sel, filter?)
p.getByRole(role, opts?)
p.getByLabel(text|RegExp, { exact })
p.getByText(text|RegExp, { exact })
p.frameLocator(sel)
```

Page-level actions are only `click(sel, opts?)` and `fill(sel, value)`. Everything
richer lives on `Locator`. `$` and `$$` still work but warn; use `locator().first()`
and `locator().all()`.

`p.evaluate(fnOrExpr, arg?)` takes **one** optional argument. Pack multiple values
into an object.

## Locator

Actions: `click`, `fill`, `selectOption`, `check`, `uncheck`, `setChecked`,
`clear`, `type`, `press`, `pressSequentially`, `hover`, `dblclick`, `focus`,
`blur`, `tap`, `scrollIntoViewIfNeeded`, `setInputFiles`, `dragTo`,
`dispatchEvent`.

Reads and chaining: `evaluate`, `evaluateAll`, `boundingBox`, `screenshot`,
`count`, `all`, `first`, `last`, `nth`, `locator`, `filter({hasText})`,
`getAttribute`, `isChecked`, `isDisabled`, `isEditable`, `isEnabled`, `isHidden`,
`isVisible`, `inputValue`, `innerHTML`, `innerText`, `textContent`,
`elementHandle`, `waitFor({state, timeout})`.

`waitFor` states are exactly `attached`, `detached`, `visible`, `hidden`. Default
timeout 3000ms.

## Snapshot and refs

```js
const s = await snapshot(p, { interactive: true });
// { tree: string, refs: Record<string, RefMeta>, diff: string }
```

Options: `interactive`, `showHidden`, `ref`, `selector`, `maxDepth`, `maxChars`.

Refs are `e<n>` in the main frame and `f<n>e<n>` in child frames. `RefMeta` carries
`role`, `name` (truncated to 100 chars), `tagName`, and optionally `inputType`,
`ariaLabel`, `placeholder`, `nthAmongSameSignature`.

Refs resolve through a virtual registry and **go stale after the page changes**.
Take a fresh snapshot after every action that mutates the DOM. The second call
returns a diff when that is shorter than the full tree, which makes the
inspect-act-reinspect loop cheap.

```js
const shot = await annotatedScreenshot(p);  // { base64Image }
display(shot.base64Image);
```

`annotatedScreenshot` overlays numbered red boxes on referenced elements, which is
the fastest way to see why a ref is not matching what you expect.

## cua: coordinate fallback

Use only when refs and locators genuinely cannot target the element: canvas apps,
drag handles, map pins, custom sliders.

```js
await cua.click({ x, y, button, keypress });   // button defaults to 'left'
await cua.doubleClick({ x, y, keypress });
await cua.drag({ path: [{x,y}, {x,y}], keys });
await cua.move({ x, y, keys });
await cua.scroll({ x, y, scrollX, scrollY, keypress });
await cua.keypress({ keys: ['Meta','a'] });    // joined with '+'
await cua.type({ text });
const png = await cua.getVisibleScreenshot();  // base64
```

Note the inconsistency: modifiers are `keypress` on click/doubleClick/scroll but
`keys` on move/drag.

`cua` always acts on the active page, so focus the right tab first.

## display

`display(image)` is image-only. It accepts base64, a data URL, `Uint8Array`,
`Buffer`, or `ArrayBuffer`. For text use `console.log()`.

## fs and the jail

`fs` is async: `readFile`, `writeFile`, `mkdir`, `readdir`, `stat`, `lstat`,
`unlink`, `rm`, `rename`, `copyFile`, `access`, `resolvePath`. There is no
`writeFileSync`.

A path is accepted only if it resolves inside `cwd`, the account root, or the
session storage dir. Registered downloads are readable but never writable.
Relative paths beginning `artifacts`, `attachments`, or `tmp` resolve against the
session dir; others resolve against `cwd`.

Anything else throws immediately:

```
Path escapes Project and session roots: /etc/passwd
```

**This throw is a feature.** Unlike `exec`, the repl fs fails fast instead of
hanging. When you only need to read or write a file, repl is the safer surface.

## Other globals

`fetch(input, init)` attaches session cookies and a browser User-Agent.
`installPageScript(page, key, script)` evaluates once per page/key and retries
transient navigation errors. `getTabByTargetId(id)` returns an attached page.

Service-specific globals ride the builtin skills: `chrome`, `twitter`, `gmail`,
`googleAccounts`, `googleDocs`, `googleSheets`, `googleSearch`, `googlePeople`,
`notion`, `slack`, `linkedin`, `youtube`, `imageSearch`, `imagegen`,
`applePasswords`, `captcha`, `aside`. Read the matching skill in
references/builtin-skills.md before using one.

## A working loop

```js
const p = await openTab('news.ycombinator.com');
const s = await snapshot(p, { interactive: true });
console.log(s.tree.slice(0, 2000));
await p.locator('a.storylink').first().click();
const after = await snapshot(p, { interactive: true });
console.log(after.diff);
```

Inspect, act, re-inspect. Never chain blind actions.
