# Quickshell Rule Evidence

Measurements, incidents and history behind the rules in `.claude/rules/quickshell-qml.md` and
`.claude/rules/quickshell-design.md`. Each section below is the **verbatim original text** of a rule
before it was condensed (2026-10-18); the rule files keep the imperative and the number that decides
it. Evidence, not a backlog — nothing here is to be implemented.


---

## Rich text self-promotion: the Omarchy history

*Originally `quickshell-qml.md` lines 149–157.*

🚨 **`Text` defaults to `Text.AutoText`, and `AutoText` SELF-PROMOTES to rich text.** Qt runs
`Qt.mightBeRichText()` on the string and switches format by itself — no `StyledText`, no opt-in.
Rich text then **fetches `<img src="http://…">`**, so any `Text` rendering a string this repo did
not author is an unauthenticated outbound GET waiting for a sender to notice. The reachable path
here was the shared `BarWidget` label, which carries the **window title** and the **MPRIS track
title**: a web page setting `document.title = '<img src="http://…">'` makes the bar beacon.
Omarchy shipped the same class and patched it in v4.0.2 (`shell/plugins/notifications/`), after
its own `/<img[^>]*>/gi` strip turned out to be bypassable — `<im<img src="decoy">g src="beacon">`
is *rewritten into* a live tag by a substring strip. Do not strip; declare the format.


---

## Exclusive zone: the compositor adds the margin

*Originally `quickshell-qml.md` lines 186–201.*

🚨 **The compositor ADDS the margin, so the zone is not the bar's bottom edge.** An
exclusive zone is measured from the surface's own edge, so Hyprland reserves
`margins.top + exclusiveZone`. Verified live 2026-09-10: `margins.top` 4 with a zone of 44
gave `hyprctl monitors` `reserved=[0,48,0,0]` — four PAST the bar's own bottom edge, not at
it. `barHeight` alone is what reserves exactly the bottom edge and leaves `gaps_out` as the
only gap below the bar.

This tree deliberately does **not** do that: `exclusiveZone` is `barHeight + barInset`, so
the inset is counted twice and the gap under the bar is `barInset + gaps_out` (8) against
the 4 its side edges get. Both were rendered and compared on 2026-09-10 and the asymmetric
one was chosen — the bar reads as separated from the windows rather than as one more tile.
So a symmetric-looking `barHeight` here is a *change*, not a fix. See `bar/Bar.qml`.

Check it against the compositor, never against the QML: `hyprctl monitors -j` for `reserved`,
`hyprctl layers` for the bar's own `xywh`, and `hyprctl clients -j` for the first tiled
window's `at` — which is inside the 2px border, so it reads `gaps_out + border_size`.


---

## grabFocus on a layer-shell parent: the measured log

*Originally `quickshell-qml.md` lines 210–219.*

🚨 **`PopupWindow.grabFocus` does not work on a layer-shell parent.** It sets `Qt::Popup`
(`popupwindow.cpp:63`), which makes Qt request an *xdg_popup* grab — and a popup parented to a
layer surface is not an xdg_popup. Measured 2026-09-10 with `quickshell -p`: *"Failed to create
grabbing popup. Ensure popup has a transientParent set and that parent window has received
input"*, then *"Cannot attach popup … as the popup is not an xdg_popup"*, and the popup silently
sets itself back to invisible. So a bar popup gets **no** click-outside dismissal from Qt.
`HyprlandFocusGrab` (`Quickshell.Hyprland`, re-exported from `_FocusGrab`) is what works: keys
reach a focused `Item` inside the popup and `cleared` fires on an outside click — but it takes
the keyboard away from the focused application for as long as it is active, and it survives a
workspace switch, so it is only correct for a surface the user deliberately summoned.


---

## Pipewire default sink resolved by name: the leak

*Originally `quickshell-qml.md` lines 263–274.*

🚨 **`Pipewire.defaultAudioSink` is resolved BY NAME, so a duplicate node wins silently.**
`defaults.cpp` `onMetadataProperty` reads `default.audio.sink` out of the metadata as a *name*
string and hands it to `registry->findNodeByName()` — first match, no id, no tiebreak. Every
suspend/resume on this laptop leaks one orphaned `Audio/Sink` node whose `device.id` points at a
device that no longer exists, all sharing the name `alsa_output.pci-…-analog-stereo`; after 17
resumes there were 18. Quickshell bound a frozen one, so `onVolumeChanged` never fired and the OSD
and `AudioWidget` tracked a node nothing could change — while `pamixer` was correctly moving the
real sink all along. The symptom reads as *"the volume keys do nothing"*, and every layer below QML
tests clean. Diagnose with `wpctl status` (the live default carries `*`) or
`pw-dump | jq '.[] | select(.info.props["media.class"]=="Audio/Sink")'`; `systemctl --user restart
wireplumber` destroys the orphans. The leak is swept on every resume by `after_sleep_cmd` in
`.chezmoitemplates/hypridle_general` — on the laptop only, where it was measured (chassis-gated).


