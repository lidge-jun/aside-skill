# wp1 — Lock the caller contract

Documentation-only cycle. NEW 000_plan.md, 001_research.md, this document and
020_routing.md within the existing numbered devlog convention. No production
skill/reference changes in this cycle.

The roadmap must distinguish five execution surfaces: external host shell,
external host's native Code Mode, caller-attached codemode MCP, Aside agent and
Aside CLI REPL. Direct CLI execution must work without invoking Aside's agent or
registering any MCP. A tool that exists only inside Aside is not available to
Codex/Claude by inheritance.

Before closing, require the complete exact-path change map in 020_routing.md,
current source anchors, design proposal/reflection and independent audit. Verify
these documents are nonempty and every planned existing path resolves; inspect
all NEW-file specifications and before/after contracts manually. Record the
actual command and reviewer outcome. wp2 consumes this locked roadmap and
revalidates source/version changes before implementation.

## Locked roadmap result

The source inventory and recipe specification are concrete and include exact CLI
and MCP values, positive and negative caller probes, section-level edit anchors,
disjoint worker write sets and older-runtime behavior. This cycle changes only
numbered planning documents; product files remain at baseline. The next cycle
implements 020/021 and checks the delivered snippets, not just this plan.
