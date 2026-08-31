# 010 - references/deep-research.md

One new reference. It must be usable without reading the devlog.

## Sections

1. **Why Aside for research.** Lead with the signed-in advantage and the two measured
   probes. A reader who does not need a login should be told to use ordinary search
   instead - the lane is not a default.
2. **Surface routing table.** Codex / repl / exec, one row per rung, each with the
   call and what the probe returned. This is the load-bearing section.
3. **Recipes.** Whole flows that fit one repl invocation: a signed-in search sweep, a
   structured-API pull, a transcript read, a prior-art check against history.
4. **The exec template.** For research that needs an account action mid-flow, built on
   the three standing clauses plus the no-questions ladder.
5. **Claim ledger.** Table format with a proving-surface column, plus the promotion
   rule from candidate to verified.
6. **googleSearch is not a rung.** Verbatim error and why.
7. **Snapshot handling.** The daemon's runtime warning, and that filtering a tree for
   links trips it.

## Rules to state explicitly

- Discovery stays on Codex's hosted search. Aside is proof, not discovery, except when
  the source itself is behind a login.
- A signed-in snapshot is stronger evidence than a snippet and weaker than an official
  document. Record the surface so the reader can weigh it.
- State plainly what a snapshot proves: that the opened source displays the claim, not
  that the claim is true. Opening a logged-in dashboard proves what the dashboard says.
  That is exactly the distinction the proving-surface column exists to keep visible,
  and it is what keeps this lane compatible with an ordinary source-proof discipline.
- Never filter or truncate a snapshot to make research output tidy.
- Notes go under `~/.aside/u/0/`; Codex copies them into the workspace.
