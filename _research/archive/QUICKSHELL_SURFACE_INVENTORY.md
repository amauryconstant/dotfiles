# Desktop shell — surface inventory

**Date**: 2026-09-03 · **Statuses refreshed**: 2026-09-13
**Purpose**: the complete list of surfaces a desktop shell owns here, described by *what they are
made of* and *how they must behave* — not by how they are drawn or built.

🚨 **ARCHIVED 2026-09-13. This was written as the backlog and it stopped being one.** It listed
what a shell must own and what was left to build; recounting it entry by entry on 2026-09-13 found
**21 of the 23 surfaces shipped**, §15's region overlay and §23's greeter both recorded refusals,
and nothing at all waiting to be picked up (see the Summary — the table that said 18/2/3 had simply
not been recounted since §8 and §11 landed).

Its value now is the **left half** of every entry: what a surface is *made of*, how it must
*behave*, and which of its constraints are facts rather than preferences. That is design knowledge
and it does not expire. The Status lines are a build record.

**Where the live content went, on the day this was archived:**

| Question | Read |
|---|---|
| What is this shell, surface by surface, and why each departure | `private_dot_config/quickshell/CLAUDE.md` |
| What is still open | `_plans/QUICKSHELL_TOOL_RETIREMENT.md` (`_plans/archive/QUICKSHELL_OPEN_WORK.md` is closed) |
| What is left to remove | `_plans/QUICKSHELL_TOOL_RETIREMENT.md` |
| QML syntax, tooling, measured runtime traps | `.claude/rules/quickshell-qml.md` |
| The quickshell 0.3.1 API | `_research/QUICKSHELL_QML_API.md` — the last live research doc |

Every other Quickshell file is a record of work already done or a decision already taken. **Seven
of the twelve** are now under `_research/archive/` or `_plans/archive/`; the reading order below
carries their paths and is correct **as of 2026-09-13** rather than maintained.

**The per-surface descriptions below are as written on 2026-09-03; only the `Status` lines are
maintained.** A constraint an entry states was true when written and may have been answered by the
implementation since — the status line says so where it was.

| Document | What it is | Read it for |
|---|---|---|
| `private_dot_config/quickshell/CLAUDE.md` | **live** | what the shell is today, and why each departure. **Start here** |
| `.claude/rules/quickshell-qml.md` | **live** | QML syntax, tooling, measured runtime traps |
| `_plans/archive/QUICKSHELL_OPEN_WORK.md` | archived | the contrast rulings, closed the day they were written |
| `_plans/QUICKSHELL_TOOL_RETIREMENT.md` | **live** | what is left to remove, per tool |
| `_research/QUICKSHELL_QML_API.md` | **live** | the 0.3.1 API, corrected four times |
| **this file** | archived 2026-09-13 | what each of the 30 surfaces is made of, and what it shipped as |
| `_research/archive/QUICKSHELL_DESIGN_AUDIT.md` Part 5 | archived 2026-09-13 | the fourteen-page design's defects and this tree's rulings, incl. §5.6 on page 12 |
| `_research/archive/QUICKSHELL_GREETER.md` | closed 2026-09-12 | why §23 is not built, and what would reopen it |
| `_plans/archive/QUICKSHELL_SHELL.md` | frozen 2026-09-03 | why a phase was built the way it was |
| `_research/archive/QUICKSHELL_DESKTOP_RESEARCH.md` | closed 2026-09-01 | why Quickshell, and the alternatives rejected |
| `_research/archive/QUICKSHELL_COMPONENT_MAPPING.md` | historical | what the replaced tools did |
| `_research/archive/QUICKSHELL_DESIGN_BRIEF_R5.md` | delivered 2026-09-08 | what was asked of the design, before the rewrite |
| `_research/archive/QUICKSHELL_DESIGN_AUDIT.md` Parts 1–4 | historical | measurements only — every artboard id is dead |

**For**: the design system. Every entry is something the design must eventually specify; nothing
here prescribes a layout, a component name, or an API.

**Derived from**: `_research/archive/QUICKSHELL_COMPONENT_MAPPING.md` (what each replaced tool does),
`_research/QUICKSHELL_QML_API.md` (what the runtime can express), the script inventory under
`private_dot_local/lib/scripts/`, and `_research/archive/QUICKSHELL_DESIGN_BRIEF_R5.md` §1.1 (scope law).

**Scope law**: the shell replaces the desktop shell wholesale. A surface stays out only for a
**technical or safety** reason, and that reason must name the condition that brings it back.
Nothing is out on grounds of "that's not a bar".

---

## How to read this

Surfaces are grouped by **behaviour class**, because the class — not the content — decides most of
the design: whether it takes keyboard focus, whether it can be dismissed by looking away, how many
of it exist at once, and what happens on a second monitor.

