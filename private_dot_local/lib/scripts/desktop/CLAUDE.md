# Desktop Scripts - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/desktop/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Hyprland desktop utilities
- **UI Pattern**: notify-send for user feedback (keybinding-triggered)
- **Integration**: Hyprland bindings, theme system
- **Naming**: files are extensionless (`.sh` below is illustrative; actual scripts have no extension, e.g. `theme-apply-firefox`)

## Theme Application Scripts

### Firefox Theme Integration

**Script**: `theme-apply-firefox`
**Method**: CSS symlink injection via userChrome.css
**Status**: ✅ Working

**Manual Requirement** (one-time setup):
1. Open Firefox
2. Navigate to `about:config`
3. Search: `toolkit.legacyUserProfileCustomizations.stylesheets`
4. Set to: `true`
5. Restart Firefox

**How it works**:
- Theme files: `~/.config/themes/{variant}/firefox-userChrome.css` (one per theme)
- Script creates symlink: `~/.mozilla/firefox/{profile}/chrome/userChrome.css` → `~/.config/themes/current/firefox-userChrome.css`
- Firefox restart required to see theme changes
- All theme CSS files exist (Catppuccin, Rose Pine, Gruvbox, Solarized)

**CSS Structure** (per theme ~30 lines):
- Semantic CSS variables (--bg-primary, --fg-primary, --accent-primary, etc.)
- Styles: Tab bar, URL bar, navigation bar, sidebar

---

### Spotify Theme Integration

**Script**: `theme-apply-spotify`
**Method**: spicetify-cli configuration
**Status**: ✅ Fully automated (Flatpak support)

**Automated Setup**: Configured via `run_onchange_after_configure_spicetify.sh.tmpl`
- Detects Flatpak install location (system `/var/lib/flatpak` or user `~/.local/share/flatpak`)
- Sets `spotify_path` automatically
- Detects and sets `prefs_path` (checks both `~/.var/app/com.spotify.Client/config/spotify/prefs` and `~/.config/spotify/prefs`)
- Handles permissions (prompts for sudo if system Flatpak)
- **Installs spicetify marketplace** automatically (CustomApp for browsing themes/extensions)
- Enables marketplace in spicetify config
- Runs `spicetify backup apply` automatically
- Hash-triggered (re-runs if packages.yaml changes)

**Theme Installation** (via marketplace):
1. Open Spotify (marketplace will be in sidebar)
2. Click "Marketplace" tab
3. Browse and install themes:
   - Search for: catppuccin
   - Search for: Rosé-Pine
   - Search for: Gruvbox
   - Search for: Solarized
4. Themes auto-apply via `theme-switcher`

**Troubleshooting**:
- If prefs not found: Run Spotify once to generate preferences file, then re-run `chezmoi apply`
- If permissions fail: Check sudo access for system Flatpak location (`/var/lib/flatpak`)
- After Spotify updates: Re-run `chezmoi apply` to trigger reconfiguration

**How it works**:
- Script reads current theme from `~/.config/themes/current` symlink
- Maps dotfiles theme to spicetify theme + color_scheme:
  - catppuccin-latte → theme: catppuccin, scheme: latte
  - catppuccin-mocha → theme: catppuccin, scheme: mocha
  - rose-pine-dawn → theme: Rosé-Pine, scheme: dawn
  - rose-pine-moon → theme: Rosé-Pine, scheme: moon
  - gruvbox-light → theme: Gruvbox, scheme: light
  - gruvbox-dark → theme: Gruvbox, scheme: dark
  - solarized-light → theme: Solarized, scheme: light
  - solarized-dark → theme: Solarized, scheme: dark
- Runs `spicetify config` + `spicetify apply`
- Changes apply immediately (no restart needed)

---

### opencode Theme Integration

**Script**: `theme-apply-opencode`
**Method**: Custom JSON theme files with symlink management
**Status**: ✅ Fully integrated

**Requirements**:
- opencode installed via mise (v1.0.193+)
- Theme JSON files in each theme directory

**How it works**:
- Script reads current theme from `~/.config/themes/current` symlink
- Verifies theme has `opencode.json` file
- Creates symlink: `~/.config/opencode/themes/current.json` → theme's opencode.json
- Updates `opencode.jsonc` via jaq: Sets `"theme": "current"`
- Silent failure if opencode not installed

**Theme files**: `~/.config/themes/{variant}/opencode.json` (one per theme).

**JSON structure**:
- **defs**: semantic color variables (bg-primary, fg-primary, accent-*, etc.)
- **theme**: opencode properties mapped to those semantic variables
- Supports both light and dark variants via "light"/"dark" keys

