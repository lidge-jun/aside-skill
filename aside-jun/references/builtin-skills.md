# Aside builtin skills

Union of the macOS builtin tree (CLI 1.26.902.1732, 2026-09-03) and the Windows
builtin tree (CLI 1.26.906.1630, 2026-09-11). Do not hardcode a `/Users/...` path.
Regenerate a single-tree dump with `scripts/refresh-builtin-summary.sh [account-root]`;
the script defaults the account root per OS and emits a `Platform` column.

Aside owns these and ships updates with the app; re-run the script after an Aside update.

**Staleness (2026-09-25).** These tables come from the 902 (macOS) and 906
(Windows) trees. CLI 1.26.916.1741 is on offer and was not installed. On macOS
CLI 1.26.906 `aside skills list` printed 11 names: `aside`, `google-accounts`,
`google-docs`, `google-gmail`, `google-search`, `google-sheets`, `linkedin`,
`Messages`, `notion`, `slack`, `youtube`. Trust the live `aside skills list` /
`show` output over this file.

`aside exec` loads them on its own when the prompt names one. Codex can read any skill
body with `aside skills show <name>`; `aside skills list` prints the subset marked
`CLI listed` below.

Check this list before driving a site by hand with `snapshot()`: a matching skill usually
reaches an API and skips the DOM entirely. When you use one, tell the user which skill
and why.

34 top-level skills on macOS, 31 on Windows. 16 site-specific skills on both.

The `Backing` column says how the skill works. A `repl global` skill documents a JavaScript
object you can also drive yourself from `aside repl`; several of those reach an API and never
open a tab. An `instructions` skill is guidance for the agent with no matching global.

`Platform` is `macOS` for names measured absent from the Windows tree on 2026-09-11:
`apple-passwords`, `imessage`, and `context-awareness`. Everything else, including nested
`site-specific/` skills, is `both`. Windows adds none of its own.

## Top-level

