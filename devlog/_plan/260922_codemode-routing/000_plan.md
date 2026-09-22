# Direct codemode calls from coding agents

Codex and Claude Code should select aside-codemode for an Aside-related batch and
invoke an available CLI or caller-attached MCP themselves. Aside exec remains the
judgment/delegation route, and Aside's dev-visualizer owns visual artifacts. This
unit makes those choices actionable without copying either extension's runtime.

## Loop specification

- Archetype: satisfy-spec; C3 documentation/integration contract update.
- Trigger: user requested current Aside + own codemode/visualizer integration,
  explicitly including external Codex/Claude callers and Sol subagents.
- Goal: concise portable skill with executable caller recipes and honest failure
  handling; README is the general source of truth.
- Non-goals: sibling repository changes, installed skill synchronization, package
  upgrades, account/MCP configuration mutation, publishing, pushing or merging.
- Verifier: skill-creator quick_validate on aside-jun (baseline valid using the
  existing cached PyYAML); local Markdown target check (11 files, zero broken
  links on baseline); git diff --check; isolated codemode smoke and source review.
  Commands and exact fixture recipes are locked in the implementation design.
- Stop: all four goal criteria met, two work-phases closed, local commits recorded.
- Memory artifact: this unit and .codexclaw session receipts, not global memory.
- Outcomes: DONE on evidence; NEEDS_HUMAN for required process/capability decision;
  BLOCKED only under the host's repeated-block rule; no invented budget exhaustion.
- Escalation: new scope, external writes or required unsupported capability. No
  time/token/cost cap supplied. Use bounded jobs and disjoint Sol waves; no total
  dispatch cap. Read-only network research and scratch fixtures are allowed.

## Dependency order and ownership

| Work-phase | Deliverable | Depends on |
|---|---|---|
| wp1 | Source-backed, independently reviewed roadmap; documentation only | none |
| wp2 | Caller router, executable examples, current compatibility and verification | wp1 |

Main owns SKILL.md, README.md, agents/openai.yaml, integration and phase evidence.
A Sol worker owns codemode.md only. Another owns visualizer.md only. A third owns
credentials.md, host-windows.md and compatibility.md only. Scope packets prohibit
Git branch operations and writes to sibling/installed paths. Independent Sol
reviewers examine plans and final behavior; they do not count as implementation.

## Design consultation

The live V1 transport has no agent_type field. The user was asked whether a
read-only Sol design consultation may replace the skill's native-architect
requirement. That question remains pending; no dependent approval is claimed.
The general design consultant is 01a0c7fb-2afd-7590-a692-a2c713c3378f. Its proposal,
main dispositions and same-context reflection will be recorded before A.

## Evidence

[Source inventory](001_research.md). Existing historical ship checks hardcode old
wording, remote/main synchronization or installed copies, so they do not observe
this scoped change. They are retained as historical evidence, not weakened to
manufacture a pass. New acceptance is semantic routing plus executable examples,
not phrase-matching tests.

## Decision and closure log

Pending proposal/reflection and user process decision. No product files changed.

### Design proposal dispositions

Sol consultant 01a0c7fb-2afd-7590-a692-a2c713c3378f returned PORT-01..07.
Accept PORT-01 concise router, PORT-02 distinct execution surfaces, PORT-03
absolute CLI/code-file invocation, PORT-04 workload boundaries, PORT-06 retained
safety/verification, PORT-07 reuse rather than wrapper. Accept PORT-05 Aside
composition and remote retrieval; amend its assurance recommendation: report QA
scales to the requested output, but this bridge does not invent supported
`draft/standard/publication` flags absent from the installed visualizer contract.

The first reflection reported two mismatches. Main dispositions:
- PORT-03: rebut factual premise. The pending question concerns substitution of
  the native architect role, not shell process substitution. No `<(...)` recipe
  was proposed; nevertheless portable examples explicitly exclude it.
- PORT-05: accept clarification, reject new named assurance API. Preserve requested
  output quality and actual PDF verification while stating the installed skill
  owns detailed QA. No unsupported tier/flag is advertised.

The same consultant receives this amended plan for reflection. Native architect
exception remains pending and is not inferred from silence.

Same-context reflection of the amended revision: PORT-03 ALIGNED and PORT-05
ALIGNED; all other PORT decisions were already aligned. This is a completed
technical Sol consultation, not a claim that native architect setup exists.

### Continuation checkpoint

The host continuation hook requested P->A, but the user has not answered the
explicit native-role exception question. A hook reminder does not resolve that
authority gap. P remains active; no A approval or implementation is claimed.
Independent preliminary reviewer 01a0c804-4280-73e1-b4dc-b3f445393cde is still
working. Its observed browser-example gap was addressed with a literal rendered
batch in 021 and a fresh actions.check result (all error arrays empty), explicitly
not a live browser claim.

### Awaiting user decision

The native-role substitution question remained unanswered across the original
user-triggered goal turn and two automatic continuations. No forward phase edge
was taken; FSM remains P. All independent discovery and caller-contract probes
are complete. The preliminary reviewer was directed to return current findings
without further reads; its handle is preserved above. This is a required user
process decision, not test failure, budget exhaustion or implementation success.
Resume by recording the user's explicit choice, inspecting goal/FSM state, and
finishing the roadmap review before any product change. Do not infer approval
from a continuation hook or elapsed time.

### User-approved continuation

The user answered "ㅇㅇ 진행해" to the native-role substitution question. Record
that explicit approval: use the completed read-only Sol design consultation in
place of the unavailable native architect selector for this task. The technical
proposal and same-context ALIGNED reflection remain valid. This does not claim
that a native architect tool has appeared. Host get_goal still reports blocked;
the host exposes no resume mutation here, so do not recreate or edit its database.
Continue the explicitly authorized work on the same goalplan and report persisted
phase accurately; automatic HOTL continuation is not claimed while host is blocked.

### A synthesis

Reviewer 01a0c804-4280-73e1-b4dc-b3f445393cde returned GO-WITH-FIXES (blockers=2).
Accepted both: 020 now specifies exact section replacement anchors and the older
runtime/missing metadata outcome. Missing coverage cannot prove exhaustive
absence; bounded positive work remains possible without silent installation.
The approved native-role exception is no longer a blocker. Re-review requested.

### wp1 closure

Same reviewer rechecked both amendments: blocking_issues:0, VERDICT: PASS.
Roadmap is ready. Evidence is source inspection, literal recipe smoke and
structural checks; no production functionality has been delivered in wp1.
Direction for wp2: implement the locked caller/reference map and verify final
snippets. The native-role exception was approved; no further permission question
is required for Sol design consultation in this task. Host goal remains blocked
because its exposed API has no resume operation; explicit user continuation owns
this work. Do not claim automatic Stop arming.