**Reload behavior**:
- Theme applies to new opencode sessions only
- Running instances keep old theme (TUI limitation)
- User restarts opencode to see new theme

---

### claude-code CLI Theme Integration

**Script**: `theme-apply-claude-code`
**Method**: Direct JSON config modification
**Status**: ✅ Fully integrated

**Requirements**:
- claude-code CLI installed (global npm package)
- `~/.claude.json` configuration file

**How it works**:
- Script reads current theme from `~/.config/themes/current` symlink
- Maps theme to light/dark mode
- Updates `~/.claude.json` via jaq: Sets `"theme": "light"` or `"theme": "dark"`
- Silent failure if claude-code not installed

**Theme mappings**: `theme-switcher variant "$THEME_NAME"` → `light` / `dark` / `other`.

🚨 **`theme-apply-{gtk,qt,claude-code}` each carried their own copy of that four-slug case arm**
until 2026-09-10, and `theme-menu` a fourth enumeration. They all ask `theme-switcher` now — an
`other` answer skips rather than defaulting into a variant, because a wrong answer here themes
GTK, Qt and Claude Code the wrong way in silence. The darkman `{dark,light}-mode.d` scripts are
deliberately **not** on it: they map a theme to its counterpart, which is a different question.

**Reload behavior**:
- Theme applies to new claude-code sessions only
- Running instances keep old theme (CLI limitation)
- User restarts claude-code to see new theme

---

### Other theme-apply scripts

Same pattern (read `current` symlink → map → apply; silent skip if app absent):
- `theme-apply-gtk` — GTK theme/color-scheme
- `theme-apply-qt` — Qt (qt5ct/qt6ct)
- `theme-apply-neovim` — Neovim colorscheme

---

## Theme Switcher

**Script**: `theme-switcher.tmpl`
**Integration**: Central orchestrator

**Execution flow**:
1. Updates `~/.config/themes/current` symlink
2. Reloads core apps (Hyprland, Waybar, Swaync, Ghostty, Quickshell).
   **Ghostty reloads on SIGUSR2** — undocumented in the man pages, verified on
   1.3.1-arch2 (the binary logs "received SIGUSR2, reloading configuration" and
   survives the signal). Do not read the man page's silence as absence: that
   reading removed the call in 87fe34b5 and broke Ghostty theming.
3. Runs every `theme-apply-*` in this directory (glob loop, not an enumerated list — a new apply
   script wires itself by existing). Each is independent: reads `themes/current`, writes to its
   own app, reads no other's output, so glob order is fine
4. Triggers `theme-change` user hook
5. Updates wallpaper randomly from theme collection
6. Sends desktop notification

**User commands**:
```bash
theme switch catppuccin-mocha    # Switch to specific theme
theme list                        # List all themes
theme current [--slug]            # Show active theme (--slug: directory name)
theme variant [theme]             # dark | light | other — the ONE classifier
theme-menu                        # Interactive menu (Quickshell picker)
```

**Keybindings**:
- `Super+Shift+Y` - Toggle between two themes
- `Super+Shift+Ctrl+Space` - Theme menu

---

## Window Management

**launch-or-focus**: Single-instance app launcher
- Focus if window exists, launch if not
- Integration: `Super+E` → dolphin
- Pattern: `launch-or-focus dolphin` or `launch-or-focus btop "ghostty -e btop"`

**keybindings**: Keybinding reference (`Super+?`)

---

## Display & Monitors

**Scripts**: monitor-switch, monitor-mirror, monitor-*.sh
- Display configuration management
- All use `notify-send` for feedback
- Keybinding-triggered utilities

---

## Appearance & Style

**Bar**: `quickshell-toggle` (bar, launcher, power, notifications, clipboard, overview, popovers)
— the active shell. `waybar-toggle`, `waybar-style` drive the fallback bar.
🚨 `quickshell-toggle` **starts `quickshell.service`**, never a bare `quickshell` — a shell
launched any other way is unsupervised. It clears a spent restart budget (`reset-failed`) first,
because that is exactly the state in which the user has no bar left to ask with
**Restart**: `quickshell-restart` — refuses while the session is locked (see "Idle & Lock")
**Menus**: `quickshell-menu` — the dmenu substrate every `menu-*` script renders through
**Night light**: nightlight-toggle, nightlight-config
**Workspace gaps**: workspace-gaps-toggle, workspace-gaps-reset
**Idle management**: idle-toggle, idle-toggle-nolock (see "Idle & Lock" below)

All use `notify-send` for user feedback.

---

## Other Utilities