---

## Locked vs stranded: the 2026-09-12 measurement

*Originally `quickshell-qml.md` lines 321–329.*

🚨 **"Is the compositor locked" is NOT "is the lock stranded", and acting on the first
displaces a live lock screen.** `desktop/session-locked` is equally true while hyprlock is
running, and `misc:allow_session_lock_restore` means a second client is now *accepted* rather
than refused — which is the whole reason `immediate-lock`'s guard had to become a `flock`.
Measured 2026-09-12: `lock/LockScreen.qml` ran `session-locked` at startup, got 0 while
hypridle's hyprlock was up, concluded orphan, and took a second lock on top of a live one. The
probe is `desktop/session-lock-stranded` (locked **and** the lock file free); the QML rules
*itself* out first with `locked || lockRequested`, because the in-process locker takes no lock
file and so cannot be seen by one.


---

## NotificationServer tracked=false: the symptom

*Originally `quickshell-qml.md` lines 349–353.*

Missed, the failure is quiet and misleading: popups still appear (the handler already captured
the pointer), then turn into a list of `null`s, while the centre stays permanently empty. The
only symptom in the log is `TypeError: Cannot read property 'hints' of null`. Verified live
2026-09-01. The corollary: implement `transient` by filtering it out of history, never by
setting `tracked = false`.


---

## chezmoi apply and the Quickshell file watcher

*Originally `quickshell-qml.md` lines 364–388.*

🚨 **`chezmoi apply` does not reliably reload a running Quickshell.** Verified 2026-09-02
after Phase 5.5: the files on disk were correct, the shell's own log said
*"Reloading configuration… Configuration Loaded"* — and the live generation was still the
pre-apply one. `ipc show` listed no `overview` target and `hyprctl layers` showed no dock
surface, while the same tree run with `quickshell -p` mapped it immediately at `1920x74 @0,1006`
with no errors.

Two facts behind it, both measured:

- **The watcher compares CONTENT, not mtime.** `touch shell.qml` produces no reload at all;
  appending a byte produces one. So `touch` is not a reload command.
- `EngineGeneration::setWatchingFiles` (`generation.cpp:170`) adds a `QFileSystemWatcher` path
  for every scanned file *and* its directory. chezmoi replaces files by writing a temp and
  renaming over the target, which is exactly the pattern a per-file watch does not survive —
  and the one directory-triggered reload can land mid-apply, re-reading files that have not
  been replaced yet. (The mid-apply ordering is inference; the stale generation is not.)

The watcher is therefore **off in the deployed shell**: `quickshell.service` sets
`Environment=QS_DISABLE_FILE_WATCHER=1` (`qmlglobal.cpp:67`), the same call Omarchy makes in
`bin/omarchy-launch-shell` for the same reason — an upgrade rewriting the tree must not reload
against a half-written one. The facts above are why it is off, not a behaviour to work around.

So an apply that changes this tree ends with **`desktop/quickshell-restart`** (which wraps
`systemctl --user restart quickshell.service` in the lock guard below), the only reload path. Never verify by looking at the files — verify with
`quickshell -c dotfiles ipc show` (is the new target there?) or `hyprctl layers`.


---

## Why the quickshell unit exists

*Originally `quickshell-qml.md` lines 397–401.*

Quickshell also re-execs **itself** from its signal handlers (`src/crash/handler.cpp:148-156`), so
an ordinary segfault never reaches systemd. The unit exists for what that cannot cover: Qt leaving
through `_exit()` on a lost Wayland connection, a crash within 10s of launch (its own crash-loop
guard calls `exit(-1)` instead of relaunching, `src/launch/main.cpp:68`), `SIGKILL`, and a QML tree
that fails to load at all.


---

## Reveal mask: caelestia and the pointer-driving verification

*Originally `quickshell-qml.md` lines 452–479.*

🚨 **The reveal mask is the UNION of the hot edge and the panel's LIVE rect.** `regions` is
`Region`'s default property (`region.hpp:109`) and `Intersection` defaults to `Combine`
(`region.hpp:144`), so a nested `Region` unions in:

