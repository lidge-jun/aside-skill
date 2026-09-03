> ## Documentation Index
> Fetch the complete documentation index at: https://docs.aside.com/llms.txt
> Use this file to discover all available pages before exploring further.

# Components

> Changelog for the Aside browser (components)

# v1.26.829.1514

August 29, 2026

* \[Improvement] **Screen capture**: Adds a Settings > General toggle to turn capture off. Repeated shortcut captures no longer drop or fire twice, and the composer keeps focus after a capture.
* \[Fix] **Chat**: Lets you type in the sidebar rename dialog. Links in the side panel open in a browser tab. Hash-only popups stay in the background.
* \[Fix] **Lasso**: Stops Translate from inserting quotes and newline characters into the result.
* \[Fix] **Password manager**: Skips invalid 1Password items so one bad row does not abort the import. Imports month/year date fields and shows save errors at the top of the form.
* \[Fix] **Agent runtime**: Repairs a runtime install that macOS quarantined.
* \[Fix] **Routines**: Starts a routine when the project name contains non-ASCII characters.

# v1.26.827.1029

August 27, 2026

* \[Improvement] **Shared sessions**: Stabilized snapshot storage.
* \[Improvement] **New tab**: Uses the Settings > General Search or Ask default for each new tab. Switching mode on a tab is temporary.
* \[Fix] **Chat**: Stops link and attachment cards from jumping when you open a task. Failed model tool calls show **Model tool call failed**. Opening a composer menu no longer flashes the incognito tooltip.

# v1.26.826.1414

August 26, 2026

* \[Feature] **Shared session**: Copy a public link from session detail for a read-only snapshot of the chat, including tools, images, and errors. Revoke the link to take it down. Shared pages follow the system theme.
* \[Feature] **Side panel**: Adds a setting to keep the current side-panel chat when you change tabs. The live tab chip still follows the tab you are on.
* \[Improvement] **Password manager**: Fills identity fields (name, birth date, phone) from agent-saved items, including Korean identity-verification forms. Failed fills show why they failed.
* \[Improvement] **Channels**: Posts heartbeats and app-started runs in the bound Slack, Discord, or Telegram thread. `/model`, `/effort`, `/sessions`, `/usage`, and `/new` work on Slack and Discord if you type a leading space. `/usage` reset times are correct.
* \[Fix] **Daemon**: Recovers a stuck background service without a browser restart. Finished chats stay finished after compaction or a daemon restart.
* \[Fix] **Permissions**: Enforces browser and network permission rules, including downloads and cookie-bearing fetches.
* \[Fix] **Mini popup**: Applies custom keyboard shortcuts and resizes height to fit.
* \[Fix] **Chat**: Lets you change model or permissions while a task is running, and clears the error banner when Continue or Retry starts.
* \[Fix] **Routines**: Loads Settings > Routines when older paused rows have missing pause metadata.
* \[Fix] **Skills**: Discovers symlinked skill folders without looping.

# v1.26.824.1930

August 24, 2026

* \[Fix] **Password manager**: Clears the clipboard after you copy a secret. Drops decrypted vault data when the session expires and stops storing unmasked account hints in the locked cache.
* \[Improvement] **Password manager**: Offers Import when the vault is empty.
* \[Fix] **Mini popup**: Returns focus to the popup after menus close. Hides Mini popup in Settings when this Mac cannot open that window.

# v1.26.824.1718

August 24, 2026

* \[Improvement] **Mini popup**: Customize the shortcut from Settings > Mini popup. Mention suggestions resize as you type.
* \[Improvement] **Tab search**: Launches an installed extension from tab search.
* \[Improvement] **Context menus**: Keeps Capture first and simplifies Translate actions.
* \[Fix] **Chat**: Stops a false Show more after the window resizes. Keeps the coding-agent nudge in the transcript so it does not cover jump-to-bottom.
* \[Improvement] **What's new**: Refreshes the banner layout and can open the relevant setting.

# v1.26.824.1341

August 24, 2026

* \[Feature] **Mini popup**: Opens a native mini chat from anywhere. Set the shortcut in Settings > Keyboard shortcuts. Start a session with Cmd+N, switch sessions, attach files, and keep @-mentions, model, profile, and project pickers inside the popup. Drag, resize, or press Esc to dismiss.
* \[Feature] **Screen capture**: Right-click > Capture, or Cmd+Shift and drag, to grab the viewport, the full page, a hovered element, or a free-form area. Copy or download the PNG. The selection overlay is not in the crop.
* \[Improvement] **Chat**: Hides the pinned summary when the side panel is expanded. Clears leftover live status after a run. Follow-up prompts unpin the previous action bar. Bash and REPL tools show a loading animation.
* \[Improvement] **Credits**: Warns about Aside monthly usage in the omnibox only when less than 20% remains.
* \[Fix] **Models**: Falls back to another provider when Azure rate-limits mid-stream.
* \[Fix] **Plugins & MCPs**: Loads when skill or memory folders contain circular symlinks.
* \[Fix] **Agent runtime**: Completes Node install and reinstall on macOS.
* \[Fix] **Routines**: Syncs older routines that are missing a window id.

# v1.26.822.2145

August 22, 2026

* \[Feature] **Pinned summary**: Floats the summary panel in a narrow task layout.
* \[Feature] **Created files**: Opens a generated file in another app or shows it in Finder.
* \[Feature] **Models**: Adds Command Code as an API-key provider.
* \[Improvement] **AI providers**: Shows Reauthenticate on OAuth providers and refreshes subscription usage after you reconnect.
* \[Improvement] **Chat**: Converts citation tags to markdown links when you copy a message.
* \[Fix] **Agent runtime**: Notarizes and verifies macOS runtime installs before activation.
* \[Fix] **New tab**: Uses the selected omnibox suggestion instead of navigating to a typed URL.
* \[Fix] **Password manager**: Skips Touch ID after you pick an item in the passkey dialog.
* \[Fix] **Models**: Includes OpenRouter models that omit structured output.

# v1.26.821.1756

August 21, 2026