**audio-switch**: Audio device switching
**battery-status**: Battery/power status output
**screenrecord**: Screen recording
**system-settings**: Launch system settings
**wlogout**: Logout menu launcher
**window-pop**: toggle a window to/from a floating "pop" state
**zoom-cursor**: cursor magnifier
**voice-meeting**: meeting voice helper
**recover-workspaces**: re-assign orphaned windows to workspaces
**hypr-submap**: enter a Hyprland submap by name. Exists only because voxtype's
`output.*_command` hooks are undocumented on whether they run through a shell, and the Lua
dispatch form survives `sh -c` only if quoted and naive argv splitting only if *not* quoted —
routing through a wrapper keeps the hook a plain whitespace-separated command

🚨 **Every `hyprctl dispatch` in this directory takes the Lua form** (`hl.dsp.*`) since the
2026-09-01 cutover. Lua mode splices the request verbatim into `return hl.dispatch(...)`, so a
legacy string fails with exit 7 — which buys nothing here, because these scripts all write
`2>/dev/null || true`. See `_research/HYPRLAND_LUA_AUDIT.md` for the per-dispatcher argument
shapes; they are **not** in the Hyprland stubs, which type every dispatcher as `fun(...)`.

**Keyboard (Kanata)**: `kanata-layer`, `kanata-layer-toggle` — query/switch layers via the kanata daemon (laptop; see `systemd/user/CLAUDE.md`).

🚨 **A bar's persistent JSON source must guard on its parent still being alive.** `kanata-layer` is
spawned by whichever bar is deployed (Waybar's `exec-persistent`, Quickshell's
`WaybarJsonSource`), and only writes on a state change — so it never takes SIGPIPE when the bar's
read end closes. Quickshell's `Process` destructor
SIGKILLs its direct child, but only on a graceful teardown; a hard-killed or crashed bar leaves
the whole tree behind. Verified live 2026-09-01: **seven orphaned `kanata-layer`** (and five
`voxtype-waybar-status`, since retired with voxtype 1.0) reparented onto `systemd --user`, each
still holding an open kanata TCP connection, accumulating one set per bar restart.

It now captures `$PPID` at start and stops when it goes. The shape follows the blocking point:

- `kanata-layer` blocks inside `nc | while read` for as long as it stays connected, so a
  background watchdog `pkill -P "$MAIN_PID" -x nc`s when the parent dies. It kills `nc` rather
  than the shell on purpose: that unblocks the pipeline, the outer loop re-tests its own
  condition and exits, and the `EXIT` trap reaps the watchdog. A bare `pkill -P "$MAIN_PID"`
  would match the watchdog itself, which is also a child of that shell.

Two traps, both hit while building this and both silent:

🚨 **`kill -0` succeeds on a ZOMBIE**, so a parent left unreaped keeps the guard true forever.
The check is `/proc/<pid>/stat` field 3 instead — state `Z` and a missing file both mean gone.
The `[ -r ... ]` test comes first because a failing redirect prints its own message *before*
`2>/dev/null` is applied.

🚨 **`$PPID` is read AFTER any reparent that already happened.** A spawner that exits in the
same instant — `sh -c 'script &'` — leaves the script holding the REAPER's pid, which in a
systemd user session is `systemd --user`, not pid 1. That parent never dies, so the guard is
disabled for the life of the process, silently. Both scripts therefore refuse to start when
their parent's `comm` is `systemd`/`init`: being spawned by the reaper means already orphaned.
**If either script is ever run as a systemd unit rather than as a bar's stdout source, that
check is the first thing to revisit.**

Testing it needs both shapes: a parent that stays alive and is then killed *and reaped* (the
bar case), and a spawner that exits instantly (the reaper-capture case). A parent that merely
dies without being waited on proves nothing — that is the zombie above.

---

## Idle & Lock

**Daemon**: `hypridle.service` (systemd user unit, `graphical-session.target`) — *not* `exec-once`.
Timeouts live in `.chezmoidata/globals.yaml` (`globals.idle.*`), shared by both configs.

**Three relaxations, composed from two independent switches** — they are not one
three-way mode, and both can be on at once:

| State | Trigger | Mechanism |
|-------|---------|-----------|
| Armed (default) | — | `hypridle.conf` — lock, DPMS off, sleep |
| Presentation | `Super+I` → `idle-toggle` | `systemd-inhibit --what=idle` held by a backgrounded `sleep infinity`, pidfile in `$XDG_RUNTIME_DIR` |
| No-lock | `Super+Shift+I` → `idle-toggle-nolock` | writes `HYPRIDLE_CONF` into `$XDG_RUNTIME_DIR/hypridle-mode.env` (the unit's optional `EnvironmentFile`) → restart |

Because they are independent, clearing one does not necessarily re-arm idle locking;
the toggles say so in their notification text, and the indicator shows presentation
first (it is the stronger relaxation).

**Why two mechanisms**: an idle inhibitor pauses *every* listener, so it cannot express
"displays still power off, but no lock" — that needs a different config. Both mechanisms
live in `$XDG_RUNTIME_DIR` (tmpfs), so neither survives a logout: a fresh session is
always fully armed.

**Never stop the daemon to disable locking.** hypridle holds the logind delay-inhibitor
and answers the `Lock` signal — killing it silently disables lock-before-suspend, so a
lid close suspends the machine unlocked. The inhibitor leaves `before_sleep_cmd` armed.

**`immediate-lock`** is the single lock entry point (`Super+L`, wlogout, system menu, and
hypridle's `lock_cmd`). `grace` is a hyprlock **CLI flag** since 0.9.6, not a config key.

**It has two routes, chosen at RUNTIME**: the Quickshell lock surface (§22) when
`quickshell -c dotfiles ipc call lock lock` answers `ok`, hyprlock otherwise. Runtime rather than
a `.tmpl` branch on purpose — if the shell is down, its restart budget is spent, or its QML tree
will not load, `Super+L` must still lock the screen. ⚠️ `ipc call` **exits 0 even when it fails**,
so the route is decided by the answer, never the status; `missing-pam` falls through too, because
hyprlock reads the same `/etc/pam.d/hyprlock` and will report the real problem in its own UI.

🚨 **Its re-entrancy guard is a `flock`, not `pidof hyprlock`.** `hypr/conf/general` now
sets `misc:allow_session_lock_restore`, so the compositor *accepts* a second locker where it used
to reject one. A check-then-act guard that loses its race therefore displaces a live lock screen
out from under whoever is typing into it. The lock file is `$XDG_RUNTIME_DIR/immediate-lock.lock`;
the descriptor is inherited by the exec'd hyprlock and released only when it exits, so the window
is closed rather than narrowed. Proven by a stand-in run: held → second invocation exits 0
having run nothing; released → it runs.

**`session-locked`** answers whether the compositor holds an `ext-session-lock`, by exit status
only: **0** locked · **1** unlocked · **2** undetermined. Hyprland exposes no lock state, so it
reads `LOCK` out of `solitaryBlockedBy` in `hyprctl -j monitors` — which stays set after the lock's
*client* dies, and that stranded case is the one worth detecting: the session then sits behind the
compositor's failsafe with nothing to authenticate against.

⚠️ **2 is a real third answer, not an error.** Hyprland stops at the first blocking reason, so a
monitor with no workspace yet reports `WORKSPACE` and never reaches the lock — a missing `LOCK`
there means the question was never asked. A caller that branches only on success may treat 2 as
unlocked; a caller that *retries* must not treat it as an answer. Adapted from Omarchy's
`bin/omarchy-hyprland-session-locked`.

🚨 **`session-locked` is NOT "is the lock stranded", and conflating the two displaces a live lock
screen.** It is equally true while hyprlock is running, and `allow_session_lock_restore` means a
second client is now *accepted* rather than refused. Measured 2026-09-12: the Quickshell lock's
recovery ran `session-locked`, got 0 while hypridle's hyprlock was up, concluded orphan, and took
a second lock on top of a live one — the exact failure the `flock` above exists to prevent.

**`session-lock-stranded`** is that question, and the only place that defines it: `session-locked`
says locked **and** the `immediate-lock` lock file is free. **0** stranded · **1** not stranded
(unlocked, *or* a live locker owns it) · **2** undetermined, passed straight through.
⚠️ It answers about lockers **other than the caller** — the Quickshell surface is in-process and
takes no lock file, so a caller that can itself be the locker rules that out first, which is what
`lock/LockScreen.qml`'s `locked || lockRequested` guard does before it ever runs this.

**`quickshell-restart`** is THE restart path for the shell, replacing a bare
`systemctl --user restart quickshell.service`. It asks `ipc call lock status` and refuses while
`secure` or `requested` — restarting a shell that holds the session lock drops the
`ext-session-lock` client while the compositor still holds the lock, so the user waits behind the
failsafe for seconds, self-inflicted. No answer at all means no shell to strand, which is the
recovery case and must proceed. `reset-failed` first, like `quickshell-toggle`.

🚨 **`before_sleep_cmd` must BLOCK until the lock is real, and `loginctl lock-session` does
not.** hypridle holds the logind **delay** inhibitor (`systemd-inhibit --list`: *"Hypridle wants
to delay sleep until it's before_sleep handling is done"*) only until that command returns — and
`lock-session` returns the instant the signal is sent, before hypridle has even run `lock_cmd`.
So the inhibitor was released with nothing drawn, and the machine could suspend with the lock
still on its way. One frame of desktop on resume is the whole failure.

**`lock-before-sleep`** is `before_sleep_cmd` now: `loginctl lock-session`, then poll
`session-locked` until the **compositor** confirms — route-agnostic, so it reads the same whether
the Quickshell surface or hyprlock got there. Budget 4s against logind's `InhibitDelayMaxUSec`
(5s here; read it with `busctl get-property org.freedesktop.login1 /org/freedesktop/login1
org.freedesktop.login1.Manager InhibitDelayMaxUSec`). On timeout it returns anyway — logind is
about to force the suspend, so waiting longer makes the lock later, not surer, and blocking
forever would leave the machine awake with the lid shut. Verified against stubs: 470ms when the
lock lands on the 5th poll, 4378ms when it never does.

⚠️ **No inhibitor of our own.** Omarchy needs `omarchy-sleep-lock.service`
(`systemd-inhibit --what=sleep --mode=delay`) because its shell has no hypridle to borrow one
from. Here hypridle already holds it, so a second holder would be a second thing to keep in step.

**`idle-sleep`** asks logind `CanSuspendThenHibernate` at runtime rather than trusting
`boot.hibernation.enabled` — `suspend-then-hibernate` fails outright where hibernation is
unavailable, leaving the laptop awake and draining. This machine currently answers `"na"`
(no swap, LUKS root), so it takes the suspend path and upgrades itself automatically if
swap is ever configured.

**Hooks**: `lock-change` (`lock`/`unlock`) fires from `on_lock_cmd`/`on_unlock_cmd` — true
authenticated events, in both configs. `idle-change` (`timeout`/`resume`) fires from
listener 1, which only exists in `hypridle.conf` — it goes silent in no-lock mode. And
`resume` fires on *any* input, before authentication; don't treat it as an unlock.

**Waybar**: `custom/idle-indicator` — blank when armed, 󱫖 presentation, 󰍹 no-lock,
󰒲 (`.error`) when the daemon is down. Refreshed by `pkill -RTMIN+9 waybar` on toggle,
plus a 30s interval so an externally-stopped daemon can't leave a stale glyph.

---

## Session Management

**Scripts**: `session-save`, `session-restore`, `session-prompt`, `hypr-session` (CLI wrapper)
**State**: `~/.local/state/dotfiles/hyprland-session-<slot>.json` (+ `hyprdrover` index)

**Save** (`session-save`): captures `hyprctl clients`, enriches each window with a
launch command, terminal CWD (`/proc/<pid>/cwd`), and monitor name. Launch command
resolution order: explicit class map → Flatpak app-ID → `/proc/<pid>/cmdline` argv[0]
(on PATH) → lowercased class. Browser classes are deduped to one window (the app
restores the rest). The full `hyprctl` object is kept, so `initialClass`/`initialTitle`
are persisted for matching.

**Restore** (`session-restore`): launches saved apps, then places each window via the
Hyprland `socket2` event stream (`nc -U`, openbsd-netcat) — correlating each
`openwindow` event to a pending slot (exact `initialTitle` match, else class FIFO by
workspace) and moving it immediately. `post_restore_workspace_fix()` is a **fallback**,
run only for windows the event stream didn't place (or when socket2 is unavailable);
it is pre-seeded with already-placed addresses so it never disturbs correct windows.

**Env vars**: `DOTFILES_SESSION_QUIET=1` (suppress notifications — used by the
autosave timer), `DOTFILES_SESSION_CORR_TIMEOUT` (socket2 correlation budget, default
8s), `DOTFILES_SESSION_LAUNCH_DELAY`, `DOTFILES_SESSION_SETTLE_DELAY`.

**Auto-save**: `session-autosave.timer` (15min) → `autosave` slot. See
`systemd/user/CLAUDE.md`. Config: `~/.config/dotfiles/session-{denylist,browsers,single-instance-apps}.conf`.

**Debug**: `journalctl --user -t hypr-session -f` (both scripts log richly via `logger`).

---

## UI Pattern

**All desktop scripts** use `notify-send` for user feedback (not gum-ui library).

**Rationale**: Keybinding-triggered background utilities, minimal overhead, native notifications.

**See**: `../CLAUDE.md` for UI pattern standards by category.