| Skill | Backing | CLI listed | Platform | Purpose |
|---|---|---|---|---|
| `1password` | instructions | - | both | Read this skill when the user uses 1Password. |
| `apple-passwords` | repl global | - | macOS | Use Apple Passwords on macOS when the user asks to save, retrieve, or autofill Apple/iCloud passwords or OTPs. |
| `aside` | repl global | yes | both | Use this when you need to inspect or update Aside daemon settings, Projects, sessions, routines, task transcripts, child sessions, |
| `bitwarden` | instructions | - | both | Read this skill when the user uses Bitwarden. |
| `captcha-solver` | repl global | - | both | Read this skill when a page has a CAPTCHA that needs solving (reCAPTCHA, Turnstile, hCaptcha, or image CAPTCHA). |
| `channel` | instructions | - | both | Read and act through the configured Slack, Discord, or Telegram bot connection that started the current task. Use for channel hist |
| `chrome` | repl global | - | both | Read this when you need to use Chrome extension APIs: managing bookmarks, tabs, windows, tab groups, history, downloads, or top si |
| `context-awareness` | instructions | - | macOS | Use this when you need the user's observed computer activity (Context Awareness) — searching raw captured evidence, reading stored |
| `dashlane` | instructions | - | both | Read this skill when the user uses Dashlane. |
| `docx` | instructions | - | both | Use this skill whenever a Word .docx file must be read, created, inspected, or edited, including its tables, images, headers, foot |
| `draft-preview` | instructions | - | both | Use when the user explicitly asks for drafting content. |
| `google-accounts` | repl global | yes | both | IMPORTANT- Read this skill before interacting any Google apps! |
| `google-docs` | repl global | yes | both | Read this skill when you need to read or write Google Docs. Reading works without opening a browser tab. |
| `google-gmail` | repl global | yes | both | Read this skill when you need to use user's Gmail. Don't have to open a browser tab. |
| `google-search` | repl global | yes | both | Use this when you need to search web on Google and websearch tool is not enough |
| `google-sheets` | repl global | yes | both | Read this skill when you need to read or write Google Sheets. Works without opening a browser tab for reads. |
| `image-search` | repl global | - | both | Use when you need to search images |
| `imagegen` | repl global | - | both | Generate a new image or edit an existing image from a text prompt. Use for illustrations, photos, textures, mockups, visual varian |
| `imessage` | instructions | yes | macOS | Read iMessages conversations, text someone, or get SMS codes. |
| `kakaotalk` | instructions | - | both | Read your KakaoTalk chats and messages (read-only). |
| `lastpass` | instructions | - | both | Read this skill when the user uses LastPass. |
| `notification-activation` | instructions | - | both | Enable browser notifications on websites for monitoring and event-driven routine flows. |
| `notion` | repl global | yes | both | Read this skill when you need to use Notion. Don't have to open a browser tab. |
| `onboarding` | instructions | - | both | Run the first-session onboarding - get to know the user from the tools they already use, show a couple of things you can do for th |
| `password-manager` | instructions | - | both | Use Aside Password Manager when it helps with login, signup, password generation, credential storage, payment card / identity auto |
| `pdf` | instructions | - | both | Use this skill to read, render, merge, split, rotate, or fill PDFs. |
| `pptx` | instructions | - | both | Use this skill whenever a PowerPoint .pptx file must be read, created, inspected, or edited, including slides, notes, images, tabl |
| `proton-pass` | instructions | - | both | Read this skill when the user uses Proton Pass. |
| `skill-creator` | instructions | - | both | Create or update Aside skills. Use when the user wants to turn reusable instructions, site instructions, workflows, domain knowled |
| `slack` | repl global | yes | both | Read this when you need to use Slack. |
| `visual-browse` | instructions | - | both | Read this when you need a coordinate fallback for visible browser UI that snapshots, refs, or locators cannot target reliably. |
| `x-twitter` | repl global | - | both | Read this skill when you need to use X (Twitter). Don't have to open a browser tab. |
| `xlsx` | instructions | - | both | Use this skill whenever an .xlsx or .xlsm workbook must be read, created, inspected, or edited, including formulas, formatting, ch |
| `youtube` | repl global | yes | both | Use this skill when you need to search YouTube, read video transcripts, or inspect comments without opening YouTube manually. |

## Site-specific

Nested under `site-specific/`. The container directory has no SKILL.md and is not itself
loadable; name the individual site skill instead. The nested set is present on macOS and
Windows (measured 2026-09-11).

| Skill | Backing | CLI listed | Platform | Purpose |
|---|---|---|---|---|
| `airtable` | instructions | - | both | Airtable base, view, and record-pane guidance. |
| `amazon` | instructions | - | both | Amazon shopping, orders, and account-state guidance. |
| `asana` | instructions | - | both | Asana inbox, my-tasks, and task-pane guidance. |
| `clickup` | instructions | - | both | ClickUp command-bar, task, and inbox guidance. |
| `confluence` | instructions | - | both | Confluence Cloud page and editor guidance. |
| `discord` | instructions | - | both | Discord web app channel and message workflow guidance. |
| `github` | instructions | - | both | GitHub repo, issue, PR, and review guidance. |
| `google-calendar` | instructions | - | both | Google Calendar event browsing, search, and creation guidance. |
| `google-drive` | instructions | - | both | Google Drive navigation and result-reading guidance. |
| `google-forms` | instructions | - | both | Google Forms navigation and editing guidance. |
| `google-slides` | instructions | - | both | Google Slides reading and editing guidance. |
| `jira` | instructions | - | both | Jira Cloud issue, search, and list-view guidance. |
| `linear` | instructions | - | both | Linear issue, inbox, and keyboard-driven workflow guidance. |
| `linkedin` | repl global | yes | both | Read this when you need to use LinkedIn. |
| `notion` | repl global | yes | both | Notion workspace, page navigation, and block-editing guidance. |
| `trello` | instructions | - | both | Trello board, inbox, and card workflow guidance. |