| Class | Defining property |
|---|---|
| **Persistent** | Always on screen. Never takes focus. Reserves space or floats over content |
| **Ambient** | Appears without being asked, disappears on its own, accepts no keyboard input |
| **Summoned** | The user asks for it. Takes keyboard focus. Dismissed by choosing, or by cancelling |
| **Interrupt** | The *system* asks for it. Takes focus away from whatever the user was doing |
| **Foundation** | Not a surface — a rule every surface obeys |

Each entry states: what it is **made of** (its content), the **behaviour** expected of it, the
**constraints** that are facts rather than preferences, and its current **status**.

Status vocabulary: **Shipped** · **Shipped, off by default** · **Partial** (some of it exists) ·
**Not built** · **Deferred** (with a named condition).

---

## Class 1 — Persistent

### 1. Status bar

**Made of**: three zones (identity/workspaces, a centre, a system-status cluster) holding roughly
fourteen distinct readouts: workspace set, focused window title, clock, audio, network, Bluetooth,
battery, screen brightness, system tray, media player, notification state, keyboard layer,
dictation state, idle state.

**Behaviour**: never takes focus. Each readout is a *glyph at rest*; its number or detail lives in
a hover affordance or a popover, not on the bar. Exactly one element may carry an accent at rest —
everything else is neutral until it has a genuine state to report. Groups are separated by a
hairline that disappears with the group it introduces, so a machine missing a whole class of
hardware shows no orphan rules.

**Constraints**: one per monitor. It must reserve its own space plus its float inset, or windows
tile underneath it. Readouts appear and disappear with hardware and services, so every zone has to
survive its neighbours vanishing.

**Status**: Shipped.

### 2. Dock

**Made of**: a row of application tiles — pinned entries plus running windows — each with an icon,
a running/focused indicator, and a hover label.

**Behaviour**: hidden at rest. Revealed by the pointer reaching a screen edge, retracted when it
leaves, with a grace period so that crossing onto a tile does not retract it out from under the
click. Clicking a tile focuses or launches. It is a pointer surface; it never takes keyboard focus.

**Constraints**: one per monitor. The reveal region must cover both the hot edge and the panel's
live position while it animates, with no seam between them — otherwise the pointer falls out of the
region mid-reveal and it oscillates. Tiles resolve to real installed applications, so the design
must say what an unresolvable entry looks like.

**Status**: Shipped, off by default.

---

## Class 2 — Ambient

### 3. Notification toasts

**Made of**: a stack of cards. Each card carries an application identity, a summary, a body, an
optional image, an optional set of actions, and an urgency. Long bodies truncate; images may be
absent.

**Behaviour**: appears on arrival, stacks newest-first, auto-hides after a timeout that the sender
may specify, and can be dismissed by hand. Auto-hiding a toast must never destroy the underlying
notification — the centre's history is the same set of objects, so a toast that expires still has
to be readable later. Actions are invokable from the card. Urgent notifications do not auto-hide.

**Constraints**: one stack per monitor, and a sender may request *which* monitor it lands on.
Bodies are untrusted third-party text: they may be arbitrarily long, contain markup, or be empty.
Urgency is a small enumeration, and the design must express it as something other than a coloured
fill — a red card is unreadable in half the palettes.

**Status**: Shipped.

### 4. Adjustment overlay

**Made of**: a glyph, a progress track and fill, and optionally a numeric value. Currently used for
volume and screen brightness; it should generalise to any continuously-adjusted quantity.

**Behaviour**: appears when the value changes from any source — a key, a script, another
application — holds while the value keeps changing, then fades. Purely informational: it accepts
no input at all, and the pointer must pass straight through it to whatever is underneath.

**Constraints**: exactly one instance, following the focused monitor. It must distinguish states
that share a value: muted-at-50% is not the same as 50%. A progress fill is a UI component, not
text, so its contrast floor is lower than text — but it still has one, and the track it sits on is
the thing that usually fails.

**Status**: Shipped.

### 5. Mode and state indicators

**Made of**: small persistent markers for states the user has switched on and can forget about —
idle inhibition, presentation mode, screen recording in progress, dictation listening, non-default
keyboard layer.

**Behaviour**: visible whenever the state is active, invisible otherwise. These are the states most
likely to be *forgotten*, so they need to read as "something is deliberately not normal", distinct
from both a resting readout and an error. Several can be active at once, and the design must rank
them: the strongest relaxation of normal behaviour wins the indicator.

**Constraints**: some of these states are composed from independent switches — clearing one does
not necessarily restore the default — so an indicator cannot imply a single three-way mode.