```qml
mask: Region {
    item: hotEdge
    Region { item: panel }
}
```

Three ways a single rect gets this wrong, all of which drop the pointer out of the input region
and oscillate: binding it to the panel **alone** (the panel has not arrived yet while it slides),
pinning it to one **static centred** band (an off-centre entry is outside it), and leaving a
**seam** between the panel's resting edge and the hot edge (crossing it loses hover). Grow the
hot edge to meet the panel while revealed, and keep it full-width so the edge can be entered
anywhere. caelestia's `modules/drawers/Regions.qml` sizes its regions off the live animation
(`panel.height * (1 - offsetScale) + borderThickness`) for the same reason — with slack.

**Add a hide grace period anyway.** caelestia gets away with none because its hit-testing is
exhaustive coordinate math in one `MouseArea`; anything built from real child `MouseArea`s
wants the slack. `Config.dockHideDelayMs` (220) holds `revealed` true through a momentary loss:
`revealed: hoverHandler.hovered || hideDelay.running`.

Verified by driving the pointer with `hyprctl dispatch 'hl.dsp.cursor.move({ x = …, y = … })'`
(note the **table** argument — a positional `move(x, y)` errors) and logging the state: hover
held continuously from a bottom-centre entry, onto a tile, and across a far-left entry at
x=120 against a panel spanning only x≈815–1104.


---

## signalError is the only semantic colour: the measurements

*Originally `quickshell-qml.md` lines 624–635.*

🚨 **`signalError` is the ONLY semantic colour a bar widget may take.** Measured across all
eight colorsets, `SIGNAL_WARN` lands at **2.05** in rose-pine-dawn and 2.19 in
gruvbox-light, and `SIGNAL_INFO` at **2.80–3.31** in the light sets — under the 3:1 a graphic
owes, so a state drawn in either was *less* visible than the same state drawn neutral. Only
`SIGNAL_ERROR` clears 3:1 everywhere (worst 3.25, on `GROUND_BASE`). The battery's low band,
the idle inhibitor's second state, the unread bell and three dictation states all moved onto
their own **glyph**, which is what they should always have carried. `signalInfo` and `signalOk` are bound in
`Theme.qml` and drawn nowhere. `signalWarn` has exactly one site, and it is not a glyph:
`MetersWidget` tints its pill's **ground** with it at 18%. That is a different job with a
different floor, and `mise run lint:theme-contrast` measures both tints (and the battery's
14% one) as **composites** — a `Qt.alpha` ground is not a token, so no `PAIRS` row could
express it and no run measured either until 2026-09-13.


---

## Tinted pill 3.19: why it is accepted

*Originally `quickshell-qml.md` lines 637–647.*

🚨 **The tinted pill's number is 3.19 at worst (solarized-light, critical) and that is
ACCEPTED, not a defect to fix.** Three facts settle it, all measured 2026-09-13: the
**untinted** pill is already 3.64 in that theme and was already excused as a colorset
property; no alpha recovers it, because the limit as alpha → 0 is `INK_PRIMARY` on
`GROUND_BASE` = **4.13** there; and swapping the two solarized inks — the obvious palette fix
— reaches 4.39 on `GROUND_RAISED` in solarized-light and 4.49 on the warn tint in
solarized-dark, so it still misses while demoting Solarized's own body value to the quiet
role. Six of eight themes clear 4.5 with margin (worst 5.21, latte). The tint is also
load-bearing: a `signalError` **glyph** on a pill cannot replace it, because that pair is
2.81 on `groundRaised` in solarized-dark — which is why `PowerMenu` moved its tiles off that
tier.


---

## The hairline mis-mapping of 2026-09-01

*Originally `quickshell-qml.md` lines 673–677.*

🚨 **This was the fill-inert tier until 2026-09-01, on a mis-mapping.** Amendment A read the canvas's
`#313244` as "`surface0`, which is what `FILL_INERT` maps to". It does not: in
`themes/catppuccin-mocha/colors.sh`, `GROUND_RAISED` is `#313244` and `FILL_INERT` is
`#45475a`. The correction moved the hairline one tier the wrong way in all 8 themes. See the
hex table below — and never map a canvas colour by its LABEL.


---

## Contrast lint history: INHERENT, harvesting

*Originally `quickshell-qml.md` lines 687–698.*

