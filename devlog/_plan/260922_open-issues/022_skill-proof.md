# Skill issues 1 and 2: verified mitigation

Native Aside CLI1.26.906.1630 / daemon1.26.921.1617 on macOS still reproduces both
upstream behaviors: locator capture throws Invalid parameters and fresh session
fs.writeFile to tmp fails ENOENT. No daemon code was changed.

The bundled helper creates tmp/artifacts recursively and the real same-session
write/read returned ready. Element source capture uses full viewport because the
native clip origin was visually wrong. Actual source was 2880x1800 pixels for a
1440x900 CSS viewport; the observed120x60 element at48,40 maps to pixel rectangle
96,80,336,200. Host crop returned240x120 PNG. All four corners were color-managed
red (R>200,G/B<80), no white origin offset, and main inspected the image.

- node --test 020_repl-helpers.test.mjs: 7 passes,0 failures.
- Existing bundled Python/Pillow running021_crop-element.test.py: 3 passes.
- Invalid targets/paths/page interfaces fail before writes; native errors propagate.
- Exclusive output refuses overwrite; injected save failure removes only new output.
- Source-extracted codemode recipe/link check: PASS,15 Markdown docs.
- Sol review found missing page validation and partial-output cleanup; both fixed
  with tests. Same reviewer returned PASS, no remaining blockers.

Files under native session artifacts and task scratch were used for live proof;
no private site data, credential material or machine-specific runtime paths are
included here. Issue closure means supported skill workflow mitigation, not that
native locator.screenshot or automatic daemon directory initialization was fixed.