* \[Improvement] **Agent tabs**: Groups the agent's tabs and popups into Agent Tabs.
* \[Improvement] **Credits**: Shows Aside usage warnings in the composer. Notice links open in a new tab.
* \[Fix] **Image generation**: Restores ChatGPT image generation for Codex.
* \[Fix] **Long tasks**: Recovers when compaction fails in the agent runtime.
* \[Fix] **Passkeys**: Shows the passkey dialog only after iframe content is ready.

# v1.26.821.53

August 21, 2026

* \[Improvement] **Credits**: Lets you buy add-on credits or change plan from a credit-exhausted task.
* \[Improvement] **Context usage**: Shows session fill and ChatGPT, Kimi, and Grok plan limits beside the model picker.
* \[Improvement] **New tab**: Opens faster.
* \[Fix] **Chat**: Submits an edited message with Cmd+Enter.
* \[Fix] **Onboarding**: Keeps the browser import picker visible.
* \[Fix] **Outputs**: Restores Open with for files outside a Project.
* \[Fix] **Daemon**: Logs health probes and closes idle HTTP keep-alive after 5s.

# v1.26.820.1844

August 20, 2026

* \[Feature] **Image generation**: Generates and edits images in chat. Pick a model in Settings > AI, including ChatGPT when connected.
* \[Feature] **Agent runtime**: Installs Node.js, Python, and file search from Settings > Agents or `aside runtime install`.
* \[Feature] **Models**: Adds Grok 4.6 and OpenRouter Auto.
* \[Feature] **Projects**: Deletes archived Projects.
* \[Improvement] **Password reset**: Signs out other devices and starts a fresh cloud sync after you reset your account password.
* \[Improvement] **Models**: Limits visual-task model choices to vision-capable models.
* \[Fix] **Ask AI**: Lets you type while models load.
* \[Fix] **Notifications**: Sends one task-completion alert instead of duplicates.
* \[Fix] **Password manager**: Fills after SPA navigations, and imports Firefox CSV files without a name column.

# v1.26.818.1059

August 18, 2026

* \[Feature] **Channels**: Opens Slack and Telegram remote control to Pro, and shows an overview with an upgrade prompt on Free.
* \[Improvement] **Password manager**: Opens the popup faster.
* \[Fix] **Password manager**: Saves after email verification, keeps passkeys working across sign-in, and restores OAuth suggestions after a reload.
* \[Fix] **Long tasks**: Compacts when the remaining output window is too small to continue.

# v1.26.816.2129

August 16, 2026

* \[Feature] **Chat**: Renders TeX-style math from the model (`\(…\)`, `\[…\]`) without treating every `$` as math.
* \[Fix] **New tab**: Submits the text you typed after dismissing a suggestion, and opens `aside://` internal pages.
* \[Fix] **Password manager**: Saves generated passwords on signup when the email is locked or prefilled.
* \[Fix] **Lasso**: Applies replacements in rich text editors without wiping or duplicating surrounding text.

# v1.26.815.2155

August 15, 2026

* \[Feature] **Sounds**: Lets you replace the agent completion sound with your own file and preview it.
* \[Feature] **Models**: Adds DeepSeek V4 Flash and Pro, and switches Gemini Flash to 3.7.
* \[Improvement] **Lasso**: Lets you toggle lasso separately from text selection.
* \[Improvement] **Settings**: Moves Projects to its own page.
* \[Fix] **Feedback**: Asks for confirmation before closing a form that has text or attachments.
* \[Fix] **Password manager**: Fills credentials when you click an inline suggestion, and lets the agent save logins to Apple Passwords.
* \[Fix] **Agents**: Compacts long sidechat parent context, and keeps tool results when you stop a run.

# v1.26.814.1913

August 14, 2026

* \[Feature] **Settings**: Reorganizes settings by topic and keeps the sidebar visible as you scroll.
* \[Feature] **Plan & Usage**: Shows monthly credit usage for each task and model, with CSV download.
* \[Feature] **Subagents**: Groups subagent activity inside each task and lets you follow a subagent's live work in the side panel.
* \[Feature] **Command palette**: Searches bookmarks and installed extensions alongside open tabs, chats, and history.
* \[Feature] **Routines**: Lets the agent pause or resume a routine when you ask.
* \[Improvement] **Account recovery**: Adds a confirmation step before you download your recovery key.
* \[Fix] **Password manager**: Saves generated passwords after signup redirects and recognizes phone-number login fields.
* \[Fix] **Long tasks**: Keeps parallel tool results within the context window and reduces memory use when previewing them.

# v1.26.813.1554

August 13, 2026

* \[Feature] **Proton Pass import**: Imports vaults and passkeys from Proton Pass, including encrypted ZIP exports.
* \[Improvement] **Password manager performance**: Limits page scanning to password-manager form fields, so unrelated pages use less CPU.
* \[Improvement] **Grok models**: Refreshes subscription models without an app update.
* \[Fix] **Password manager**: Keeps vault fields visible during access checks and honors Save as new for passkeys.
* \[Fix] **Windows file access**: Keeps native file dialogs and File Explorer in front when tasks open or reveal files.
* \[Fix] **Agent recovery**: Keeps local tasks moving during Aside API outages and recovers from model provider overloads.
* \[Fix] **Cloud sync**: Recovers older sync exports and missing external file references.
* \[Fix] **Command palette**: Submits a search completion when you accept it with Tab.

# v1.26.812.1644

August 12, 2026

* \[Feature] **Side chat**: Lets you open a separate chat in the task side panel with the main conversation as context while the main task continues.
* \[Improvement] **Password manager**: Redesigns vault item details and releases credentials after vault unlock and page authorization.
* \[Improvement] **Composer**: Gives long prompts more room.
* \[Improvement] **Task details**: Shows file previews for memory and file-read actions and refines confirmation cards.
* \[Improvement] **Notifications**: Removes Markdown syntax from OS notifications.
* \[Fix] **Browser automation**: Prevents reversed or mixed text when the agent types in background tabs and rich text editors.
* \[Fix] **Memory search**: Restores results after the local memory cache reloads.
* \[Fix] **Password manager**: Retries keychain reads and saves so a transient failure does not lock the vault.

# v1.26.810.1916

August 10, 2026

