# Credentials and first-run setup

Aside can sign in to sites for you, but the credential layer has a first-run trap
that parks a CLI run (or, on 1.26.902, ends it unanswered) if it is not settled
beforehand. Read this before asking `exec` to log in anywhere.

The trap is not the same on both platforms. Windows has no `apple-passwords`
builtin skill. macOS still has Apple Passwords, the PasswordImporter container,
`com.apple.quarantine`, `pgrep`, and `open -a Aside`. Use the section that matches
the OS. The JSON key `biometricUnlockEnabled` is the same on both and was
measured `false` on both; leave it off.

## Windows: passwordManager and the provider skills

On Windows, start with Aside's own `passwordManager` (exec's repl tool only) and
the provider skills that ship in the Windows builtin tree: `1password`,
`bitwarden`, `dashlane`, `lastpass`, `proton-pass`. All five are present on
Windows. None of them needs the Apple Passwords PIN handshake.

If the user has a choice of provider, 1Password is the smoother one for
agent-driven sign-in. Aside ships a builtin `1password` skill that `exec` can
load by name. The other four sidestep a vault-PIN ceremony the same way.

Practical sequence on Windows: the user signs in once in the Aside window, or
`exec` searches the Aside vault / a connected provider and autofills. Do not
ask `exec` to perform an Apple Passwords key ceremony; that skill is not there.

## Leave biometric unlock off

The stored form is `biometricUnlockEnabled` in the account-root passwords
settings file. On macOS that is Touch ID. On Windows it is Windows Hello. The
key name is the same, and it was measured `false` on both (Windows host
2026-09-11, `autoLockTimeout` 10080). Keep it disabled. With it off, a one-time
PIN or provider unlock is all the vault needs. Turning it on re-arms a gate an
agent cannot pass.

The daemon makes the mechanism concrete: `checkPasswordVerificationRequired`
returns false immediately while `biometricUnlockEnabled` is false, and once the
setting is on it re-arms a password re-verification every
`accountPasswordVerificationInterval` days (30 on this account) - a prompt no
non-interactive run can answer. Verified against daemon 1.26.903.1631. Aside
1.26.822 notes that Touch ID is skipped after a passkey dialog, but that is the
OS passkey sheet, not a vault first-run handshake, and no Touch-ID symbol
survives in the daemon bundle, so it stays unverified and the setting stays off.

Confirm it reads `false` with the Aside bundled runtime python, not PATH
`python3`. On Windows, PATH `python3` is the Store stub (exit 49).

```powershell
# Windows / PowerShell (5.1 and 7)
$py = Join-Path $env:USERPROFILE '.aside\runtime\bin\python3.cmd'
$settings = Join-Path $env:USERPROFILE '.aside\u\0\passwords\settings.json'
& $py -c "import json,sys; print(json.load(open(sys.argv[1]))['biometricUnlockEnabled'])" $settings
```

```bash
# Windows / Git Bash
PY="$USERPROFILE/.aside/runtime/bin/python3.cmd"
SETTINGS="$USERPROFILE/.aside/u/0/passwords/settings.json"
"$PY" -c "import json,sys; print(json.load(open(sys.argv[1]))['biometricUnlockEnabled'])" "$SETTINGS"
```

```bash
# macOS / bash
PY="$HOME/.aside/runtime/bin/python3"
SETTINGS="$HOME/.aside/u/0/passwords/settings.json"
"$PY" -c "import json,sys; print(json.load(open(sys.argv[1]))['biometricUnlockEnabled'])" "$SETTINGS"
```

```powershell
# macOS / PowerShell
$py = "$HOME/.aside/runtime/bin/python3"
$settings = "$HOME/.aside/u/0/passwords/settings.json"
& $py -c "import json,sys; print(json.load(open(sys.argv[1]))['biometricUnlockEnabled'])" $settings
```

PIN is a one-time setup. Biometrics is a permanent gate. Off is the working
configuration.

The reasoning behind that instruction, including the daemon predicate it rests on, is in
`devlog/_plan/260903_parity-and-probes/001_probe-remote-and-touchid.md`.

Also worth checking once: `autoLockTimeout` in the same file is in minutes
(`10080` is a week). A short timeout means the vault re-locks between runs and the
PIN ceremony returns.

If you quit Aside to edit that file, relaunch it:

```powershell
# Windows / PowerShell (5.1 and 7)
Start-Process -FilePath 'C:\Program Files\Aside\Application\Aside.exe'
```

```bash
# Windows / Git Bash
"/c/Program Files/Aside/Application/Aside.exe" &
```

```bash
# macOS / bash
open -a Aside
```

```powershell
# macOS / PowerShell
Start-Process -FilePath /usr/bin/open -ArgumentList @('-a','Aside')
```

