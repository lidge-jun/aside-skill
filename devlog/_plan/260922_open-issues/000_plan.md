# Resolve open issues and land on dev

The user requested current issues resolved and merged into dev. This work covers
aside-codemode #44/#45 and aside-skill #1/#2 plus existing skill PR3. Runtime
package releases and app upgrades are not part of this request.

## Scope and completion

C3 API/memory work with C4-level care for execution identity. Main owns skill
helpers, integration review and repository publication; Sol workers own separate
codemode checkouts for context routing and memory-bound search. Existing dirty
issue45 work was snapshotted into a task-owned worktree; the original is untouched.
The user's previously approved read-only Sol architect substitution applies.

- #44: explicit immutable browseContext config/CLI selection and honest report;
  malformed/unknown execution flags rejected before effects, no changed defaults,
  run/raw/report and cache/approval context separation verified. Configured context
  is not proof of resolved remote account identity. Fail unsupported remote file
  transfer paths rather than presenting remote paths as local files.
- #45: bound streamed record/raw/retained bytes before unbounded parse/allocation;
  disclose any loss, retain correct small/exact-cap semantics, UTF8/chunk/partial
  cases, and deterministic pathological fixtures. No private corpus needed.
- Skill#1/#2: provide explicit REPL helper for session directory creation and
  element capture via page clip. Do not claim the third-party daemon is repaired.
  Native defects remain described as such; close only this repository's supported
  workflow issue with an explicit mitigation outcome after real runtime proof.

## Order and file map

1. Read issues and current dev/main/dirty work; separate ownership (complete).
2. Design helper and review execution-context/memory contracts before integration.
3. Add aside-jun/scripts/repl-helpers.js, behavioral unit tests in the existing
   unit, and precise usage in repl-api.md/SKILL.md. Main implements after Sol design.
4. Workers update existing codemode source/test/structure owners in their task-owned
   checkouts; no dependencies or package version changes.
5. Targeted tests, full zero-dependency codemode suites, independent reviews and
   real task-owned Aside fixture capture. CI must run on actual PR heads.
6. Create aside-skill dev from existing main (no dev exists); retarget PR3 to dev.
   Codemode fix PRs target existing dev. Merge only green reviewed heads, preserve
   original human work, verify remote dev SHA and issue closure evidence.

## Verification and authority

Plan verifier: npm test/node --test and structure:check in codemode; source-extracted
022_verify.py plus JS helper tests and real native REPL fixture in skill. Expected
outcome DONE when code/workflow fixes and exact dev merges proven; report third-party
limits rather than declaring upstream fixed. User authorized push/PR/merge and issue
updates. No blanket external messages, deployment, provisioning or release. No new
host goal is required for this follow-up. No invented time/token bound.

## Threat boundary

Assets are user account/browser state and process memory. Untrusted CLI/config and
browser outputs must not select a different account silently or induce unbounded
allocation. Validate at input boundaries, preserve request context per execution,
keep cache/approval state separated, emit no credentials, and test rejection paths
without real account mutations. Skill helper gets explicit Page/locator and session
relative output only; never monkeypatch native methods or bypass fs guards.

## Progress: codemode #45

Existing owner committed and published PR46 while initial worktree inspection was
in progress. Main did not modify that checkout. The exact published patch was
copied into a task-owned worktree for independent read-only review. Sol reviewer
reported 51 targeted tests and full 1,073 passes/0 failures/1 known filesystem
skip, plus structure and identity checks. PR46 was merged into dev by the owner
at 0018f042406baf68cba76e54536a687bcf3e6a9c; its tree equals reviewed head1116376.
Main verified the merge and closed issue45 with explicit dev-only delivery scope.