* \[Feature] **New tab**: Shows unread badges on the Chats and Routines tabs so pending items are easy to spot.
* \[Fix] **Password manager**: Makes biometric unlock and vault recovery safer, with clearer next-step guidance when recovery is needed.
* \[Fix] **Model picker**: Keeps the menu stable in narrow side panels, and preserves maxTokens when editing custom providers.
* \[Fix] **Settings**: Repairs invalid custom model entries so other settings can still save.
* \[Fix] **Sessions**: Keeps sidebar date order after unarchive, and truncates long side panel titles cleanly.
* \[Improvement] **Performance**: Uses less CPU while chat is idle or running in the background.

# v1.26.806.238

August 6, 2026

* \[Feature] **Pinned summary**: Replaces the session side panel with a pinned summary for browser tabs, outputs, and file preview.
* \[Feature] **Created files**: Adds list and grid view modes for generated files, with a Finder-style context menu on artifacts.
* \[Feature] **Memory in chat**: Shows memory file chips with line diffs, and links extractions to the session run that produced them.
* \[Improvement] **Chat details**: Keeps trailing assistant actions visible, shimmers running subagent labels, and shows bouncing dots on scroll-to-bottom while streaming.
* \[Improvement] **Browser previews**: Adapts tab card chrome to the page top tone and uses Chrome's favicon cascade.
* \[Fix] **Small contexts**: Stops the agent from ending silently when the remaining context window is too small to continue.
* \[Fix] **Session files**: Renders custom session file protocols in chat.
* \[Fix] **Password manager**: Recovers autofill after a session storage quota failure.
* \[Fix] **Action confirmation**: Accepts multiline feedback on confirmation cards.
* \[Fix] **Onboarding**: Breaks the unlock loop when you choose manual unlock, and surfaces pricing and model picker load failures.
* \[Fix] **Routines**: Supports custom schedules with more than one time of day.
* \[Fix] **Channels**: Delivers mid-run messages instead of dropping or orphaning them.

# v1.26.804.1737

August 4, 2026

* \[Feature] **Channels**: Adds remote control over Slack and Telegram, with guided connection settings, durable delivery, and Telegram chat commands for session control.
* \[Feature] **Lasso chat**: Keeps a persistent chat for the current page selection.
* \[Feature] **Translation**: Adds local context-menu translation for selected page text.
* \[Feature] **/compact**: Adds a slash command for manual context compaction.
* \[Feature] **Documents**: Reads PDFs through a shared PDFium runtime and routes Office files through restored skill workflows.
* \[Feature] **Paywall**: Shows plan limits when a task needs a paid plan.
* \[Improvement] **Channels**: Keeps the agent's working process visible after a run and delivers suspension prompts in the same order as the app.
* \[Fix] **Compaction**: Compacts between agent tool turns so long tool loops stay within the context window.
* \[Fix] **Memory history**: Paginates large history logs without flickering the detail pane.
* \[Fix] **Action confirmation**: Scrolls overflow content instead of clipping the card.
* \[Fix] **MCP**: Caches each server's tool list across reconnects.
* \[Fix] **Models**: Shows GPT-5.3 Codex Spark, discovers Ollama model metadata, and identifies Aside in OpenRouter request headers.

# v1.26.730.1655

July 30, 2026

* \[Feature] **Sync repair**: Repair missing sync keys with your account password.
* \[Feature] **AI models**: Adds GLM 5.2 and Kimi K3 for Pro and Max.
* \[Fix] **New tab search**: Uses your default search engine for IME searches.
* \[Fix] **New tab input**: Restores typing after canceled IME input on macOS.
* \[Fix] **Generated files**: Opens images and downloads from local session links.
* \[Fix] **Chat deletion**: Stops the task and closes its tabs before deletion.
* \[Fix] **Long tasks**: Reduces daemon memory use when a task ends.
* \[Improvement] **New tab**: Clarifies expired trials and local profile avatars.
* \[Fix] **Cloud sync**: Keeps the previous file until the new version is saved.

# v1.26.727.2357

July 27, 2026

* \[Feature] **Tab switcher**: Adds a setting for tab switcher ordering.
* \[Feature] **Keyboard shortcuts**: Links Appearance settings to Chromium's advanced extension shortcuts page.
* \[Fix] **Billing**: Renews credits on subscription anniversaries and repairs missing paid credit grants.
* \[Fix] **Password manager**: Prompts sign-in when the profile master key is missing, recovers missing vault projections for autofill, and ignores non-auth OAuth copy as a sign-in suggestion.
* \[Fix] **Projects**: Keeps the Create button available when only archived projects remain.
* \[Fix] **Questions**: Always allows a custom answer on agent question prompts.
* \[Fix] **New tab**: Preserves IME composition and stabilizes internal omnibox suggestions.

# v1.26.726.101

July 26, 2026

* \[Feature] Added Claude Opus 5.
* \[Feature] Aside now pulls provider model from the catalog API, so new models will show in the picker without an app update.
* \[Improvement] Selection that a provider retires falls back to the first model you can reach instead of showing Select model.
* \[Improvement] The model list loads from cache while it refreshes in the background, cutting a stale-cache load from about 1.4s to 45ms.
* \[Improvement] Subagent badges show model names instead of raw model IDs.
* \[Fix] The background service sends requests over HTTP/1.1, ending the repeated `fetch failed` errors that a dropped HTTP/2 session caused on Node 26.
* \[Fix] A failed catalog refresh keeps the last working model list, and a model you selected stays selected even when new visibility rules would hide it.
* \[Fix] Long-running sessions refresh their OAuth tokens on every request, and a network error no longer forces you to reconnect a provider whose refresh token still works.

# v1.26.725.633

July 25, 2026

* \[Fix] **Chat history**: Messages render when you open a task and stay visible while you scroll back through a long conversation.

# v1.26.725.345

July 25, 2026

