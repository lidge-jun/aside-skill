# wp2 — Caller-facing routing and references

Consumes wp1's locked roadmap. Revalidate the named source contracts at P.
This is a documentation change, not a codemode runtime fork or an installer.

## Exact file map

| Operation | Path | Before → after |
|---|---|---|
| MODIFY | aside-jun/SKILL.md | 495-line exec/repl manual → compact common preflight, route table, direct-call rule, delegation boundary and reference links |
| MODIFY | aside-jun/agents/openai.yaml | authenticated browsing description → authenticated browser + code-mode batch description; preserve implicit selection |
| MODIFY | README.md | browser CLI skill → Codex/Claude-compatible router with direct CLI/MCP distinction, examples, optional setup, updated layout and evidence limits |
| NEW | aside-jun/references/codemode.md | portable caller cookbook specified below; no copied runtime or per-machine paths |
| NEW | aside-jun/references/visualizer.md | Aside account dev-visualizer handoff specified below |
| NEW | aside-jun/references/exec.md | focused current exec contract extracted from entrypoint, with dated measurements separated |
| NEW | aside-jun/references/compatibility.md | dated CLI/app/package matrix, official URLs, known contradictions, source vs runtime proof |
| MODIFY | aside-jun/references/credentials.md | mandatory disabled biometrics/internal settings edits → current Vault access policy and explicit human unlock boundary; preserve dated Apple Passwords evidence |
| MODIFY | aside-jun/references/host-windows.md | universal broken-PATH/junction premise → signed official installer + fresh terminal/PATH discovery; historical fallback only if discovery fails |
| MODIFY | aside-jun/references/repl-api.md | undated persistence/getTabs facts → one-process vs one-shot lifetime plus guide-before-use and dated probe caveat |
| MODIFY | aside-jun/references/scheduling.md | guaranteed expiry/mandatory save setting → dated measurement and optional user-requested persistence; current resume commands |
| MODIFY | aside-jun/references/permissions.md | automatic full-access/default claims → task-authorized scope, dated diagnostics, no automatic retry or config changes |
| MODIFY | aside-jun/references/deep-research.md | every source proved individually → independent known-page batch links to codemode while first-look/login stays native |

No DELETE operations. Keep historical refskill-aside.md explicitly historical.
Do not change sibling repos or global skills. Fix stale visualizer limitations in
this bridge; identify their upstream origin rather than editing the sibling.

## SKILL.md replacement contract

Frontmatter keeps `name: aside-jun`. Description covers authenticated Aside browser
work, explicitly requested Aside code-mode batching, and visual artifacts delegated
to Aside; excludes unrelated ordinary local search and public HTTP fetching.

Body order:
1. Purpose: one entrypoint for compatible coding agents. Current user/tool
   authorization wins. Dependencies optional; never install just to use skill.
2. Preflight: resolve selected host/account from current Aside CLI help/account
   list when browser use needs them. Use actual absolute account root. Read one
   OS host reference for exec deadlines; read current `aside guide repl` before
   native REPL. Reading help must not mutate settings.
3. Route table: native one-file/first-look/dependent/sign-in; codemode independent
   multi-item workloads and directory searches inside the requested Aside/code-mode
   workflow; exec judgment; exec + dev-visualizer composition. Public HTTP stays
   on host source reader unless user requested Aside.
4. Direct caller rule: caller-attached discovered MCP with its live schema, else
   verified installed CLI/absolute Node+CLI pair using --code-file. Do not put
   guest globals in Codex functions.exec, shell JS or native Aside REPL.
5. Result rule: guest `return`; preserve envelope metadata and item failures,
   root/host/account boundaries, no blind replay of indeterminate effects.
6. Relevant reference links and minimal exec/repl constraints: one-shot scope,
   inspect-act-verify, deadline, exit0 != completion, no guessed tools/refs.

## codemode.md content contract

Reader: coding agent outside Aside needing a concrete invocation now.

- Distinguish CLI guest, caller-attached MCP execute_code and Aside REPL cm helper.
- CLI: discover installed command; use absolute resolution supplied by setup when
  available, otherwise inspect PATH once. --code-file is preferred, stdin is a
  documented alternative, --cwd fixes relative paths but does not grant roots.
- Bash and PowerShell pass paths as separate quoted arguments; no embedded code
  string interpolation. No npx auto-install fallback.
- Guest: async body, await + return; no Node require/import/process or browser
  page/fs assumptions. Use actions.describe/check for installed API discovery.
- No-auth local example: search.content then fs.readMany bounded paths; return
  original `hits` plus excerpts, keeping complete/truncated/partial/scope. Scope
  coverage is preserved when supplied by 0.9.0, not reconstructed.