**Status**: **Shipped 2026-09-12.** Five indicators share `bar/Bar.qml`'s `gStatus` group, each
drawn only while active, ordered by how far the state departs from normal — the ranking this entry
asks for, fixed rather than most-recent-first. Night light and screen recording were added in the
same change; neither had ever been drawn, and `screenrecord` had been signalling a Waybar module
that never existed. The shared vocabulary is: the glyph carries the state, no mode takes a colour
(only `signalError` clears 3:1 in all eight colorsets, and none of these is a fault). See
`private_dot_config/quickshell/CLAUDE.md` → Mode indicators.

---

## Class 3 — Summoned

### 6. Application launcher

**Made of**: a query field, a result list of installed applications with icons, and a selection.

**Behaviour**: summoned by a key. Takes exclusive keyboard focus. Fuzzy-matches as the user types,
ranks by recency/frequency, launches on confirm, closes on cancel or on losing focus. Keyboard is
the primary input; the pointer is secondary.

**Constraints**: one instance, on the focused monitor. The application index is live — entries can
appear or change while the launcher is open. Icons may be missing for some entries. Non-application
modes are a separate component, below.

**Status**: Shipped. Application search plus two prefix modes — `:` runs a command in a
terminal, `=` evaluates through `qalc`. An older mockup's five modes were declined; two is the
whole set.

### 7. Generic list picker

**The largest single gap.** Eighteen scripts summon a chooser today, and they are not launchers:
they hand the shell a list of lines and expect one back.

**Made of**: a title or prompt, a list of arbitrary text lines (sometimes with a leading glyph or
an icon), a filter field, and a selection. Some callers need a yes/no confirmation shape rather
than a list.

**Behaviour**: summoned *by a script*, not by the user directly. Takes exclusive keyboard focus,
filters as typed, returns exactly one selection or a cancellation. Cancelling must be
distinguishable from selecting nothing. Callers vary in list length from two items to several
hundred, and in line width from one word to a full command line.

**Constraints**: this is a reusable surface with many callers, so the design owes it a *contract*,
not a screen: how a title is shown, how long lines behave, how a list too long to fit scrolls, what
an empty filter result says, and how a confirmation variant differs from a list variant. Callers
today style themselves individually; that must collapse into one specified surface with variants.

**Status**: Shipped 2026-09-09. `MenuPicker.qml` on the shared `PickerSurface` chrome, fed by
`MenuServer.qml` over `$XDG_RUNTIME_DIR/quickshell-menu.sock` and called by
`desktop/quickshell-menu`. A socket rather than IPC because a dmenu call must block; the wrapper
keeps a Wofi fallback path. Rich items (glyph, subtitle, payload) landed 2026-09-10.

### 8. Hierarchical system menu

**Made of**: a root menu of about ten categories (applications, help, quick actions, appearance,
setup, install, update, AI, about, power), each opening a submenu, some nesting a level deeper.
Leaves either run something, or open one of the other surfaces in this document.

**Behaviour**: summoned by a key. Keyboard-navigable in both directions — entering a submenu and
going back — with a visible sense of where you are. Each level is a list picker, so this component
is largely a *navigation model* layered on component 7, plus the rule for how a leaf hands off.

**Constraints**: the real menu tree already exists and has a fixed shape; the design should be
drawn against it rather than an invented one. Depth is at most three. Some leaves are destructive
(power, package removal) and need a confirmation step that the launcher path does not have.

**Status**: **Shipped 2026-09-13** — the navigation model moved into the shell, the tree did not.
`MenuServer` takes two optional request fields: `breadcrumb`, drawn before the prompt, and `back`,
answered on Left or Backspace with an empty query. `back` is a *payload*, so each submenu opts in
with two extra arguments to `show_menu` and dispatches it through the `󰁍 Back` arm it already had.

The tree stays in the thirteen `menu-*` scripts deliberately: page 10 asks for the navigation
model in the shell, not the content, and moving thirteen scripts' worth of menu into QML would put
every future menu change inside the shell. The Back rows stay too, because both fields are ignored
on the Wofi fallback path.

Found while wiring it: **every `󰁍 Back` row in six of those scripts had been dead**, pointing at
`system-menu.sh` — a name chezmoi has never produced. 18 such paths were corrected in the same
pass; see `user-interface/CLAUDE.md`.

Verified live 2026-09-13 against the deployed shell: a request carrying `breadcrumb` and `back`
draws the trail before the prompt and the `← back` hint in the footer; a second request while one
picker is open is refused immediately (exit 1, no queueing); killing the caller closes the surface
through `aborted` rather than leaving it waiting on a socket nobody reads. The Left/Backspace
keypress itself is the one part not machine-checkable here — no input is injected into the live
session.

### 9. Keybindings reference

**Made of**: the full binding set, grouped by modifier or by category, each row a key combination
and a description. Long — this is the one summoned surface that is a *document*, not a chooser.

**Behaviour**: summoned by a key, filterable, scrollable, dismissed by cancel. Read-only. The
design question is legibility at density, not interaction.

