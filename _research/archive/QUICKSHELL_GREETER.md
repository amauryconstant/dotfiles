# Surface §23 — the greeter, investigated

**Date**: 2026-09-12
**Purpose**: close the one entry in `_research/QUICKSHELL_SURFACE_INVENTORY.md` whose status reads
*"Not built, no decision recorded"*. This file records the facts; the decision follows them.

**See**: `_research/QUICKSHELL_SURFACE_INVENTORY.md` §23 · `private_dot_config/quickshell/CLAUDE.md`
for the lock screen this would share a visual language with.

---

## Can Quickshell do it? Yes — and it is not `WlSessionLock`

Quickshell vendors a real greetd protocol client. `_ai/quickshell/src/services/greetd/` exposes a
`Quickshell.Services.Greetd` singleton:

| Member | Shape |
|---|---|
| `available` | `bool`, **`CONSTANT`** — whether the greetd socket exists |
| `state` | `GreetdState::Enum` |
| `user` | the currently authenticating user |
| `createSession(user)` · `cancelSession()` · `respond(response)` | invokables |
| `launch(command[, environment[, quit]])` | requires `state == GreetdState.ReadyToLaunch` |
| `authMessage(message, error, responseRequired, echoResponse)` | recoverable prompts and errors |
| `authFailure(message)` | terminal failures — a bad password ends the session |
| `readyToLaunch()` · `launched()` · `error(error)` | |

Three things in that API matter for a design and are easy to get wrong:

1. 🚨 **`error` and `responseRequired` are mutually exclusive on `authMessage`**, and the split
   between `authMessage(error: true)` and `authFailure` is *recoverable vs terminal* — a fingerprint
   reader failing to read is the first, a wrong password is the second. Our lock screen makes the
   opposite assumption for PAM (`lock/LockScreen.qml`: a failure does **not** end the flow, because
   Quickshell starts a fresh PAM session automatically). A greeter cannot reuse that reading:
   `authFailure` means the greetd session is gone and `createSession` must be called again.
2. 🚨 **greetd expects the greeter to exit immediately after `launch()`.** Upstream warns that
   waiting too long "may lead to unexpected behavior such as the greeter restarting", so any
   animation runs *before* the call, never after. That is the inverse of every other surface here,
   where motion communicates the result of an action.
3. **`available` is `CONSTANT`** — it is read once, not bound. A tree that renders both a session
   shell and a greeter cannot flip between them reactively; it is one or the other per process.

This is a different mechanism from `WlSessionLock`, which locks an *existing* session and is used
only by `lock/LockScreen.qml`.

## What logs this machine in today: SDDM

| Fact | Where |
|---|---|
| `sddm` + `solarized-sddm-theme` installed | `.chezmoidata/packages.yaml` |
| Enabled with `sudo systemctl enable sddm.service` | `.chezmoiscripts/run_once_after_006_configure_boot_system.sh.tmpl` |
| Configured — `RememberLastSession`, `RememberLastUser`, `ReuseSession` | same script, `[Users]` block |
| **No `[Autologin]` anywhere** | verified by grep across the tree |
| Hyprland starts from a wayland-session desktop file, then uwsm | same script; `hypr/conf/autostart.conf` notes the session is uwsm-managed, so `hyprland-session.target` is never reached |

`greetd` is not installed and is referenced nowhere in `.chezmoidata/`.

## What Omarchy does: also SDDM, still

Worth stating plainly, because the rest of this repo's Quickshell work follows Omarchy's lead and
here it does not lead anywhere. At **v4.0.3**, having replaced its entire shell with Quickshell in
v4.0.0 — bar, launcher, notifications, OSDs, lock screen and polkit agent — Omarchy still logs in
through SDDM:

- `install/login/all.sh` runs exactly one step, `install/login/sddm.sh`.
- `bin/omarchy-provision-owner` writes `/var/lib/sddm/state.conf` and, on first boot only,
  `/etc/sddm.conf.d/autologin.conf`, then a one-shot unit deletes the drop-in before SDDM next
  reads config — permanent autologin only where LUKS already gates access.
- `greetd` and `seatd` appear **nowhere** in the v4.0.3 tree.

So the project that went furthest with Quickshell as a desktop shell declined the greeter. That is
evidence, not proof — but it is the only prior art available and it points one way.

## What a greeter would cost

- **greetd replaces SDDM**, which means replacing the thing that currently works, on the boot path.
- **The failure mode is total.** A greeter that does not start is a machine with no graphical
  login. Recovery is a TTY and `systemctl enable sddm.service` — fine for someone who knows that,
  and the reason this cannot be a casual change.
- **The session-launch path is ours to rebuild.** SDDM currently picks the wayland-session desktop
  file and uwsm wraps it; a Quickshell greeter calls `launch(command, environment)` and has to
  reproduce that environment itself.
- **It is a second lock screen with a different failure model** — see the `authFailure` note above.
  Shared visual language, genuinely different state machine.

## What it would buy

Honestly: consistency of appearance at one moment of the session, and one fewer theme to maintain
(`solarized-sddm-theme` is per-theme styling outside the `colors.sh` role system). Nothing
functional. SDDM already remembers the last user and session.

## Ruling

**Not built, and now that is a decision rather than an omission.** SDDM stays.

The condition that would reopen it, named so a later reader does not have to re-derive this:
greetd becomes worth it if SDDM's theming drifts out of the colorset system badly enough to need
its own maintenance, **or** if a second machine needs a login surface the eight themes must cover.
Neither is true today. If it reopens, the design shares page 09's language with the lock screen and
must not share its PAM assumptions.
