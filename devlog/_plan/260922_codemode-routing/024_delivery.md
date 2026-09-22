# Authorized installation and remote delivery

The user authorized the previously deferred installed-skill update and push, plus
the remaining available Windows/authenticated-browser checks. This follow-up does
not install or upgrade Aside/codemode, alter accounts, or merge a pull request.

## Remote and installed artifact

- Published branch: `codex/aside-codemode-routing` in lidge-jun/aside-skill.
- Unpushed commits were normalized to the verified GitHub noreply identity before
  their first push. Source files were unchanged by that history rewrite.
- The staged skill was downloaded by skill-installer from exact remote revision
  f9699a9aca9fd47107cc6807719cf5707bf2f7cc; all 16 files matched the checkout.
- Existing Codex installation was backed up outside the repository and updated.
  SHA-256 comparison verified every source file and found no extra installed file.
  Skill frontmatter validation passed. The private backup location is retained in
  the task's local delivery evidence rather than in the public repository.
- No GitHub Actions workflows are configured in this repository; an empty run
  list is not CI test success. Local documented-recipe checks passed before push.

## Authenticated browser check

macOS, Aside CLI 1.26.906.1630, existing selected local profile. Native REPL read
an already-open GitHub issue tab. The snapshot exposed the signed-in user menu,
owner-only title editing and authenticated comment UI. No action was submitted.

The verified aside-codemode 0.9.0 source snapshot then called browse.attach on
that exact target ID. It returned ok:true, complete:true, truncated:false and
all three authenticated UI markers true; effects was empty. A following native
listBrowserTabs check confirmed the borrowed tab remained open. Only boolean
markers, not account data or page content, are retained as delivery evidence.

This proves one existing authenticated profile and borrowed-tab read path. It
is not a login/MFA test, a Vault test, a host-side MCP attachment test, or proof
that every site's authentication works. The installed codemode package remains
unchanged; the test used the source snapshot named in 001_research.md.

## Windows CLI proof

An existing Windows 11 Pro build 26200 (AMD64) host was reached through its
configured SSH connection. PowerShell 5.1.26100.8655 ran existing Node v24.16.0,
aside-codemode 0.9.0 and Aside CLI 1.26.906.1630. Python subprocess argument arrays
and UTF-16LE EncodedCommand carried the commands after quoting-only attempts were
rejected by the PowerShell parser. Those parse failures did not execute the jobs.

A unique temporary directory held exactly two fixture inputs plus config/job
files. Browser access was disabled and roots were limited to that directory.
The absolute Node/CLI pair with --config/--cwd/--code-file returned both expected
TODO hits and excerpts, complete:true, truncated:false, partial:[], and preserved
scope.coverage. A compound read of an outside-root path returned a per-row error
with outer ok:true/exit0, confirming why callers must inspect each row. Dynamic
import was rejected with EGUESTIMPORT and exit1. Main inspected the task-owned
fixture and independently repeated the positive invocation.

This is Windows shell/CLI/filesystem evidence, not Windows browser, Vault, MFA or
installer proof. Existing runtime and account configuration were left unchanged.