**Constraints**: key combinations are typographically awkward — modifiers, symbols and letters
mixed — and want a distinct treatment from the descriptions beside them. The list is generated, so
its length and content change without notice.

**Status**: Shipped as a list, not as a document. `desktop/keybindings` formats the binding set and
pipes it through the picker. The density treatment this entry asks for is unaddressed — a picker row
is not a reference page.

### 10. Theme picker

**Made of**: the eight themes, each ideally previewable as something more than its name.

**Behaviour**: summoned from the menu or a key; selecting one re-themes the entire shell live.

**Constraints**: this is the one picker whose *own* appearance changes as a result of using it. The
design should say what the transition looks like, and whether the picker survives it. A preview
must not imply a colour is available that the theme does not define.

**Status**: Shipped 2026-09-10. `user-interface/theme-menu` on the picker, with a per-theme brand
mark; themes with no brand mark take a tinted glyph chip instead. The picker does not survive the
switch — it closes on selection, and the shell repaints with no transition.

### 11. Display and monitor profile picker

**Made of**: the available monitor arrangements, each with enough identity to be told apart —
outputs, resolutions, which is primary.

**Behaviour**: summoned when monitors change or on demand. Selecting one reconfigures the layout,
which may make the picker's own monitor disappear.

**Constraints**: the shell's own geometry changes as a direct result of the selection. Monitor
identity is not a port name — the same physical display can arrive on a different connector — so
the design must not lean on "DP-1" as a label a user recognises.

**Status**: **Shipped 2026-09-12 as an OUTPUT picker, with the profile picker declined and the
reason recorded.**

🚨 **A saved-profile picker cannot be built.** `hyprdynamicmonitors` selects a profile by matching
EDID descriptions and offers no way to force one: `run` auto-selects, `freeze --profile-name` goes
the other way (live state → new profile), and there is no `apply`/`switch` subcommand and no IPC
socket. The only lever is editing `config.toml` and restarting the daemon. Omarchy's shell has no
analogue either — `shell/plugins/panels/monitor/` is a live brightness/scale/enable-per-output
panel, not a profile picker.

So `desktop/display-menu` picks over **the outputs themselves**, which is reachable: each row is an
output, titled by its EDID description with the port, mode, scale and focus as the subtitle —
honouring this entry's constraint that the user must not be asked to recognise "DP-1". Selecting an
output enables or disables it; disabling the *last* enabled output is refused outright, because
that is a black screen with no way back that does not involve a TTY. The last row opens wdisplays
through `monitor-switch`.

It replaces the old "Displays" menu entry, which duplicated `monitor-switch`'s body inline and
launched wdisplays without ever showing what was connected — `monitor-switch` itself picks nothing
and never did, despite the name.

**If the profile picker is wanted later**, the cheapest path is writing the chosen profile's
`hyprconfigs/*.lua` straight to the daemon's own `destination` (`~/.config/hypr/monitors.lua`) and
reloading; the honest path is an upstream `apply` subcommand.
### 12. Session save and restore prompt

**Made of**: a prompt naming a saved window session and how many windows it holds, with a restore
or skip choice; and, for saving, a slot chooser.

**Behaviour**: appears at login when a saved session exists, and on demand. Timing matters — it
arrives while the desktop is still assembling itself.

**Constraints**: it competes for attention with everything else that happens at login. The design
should decide whether this is a picker or an interrupt; it is currently drawn as a picker but
behaves like one of the few things the shell asks the user unprompted.

**Status**: Shipped as a picker. `desktop/session-prompt` asks through the generic picker. The
picker-or-interrupt question this entry raises is still unanswered — it was inherited, not decided.

### 13. Colour-temperature control

**Made of**: an on/off state plus a temperature value, and the schedule that drives it.

**Behaviour**: summoned to adjust; the value is continuous, so this is closer to a slider surface
than a list. Changing it has an immediate, whole-screen visual effect.

**Constraints**: the shell's own colours are being distorted while the user is adjusting them. Any
preview inside this surface is lying by definition, and the design should acknowledge that rather
than fight it.

**Status**: Shipped as a picker of preset values (`desktop/nightlight-config`), not as the
continuous control this entry describes. `PopoverSlider` now exists and would serve it.

### 14. Audio device picker

**Made of**: the available outputs and inputs, each with a name, a type, and which is current.

**Behaviour**: summoned to switch. Devices appear and disappear as hardware is plugged in, while
the surface is open.

**Constraints**: device names come from the system and are frequently long, duplicated, or
meaningless to a human. This may be a variant of the audio popover (component 20) rather than a
separate surface — the design should rule on that rather than leaving both.

**Status**: Shipped **inside the audio popover**, which is the ruling this entry asked for: one row
per sink, with the input below it. There is no separate device-picker surface and none is wanted.

### 15. Screenshot and recording control

**Made of**: a mode choice (region, window, whole screen), a destination, and — for recording — a
running state with elapsed time and a stop affordance.

