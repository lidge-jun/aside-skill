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
option along the lines of *Unlock the vault with your biometrics*. Do not enable
it. Biometric unlock requires a live fingerprint at unlock time, which an agent
cannot supply, so turning it on converts a once-per-setup ceremony into a prompt
that blocks every future run. The stored form of this setting is
`biometricUnlockEnabled` in `~/.aside/u/0/passwords/settings.json`; verify it reads
`false`:

```bash
python3 -c "import json;print(json.load(open('$HOME/.aside/u/0/passwords/settings.json'))['biometricUnlockEnabled'])"
```

The PIN path is a one-time setup. The biometric path is a permanent gate.

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

## Passkeys

Passkey assertion is designed to require a human gesture. Even with passkeys
imported into Aside, macOS may demand biometric confirmation at use time, which an
agent cannot satisfy. Treat any passkey-gated site as needing a human present, and
have the user sign in once in the Aside window so `exec` inherits a live session.

## The pattern that works

Sign in once, by hand, in the Aside window. Then delegate. `exec` inheriting a live
session never has to touch a credential, which removes the whole class of prompts
that hang a run.