* \[Feature] **Passkeys**: The password manager inline menu offers an action for handing a sign-in back to the browser's own passkey flow.
* \[Improvement] **Chat scrolling**: Aside rebuilds the message list around turns, so long conversations hold your position during streaming, measurement, and fold changes. Short conversations start at the top of the pane.
* \[Improvement] **Settings**: Settings > AI > Models is now Task Models.
* \[Fix] **Long conversations**: Tasks and routines created under the previous GPT-5.6 Sol context window recover instead of failing every request, and a failed compaction keeps your last prompt.
* \[Fix] **Startup**: Aside repairs duplicate routine trigger records that blocked the Project migration and upgrades databases left on older schemas.
* \[Fix] **Password manager popup**: Search ranks title matches first, the locked inline menu keeps its actions button, and the inline menu survives focus changes inside iframes. Field icon tooltips match their toggle state.
* \[Fix] **Provider errors**: Aside retries Codex server errors that arrive without standard error details and drops the bug report prompt from provider failures.
* \[Fix] **Composer**: Prompts that contain dollar amounts submit as written.
* \[Fix] **Avatars**: Cached favicons no longer show the fallback letter through transparent icons.

# v1.26.724.22

July 24, 2026

* \[Improvement] **Projects**: Adds Project memory, linked task breadcrumbs, and clearer controls for instructions and working directories.
* \[Fix] **Project migration**: Preserves symlinks and prevents legacy file conflicts from blocking startup.

# v1.26.723.2306

July 23, 2026

* \[Feature] **Projects**: Adds dedicated spaces for work that needs its own files, instructions, and local workspace.
  * Create a Project with a name, icon, color, and workspace folder, then select it from the task composer.
  * Add source files and edit Project-specific `AGENTS.md` instructions from the Project page.
  * Start and review Project tasks in one place, switch between Projects, and archive finished Projects without removing their tasks or routines.
* \[Feature] **AI subscriptions**: Adds Kimi Code sign-in and Qwen Token Plan connections, refreshes provider branding, and updates the Gemini Flash models.
* \[Feature] **Device management**: Shows active cloud devices in account settings and lets you sign out a remote device.
* \[Improvement] **Local AI providers**: Lets you choose models while connecting Ollama or LM Studio.
* \[Improvement] **Chat history**: Collapses completed agent activity under a Worked for summary, keeps steering messages in the same run, and shows thinking only while the agent is responding.
* \[Improvement] **Created files**: Groups generated files into folders and shows them in an icon grid.
* \[Improvement] **Task browsing**: Simplifies task and routine lists, updates task preview cards, and keeps the current navigation context when you open a task.
* \[Fix] **MCP authentication**: Detects when a custom MCP server needs authorization, starts OAuth before a tool call fails, and provides an authorization retry action.
* \[Fix] **AI provider errors**: Shows credit errors from the provider that caused them and limits Aside credit prompts to Aside models.
* \[Fix] **Password manager capture**: Saves cards and billing identities from hosted payment frames, includes CVV and full billing addresses, and retries submit buttons that are temporarily disabled.
* \[Fix] **Password manager matching**: Stops treating login email fields and passkey buttons as one-time password or password-submit targets. Apple Passwords imports now use the selected browser profile.
* \[Fix] **Chat rendering**: Restores completed tool result cards, keeps chat detached after small scroll movements, and displays images referenced by absolute session paths.

# v1.26.721.1635

July 21, 2026

* \[Feature] **One-time password setup**: Aside detects TOTP QR codes on setup pages and offers to save them to matching logins, including when the vault is locked. You can start a scan from a login item's menu.
* \[Feature] **Post draft copying**: LinkedIn and X draft previews include a button for copying the post body.
* \[Improvement] **Routine pauses**: Aside shows why a routine paused and reconnects scheduled routines to your current browser profile when you resume them. Aside keeps Trigger now unavailable while the routine remains paused.
* \[Fix] **Custom AI providers**: Aside bundles Mistral support in production and restores Edit and Delete for providers added through + Connect.
* \[Fix] **Model fallback**: Aside keeps your selected default and session models when a temporary availability check falls back to an Aside model.
* \[Fix] **Task errors**: Aside shows a provider rate-limit message for upstream limits and a usage-limit message for Aside plan exhaustion. Aside brings disk-full failures out of collapsed tool output and provides recovery steps.
* \[Fix] **Image attachments**: Aside converts HEIC attachments to PNG before the agent reads them and reports broken JPEGs. It preserves previews for formats outside the resize pipeline, including AVIF and SVG.
* \[Fix] **Chat stability**: Chat holds your reading position while a task streams and when you reopen a session. Failed favicons fall back to initials without triggering an error screen.
* \[Fix] **Notification use**: The Notification Use page hides Aside's task-status notifications and limits long previews to four lines.
* \[Fix] **Omnibox navigation**: Aside opens `aside://` addresses entered in the search omnibox as internal Chrome pages.
* \[Fix] **Vault sync**: Aside recovers missing or conflicted vault records without changing stored values and repairs verified legacy sync metadata.
* \[Fix] **Passkeys**: Aside prevents assertion counter conflicts when new passkeys sync across devices.
* \[Fix] **Network authentication**: The packaged background service trusts system-managed certificate authorities, so authentication refresh works behind HTTPS-filtering software.

## v1.26.719.841

July 19, 2026

* \[Improvement] **Fast mode**: Aside places the Fast label beside thinking effort in chat and routine model selectors.
* \[Fix] **Pasted content**: Chat keeps pasted images attached and preserves citation text when you copy a message. Aside gives duplicate filenames separate storage names.
* \[Fix] **Chat scrolling**: Chat follows streaming output when you are at the bottom and holds your reading position after the task finishes.
* \[Fix] **AI provider sessions**: Aside disables models from OAuth providers whose credentials expired and shows a Reconnect action. A successful reconnect refreshes provider state across open extension tabs.
* \[Fix] **MCP previews**: Aside renders MCP tool previews on the new tab page without a route-context crash.
* \[Fix] **Account setup**: Aside waits for fresh account state before finishing onboarding and closes the password-gate popup so Chromium can open a normal new tab page.

## v1.26.717.1605

July 17, 2026

