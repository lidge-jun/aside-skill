# 030 - validation and shipping spec

Consumed by wp3-verify and wp4-ship.

## Validation

The validator imports PyYAML, which the default `python3` on this machine lacks.
Resolve a working interpreter before relying on the check:

```bash
VALIDATOR_PY=/usr/local/bin/python3          # has PyYAML here
"$VALIDATOR_PY" -c 'import yaml' 2>/dev/null || {
  python3 -m venv /tmp/_yamlenv && /tmp/_yamlenv/bin/pip install -q pyyaml
  VALIDATOR_PY=/tmp/_yamlenv/bin/python
}
"$VALIDATOR_PY" ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-dir>
```

Must exit clean with no placeholder findings. A `ModuleNotFoundError: yaml` is an
environment failure, not a passing validation.

Also assert: refskill-aside.md has no leading frontmatter; every hang class in
SKILL.md traces to devlog/000-research.md; no exec template contains `-m`.

## Forward test

Dispatch one independent subagent with only the skill and a realistic request.
It must complete a real Aside task without hanging. Capture the transcript as
criterion evidence for c8.

The test should exercise the dangerous path deliberately: ask for something whose
natural output location is outside the guard roots, and confirm the skill steers
the agent to write inside `~/.aside/u/0/` instead of hanging.

## Shipping

1. `git init` (already done), commit the tree.
2. `gh repo create` under lidge-jun, public.
3. Push, then `gh repo view` to confirm visibility and HEAD.
4. Install to `~/.codex/skills/aside/`, leaving `aside-cli/` intact.
5. `ls` the install path to confirm SKILL.md is readable.

## Audit amendments (round 1)

**Validation additions.** Beyond `quick_validate.py`: assert no exec example
contains `-m`, assert every `aside exec` example is wrapped in `timeout`, assert
the no-questions clause is present, and confirm refskill-aside.md has no leading
frontmatter.

**Forward test bound.** The forward test runs under a host timeout. A hang is a
test failure, not a slow pass.

**Packaging is explicit.** The installed skill contains SKILL.md, agents/,
references/, and scripts/ only. `.git/` and `devlog/` stay out of the install,
since devlog is planning material rather than skill content. After installing, run
`quick_validate.py` against the installed path and diff it against the shipped tree
so the install is provably the published revision.
