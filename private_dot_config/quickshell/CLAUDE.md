# Quickshell Desktop Shell

**Location**: `private_dot_config/quickshell/dotfiles/` → `~/.config/quickshell/dotfiles/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Syntax, tooling, traps**: `.claude/rules/quickshell-qml.md`
**What is left to build**: `_research/QUICKSHELL_SURFACE_INVENTORY.md` (also the reading order for every Quickshell doc)
**What is left to remove**: `_plans/QUICKSHELL_TOOL_RETIREMENT.md`
**How it got here (frozen 2026-09-03, not a roadmap)**: `_plans/archive/QUICKSHELL_SHELL.md`

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Status**: Phases 2, 2.5, 3, 4, 5 and 5.5 complete, then realigned 2026-09-08 against the
  **rewritten fourteen-page design** (`Shell-00-Index` … `Shell-13-Accessibility`; the nine-file
  set every older note cites no longer exists). Floating bar (40 tall, inset 8, reserving 48),
  volume/brightness OSD, launcher, power menu, notification server + centre, and Hyprland on the
  Lua entry point. **2026-09-09**: the shared picker chrome, the dmenu substrate and clipboard
  history. **2026-09-10**: the seven bar popovers (page 06). Page 10's *native nested* menu is
  designed and **not built**. **2026-09-12**: supervision (the shell is a systemd user unit),
  then the two surfaces page 12 had deferred on it — the polkit dialog (§21) and the lock
  screen (§22). Every surface in the fourteen-page design now exists or is a recorded refusal
- 🚨 **It runs as `quickshell.service`, and nothing else may launch it.**
  `desktop/quickshell-restart` is the reload path — it wraps `systemctl --user restart` in a
  refusal while the session lock is live, because restarting then drops the `ext-session-lock`
  client while the compositor still holds the lock; `chezmoi apply` does not reload anything, and
  the file watcher is off in the unit on purpose. `quickshell -c dotfiles kill` is a restart, not
  a stop (`Restart=always`, 2s). Quickshell re-execs itself on a crash *signal*
  (`src/crash/handler.cpp`), so the unit is there for what that cannot reach — `_exit()` on a lost
  Wayland connection, a crash inside 10s of launch, `SIGKILL`, a QML tree that will not load. The
  budget is 5 restarts per 60s, then `failed`; `SUPER+B` (`desktop/quickshell-toggle`) clears it
  and starts again, which is the only route back once the bar, the launcher **and the notification
  daemon** are all gone with it. See `.claude/rules/quickshell-qml.md`
- 🚨 **The shell owns the polkit agent** (`polkit/PolkitDialog.qml`, surface §21, added
  2026-09-12 on top of that supervision — the inventory deferred it until a crash-recovery story
  existed, because a crashed agent leaves the session with NONE and every privileged action then
  fails with no prompt). A session may have exactly one agent and **constructing `PolkitAgent`
  registers it**, so the dialog sits behind `Loader { active: Config.polkitOwned }`, gated on
  `features.quickshell_polkit`. Flipping that off deploys `hypr/conf.d/polkit-gnome.{lua,conf}`
  instead. It is an **interrupt**: no toggle, no IPC target, no keybinding — its visibility is the
  agent's `isActive` and nothing else. Escape cancels, Return submits, Tab cycles identities when
  polkit offers more than one (the branch §21 called out as assumed away)
- 🚨 **The shell draws the lock screen** (`lock/LockScreen.qml` + `lock/LockContent.qml`,
  surface §22, added 2026-09-12), gated on `features.quickshell_lock`. Unlike the two flags above
  **nothing is displaced**: `desktop/immediate-lock` asks the running shell and falls back to
  hyprlock at RUNTIME, so `SUPER+L` locks the screen with the flag off, with the shell down, or
  with its restart budget spent. PAM is `/etc/pam.d/hyprlock`, borrowed from the package — no
  root write and no installer script. The `lock` IPC target is registered either way and answers
  `"disabled"`, so a switched-off feature stays distinguishable from a broken wiring
  — **Background is the WALLPAPER**, read per output from `awww query` and dimmed by
  `Config.lockDimOpacity` (0.7, the knob for legible text over an arbitrary image). Not a blurred
  desktop screenshot, which is what hyprlock drew here (`path = screenshot`, `blur_passes = 3`):
  that puts window shapes and colours in front of whoever is at the machine, and a wallpaper is
  already public. Not flat black either — **black is what the failsafe looks like**, and a lock
  indistinguishable from a crashed one teaches the user to read a real fault as normal
- 🚨 **A stranded lock is recovered; a LIVE one must not be touched.** `ext-session-lock` outlives
  its client, so a shell that restarts while locked comes back holding nothing while the
  compositor still holds the failsafe. `misc:allow_session_lock_restore` lets the fresh client
  re-acquire it, driven by `desktop/session-lock-stranded`. That probe is *two* conditions on
  purpose — the compositor is locked **and** `immediate-lock`'s lock file is free. Asking only
  the first took a second lock on top of a running hyprlock on 2026-09-12, which is the same
  displacement the `flock` was added to prevent
- 🚨 **Colours are SEMANTIC ROLES, all the way down.** `themes/*/colors.sh` was renamed on
  2026-09-09: 18 role keys (`GROUND_*`, `FILL_INERT`, `INK_*`, `SIGNAL_*`, `IDENTITY_1..5`),
  six module-named ones deleted for having no consumer. `Theme.qml` is therefore no longer a
  translation layer — it reads the key of the same name and adds only the **derived** tier.
  `waybar.css`, `wofi.css`, `swaync.css.tmpl` and the rest carry their own variables and were
  never involved. See `.claude/rules/quickshell-qml.md`
- 🚨 **The second ink is OFFERED, not guaranteed.** `Theme.inkSecondary` falls back to
  `inkPrimary` wherever it fails 4.5:1 on `groundBase` — rose-pine-dawn (4.02) and both
  Solarized sets. One derivation instead of hand-editing two palettes; design page 01 states
  the rule, `mise run lint:theme-contrast` prints which themes withdraw it
- 🚨 **BOTH Phase 5.5 surfaces ship OFF**: `Config.dockEnabled` and `Config.overviewEnabled`
  are both `false`. Built, tried in daily use 2026-09-02, and declined — the bar's launcher
  chip and `SUPER+D` already covered launching, and the carousel was not wanted. The dock is
  hidden via `visible:`; the overview sits behind a `Loader` in `shell.qml`, so with the flag
  off there is no window, no screencopy and no carousel bindings at all. Re-enabling the
  overview needs the `SUPER+grave` binding restored to `hypr/conf.d/quickshell.{lua,conf}`
  too — those are plain files, so a single line in them cannot be template-gated. The
  `overview` IPC target stays registered either way and answers `"disabled"`, so a broken
  wiring still looks different from a switched-off feature
- **Gate**: `features.quickshell_shell.enabled`. Flip it + `chezmoi apply` is the whole
  rollout; flipping back is the whole rollback
- **Second gate**: `features.quickshell_notifications.enabled`, for notifications ONLY.
  Separate because it does something the bar flag does not — it takes
  `org.freedesktop.Notifications` from swaync by MASKING the unit
  (`run_onchange_after_configure_notifications`). A bus name has one owner, so this is the one
  phase with no coexistence. Flipping it back unmasks swaync, starts it, and points
  `SUPER+SHIFT+N` back at `swaync-client`
- 🚨 **The two bars are mutually exclusive, by config.** `.chezmoiignore` deploys exactly one
  of `hypr/conf.d/quickshell.{lua,conf}` and `hypr/conf.d/waybar.{lua,conf}`; each drop-in
  carries both its own autostart and `SUPER+B`. `conf/autostart.*` and
  `conf/bindings/desktop-utilities.*` start and bind **no** bar — that is deliberate, not an
  omission
- **Launch**: `quickshell -c dotfiles`, from `hypr/conf.d/quickshell.{lua,conf}`
- 🚨 **`PowerMenu.qml` holds the tree's only `hyprctl dispatch`** (log out). Under the Lua config
  provider it must be `hl.dsp.exit()`, never the legacy `exit` — it was the 30th call site the
  cutover audit had missed, because it postdates that inventory
- **Toggle**: `desktop/quickshell-toggle [bar|launcher|power|notifications|overview|clipboard]`
  — `SUPER+B` (bar), `SUPER+D` (launcher), `SUPER+SHIFT+Q` (power menu), `SUPER+SHIFT+N`
  (notifications), `SUPER+C` (clipboard), `SUPER+grave` (overview). One script for all of them:
  IPC only reaches a *running* instance, so every binding needs the same launch-then-retry dance
- 🚨 **The menu picker is NOT on IPC — it is a SOCKET**, `$XDG_RUNTIME_DIR/quickshell-menu.sock`,
  served by `MenuServer.qml` and called by `desktop/quickshell-menu`. A dmenu call has to BLOCK
  until the user chooses, and an IPC handler returns immediately (and `ipc call` exits 0 even
  for a target that does not exist). One connection is one menu
- 🚨 **The primary keys were taken on 2026-09-01, by gating not shadowing.** Duplicate binds
  *stack* in Hyprland — both would fire — so the Wofi `SUPER+D`
  (`conf/bindings/applications.{conf,lua}.tmpl`) and the wlogout `SUPER+SHIFT+Q`
  (`conf/bindings/system-control.{conf,lua}.tmpl`, renamed to `.tmpl` for this) are wrapped in
  `{{ if not .features.quickshell_shell.enabled }}`. Flip the flag and the old pair comes back.
  **Wofi is now a FALLBACK, not a renderer.** `SUPER+C` was taken the same way on 2026-09-09
  and `SUPER+SHIFT+C` retired (deletion is Shift+Delete inside the surface). It stays installed
  because `quickshell-menu` falls back to it when the shell is unreachable — during first-boot
  setup, and across a shell restart — which is the one thing a blocking picker must never do
- 🚨 **`chezmoi apply` does not reliably reload the running shell.** The log will still say
  *"Configuration Loaded"* while the live generation is the pre-apply one — chezmoi replaces
  files by rename, which a per-file watch does not survive, and the watcher compares content
  rather than mtime so `touch` does nothing either. Finish an apply with
  `quickshell-restart`, and verify with
  `quickshell -c dotfiles ipc show`, never by looking at the deployed files
- **Lint**: `mise run lint:qml` · **Format**: `mise run format:qml`

## Departures from the design, and why

The fourteen-page design is the input, not a specification to apply blindly. Each row below is a
decision; each is also commented at its site. Everything **not** listed here follows the design.

| Design says | Here | Why |
|---|---|---|
| **09** five session tiles, no hibernate | six, hibernate kept | Hibernate does real work on this laptop, and the design's own rule — *a control that would do nothing is removed* — endorses keeping one that works |
| **09** nothing pre-selected | Lock pre-selected | Already safe: an accidental Return locks, which is recoverable. It is also wlogout's model, which this menu replaced without smuggling in a behaviour change |
| **09** 88px tiles | 124px | 88 was drawn for a five-tile row; we have six. Cosmetic, no defect |
| **08** OSD fill on `fillInert` over a `groundRaised` track | fill `signalFocus`, track `groundRaised` | The design's pair measures ≈**1.3:1**, under its own 3:1 graphic floor |
| **01** `inkOnSignal` is a fixed binding | computed | Pages 04 and 07 call it computed; the computation's result is provably ≥ the fixed binding in every theme |
| **07** timestamp in `inkSecondary` | `inkPrimary` | Page 01's tier table binds `groundFloat` as carrying the primary ink only. Foundation beats surface |
| **02** three density columns | default 13 only | The only thing that could select a column is the system menu, which is not built. Two unreachable columns are dead configuration |
| **04** a named width-breakpoint overflow order | **not built** | No output this repo drives is narrow enough to fire it, so it could be neither observed nor tested. The parts that *do* fire are built: the title's pixel bound and the tray's 8-item cap. See the ponytail note in `Config.qml.tmpl` |
| **07** inline reply | not built | Needs `x-kde-reply` plumbing; out of the agreed scope |
| **12** the lock returns when "the lock process can be supervised independently of the rest of the shell" | in-shell, recovered rather than isolated | Hyprland's failsafe is **opaque**, so a crashed locker is ugly and never insecure. `Restart=always` plus `allow_session_lock_restore` plus `session-lock-stranded` turns that into ~2s of failsafe and then a prompt, and hyprlock stays as the runtime fallback for a shell that cannot come back at all. A second always-running instance buys isolation the failure mode does not need |
| **12** the lock draws nothing behind its content | the dimmed wallpaper | The page's own mock is a near-black card, which is also exactly what Hyprland's failsafe renders — so the drawn design makes a crashed locker and a working one look alike. The wallpaper is public, costs one `awww query`, and leaks nothing the page forbids |
| **12** the lock's failure line in `signal-error` | `fgOnScrim` | Measured on the scrim: 3.87 (latte), 3.84 (gruvbox-light), under the 4.5 text owes. Page 12 requires the colour be "paired with words, never colour alone", so the words carry it. Row in `lint:theme-contrast` |
| **12** the date drawn at 12px, called "meta" in the prose | `fontMeta` (11) | The prose names the role; page 02 is what fixes what a role is worth. A surface page contradicting a foundation page is a defect in the design |
| — | dock and overview kept, dormant and untouched | Neither has a page in the new set; both already `false` and declined in daily use |

Rulings, contradictions and every measurement behind these: `_research/QUICKSHELL_DESIGN_AUDIT.md`
Part 5.

## Layout

```
dotfiles/
├── shell.qml              # ShellRoot: IPC handlers + Variants over screens + the OSD
├── qmldir                 # declares the six singletons (required by qmllint)
├── Theme.qml              # semantic roles + derived materials, from colors.sh at runtime
├── Config.qml.tmpl        # geometry, type, motion, fonts, chassis, scriptsDir, glyph ramps
├── Backlight.qml          # sysfs backlight, shared by the bar widget and the OSD
├── Meters.qml             # CPU + memory from /proc, for the bar's one load readout
├── Notifications.qml      # NotificationServer + DND + popups + grouping + restart persistence
├── MenuServer.qml         # the dmenu SOCKET — one connection is one blocking menu call
├── osd/Osd.qml            # volume + brightness overlay, follows the focused monitor
├── launcher/
│   ├── PickerSurface.qml  # the chrome all three list surfaces share (see below)
│   └── Launcher.qml       # app launcher + `:` run and `=` calc (design page 05)
├── menu/MenuPicker.qml    # what every `show_menu` call in this repo now draws
├── clipboard/ClipboardPicker.qml  # cliphist history (design page 11)
├── polkit/PolkitDialog.qml        # the authentication dialog (design page 12) — an INTERRUPT
├── lock/
│   ├── LockScreen.qml     # WlSessionLock, PAM, stranded-lock recovery — draws nothing
│   └── LockContent.qml    # clock, date, one field, one line (design page 12)
├── power/PowerMenu.qml    # power / session menu (design page 09)
├── dock/Dock.qml          # auto-hiding dock, one PER SCREEN — DORMANT, no page in the current design
├── overview/
│   ├── Overview.qml       # workspace carousel — DORMANT, no page in the current design
│   └── WorkspaceCard.qml  # one card, used at all three carousel scales
├── notifications/
│   ├── NotificationCard.qml     # THE card — shared by the centre and the popups
│   ├── NotificationPopups.qml   # toast stack, one window PER SCREEN
│   └── NotificationCentre.qml   # the 340-wide panel (design page 07)
├── bar/popovers/*.qml     # the seven payloads — one per bar widget that owns one
└── bar/
    ├── BarPopover.qml     # the shared popover chrome: header, body slot, footer, anchoring, grabs
    ├── PopoverRow.qml     # the 34 row shared by every list-shaped payload
    ├── PopoverSlider.qml  # the only control in the shell that takes both drag and the wheel
    ├── Bar.qml            # PanelWindow, one per screen, three zones, grouped right side
    ├── BarWidget.qml      # the chip, the accent rule, tooltip, click/scroll plumbing
    ├── BarTooltip.qml     # PopupWindow hover tooltip
    ├── BarSeparator.qml   # 1x16 hairline, hides with the group it precedes
    ├── WaybarJsonSource.qml  # Process + SplitParser for Waybar-JSON scripts
    └── widgets/*.qml      # one per bar widget
```

`shell.qml` owns no widget. Widgets are added to a zone in `Bar.qml`, in
`waybar/config.tmpl`'s `modules-right` order, inside one of the six separator-delimited
groups (tray · network+bluetooth · backlight+battery · audio+media · kanata+idle+voxtype ·
notification).

A widget sets `icon`, `label` and — only for a real state — `iconColor` on `BarWidget`. It
does **not** declare its own `Text`, write a radius, or pick a rest colour: geometry and the
accent rule both live one level up. See `.claude/rules/quickshell-qml.md`.

## The three list surfaces — `launcher/PickerSurface.qml`

Design page 11 says the clipboard is *"deliberately the launcher's shape, because it is the same
interaction and a second layout would be a second thing to learn"*. So there is one chrome —
window, scrim-dismiss, panel, header with query field and counter, scrolling list, footer,
keyboard model — and three consumers: `Launcher`, `MenuPicker`, `ClipboardPicker`.

🚨 **Consumers supply DATA, not a delegate.** A `property Component delegate` does not survive
qmllint: it cannot know the component is a delegate, so the `index`/`modelData` required
properties that `pragma ComponentBehavior: Bound` forces read as unsatisfiable, and **every use
site fails the build** — including `shell.qml`, which is where the error surfaces rather than in
the file that caused it. The three row shapes were the same shape anyway, so one built-in
delegate reads a small row contract:

| Field | Effect |
|---|---|
| `title` | required |
| `subtitle` | its absence is what makes a row `rowH` 34 instead of `launcherRowHeight` 48 — page 10's menu row and page 05's launcher row, decided by the data |
| `glyph` / `iconSource` | leading glyph, or a themed icon which wins over it |
| `mono` | title in `terminalFont` — content that will be pasted verbatim |
| `elideMiddle` | for a path, whose identifying half is its tail |
| `subtitleError` | subtitle in `signalError`, for a failure reported in place |
| `badge` | short right-aligned meta text. **One trailing slot**: the `↵` mark takes it over while the row is selected, so a badge and the mark can never collide, and the title column has one thing to anchor against |
| `glyphColor` / `glyphBackground` | the glyph in a colour the ROW supplies, on a round ground of its own. The one place a non-`Theme` colour is drawn in this tree: a theme-picker row is a **sample of another palette**, so the colour is content. Ignored when `iconSource` is set, and the ground carries a `Theme.edge` hairline or a light sample vanishes on a light panel |
| `header` | a section label instead of a row — `menuSectionHeight` 24, no tint, no hit target, and `moveSelection` steps straight over it. A section is a ROW, not a parallel list: a separate model would need re-indexing against the filtered rows on every keystroke |

🚨 **A `current` marker belongs in `badge`, never in a `subtitle`.** A subtitle is what decides
row height, so marking one row that way makes it 48 against its neighbours' 34 and the list steps.

**Esc is configurable**: `escapeClears` (default true) is the launcher's two-step Esc. `MenuPicker`
sets it false — there the query is incidental and Esc means the blocked caller gets nothing.

**Shift+Delete, not Delete**, for `removed`. The query field always holds focus, so a bare Delete
mid-query would destroy a row while the user meant to edit text. Page 11 draws "del"; this is one
modifier further and the footer says so.

## The dmenu substrate — `MenuServer.qml` + `desktop/quickshell-menu`

Twenty-two scripts in this repo ask the user to pick from a list. Sixteen route through
`show_menu()` in `user-interface/menu-helpers.sh`; the rest called `wofi --dmenu` directly. All of
them now reach the shell.

🚨 **A socket, not IPC.** A dmenu call is request/response and **blocking** — the script must not
return until the user has chosen. `quickshell ipc call` cannot do that: a handler returns
immediately, and `ipc call` exits 0 even when the target does not exist, so a caller could not
even tell. `SocketServer` gives blocking, cancellation, concurrent callers and a clean
"shell is down" signal for free. Protocol is one line each way: `{"prompt":…,"items":[…]}` in, the
chosen item out, nothing at all on cancel.

Four things that each broke it once, all now load-bearing in the wrapper:

| Trap | What happens |
|---|---|
| `nc -N` | half-closes the write side; QLocalSocket has **no half-close**, so Qt reports `PeerClosedError` and drops the connection before the shell can answer. Every call returned empty |
| `$(…)` strips the trailing newline | `SplitParser` emits nothing without one, so the request is never parsed and nc waits **forever** — there is no timeout in this path |
| `[ -S "$socket" ]` as the reachability test | a killed shell leaves its socket file behind (quickshell deletes a stale one only when it next starts, `socket.cpp:170`), so the file test passes against a dead shell and the caller reads the empty answer as a cancellation. Test the **connection**: nc's exit status |
| a second request while one is open | refused immediately rather than queued. A menu that appears minutes later, attached to a script that has moved on, is worse than a refusal |

**With nothing matching, Return answers with the TYPED TEXT.** That is dmenu's contract, not a
nicety: `menu-install` asks for a package name by handing the picker an empty list.

### Rich items — `quickshell-menu --json`

An item may be an **object** instead of a string, which is how a caller reaches the row contract
above rather than packing glyph, state and payload into one label:

```json
{"prompt": "Select Theme", "items": [
  {"header": true, "title": "LIGHT"},
  {"title": "Rose Pine Dawn", "badge": "current", "payload": "rose-pine-dawn",
   "glyph": "", "iconSource": "file:///home/…/themes/rose-pine-dawn/icon.png"}]}
```

`iconSource` is any URL `QtQuick.Image` accepts and **wins over `glyph`**, which stays the
fallback for a missing file and for the Wofi path, where no image can be drawn at all.
`theme-menu` uses it for the per-theme brand marks vendored in `themes/<name>/icon.png` — see
`themes/CLAUDE.md` for their provenance.

`MenuServer.normalise()` turns both shapes into one row: a plain string becomes
`{title: s, payload: s}`, so the sixteen `show_menu()` callers, their `case` statements and
`menu-install`'s empty-list free-text prompt are all untouched.

🚨 **`payload` is what the caller is answered with, and it is NOT in the search haystack** —
`MenuPicker` matches on `title` and `subtitle` only. That is the whole point: before this,
`theme-menu` shipped its slug through the picker as a visible `|rose-pine-dawn` suffix that the
user read and the fuzzy match hit.

The Wofi fallback flattens what it cannot draw: headers dropped, glyph pasted back in front of
the title, payload recovered afterwards by exact display text. `theme-menu` is the only caller
using the JSON form today.

## Clipboard — `clipboard/ClipboardPicker.qml`

**Fronts `cliphist`; does not replace it.** `media/clipboard-store` is a four-layer secret filter
(password-manager windows, browser auth pages, terminal `ssh`/`sudo`/`gpg`/`pass` titles, then a
`gitleaks stdin` scan) already wired to `wl-paste --watch`. That is page 11's sensitive-source
policy, implemented better than the page states it.

Return copies and closes; it **never pastes** — a shell that synthesises keystrokes into whatever
happens to be focused will eventually type into the wrong window. Two departures from page 11,
both forced by what cliphist stores: no age and no source application (it records neither, and
inventing "2m · Neovim" would be a lie in `inkSecondary`), and no thumbnail yet — the dimensions
and format cliphist already prints in its `[[ binary data … ]]` preview are what tell two
screenshots apart.

## Popovers (design page 06)

Seven payloads on one chrome: **audio, network, bluetooth, calendar, media, meters, power**,
each anchored under the bar widget that owns it. They are what removed the last four
shell-outs from the bar — `pavucontrol`, `nmtui`, `blueman-manager` and `btop` all moved from
the click to the footer, where the design puts the "escape hatch".

🚨 **`grabFocus` cannot be used.** `PopupWindow.grabFocus` makes Qt request an *xdg_popup* grab,
and a popup whose parent is a **layer-shell** window cannot be one. Measured 2026-09-10:

```
WARN qt.qpa.wayland: Failed to create grabbing popup. Ensure popup has a transientParent set
                     and that parent window has received input.
WARN: Cannot attach popup ... as the popup is not an xdg_popup.
```

and the popup sets itself back to invisible. So the click-outside dismissal that flag exists for
is simply unavailable here, and the design's two open modes are built from what is:

| Mode | Grab | Close signal | Ring |
|---|---|---|---|
| **Pointer** (a click on the widget) | none — the keyboard stays with the application, which is exactly what page 03 demands | losing the pointer, with `Config.popHideDelayMs` (260) of slack for the crossing | no |
| **Keyboard** (the `popovers` submap) | `HyprlandFocusGrab`, verified to deliver keys to a focused `Item` and to signal `cleared` on an outside click | Esc, `cleared`, or the same key again | yes |

The keyboard grab **takes the keyboard from the focused application** for as long as it is up.
That is the trap page 03 describes, and it is why the ring is mandatory in that mode and absent
in the other.

🚨 **`anchor.updateAnchor()` on every open.** The anchor rect is computed only when a popup is
*first* shown and does not follow its item (`popupanchor.hpp`). Bar widgets move — the window
title changes width, a workspace appears — so without it a reopened popover lands where its
widget used to be.

🚨 **`signal closed` is taken.** `PopupWindow` already carries one, and overriding it is a
*runtime* warning (`Duplicate signal name: invalid override`) that qmllint does not report. The
chrome's is `dismissed`.

**The coordinator is one string on `Bar`.** A `Bar` is created per screen by the `Variants` in
`shell.qml`, so `openPopover` is per-output for free: two screens may each show one, and an
output vanishing takes its bar, its popovers and its coordinator with it. `Bar.togglePopover(id,
keyboard)` closes whatever is open before opening the next.

**Widgets raise, `Bar` decides.** Each of the seven declares `popoverRequested` and `Bar` relays
it — the same shape `LauncherWidget` and `NotificationWidget` already had. `Bar` also binds
`popoverOpen` back onto the widget, which keeps its chip lit and **suppresses its tooltip**: a
tooltip hanging over the popover it opened describes the widget twice and covers the payload.

🚨 **The ↵ mark follows the CURSOR, not `selected`.** `PopoverRow` means something different by
`selected` than the launcher does: *this is the current device / the active route*, which Return
would not change. A ↵ on a row that does nothing is a lie about the key.

Departures from page 06, each measured:

| Design | Here | Why |
|---|---|---|
| Slider fill `fill-inert` on a `ground-raised` track — "the one legal use of that tier" | fill `signalFocus` | The pair measures **1.15–1.3** (worst rose-pine-dawn) against page 13's own 3:1 graphic floor. Same ruling the OSD already took; both pairs are lint rows |
| Thumb hairline `accent-border` | `Theme.edge` | That key was deleted from all 8 colorsets on 2026-09-09 for having no consumer, and page 13 lists it as *compositor decoration measured only so nobody re-adopts it* |
| Meters payload includes temperature | CPU, memory, uptime | `Meters.qml` records it: a temperature is not a percentage until someone names the hwmon path and the threshold it is a percentage OF |
| Power payload includes a profile control | absent | `power-profiles-daemon` is not installed, and `PowerProfiles.profile` answers "Balanced" anyway with no daemon — the row would state a profile that is not real. Page 03: a control that would do nothing is removed |
| Meter fill takes the warn/error ramp | the band is a **word** (`warn` / `critical`), the fill goes `signalError` only at critical | `signalWarn` is 2.05 in rose-pine-dawn and banned as a graphic here; a band nobody can see is not a band |

**Escape hatches**, all clickable, all closing the popover: `pavucontrol` (added to
`packages.yaml` — it was never installed, so `AudioWidget`'s old click did nothing),
`nm-connection-editor` (replacing `nmtui` in a terminal), `blueman`, `btop`, `battery-status`.
The calendar's footer carries today's date instead, because it launches nothing.

**Keyboard**: `SUPER+P` enters the `popovers` submap in `hypr/conf.d/quickshell.{lua,conf}`;
`a n b c m e w` pick audio / network / bluetooth / calendar / media / meters / power, Esc leaves.
One top-level key rather than seven, and every key goes through
`quickshell-toggle popover <id>` for the same reason every other binding does: IPC only reaches a
running instance.

## Widget → source

| Widget | Backed by |
|---|---|
| Launcher | none — a chip that raises `launcherRequested`; `shell.qml` owns the window |
| Workspaces, WindowTitle | `Quickshell.Hyprland` |
| Audio, Media, Tray | `Pipewire`, `Mpris`, `SystemTray` |
| Network, Bluetooth, Battery | `Networking`, `Bluetooth`, `UPower` — laptop only |
| Backlight | the `Backlight` singleton (sysfs via `FileView`), writes through `desktop/brightness-set` — laptop only |
| Meters | the `Meters` singleton (`/proc/stat` + `/proc/meminfo` via `FileView` on a 2s timer) — **new**, Waybar had no cpu/memory module here |
| Kanata, Voxtype, Idle | existing scripts, via `WaybarJsonSource` |
| Notification | the `Notifications` singleton — Phase 4 cut the last `swaync-client` call out of the tree |

## OSD (Phase 3)

`osd/Osd.qml`, one window, instantiated once in `shell.qml`. **Nothing triggers it** — no
keybinding, no IPC, no script change: it watches `Pipewire.defaultAudioSink` and the
`Backlight` singleton, so it fires whatever changed the value (media key, bar scroll, another
app). Three things in it are load-bearing:

- `mask: Region {}` — an empty input region. Without it the window eats every click in its
  200×96 patch while up, and it has nothing interactive to justify that
- an `armed` flag on a 1s timer — Pipewire's first binding and the first sysfs read both land
  after launch and would flash the OSD on every login
- `screen:` matched by **name** against `Hyprland.focusedMonitor` — `HyprlandMonitor` has no
  `screen` property; both sides expose `name`

**Fixed 200 × 96** (was 320 × 56): a readout that resizes as the number crosses 100 draws the eye
to the wrong thing. A 28px glyph beside a 20px number, over a 152 × 6 track. The number carries
**no percent sign** — the bar under it already says what the scale is — and it is **not clamped**
at 100 while the bar is, because clamping the number would hide a real state. There is **no
fade-in**, only a `motionSlow` fade-out: a readout you have to wait for has already failed.

🚨 **The fill stays `signalFocus` on a `groundRaised` track**, against design page 08, which puts
the fill on `fillInert` over `groundRaised`. That pair measures about **1.3:1** in Mocha — the
design contradicts its own 3:1 graphic floor there. Both candidate pairs are rows in
`lint:theme-contrast` so the comparison is on record.

Sits at `Config.osdMargin` (160) from the bottom, clearing voxtype's own OSD (a 72-tall card
at bottomMargin 72) so a dictation card and a volume key cannot overlap. On a desktop with a
DDC monitor there is no sysfs backlight, so the brightness half simply never fires.

**Two scripts are reused, not ported**: `kanata-layer` and `idle-indicator` already emit Waybar's
custom-module JSON. Voxtype reads `voxtype status --follow --format json` directly — the
`voxtype-waybar-status` wrapper it used went with voxtype 1.0's on-demand loading.
(`swaync-client -swb` was a third until Phase 4; the bell now reads an in-process singleton.)

## Launcher and power menu (Phase 5)

Two `PanelWindow`s in `shell.qml`, each a **single window that follows the focused monitor**
(same name-matching as the OSD) rather than one per screen: a modal you summoned belongs where
you are looking.

Both differ from every other window in this tree on two points:

- `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` — they must receive keys the
  instant they map, without a click first. The bar and the OSD are both `None`
- **no `mask`** — the opposite of the OSD's `mask: Region {}`. These *want* the whole surface,
  so a click anywhere outside the panel dismisses them

`toggle()` returns the state actually reached (`"shown"`/`"hidden"`), the same contract
`bar.toggle()` has, so `quickshell-toggle` can report what happened rather than what was asked.

**The bar's launcher chip does not shell out.** It raises `launcherRequested` on
`LauncherWidget`, relayed by `Bar.qml` to `shell.qml`, which owns the window. Going out through
`quickshell-toggle` would spawn a process for the shell to talk to itself.

### Launcher

`DesktopEntries.applications` + `TextInput` + a ranking function compressed from Omarchy's
`services/AppSearch.js` (prefix > substring > keyword/comment > acronym). `entry.execute()`
launches. Icons are `IconImage` on `Quickshell.iconPath(icon, true)`, falling back to
`Config.windowGlyphFallback` when the theme has none — same contract the workspace pills have.

**340 wide** (was 760), with popover chrome: a hairline-separated header carrying the glyph, the
query, an accent caret and a right-aligned match count, and a permanent footer carrying the keys
on the left and the prefix hint on the right.

**Three modes.** Apps, plus `:` **run in a terminal** (`Config.terminal`, from `globals.yaml`) and
`=` **calculate** through `qalc` — Return copies the result and launches nothing. `libqalculate`
is in `packages.yaml` for exactly this; without it the mode reports nothing rather than pretending
to work. The five-prefix set an older mockup drew (`>` `:` emoji, `/` files, `?` help) is not
built, and neither is the web-search fallback row.

🚨 **Esc CLEARS the query; a second Esc closes.** The one surface where Esc is not a single-step
close. The function is `clearOrClose()` and **must not** be called `escape()` — that is an illegal
method name in QML and the engine rejects the whole file at load time, which qmllint does not
catch.

**Zero matches** is two lines, never one: the fact in `inkPrimary`, the exit in `inkSecondary`,
and the list area keeps its height so the surface does not jump as the query narrows.

**There is no "Starting…" state.** `DesktopEntry.execute()` reports nothing on success and gives
no completion signal, so a spinner or a fixed delay would be theatre. A spawn that *throws* is
real: the row keeps the failure text, its siblings go inert at `Theme.disabledOpacity`, and the
launcher refuses to close — the one place Return does not dismiss it.

### Power menu

A front-end over the **exact** commands `wlogout/layout` ran, `session-save` included. Two
deliberate departures from design page 09:

- **Six tiles, not five.** Hibernate exists here and does real work on the laptop. Same rule
  the bar's eleven widgets follow: do not delete a function to match the drawing
- **wlogout's mnemonics** (`l u e h r s`), not the canvas's `l s e r p` — muscle memory, and
  the canvas's set collides on `s`

🚨 **It keeps wlogout's activation model: one activation fires, no confirmation step**, because
the wrapper it replaces has none. Adding one would be a behaviour change smuggled in as a
redesign. What protects you is the *selection*: Lock is selected on open, so Return alone can
never power anything off. Design page 09 asks for **nothing** pre-selected; ours is already safe
and is the model this menu was written to replace without smuggling in a behaviour change.

🚨 **The tiles ground on `groundBase`, not `groundRaised`.** The power-off tile draws
`signalError` as a glyph and a border, and that pair measures **2.81** on `groundRaised` in
solarized-dark — under the 3:1 a graphic owes. On `groundBase` it is 3.25 at worst and clears
everywhere. The tiles sit on the scrim anyway, so the raised tier bought nothing.

🚨 **The scrim is `Theme.scrim`, never a background token.** It was `groundBase` at 86%, which is
the documented defect one tier over: that token measures 0.71–0.96 luminance in all four light
colorsets, so the wash rendered near-white. Everything drawn directly on the scrim — the identity
line, the mnemonic row — takes `Theme.fgOnScrim`.

## Dock and workspace overview (Phase 5.5)

Both optional, both genuinely new — nothing here did either job, and Omarchy has no dock to
read from. 🚨 **Both are DORMANT and have no page in the current design set**, so nothing below
was realigned on 2026-09-08 — they still use the token names the rest of the tree moved off,
via the mechanical rename only. Four things the now-deleted `Composites` artboards settled that
the plan's prose transcription had wrong or missing; see Amendment E.

### Dock — `dock/Dock.qml`

One per screen, like the bar and unlike every modal here: a dock is furniture, not something
you summon. Geometry was measured off the old `comp-a` artboard and sits **outside** the scale
(`Config.dock*`), the same way `powerTileRadius` does — the dock is a peer of the bar, not
something nested in it. Amendment A's transcription had the padding (14, not `padTight`), the
tile radius (12, not `radiusTile`) and the gap (10, not `gap`) all wrong.

🚨 **Three input traps, all silent:**

- `exclusiveZone: 0` and a **`mask`**. An unmasked layer-shell window swallows every click over
  its whole surface — the dock would eat clicks along the bottom of every screen, permanently.
- Hover comes from a **`HoverHandler`**, not a `MouseArea`. A `MouseArea` only reports hover
  while nothing above it has it, so each tile's own `MouseArea` stole it and the dock retracted
  out from under the click. `z: -1` does not help — stacking picks the winner, not the
  observers.
- The revealed mask is the **union of the hot edge and the panel's live rect**, with the hot
  edge growing to meet the panel and staying full-width. A single rect fails three ways: bound
  to the panel alone it lags the slide, pinned static and centred it misses an off-centre
  entry, and left short of the panel it leaves a seam to cross.

Plus a `Config.dockHideDelayMs` grace period, so a momentary hover loss cannot retract it.

**The running-indicator dot is kept against the artboard**, which drew none. A static mockup
of one moment is weak evidence that a *state* indicator does not exist, Amendment A specifies
it, and without it the dock is a strictly worse `SUPER+D`. Running → `workspace.activate()`;
not running → `entry.execute()`.

`Config.dockApps` holds **desktop-entry ids**, deliberately not interpolated from
`globals.yaml` `applications`: that file holds binary and MIME names, so `ghostty` and
`org.xfce.thunar` would both resolve to null. `DesktopEntries.heuristicLookup()` does not close
the gap either — it falls back to `StartupWMClass`, which is `com.mitchellh.ghostty` for the
one and absent for the other.

### Overview — `overview/Overview.qml`

Structurally the launcher again: focused monitor, `WlrKeyboardFocus.Exclusive`, no mask,
click-out dismisses, `toggle()` returning the state reached.

**Windows are live `ScreencopyView` captures**, falling back to the app glyph and title when
there is no content. Phase 5.5 first shipped *without* them, on the reading that the artboard
draws chrome rather than screenshots — which read the mockup right and the requirement wrong.

🚨 Two silent conditions: the view must sit in a **rendered** window or no recording context is
created, and `captureFrame()` from `Component.onCompleted` is too early. `live: true` avoids
the timing, scoped to an explicit `active` property — a window's `visible` does **not** reach
its content item, so binding capture to `root.visible` would capture forever.

Hyprland does capture windows on **inactive** workspaces over `hyprland-toplevel-export-v1`,
verified — which is what makes a workspace overview possible at all.

🚨 **The projection divides by `monitor.scale` first.** `HyprlandMonitor.width`/`height` are
copied verbatim from the `hyprctl monitors` JSON (`ipc/monitor.cpp:41`), so they are
**physical** pixels while window `at`/`size` are **logical**. Missed, a scale-1.25 display
draws every window 25% oversized — and a scale-1 laptop hides it completely.

Cards take the **monitor's** aspect, not the artboard's: the old `comp-b` drew three aspect
ratios (0.81 / 0.68 / 0.59), none of which is a screen, so its cards cannot host a truthful
layout. The note's falloff curve carries over unchanged (scale 1.0 / 0.69 / 0.46, opacity
1 / .6 / .35).

**Two drawn behaviours are out, both because they need a raw `Hyprland.dispatch()`** — exactly
what the Phase 2 cutover removed: dragging a window between workspaces (there is no
`toplevel` move invokable at all) and the dashed "+" card that creates a workspace.

A slot's height comes from the **monitor**, never from the carousel `Row`: sizing a child off
the positioner that sizes itself from its children is a binding loop.

🚨 **The scrim is `Theme.scrim`, a shade rather than a token**, because `GROUND_FLOAT` is
0.71–0.96 luminance in every light theme and an 86% scrim over it renders near-white. Anything
drawn on it then needs `Theme.fgOnScrim`: the scrim is dark in all 8 themes, so a light theme's
own `fgPrimary` measures 1.81 there.

## Notifications (Phase 4)

`Notifications.qml` owns the server; `notifications/` draws it. The centre is the launcher and
power menu again structurally — focused monitor, exclusive keyboard focus, no mask, click-out
dismisses — but anchored top-right under the bar rather than centred, where the toasts it
archives were.

**The popups are the exception to "one window that follows the focus"**: one per screen. A
notification arrives on its own schedule, so "wherever you were looking when it fired" is the
wrong answer. Routing honours `x-canonical-monitor`, the hint `ui_notify_focused`
(`core/gum-ui.sh`) has always sent; anything unhinted lands on the focused monitor.

Four things are load-bearing, all documented in `.claude/rules/quickshell-qml.md`:

- a popup timing out must **not** `expire()`/`dismiss()` — that would empty the history
- constructing `NotificationServer` is what claims the bus name, hence the `Loader`
- `transient` cannot be implemented with `tracked = false` (the server deletes immediately)
- `keepOnReload` survives a reload, not a restart — same as swaync, so no disk persistence

**Card rules, both easy to "improve" wrongly**: no severity stripe (every card keeps an
identical silhouette), and every string on a card is `inkPrimary` — the ground is
`groundFloat`, which design page 01's own tier table says carries the primary ink *only*, so
hierarchy comes from size, weight and mono-vs-sans, never from dimming. Page 07 draws the
timestamp in `inkSecondary`; the foundation page wins. The one non-`inkPrimary` foreground on a
card is the secondary action's **outline** — a graphic at 3:1, not text, and page 13 rules it
`inkSecondary` explicitly (it was 2.18 as the retired muted token).

**Timeouts are 5s normal, 3s low, critical never** — shorter than the swaync config they replaced
(10s/5s), because an expired popup is not gone: it moves to the centre, which is the whole
difference between dismissing and ignoring. The stack shows **three** cards and a `+N more`
count; history is bounded at **100**, oldest dropped first. Bell gestures are swaync's — left
opens, right toggles DND, middle clears.

🚨 **Severity moved off the title colour.** It is now the glyph chip: a `signalError` tint AND a
different glyph, plus the card's border. `signalError` as TEXT measures **2.81** at worst and is
banned in every theme, so the old title colour was unreadable exactly when it mattered. There is
no severity *title* either — it repeats what the glyph and body already say.

**Grouping collapses at THREE, not two.** Two messages from one app are two things to read;
hiding one behind a count saves a card and costs the message, so a pair is expanded back in place.

**An image payload replaces the glyph chip** with a 38px thumbnail in the same slot, decoded *at*
that size — a screenshot notification that stalls the shell for a 4K decode is worse than no
thumbnail — and falls back to the glyph on a failed decode.

🚨 **DND and the undismissed queue now survive a RESTART**, in
`~/.local/state/quickshell/notifications.json` via `FileView` (which creates the parent directory
on write). They are the only two things in this shell that persist: one the user set deliberately,
the other is their unread mail. **A restored entry is a SNAPSHOT, not a live `Notification`** —
the sending process is gone, so its actions cannot be invoked and none are offered; only Dismiss
is. Its `actions` is an empty array rather than absent, so the card needs no special case.

## Deviations from Waybar, and why

Not oversights — each replaces something that was broken or useless:

| Module | Change |
|---|---|
| Clock | `format-alt` dropped. It turned the bar text into a calendar block; the calendar is in the tooltip instead, where Waybar's own default also puts it |
| Battery | No power profile. `power-profiles-daemon` is neither installed nor in `packages.yaml`, so Waybar's `on-click: powerprofilesctl` launched a binary that does not exist. Click runs `battery-status` instead |
| Backlight | **New, not ported.** Waybar's was gated on `exec-if: which light`, and `light` is not installed, so it never rendered |
| Network | No bandwidth counters — the native module does not expose them. Event-driven rather than Waybar's 5s poll |
| Media | `playerctld` is filtered out alongside the browsers: Quickshell lists every player, so the proxy would double-count the player it proxies |

## Gotchas

Full list in `.claude/rules/quickshell-qml.md`. The two that cost the most time:

- **`UPowerDevice.percentage` is 0..1**, not 0..100. Waybar/`upower` say 72%, the property says 0.72
- **Pipewire volume needs a `PwObjectTracker`** or it binds to nothing and shows 0% with no error
- **A glyph literal can be authored as `""`** and render nothing, with no error — it has
  happened twice here. Take codepoints from the `nerdfonts-search` skill and write them via
  an explicit `chr(0x…)`, never a paste
- **`escape()` is an illegal QML method name.** Renders, formats and lints clean, then the engine
  refuses the whole file at load with *"Illegal method name"*. Only running the tree finds it
- **A character-count truncation does not bound pixels.** `titleMaxLength` and `mediaMaxLength`
  are gone; use `BarWidget.labelMaxWidth` plus `Text.elide`

All three fail silently and look plausible on screen.