- Browser example: known independent URLs in one browse.exec; discovered selectors
  only; preserve item errors/status and verify actual content. `browse.readText`
  is fetch-first and must not be promised authenticated-rendered proof.
- MCP: names are caller-specific; inspect tool schema. Aside's --install-mcp
  registers only in Aside; it does not attach tools to Codex/Claude. Caller MCP
  configuration belongs to explicit setup. No fabricated client commands.
- Missing CLI/MCP returns clear prerequisite and stays within available authorized
  native tools. EDISABLED does not authorize --enable-browse.
- If account/remote host routing is unsupported/unverified by codemode, use native
  Aside's explicit --account/--host rather than silently using a default profile.
- Setup section links official package docs; no automatic --force/install.

## visualizer.md content contract

- Repository aside-visualizer installs as account user skill dev-visualizer.
- Inspect selected account/host installed SKILL, not CLI builtin catalog alone.
- Explicit delegation prompt: use dev-visualizer, authorized inputs, requested
  format/template, output inside selected account/session artifacts, exact paths
  and verification evidence, no publishing or questions from unattended exec.
- Missing extension: report and use an already available requested format owner;
  do not pretend it loaded or copy it into global coding-agent skill folders.
- Data collection can use direct codemode first; composition belongs to visualizer.
- PDF preferCSSPageSize/margin accepted by current codemode, unlike September 16
  visualizer prose. pageBox measurement != CSS fidelity; inspect actual PDF.
- No system Chrome required for native Aside page.pdf; standalone exporter has
  its own dependencies. Avoid file://; use small data URL or task-owned loopback.
- Local artifacts require actual retrieval when Aside runs remotely.

## exec.md content contract

Move the current entrypoint's operational knowledge here, but keep only actionable
rules: task scope, chosen permissions (full-access only for already authorized
paths), account-specific absolute output/read paths, noninteractive no-question
clause, host deadline, artifact verification, current session control verbs and
checkpoint before retry. Permission is a capability choice, not authorization.
Prompt fences are instructions, not filesystem enforcement. Logs may hold private
material; do not prescribe hidden --log-dump without current parser verification.
Persistence settings change only when requested. Link deep credentials/scheduling
and historical permissions measurements rather than restating them.

## Compatibility and surgical edits

compatibility.md records 2026-09-22 CLI 1.26.906.1630, offered 1.26.916.1741, app
1.0.914.1, official components 1.26.917.1731, package main/npm 0.9.0 and local
0.8.1. No live browser, updated Windows or Claude integration claim. Prefer current
help + source over stale website flags, with conflicts named. Date old 15-minute
purge, getTabs absence and passwordManager availability observations.

credentials.md removes universal disabled-biometric advice and internal JSON edit
recipes. Current Vault access policy and unlocking remain user-controlled; locked
vault/MFA => explicit blocked result, not an attempted security-setting repair.
Retain literal helper API names and dated evidence. Never infer selected account
from which unlocked account owns an autofill credential.

host-windows.md adds official signed installer URL/publisher validation as setup
only, PATH/new-terminal check then dated junction fallback. No certificate changes
or live installation in this unit.

repl-api/scheduling/permissions/deep-research receive only the cross-reference and
compatibility corrections above. Existing deadlines and real path guards stay.

## Verification scenarios and observable outcomes

- External Codex with CLI but no MCP: selects direct CLI + --code-file, not exec
  delegation or fictitious MCP. Claude same available capability => same recipe.
- MCP exposed: schema inspected and bounded guest sent with actual field names;
  a generic tool named execute_code alone is insufficient identity proof.
- Missing/disabled codemode: reports prerequisite, no install/config mutation.
- Single click, current tab, login wall, dependent wizard: native route preserved.
- Multi-item search/capture: direct batch, no metadata-stripping map-only answer.
- Partial/truncated search or per-file error: visible in return; absence not proved.
- Guest import and outside-root reads: errors reported, no widening or blind retry.
- Visual report: selected Aside account skill + output proof; requested DOCX/PDF
  preserved and remote/local path distinction explicit.

Execute local fixture recipes under explicit scratch roots, browser disabled and
known rg path. Confirm positive two-file read/search and negative root escape or
invalid guest import. Verify behavior of installed 0.8.1 separately from 0.9.0
source; optionally use a temporary source snapshot of exact main for a current
contract smoke without altering the installed package. Persist commands, versions,
output and limits. Do not run broad unrelated product suites.