**Behaviour**: summoned by a key. Region selection is a full-screen interaction with its own
visual language: a dimmed field, a live selection rectangle, dimensions. Recording then transitions
into a persistent indicator (component 5) that must be reachable to stop.

**Constraints**: the only surface here that draws over the *entire* screen and takes pointer input
across all of it. It must also stay out of its own capture. There is no surface for this at all
today, in any tool being replaced.

**Status**: **Partially shipped 2026-09-12, and the unbuilt half is a ruling rather than a gap.**

🚨 **The full-screen region overlay is deliberately not built.** This entry's own constraint — "it
must stay out of its own capture" — has no mechanism: no `excludeFromCapture` or equivalent exists
anywhere in Quickshell, on `PanelWindow`, `WlrLayershell` or `ProxyWindowBase`. And omarchy, running
the same stack, did not build one either: its only QML piece is
`shell/plugins/bar/indicators/ScreenRecording.qml`, while region select and recording stay in
`bin/omarchy-capture-screenrecording`, on the same slurp + PID-sidecar architecture ours already
uses. Region select stays with `wayfreeze` + `slurp` + `grim`.

What shipped is the rest of the entry:

- **The running state with a reachable stop affordance** — `RecordingWidget`, in the bar's mode
  indicator group (§5), reading `/tmp/screenrecord_$USER.pid`, elapsed time ticking from that
  file's mtime, click to stop. Before this, `screenrecord` signalled a Waybar module that never
  existed.
- **The mode choice** — `media/capture-menu` on the shared picker: region, window, whole screen,
  smart, region-to-clipboard, QR, OCR, record. It invokes the same scripts the Print-key chords
  run, so no capture path has a second implementation. Bound to `CTRL ALT SHIFT + Print`, which
  until now ran the *identical* command as `ALT SHIFT + Print` while claiming to be "Fullscreen
  recording".

### 16. Clipboard history

**Made of**: a list of past clipboard entries — text, and ideally images — most recent first, with
a preview and a selection that re-copies.

**Behaviour**: summoned by a key, filterable, selection replaces the current clipboard content.

**Constraints**: **the shell must own the storage.** The system provides only the *current*
selection, so history, capacity, eviction and persistence across restarts are all design decisions
with no default to inherit. Clipboard content is frequently sensitive — passwords pass through it —
so the design must state a policy for previewing and for whether history survives a lock.

**Status**: Shipped 2026-09-09. `ClipboardPicker.qml` over `cliphist`, `SUPER+C`. Storage stays
cliphist's, so the ownership question this entry raises was answered by *not* taking it: capacity,
eviction and lock behaviour are cliphist's, not the shell's.

### 17. Power and session menu

**Made of**: five or six terminal actions — lock, log out, suspend, hibernate, reboot, shut down —
each a tile with a glyph and a label.

**Behaviour**: summoned by a key. Keyboard-navigable, one action per tile, immediate on confirm.
Most actions save the window session first; lock does not.

**Constraints**: every action is irreversible and several are destructive of unsaved work. The
design must rank them so the safest is the default landing point, and give the destructive ones
weight without resorting to a red fill that half the palettes cannot render legibly. Hibernate may
be unavailable on a given machine and must degrade rather than fail.

**Status**: Shipped.

### 18. Workspace overview

**Made of**: the workspaces of a monitor, each holding scaled representations of its windows,
positioned as they actually are.

**Behaviour**: summoned by a key. Selecting a workspace switches to it; selecting a window focuses
it. Live rather than a snapshot — windows moving while it is open should be visible.

**Constraints**: it follows the focused monitor and shows that monitor's aspect, not a portrait
card. Window positions must be projected from real geometry, which means accounting for display
scaling; a shell that ignores this renders a plausible-looking but wrong layout. Windows on
inactive workspaces *can* be shown live.

**Status**: Shipped, off by default.

### 19. Notification centre

**Made of**: the full notification history as a list of the same cards used for toasts, grouped or
ordered by time, plus controls — clear all, clear one, do-not-disturb.

**Behaviour**: summoned by a key or from the bar. Scrollable, actions still invokable on old
entries, dismissal removes an entry permanently. Do-not-disturb suppresses toasts while still
recording history.

**Constraints**: history is in memory only — it survives a configuration reload but not a restart —
so the design should not promise permanence it does not have. The empty state is the state a user
sees most often. Card contrast is stricter here than for toasts, because cards sit on a panel
ground rather than over the wallpaper.

**Status**: Shipped.

### 20. Widget popovers

**Made of**: seven detail surfaces, one per bar readout that has more to say than a glyph — audio,
network, Bluetooth, battery, media, calendar, notifications. Each carries the readout's full state
plus its common controls.

