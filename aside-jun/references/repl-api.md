# repl API reference

`aside repl` runs JavaScript against the live Aside browser. The surface is
Playwright-shaped: if you know Playwright, you already know most of it. Signatures
below were recovered from the daemon bundle.

No `import`/`require`. Use `console.log()` to see values; a bare expression prints
nothing. Execution timeout is 120 seconds.

Check the CLI's own help before trusting remembered flags - `aside --help`,
`aside exec --help`, `aside repl --help`. Run `aside repl` in a TTY when you want
thinking and tool output to stream live; piped into a file it still works but you
lose the live view. Because scope dies with the invocation, name variables freshly
within a call rather than assuming a previous one is gone or present.

Aside's own guidance calls the repl "a persistent ES2023+ JavaScript environment"
whose "top-level `const` and `let` bindings persist." Inside one invocation, yes.
Between two `aside repl` commands, no: bindings, `page`, `tabs`, and every ref are
gone, and a tab opened by the first call is closed before the second starts. Plan
each command as a complete flow, or borrow a window tab with `attachBrowserTab`,
which detaches rather than closes.

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

The three attach calls differ in what they do to session state.
`listBrowserTabs()` only reads: it lists open Aside tabs without attaching any, so
`page` stays as it was. `attachBrowserTab(targetId)` attaches that tab to this repl
session and makes it `page`. `attachActiveBrowserTab()` does the same for whichever
tab is currently active in the browser. Attached tabs are borrowed, so `closeTab`
detaches them instead of closing.

The full global list is `page`, `tabs`, `fs`, `path`, `Buffer`, `sleep`, `display`,
`pwd`, `fetch`, plus the tab and snapshot helpers and the service globals below.
`pwd` is a string, not a function.

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

## Which tab to work on

A CLI repl starts neutral, with no attached tabs, so `page` is `null` and `tabs` is
empty. Do not assume it is the user's current tab.

When the task mentions the current page, an already-open page, or a site that might
already be open, look before opening:

```js
const open = await listBrowserTabs();
console.log(open.map(t => ({ targetId: t.targetId, active: t.active, title: t.title, url: t.url })));
```

Then pick deliberately. `attachActiveBrowserTab()` only when the task is about the
active page. `attachBrowserTab(targetId)` when a listed tab matches or an id was
given. Read with `snapshot(page, { interactive: true })` right after attaching. Call
`openTab()` only when nothing relevant is open, or the task explicitly asks for a
new page.

Tab lifecycle has one hard rule: `openTab` and `closeTab` only. Never
`page.context().newPage()` or `page.close()` - they leak memory. Do not guess URLs
either, except well-known destinations like Google or YouTube.

## Reading escalation

Climb this ladder in order rather than jumping to pixels:

1. `snapshot(page, { interactive: true })`
2. `snapshot(page)`
3. wait briefly and snapshot again, but only if the page is still changing
4. `annotatedScreenshot(page)` for bounding boxes with ref ids, or
   `page.screenshot()` for raw visual state

Avoid `page.content()` and `page.evaluate()` unless you already know the exact
selector. The tree is usually enough: it carries the page title, the URL, child
iframe contents, and elements outside the scroll viewport.

No scrolling is needed. Snapshot already includes off-screen elements, and `click`
scrolls its target into view.

## Ref discipline

Ref ids such as `e12` or `f1e1` are virtual locator ids, not DOM properties. Pass
one straight to `page.locator('e31')`; never splice it into a CSS selector. Every new
snapshot invalidates every earlier ref.

The `selector` option is CSS even though the tree prints ARIA role names, so a
dialog is `[role="dialog"]` and not `dialog`.

Never guess a ref, a selector, page content, or how large a snapshot will be. Take
the snapshot instead.

## Action discipline

Pack an action and the following snapshot into one call when the next step does not
depend on the new state. Split them when it does, because the refs you need come
from the newer snapshot.

Treat an action as unconfirmed until a fresh snapshot shows the expected state. Once
the site has visibly accepted a change, that state is the evidence; re-check only on
a concrete contradiction, a stale snapshot, or no change at all. When state surprises
you, suspect a missed, stale, or wrong-target action before inventing a
site-specific rule.

`openTab` and `click` already wait for interactivity and DOM stability, so a
`sleep` right after either is noise. Use `sleep` only when a fresh snapshot shows
the page still transitioning.

## Downloads

Two paths, and the choice depends on how the file is served.

For a direct URL found on the current page, `fetch` carries session cookies:

```js
await fs.mkdir('./artifacts', { recursive: true });
const href = new URL(downloadUrl, page.url()).href;
const res = await fetch(href);
if (!res.ok) throw new Error('download failed: ' + res.status);
await fs.writeFile('./artifacts/download.pdf', Buffer.from(await res.arrayBuffer()));
console.log(res.status, res.headers.get('content-type'));
```

Keep `fetch` to same-origin or explicitly trusted direct-download GET/HEAD requests.
Not mutations, not cross-origin credential forwarding, and not a URL lifted from page
text without checking it.

For buttons, blob URLs, redirects, and POST-backed downloads, let the browser do it:

```js
const pending = page.waitForEvent('download');
await page.locator('button.export').click();
const download = await pending;
const p = await download.path();
console.log({ filename: download.suggestedFilename(), path: p, size: (await fs.stat(p)).size });
```

`download.saveAs('./artifacts/name.ext')` only when you actually need an artifacts
copy. Note that `fs` cannot browse the real `~/Downloads`; a registered download is
readable through `download.path()` and nowhere else. In a one-shot
`aside repl "..."` verify the file in the same command, because the session closes
with the process.

