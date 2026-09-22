# Source inventory

Observed 2026-09-22. This is source/documentation evidence, not a live login or
browser compatibility certification.

- aside-skill baseline: `a3fa0b328854258ca269a310d35d22e39120d03b`.
  The entrypoint routes only exec/repl. The installed local copy is older; the
  installed copy is outside this change's write scope.
- aside-codemode: GitHub main and npm report 0.9.0; the sibling checkout reports
  0.8.1. Recipes must use the current published contract, with runtime identity
  recorded separately. Do not update that sibling or its untracked work.
- aside-visualizer: skill name `dev-visualizer`; it belongs inside an Aside
  account. Its September 16 README still says codemode lacks preferCSSPageSize,
  but current codemode browse/schema.js accepts that option and margin. Do not
  inherit the stale limitation. Source acceptance is not proof of CSS fidelity.
- Installed Aside CLI reports 1.26.906.1630 and advertises 1.26.916.1741. The app
  reports 1.0.914.1. No update was performed.
- [Official components changelog](https://docs.aside.com/changelog/components)
  lists 1.26.917.1731 (September 17): credential suggestions can span unlocked
  accounts while filling uses the owning account. September 14 introduces the
  Aside Vault naming/setup flow.
- [Official developer docs](https://docs.aside.com/help/developers) now show a
  signed Windows PowerShell installer and PATH setup. The same page retains a
  stale --session example; installed help/guide and the components changelog
  instead name `aside session resume`.
- [Official Vault docs](https://docs.aside.com/help/password-manager) describe
  Touch ID/Windows Hello as vault unlock mechanisms. Do not prescribe disabling
  biometrics from an older build's observation.

## Execution and verification boundaries

The external caller's shell, its native Code Mode, Aside's exec agent, Aside CLI
REPL, and an MCP registered only inside Aside are distinct environments. A tool
name in documentation is not proof that it is exposed to the current caller.
Preserve account, host and result-completeness boundaries when routing work.

Existing repository checks assert historical text, remote synchronization and
installed copies; they are unsuitable as this change's acceptance gate. The
skill-creator validator reads aside-jun/SKILL.md but requires PyYAML. No package
installation is needed solely to validate this documentation.

## Process scope

V1 subagents are exposed through spawn_agent/send_input/close_agent; no native
agent_type selector exists. Sol is explicitly requested. A question about using
a read-only Sol design consultant in place of the skill's native architect
requirement is pending; no dependent plan approval is claimed before an answer.
All new work remains local. No publishing, deployment, app updates, account
configuration changes or installed-skill synchronization is authorized here.

## Sol compatibility audit

Read-only Sol investigator 01a0c7f7-7cba-74d2-81e2-d7ac02cf5960 confirmed the
Windows installer/PATH and Vault policy changes above. Accept current official
Vault policy over a blanket disable-biometrics recommendation. Preserve older
CLI purge/getTabs/hidden logging measurements only as dated observations.
Session resume and current selected-account discovery belong in normal recipes;
revalidate any undocumented flag before using it. The CLI's top-level model
flags and resume-specific parser are separate: absence from a subcommand's help
alone does not prove a global flag is rejected. No new login/runtime probe ran.

## Fresh caller-recipe probe

Fetched aside-codemode main b76c911318ebe64f03dffb7bb27b37b23ebab777 to a temporary
source directory without npm install or changing the global link. Package 0.9.0.
Executed Node + bin/codemode.mjs with --config, --cwd and --code-file against
temporary two-file fixtures only; config roots narrowed to the scratch directory,
browser disabled, inherited CODEMODE_* overrides removed for the child process.

- search.content + fs.readMany returned both expected TODO rows and excerpts,
  ok:true, complete:true, truncated:false, partial:[], full scope.coverage. Exit 0.
- Two matching lines with max:1 returned complete:false, truncated:true. Exit 0;
  this demonstrates why process success does not mean complete search.
- ../not-authorized.txt returned EROOT, hostCallFailures:1, exit 1.
- import("node:fs") returned EGUESTIMPORT, exit 1.
- Baseline quick_validate passed using existing cached PyYAML via PYTHONPATH.
- Baseline local-link scan covered README plus 10 skill Markdown files; 0 broken
  relative targets. git diff --check exited 0.

These prove the proposed local guest recipe, not browser/Claude/MCP end-to-end
compatibility. Re-run snippets extracted from delivered documentation in C.

## Raw MCP proof and routing boundary

Sol investigator 01a0c7f7-7c02-7bd3-a637-3f6f4432867c supplied a scratch harness at
/tmp/aside-codemode-caller-smoke.Gk7zOL/mcp-smoke.mjs. Main inspected it and reran
it against its exact-main 0.9.0 snapshot with browser disabled. initialize returned
serverInfo aside-codemode/0.9.0; tools/list exposed execute_code with required
code:string and optional timeoutMs:number, additionalProperties:false. tools/call
returned isError:false with execution JSON in content[0].text; capped search still
reported complete:false/truncated:true and retained scope.coverage. Exit 0.

Source anchors at b76c911318ebe64f03dffb7bb27b37b23ebab777: src/tools.js:23-35
schema, :48 result envelope. src/host/browse/session.js:432 and :647 spawn only
['repl', source], with no explicit host/account arguments. Do not mistake
--account on --install-mcp for per-call account selection. An MCP process cwd
belongs to its caller configuration; execute_code has no cwd field. Use absolute
guest paths or a verified configured cwd. Tool qualification belongs to the
caller; never assert that an Aside-local inventory is attached elsewhere.

A browser-disabled configuration was activated with browse.exec on a public URL:
EDISABLED, hostCallFailures:1, exit 1, before browser launch. Its error suggests a
config-writing command, but that suggestion is not task authorization. The bridge
must report the disabled capability without running --enable-browse automatically.

## Authorized upstream issue

During implementation the user explicitly authorized filing codemode improvement
issues. Existing issues 1-42 were inspected for duplicates. Current 0.9.0 accepts
`--host sample-host --account u99 --code 'return 1'` with ok:true/result:1 and
exit0, although those selectors do not propagate to browse session spawning.
Opened https://github.com/lidge-jun/aside-codemode/issues/44 with the browser-free
reproduction, exact source revision, propagation anchors and requested acceptance
checks. No wrong-account browser operation was performed. This authorization is
for issue filing; it does not authorize changing/publishing either repository.
