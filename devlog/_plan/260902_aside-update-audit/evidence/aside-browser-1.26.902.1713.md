---
name: aside-browser
version: 2
description: Use this skill for any task that needs a browser.
---

# Aside browser

Aside is an AI browser. Inside Aside, there is an intelligent agent designed to handle complex tasks across user's credentials, cookies, browsing history, and various websites the user uses.  
Default: hand the work to Aside. Skip JavaScript unless the user named Playwright or asked you to attach to a specific tab and run code. Do not mix both in one request.

\`aside --help\` and \`aside <command> --help\` print current flags and examples.

## Run the task to Aside

Use this for research or actions on websites like Slack or Gmail. Aside plans the steps and controls the browser. Plain text only.

Start Aside Browser before running CLI commands. (Use \`aside -h\` to see how.)

### Start a task

\`\`\`bash
aside "Find flights from SF to Tokyo for next weekend"
aside -m openai/gpt-5.6-sol -s fast --effort high "Research quarterly earnings"
aside --effort ultrabrowse "Research this deeply"
aside --account u1 "Check unread Slack notifications"
aside --permission full-access "Install the CLI from the project README"
aside "https://example.com"
\`\`\`

After running the task, watch the run and give the user a status update around every 60 seconds.

### Control sessions

\`\`\`bash
aside session resume <id>
aside session resume <id> "Continue the search"
aside session steer <id> "Switch to Google Flights"
aside session queue <id> "Export the final list to CSV"
aside session stop <id>
aside session archive <id>
aside session delete <id>
\`\`\`

Resume with a prompt argument runs a single turn. Resume without a prompt opens an interactive session with \`>\`, \`/session\`, and \`/exit\`.

\`steer\` redirects a running turn. \`queue\` schedules instructions after the current step. Both commands print \`ok\` and exit.

\`aside session list\` includes sessions that were not saved to the chat list.

### Persistence

Sessions stay off the chat list by default. \`aside settings save-sessions true\` keeps them there.
\`aside settings set-default-profile u1\` makes later CLI commands use that profile. One-shot override: \`--account u1\`.

## Memory

Aside continuously distills the user's browsing into plain-Markdown memory. Recall it before asking the user about prior context:

\`\`\`bash
aside memory search "<query>" --json
aside memory list --json
aside memory show MEMORY.md
aside memory path
\`\`\`

Never edit memory files yourself. If the user wants Aside to remember something, run it through \`aside exec\`. Over \`aside mcp\`, prefer the \`memory_search\` tool.

## Skills

Check for an Aside skill before driving a site through \`snapshot()\` by hand:

\`\`\`bash
aside skills list
aside skills show <name>
\`\`\`

Read the matching skill first, then follow it. Tell the user which Aside skill you are using and for what.

## Remote hosts

\`\`\`bash
aside host list
aside exec --host <id-or-name> "..."
aside repl --host <id-or-name>
aside host use <host>
\`\`\`

Same Aside account, Remote Control enabled on the host. \`aside login\` once; afterwards remote hosts work even when Aside is not running locally.

## Drive the browser with JavaScript

Open this path when the user named Playwright, asked for a snapshot/locator script, or told you to attach to a given tab and run JS. Aside stays out.

\`\`\`bash
aside repl "…"
\`\`\`

MCP \`repl\` takes \`{ title, code }\`. Timeout is 120s. No \`import\`/\`require\`. Print with \`console.log()\`.

\`page\` starts unset. \`listBrowserTabs()\`, then \`attachActiveBrowserTab()\` or \`attachBrowserTab(targetId)\`. \`openTab(url)\` only if nothing relevant is open.

\`snapshot(page)\` returns \`{ tree, diff }\`. Click with \`page.locator('e12')\`, never as CSS. A new snapshot invalidates old refs. Print \`tree\` first, then \`diff\`. Fall back to \`annotatedScreenshot(page)\` when the tree is not enough.
`}));function directoryExists(Cn){try{return fs.statSync(Cn).isDirectory()}catch{return!1}}function fileExists(Cn){try{return fs.statSync(Cn).isFile()}catch{return!1}}function getAgentConfigDir(Cn){return directoryExists(Cn.configDir)?Cn.configDir:Cn.fallbackConfigDirs.find(directoryExists)??null}function getAsideBrowserSkillFile(Cn){return path.join(Cn,ASIDE_BROWSER_SKILL_NAME,`SKILL.md