Static checks: quick_validate aside-jun using an existing PyYAML runtime;
Markdown local-link checker over README.md + aside-jun/**/*.md; git diff --check.
Baseline: validator valid and 11 Markdown files with 0 broken links. A unit-local
standard-library check can extract and execute the exact documented guest snippets
against scratch inputs if needed; validate it with a corrupt snippet/target so an
empty or wrong input cannot pass silently. Independent Sol forward readers receive
realistic requests and capability lists, without expected routing answers.

## Planned implementation packets

- Main: entrypoint, README/UI metadata, exec.md and small compatibility cross-links.
- Worker codemode: NEW codemode.md only; source-verified runnable examples.
- Worker visualizer: NEW visualizer.md only; verified delegation boundary.
- Worker compatibility: credentials.md, host-windows.md, NEW compatibility.md only.
- Independent reviewers: plan audit then final routing/semantic review; no writes.

## Design reflection amendments

- Portable examples use real --code-file paths or stdin, never shell `<(...)`
  process substitution. The pending user process question is about native role
  substitution, not shell syntax.
- Visualizer QA scales to the requested deliverable and its installed contract.
  Do not introduce `draft`, `standard` or `publication` as supported flags or
  machine-enforced profiles; this sibling version does not document such an API.
  Explicitly requested PDF still requires actual export and artifact inspection.

### Locked direct-call values

Current MCP input is `{code: string, timeoutMs?: number}` with no extra fields;
output execution JSON is `content[0].text` and failures can set `isError:true`.
Guest `return` becomes `result`; console output goes to `logs`. MCP has no per-call
cwd/account/host fields; use absolute guest file paths and verify server process
scope. codemode's browser runner spawns `aside repl` without explicit --account
or --host. A requested nondefault account/remote host must use native Aside's
explicit route unless the existing codemode execution context has been verified.

## A-review fold-back: exact modification anchors

- SKILL.md: replace entire body and description with the replacement contract
  above; keep name. The existing `## Host layer`, `## exec`, `## repl` operational
  material is consolidated in exec.md/repl-api.md rather than lost.
- agents/openai.yaml: replace only interface.short_description with
  `Authenticated Aside browsing, code-mode batches and artifacts`.
- README.md: replace introductory paragraphs before `## Install`, `## Layout`,
  `## What it covers`, `## Requirements`; retain Codex/Claude directory guidance,
  correct copy-on-update nesting and preserve supported references. Add direct
  caller example linked to codemode.md; no host MCP registration assumed.
- credentials.md: replace `## Leave biometric unlock off` through the next
  macOS-only heading with current Vault unlock/access policy. Replace the opening
  `leave it off`, Apple Passwords step 2 and final Biometrics disabling directives;
  add dated multi-account semantics in `## Choosing a route`. Retain old provider
  observations with explicit dates and no new current-runtime claims.
- host-windows.md: add current installer/discovery immediately before `## CLI
  해석과 junction 결함`; label junction paragraph at `사용자 PATH에` historical;
  resolve Get-Command aside first before current/version fallback snippets.
- repl-api.md: replace opening persistence discussion before `## Getting a page`
  with interactive-process vs one-shot contract and current guide prerequisite;
  replace getTabs sentence with dated absence/help contradiction caveat.
- scheduling.md: replace opening expiry assertion, rename `## Sessions expire
  after 15 minutes unless saved` as historical 1.26.902 measurement, replace
  mandatory `Set it once and leave it on` with explicit-request-only setting;
  qualify indefinite/purge claims as historical, link compatibility.md.
- permissions.md: add current scope note before `## The mechanism`; replace
  default full-access recommendation and `Under guard it cannot` absolutes with
  authorized-scope choices. Rename `## Two hidden CLI flags` as historical parser
  observations, replace automatic re-run logging advice with inspect-before-retry.
- deep-research.md: add batch routing after `## Who does what`, keep native first
  inspection/login and preserve public HTTP default. Link codemode.md.

## A-review fold-back: older-runtime decision

No codemode --version is assumed (installed CLI rejects it). Use MCP initialize
serverInfo.version when available, or the resolved package.json alongside the
verified CLI path. Feature discovery uses actions.describe/check without browser
launch. For completeness-sensitive searches require the 0.9.0 contract and actual
complete/truncated/partial/scope.coverage fields. Missing metadata or older runtime
must not prove exhaustive absence. Report the limitation; use already-authorized
native capability or request/update setup only if user separately authorizes it.
Ordinary bounded positive reads may run on an older verified compatible API with
version and coverage limits disclosed. No automatic package update. C includes a
simulated older/missing-metadata routing scenario, plus actual 0.9.0 fixture proof.
