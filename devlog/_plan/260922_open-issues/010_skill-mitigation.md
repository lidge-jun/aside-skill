# Skill-owned REPL compatibility helpers

NEW aside-jun/scripts/repl-helpers.js is a plain expression evaluating to a frozen
helper object. It requires no import/require, no global assignment, and no patches
to native methods. The caller reads its local installed source outside Aside and
passes it as code in one native REPL invocation; do not ask root-guarded REPL fs to
read a coding-agent skill directory it cannot access.

APIs: prepareSessionDirs() calls fs.mkdir for ./tmp and ./artifacts recursively;
screenshotElement(page, locator, {path?}) requires exactly one locator, scrolls it
into view, reads boundingBox, validates finite nonnegative viewport geometry and
positive dimensions, and calls page.screenshot({type:'png',clip:box,path?}). Optional
path must be a simple PNG filename under ./artifacts or ./tmp; disallow absolute,
parent traversal, backslash, control characters and URL paths. No broader config.
Prepare dirs before output but after validation. Let fs, locator and screenshot
errors propagate. Return original screenshot buffer for inspection; no fake success.

Reject empty/multiple/invisible/offscreen boxes rather than silently capturing the
wrong element. CSS size and PNG pixel size can differ by device scale; measure
PNG IHDR and report scale rather than demanding equal dimensions. Preserve existing
tabs; helper does not open/close pages. Native upstream bugs remain documented.

MODIFY repl-api.md: route screenshots and fresh session writes to the helper and
provide complete host-read/native-eval example. MODIFY SKILL.md compact pointer.
NEW unit-local helper tests use node:vm and injected native-shaped stubs to assert
idempotent directory preparation, missing dirs, argument negatives and error
propagation; live fixture is real data URL, no auth or user content. Read actual PNG.

## Spatial-proof correction (supersedes screenshotElement above)

Live inspection found x/y origin ignored on daemon1.26.921.1617; correct PNG
geometry alone was false proof. Left/top fails, fullPage+clip is byte-identical.
Reject the native-clip design. API is now captureElementSource(page, selector,
{path}) returning a full viewport sourcePath, measured box/viewport and cropped:false.
It creates dirs and detects target movement; the selector belongs to the supplied
Page so a mismatched locator/Page cannot silently crop another page.

NEW scripts/crop-element.py uses an already available Pillow runtime, no installs,
scales CSS coordinates by actual PNG/viewport size, checks aspect/containment and
writes a new PNG with exclusive creation. Missing Pillow yields a clear prerequisite,
never a false crop. Native filesystem guards stay unchanged. Return original
source for audit and inspect actual cropped pixels. Target fixture at offset48,40,
size120x60 must have red at output origin and corners, no white border. This is a
supported skill mitigation, not a native daemon patch.