* \[Improvement] **Model selector**: Shows the selected model's provider icon in the task composer.
* \[Fix] **Draft actions**: Draft cards now place `Send`, `Send invite`, or `Post` in the task composer when you click their action button, including from the side panel.
* \[Fix] **Aside credits**: Chat shows the credit notice and Change plan button when you run out of credits for Aside models.
* \[Fix] **Task list links**: Saved task list links open with the All filter when they contain an unsupported filter.
* \[Fix] **CLI browser access**: CLI and REPL sessions connect to the last-focused window when one browser profile is open for your account. Aside restores this connection for older CLI sessions and asks you to close extra profiles when more than one matches.

## v1.26.716.1706

July 16, 2026

* \[Fix] Browser profiles: Tasks and routines stay attached to their original profile after browser restarts, window changes, and profile switches. Aside blocks browser actions when it cannot verify the profile.
* \[Fix] Chat delivery: Aside no longer sends prompts twice during profile checks or drops follow-up messages queued while the agent is replying.
* \[Fix] Task recovery: Aside clears failed runs stuck in the running state and repairs invalid preview data that can prevent the task list from loading.
* \[Improvement] Long conversations: Aside now uses Pi’s native compaction engine while retaining current task state and compatibility with existing histories.
* \[Improvement] AI models: OpenAI Codex users can select GPT-5.6 Luna again. GPT-5.6 Sol is now the default for Aside Pro and Max, with legacy GPT-5.5 compatibility.
* \[Fix] Routines: The scheduler prevents duplicate runs when checks overlap and retries temporary database locks.

## v1.26.715.1706

July 15, 2026

* \[Feature] **Task approvals**: Shows pending questions and permission requests in task previews, then lets users resolve action confirmations from the new tab page.
* \[Feature] **Windows file access**: Adds a native folder picker and lets users open files or show them in File Explorer.
* \[Feature] **Vertical tabs**: Adds an Appearance setting for hiding the bookmarks section and moves tab style controls into the same page.
* \[Improvement] **Update settings**: Shows the browser version and background service version on separate rows, then prompts for a restart when they do not match.
* \[Improvement] **Custom AI providers**: Supports Mistral and the remaining Pi runtime APIs while preserving tiered pricing metadata.
* \[Fix] **Agent context**: Keeps discarded user requests and constraints in compaction summaries.
* \[Fix] **Browser automation**: Makes manual key down and key up sequences enter printable text, recovers tab creation after a saved tab or window closes, and checks file permissions against the resolved tool path.
* \[Fix] **Custom skills**: Keeps invalid frontmatter from crashing Skills settings and handles unquoted colons in agent-created descriptions.
* \[Fix] **Agent runtime**: Keeps background failures from terminating the daemon and prevents repeated approval waits from leaving tool calls stuck.
* \[Fix] **Account recovery**: Requires email verification before password recovery and waits for local security setup before committing cloud sign-in.
* \[Fix] **Password manager integrations**: Prevents WebAuthn hook conflicts and duplicate FIDO2 registrations, and stops content scripts from breaking Bitwarden frames.
* \[Fix] **Password save prompts**: Updates the login selected in the prompt instead of the initial match.
* \[Fix] **Password manager popup**: Retries transient daemon authentication failures and shows a reconnect action when the local service remains unavailable.
* \[Fix] **macOS notifications**: Removes the duplicate extension icon from basic notifications while preserving click actions and rich alerts.
* \[Fix] **Task previews**: Centers draft artifact previews and restores confirmation card spacing.

## v1.26.713.1911

July 13, 2026

* \[Fix] **Agent sandboxes**: Applies each agent's sandbox settings when creating a session.
* \[Fix] **Memory cleanup**: Releases idle Memory clients and sessions on timeout and after rebuild, shutdown, or index changes, then drops failed push sessions before retrying.

## v1.26.713.1553

July 13, 2026

* \[Feature] **Archived chats**: Adds a page for browsing archived chats.
* \[Feature] **Appearance settings**: Replaces Personalize with an Appearance page that groups theme controls and keyboard shortcuts.
* \[Feature] **GPT-5.6 fast mode**: Enables fast mode for Sol, Terra, and Luna through the priority service tier.
* \[Feature] **Immediate follow-ups**: Sends Command + Enter follow-ups as interrupt steering while an agent is responding.
* \[Improvement] **Additional profile onboarding**: Skips the splash, import, and completion screens after account security setup for extra browser profiles.
* \[Fix] **Side panel sessions**: Keeps the side panel session in sync with the active tab.
* \[Fix] **MCP connections**: Shows stderr and timeout details when a local stdio server fails to connect.
* \[Fix] **AI providers**: Restores prompt caching and stops retrying provider authentication failures.
* \[Fix] **Chat UI**: Renders error alerts when UI context is unavailable, stabilizes read markers and confirmation shortcuts, and restores light-mode scroll button contrast.

## v1.26.711.1147

July 11, 2026

* \[Feature] **MCP servers**: Adds MCP settings, a server setup dialog, session tools, and authenticated HTTP connectors.
* \[Feature] **Profile routing**: Routes agent sessions and extension commands through the matching browser profile.
* \[Improvement] **Task cards**: Shows four cards per row and includes task errors in preview cards.
* \[Fix] **Passkeys**: Validates requests against the sender scope and prevents duplicate sign-in suggestions.
* \[Fix] **GPT-5.6 Sol**: Makes Sol available to eligible paid ChatGPT plans.
* \[Fix] **Sandbox tools**: Allows agents to use Xcode command-line tools inside the sandbox.

## v1.26.710.1610

July 10, 2026

* \[Feature] **Office attachments**: Accepts DOC, DOCX, PPT, PPTX, XLS, and XLSX files in chat uploads.
* \[Feature] **GPT-5.6 models**: Adds Responses API models and max thinking effort through the v2 model catalog.
* \[Fix] **Model selection**: Keeps Codex GPT-5.4 visible, handles retired Grok selections, restores Composer 2.5 Fast, and prefers connected subscriptions over Aside fallback models.
* \[Fix] **Routine schedules**: Supports monthly routines and waits for the recurrence field to lose focus before saving custom schedules.
* \[Fix] **Completion notifications**: Suppresses OS alerts while the user is viewing the session and sends alerts before memory extraction work starts.
* \[Fix] **Session state**: Preserves agent tabs during model reload and marks completed sessions as read while they remain visible.
* \[Fix] **Attached files**: Requires the agent to read attached files before answering and keeps REPL screenshots in the session temporary directory.
* \[Fix] **Provider connections**: Restores the ChatGPT disconnect flow.
* \[Fix] **Action confirmations**: Keeps confirmation prompts in English.
* \[Fix] **Password manager menu**: Prevents the autosave vault dropdown from clipping.

