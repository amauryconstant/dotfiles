# Quickshell Shell — Integration Plan

**Status**: Proposed. Nothing built yet.
**Decision**: Approach **A** (build our own, Omarchy 4 as design reference) — confirmed from
`_research/QUICKSHELL_DESKTOP_RESEARCH.md`, which left the approach leaning but unchosen.
**Scope**: bar → OSDs → notifications → launcher/power menu. Lock screen and idle daemon
stay out.
**Prerequisite work**: none. This plan is deliberately decoupled from the P2
`colors.toml` item in `_plans/OMARCHY.md` (see "Theming bridge").

Created 2026-08-30.

---

## Why now, and what changed

`_plans/OMARCHY.md` records the whole Omarchy 4 shell as **Skipped** — correctly, because
`omarchy-shell` ships as Arch packages under `/usr/share/omarchy` behind an ALPM guard.
That skip is about *adopting their artifact*. It says nothing about building our own, which
is what this plan proposes.

Three things make the timing better than the research docs assumed:

1. **Quickshell 0.3.1 already solves the Waybar Lua blocker.** `_plans/OMARCHY.md` P1
   ("Hyprland Lua config is the forward path") is blocked on Waybar ≥ 0.16.0 shipping
   PR #5013, merged 2026-05-04 and still in no tagged release. Quickshell's
   `HyprlandWorkspace.activate()` already branches on `Hyprland.usingLua` and emits
   `hl.dsp.focus({ workspace = "…" })` in Lua mode. A Quickshell bar removes the blocker
   without waiting on anyone. See "Verified facts" #5.
2. **Omarchy 4 is a shipped, readable reference** for a curated-and-semantically-themed
   Quickshell shell with no compiled components — the combination the research doc was
   written to say did not exist.
3. **Three of the four "blockers" in `QUICKSHELL_COMPONENT_MAPPING.md` are not real.**
   They were written against an incomplete API picture. See below.

---

## Verified facts (2026-08-30)

Checked against the installed `quickshell 0.3.1-1` and the vendored source at
`_ai/quickshell/`. **These correct the research docs** — several of their code samples do
not compile as written.

| # | Fact | How verified |
|---|------|--------------|
| 1 | Real module URIs are `Quickshell`, `Quickshell.Io`, `Quickshell.Wayland`, `Quickshell.Hyprland`, `Quickshell.WindowManager`, `Quickshell.Widgets`, `Quickshell.Networking`, `Quickshell.Bluetooth`, `Quickshell.Services.{Notifications,Mpris,Pipewire,UPower,SystemTray,Polkit,Pam,Greetd}` | `grep 'URI ' _ai/quickshell/src/**/CMakeLists.txt`; `ls /usr/lib/qt6/qml/Quickshell/` |
| 2 | Singletons are **not** auto-available. Each is `QML_SINGLETON` inside its own module and needs that module imported. Hyprland types live in `Quickshell.Hyprland`, **not** `Quickshell.WindowManager` (that is the newer compositor-agnostic layer) | `QML_SINGLETON` grep over `src/**/*.hpp` |
| 3 | Singleton names are `Hyprland`, `WindowManager`, `Mpris`, `UPower`, `PowerProfiles`, `SystemTray`, `Networking`, `Bluetooth`, `DesktopEntries`, `Quickshell` — **not** `StatusNotifier`, `NetworkManager`, `PipeWire` as written in `QUICKSHELL_QML_API.md` | `QML_NAMED_ELEMENT` grep |
| 4 | `Quickshell.Io` provides `Process` (with `stdout`/`stderr` → `SplitParser`, `StdioCollector`), `Socket`, `SocketServer`, `FileView` (`watchChanges: true`), `JsonAdapter`, `IpcHandler` | `src/io/{process,socket,datastream,fileview,ipchandler,jsonadapter}.hpp` |
| 5 | **Lua-mode workspace clicks work today.** `Hyprland.usingLua` is set from `j/status` → `configProvider == "lua"`; `HyprlandWorkspace.activate()` branches on it | `src/wayland/hyprland/ipc/workspace.cpp:153`; confirmed present in the *installed* binary: `strings /usr/bin/quickshell \| grep -F 'hl.dsp'` → `hl.dsp.focus({ workspace = "%1" })` |
| 6 | Only `activate()` is translated. A raw `Hyprland.dispatch("…")` is sent verbatim, so **every other dispatcher we call must branch on `usingLua` ourselves** | `src/wayland/hyprland/ipc/connection.cpp:202` — `dispatch()` just prefixes `dispatch ` and writes |
| 7 | `DesktopEntries` is a built-in singleton (parsed `.desktop` index with icons) | `src/core/desktopentry.hpp` |
| 8 | Configs are discovered as `~/.config/quickshell/<name>/shell.qml`. **A bare `~/.config/quickshell/shell.qml` disables subdirectory discovery entirely** | `quickshell --help`, Config Selection group |
| 9 | `Singleton` is a QML element of the `Quickshell` module — singleton QML files need no `qmldir` | `src/core/singleton.hpp:15` |
| 10 | `qmllint`, `qmlformat`, `qmlls` are already installed (`qt6-declarative`, a quickshell dependency) | `pacman -Qo /usr/lib/qt6/bin/qmllint` |
| 11 | No native backlight module exists. Brightness stays a `Process` call to our own `brightness-set` (already DDC/CI-aware) | no `backlight`/`brightness` under `src/` |

