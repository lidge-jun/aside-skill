# 020 - references/repl-api.md at parity

The reference currently lists signatures. The official doc adds an operating
protocol, which is the part that actually changes behavior. Absorb it.

## Tab inspection protocol

Missing entirely. Add the official order: `listBrowserTabs()` first when the user
mentions the current page or an already-open tab, print
`{targetId, active, title, url}`, then `attachActiveBrowserTab()` only for the
active page, `attachBrowserTab(targetId)` for a named tab, interactive snapshot
after attaching, and `openTab()` only when nothing relevant is open. Pair it with
our measured fact that a CLI repl starts with zero attached tabs.

## Reading escalation ladder

Add verbatim in order: `snapshot(page, {interactive:true})`, then `snapshot(page)`,
then wait and re-snapshot only while the page is still changing, then
`annotatedScreenshot(page)` or `page.screenshot()` for visual confirmation. Include
the warning to avoid `page.content()` and `page.evaluate()` without an exact
selector.

## Ref discipline

Refs are virtual locator ids - pass them straight to `page.locator('e31')`, never
mix them into CSS or treat them as DOM properties. Every snapshot invalidates
earlier refs. The `selector` option takes CSS even though the tree prints ARIA
roles, so `[role="dialog"]` and not `dialog`. The tree already includes title, URL,
iframe contents, and off-screen elements.

## Action discipline

Add: pack action plus snapshot in one call when the next step does not depend on new
state, split after a snapshot when it does, treat an action as unconfirmed until a
fresh snapshot shows the expected state, suspect a missed or wrong-target action
before inferring site rules, no redundant `sleep` after navigation or click, and no
scrolling because snapshot sees off-screen elements and click scrolls into view.
Add the memory-leak rule: `openTab`/`closeTab` only, never
`page.context().newPage()` or `page.close()`.

## Downloads

Add both official paths. `fetch()` is cookie-bearing and restricted to same-origin
or explicitly trusted direct-download GET/HEAD urls found on the page - not
mutations, not cross-origin credential forwarding, not urls lifted from page text.
For buttons, blobs, redirects, and POST-backed downloads use
`page.waitForEvent('download')`, then `download.path()`,
`download.suggestedFilename()`, and `download.saveAs()` only when an artifacts copy
is actually needed. State that `fs` cannot browse `~/Downloads` and that a one-shot
`aside repl` must verify inside the same command.

## Missing globals and error strings

Document `page.pdf(options?)` (Chromium printToPDF options, `printBackground`
defaults true), `annotatedScreenshot(page): {base64Image}` with no options,
`display(input, context?)` accepting base64, data urls, `Uint8Array`/`Buffer`, and
`installPageScript(page, key, evaluator)`. Add the service-global method tables and
the exact error strings recovered from the daemon, since a verbatim error is what
makes a failure diagnosable:

```text
No active page. Open a tab first.
Ref "${ref}" points to a frame that is no longer available. Take a new snapshot.
Path escapes Project and session roots: ${path}
Password manager is locked for this agent session.
No auth_token cookie — not logged in to X?
```

That last one carries an em dash in the binary. Copy these strings byte-for-byte or
they stop being greppable, which defeats the point of quoting them.