Do not read `$LASTEXITCODE` after `Start-Process`. A launch does not need
`WaitForExit`; this is not the exec deadline recipe.

## macOS-only: Apple Passwords

Windows has no `apple-passwords` skill. The rest of this section is macOS.

Apple Passwords keeps its own encryption key. Until that key is unlocked in the
current Aside session, every credential read fails:

```
Missing Apple Passwords encryption key.
Call applePasswords.requestAuth(), then applePasswords.verifyAuth(pin).
```

`requestAuth()` returns immediately with an instruction, not a key:

```json
{"status":"auth-requested",
 "instruction":"Ask the user to approve Apple Passwords / Touch ID and provide
                the 6-digit code if macOS shows one, then call
                applePasswords.verifyAuth(pin)"}
```

macOS then shows a **6-digit code that only a human can read off the screen**.
There is no API that returns it. An agent in a non-interactive `exec` run has no
way to obtain it, and if the prompt does not forbid questions the agent asks anyway:
through 1.26.831 that call deadlocked the run, on 1.26.902 the tool is gone and the
question ends the run unanswered.

This is not hypothetical. A real run hit exactly this and stopped cleanly only
because the standing clauses forbade questions:

> "The vault unlock step failed because a 6-digit PIN prompt appeared on macOS
> that I cannot complete myself. I reported exactly what appeared and stopped."

Two things must be true before any `exec` login task on Apple Passwords, and both
need a human at the keyboard once.

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

**2. Leave biometric unlock off**, as in the section above. The Apple Passwords
settings label is along the lines of *Unlock the vault with your biometrics*.

### Importer install failure

Connecting Apple Passwords may fail with:

```
EPERM: operation not permitted, open
'$HOME/Library/Containers/at.studio.AsideBrowser.PasswordImporter/Data/.aside/
 apple-credential-exchange-helper-context.json'
```

This is a stale sandbox container left behind by an earlier install, carrying a
`com.apple.quarantine` attribute. Quit Aside completely, move the container out of
the way, then relaunch and press Install so macOS recreates it:

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

Move rather than delete, so it can be restored. The container holds no
credentials; the real vault is `$HOME/.aside/u/0/passwords/vault.encrypted.db`. This
was verified to fix the EPERM. There is no PasswordImporter container on Windows.

## Two credential surfaces

`applePasswords` is available in `aside repl` on macOS and is the one that needs
the key ceremony. It is not a Windows builtin skill. `passwordManager` is Aside's
own native manager, exposed to the **exec agent only** (it is `undefined` in a CLI
repl session), and it never reveals secret values. The builtin `password-manager`
skill documents it; `exec` can load that skill by name. That surface is the one
Windows has.

Practical consequence: on macOS, unlock `applePasswords` from repl yourself before
delegating, or let `exec` use `passwordManager` and the provider skills. Do not
ask `exec` to perform the Apple Passwords key ceremony. On Windows, skip
`applePasswords` and use `passwordManager` / the provider skills.

### The unlock outlives the session

Worth knowing before you plan around the PIN: `verifyAuth` is not per-session. A
CLI repl called `requestAuth()`, a human read the 6-digit code off the macOS
prompt, and `verifyAuth('<code>')` returned `{"status":"authenticated"}`. Every
later call - new repl processes, and `exec` runs after them - went straight
through with no second prompt. The key is held at the account level, bounded by
`autoLockTimeout`, not by the process that unlocked it.

So the ceremony is genuinely once. Do it by hand, then delegate freely.

`applePasswords.listLogins` takes a `url` and returned `[]` for every site tried,
even with 319 items in the vault. That is the external-provider bridge reporting
nothing, not an empty vault. The vault contents are reachable through
`passwordManager` instead, which is why the surface split matters in practice
rather than only on paper.

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

Every branch below names the surface and the concrete call. `passwordManager` means
exec's repl tool, since it is `undefined` in a CLI repl.

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

Providers are `1password`, `bitwarden`, `dashlane`, `lastpass`, `proton-pass`. If no
saved unlock item exists the call reports so; use the Aside vault rather
than asking.

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

**Biometrics.** Not automatable, ever. Stop and report. Keeping
`biometricUnlockEnabled` false is what stops this from recurring.

### The full passwordManager surface

Eight methods, from Aside's builtin `password-manager` skill:

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

There is no TOTP method here. On macOS, codes come from `applePasswords.getOtps(url)`.

## The pattern that works

Sign in once, by hand, in the Aside window. Then delegate. `exec` inheriting a live
session never has to touch a credential, which removes the whole class of prompts
that park a run.

## Two runs worth learning from

Both were real `aside exec` runs against a live browser on macOS. Account addresses are
masked here; use your own.

### It stopped instead of hanging

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

### It routed around a passkey by itself

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
