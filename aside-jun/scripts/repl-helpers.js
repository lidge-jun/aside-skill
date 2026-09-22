// Evaluate this trusted local source inside one native Aside REPL invocation.
// No globals are replaced; callers explicitly use the returned helper object.
(() => {
  function outputPath(value) {
    if (value === undefined) return undefined;
    if (typeof value !== 'string' || !/^(?:\.\/)?(?:tmp|artifacts)\/[A-Za-z0-9_-][A-Za-z0-9._-]*\.png$/.test(value)) {
      throw new TypeError('path must be a PNG filename directly under ./tmp or ./artifacts');
    }
    return value.startsWith('./') ? value : './' + value;
  }

  async function prepareSessionDirs() {
    // Session allocation does not create these parents on measured Aside builds.
    // Leave the native filesystem guard in charge of actual path access.
    await fs.mkdir('./tmp', { recursive: true });
    await fs.mkdir('./artifacts', { recursive: true });
    return { tmp: './tmp', artifacts: './artifacts' };
  }

  async function captureElementSource(targetPage, selector, options = {}) {
    if (!targetPage || ['locator', 'viewportSize', 'screenshot'].some(key => typeof targetPage[key] !== 'function')) throw new TypeError('page must expose locator, viewportSize and screenshot');
    if (typeof selector !== 'string' || !selector.trim()) throw new TypeError('selector must be a nonempty observed selector or snapshot ref');
    if (!options || typeof options !== 'object' || Array.isArray(options)) throw new TypeError('options must be an object');
    const unknown = Object.keys(options).filter(key => key !== 'path');
    if (unknown.length) throw new TypeError('unsupported capture options: ' + unknown.join(', '));
    const path = outputPath(options.path);
    if (path === undefined) throw new TypeError('path is required for the full viewport source PNG');
    const locator = targetPage.locator(selector);
    const count = await locator.count();
    if (count !== 1) throw new Error('element capture requires exactly one matched element; got ' + count);
    await locator.scrollIntoViewIfNeeded();
    const box = await locator.boundingBox();
    if (!box || !['x', 'y', 'width', 'height'].every(key => Number.isFinite(box[key])) ||
        box.x < 0 || box.y < 0 || box.width <= 0 || box.height <= 0) throw new Error('element has no finite visible capture box');
    const viewport = targetPage.viewportSize();
    if (!viewport || !Number.isFinite(viewport.width) || !Number.isFinite(viewport.height) ||
        viewport.width <= 0 || viewport.height <= 0 ||
        box.x + box.width > viewport.width || box.y + box.height > viewport.height) {
      throw new Error('element does not fit the viewport; use an explicit page screenshot instead');
    }
    await prepareSessionDirs();
    // Both locator.screenshot and native clip origin are broken on measured builds.
    // Preserve the full source and crop on the caller host; never label this the crop.
    await targetPage.screenshot({ type: 'png', fullPage: false, path });
    const after = await locator.boundingBox();
    if (!after || ['x', 'y', 'width', 'height'].some(key => after[key] !== box[key])) {
      throw new Error('element moved during capture; source is not a verified element crop');
    }
    return { sourcePath: path, box: { ...box }, viewport: { ...viewport }, cropped: false };
  }

  return Object.freeze({ prepareSessionDirs, captureElementSource });
})()
