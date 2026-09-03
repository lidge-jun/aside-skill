# Aside Discord release / changelog notes

Collected: 2026-09-02 (KST), CLI/browser era `1.26.810` through `1.26.902`.

## Source

- **Server:** Aside (community server; invite-link joinable, Level 1 boost)
- **Guild ID:** `1518417473043693608`
- **Invite used:** `https://discord.com/invite/2h4cNW6ayc` (from [aside.com](https://aside.com/) footer → Community → `/community`)
- **Channel read:** `#announcements` (announcement / 공지 channel)
- **Channel ID:** `1518420346057785444`
- **Channel URL:** https://discord.com/channels/1518417473043693608/1518420346057785444

## Other channels checked

Quick Switcher search on this account found **no** Aside channels named `changelog`, `releases`, `updates`, or `release-notes`.

Visible Aside channels in the sidebar / browse list (read-only; only `#announcements` was mined for release posts):

- `#announcements` (공지)
- `#rules`
- Community: `#welcome`, `#general`, `#help` (forum), `#use-cases`, `#ideas` (forum)
- Archived: `#feature-request`

Release / changelog posts live in `#announcements`. Native browser version posts (`v1.0.811.1`, `v1.0.813.1`, `v1.0.825.1`) are also in this same channel.

## Method / notes

- Signed in to Discord with the owner's existing account (handle and email redacted before commit).
- Joined Aside via the official Community invite. Did not post, react, or change settings.
- Posts below are from `#announcements` only, from 2026-08-10 through 2026-09-02.
- Times are **Asia/Seoul (KST)** from Discord message snowflakes / `datetime` attributes. UTC is also listed.
- Hidden Discord list commas from the accessibility tree were stripped. Nested bullets match the original HTML lists.
- Consecutive same-author messages (no username header) are attributed to the previous author.
- Authors: **hiddenest** (ASID staff) and **Dora Lee** (ASID staff).

---

## Posts (oldest → newest)

### 2026-08-10 19:37:28 KST — hiddenest

- **UTC:** 2026-08-10 10:37:28
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1536322586361856041
- **Version:** Background service `v1.26.810.1916`
- **Edited:** no

@everyone **Updates / August 10**

Good morning, everyone.
This week, we will mainly focus more on improving the performance, especially for the speed and memory usage.
The changes will be rolled out in stages throughout this week.

- Chat UI uses less CPU when idle or in the background.
- Idle ephemeral CLI sessions are purged after 15 minutes
- Memory extraction reuses the session’s model for more consistent results
- CLI and MCP stay pinned to the correct account after idle/recycle
- Browser bindings recover more reliably across upgrades and resolve the right window for the active profile
- Stabilize password vault and recovery logics
- New tab Chats / Routines tabs show unread badges
- Unarchiving sessions no longer reshuffles sidebar date order
- Narrow / sidepanel model menus stay usable: submenus open as overlays, and selecting a model no longer jumps or bounce-closes the menu.
- Editing a custom provider keeps `maxTokens`

enjoy!

> Background service: v1.26.810.1916

---

### 2026-08-12 00:50:47 KST — Dora Lee

- **UTC:** 2026-08-11 15:50:47
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1536763824659632338
- **Version:** Aside Browser `v1.0.811.1`
- **Edited:** yes (2026-08-12 01:03 KST)

@everyone

**Aside Browser v1.0.811.1 is now available**

Long time no see!! I shipped a new version of macOS Aside!

To update:
**Vertical tabs**: Click the Update indicator next to the traffic-light window controls.
**Horizontal tabs**: Click the Update button next to the profile button on the far right.

**What's new**

**New Rendering Engine Pipeline enabled**

- Performance is better than previous version of Aside (~ x1.5 ~ x2)

**Redesigned the sidebar**

- Chats now have their own section above regular tabs and are expanded by default.
- Pinned Tabs and profile controls remain fixed while the tab list scrolls.

**Improved New Chat**

- New Chat now appears as a dedicated row with its keyboard shortcut shown on hover.
- Opening it again focuses the existing New Chat tab instead of creating duplicates, and a newly started chat transitions into its own chat row.

**Added permanent chat deletion**

- Chats can now be permanently deleted from their context menu.

**Added a Tab Switcher order setting**

- Choose whether Ctrl + Tab lists tabs by most recently used order or by their current order in the sidebar.

**Improved profile switching**

- Switching profiles with many open tabs is now faster and smoother.
- Swipe previews are also more reliable in both directions, including when using a collapsed floating sidebar.

**Other fixes and improvements**

- Updated Chromium to `151.0.7922.109`
- Fixed Ask Aside changing its open or closed state when switching tabs. It now preserves the state selected by the user.
- Fixed the Aside password manager losing its pinned position or toolbar order after a component update.
- Fixed Picture-in-Picture sessions not returning to their original tab correctly after switching profiles.
- Fixed a crash when using Move Tab to Another Window.
- Fixed several crashes that could occur during browser startup, profile switching, window teardown, and vertical tab cleanup.
- Fixed a crash when opening the bookmark dialog from the focused address-bar button.
- Fixed a crash when using IME input through DevTools on a prerendered page.
- Fixed visual trails and stale highlights when dragging vertical tabs or expanding collapsed tab groups.
- Fixed Saved Tab Groups calculating incorrect tab move destinations when some synced tabs were not open locally.

Thanks as always for all the reports and feedback!

---

### 2026-08-12 18:33:45 KST — hiddenest

- **UTC:** 2026-08-12 09:33:45
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1537031330636763226
- **Version:** Background service `v1.26.812.1644`
- **Edited:** yes (2026-08-12 20:10 KST)

@everyone **Updates / August 12**

Good morning.

We shipped some qol improvements, bug fixes, and some improvement works.

- Introducing "Sidechat"
  - If you want to ask something but not interrupting the main chat, open sidechat.
- Fixed memory retrieving errors
  - Fixed the "no memories found" issue
  - Rebuilt stale memory caches so memory search works again after reloads
- Re-architectured Aside Password Manager
  - Fixed where Aside Password Manager shows sign in popup in random
  - logical improvements on loading metadata, agent vault access, TOTP suggestions, and more
- Ask Aside screen will show up slightly faster than before
- ... and more

Also, we'll patch more stuffs like restoring the bookmark header very soon.

enjoy!

> Background service: v1.26.812.1644

---

### 2026-08-13 04:24:45 KST — Dora Lee

- **UTC:** 2026-08-12 19:24:45
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1537180058274373692
- **Version:** Aside Browser `v1.0.813.1`
- **Edited:** no

@everyone

**Aside Browser v1.0.813.1 is now available**

To update:
**Vertical tabs**: Click the Update indicator next to the traffic-light window controls.
**Horizontal tabs**: Click the Update button next to the profile button on the far right.

**Fixes and improvements**

- Added a collapsible Bookmarks section to the vertical sidebar.
- Fixed an issue where pages would sometimes fail to load and remain stuck on a blank white screen indefinitely.
- Fixed numbered tab shortcuts (Ctrl/Command + 1–9) not working while the vertical sidebar was collapsed.
- Fixed the collapsed sidebar preview unexpectedly closing while the pointer was still at the edge of the window.
- Fixed nested extension submenus closing their parent menus when navigating to deeper levels.
- Fixed Split View tabs becoming separated or misplaced when moved to the end of the tab list.
- Improved the reliability of grouped and Split View tabs when moving them between profiles.
- Fixed the address bar’s permission indicator disappearing after camera or microphone activity ended while another permission was still active.
- Fixed a crash that could occur when closing the browser while a bookmark item was focused.
- Fixed crashes that could occur while navigating menus and dialogs with the keyboard.
- Improved stability when closing popovers and dialogs.
- Fixed tab updates and closures initiated from Aside's internal pages.

This update is focused on stability! Sorry for something laggy

---

### 2026-08-13 16:14:14 KST — hiddenest

- **UTC:** 2026-08-13 07:14:14
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1537358607312625745
- **Version:** Background service `v1.26.813.1554`
- **Edited:** no

@everyone **Updates / August 13**

Good morning. We made the biggest performance and accuracy improvements in Aside Password Manager. And also released few more runtime optimizations as well.

- Re-architected the whole password manager structure
  - Now it detects and autofills much better
  - Significantly reduced the CPU, memory, and DOM mutation usages -> make Aside more performant
  - Fixed bugs like showing unnecessary sign-in popup and improved metadata matching accuracy
- Support Proton Pass password import
- Prevented the daemon from stalling the whole app when it can't connect to api server (e.g. Tailscale connectivity issue)
- Added Grok 4.6 support (it will take up to an hour to fetch a new catalog)
- Fixed Tab-accepted omnibox completions bug

enjoy!

> Background service: v1.26.813.1554

#### Follow-up (same author, 2026-08-13 16:23:52 KST)

- **UTC:** 2026-08-13 07:23:52
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1537361031142047865

+ shoutout to @Sungmin for this massive update

---

### 2026-08-14 19:27:35 KST — hiddenest

- **UTC:** 2026-08-14 10:27:35
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1537769651591839886
- **Version:** Background service `v1.26.814.1913`
- **Edited:** no

@everyone **Updates / August 14**

- Revamped Settings page
  - restructured the menu hierarchy and polished some ui designs
  - also added search, so you can easily find relevant menu
- Fixed where Aside throws error before the compaction, especially using ChatGPT models
- Fixed logical failures when resetting account password
- Preserve generated-password autosave after sign up and redirected to other pages
- Optimized loading session files or memories

enjoy!

> Background service: v1.26.814.1913

---

### 2026-08-14 23:57:46 KST — hiddenest

- **UTC:** 2026-08-14 14:57:46
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1537837645730942986
- **Edited:** yes (2026-08-14 23:58 KST)

smol update on aside provider:

- Gemini 3.6 Flash → Gemini 3.7 Flash
- (new) DeepSeek V4 Flash (for all)
- (new) DeepSeek V4 Pro (Pro/Max users only)

It will be updated in the next few hours

---

### 2026-08-15 22:00:34 KST — hiddenest

- **UTC:** 2026-08-15 13:00:34
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1538170540580413460
- **Version:** Background service `v1.26.815.2155`
- **Edited:** no

@everyone **Updates / August 15**

Good morning. We fixed some rough cases and add a little touch to the UI.

- You can replace the agent completion sound with your own file
- More model support in Aside Provider #announcements
- Clicking an inline autofill suggestion no longer drops the field before credentials fill
- Fixed several compaction issues including sidechat, steer/queue, and such
- Experimental: agent can create or update logins in Apple Passwords
- Lasso and text selection can be turned on or off independently

enjoy!

> Background service: v1.26.815.2155

#### Follow-up (same author, 2026-08-15 22:01:11 KST)

- **UTC:** 2026-08-15 13:01:11
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1538170693638951042

and now we have 1️⃣ 0️⃣ 3️⃣ 4️⃣ members in our community! :party_parrot:

---

### 2026-08-16 21:43:48 KST — hiddenest

- **UTC:** 2026-08-16 12:43:48
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1538528706694348890
- **Version:** Background service `v1.26.816.2129`
- **Edited:** no

@everyone **Updates / August 16**

Good morning. It seems like more researchers are using Aside, so did some smol patches.

- Enhanced TeX rendering #general
- Fixed text selection breaks after the replacement #알 수 없음
- Show Password save popup when clicked 'Use generated password' on password manager
- Skip repeated tab finding api calls, which could cause infinite loops

enjoy!

> Background service: v1.26.816.2129

Note: Discord rendered the second channel mention as `#알 수 없음` (unknown / inaccessible channel). Left as shown.

---

### 2026-08-18 11:11:27 KST — hiddenest

- **UTC:** 2026-08-18 02:11:27
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1539094348409610302
- **Version:** Background service `v1.26.818.1059`
- **Edited:** yes (same minute; title is **Updates / August 17**)

@everyone **Updates / August 17**

wanted to hit the release button guys

- Pro users can now use Channels
- Improved reliability of password manager
  - OAuth sign-in suggestions and flows, Faster popup open, passkeys
- Long chats compact more reliably
- Ephemeral session cleanup is safer so live work isn’t wiped accidentally
- Editing a message after interrupt/steer targets the right message again

enjoy!

> Background service: v1.26.818.1059

---

### 2026-08-20 19:00:51 KST — hiddenest

- **UTC:** 2026-08-20 10:00:51
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1539937253923758080
- **Version:** Background service `v1.26.820.1844`
- **Edited:** no

@everyone **Updates / August 20**

Good morning. We added some QoL improvements and fixed some annoying bugs.

- Introducing `/Imagegen` skill
  - Ask the agent to make or edit images by using this skill
- Added Grok 4.6 in Aside provider (for everyone)
- Fixing compaction issues, especially on GPT-5.6 Sol
  - Long sessions with large repl output are compacted before they overflow the model context
- Login suggestions only appear when the field can actually be filled
- Fixed an issue when resetting password kept fail, especially someone who have large browsing history
- and many more...

+ We're planning to release another performance/bug fix release today (the smol one).

enjoy!

> Background service: v1.26.820.1844

---

### 2026-08-21 01:11:51 KST — hiddenest

- **UTC:** 2026-08-20 16:11:51
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1540030618988052523
- **Version:** Background service `v1.26.821.53`
- **Edited:** no

@everyone Folks, smol updates

- The agent can no longer create or mutate Chrome tabs in ways that steal focus
- Revamped showing the context usage UI
  - it also show 5-hour, weekly, and monthly usage, if you're using your sub
- Opening new tab page will be slightly faster than prev version
- In a narrow sidepanel, the session title no longer covers other buttons
- Fixed an issue when clicking "Open with" shows an error on Outputs section

enjoy!

> Background service: v1.26.821.53

---

### 2026-08-21 18:11:59 KST — hiddenest

- **UTC:** 2026-08-21 09:11:59
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1540287342856634408
- **Version:** Background service `v1.26.821.1756`
- **Edited:** no

@everyone **Updates / August 21**

Good morning. We fixed several bugs today, and did some preps for the new features.

- Fixed an issue where agents open tabs in inaccessible groups, so it couldn't complete tasks
  - Fixed similar issues with popups and pages opened via `window.open`
- Added notices for Aside reauthentication and monthly usage limits
- Fixed an issue where the passkey dialog appeared before the page requested a passkey
- Reduced the frequency of idle vault background syncs
- Fixed image generation failures for people who use ChatGPT sub
- Hardening compaction edge cases

enjoy!

> Background service: v1.26.821.1756

---

### 2026-08-22 22:00:39 KST — hiddenest

- **UTC:** 2026-08-22 13:00:39
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1540707277709901874
- **Version:** Background service `v1.26.822.2145`
- **Edited:** yes (2026-08-22 22:02 KST)

@everyone **Updates / August 22**

Good morning, and enjoy your weekend.

- You can connect **Command Code** with an API key (GOAT, Pro, Max plan)
- Fixed an issue that Agent runtime tools (rg, Python, PDF helpers) were blocked by Gatekeeper after download
- You can find and select 'Ox Alpha' on OpenRouter models
- On a narrow chat view, pinned summary floats over the chat instead of squeezing it
- You can right click on a created files and select which app to open (e.g. Preview, Pages, and such)
- ...and fixed some tiny bugs

enjoy!

> Background service: v1.26.822.2145

---

### 2026-08-24 17:44:04 KST — Dora Lee

- **UTC:** 2026-08-24 08:44:04
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1541367481522847784
- **Version:** Background service `v1.26.824.2150`
- **Edited:** yes (2026-08-24 22:05 KST)

@everyone **Updates / August 24**

Good morning. You can now capture anything on a page and use Aside with iMessage. We also improved reliability and polished the chat experience.

- Introducing **Screen Capture**
  - Capture the viewport, full page, an element, or any selected area
  - Right-click → Capture, or use Cmd+Shift (Ctrl+Shift) and drag
- Introducing **iMessage**
  - Ask Aside to read or search messages, find contacts, and send texts or files after your approval
  - Aside can also pick up verification codes that just arrived during sign-in
- Replies now recover more reliably from temporary service limits
- Fixed issues that could prevent plugins, tools, and routines from loading correctly
- fixed some tiny bugs

enjoy!

> Background service: v1.26.824.2150

---

### 2026-08-25 20:32:26 KST — Dora Lee

- **UTC:** 2026-08-25 11:32:26
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1541772239190495232
- **Version:** Aside Browser `v1.0.825.1`
- **Edited:** no

@everyone

**Aside Browser v1.0.825.1 is now available**
I shipped a new version of macOS Aside!

**To update:**
**Vertical tabs:** Click the Update indicator next to the traffic-light window controls.
**Horizontal tabs:** Click the Update button next to the profile button on the far right.

**What's new**

**Mini Popup**

- Open Ask Aside from any app using a configurable global shortcut.

**Improved tab UX**

- Tabs can now be dragged between regular tabs, Pinned Tabs, and Bookmarks.
- Added smoother drag previews and animations when moving items between sections.

**Improved Agent Tabs**

- Tabs grouped under Agent Tabs are now muted by default.

**Improved Ask Aside and Agent Manager**

- Ask Aside now temporarily hides on Agent Manager and New Tab pages, then returns to its previous state when leaving those pages.

**Improved profile switching**

- Fixed tabs and Chat state being replaced or lost when switching profiles, particularly when using multiple windows.
- Fixed profile switching occasionally showing or focusing the wrong window.

**Fixes and Improvements**

- Updated Chromium to `151.0.7922.171`.
- Fixed restored New Tab pages opening the blank page instead of Agent Manager.
- Fixed the crash recovery prompt reappearing after it had already been dismissed or acknowledged.
- Fixed horizontal tabs becoming invisible after rapid scrolling.
- Fixed the browser opening before Password Manager, Agent Manager, or required background components were ready.
- Fixed extension actions launched from Tab Search opening in the wrong browser window or leaving Tab Search open.
- Removed the duplicated browser import entry from Settings.
- Fixed several crashes involving menus, Task Manager, dialogs, Sync, search suggestions, and extension image handling.
- Fixed macOS crashes involving Dock reopening, task popovers, and AppleScript bookmark insertion.
- Updated the Aside app icon for the macOS Clear appearance

Thanks as always for all the reports and feedback!

---

### 2026-08-29 15:31:41 KST — hiddenest

- **UTC:** 2026-08-29 06:31:41
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1543146104781275166
- **Version:** Background service `v1.26.829.1514`
- **Edited:** no
- **Title in post:** Updates / Aug 28 (posted Aug 29 KST)

@everyone **Updates / Aug 28**

Good night and good morning, everyone. I got covid for the last several days so couldn't reply. but the whole team worked really hard and rolled out some of the features and the fixes.

- You can keep the current sidepanel chat when you change tabs, instead of always opening a new session
- You can set default new tab mode to either search or ask
- Faster account sync (another "our cto is cooking" series)
  - the query latency is now 16.7x faster and the connection latency is 2x faster
- (Experimental) share your sessions with a link. click [share] on the top of the chat view
- new commands for channels
  - /model, /effort, /sessions, /usage, and /new work
  - for slack, please add leading space (e.g. `/model`)
- Stabilized mini popup behavior
- Lasso respones no longer dumps quote or `\n`
- Fixed several bugs..

> Background service: v1.26.829.1514

---

### 2026-08-31 15:25:47 KST — hiddenest

- **UTC:** 2026-08-31 06:25:47
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1543869396873904168
- **Version:** Background service `v1.26.831.1513`
- **Edited:** no

@everyone **Updates / Aug 31**

Good morning. We're planning to release some exciting features you'll love and improve the CLI/MCP experience over the coming week. but before that.. smol fixes.

- After Cmd+Q or a crash, leftover Agent Tabs will be closed
- Telegram voice notes are transcribed in Channels
- Task composer stays on screen instead of overflowing the viewport
- After a rate limit, the agent no longer retries compaction on the same transcript
- Added some mysterious experimental features

see ya tomorrow!

> Background service: v1.26.831.1513

---

### 2026-09-02 04:52:10 KST — hiddenest

- **UTC:** 2026-09-01 19:52:10
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1544434717418594364
- **Edited:** no

@everyone **Claude Fable 5.1** is now available on Aside Plan (for Pro/Max users).
It will take up to hour to show it on model catalog.

+ Claude subscription will see it very soon (updating the upstream provider provision)

---

### 2026-09-02 09:07:28 KST — hiddenest

- **UTC:** 2026-09-02 00:07:28
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1544498964114448544
- **Edited:** no

@everyone
We just updated the background service, but seems like the local migration process is taking longer than we expected, causing empty screen for new tab / task page. We're looking into this and share the status soon.

#### Follow-up reply (same author, 2026-09-02 09:45:13 KST)

- **UTC:** 2026-09-02 00:45:13
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1544508463500234763
- **Edited:** yes (same minute)

[Update] we found two related issue:

- Cloudflare was a bit unstable for about 5-10 min
- (depends on 1) Channels initialization takes lots of time like 50-80s

so, the initialization won't take that much (and closing the case).
but will patch more code to prevent channel initialization blocks the background service booting.

---

### 2026-09-02 17:37:44 KST — hiddenest

- **UTC:** 2026-09-02 08:37:44
- **Message:** https://discord.com/channels/1518417473043693608/1518420346057785444/1544627376346890331
- **Version:** Background service `v1.26.902.1713` / CLI `v1.26.902.1732`
- **Edited:** yes (2026-09-02 17:38 KST)

@everyone **Updates / Sep 2**

Good morning. We just revamped the CLI/MCP experiences. Also, I guess that lots of new models will be released this week, so i'll keep working on it.

- Revamped Aside CLI / MCP and Skills
  - rewrote the whole `/aside-browser` skills
  - your agent can now use Aside built-in skills with `aside skills`
  - search Aside's memory with `aside memory`
  - added more commands like `aside session resume|steer|queue|stop..`
  - permission / ask user question tool / final confirm won't throw an error
  - now we let MCP can create and run the agent tasks
- Introducing Remote Control (for Pro/Max users)
  - now you can run the task in the remote device
  - enable it on settings > developers
  - `aside exec --host <hostname> "<prompt>`

> ⚠️ **Please update your Aside CLI** (`aside --update`)

- QoL improvement: Now you can move your chats to the other projects
- Copying a credential in password manager now schedules a clipboard clear
- Fixed an issue that Claude subscription users can't use Fable 5.1

happy coding!

> Background service: v1.26.902.1713
> CLI: v1.26.902.1732

---

## Version index (this window)

| Date (KST) | Author | Named version(s) |
|---|---|---|
| 2026-08-10 | hiddenest | Background service `v1.26.810.1916` |
| 2026-08-12 | Dora Lee | Aside Browser `v1.0.811.1` |
| 2026-08-12 | hiddenest | Background service `v1.26.812.1644` |
| 2026-08-13 | Dora Lee | Aside Browser `v1.0.813.1` |
| 2026-08-13 | hiddenest | Background service `v1.26.813.1554` |
| 2026-08-14 | hiddenest | Background service `v1.26.814.1913` |
| 2026-08-15 | hiddenest | Background service `v1.26.815.2155` |
| 2026-08-16 | hiddenest | Background service `v1.26.816.2129` |
| 2026-08-18 (titled Aug 17) | hiddenest | Background service `v1.26.818.1059` |
| 2026-08-20 | hiddenest | Background service `v1.26.820.1844` |
| 2026-08-21 | hiddenest | Background service `v1.26.821.53` |
| 2026-08-21 | hiddenest | Background service `v1.26.821.1756` |
| 2026-08-22 | hiddenest | Background service `v1.26.822.2145` |
| 2026-08-24 | Dora Lee | Background service `v1.26.824.2150` |
| 2026-08-25 | Dora Lee | Aside Browser `v1.0.825.1` |
| 2026-08-29 (titled Aug 28) | hiddenest | Background service `v1.26.829.1514` |
| 2026-08-31 | hiddenest | Background service `v1.26.831.1513` |
| 2026-09-02 | hiddenest | Background service `v1.26.902.1713`, CLI `v1.26.902.1732` |

No `#announcements` post between 2026-08-10 and 2026-09-02 named a background-service build as `1.26.902` until the Sep 2 CLI/MCP post (`v1.26.902.1713` / CLI `v1.26.902.1732`). Native browser releases in this window were `v1.0.811.1`, `v1.0.813.1`, and `v1.0.825.1`.