**Behaviour**: opened from its bar widget, anchored beneath it and never covering it, closed by
choosing, by cancelling, or by clicking away. Some are read-only; some contain controls that change
system state (switching a network, disconnecting a device, transport controls).

**Constraints**: these collectively replace a monolithic control centre, so together they must
cover everything that panel would have. They are the only summoned surfaces anchored to a specific
point rather than centred, and the anchoring is what makes them read as belonging to their widget.
Each must have a meaningful state for "the underlying service is absent".

**Status**: Shipped 2026-09-10. Seven payloads on one chrome (`BarPopover`), two open modes —
pointer (no grab, closes on losing the pointer) and the `SUPER+P` submap (`HyprlandFocusGrab`, focus
ring). The **set differs from this entry**: audio, network, bluetooth, calendar, media, **meters**,
**power**. Battery folded into power; notifications kept the centre it already had. They removed the
bar's last four shell-outs. Departures from design page 06 are measured in
`_research/archive/QUICKSHELL_DESIGN_AUDIT.md` §5.5.

---

## Class 4 — Interrupt

### 21. Authentication dialog

**Made of**: the action being authorised, the application asking, a password field, and a feedback
line for failures and remaining attempts. Sometimes a choice of *which* identity to authenticate
as.

**Behaviour**: raised by the system, not the user. Takes focus immediately, cannot be ignored
indefinitely, and either succeeds, fails with a retry, or is cancelled. Every failure state has
text the surface must show verbatim from the system.

**Constraints**: exactly one such agent may exist for the whole session, so adopting this means
displacing the existing one — and a crash then leaves *none*, breaking every privileged action
until the shell restarts. Deferred until the shell has a crash-recovery story; keep designing it.
The identity-choice case is a real branch the current drawings assume away.

**Status**: **Shipped** 2026-09-12 — `quickshell/dotfiles/polkit/PolkitDialog.qml`, gated on
`features.quickshell_polkit` (its own flag: displacing a session-exclusive agent is a separate
decision from running the bar, exactly as `quickshell_notifications` is for swaync). polkit-gnome
moved out of the shared `hypr/conf/autostart.*` into `hypr/conf.d/polkit-gnome.{lua,conf}`, which
deploys only when the flag is off.

The stated blocker was answered first: the shell runs as `quickshell.service`, `Restart=always`
with a 5-per-60s budget, and `SUPER+B` clears a spent budget — so a crashed agent is a ~2s gap
rather than a session with none.

**The identity-choice branch is built**, not assumed away: `AuthFlow.identities` /
`selectedIdentity` exist in 0.3.1, group entities are filtered out (a group has no password of its
own), the chip row collapses at one identity, and Tab cycles. Omarchy's own agent ignores them.

Constraints that turned out to matter, both now in `.claude/rules/quickshell-qml.md`: constructing
`PolkitAgent` is what registers it, and a failure does **not** end the flow — Quickshell starts a
fresh PAM session and the dialog must stay up.

### 22. Lock screen

**Made of**: a clock, an identity, a password field, authentication feedback, and whatever ambient
information is allowed while locked — notification presence, media state, battery.

**Behaviour**: covers every monitor, takes all input, and cannot be dismissed except by
authenticating. Distinct visual states for idle, typing, verifying, failed. It is also the surface
most likely to be seen at a glance from across a room.

**Constraints**: a crash here is unrecoverable without a text console, which is why it is deferred.
The design must decide how much is shown on a locked screen — every notification preview is a
privacy decision. Multi-monitor behaviour needs a rule: one prompt or one per screen.

**Status**: **Shipped 2026-09-12** (`lock/LockScreen.qml` + `lock/LockContent.qml`, behind
`features.quickshell_lock`). The deferral was never about supervision: `Restart=always` alone made
this entry WORSE, because `ext-session-lock` outlives its client, so a restarted shell came back
holding no lock while the session sat behind Hyprland's failsafe with nothing to authenticate
against. Three pieces answered that, all now present:

- `misc:allow_session_lock_restore = true` in `hypr/conf/general.{lua,conf}` — the tree's only
  `misc` block. The compositor accepts a replacement client instead of refusing one.
- `desktop/session-locked`, answering by exit status alone: 0 locked, 1 unlocked, **2
  undetermined** (a monitor with no workspace yet never reaches the lock, so a retrying caller
  must not treat 2 as an answer) — and `desktop/session-lock-stranded` on top of it, which is
  the question the recovery actually asks.
- `desktop/quickshell-restart`, which refuses while `lock status` reports `secure` or `requested`.

Consequence already handled in the same pass: `desktop/immediate-lock` moved from
`pidof hyprlock` to a `flock`, because the compositor now *accepts* the second locker a lost race
would spawn.

