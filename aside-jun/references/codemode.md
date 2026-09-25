# Aside code mode from Codex or Claude

Use this cookbook when an external coding agent needs one bounded Aside code-mode
batch. Code mode has three distinct callers:

- The `codemode` CLI runs a sandboxed guest program from a shell.
- A caller-attached aside-codemode MCP server exposes one `execute_code` tool.
- Aside's native REPL can load the installed `cm` helper for bounded browser-tab
  concurrency. That helper is not an external MCP tool.

Do not paste the guest examples into Codex host Code Mode, a shell JavaScript
runtime, or the native Aside REPL. Each has different globals and filesystem
rules.

## Pick an available route

First inspect the caller's current tool inventory. Use MCP only when the server
identity and live schema identify aside-codemode. Tool names are qualified by the
caller, so a generic tool called `execute_code` is not identity proof. Do not
assume an MCP server registered in Aside is attached to Codex or Claude.

If no matching MCP tool is attached, use a verified local CLI. Prefer the absolute
Node executable and `bin/codemode.mjs` path supplied by setup. Otherwise inspect
`PATH` once (`command -v codemode` on POSIX or `Get-Command codemode` in
PowerShell) and verify the resolved package before use. Never use `npx` as an
auto-install fallback.

If neither route exists, report that aside-codemode is a prerequisite and continue
only with already available, authorized native tools. Do not install, update, edit
configuration, widen roots, or enable browsing as an implicit recovery step.

## Identify the installed version

`codemode` has no `--version` or `--help`; both return
`{"ok":false,...,"code":"EBADARGV"}` on 0.9.2. Resolve the command to its real
file and read the neighbouring package metadata instead:

```bash
CM="$(command -v codemode)"; real="$(readlink -f "$CM")"
# a shell launcher (e.g. ~/.local/bin/codemode) names its target in its exec line
head -5 "$real"
node -p "require('$(dirname "$(dirname "$real")")/package.json').version"
```

A `browserContext` object in the result envelope means the #44 routing report
is present (0.9.1+). A host can hold several installs; on the measured Mac
(2026-09-25) `~/.local/bin` and nvm resolved to a 0.9.2 checkout while
`/opt/homebrew/bin/codemode` was 0.9.1. PATH order decides which one a
non-login shell gets, so pin the absolute path you verified. npm `latest` was
0.9.2 on that date.

## CLI: local search and bounded reads

Guest code is an async function body. Use injected globals such as `search`, `fs`,
`actions`, and `browse`; `await` their operations and `return` the result. There is
no guest `require`, `import`, `process`, Node filesystem, or assumed browser page.
Use `actions.describe(path)` and `actions.check(path, args)` to discover the
installed API without performing the action. `path` is a full action name such
as `browse.exec`; a bare namespace (`browse`) fails with a did-you-mean list.

Save this as a task-owned UTF-8 `batch.js`:

<!-- example: local-batch -->
```js
const hits = await search.content({
  path: ".",
  query: "TODO",
  glob: "**/*.txt",
  max: 20
});
const paths = [...new Set(hits.map(hit => hit.file))];
const excerpts = await fs.readMany(paths, { maxBytes: 4096, totalBytes: 8192 });
return { hits, excerpts };
```

Supply paths as separate quoted arguments. The explicit Node/CLI pair avoids
wrapper and `.cmd` argument differences, while `--code-file` avoids embedding
guest JavaScript in shell quoting.

```bash
"$CODEMODE_NODE" "$CODEMODE_CLI" --config "$TASK_CONFIG" \
  --cwd "$PROJECT_DIR" --code-file "$JOB_FILE"
```

```powershell
& $codemodeNode $codemodeCli --config $taskConfig --cwd $projectDir --code-file $jobFile
if ($LASTEXITCODE -ne 0) { throw "codemode failed: $LASTEXITCODE" }
```

Those variables are caller-owned absolute paths, not codemode environment keys.
For an already configured, verified command, the equivalent is
`codemode --cwd /absolute/project --code-file /absolute/batch.js`. Standard input
with `--code -` is the documented alternative. An explicit config is useful for
isolated proofs but is not required for normal configured use. Inspect any
`CODEMODE_*` environment overrides when a config is supplied.

`--cwd` resolves relative guest paths; it does not add an allowed root. A process
exit of zero is only transport evidence. Parse the JSON envelope and inspect the
returned data.

## MCP: use the discovered live schema

At aside-codemode 0.9.0 the MCP input schema is exactly
`{code: string, timeoutMs?: number}`. There are no per-call `cwd`, `account`, or
`host` fields. Use absolute guest paths because the server process may have a
different working directory.

```json
{"code":"return await search.count({path: '/absolute/project', query: 'TODO'});","timeoutMs":30000}
```

Read both MCP layers: tool failure may set `isError: true`, while
`content[0].text` contains the serialized execution envelope. Parse that text
before reading `result`. MCP initialization `serverInfo.version`, when exposed,
is the preferred version proof.

Running aside-codemode's `--install-mcp` configures the selected Aside account;
it does not attach a tool to Codex or Claude. External caller MCP attachment is a
separate setup action and must follow that caller's current configuration flow.

## Browser batches

Discover the installed action shapes before building a known-page batch. This
snippet performs no browser request:

<!-- example: browser-discovery -->
```js
return {
  exec: actions.describe("browse.exec"),
  capture: actions.describe("browse.captureMany")
};
```

Use `actions.check("browse.exec", args)` to validate the actual arguments. Inspect
an unfamiliar page or dependent flow natively first. For known, independent,
task-authorized URLs, this is the bounded rendered-page batch:

