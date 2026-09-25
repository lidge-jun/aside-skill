# Credentials and first-run setup

Aside can sign in through Aside Vault without exposing a raw password to the
agent.

**Sign-in is exec's job first.** When a task reaches a login page, hand the
login to `aside exec` (or the attached native `exec` tool) inside the same task
prompt. Its agent searches Aside Vault and any connected password manager,
autofills, and may choose a sign-in route such as SSO with the signed-in
browser account (exec's judgment; not separately measured here). Do not ask the
user to sign in or unlock anything beforehand. Ask the human only after exec
reports a concrete blocker: locked Vault, access policy `Never`, no matching
credential, MFA, passkey, CAPTCHA or identity verification. Exec signing in
stays inside the task's authorization: no account switching, no policy or
biometric changes, and no new account creation without the user's say-so.
Observed 2026-09-25: a coding agent told the user to sign in to Cloudflare by
hand; the user corrected it because exec could do the login itself.
 Unlock state, the agent access policy, and any MFA, passkey, CAPTCHA, or
identity-verification step remain under human control. Read this before asking
`exec` to log in anywhere.

The current official Vault policy is documented first. The Apple Passwords and
provider-helper sections preserve dated observations from older builds; verify
the helper exists in the active runtime before relying on it.

## Windows provider observations (measured 2026-09-11)

The measured Windows builtin tree exposed Aside's `passwordManager` through the
exec agent's repl tool and included these provider skills: `1password`,
`bitwarden`, `dashlane`, `lastpass`, `proton-pass`. All five are present on
that measured build. None used the Apple Passwords PIN handshake.

If the user has a choice of provider, 1Password is the smoother one for
agent-driven sign-in. Aside ships a builtin `1password` skill that `exec` can
load by name. The other four sidestep a vault-PIN ceremony the same way.

Practical sequence on that build: `exec` searches the Aside vault or a connected
provider and autofills; the user signs in by hand only if exec reports a blocker. The
2026-09-11 Windows inventory did not include the `apple-passwords` builtin skill;
do not generalize that observation to an uninspected runtime.

## Aside Vault unlock and agent access

Official documentation checked 2026-09-22 separates two choices:

- Touch ID on macOS and Windows Hello on Windows are optional ways for the user
  to unlock Aside Vault. Choosing `Enable` or `Not now` is the user's decision.
- `Settings > Passwords > Access policy for AI agents` controls agent use with
  `Always allow`, `While unlocked`, or `Never`. Imported items may override the
  global policy per item, and Vault access is unavailable in incognito sessions.

Unlock method does not expand agent access. Before an unattended login task, the
user chooses the access policy and unlocks the Vault when their policy requires
it. That is a standing user choice, not a pre-task step the agent requests: exec
attempts first. If the Vault is locked or the site requires MFA, passkey approval, CAPTCHA,
or identity verification that the current run cannot complete, return an explicit
blocked result. Do not change biometric settings, access policy, or internal
password-settings JSON to make the task proceed.

Current source: [Use Password Manager](https://docs.aside.com/help/password-manager).

## macOS-only: Apple Passwords (historical observations)

The helper names and result shapes below were measured on macOS from 2026-08-31
through 2026-09-03, around CLI 1.26.902 and daemon 1.26.903. They are retained as
diagnostic evidence, not a current runtime contract. Inspect the active REPL guide
and globals before using them. The 2026-09-11 Windows inventory found no
`apple-passwords` skill.

Apple Passwords keeps its own encryption key. Until that key is unlocked in the
current Aside session, every credential read fails:

```
Missing Apple Passwords encryption key.
Call applePasswords.requestAuth(), then applePasswords.verifyAuth(pin).
```

In those probes, `requestAuth()` returned an instruction rather than a key:

```json
{"status":"auth-requested",
 "instruction":"Ask the user to approve Apple Passwords / Touch ID and provide
                the 6-digit code if macOS shows one, then call
                applePasswords.verifyAuth(pin)"}
```

macOS then showed a **6-digit code that only a human could read off the screen**.
The measured surface exposed no API that returned it. An agent in a non-interactive `exec` run had no
way to obtain it, and if the prompt does not forbid questions the agent asks anyway:
through 1.26.831 that call deadlocked the run, on 1.26.902 the tool is gone and the
question ends the run unanswered.

This is not hypothetical. A real run hit exactly this and stopped cleanly only
because the standing clauses forbade questions:

> "The vault unlock step failed because a 6-digit PIN prompt appeared on macOS
> that I cannot complete myself. I reported exactly what appeared and stopped."

The measured setup required a human at the keyboard. Treat the commands below as
historical diagnostics and verify them against the active guide before use.

**1. Complete the one-time 6-digit setup.** In Aside, open Settings, go to the
password manager section, and connect Apple Passwords. Install the Apple Passwords
Importer when prompted. Then trigger the unlock once and enter the 6-digit code
macOS displays.

```bash
# macOS / bash
aside repl "console.log(JSON.stringify(await applePasswords.requestAuth()))"
# read the 6-digit code off the macOS prompt, then:
aside repl "await applePasswords.verifyAuth('<6-digit-code>'); console.log('unlocked')"
```

```powershell
# macOS / PowerShell
& "$HOME/.local/bin/aside" repl "console.log(JSON.stringify(await applePasswords.requestAuth()))"
& "$HOME/.local/bin/aside" repl "await applePasswords.verifyAuth('<6-digit-code>'); console.log('unlocked')"
```

Confirm it worked before delegating anything:

```bash
# macOS / bash
aside repl "try{const l=await applePasswords.listLogins();console.log('UNLOCKED',l.length)}catch(e){console.log('LOCKED',e.message)}"
```

```powershell
# macOS / PowerShell
& "$HOME/.local/bin/aside" repl "try{const l=await applePasswords.listLogins();console.log('UNLOCKED',l.length)}catch(e){console.log('LOCKED',e.message)}"
```

After setup, use the user's current Vault unlock choice and access policy. Do not
disable biometrics or edit internal settings as an automation workaround.

### Importer install failure

Connecting Apple Passwords may fail with:

```
EPERM: operation not permitted, open
'$HOME/Library/Containers/at.studio.AsideBrowser.PasswordImporter/Data/.aside/
 apple-credential-exchange-helper-context.json'
```

In the 2026-08-31 probe, this came from a stale sandbox container left by an
earlier install with a `com.apple.quarantine` attribute. The recovery below was
verified for that failure shape. Use it only after confirming the same condition
and receiving authorization to quit Aside and move the container:

```bash
# macOS / bash
pgrep -f Aside            # must be empty first
mkdir -p "$HOME/.aside-container-backup"
mv "$HOME/Library/Containers/at.studio.AsideBrowser.PasswordImporter" "$HOME/.aside-container-backup/"
open -a Aside
```

```powershell
# macOS / PowerShell
& /usr/bin/pgrep -f Aside            # must be empty first
New-Item -ItemType Directory -Force -Path "$HOME/.aside-container-backup" | Out-Null
Move-Item -LiteralPath "$HOME/Library/Containers/at.studio.AsideBrowser.PasswordImporter" -Destination "$HOME/.aside-container-backup/"
Start-Process -FilePath /usr/bin/open -ArgumentList @('-a','Aside')
```

That probe moved rather than deleted the container so it could be restored. It
found credentials in `$HOME/.aside/u/0/passwords/vault.encrypted.db`, not in the
moved container, and verified that recreation fixed the EPERM. The 2026-09-11
Windows inventory found no PasswordImporter container.

## Two credential surfaces (measured 2026-08-31 to 2026-09-03)

On the measured builds, `applePasswords` was available in `aside repl` on macOS
and needed the key ceremony. `passwordManager` was Aside's native manager,
exposed to the **exec agent only** (`undefined` in a CLI repl session), and its
listing results omitted secret values. The builtin `password-manager` skill
documented it; `exec` could load that skill by name. Re-check these surfaces in
the active runtime before depending on them.

Practical consequence: let `exec` use `passwordManager` and the provider skills
by default. The Apple Passwords key ceremony needs a human to read a 6-digit
code, so use it only after exec reports that the needed credential lives there,
and do not ask `exec` to perform that ceremony. On Windows, skip
`applePasswords` and use `passwordManager` / the provider skills.

### The unlock outlived the session in the measured build

Worth knowing before you plan around the PIN: `verifyAuth` is not per-session. A
CLI repl called `requestAuth()`, a human read the 6-digit code off the macOS
prompt, and `verifyAuth('<code>')` returned `{"status":"authenticated"}`. Every
later call - new repl processes, and `exec` runs after them - went straight
through with no second prompt. The key is held at the account level, bounded by
`autoLockTimeout`, not by the process that unlocked it.

That observation does not establish current unlock duration. Let the user unlock
again when the active Vault policy or runtime asks.

`applePasswords.listLogins` takes a `url` and returned `[]` for every site tried,
even with 319 items in the vault. That observation did not prove the external
vault was empty. In the same dated probe, matching items were reachable through
`passwordManager`.

### Verified: exec fills a login form end to end

One `exec` run, repl tool only, no browser tab opened by hand:

```js
await passwordManager.listVaults();                    // [{vaultId, name:"Personal"}]
await passwordManager.listItems({ text: 'nid.naver.com', category: 'login' });
await passwordManager.autofillItem(page, '<itemId>');
```

`listItems` returned nine Naver logins with titles, usernames, and hosts and no
secret values. `autofillItem` filled the form: the snapshot afterwards showed the
ID textbox holding the chosen username and the password textbox holding
`[redacted]`. The agent never saw the password and neither did the transcript.

That is the shape to copy. Search, choose by username or host, autofill, then
re-snapshot to confirm. `autofillItem` returns nothing useful, so the snapshot is
the verification step, not the return value.

## Choosing a route

Every helper call below comes from the dated measurements above. Verify the
helper exists before use. `passwordManager` means exec's repl tool on those builds.

The selected Aside account and the account that owns a suggested credential are
different concepts. Since components 1.26.917.1731, suggestions may include
logins from every unlocked account. Filling, passkeys, one-time codes, and
save-or-update prompts use the credential's owning account without changing the
selected account; a new save goes to the selected account. Therefore discover or
target the selected account independently with `aside account list`, `aside
account status`, or an explicit `--account`. Never infer it from the credential
that autofill chose. Source: [components changelog](https://docs.aside.com/changelog/components).

**Already signed in.** Open the page and read it. Confirm the account rather than
assuming: `googleAccounts.print()` for Google, `await twitter.getMe()` for X, or an
interactive snapshot of the header. Nothing else is needed.

**A vault item matches.** Delegate to exec and let it search and fill:

```js
const items = await passwordManager.listItems({ text: '<host>', category: 'login' });
await passwordManager.autofillItem(page, '<selected-item-id>');
console.log((await snapshot(page, { interactive: true })).tree);
```

Choose by host, title, username, and task context. `autofillItem` returns nothing
useful, so the snapshot is the verification.

**An external provider is locked.** For 1Password the unlock happens on its own
extension page, then you return:

```js
await passwordManager.unlockExternalPasswordManager(page, '1password');
```

The measured providers were `1password`, `bitwarden`, `dashlane`, `lastpass`, and
`proton-pass`. If the provider remains locked or needs a human verification step,
stop with a blocked result; do not change security settings or access policy.

**A passkey prompt.** Usually a fork, not a wall. Look for "Try another way" and a
password or OAuth fallback first; a verified run took exactly that detour and
finished the sign-in on its own. Passkey assertion itself does require a human
gesture, and the OS may demand biometric confirmation at use time (Touch ID on
macOS, Windows Hello on Windows), so treat it as a human step only once no
fallback is offered. Then the user signs in once in the Aside window and `exec`
inherits the live session.

**A TOTP field.** If the provider already filled it, verify and move on. Otherwise
on macOS `applePasswords.getOtps(url)` returns codes once the vault is unlocked.
That call is not a Windows builtin path. Never print a seed or a recovery code.

**A CAPTCHA.** `captcha.click(page, bounds)` for checkboxes,
`captcha.drag(page, from, to)` for sliders, `captcha.readText(page, bounds)` for
text. Verify with a fresh snapshot afterwards.

**Vault or OS verification.** A visible Touch ID, Windows Hello, passkey, MFA,
CAPTCHA, or identity-verification prompt is a human boundary unless the active
surface documents and successfully performs an authorized alternative. Stop and
report the blocked step; do not alter the user's unlock method or policy.

### The measured passwordManager surface

Eight methods were listed by the 2026-08-31 builtin `password-manager` skill:

| method | use |
|---|---|
| `listVaults()` | `{vaultId, name}[]` |
| `listItems({text?, category?, url?, vaultId?})` | search; never returns secrets |
| `autofillItem(page, itemId)` | fills logins, credit cards, identities |
| `unlockExternalPasswordManager(page, provider)` | unlock a connected provider |
| `generatePassword({length?, include?, symbols?})` | returns a ref, not a string |
| `fillPassword(page, fieldRef, passwordRef)` | fill a generated ref during signup |
| `createItem(input)` | store a new credential |
| `updateItem(itemId, patch)` | amend title, urls, fields, notes |

`generatePassword` plus `fillPassword` is how a signup completes without the agent
ever seeing the password. Categories include `login`, `credit-card`, and
`identity`, so checkout forms use the same `autofillItem` path.

That measured `passwordManager` surface had no TOTP method. The dated macOS probe
used `applePasswords.getOtps(url)`; do not assume either fact for a newer runtime.

## The pattern that works

Delegate the sign-in to `exec` with the intended account named in the prompt
(`--account`), and let it report which account it ended up in. An existing live
session skips credential handling entirely. Neither removes later MFA, step-up
verification, expiry, or Vault-policy boundaries; those come back as blockers
for the human.

## Two runs worth learning from

Both were real `aside exec` runs against a live browser on macOS. Account addresses are
masked here; use your own.

### It stopped instead of hanging (2026-08-31 probe)

The task began with "unlock the Apple Passwords vault." The agent planned five
steps, called `requestAuth()`, and met the macOS 6-digit prompt. It then ended the
run in 27 seconds with exit 0:

> "The vault unlock step failed because a 6-digit PIN prompt appeared on macOS
> that I cannot complete myself. I reported exactly what appeared and stopped."

On the build this ran on, without the no-questions clause the agent would have
called `ask_user_question` and the run would have sat silent until the shell
deadline. On 1.26.902 the tool is absent from CLI sessions, so the clause now
prevents a question typed into chat that ends the run unanswered; either way it
converts a dead end into a clean, informative failure.

### It routed around a passkey by itself (2026-08-31 probe)

The task was to sign out of one Google account and sign in with another. Google
presented a passkey prompt, which an agent cannot satisfy. Rather than stopping,
the agent chose **Try another way** and then **Enter your password**, pulled the
saved credential from the password manager, and completed the sign-in. It then
confirmed the new account from the account menu and captured the inbox.

Two lessons. A passkey prompt is often a fork rather than a wall, because most
sites keep a password fallback; instruct the agent to look for one before treating
passkeys as fatal. And the "pick the most reasonable option and continue" half of
the clause is doing real work here: the same sentence that prevents questions also
authorizes the detour. Since 1.26.824 the agent clears the clipboard after copying a
credential, so a run that copied a password leaves nothing behind.

### The file-tool rule held

Asked to save a screenshot under the account root, the agent captured into the
session tmp directory and then moved the file with the `bash` tool rather than
`write_file`. That is the file-tool rule behaving correctly on a path the file
tools should not touch. On Windows that `bash` tool is PowerShell; do not put bash
syntax in it.

### Model selection

The second run used no `-m` flag and picked up the account's configured default.
Omitting the model is the working default; reach for `-m` only when the configured
default is broken.
