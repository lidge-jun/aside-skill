# Deep research with Aside

Ordinary research does not need this. A hosted web search plus opening the page is
cheaper and better for anything public. Reach for Aside when the sources themselves
are behind a login, or when the research needs an account action partway through.

## Why the signed-in profile matters

Two measurements from a plain CLI repl, no setup:

```js
const p = await openTab('https://x.com/search?q=aside%20browser&f=live');
const s1 = await snapshot(p, { interactive: true });
console.log(s1.tree);   // 15099 chars of signed-in search results
```

```js
const t = await twitter.search('aside browser', { count: 3 });
// logs: X auth extracted (auth_token present, ct0 from cookie)
// returns { tweets: [{ id, text, author: { screenName, followersCount }, createdAt }] }
```

Nothing without that session gets the same page, and both halves of that were tested
rather than assumed:

| how the same URL was opened | what came back |
|---|---|
| `curl`, no session | `200`, 289KB, zero tweet markup - the JavaScript shell, carrying "JavaScript is not available" |
| real rendering Chrome, isolated profile, no session | a sign-in wall: "Email or username", "Continue with phone", "Continue with Apple", zero results |
| Aside CLI repl, signed-in profile | 15063-char interactive tree of actual search results |

So it is neither an HTTP refusal nor only a rendering problem. Fetching gets bytes with
no results, rendering without a session gets a login form, and only the session gets the
page. The second probe skips the page entirely and returns structured data with follower
counts and timestamps, no DOM parsing at all.

That gap is the only reason to bring Aside into a research task.

## Who does what

Codex discovers and decides. Aside proves what needs cookies. exec handles anything
that needs judgment or an account.

| step | surface | call | measured |
|---|---|---|---|
| find candidates | Codex | hosted `web_search` | - |
| prove a public page | repl | `fetch(url)` | `200`, 559 bytes on a static page |
| pull a JSON API | repl | `fetch(apiUrl)` then `.json()` | live `stargazers_count` and `pushed_at` |
| read a rendered page | repl | `openTab` + `snapshot` | 10363-char interactive tree |
| read a page behind a login | repl | `openTab` on the signed-in URL | 15099-char tree, no wall |
| query a service directly | repl | `twitter.search`, `youtube.search`, `gmail.search`, `linkedin.searchPeople` | 3 tweets / 2 videos with metadata |
| pull a transcript | repl | `youtube.getTranscript(url)` | - |
| check prior art | repl | `chrome.history.search({ text, maxResults })` | real visits with `visitCount`, `lastVisitTime` |
| in-browser search engine | repl | `openTab('https://duckduckgo.com/?q=...')` | 8507-char tree, no challenge |
| sign up, log in, solve a CAPTCHA | exec | delegated prompt | see the template below |
| synthesise | Codex | - | - |

Discovery stays on Codex. Aside is a proof surface, with one exception: when the source
is itself behind a login, Aside does the discovery too, because nothing else can see it.

## googleSearch is not a rung

`googleSearch.search()` exists and fails:

```text
Google Search returned bot challenge HTML. Open
https://www.google.com/search?q=...&safe=active&num=20 in the browser, solve it,
then retry.
```

The remedy it proposes is a human solving a challenge, so it cannot be a rung in an
unattended run. It fails fast rather than hanging, which makes it harmless but useless.
When an in-browser engine is genuinely needed, DuckDuckGo through `openTab` went
through cleanly on the same machine.

## Recipes

Each fits one invocation, because repl scope dies with the process.

**Signed-in sweep.** Open the authenticated search URL, read the whole tree, and write
the notes inside the account root:

```js
const p = await openTab('https://x.com/search?q=<query>&f=live');
const s1 = await snapshot(p, { interactive: true });
console.log(s1.tree);
await fs.mkdir('./artifacts', { recursive: true });
await fs.writeFile('./artifacts/sweep.md', s1.tree);
```

**Structured pull, no page.** Faster and cleaner than scraping when the service has an
API behind the global:

```js
const t = await twitter.search('<query>', { count: 20 });
console.log(JSON.stringify(t.tweets.map(x => ({
  url: 'https://x.com/' + x.author.screenName + '/status/' + x.id,
  followers: x.author.followersCount, at: x.createdAt, text: x.text }))));
```

**Transcript plus reception.** What a video says and how it landed, in one call:

```js
const r = await youtube.search('<topic>', { limit: 3 });
console.log(JSON.stringify(r));
const tr = await youtube.getTranscript(r[0].url);
console.log(tr);                       // a plain string, not a segment array
const c = await youtube.getComments(r[0].url, { limit: 20 });
console.log(JSON.stringify(c));
```

Both recipes above were run as written. `getTranscript` returned an 8892-character
string of Korean narration for a Korean video, so it follows the audio language rather
than the query. The tweet mapper returned real permalinks, follower counts, and ISO
timestamps.

**Prior art.** Whether the user already read something, which no external search knows:

```js
console.log(JSON.stringify(await chrome.history.search({ text: '<topic>', maxResults: 20 })));
```

## Never filter a snapshot

The daemon watches for this. It holds a template, not a fixed string:

```js
SNAPSHOT_SLICE_WARNINGS = ['substring','slice','split'].map(m =>
  [RegExp('tree\\.' + m + '\\s*\\('), '[system][warning] DO NOT USE tree.' + m + '() ...'])
```

All three methods are regex-matched against the code you submit, and the method name is
interpolated into the warning at runtime. Research code is the usual offender: reducing
a tree to "just the links" is exactly that shape. Print the whole tree, or `diff` after
an action.

## Research that needs an account

Signing up to read documentation, logging into a portal, clearing a CAPTCHA - repl
cannot do these, because `passwordManager` lives only in exec's repl tool. Delegate:

```bash
timeout 600 aside exec "Research <question> using <site>, which requires an account.

If a sign-in is needed, use your repl tool: search the vault with
passwordManager.listItems({ text: '<host>', category: 'login' }) and fill a clearly
matching item with passwordManager.autofillItem(page, itemId). Verify with a fresh
snapshot. Never print a password.

If no item matches, stop and report that the vault has no credential for <host>.
Do not create an account.

If a passkey appears, try 'Try another way' and a password fallback first.

Then answer <question>. For every claim, report the exact URL you read it on and quote
the sentence that supports it. Do not summarise a page you did not open.
Write your notes to ~/.aside/u/0/research/<slug>.md.

Use read_file, write_file and edit_file only under ~/.aside/u/0/. For any other
local path use the bash tool instead - never the file tools.
Downloading to ~/Downloads is fine; move anything you keep under ~/.aside/u/0/.
Do not ask me any questions. If something is blocked or ambiguous, pick the most
reasonable option and continue, or report exactly what blocked you and stop."
```

Then copy the notes out yourself; Codex has the filesystem access Aside does not.

## Creating an account, only when asked

`passwordManager` can register a new account, and research alone is not a reason to.
Signing up commits the user to terms they have not read, attaches their identity and
email to a service, and can start a trial that later charges them. Treat it as an
action outside the research mandate: ask the user first, name the site, and say what
the account will be used for. Without that answer, report the missing credential and
stop.

Once the user has agreed, add this to the exec prompt in place of the stop clause. It
keeps the password out of the transcript by passing a reference:

```text
The user has approved creating an account on <site>. Register with <email>, and never
handle the password yourself: generate a reference with
passwordManager.generatePassword({ length: 16, include: ['lowercase','uppercase','digit'] }),
fill it into the password field ref from your latest snapshot with
passwordManager.fillPassword(page, '<field-ref>', passwordRef), and after signup save it
with passwordManager.listVaults() then passwordManager.createItem({ vaultId, category:
'login', title, urls, fields: [{ label: 'username', value: '<email>', designation:
'username' }, { label: 'password', value: passwordRef, designation: 'password', isSecret:
true }] }). Pass the ref, never a literal password.

Do not accept a paid plan, enter payment details or start a trial that requires a card.
If signup demands any of those, or asks to verify a phone number, stop and report it.
```

Confirm the item landed in the vault afterwards, so the user owns a credential they can
find and revoke rather than one stranded in a transcript.

## Claim ledger

Record which surface proved each claim, because they are not equal strengths:

| claim | source URL | date | proving surface | status |
|---|---|---|---|---|
| ... | ... | ... | `repl fetch` / `repl snapshot (signed-in)` / `twitter.search` / `exec` / `Codex fetch` | candidate / verified / contradicted |

A claim reaches `verified` when a source was opened and read, never on a snippet. State
what the proof actually establishes: a snapshot proves the opened source **displays**
the claim, not that the claim is true. A signed-in dashboard showing a number proves the
dashboard shows it.

Rank by that column when sources conflict. An official document beats a signed-in page,
which beats a public page, which beats a snippet. Say which one won and why rather than
averaging them.