<!-- example: browser-batch -->
```js
const result = await browse.exec({
  urls: ["https://example.com", "https://example.org"],
  snapshot: false,
  fullText: true,
  maxTextChars: 4000
});
return result;
```

Replace the example URLs; do not invent selectors, login state, or an account
switch. Inspect each item's status, error, returned text, and completeness fields.
`browse.readText` is fetch-first, so an HTTP response from it is not proof of a
signed-in rendered page. Use `browse.exec` or native Aside and verify the expected
rendered content when authentication matters.

If browsing returns `EDISABLED`, report that prerequisite. The error does not
authorize `--enable-browse` or a configuration edit.

## Read results without losing evidence

CLI and MCP guest execution return an outer envelope containing `ok`, optional
`result`, `logs`, and `elapsedMs`; output budgeting can also add truncation fields.
`console` output goes to `logs`. Only an explicit guest `return` becomes `result`.
`ok: true` means the guest finished, not that every requested item was read or the
content was correct.

Search arrays remain iterable inside the guest, but serialize as
`{rows, complete, truncated, partial, scope}`. Return the original value or retain
those fields when projecting it. `partial` is an array of reasons, not a boolean;
no reported partial failures means `partial.length === 0`, not `partial === false`.
Inside the guest the decorated search value is still an array; after transport
parse its envelope's `rows`. In the local example, returning `hits` intact
preserves that envelope. `fs.readMany` can return per-row `skipped` or `error`
entries even when the outer execution has `ok: true`.

Treat absence as proven only when the installed contract supplies the evidence.
For 0.9.0 searches, inspect `complete`, `truncated`, `partial`, and
`scope.coverage`. Coverage entries identify pruning such as ignore rules, hidden
files, excludes, size limits, binary content, symlinks, encoding, and Unicode
forms. Preserve the supplied values; never reconstruct or improve them in the
caller. Empty rows with incomplete, enabled, or unknown coverage do not prove
that content is absent.

For browser batches, preserve the returned `status`, `complete`, `partial`,
`truncated`, `lostTo`, `contentVerified`, and all item-level failures. A partial or
indeterminate side effect must be inspected before any retry; do not blindly
replay it.

## Older or unknown versions

Do not assume a `codemode --version` flag. For MCP use initialization
`serverInfo.version`; for CLI read the package version beside the verified CLI
path. Completeness-sensitive searches require the 0.9.0 contract and the actual
metadata fields above. Older runtimes or missing metadata may support bounded
positive reads, but disclose the version and coverage limit and do not use them
to prove exhaustive absence. Never update the package automatically.

## Account, host, and filesystem boundaries

The MCP call has no account or host selector, and codemode's browser runner does
not pass an explicit `--account` or `--host` to native Aside. Verify the server
process and selected account context before using browser state or account-owned
paths. When the task names a nondefault account or remote host and that context is
not already verified, use native Aside's explicit `--account`/`--host` route
instead of silently accepting a default profile. Unsupported execution flags being
silently ignored are tracked in
[aside-codemode issue #44](https://github.com/lidge-jun/aside-codemode/issues/44).

The filesystems are role-specific:

- CLI/MCP guest `fs` is aside-codemode's guarded API, with calls such as
  `fs.readMany`; its configured roots and `--cwd` rules apply.
- Native Aside REPL `fs` uses calls such as `fs.readFile` and resolves within the
  selected account/session/project roots. Its relative path base differs between
  `aside repl` and the in-app agent REPL.
- Codex host Code Mode exposes its own host tools. It does not inherit guest
  globals such as `search`, `fs`, `actions`, or `browse`.

The installed `cm` helper belongs only to the native Aside REPL. Load the selected
account's copy by its verified absolute path, then use `cm.run` for tab budgeting
while native `openTab`, `snapshot`, locators, and `cua` continue to do browser
work. Do not infer that `cm`, an account skill, or Aside's MCP registration exists
in an external caller.

## Separate setup

Installation, upgrades, MCP attachment, root configuration, and browser enablement
are setup work, not part of these execution recipes. Follow the current
[aside-codemode package documentation](https://github.com/lidge-jun/aside-codemode#readme)
or [npm package page](https://www.npmjs.com/package/aside-codemode) only when the
user separately authorizes setup. Do not add `--force` or change an account's
configuration as a convenience fallback.

## Context selection in the 0.9.1 source contract

The implementation merged in [codemode PR #48](https://github.com/lidge-jun/aside-codemode/pull/48)
adds explicit CLI `--account` and `--host`, optional `browseContext` configuration,
and **per-call MCP** `account`/`host` fields. Inspect the actual installed schema:
0.9.0 installations still use the smaller schema described above. A source merge
or version string is not proof that this caller has loaded the updated server.

When the exposed schema supports it, a context-pinned MCP call is:

```json
{"code":"return await browse.context();","account":"u1","host":"local","timeoutMs":30000}
```

Use both selectors when identity matters. `browserContext` reports requested
account/host and whether each came from explicit input, config or inherited
native defaults. It is a routing report, not proof of authenticated browser
identity. `await browse.context()` exposes the same selection to guest code.
Inspect real page/account state separately and preserve output-truncation signals.

Do not use local artifact materialization for an unverified remote/inherited host;
there is no verified transfer mechanism in this skill. Use explicit `host: "local"`
for local capture/report output. Missing or partial identity cannot safely justify
reusing cached authenticated data or persistent approval state. The additional default-context and administrative-argument guards shipped in
0.9.2; the original 0.9.1 routing API alone does not include them. Inspect the
installed version and actual schema before selecting a path.