## v1.26.709.1533

July 9, 2026

* \[Feature] **Omnibox navigation**: Adds Control + N and Control + P shortcuts for moving through suggestions.
* \[Fix] **Browser automation**: Supports same-document navigation, Playwright page shortcuts, chained `locator.last`, and native Chrome download checks. Rejects `page.evaluate` calls whose arguments would be dropped.
* \[Fix] **Account registry**: Writes JSON through a temporary file and recovers empty or corrupt account registries at startup.
* \[Fix] **Profile accounts**: Prevents duplicate Chromium profile sign-ins and keeps duplicate account slots from blocking valid accounts.
* \[Fix] **Session transcripts**: Finds transcripts when timezone shifts move the expected date path.
* \[Fix] **Chat scroll**: Follows the bottom based on the user's scroll intent.
* \[Fix] **New tab attachments**: Starts file prompts through the daemon.
* \[Fix] **Model runtime**: Guards the reasoning option during compaction and refreshes the Grok subscription model cache.

## v1.26.708.1707

July 8, 2026

* \[Feature] **Custom skills**: Replaces the custom skill tool with a built-in skill creator and allows agents to write memory and skill files.
* \[Fix] **Local service sign-in**: Distinguishes an unavailable daemon from an unsupported macOS version during authentication.
* \[Fix] **Apple Passwords import**: Reads the required vault data without loading a full vault snapshot.

## v1.26.707.1525

July 7, 2026

* \[Feature] **Password suggestions**: Uses one decision path across suggestion surfaces and records the evidence behind autosave outcomes.
* \[Improvement] **Password manager state**: Moves vault, settings, suggestion, and workflow state into the background runtime and skips snapshot reloads when the vault revision has not changed.
* \[Fix] **Password manager workflows**: Refreshes passkey data after vault updates, excludes external unlock items, and suppresses autosave prompts after browser back or on Agent Manager pages.
* \[Feature] **Daemon health**: Reports the running daemon's release tag in health checks.
* \[Fix] **Daemon startup**: Replaces a stale daemon process during startup.
* \[Fix] **Network errors**: Shows TLS troubleshooting guidance when secure connections fail.
* \[Fix] **Password provider menu**: Uses the correct hover color in dark mode.

## v1.26.706.1521

July 6, 2026

* \[Feature] **Session commands**: Adds `/feedback`, `/new`, and `/clear` commands in chat.
* \[Fix] **Google sign-in**: Prevents the Google sign-in popup from hanging during profile lookup or OAuth start.
* \[Fix] **Auth refresh**: Handles revoked devices, scoped sign-out, and recoverable token refresh failures.
* \[Fix] **Profile accounts**: Shows disk-full and duplicate-start errors during profile account setup.
* \[Fix] **Account startup**: Waits through short account registry lock contention during startup.
* \[Fix] **Chat scroll**: Keeps message row measurement from shifting the current scroll position.
* \[Fix] **Google Docs selection**: Preserves table selection while Aside reads the current selection.
* \[Fix] **Password manager OTP**: Reports failed OTP autofill and sends input events that more OTP forms accept.
* \[Fix] **CLI and MCP**: Keeps the MCP server alive after idle periods, releases idle REPL sessions, and reports daemon outages in plain language.
* \[Fix] **Custom skills**: Allows a new skill with a distinct name even when an existing skill looks similar.

## v1.26.703.1528

July 3, 2026

* \[Fix] **Provider OAuth**: Handles expired provider OAuth credentials.
* \[Fix] **Compaction**: Improves recovery across providers and resumes sessions after length-stop compaction.
* \[Fix] **Password import**: Skips invalid 1Password import URLs.
* \[Fix] **Checkout and billing**: Shows promotion code fields and repairs stale paid entitlements.
* \[Fix] **New tab**: Preserves omnibox input during bootstrap.
* \[Fix] **Chat scroll**: Keeps scroll correction from overriding user wheel intent.

## v1.26.702.2347

July 2, 2026

* \[Fix] **Auth refresh**: Classifies refresh failures by API code and retries transient token refresh failures.
* \[Fix] **Session refresh**: Avoids refreshing stale persisted sessions.
* \[Fix] **Refresh tokens**: Aligns refresh token JWT and persisted TTL.
* \[Fix] **Account state**: Avoids defaulting sidebar state, file links, and pending account caches to account 0.
* \[Improvement] **Refresh telemetry**: Records richer refresh failure causes and retry attempt details.

## v1.26.702.1638

July 2, 2026

* \[Fix] **Profile accounts**: Keeps profile account resolution compatible with older daemons.
* \[Fix] **Lasso popup**: Resolves the popup account from the active browser profile.
* \[Improvement] **Profile telemetry**: Tracks browser profile context read failures.

## v1.26.702.1558

July 2, 2026

* \[Feature] **Chat actions**: Adds chat delete actions.
* \[Feature] **Local context**: Allows local folders to be attached as chat context.
* \[Fix] **New tab accounts**: Renders the new tab shell before account resolution and prevents account 0 flicker during bootstrap.
* \[Fix] **Mentions**: Prevents mention Enter from submitting and scopes tab mentions to the active account.
* \[Fix] **Skill auth**: Recovers Slack and Notion skill authentication.
* \[Fix] **Billing**: Returns from embedded checkout after onboarding.
* \[Fix] **Chat rendering**: Stops conversation scroll flicker loops.
* \[Fix] **Settings**: Stabilizes settings row separators.

## v1.26.701.2158

July 1, 2026

