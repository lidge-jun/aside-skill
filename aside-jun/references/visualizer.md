# Delegate visual artifacts to Aside

Use the selected Aside account's installed `dev-visualizer` skill for composed
HTML/SVG documents, reports and visual PDF work. Aside has no host inline
visualizer: the deliverable is a standalone file in the run's artifact directory.
Preserve every requested format, template, brand rule, section order and required
content. An HTML preview does not replace a requested PDF, DOCX, PPTX or XLSX.
The `aside-visualizer` repository installs into an account as the user skill
`dev-visualizer`; the repository checkout itself is not the loaded skill.

## Confirm the installed route

Resolve the Aside executable, account, host and that account's absolute root from
current CLI help and `aside account list`. Use the account and host the user chose;
do not infer the account directory from an example such as `u/0`, switch defaults,
or edit configuration. On that host, use an authorized read to confirm and read
the account user skill file itself:

```bash
VISUALIZER_SKILL="$ASIDE_ACCOUNT_ROOT/skills/user/dev-visualizer/SKILL.md"
test -f "$VISUALIZER_SKILL" && cat "$VISUALIZER_SKILL"
```

Run that read on the selected host and replace every variable with its resolved
absolute value. For a remote host, use an existing authorized remote read route;
the caller's local filesystem is not evidence about the remote account. Current
`aside skills show` may describe the builtin catalog, so `skills list/show` failure
does not prove this account user skill is missing. The installed file body is the
contract for composition, available format owners and checks.

If the account file is absent or unreadable through the authorized route, report
the installation as missing or unverified. An already installed owner for the
requested format may still complete the task, but do not claim the visualizer was
loaded, install it, or copy the sibling repository into a global coding-agent
skill directory.

## Collect sources before composition when useful

For independent file, URL or query collection, call aside-codemode directly as
described in [Code-mode calls](codemode.md), preserving source URLs, dates, units,
coverage metadata and per-item failures. Give the visualizer the collected source
packet through an authorized absolute path it can read. Use this route only when
codemode's verified execution context matches the selected account and host; a
required nondefault account or remote host stays on Aside's explicit native route.

Codemode collects evidence; `dev-visualizer` decides the document structure and
composition. Do not ask an unattended `exec` run to rediscover known inputs unless
the visualizer needs browser judgment to complete the artifact.

## Delegate with bounded inputs and output

Read [exec delegation](exec.md), use its host deadline, and pass a prompt with real
absolute input paths or URLs. A concise prompt is:

```text
Use the installed dev-visualizer skill.
Authorized inputs: <real absolute paths and URLs on this host>.
Create: <requested format, audience and purpose>.
Preserve: <template, branding, section order and other stated constraints>.
Write only inside the absolute session artifacts directory supplied to this Aside run.
Return the exact absolute source and final artifact paths, plus the verification performed and any failures.
Do not publish, send, install, change account/tool settings, or modify other files.
Do not ask questions in this unattended run. If an essential input, skill, format owner, human approval, MFA or vault unlock is missing, report the exact blocker and stop.
```

Run it with the selected context rather than a default profile:

```bash
ASIDE_CONTEXT=(--account "$ASIDE_ACCOUNT" --host "$ASIDE_HOST")
/usr/bin/perl -e 'alarm shift; exec @ARGV' 300 "$ASIDE" \
  "${ASIDE_CONTEXT[@]}" exec --permission "$ASIDE_PERMISSION" -- "$PROMPT"
```

That is the macOS deadline form; use the Windows wrapper linked from
[exec delegation](exec.md) on Windows. Choose permission from the task's existing
authorization. The example duration and permission variable are not visualizer
flags or new authority.

## PDF routes and proof

Native Aside `page.pdf()` uses Aside's Chromium and does not require system Chrome.
The standalone `scripts/export-paged-report.mjs` route has its own Node, Chrome and
PDF-tool dependencies; do not assume they are installed. Avoid `file://`: use a
small `data:` URL or a task-owned loopback server bound to `127.0.0.1`.

The aside-codemode 0.9.0 contract accepts `preferCSSPageSize` and `margin` in the
PDF options for `browse.exec` and `browse.captureMany`. Verify the installed
runtime before using those options; older installations may not support them.
The returned `pdf.pageBox` establishes the measured PDF boxes and which size rule
ran. It does not prove CSS fidelity, margin fidelity, correct pagination, fonts,
glyphs, clipping or visual quality. Inspect the actual exported PDF pages before
calling the PDF complete. The September 16 no-Chrome reference in the sibling
repository predates this codemode support.

Scale proof to the requested output and the installed skill contract. Open and
inspect HTML/SVG artifacts; exercise requested interactions; for PDF, export and
inspect the actual pages; for another document format, use its installed owner and
verify the final file in that format. Do not invent named assurance tiers, flags or
unrequested page-by-page checks.

## Deliver from the correct host

Treat every returned path as belonging to the selected host. Check that each final
artifact exists, is nonempty, has the requested format and satisfies the relevant
installed-skill checks. Record the actual Aside session ID and verify the returned
paths resolve inside that run's absolute
`$ASIDE_ACCOUNT_ROOT/sessions/<actual-session-id>/artifacts/` directory; do not
report a template path. When Aside ran remotely, retrieve the artifact through an
already authorized transfer route and verify the retrieved local file before
presenting a local path. A remote path alone is not local delivery.
