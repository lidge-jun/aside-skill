# Executable caller recipe specification

This document locks the code values for the new codemode reference. Prose can be
edited for clarity; the code below must be executed from the delivered reference
in C rather than inferred from this specification.

## CLI guest program

Save as a task-owned UTF-8 `batch.js`, then supply its absolute path to
`--code-file`. `--cwd` points at the authorized project root.

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

`hits` is deliberately returned intact. `excerpts` can contain errors or skipped
rows despite top-level `ok:true`. Never turn that into a complete-content claim.
The TODO and .txt pattern are example inputs, not compulsory search scope.

Bash invocation after resolving actual paths:

```bash
"$CODEMODE_NODE" "$CODEMODE_CLI" --config "$TASK_CONFIG" \
  --cwd "$PROJECT_DIR" --code-file "$JOB_FILE"
```

PowerShell invocation with the same explicit Node/CLI pair avoids `.cmd` argument
ambiguity and embedded guest quoting:

```powershell
& $codemodeNode $codemodeCli --config $taskConfig --cwd $projectDir --code-file $jobFile
if ($LASTEXITCODE -ne 0) { throw "codemode failed: $LASTEXITCODE" }
```

`CODEMODE_NODE`, `CODEMODE_CLI`, `TASK_CONFIG`, `PROJECT_DIR`, `JOB_FILE` are caller
variables populated with discovered/authorized absolute paths. They are not
codemode environment configuration keys or instructions to modify shell profiles.
The exit check is necessary but not sufficient; read the JSON result too.

For an already configured verified CLI command, the equivalent is
`codemode --cwd /absolute/project --code-file /absolute/batch.js`.
Configuration roots constrain accessible paths; cwd does not add a root. Explicit
config is optional for normal use and useful for isolated proofs. Inspect
CODEMODE_* overrides because individual environment keys can override JSON.

## MCP payload

Only call a current-host tool whose identity and live schema identify the
aside-codemode server. At the tested 0.9.0 contract:

```json
{"code":"return await search.count({path: '/absolute/project', query: 'TODO'});","timeoutMs":30000}
```

No `cwd`, `account` or `host` key belongs in this payload. Absolute paths avoid
assuming the server cwd. Client-qualified tool names differ by host. Read MCP
`isError` and the execution JSON in text content, then preserve result completeness.

## Browser schema discovery

This is safe shape discovery; it makes no browser request:

```js
return {
  exec: actions.describe("browse.exec"),
  capture: actions.describe("browse.captureMany")
};
```

Use the returned contract to construct the user's known independent URL batch.
No guessed selector or implicit account switch. `browse.readText` is fetch-first;
when a source needs a logged-in rendered page, verify rendered content using
browse.exec or native Aside rather than trusting a fetch result's HTTP status.

## Acceptance commands already exercised in discovery

Source version: aside-codemode 0.9.0 at
b76c911318ebe64f03dffb7bb27b37b23ebab777, downloaded only to a scratch source tree.
Normal two-file search/read, capped search, EROOT and EGUESTIMPORT were executed
with explicit scratch roots and browser disabled. Raw MCP initialize/list/call was
also executed with browser disabled. See 001_research.md. These runs validate the
planned shapes; completion still needs extraction from final codemode.md.

A browser-disabled negative was also executed in discovery: browse.exec with one
public URL returned EDISABLED/exit1 before launching the browser. Do not execute
the config-writing remedy mentioned in that error without setup authorization.

## Known-page rendered batch

For known independent pages, after confirming the required current account/host
context, the direct codemode guest is:

```js
const result = await browse.exec({
  urls: ["https://example.com", "https://example.org"],
  snapshot: false,
  fullText: true,
  maxTextChars: 4000
});
return result;
```

Replace example URLs with task-authorized, already-known URLs. Inspect unfamiliar
page structure natively first. No invented selector or login assertion is hidden
in this example. The returned item text and completeness must be inspected; title,
HTTP 200 or completed status alone does not prove content or authentication.

Validated in discovery against current 0.9.0 with
`actions.check("browse.exec", {urls:["https://example.com","https://example.org"],snapshot:false,fullText:true,maxTextChars:4000})`:
ok:true, missing/unknown/typeErrors/invalid all empty, CLI exit 0. This is schema
validation only; no browser navigation was run. C repeats extraction/schema
validation on the final snippet and must not label it browser E2E proof.