* \[Feature] **Tool calls**: Shows a shimmer animation while a tool call is running.
* \[Feature] **Skills**: Shows skills in slash rich input and adds a draft skill.
* \[Feature] **PDF support**: Adds native PDF support and improves the PDF skill.
* \[Feature] **Model runtime**: Migrates models to Pi explicit runtime providers.
* \[Fix] **Profile accounts**: Avoids repeated bootstrap work during profile account resolution and prevents wrong account fallback.
* \[Fix] **REPL output**: Hardens untrusted tool output guards.
* \[Fix] **Ask omnibox**: Restores Enter submit.
* \[Improvement] **Omnibox**: Supports selecting omnibox text with Shift + ArrowUp.

## v1.26.630.2302

June 30, 2026

* \[Fix] **REPL output guards**: Gates REPL output guards by model capability and hides guard markers from chat.
* \[Fix] **Password manager**: Avoids Bitwarden inline menu top-layer conflicts.

## v1.26.629.2342

June 29, 2026

* \[Fix] **Local AI providers**: Allows Ollama and LM Studio sessions to run without API keys.
* \[Fix] **Compaction**: Prevents repeated compaction loops that could drain credits without advancing the retained message boundary.
* \[Fix] **Grok Build**: Hides reasoning controls for Grok subscription models that do not support reasoning effort.
* \[Fix] **Chat connections**: Suppresses expected websocket cancellation errors when switching Ask AI sessions quickly.
* \[Fix] **Account binding**: Repairs profile/account binding drift and prevents duplicate account slots after profile ID rotation.
* \[Fix] **Passkeys**: Supports prototype-level passkey fallback hooks and prevents fallback recursion with external password managers.
* \[Fix] **New tab**: Keeps selected URL autocomplete values after submit and hides empty previews while data is still loading.

## v1.26.629.231

June 29, 2026

* \[Fix] **macOS installation keys**: Supports software P-256 installation keys on Macs without Secure Enclave while keeping the public key scheme unchanged.

## v1.26.627.1553

June 27, 2026

* \[Improvement] **Grok Build**: Enables thinking effort controls for Grok Build.
* \[Improvement] **Plan descriptions**: Clarifies Pro and Max usage descriptions.
* \[Fix] **Chat editing**: Updates edited messages in place so stale transcript rows disappear before the follow-up run starts.
* \[Fix] **AI credit usage**: Handles usage overage limits more accurately.
* \[Fix] **Browser import**: Shows Firefox import even when native profile details are not available.
* \[Fix] **Routines**: Keeps routine permissions aligned with the session that created them.
* \[Fix] **Model fallback**: Resets thinking level when Aside falls back to another available model.
* \[Fix] **Thinking messages**: Shows scroll fades only when thinking content overflows.
* \[Fix] **Activity screen**: Prevents crowded month labels in the activity heatmap.

## v1.26.627.119

June 26, 2026

* \[Feature] **Grok subscription**: Adds Grok subscription sign-in and model support.
* \[Feature] **Custom AI providers**: Adds settings UI for custom providers, Ollama, and LM Studio.
* \[Improvement] **Model provider icons**: Shows clearer icons for Grok, local providers, OpenCode, MiniMax, and Xiaomi.
* \[Fix] **Provider sign-in**: Improves ChatGPT, Claude, and GitHub Copilot subscription connection reliability.
* \[Fix] **Account sign-in**: Clears stale local profile bindings when they block a new sign-in.

## v1.26.626.218

June 25, 2026

* \[Fix] **Billing**: Allows billing requests from the extension.
* \[Fix] **Account switching**: Keeps the saved vault available after switching accounts.
* \[Fix] **Stability**: Keeps the extension connected to the local service under production security settings.

June 25, 2026

* \[Feature] **Model catalog**: Adds AI Gateway model catalog selection.
* \[Feature] **Subscriptions**: Shows subscription status on the new tab page.
* \[Fix] **Checkout**: Handles embedded checkout fallbacks more reliably.
* \[Fix] **Chat rendering**: Renders single-dollar LaTeX correctly.
* \[Fix] **New tab search**: Speeds up search handoff from the new tab page.
* \[Fix] **Thinking messages**: Keeps long thinking content scrollable without distracting message animations.
* \[Fix] **Feedback**: Sends feedback submissions more reliably.
* \[Fix] **GitHub Copilot models**: Caches model availability checks more reliably.

## v1.26.625.410

June 25, 2026

* \[Fix] **OAuth connections**: Handles local callback port conflicts more reliably during AI provider sign-in.
* \[Fix] **Tab search**: Scopes chat results to the current profile account.

## v1.26.624.1450

June 24, 2026

* \[Feature] **AI providers**: Adds DeepSeek and Kimi provider support.
* \[Fix] **Provider setup and feedback**: Improves AI provider setup submission and prevents accidental feedback dialog dismissal while sending.
* \[Fix] **Draft artifacts**: Sends draft artifact messages through the chat input more reliably.

## v1.26.624.1043

June 24, 2026

* \[Feature] **Interrupted tasks**: Adds a resume action for paused queued messages.
* \[Fix] **Agent interrupt**: Stops runs immediately on interrupt and pauses queued messages.
* \[Fix] **Chat links and composer**: Opens extension chat links in browser tabs and keeps multiline input scrolled correctly.
* \[Fix] **Passkey registration**: Clears the autosave prompt before passkey registration.

## v1.26.624.131

June 24, 2026

* \[Fix] **Session restore**: Reopens empty session run projections more reliably.

## v1.26.623.1918

June 23, 2026

* \[Feature] **Custom skills**: Opens custom skill management to more users.
* \[Fix] **Password manager install**: Stops the password manager popup from opening during extension install.

## v1.26.623.1804

June 23, 2026

* \[Feature] **Suggested tasks**: Shows suggested tasks from onboarding browser history on the welcome surface.
* \[Improvement] **Onboarding polish**: Fixes onboarding loops, browser import picker clipping, autosave scope, and routine recents.

## v1.26.622.1544

June 22, 2026

* \[Feature] **Help Center**: Adds the first Aside Help Center pages.
* \[Feature] **Routine cards**: Shows routines on the new tab page.
* \[Improvement] **Model errors**: Makes unavailable model errors clearer.

## v1.26.620.1506

June 20, 2026

* \[Feature] **Plan limits**: Shows clearer limits for Ultrabrowse and routine creation on the free plan.
* \[Feature] **Touch ID setup**: Prompts Touch ID setup after password manager unlock.
* \[Fix] **Inline citations**: Renders inline citations more reliably.