**Consequences for `_research/QUICKSHELL_COMPONENT_MAPPING.md`** — three of its four
"Integration Challenges" are void:

- *"No `exec-persistent` analog"* → `Process { stdout: SplitParser { onRead: … } }` is an
  exact analog. Kanata's TCP socket is `Socket`; `voxtype status --follow` is `Process`.
- *"No `.desktop` parser"* → `DesktopEntries`.
- *"Theming bridge mechanism undecided"* → decided below.

Only the backlight wrapper survives, and it is a one-liner.

`_ai/quickshell/` tracks upstream, which may be **ahead of the installed 0.3.1**. Any API
this plan relies on must be confirmed against the installed build (qmltypes, `strings`, or a
runtime smoke test) before it is designed around — not against the subtree alone.

---

## Scope

**In** (in phase order):

1. Bar — replaces Waybar
2. Volume / brightness OSDs — new; we have none today
3. Notifications — replaces swaync (daemon, popups, history, DND)
4. Launcher — replaces Wofi
5. Power menu — replaces wlogout
6. *Optional* retirement of the tools 1–5 replaced — Phase 6, per tool, never automatic

"Replaces" means *takes over the job*, not *gets uninstalled*. Removal is Phase 6 and is
optional; Wofi is expected to stay regardless.

**Out, deliberately**:

| Not doing | Why |
|---|---|
| Lock screen (hyprlock) | Security-sensitive, lowest reward, lockout risk. `WlSessionLock` + `Quickshell.Services.Pam` make it *possible*; that is not a reason |
| Idle daemon (hypridle) | Recently reworked and correct (`hypridle@.service`, lock-change hook). Nothing to gain |
| Polkit agent | polkit-gnome works; the Qt agent path already caused crashes here (`autostart.lua`) |
| Wallpaper (awww) | Works, unrelated to shell widgets |
| Plugin system / `manifest.json` | One user, one machine class. YAGNI |
| `shell.json` layout state | Omarchy needs runtime layout editing for its users. Our layout is a file we edit |
| Wallpaper-dynamic theming | Opposite of the curated model |
| Clipboard manager, emoji picker, control panels | cliphist, wofi and the existing menus cover these |

---

## Architecture decisions

### Deployment shape

Source: `private_dot_config/quickshell/dotfiles/` → `~/.config/quickshell/dotfiles/`,
launched as `quickshell -c dotfiles`.

