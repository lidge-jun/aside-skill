# Credentials and first-run setup

Aside can sign in to sites for you, but the credential layer has a first-run trap
that will hang a CLI run if it is not settled beforehand. Read this before asking
`exec` to log in anywhere.

## The trap

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
way to obtain it, and if the prompt does not forbid questions the agent will call
`ask_user_question` and deadlock the run.

This is not hypothetical. A real run hit exactly this and stopped cleanly only
because the standing clauses forbade questions:

> "The vault unlock step failed because a 6-digit PIN prompt appeared on macOS
> that I cannot complete myself. I reported exactly what appeared and stopped."

## Recommended: use 1Password instead

If the user has a choice, 1Password is the smoother provider for agent-driven
sign-in. It avoids the Apple Passwords first-run PIN handshake entirely, and Aside
ships a builtin `1password` skill that `exec` can load by name.

Aside also supports Bitwarden, Dashlane, LastPass, and Proton Pass, each with its
own builtin skill. Any of them sidesteps the Apple Passwords key ceremony.

## If Apple Passwords is the choice

Two things must be true before any `exec` login task, and both need a human at the
keyboard once.

**1. Complete the one-time 6-digit setup.** In Aside, open Settings, go to the
password manager section, and connect Apple Passwords. Install the Apple Passwords
Importer when prompted. Then trigger the unlock once and enter the 6-digit code
macOS displays. From a terminal you can trigger it with:

```bash
aside repl "console.log(JSON.stringify(await applePasswords.requestAuth()))"
# read the 6-digit code off the macOS prompt, then:
aside repl "await applePasswords.verifyAuth('<6-digit-code>'); console.log('unlocked')"
```

Confirm it worked before delegating anything:

```bash
aside repl "try{const l=await applePasswords.listLogins();console.log('UNLOCKED',l.length)}catch(e){console.log('LOCKED',e.message)}"
```

**2. Leave "Unlock with Touch ID" OFF.** In the Apple Passwords settings there is an
option along the lines of *Unlock the vault with your biometrics*. Keep it
disabled. With it off, the 6-digit PIN you set in step 1 is all the vault needs and
agent-driven sign-in works normally. Turn it on and every unlock demands a live
fingerprint, which an agent cannot supply, so a once-per-setup ceremony becomes a
prompt that blocks every future run.

The stored form is `biometricUnlockEnabled` in
`~/.aside/u/0/passwords/settings.json`. Confirm it reads `false`:

```bash
python3 -c "import json;print(json.load(open('$HOME/.aside/u/0/passwords/settings.json'))['biometricUnlockEnabled'])"
```

PIN is a one-time setup. Biometrics is a permanent gate. Off is the working
configuration.

Also worth checking once: `autoLockTimeout` in the same file is in minutes
(`10080` is a week). A short timeout means the vault re-locks between runs and the
PIN ceremony returns.

## Importer install failure

Connecting Apple Passwords may fail with:

```
EPERM: operation not permitted, open
'~/Library/Containers/at.studio.AsideBrowser.PasswordImporter/Data/.aside/
 apple-credential-exchange-helper-context.json'
```

This is a stale sandbox container left behind by an earlier install, carrying a
`com.apple.quarantine` attribute. Quit Aside completely, move the container out of
the way, then relaunch and press Install so macOS recreates it:

```bash
pgrep -f Aside            # must be empty first
mkdir -p ~/.aside-container-backup
mv ~/Library/Containers/at.studio.AsideBrowser.PasswordImporter ~/.aside-container-backup/
open -a Aside
```

Move rather than delete, so it can be restored. The container holds no
credentials; the real vault is `~/.aside/u/0/passwords/vault.encrypted.db`. This
was verified to fix the EPERM.

## Two credential surfaces

`applePasswords` is available in `aside repl` and is the one that needs the key
ceremony. `passwordManager` is Aside's own native manager, exposed to the **exec
agent only** (it is `undefined` in a CLI repl session), and it never reveals secret
values. The builtin `password-manager` skill documents it; `exec` can load that
skill by name.

Practical consequence: unlock `applePasswords` from repl yourself before
delegating, or let `exec` use `passwordManager` and the provider skills. Do not
ask `exec` to perform the Apple Passwords key ceremony.

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

## Passkeys

Passkey assertion is designed to require a human gesture. Even with passkeys
imported into Aside, macOS may demand biometric confirmation at use time, which an
agent cannot satisfy. Treat any passkey-gated site as needing a human present, and
have the user sign in once in the Aside window so `exec` inherits a live session.

## The pattern that works

Sign in once, by hand, in the Aside window. Then delegate. `exec` inheriting a live
session never has to touch a credential, which removes the whole class of prompts
that hang a run.

## Two runs worth learning from

Both were real `aside exec` runs against a live browser. Account addresses are
masked here; use your own.

### It stopped instead of hanging

The task began with "unlock the Apple Passwords vault." The agent planned five
steps, called `requestAuth()`, and met the macOS 6-digit prompt. It then ended the
run in 27 seconds with exit 0:

> "The vault unlock step failed because a 6-digit PIN prompt appeared on macOS
> that I cannot complete myself. I reported exactly what appeared and stopped."

Without the no-questions clause the agent would have called
`ask_user_question` and the run would have sat silent until the shell timeout.
The clause converted an unrecoverable hang into a clean, informative failure.

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
authorizes the detour.

### The bash rule held

Asked to save a screenshot under `~/.aside/u/0/`, the agent captured into the
session tmp directory and then moved the file with `bash` `cp` rather than
`write_file`. That is the file-tool rule behaving correctly on a path the file
tools should not touch.

### Model selection

The second run used no `-m` flag and picked up the account's configured default.
Omitting the model is the working default; reach for `-m` only when the configured
default is broken.