## v1.26.619.1734

June 19, 2026

* \[Feature] **Pricing and subscriptions**: Adds pricing pages, plan change UI, usage limits, and limit previews.
* \[Feature] **Apple Passwords**: Adds Apple Passwords support through the browser integration.
* \[Improvement] **Password manager onboarding**: Clarifies setup copy and onboarding dialogs.

## v1.26.619.422

June 18, 2026

* \[Fix] **Passkey origins**: Shows passkey items with the parent origin.
* \[Fix] **Subagent previews**: Shows a fallback preview icon when a subagent is outside an active session.

## v1.26.618.1507

June 18, 2026

* \[Feature] **External password managers**: Adds support for more external password managers beyond 1Password.
* \[Feature] **Install page**: Adds a download and install page.
* \[Fix] **Billing and session display**: Fixes renewal credit display and temporary markdown image rendering.

## v1.26.617.1936

June 17, 2026

* \[Feature] **Subagent status**: Shows subagent state in the side panel.
* \[Feature] **Unread previews**: Adds unread session previews and responsive task cards.
* \[Improvement] **Password manager autosave**: Reduces autosave CPU usage.

## v1.26.616.1654

June 16, 2026

* \[Improvement] **Startup reliability**: Improves background service startup checks.

## v1.26.616.1613

June 16, 2026

* \[Feature] **Session previews**: Adds recent session preview cards, artifact previews, live browser previews, and Chrome session popovers.
* \[Improvement] **Task feed**: Refreshes task cards and running session previews.

## v1.26.615.1604

June 15, 2026

* \[Fix] **Passkeys**: Improves passkey bridge reliability.
* \[Improvement] **Browser colors**: Applies browser color scheme changes more consistently.
* \[Fix] **Queued continuations**: Recovers queued continuations after assistant turns.

## v1.26.613.1515

June 13, 2026

* \[Improvement] **Password manager popup**: Reduces duplicate loading and flicker in the popup.
* \[Fix] **Popup frame**: Prevents blank popup frames before the app renders.

## v1.26.612.1504

June 12, 2026

* \[Feature] **Event-triggered routines**: Adds event triggers, inbox-driven wakes, and routine filter UI.
* \[Fix] **Chat composer**: Stabilizes chat input submission.
* \[Fix] **Okta autofill**: Restores autofill on Okta passcode password forms.

## v1.26.611.1524

June 11, 2026

* \[Feature] **Model picker**: Adds searchable model selection and thinking effort controls.
* \[Feature] **Task notifications**: Sends task completion notifications when focus is away and opens sessions from notification clicks.
* \[Feature] **Settings feedback**: Sends settings feedback through Intercom.

## v1.26.610.1628

June 10, 2026

* \[Feature] **Payment autofill**: Autofills payment cards across hosted payment iframes.
* \[Feature] **CLI update notices**: Shows update notices for interactive CLI commands.
* \[Fix] **Provider rate limits**: Handles provider rate limits without automatic retry loops.

## v1.26.609.1610

June 9, 2026

* \[Feature] **Onboarding refresh**: Updates onboarding and developer connection nudges.
* \[Improvement] **Browser settings**: Moves browser settings to the native settings surface.
* \[Fix] **Side panel and autosave**: Fixes incognito side panel theming, chat pinning, and clipped autosave notifications.

## v1.26.608.2018

June 8, 2026

* \[Improvement] **CLI installer**: Polishes install, update, and version output.
* \[Feature] **OpenRouter models**: Adds configurable OpenRouter models.
* \[Improvement] **Chat and password manager speed**: Improves long chat rendering and password popup startup.

## v1.26.606.1622

June 6, 2026

* \[Feature] **Custom skills**: Adds user-owned custom skill management and skill creation from chat.
* \[Feature] **Tab search**: Adds tab search.
* \[Fix] **Password safety**: Blocks cross-site agent autofill.

## v1.26.605.1612

June 5, 2026

* \[Feature] **Workspace access**: Adds custom working directory access.
* \[Improvement] **Session list speed**: Speeds up recent session lists.
* \[Improvement] **Question prompts**: Adds cancel actions and default custom answers.

## v1.26.604.1932

June 4, 2026

* \[Fix] **New tab routines**: Hides routine suggestions on the new tab page when they should not appear.

## v1.26.604.1707

June 3, 2026

* \[Feature] **Browser import settings**: Adds browser import controls to General settings.
* \[Feature] **Routine suggestions**: Suggests routines from browser history.
* \[Fix] **Omnibox history**: Deletes omnibox history suggestions.

## v1.26.603.1838

June 3, 2026

* \[Feature] **Notification sync**: Syncs notification grants from native browser permission events.
* \[Feature] **Zoom display**: Shows zoom levels more clearly.
* \[Improvement] **Light mode**: Improves light-mode UI details.

## v1.26.602.1729

June 2, 2026

* \[Feature] **Action confirmation**: Adds clearer action confirmation controls.
* \[Feature] **External password managers**: Adds connection state, disconnect flow, and multi-manager support.
* \[Fix] **Notifications**: Avoids duplicate notification entries.

## v1.26.601.1856

June 1, 2026

* \[Feature] **Review before action**: Adds review-before-action mode.
* \[Feature] **External manager settings**: Adds external password manager connection settings.
* \[Improvement] **App speed**: Improves agent-manager loading speed.

## v1.26.531.1623

May 30, 2026

* \[Feature] **Password matching controls**: Adds per-URL matching strategy controls.
* \[Feature] **File drop**: Adds file drop support in the AI pane.
* \[Fix] **Routine pause**: Pauses finite routines after their final run.

## v1.26.529.1833

May 29, 2026

* \[Feature] **Password manager choices**: Adds detected password manager suggestions and quick setup choices.
* \[Feature] **External unlock capture**: Saves external password manager unlock passwords where supported.
* \[Fix] **Passkey bridge**: Improves passkey bridge messaging.

## v1.26.528.1924

May 27, 2026

* \[Feature] **Initial component release**: Adds the first bundled agent UI, password manager, landing pages, routines, settings, browser automation, and shared UI.