🚨 **There is no `INHERENT` escape hatch any more.** It used to excuse five accent-as-text pairs
on the grounds that Waybar renders the same ratios — parity with an older tool is not a reason to
ship failing text, as design page 13 says outright. The rules changed instead, so those pairs are
no longer drawn rather than being excused. The script also carries a `BANNED` list, measured and
reported but asserted absent from the tree: a rule keeps its evidence, or the next reader
reintroduces what it forbids.

🚨 **Harvest by parenting, never by grepping colour lines.** Most `Theme.groundRaised` uses in
this tree are 1px hairlines and borders, not grounds. Reading `color: Theme.groundRaised` two
lines above an ink token and calling it a violation invents failures that are not on
screen — the 2026-09-01 pass started with five such suspects in `NotificationCentre`,
`PowerMenu` and `Launcher` and **all five were hairlines**.


---

## First contrast run: the four sites

*Originally `quickshell-qml.md` lines 704–718.*

What the first run found, all four fixed 2026-09-01 and all four invisible to the eye on the
one theme that happened to be applied:

| Site | Was | Ratio | Now |
|---|---|---|---|
| OSD progress fill on its track | `accentPrimary` on `bgTertiary` | **1.38** in solarized-light | track is `bgSecondary` |
| OSD dimmed fill | `fgMuted` on `bgTertiary` | **1.00** in both solarized themes — `INK_MUTED` *equals* `FILL_INERT` there | `fgSecondary` on `bgSecondary` |
| PowerMenu avatar initial | `accentPrimary` on `bgTertiary` | **1.46** solarized-dark | `fgPrimary` on `bgSecondary` |
| NotificationCard action outlines | `fgMuted` on `bgOverlay` | **2.18** solarized-light | `fgSecondary` |

The pattern in three of the four: **`fillInert` (`FILL_INERT`) is the trap tier**, which is
exactly why the role system makes it a *material* rather than a ground and forbids text on it
outright. Prefer `groundRaised` for any ground that has to carry something on top of it. The
2026-09-08 pass found a fourth instance the first one missed: the occupied workspace pill, at
**1.67** in solarized-light.


---

## Design source and canvas-colour mapping

*Originally `quickshell-qml.md` lines 742–805.*

### Reading the design source, not the transcription

The canvas lives in a Claude Design project (`1d494341-deaa-47cb-ac39-32ccb9c23862`) and is
readable through the `DesignSync` MCP tool: `list_files`, then `get_file`.

🚨 **The project was REWRITTEN on 2026-09-08 and every earlier artboard id is dead.** It is
now **fourteen pages** — `Shell-00-Index`, `Shell-01-Colour`, `Shell-02-Geometry`,
`Shell-03-Behaviour`, then one page per surface (`04-Bar`, `05-Launcher`, `06-Popovers`,
`07-Notifications`, `08-OSD`, `09-Session`, `10-Menu`, `11-Clipboard`, `12-Deferred`) and
`Shell-13-Accessibility`. The nine-file set (`Foundations`, `Bar - Dock`, `Composites`,
`Launcher - Menu`, `Panels`, `Session`, `Popovers`, `States`, `Proof`) and every id inside it
— `f-a`, `bar-a`, `pop-g`, `st-b`, `pf-a`, `comp-a`, `comp-b`, `pan-a`, `1a`–`1i` — no longer
resolves. `support.js` beside them is the generated dc-runtime and carries no design content.

Three pages state rules and nothing else does: **01** colour, type and motion; **02**
geometry; **03** behaviour. A surface page states only its own departures from those, so a
number found on a surface page that contradicts a foundation page is a **defect in the
design**, not a local override. There have been four such, all catalogued.

🚨 **Read `_research/archive/QUICKSHELL_DESIGN_AUDIT.md` Part 5 before implementing anything from a
page.** It records where the fourteen-page set contradicts itself, where its numbers are
wrong, and which of this tree's departures are deliberate. Parts 1–4 audit the dead nine-file
set and are kept for their measurements only.

⚠️ **`DesignSync` needs its own authorization.** A session without it fails with *"DesignSync
needs design-system authorization"*; `/design-login` grants it. Nothing in the repo can
substitute — plan on reading the source, not a transcription of it.

**Two surfaces this tree ships have no page in the current set**: the dock and the workspace
overview. Both are dormant (`Config.dockEnabled` / `Config.overviewEnabled` are `false`) and
both were declined in daily use, so their absence is consistent rather than an omission to
correct. They are not deleted, and they are not updated.

### 🚨 Map canvas colours by HEX, never by name

