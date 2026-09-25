# wp4 — push and deploy

Previous D (wp3): skill edits landed in aside-skill 271fe1a; links, anchors
and required phrases verified. This cycle publishes them and brings every
installed copy to the same tree. The user asked for the push and for updating
"this global and wherever it is installed over ssh" on 2026-09-25.

## Preflight (P, 2026-09-26)

- aside-skill `main...origin/main [ahead 3]`, parent `aside` `[ahead 3]`
  (pointer-only bump commits), both fetched; no divergence.
- Mac copies `~/.claude/skills/aside-jun`, `~/.codex/skills/aside-jun` are real
  directories with no files absent from the repo (`diff -rq`, no "Only in
  <dest>"), so `--delete` removes nothing user-owned.
- mini checkout `C:\Users\super\Developers\aside\aside-skill`:
  `main...origin/main [behind 31]`; its `M` entries are CRLF-only
  (`git diff --ignore-cr-at-eol` empty). mini copy
  `C:\Users\super\.codex\skills\aside-jun` has no Claude sibling.

## Steps

1. `git -C aside-skill push origin main`; then parent `git push origin main`
   (only `lidge-jun/aside-skill` and `lidge-jun/aside`; never the `new` root).
2. Mac: `rsync -a --delete --exclude .codexclaw/ aside-skill/aside-jun/ <dest>/`
   for both copies; `diff -rq -x .codexclaw` must be empty.
3. mini checkout: in `aside-skill`, discard CRLF-only noise with
   `git checkout -- <files>` only after re-confirming the
   `--ignore-cr-at-eol` diff is empty, then `git merge --ff-only origin/main`.
   Parent mini checkout: `git pull --ff-only` (its `aside-codemode` pointer and
   untracked `aside-codemode-nfc/` are left untouched).
4. mini copy: rsync from the mini checkout's `aside-jun/` with the same flags;
   verify file list + sha256 against the Mac repo.

## Check

- `git status -sb` shows `main...origin/main` with no ahead/behind for both
  repos locally and for mini aside-skill.
- `diff -rq` empty for both Mac copies; sha256 manifest equal between the Mac
  repo and mini copy.

## Audit fold (reviewer NEAR-PASS)

- Folded: mini step 3 runs `git fetch origin` before `merge --ff-only`.
- Folded: mini working tree is CRLF while the installed copy is LF blobs, so
  the mini copy is synced **from the Mac repo over ssh** (`rsync -rt --delete
  --exclude .codexclaw/ aside-jun/ mini:<dest>/`), not from the mini checkout;
  check = sha256 manifest equal to the Mac repo.
- Folded: `/mnt/c` is drvfs, so use `-rt` (no perms/owner/group).
- Noted: parent `aside` commits keep that repo's existing unprefixed
  `chore: bump …` style; the `[agent]` prefix is used in aside-skill.