🚨 **The probe that recovers a stranded lock must ALSO prove no locker is alive.** Measured
2026-09-12 the hard way: `session-locked` alone returned 0 while hypridle's hyprlock was up, the
recovery read that as an orphan, and the shell took a second lock on top of a live one —
displacing exactly what the `flock` had just been added to prevent. `session-lock-stranded` is
both conditions (compositor locked **and** the lock file free), and the QML rules *itself* out
first with `locked || lockRequested`, since an in-process locker holds no lock file.

**The recovery is measured, not argued.** 2026-09-12, locked session, `systemctl --user kill -s
SIGKILL quickshell.service` from a TTY: SIGKILL at 13:04:15 (`status=9/KILL`), restart **2s**
later, `Configuration Loaded` in the same second, and the re-drawn prompt authenticated at
13:04:22 through `quickshell[9139]: pam.subprocess … config "hyprlock"` — this shell's own
`PamContext`, not the hyprlock binary. The failsafe was never what the user faced.

**What page `Shell-12-Deferred` settled**, read for the first time on 2026-09-12: nothing ambient
is drawn — no notification presence, no media, no battery, because "a lock screen that shows
message previews unlocks the user's mail for anyone walking past", which is stricter than the
"presence only" this entry proposed above. Every output is covered; the field appears on the
focused one alone. No Esc, ever. A failure clears the field and reports inline but **does not
count down publicly**.

**Two defects found the first time it was actually locked into, both fixed 2026-09-13:**

- **The field came up unfocused** and the first password went nowhere — a focus claim made from a
  child's `Component.onCompleted`, which runs before the window it would focus into exists. All
  three claim edges now defer through one `claimFocus()`. The general rule, and the line of
  `proxywindow.cpp` behind it, is in `.claude/rules/quickshell-qml.md`.
- **It was drawn at popover scale.** The density scale is calibrated for a 40px bar and 340px
  panels, so page 12's 220x34 field is correct against the scale and wrong against the surface —
  the lock is the one full-screen thing this shell draws. `lockFieldWidth` 360, `lockFieldHeight`
  56 and `lockClockSize` 72 are panel measurements in `Config.qml.tmpl`, beside `polkitDialogWidth`;
  the date moved up to `fontDisplay` for the same reason, keeping it a rank below the clock.

**The one departure**: page 12 asks for a lock process supervised independently of the shell. This
tree recovers instead of isolating — the failsafe is opaque, so a crashed locker is ugly rather
than insecure, and `Restart=always` plus lock restore plus the stranded probe turns it into ~2s
of failsafe followed by a prompt. `desktop/immediate-lock` keeps hyprlock as the runtime fallback
for a shell that cannot come back at all. Recorded in `quickshell/CLAUDE.md`'s departures table.

### 23. Greeter

**Made of**: user selection, password entry, session selection, and system actions.

**Behaviour**: the pre-session equivalent of the lock screen. Same authentication states, different
lifecycle — it runs before there is a session at all.

**Constraints**: the runtime supports this, but no decision has been recorded on whether it is in
scope. If it is, it shares almost all of the lock screen's visual language and should be designed
alongside it rather than separately.

**Status**: **Not built — decision recorded 2026-09-12**: SDDM stays, a greeter is out of scope.
Quickshell *can* do it (`Quickshell.Services.Greetd` is a real greetd client, distinct from
`WlSessionLock`), and Omarchy — having replaced its whole shell with Quickshell — still logs in
through SDDM at v4.0.3. Facts, cost, and the named condition that would reopen it:
`_research/archive/QUICKSHELL_GREETER.md`.

---

## Class 5 — Foundations

These are not surfaces; they are the rules that make thirty surfaces read as one shell.

### 24. Colour and contrast law

**Made of**: a semantic colour vocabulary — a small set of named roles, not a palette — that
resolves against **eight** different colorsets, four light and four dark.

**Behaviour**: every pairing of a foreground role on a background role must clear its contrast
floor *in all eight*, at 4.5:1 for text and 3:1 for graphics and UI components. Roles that are
distinguishable in one theme can be identical in another.

**Constraints**: no fixed token works everywhere. At least three colours have to be *computed* per
theme rather than named: the foreground on an accent fill, a modal scrim, and the foreground on
that scrim. Any rule of the form "use role X on role Y" is false somewhere unless it has been
measured against all eight.

### 25. Interaction states

**Made of**: the full state set for every interactive element — rest, hover, focus, active/pressed,
selected, disabled, loading, error — and the rule for which states an element is allowed to skip.

**Behaviour**: an element's rest appearance changes when it is placed on a lit ground rather than
the bare bar, so "rest" is not one fixed appearance. Keyboard focus must be visible on every
summoned surface, since keyboard is the primary input for most of them.

**Constraints**: the disabled state cannot use the muted foreground role — it collapses to
invisibility against a mid background in two of the eight themes.

### 26. Motion

**Made of**: the durations, easings and directions for reveal, dismiss, value change, and
attention.