`page.pdf(options?)` takes Chromium `printToPDF` options - `path`, `width`,
`height`, `margin`, `printBackground`, which defaults true - and returns a Buffer.
Save user-visible PDFs under `./artifacts/`.

After downloading a document, extract the facts you were asked for with local
document or PDF tooling, and report only what the file or the page actually shows.

## Other globals

`fetch(input, init)` attaches session cookies and a browser User-Agent.
`installPageScript(page, key, script)` evaluates once per page/key and retries
transient navigation errors. `getTabByTargetId(id)` returns an attached page.

Service-specific globals ride the builtin skills: `chrome`, `twitter`, `gmail`,
`googleAccounts`, `googleDocs`, `googleSheets`, `googleSearch`, `googlePeople`,
`notion`, `slack`, `linkedin`, `youtube`, `imageSearch`, `imagegen`,
`applePasswords`, `captcha`, `aside`. Read the matching skill in
references/builtin-skills.md before using one.

They hold their methods on the prototype, so `Object.keys(twitter)` returns `{}` and
the global looks empty. Use `Object.getOwnPropertyNames(Object.getPrototypeOf(x))` to
see the real surface, or just read the table below.

| global | methods |
|---|---|
| `twitter` | `getMe`, `getUser`, `getTweet`, `getTweetThread`, `getTimeline`, `search`, `getUserTweets`, `getBookmarks`, `tweet`, `reply`, `deleteTweet`, `like`/`unlike`, `retweet`/`unretweet`, `bookmark`/`unbookmark`, `follow`/`unfollow`, `block`/`unblock`, `mute`/`unmute`, `getDmInbox`, `getDmConversation`, `sendDm`, `getNotifications` |
| `gmail` | `getInbox`, `search`, `getThread`, `openComposer`, `openReplyComposer`, `openThreadDetailsPage`, `downloadAttachment` |
| `youtube` | `search`, `getMetadata`, `listTranscriptLanguages`, `getTranscript`, `getComments` |
| `linkedin` | `getMe`, `getProfile`, `searchPeople`, `searchCompanies`, `getCompany`, `getJob`, `getUserPosts`, `getInbox`, `getConversation`, `sendMessage`, `sendInvitation`, `getReceivedInvitations`, `acceptInvitation`, `ignoreInvitation`, `withdrawInvitation` |
| `googleDocs` | `getDocumentText`, `getDocumentHTML`, `connect`, `insertText`, `insertHtmlContent`, `pasteFromMarkdown`, `applyDiffs`, `applyDiffsAsSuggestions`, `addComment`, `selectTextRange`, `dispose` |
| `googleSheets` | `getSpreadsheetInfo`, `readSheet`, `readAllSheets`, `connect`, `writeMatrix`, `writeTsv`, `writeHtml`, `navigateToCell`, `switchSheet`, `setNote`, `addComment`, `dispose` |
| `notion` | `listAccounts`, `getClient`, `invalidateCache` |
| `slack` | `listWorkspaces`, `getClient` |
| `captcha` | `click`, `drag`, `readText` |
| `cua` | `click`, `doubleClick`, `drag`, `move`, `scroll`, `type`, `keypress`, `getVisibleScreenshot` |
| `applePasswords` | `capabilities`, `requestAuth`, `verifyAuth`, `listLogins`, `getPasswords`, `getOtps`, `saveLogin`, `autofillLogin` |
| `googleAccounts` | `list`, `print` |
| `aside` | `settings`, `projects`, `sessions`, `routines`, `channels` |

`notion.getClient()` and `slack.getClient()` return real SDK clients, so the surface
past them is the vendor's own. `gmail` methods take a numeric account `uid` first.
`passwordManager` is deliberately absent: it exists only inside exec's repl tool.

## Error strings

Recognising these saves a diagnosis. The daemon bundle is minified, so every
templated error interpolates a mangled binding - `xn`, `jn`, `Vn`, `Jn`, and member
forms like `Vn.ref` or `jn.selector` all appear. The placeholder names below are
readable stand-ins, not what the binary holds, so grep the fixed prefix and never the
whole line.

```text
No active page. Open a tab first.
No open browser tab found for targetId ${targetId}
Tab ${id} is not tracked in this session.
Tab ${id} belongs to a different browser profile.
Ref "${ref}" points to a frame that is no longer available. Take a new snapshot.
Selector "${selector}" matched no elements on page.
Snapshot refs already include frame identity; use page.locator(ref) instead of frame.locator(ref).
Path escapes Project and session roots: ${path}
```

A signed-out service fails with its own cookie message rather than a generic error,
which is the fastest way to tell "logged out" from "broken". All four are fixed
strings reproduced byte for byte, em dashes and the LinkedIn message's literal
backticks included.

```text
No auth_token cookie — not logged in to X?
No cookies for mail.google.com — not logged in?
No token_v2 cookie found — Notion session may be expired
LinkedIn session cookies missing `li_at` or `JSESSIONID`
```

## A working loop

```js
const p = await openTab('news.ycombinator.com');
const s1 = await snapshot(p, { interactive: true });
console.log(s1.tree);
await p.locator('a.storylink').first().click();
const s2 = await snapshot(p, { interactive: true });
console.log(s2.diff);
```

Inspect, act, re-inspect. Never chain blind actions, and never truncate a snapshot
with `slice`, `substring`, or `split` - the ref you need is usually the one that
gets cut. Number snapshots `s1`, `s2` so an earlier tree stays readable.