- Named subdirectory, never a root `shell.qml` (fact #8) — a root file would break config
  discovery for anything else.
- voxtype's OSD tree lives at `~/.local/share/voxtype/quickshell` and is installed by
  `voxtype setup quickshell`, not chezmoi. No collision, and it keeps running as its own
  instance.
- Config name `dotfiles` matches the repo's own namespace (`private_dot_config/dotfiles/`,
  the `dotfiles` CLI).

Layout inside:

```
quickshell/dotfiles/
├── shell.qml            # root Scope: bar + OSDs + notification server
├── Theme.qml            # Singleton — colors from themes/current/colors.sh
├── Config.qml           # Singleton — sizes, fonts, chassis-dependent bits (.tmpl)
├── bar/Bar.qml          # PanelWindow + layout
├── bar/widgets/*.qml    # one file per widget
└── osd/*.qml
```

Only files that genuinely need template data get `.tmpl` — `Config.qml.tmpl` for
`.chassisType` and `.globals.guiFont`. Widgets stay static QML: gating a widget on chassis
belongs in one `Config` property, not in eight templates.

### Theming bridge

**Decision: a `Theme` singleton that reads `~/.config/themes/current/colors.sh` at runtime
and parses it with a regex.** No new per-theme file, no new template engine, no dependency
on the `colors.toml` project.

Rationale — `colors.sh` is already the format-neutral colorset. It is machine-generated,
header-marked *"DO NOT EDIT MANUALLY"*, uniform (`readonly KEY="#hex"`), and carries exactly
the 24 semantic variables the QML needs. Parsing it is ~15 lines:

```qml
// Theme.qml (sketch)
Singleton {
  property var c: ({})
  FileView {
    id: file
    path: `${Quickshell.env("HOME")}/.config/themes/current/colors.sh`
    watchChanges: true
    onFileChanged: reload()          // watchChanges only signals; it does not re-read
    onLoaded: {
      const m = {};
      for (const line of text().split("\n")) {
        const r = /^readonly\s+([A-Z_]+)="(#[0-9a-fA-F]{3,8})"/.exec(line);
        if (r) m[r[1]] = r[2];
      }
      root.c = m;
    }
  }
  readonly property color bgPrimary: c.BG_PRIMARY ?? "#1e1e2e"  // fallback, never crash
}
```

The alternatives, and why not:

- *A 9th per-theme file (`quickshell.json` × 8 themes)* — matches the repo convention
  (`themes/CLAUDE.md`: add the file to every theme dir) but costs 8 hand-maintained files
  forever, for data that already exists in `colors.sh`.
- *Wait for the P2 `colors.toml` + template-rendering project* — that item is High effort
  and touches all 8 themes and ~20 files each. Blocking a bar on it is backwards. If it
  lands later, **only `Theme.qml` changes**: swap the path and the parser.

**Reload on theme switch**: the switch swaps the `themes/current` *symlink*, so an inotify
watch on the resolved path does not fire. `watchChanges` is belt-and-braces for hand edits;
the real signal is explicit. Add one line to `reload_applications()` in
`executable_theme-switcher.tmpl`, beside the existing waybar/swaync/ghostty reloads:

```sh
quickshell ipc call theme reload 2>/dev/null || true
```

serviced by an `IpcHandler { target: "theme" }` in `shell.qml` whose `reload` function calls
`FileView.reload()`. `|| true` because the shell may not be running.

**Contrast rules still apply.** `themes/CLAUDE.md` mandates `@fg-primary` on
`@bg-secondary`/`@bg-tertiary`/`@bg-overlay`. QML gets no automatic enforcement, so the
widget set must follow the same mapping by hand, and `theme-consistency-reviewer` should be
extended to read the QML tree once it exists.

### Hyprland dispatch discipline

Per facts #5/#6: **use `workspace.activate()` and the other object methods wherever one
exists**; they carry the Lua translation. Where we must call `Hyprland.dispatch()` directly,
branch:

```qml
Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.…` : "…")
```

Every raw dispatch is a Lua-cutover liability. Keep them countable — one helper in
`Config.qml`, not scattered string literals.

### Validation

Mirrors the existing `lint:lua` pattern in `.mise/config.toml`:

| Task | Command |
|---|---|
| `lint:qml` | `qmllint -I /usr/lib/qt6/qml $(find private_dot_config/quickshell -name '*.qml')` |
| `format:qml` | `qmlformat -i …` (`--check` under lint) |
| `lint:qml-tmpl` | render `*.qml.tmpl` through `chezmoi execute-template --source …`, pipe to `qmllint`/`qmlformat --check` — same shape and same one-branch-only limitation as `.mise/tasks/lint/lua-tmpl-file.sh` |

`qmllint` needs `-I /usr/lib/qt6/qml` to resolve the Quickshell modules; without it every
`import Quickshell` is an error. Wire `lint:qml` into `[tasks.lint].depends`; keep any task
needing a *running* Hyprland out of it, as `lint:hypr-lua` already is.

### Gating and coexistence

- `.chezmoidata/features.yaml` gains `quickshell_shell: { enabled: false }`, matching the
  existing `voxtype`/`restic`/`kanata` shape.
- Autostart is added to `conf/autostart.lua` and `conf/autostart.conf` **gated on that
  flag** — both, until the `.conf` set is retired (`_guides/HYPRLAND_LUA_CUTOVER.md`).
- Waybar keeps running throughout. Both bars anchor top and stack via layer-shell exclusive
  zones — visually ugly, perfectly functional for A/B.
- Rollback at every phase: flip the flag, `chezmoi apply`. Repo-level escape hatch is
  unchanged (`git checkout HEAD~1 && chezmoi apply`).

---

## Phases

### Phase 0 — Skeleton, theme bridge, one widget

Prove the whole pipeline end to end on the cheapest possible payload.

- `shell.qml` with a `PanelWindow` (top, full width, 30px) containing only a clock
- `Theme.qml` + `Config.qml.tmpl`
- `IpcHandler` for theme reload; `theme-switcher` line added
- `features.yaml` flag; gated autostart; `.chezmoiignore` untouched
- mise `lint:qml` / `format:qml` / `lint:qml-tmpl` tasks + pre-commit dispatch

**Exit**: bar renders above Waybar; `theme switch` across all 8 themes recolors it live with
no restart; `mise run lint` passes; flag off → nothing deployed.

### Phase 1 — Bar to Waybar parity

Widget by widget, each landing independently. Source mapping:

| Widget | Quickshell surface | Notes |
|---|---|---|
| Workspaces | `Hyprland.workspaces`, `workspace.activate()` | Carries Lua translation — the whole reason the bar goes first |
| Window title | `Hyprland.activeToplevel.title` | truncate 50 |
| Clock | `SystemClock` | Phase 0 |
| Audio | `Quickshell.Services.Pipewire` | scroll = volume, click = pavucontrol |
| Media | `Mpris` | |
| Tray | `SystemTray` | |
| Battery / power profile | `UPower`, `PowerProfiles` | laptop only, via `Config` |
| Network | `Networking` | native module — no shell-out |
| Bluetooth | `Bluetooth` | native module |
| Backlight | `Process` → `brightness-set` | fact #11 |
| kanata layer | `Socket` → kanata TCP | replaces the `exec-persistent` wrapper |
| voxtype | `Process` → `voxtype status --follow` | `SplitParser` |
| idle indicator | `Process` → `idle-indicator` | |
| Notification bell | deferred to Phase 4 | keep the swaync widget shelling out until then |

**Exit**: every Waybar module has a working counterpart; a week of daily use with the
Quickshell bar as the primary; `SUPER+B` (`waybar-toggle`) repointed or paired so either bar
can be hidden. **Waybar is not removed** — retirement is Phase 6, optional and separately
approved, per the same gate `_plans/OMARCHY.md` P1 applies to the `.conf` set.

**What Waybar is worth after this phase** — the honest version, because Phase 2 changes it.
Switching bars removes the *impact* of the Waybar/Lua incompatibility, not the
incompatibility: Waybar's workspace clicks stay broken in Lua mode whether or not a
Quickshell bar exists. They simply stop mattering once nothing clicks them. So from Phase 2
onward Waybar is a **degraded** fallback — it renders correctly (its Hyprland modules read
`socket2` events, which are unaffected) but its workspace clicks are dead. Adequate as a
"the QML bar crashed, show me something" net; not a full rollback target. The real rollback
target for Phase 2 is the `.chezmoiignore` block, not Waybar.

### Phase 2 — Hyprland Lua cutover

The payoff. **Gate**: not "Waybar retired" — only "Waybar no longer relied on for workspace
clicks", which Phase 1 exit already satisfies. Waybar may keep running, degraded (see above).

**Prerequisite: audit `hyprctl dispatch` across the whole tree.** Waybar was only ever the
*named* blocker, and it is the only one either `_research/HYPRLAND_LUA_AUDIT.md` or
`_guides/HYPRLAND_LUA_CUTOVER.md` scopes — the audit reconciled the 21 `conf/X.conf` ↔
`conf/X.lua` pairs, which is config-side only. Our own script fleet was never in scope, and
it holds ~12 call sites on the same legacy dispatch-string syntax that Lua mode changed:

| File | Sites | Dispatchers |
|---|---|---|
| `private_dot_local/lib/scripts/desktop/executable_session-restore` | 8 | workspace/window placement |
| `private_dot_local/lib/scripts/desktop/executable_recover-workspaces` | 1 | |
| `private_dot_local/lib/scripts/desktop/executable_launch-or-focus` | 1 | |
| `private_dot_config/hyprwhenthen/scripts/executable_float-and-center.sh` | 4 | `togglefloating`, `resizewindowpixel`, `focuswindow`, `centerwindow` |
| `private_dot_config/voxtype/config.toml.tmpl` | 3 | `submap` |
| `private_dot_config/hypr/hypridle{,-nolock}.conf.tmpl` | 4 | `dpms off` / `dpms on` |
| `private_dot_config/wlogout/layout` | 1 | via `session-save` |

A Quickshell bar fixes none of these. **Inference, not verified**: they break the same way
Waybar's clicks do. Quickshell's `activate()` branches on `usingLua` because the IPC
dispatch *string format* changes with config provider, and `hyprctl` writes to the same
`.socket.sock` — but this has not been confirmed, because confirming it requires being in
Lua mode. Settle it first; it may turn out `hyprctl` keeps parsing the legacy form, in which
case this prerequisite collapses to nothing.

Blast radius if the inference holds: session restore, window automation, voxtype submaps,
and idle DPMS. The last two are the dangerous ones — a dead `dpms on` means a black screen
that does not come back.

- [ ] Verify whether `hyprctl dispatch <legacy string>` still works under `configProvider = "lua"`
- [ ] If it does not: convert the ~12 sites, and fold the finding into `_research/HYPRLAND_LUA_AUDIT.md`
- [ ] Delete the `.chezmoiignore` TEMP block; `chezmoi apply`
- [ ] Follow `_guides/HYPRLAND_LUA_CUTOVER.md` (hold status, steps, rollback, hyprsplit coupling)
- [ ] Verify workspace clicks in Lua mode, and every raw `dispatch()` we shipped in Phase 1
- [ ] Update `_plans/OMARCHY.md` P1: the blocker was routed around, not resolved upstream

**Exit**: Lua entry point live across a reboot and a `hyprctl reload`; workspace clicks
working from the Quickshell bar; idle DPMS off *and back on*; voxtype submaps entering and
resetting; a session restore round-trip.

**Rollback**: restore the `.chezmoiignore` block — the `.conf` set is still deployed.

### Phase 3 — OSDs

Volume and brightness overlays. Pure addition: we have none today outside voxtype, so
nothing can regress. Reuses the Pipewire binding and `brightness-set` from Phase 1.

**Exit**: volume/brightness keys show a themed OSD that fades; no interaction with the
voxtype instance.

### Phase 4 — Notifications

The largest single component. `NotificationServer` from
`Quickshell.Services.Notifications`, plus popups, history panel, and DND.

- swaync must be **stopped** before the Quickshell server can own
  `org.freedesktop.Notifications` — one D-Bus name, one owner. swaync is D-Bus-activated
  via a systemd user service (`autostart.lua` warns against `exec-once`), so the cutover is
  `systemctl --user mask/unmask swaync`, not a config toggle. This is the first phase where
  coexistence is impossible; it needs its own flag and a tested revert.
- DND has no native support — a `Theme`-style property plus a filter, persisted to
  `$XDG_RUNTIME_DIR` or `~/.local/state`.
- `SUPER+SHIFT+N` moves from `swaync-client --toggle-panel` to `quickshell ipc call`.

**Exit**: notifications from a spread of real senders (Nextcloud, notify-send, browser,
`ui_notify_focused`) render, group, persist in history, and survive a shell restart; DND
suppresses and replays.

**Rollback**: unmask swaync, revert the binding.

### Phase 5 — Launcher and power menu

Small, and last because Wofi and wlogout are not hurting anyone.

- Launcher: `DesktopEntries` + a `TextField` + fuzzy filter. Note Wofi also serves
  `cliphist` and `--dmenu` callers (`applications.lua.tmpl`) — those keep using Wofi unless
  a dmenu-compatible IPC entry point is built. Do not remove Wofi.
- Power menu: 6 buttons over the existing `session-save` / `systemctl` paths. Keep the
  confirmation behaviour of the current `wlogout` wrapper.

**Exit**: `SUPER+D` and `SUPER+SHIFT+Q` land on the Quickshell versions; Wofi stays
installed for dmenu use.

### Phase 6 — Cleanup of replaced tooling (OPTIONAL)

**Not a phase in the sense the others are.** Phases 0–5 are complete without it, and doing
none of it is a valid end state: the replaced tools cost a package each and a config
directory each, and they are the fallback if a Quickshell phase turns out worse in daily use
than it looked at exit. Retirement is a separate, explicit decision per tool, taken after
the replacement has *lived* — not on the day its phase exits.

Same gate `_plans/OMARCHY.md` P1 puts on the Hyprland `.conf` set: keep both until the new
path is confirmed across a reboot and a `hyprctl reload`, and remove only on an explicit
go-ahead.

Order is easiest-to-reverse first.

| Tool | Prerequisite | What to remove | Keep instead? |
|---|---|---|---|
| **wlogout** | Phase 5 lived a month | `packages.yaml` entry, `private_dot_config/wlogout/`, `desktop/executable_wlogout`, `wlogout.css` × 8 themes | No. Fully replaced |
| **swaync** | Phase 4 lived a month | `packages.yaml`, `private_dot_config/swaync/`, the mask, `swaync.css.tmpl` × 8 themes, `desktop/executable_voxtype-waybar-status` swaync bits | No. Fully replaced |
| **Waybar** | Phase 2 done, Phase 1 lived a month | `packages.yaml`, `private_dot_config/waybar/` (504-line config + 625-line CSS), `desktop/executable_waybar-toggle`, `executable_waybar-style`, `voxtype-waybar-status`, autostart line, `SUPER+B` rebind, `waybar.css` × 8 themes | No — but see the `colors.sh` note below |
| **Wofi** | Never, on current scope | — | **Keep.** Still serves `cliphist` and every `--dmenu` caller (`applications.lua.tmpl`). Only removable if a dmenu-compatible IPC entry point is built, which is out of scope |

**The `waybar.css` trap.** `colors.sh` is generated *from* `waybar.css` — its own header says
so — and the `Theme` singleton reads `colors.sh`. Deleting Waybar's config without touching
that chain leaves the source of truth for every theme inside the config directory of a tool
that is no longer installed. Do not remove `waybar.css` on the same change as the Waybar
package. Either invert the chain first (that is the P2 `colors.toml` item in
`_plans/OMARCHY.md`) or keep `waybar.css` as an orphaned, clearly-commented colorset until
that lands. This is the one cleanup step with a real ordering constraint.

Per tool, the checklist is the same:

- [ ] `packages.yaml` entry removed; `package-manager sync --prune` reviewed before running
- [ ] Config directory and per-theme files removed across **all 8 themes** (`themes/CLAUDE.md`
      requires the set stay uniform — a file removed from one must go from all)
- [ ] Wrapper scripts, keybindings (`.conf` *and* `.lua`), autostart entries, menu entries
- [ ] Docs: `themes/CLAUDE.md` file list, `hypr/conf/bindings/README.md`, root `CLAUDE.md`
      Quick Reference (it names Waybar and Wofi as the desktop stack)
- [ ] One commit per tool, so a revert is one `git revert`

---

## Risks

| Risk | Mitigation |
|---|---|
| Subtree API ahead of installed 0.3.1 | Confirm every relied-on API against the installed build (qmltypes / `strings` / smoke test), as done for fact #5 |
| A Quickshell update breaks the config | Quickshell is a versioned `extra` package, not `-git`; pin nothing, but keep Waybar until Phase 1 exit and read `changelog/` before upgrading |
| Raw `dispatch()` strings break at Lua cutover | Fact #6 — funnel them through one helper, audit before Phase 2 |
| The Lua cutover's real blast radius is wider than Waybar | ~12 `hyprctl dispatch` sites in our own scripts/configs, unaudited by either Lua doc. Phase 2 prerequisite; `dpms on` and voxtype submaps are the dangerous ones |
| Cleanup removes a fallback too early | Phase 6 is optional, per-tool, and gated on the replacement having lived a month, not on its phase exiting |
| `waybar.css` deleted while it is still the colorset source of truth | `colors.sh` is generated from it and `Theme.qml` reads `colors.sh`. Phase 6 ordering constraint — invert the chain first or keep the file orphaned |
| Notification cutover is not reversible in place | Phase 4 owns its own flag, and the revert (`systemctl --user unmask swaync`) is tested before the cutover, not after |
| Theme contrast rules unenforced in QML | Follow the `themes/CLAUDE.md` mapping by hand; extend `theme-consistency-reviewer` to the QML tree |
| Scope creep toward a full Omarchy-style shell | The "Out" table is the contract. Anything in it needs an explicit decision to move |
| Two quickshell instances (ours + voxtype) | Separate configs, separate instance ids; verified non-overlapping paths. Watch memory once both run |

---

## Documentation to update as phases land

- `_research/QUICKSHELL_QML_API.md` — module URIs, singleton names, the "no import needed"
  claim, the `Quickshell.Io` omission (facts #1–#4, #7)
- `_research/QUICKSHELL_COMPONENT_MAPPING.md` — three of four Integration Challenges are void
- `_research/QUICKSHELL_DESKTOP_RESEARCH.md` — Approach A is chosen; status is no longer
  "exploration only"
- `_plans/OMARCHY.md` — P1 Lua item gains the route-around; the v4.0.0 shell skip gains a
  pointer here so "skipped" is not read as "never"
- `_research/HYPRLAND_LUA_AUDIT.md` — the audit is config-side only; the `hyprctl dispatch`
  script fleet (Phase 2 prerequisite) belongs in it either way the verification lands
- `_guides/HYPRLAND_LUA_CUTOVER.md` — the hold reason changes from "waiting on Waybar
  0.16.0" to "waiting on the Quickshell bar"; add the degraded-Waybar note
- Root `CLAUDE.md` Quick Reference and `themes/CLAUDE.md` file list — only at Phase 6, per
  tool actually removed
- `.claude/rules/` — a `quickshell-qml.md` once the tree exists, mirroring
  `hyprland-lua.md` (globals, formatting, lint scope, validation limits)
- `private_dot_config/quickshell/CLAUDE.md` — location-specific patterns
- `private_dot_config/themes/CLAUDE.md` — that QML consumes `colors.sh` at runtime, and
  what that implies for the contrast rules
