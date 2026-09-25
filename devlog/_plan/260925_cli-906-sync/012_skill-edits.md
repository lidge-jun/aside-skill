# wp3 — skill edits

Previous D (wp2): parallel one-shot REPL is safe (4/8 concurrent, 0 leaks,
isolated sessions); inside one session `page` is race-set after concurrent
`openTab`. This cycle folds F1–F8 plus that result into the skill. Direction
unchanged from the roadmap.

## Diff-level edits

**SKILL.md**
- Route table: new first row "Native Aside MCP attached to this caller
  (live schema shows Aside `exec`/`repl`, often `memory_search`) → call it
  instead of shelling out; same REPL/exec rules apply". Login row reworded:
  "Login, MFA … → `exec` signs in itself; hand it the login first".
- New section "Sign-in is exec's job" (F8): delegate first, do not ask the
  user to sign in/unlock beforehand; exec uses Aside Vault / connected
  password manager (SSO is exec's judgment, unmeasured); ask the human only
  after exec reports a concrete blocker; stays inside task authorization (no
  account switching, no policy change, no new-account creation without the
  user). Links credentials.md.
- Confirm-account section: add `aside memory search "<q>" --json` before
  asking the user for personal context; never edit memory files (F2).
- Replace "Released codemode 0.9.0's browser runner…" paragraph with the
  0.9.2 state and a version-identification pointer (F5).
- Evidence bullets: argv trap (F4); exit 0 on exec provider/auth errors,
  detect ` • Error` (F3); parallel REPL rule from wp2.
- Constraint line: `aside skills install` only on explicit user request
  (shadows aside-jun) (F6).

**references/exec.md**: new "Sign-in is delegated" section (order a/b),
provider-error detection, `session list/archive/delete`, `-s fast`,
`--effort ultrabrowse` mention.

**references/credentials.md**: new opening summary matching F8; rewrite
"Before an unattended login task, the user chooses…" sentence so the policy
is the user's standing choice and exec attempts first.

**references/codemode.md**: "Identify the installed version" subsection
(no `--version`; resolve realpath → `package.json`; `browserContext` in the
envelope ⇒ ≥0.9.1 routing; multiple installs by PATH order).

**references/repl-api.md**: "Parallel pages" section with wp2 numbers.

**references/builtin-skills.md**: staleness note (902/906 trees; 916
offered; rerun script after update); current CLI-listed set on macOS
1.26.906 (11 names).

**references/compatibility.md**: 2026-09-25 rows — CLI 906 still installed,
916 offered; aside-codemode npm latest 0.9.2; local installs 0.9.2 + stale
Homebrew 0.9.1.

## Check

- `grep` each F-marker phrase lands in the target file.
- Relative links in SKILL.md resolve (script).
- SKILL.md ≤ 500 lines, frontmatter intact.

## Audit fold (reviewer NEAR-PASS)

- Folded blockers: also rewrite credentials.md:23-24 (exec first, manual
  sign-in second), :165-166 (passwordManager via exec is default; Apple
  Passwords PIN ceremony only after a reported blocker), :289-293 ("The
  pattern that works" → exec first).
- Login row keeps "within the task's existing authorization; stop when a
  human gesture is required".
- F3 wording: "exec exited 0 on a provider 403 (quota)"; auth errors marked
  unmeasured. The ` • Error` line is the observed CLI output of that run
  (this session, 2026-09-25, also in the feedback transcript).
- F6: exec.md gets one line for `host list/use/status` and
  `settings set-default-profile` (read-only inspection; `use`/`set-*` change
  defaults — only on user request).
- Parallel text says "4 and 8 concurrent observed, not a published limit"
  and repeats the no-dependent-steps/forms/logins rule.
- New SKILL.md section ≤ ~6 lines; detail in exec.md/credentials.md.
- Check greps also for leftovers: "sign in in the Aside window",
  "before delegating", "user signs in once".