**Behaviour**: motion communicates origin — a popover grows from its widget, a dock slides from its
edge, a toast enters from where it will live. Ambient surfaces fade; summoned surfaces move.

**Constraints**: reveal animations that are driven by pointer position must remain interruptible
mid-flight, and the surface must stay usable while animating.

### 27. Glyph and icon inventory

**Made of**: the complete set of glyphs the shell draws, by role rather than by codepoint — state
ramps (battery charge, signal strength, brightness, volume), category marks, action marks.

**Behaviour**: ramps must be monotonic and readable at a glance, distinguishing full from empty
from unavailable.

**Constraints**: a missing glyph renders as nothing at all, silently — no error, no fallback box.
Every ramp must therefore be specified as an explicit, verifiable list rather than "the battery
icons".

### 28. Density and geometry

**Made of**: one radius ramp, one spacing scale, and a small set of fixed heights, shared by every
surface.

**Behaviour**: nesting reads as nesting because the ramp is consistent — a chip inside a panel
inside a screen. No surface invents its own radius or spacing.

**Constraints**: the shell spans monitors of different scales and pixel densities simultaneously,
so the scale is defined in logical units and must survive being rendered at 1× and 1.25× side by
side.

### 29. Multiplicity and focus

**Made of**: the rule, per surface, for how many exist and where they go.

**Behaviour**: three distinct answers, and every surface has exactly one: *one per monitor* (bar,
dock, toasts), *one following the focused monitor* (overlays, summoned surfaces), or *one covering
everything* (lock, region capture).

**Constraints**: a monitor's identity for this purpose is its name, and the shell's notion of the
focused monitor and the window manager's are different objects that must be reconciled. The design
should state the rule per surface rather than leaving it to implementation.

### 30. Degradation

**Made of**: the appearance of every surface when the thing it describes is absent — no battery, no
Bluetooth adapter, no backlight, no network, no media player, a service that has not started yet.

**Behaviour**: degrade by *source*, not by machine class. A desktop with a plugged-in battery
should show one; a laptop with its Bluetooth disabled should not show an adapter. Several sources
are empty for the first second or two after login and fill in on their own, so "absent" and "not
yet arrived" need different treatments.

**Constraints**: this is what keeps a single design working across a laptop and a desktop without
branching into two designs.

---

## Summary

🚨 **As of 2026-09-13 the build is closed: 21 of the 23 surfaces are shipped, and the other two
are rulings rather than gaps.** Recounted entry by entry on 2026-09-13 — the previous table said
18 / 2 / 3 and had not been recounted since §8 and §11 landed. Two of the 21 (dock, workspace
overview) ship **off**: built, tried in daily use, declined. **Nothing is deferred any more**:
§21 and §22, the two the design's own page 12 held back on safety, both landed on the supervision
that arrived the same day.

| Class | Surfaces | Shipped | Partial by ruling | Declined |
|---|---|---|---|---|
| Persistent | 2 | 2 | — | — |
| Ambient | 3 | 3 | — | — |
| Summoned | 15 | 14 | 1 (§15) | — |
| Interrupt | 3 | 2 | — | 1 (§23) |
| Foundation | 7 | — | — | — |
| **Total** | **30** | **21** | **1** | **1** |

There is no **Deferred** column any more and no **Not built** one: every entry that was either is
now shipped, or is a decision with its reason recorded. The one piece of Quickshell work still
genuinely open is in `_plans/QUICKSHELL_TOOL_RETIREMENT.md`, and it is *removal*, not building.

The 2026-09-03 reading — that the generic list picker (7) and the menu model on it (8) were the
bulk of the work — held: building the picker on 2026-09-09 closed eight entries in one change,
because eighteen scripts already spoke dmenu.

**The five entries that closed last, in full:**

| # | Surface | State |
|---|---|---|
| 5 | Mode and state indicators | **Shipped 2026-09-12** — ranking is fixed-order, glyph-carried; night light and recording newly drawn |
| 8 | Hierarchical system menu | **Shipped 2026-09-13** — navigation in the shell (breadcrumb + back gesture), tree deliberately left in the scripts |
| 11 | Display and monitor profile picker | **Shipped 2026-09-12 as an output picker** — the *profile* half is declined, because hyprdynamicmonitors exposes no way to force a profile |
| 15 | Screenshot and recording control | **Partial by ruling 2026-09-12** — indicator + mode picker shipped; the region overlay is declined (nothing can keep a surface out of its own capture, and omarchy declined it too) |
| 23 | Greeter | **Closed** — decision recorded 2026-09-12, SDDM stays (`_research/archive/QUICKSHELL_GREETER.md`) |

Surfaces 9, 12 and 13 are shipped but landed as *picker calls*, which is thinner than their entries
ask for: a keybinding document, a login interrupt and a continuous control respectively. Improving
one is optional work, not a gap.