The canvas names three background tiers with Catppuccin-tier names; our colorset has four,
ordered differently. Matching on the name is how the hairline defect above happened. Verified
against `themes/catppuccin-mocha/colors.sh`:

| Canvas hex | Canvas label | **Our token** |
|---|---|---|
| `#1e1e2e` | bg-primary | `GROUND_BASE` |
| `#313244` | bg-secondary | **`GROUND_RAISED`** — hairlines, chip grounds |
| `#45475a` | (unused by the canvas) | `FILL_INERT` |
| `#181825` | bg-tertiary | **`GROUND_FLOAT`** — notification cards, tooltips |
| `#6c7086` | fg-muted | `INK_MUTED` (`#9399b2` here — a different value, same role) |

The same trap bit `Theme.qml`: **nine of its 24 fallbacks were the canvas's Mocha palette
rather than our colorset's** — including `accentPrimary`, mauve on the canvas and blue
(`#89b4fa`) in `colors.sh`. Fixed 2026-09-01. Copy a fallback from `colors.sh`, never from a
mockup.

⚠️ **The canvas's fourth background tier has no single equivalent here.** Amendment A said
`FILL_INERT` and `GROUND_FLOAT` (then `FILL_INERT` and `GROUND_FLOAT`) "are the same value in the
shipped themes (verified in `rose-pine-moon`)" — that generalised from **one** theme. Checked across all eight, they are
equal only in `rose-pine-moon`; mocha has `#45475a` vs `#181825`, latte `#bcc0cc` vs
`#e6e9ef`. The canvas's separate "visible on another monitor" and "occupied" grounds still
collapse to one, but because collapsing a tier beats inventing a colour — **not** because the
two tokens coincide. They mostly do not.

⚠️ **The "empty" workspace pill departs from the mockup on purpose.** The canvas gives it a
faint ground; ours stays transparent, because a ground makes it an elevated surface and the
contrast rule would then force `fg-primary` on the one state that has to recede. On the bar
ground, `fg-muted` is allowed.


---

## IPC callers

*Originally `quickshell-qml.md` lines 845–847.*

Callers today: `desktop/theme-switcher` (theme reload), `desktop/idle-toggle{,-nolock}` (idle
refresh, beside their existing `pkill -RTMIN+9 waybar`), and the `SUPER+B` binding in
`hypr/conf.d/quickshell.{lua,conf}`.


---

## The 2026-09-09 colorset rename

*Originally `quickshell-qml.md` lines 863–869.*

🚨 **The names are SEMANTIC ROLES, in the colorset too.** A token names a meaning or it names the
module that happens to spend it, and only the first kind can be reasoned about — a module-named
scheme cannot even *express* the requirement that a CPU readout and a failed service must stay
tellable apart. Until 2026-09-09 `Theme.qml` was a translation layer over module-named keys;
the colorsets were renamed on that date, so a property here now reads **the key of the same
name** and six keys with no consumer were deleted. `waybar.css`, `wofi.css`, `swaync.css.tmpl`,
`btop.theme` and `ghostty.conf` carry their own variables and were never involved.


---

## Six colorset keys deleted in the rename

*Originally `quickshell-qml.md` lines 905–909.*

**Six keys were deleted outright** in the rename, all with zero consumers: `ACCENT_BORDER`,
`ACCENT_PERFORMANCE`, `ACCENT_MEDIA`, `ACCENT_SECONDARY`, `ACCENT_ALTERNATIVE` and
`ACCENT_URGENT_SECONDARY`. The first four sat too near `signalFocus` or `signalError` to be
identity slots; the last was the battery's 20–30% band, which is `signalWarn`'s job — expressed
by the glyph, since no warn colour clears 3:1. 24 keys became 18.


---

## Theming tail (stale Waybar pointer removed)

*Originally `quickshell-qml.md` lines 911–920.*

Contrast rules from `themes/CLAUDE.md` are measured by `mise run lint:theme-contrast` (see
above) across all 8 colorsets; everything that task's hand-harvested pair table does not cover
is still by-hand discipline here. The
module → semantic-colour mapping this bar follows is `waybar/CLAUDE.md`'s table.

The closest thing to enforcement is the `theme-consistency-reviewer` subagent, which takes this
tree as a second review target: literal hex (only `Theme.qml`'s fallbacks are allowed), literal
font name (only `Config.qml.tmpl`, and only through `globals.yaml`), and `Theme.inkSecondary` on
a lit ground. It judges the third against `BarWidget`'s `grounded` ternary, so an override that
pins one fixed rest colour is the finding.
