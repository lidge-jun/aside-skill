# Deep-research lane research

Question: what does Aside add to research that a hosted `web_search` cannot do, and
which surface owns each step. Every rung below was probed live on CLI
`1.26.810.1915` / daemon `1.26.829.1514`.

## The differentiator is the signed-in profile

This is the whole reason the lane exists. Two probes, both from a plain CLI repl:

```js
const p = await openTab('https://x.com/search?q=aside%20browser&f=live');
const s1 = await snapshot(p, { interactive: true });   // 15099 chars, signed-in results
```

```js
const t = await twitter.search('aside browser', { count: 3 });
// prints: X auth extracted (auth_token present, ct0 from cookie)
// returns: { tweets: [{ id, text, author: { screenName, followersCount, ... }, createdAt }] }
```

A hosted search tool reaches neither. The first is a logged-out-blocked results page;
the second is structured data with follower counts and timestamps, no DOM parsing.

## Rung inventory

| rung | probe | result |
|---|---|---|
| `fetch(url)` public | `fetch('https://example.com')` | `status=200`, 559 bytes |
| `fetch(url)` JSON API | `fetch('https://api.github.com/repos/openai/codex')` | `200`, live `stargazers_count` and `pushed_at` |
| `openTab` + `snapshot` | Hacker News | 10363-char interactive tree |
| signed-in page | `x.com/search?f=live` | 15099-char tree, no login wall |
| structured API | `twitter.search` | 3 tweets with author metadata |
| video research | `youtube.search('aside browser', {limit:2})` | 2 results with videoId, title, channelName |
| prior art | `chrome.history.search({text:'aside', maxResults:3})` | real visit with `visitCount` and `lastVisitTime` |
| general search engine | DuckDuckGo results page | 8507-char tree, result links extracted, no challenge |
| `googleSearch.search` | any query | **fails**, see below |

## googleSearch is not a rung

```text
Google Search returned bot challenge HTML. Open
https://www.google.com/search?q=...&safe=active&num=20 in the browser, solve it,
then retry.
```

The remedy the error itself proposes is a human solving a challenge, which a
non-interactive run cannot do. It fails fast rather than hanging, so it is not
dangerous, but it cannot be the discovery rung. DuckDuckGo through
`openTab` + `snapshot` went through cleanly on the same machine and is the
in-browser fallback when one is needed at all.

## The daemon watches snapshot handling

Calling `.split()` on a snapshot tree produced an unsolicited runtime warning:

```text
[system][warning] DO NOT USE tree.split() - you're hiding important context from
snapshot. don't hesitate to print the full tree or diff.
```

The mechanism, not just the message. The daemon holds a template, not the finished
string, which is why a literal grep for `DO NOT USE tree.split()` finds nothing:

```js
SNAPSHOT_SLICE_WARNINGS = ['substring','slice','split'].map(xn =>
  [RegExp(`tree\\.\${xn}\\s*\\(`), `[system][warning] DO NOT USE tree.\${xn}...`])
```

So all three of `substring`, `slice`, and `split` are matched by regex against the
code you submit, and the method name is interpolated into the warning at runtime.
Search the binary for `DO NOT USE tree.` or `hiding important context` to find it.

This makes the never-truncate rule enforced rather than merely documented, and it is
aimed squarely at research code: filtering a tree down to "just the links" is exactly
the shape that trips it.

## Division of labour

Codex owns discovery and judgment: hosted `web_search` for candidate URLs, the claim
ledger, and synthesis. It also has full filesystem access, so it keeps the notes.

repl owns proof that needs cookies, plus the structured APIs and history. It is cheap,
fails fast on a bad path, and each invocation is a complete flow.

exec owns anything needing judgment mid-research or an account action: signing up for
a service to read its docs, logging in, solving a CAPTCHA, navigating an unfamiliar
flow. It is the only surface with `passwordManager`.

## Constraints the lane inherits

- repl scope dies per invocation, so a research flow fits one call or reattaches a
  window tab with `attachBrowserTab`.
- exec file tools hang outside `~/.aside/u/0/`, so notes land under the account root
  and Codex copies them out.
- Snippets are never evidence. An Aside-proved claim must record which surface proved
  it, because "signed-in snapshot" and "public fetch" are different strengths of
  evidence.

## Phases

- `010`: write `references/deep-research.md`.
- `020`: add the routing section to SKILL.md and a README line.
- `030`: ship.
