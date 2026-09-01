# Quickshell Shell — Integration Plan

**Status**: Phases 0, 1, **2**, 2.5, 3 and 5 complete on branch `quickshell` (floating bar at
Waybar module parity, volume/brightness OSDs, launcher and power menu on the primary keys; the two
bars are mutually exclusive by config; Hyprland running the Lua entry point across a reboot). Phase 4 (notifications)
and 6 not started. See **Amendment A** at the end of this file
for the layout language adopted 2026-08-31 (structure only — colours, fonts and glyphs are
unchanged), which revises the phase list.
**Decision**: Approach **A** (build our own, Omarchy 4 as design reference) — confirmed from
`_research/QUICKSHELL_DESKTOP_RESEARCH.md`, which left the approach leaning but unchosen.
**Scope**: bar → OSDs → notifications → launcher/power menu. Lock screen and idle daemon
stay out (Amendment A's canvas draws a lock screen and a clipboard panel; both still declined).
**Prerequisite work**: none. This plan is deliberately decoupled from the P2
`colors.toml` item in `_plans/OMARCHY.md` (see "Theming bridge").

Created 2026-08-30. Amended 2026-08-31.

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
| 10 | `qmllint`, `qmlformat`, `qmlls` are installed, but **`/usr/bin/qmllint` is the Qt5 one** (`qt5-declarative`, a syntax-only verifier). The usable Qt6 tools are at `/usr/lib/qt6/bin/` and are **not on `$PATH`** | `pacman -Qo $(command -v qmllint)` → `qt5-declarative 5.15.19`; `/usr/lib/qt6/bin/qmllint --version` → `6.11.2` |
| 11 | No native backlight module exists. Brightness stays a `Process` call to our own `brightness-set` (already DDC/CI-aware) | no `backlight`/`brightness` under `src/` |
| 12 | Qt6 `qmllint` **exits 0 even when it emits warnings** (`--max-warnings` defaults to `-1`). `-W 0` makes any warning fatal | unknown property → warning printed, `exit=0`; with `-W 0` → `exit=255` |
| 13 | `-W 0` **false-positives on `PanelWindow`** (`Type PanelWindow is not creatable [uncreatable-type]`) — it is registered through the `Quickshell._Window` indirection. The lint task needs an empirically-derived category exemption list | ran against a `Scope { PanelWindow { … } }` sample |
| 14 | `qmlformat` 6.11 has **no `--check`/`--verify`** (only `-i`, `-t`, `-w`, `-n`). A format check must be `qmlformat "$f" \| diff -q - "$f"`. No `.qmlformat.ini` exists → QML defaults to **4 spaces**, unlike the Lua tree's tabs | `/usr/lib/qt6/bin/qmlformat --help` |
| 15 | `-I /usr/lib/qt6/qml` is **not needed** — it is already the default import path; Quickshell modules resolve without it | `qmllint` on a `Quickshell`/`Quickshell.Io`/`Quickshell.Hyprland` sample → `exit=0` both with and without `-I` |
| 16 | `quickshell ipc` defaults to config name **`default`** when `--config` is absent. Ours is `dotfiles`, and voxtype runs a second instance, so every IPC call must name its config | `quickshell --help`, Config Selection: *"If `--config` is not passed, 'default' will be assumed."* |
| 17 | **`.chezmoidata/` files cannot be templates.** A `.tmpl` suffix is a hard error (`.tmpl: unknown format`, exit 1, whole tree fails); `{{ }}` inside a plain data file is emitted **literally**. Gating conditions must live in the *consumer* (or in `.chezmoiignore`, which is templated) | throwaway source dir + `chezmoi data --source` |

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
the real signal is explicit. Add one line to `reload_applications()`
(`private_dot_local/lib/scripts/desktop/executable_theme-switcher.tmpl:76`), beside the
existing waybar/swaync/ghostty reloads:

```sh
quickshell -c dotfiles ipc call theme reload 2>/dev/null || true
```

serviced by an `IpcHandler { target: "theme" }` in `shell.qml` whose `reload` function calls
`FileView.reload()`. `|| true` because the shell may not be running.

**`-c dotfiles` is load-bearing** (fact #16): without it the call targets config name
`default`, which does not exist, and voxtype's instance means "just pick one" is wrong too.
Confirm exact flag placement against a running instance — `ipc` carries its own Config
Selection option group, so `quickshell ipc -c dotfiles call …` may be the accepted form.

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

Mirrors the existing `lint:lua` pattern in `.mise/config.toml`. **Three traps here, all
verified — facts #10, #12, #14. Each one independently reduces the lint task to a no-op that
reports success.**

🚨 **Always the absolute path `/usr/lib/qt6/bin/qmllint`, never bare `qmllint`.** The bare
name resolves to Qt5's syntax-only verifier, which exits 0 on `NoSuchType {}` and on unknown
properties alike. Pin it once in `[env]` or a task variable so no site can drift back.

| Task | Command |
|---|---|
| `lint:qml` | `/usr/lib/qt6/bin/qmllint -W 0 <exemptions> $(find private_dot_config/quickshell -name '*.qml')` |
| `format:qml` | `/usr/lib/qt6/bin/qmlformat -i …` — check form is `qmlformat "$f" \| diff -q - "$f"` (no `--check` exists) |
| `lint:qml-tmpl` | render `*.qml.tmpl` through `chezmoi execute-template --source …`, pipe to the same two — same shape and same one-branch-only limitation as `.mise/tasks/lint/lua-tmpl-file.sh` |

`<exemptions>` is deliberately unresolved here: bare `-W 0` fails on `PanelWindow`
(fact #13), so Phase 0 must derive the minimum set empirically against a real config and
record it with a comment per category. Do **not** widen it to silence unrelated noise — an
over-broad exemption list is the fourth way this task becomes a no-op.

`-I /usr/lib/qt6/qml` is unnecessary (fact #15); omit it rather than cargo-cult it.

Wire `lint:qml` into `[tasks.lint].depends`; keep any task needing a *running* Hyprland out
of it, as `lint:hypr-lua` already is.

**Prove the linter fails before trusting it.** `.mise/config.toml` already carries this
lesson for `find -exec` ("returns 0 even when the command fails, so a broken template would
pass silently"). Same class of bug, three new vectors. Phase 0 exit requires a deliberately
broken `.qml` making `mise run lint:qml` exit non-zero — a passing lint on good code proves
nothing.

### Gating and coexistence

- `.chezmoidata/features.yaml` gains `quickshell_shell: { enabled: false }`, matching the
  existing `voxtype`/`restic`/`kanata` shape. It stays **plain YAML** — data files cannot be
  templates (fact #17), so the `{{ if }}` reading it lives in a consumer, never here.
- Autostart is a **`conf.d/` drop-in gated in `.chezmoiignore`**, not an edit to
  `conf/autostart.{lua,conf}`. New `conf.d/quickshell.lua` + `conf.d/quickshell.conf` twins
  (both, until the `.conf` set is retired — `_guides/HYPRLAND_LUA_CUTOVER.md`):

  ```
  {{ if not .features.quickshell_shell.enabled }}
  .config/hypr/conf.d/quickshell.lua
  .config/hypr/conf.d/quickshell.conf
  {{ end }}
  ```

  Why this over templating `autostart.lua`: both entry points already glob `conf.d` and
  tolerate absence (`hyprland.conf.tmpl:25` `source = ~/.config/hypr/conf.d/*.conf`;
  `require_all.files()` in `hyprland.lua.tmpl:46`), so "flag off" means the file is simply
  never deployed — no branch to get wrong. `.chezmoiignore` is already templated and proven
  (the `chassisType`/steam block). And it renames no live, deployed file. The cost is that
  autostart is split across two locations; `conf/autostart.lua` should carry a pointer
  comment. Structural precedent: `conf.d/voxtype-submap.{lua,conf}`.
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
- `IpcHandler` for theme reload; `theme-switcher` line added (with `-c dotfiles`)
- `features.yaml` flag; `conf.d/quickshell.{lua,conf}` drop-ins; **`.chezmoiignore` gains the
  gating block** (revised — it is the gate, not untouched)
- mise `lint:qml` / `format:qml` / `lint:qml-tmpl` tasks + pre-commit dispatch, using the
  absolute Qt6 tool paths and a derived `-W 0` exemption list

Roughly ten files across five subsystems — larger than "one widget" implies. Land it as
separate commits (QML tree · theme bridge + theme-switcher · gating · lint tooling) so a
revert is surgical.

**Exit**: bar renders above Waybar; `theme switch` across all 8 themes recolors it live with
no restart; `mise run lint` passes **and a deliberately broken `.qml` makes it fail**; flag
off → `chezmoi apply` deploys nothing.

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

A Quickshell bar fixes none of these. **Verified 2026-09-01: they do break**, and the table
above undercounts — the real figure is **29 call sites across 10 files** (it missed the shared
hypridle template and `window-pop`'s six-dispatch `--batch`). Settled from Hyprland `v0.56.2`
source, not from a nested session: `dispatchRequest` (`src/debug/HyprCtl.cpp:1126`) forks on
config provider at line 1130 and splices the text into `return hl.dispatch(<verbatim>)`, so the
legacy `m_dispatchers` lookup at line 1149 is unreachable in Lua mode, with no fallback.
`hyprctl --batch` re-enters the same handler per fragment. Full evidence, the per-site
replacement table and the two open questions are in `_research/HYPRLAND_LUA_AUDIT.md`.

Blast radius, now confirmed rather than assumed: session restore, window automation, voxtype
submaps, and idle DPMS. The last two are the dangerous ones — a dead `dpms on` means a black
screen that does not come back. Note the failure is `hyprctl` exit 7, which buys nothing here:
almost every site is written `2>/dev/null || true`, `|| exit 0` or `>/dev/null 2>&1`, and
hypridle ignores its command's status.

- [x] Verify whether `hyprctl dispatch <legacy string>` still works under `configProvider = "lua"`
      — **2026-09-01: it does not.** Finding folded into `_research/HYPRLAND_LUA_AUDIT.md`
- [x] Convert the sites — **30, not 29** (`PowerMenu.qml:47` postdated the inventory).
      Done 2026-09-01; per-site table and conversion notes in `_research/HYPRLAND_LUA_AUDIT.md`
- [x] Delete the `.chezmoiignore` TEMP block
- [x] Update `_guides/HYPRLAND_LUA_CUTOVER.md`, `hypr/CLAUDE.md` (both carried the stale
      "held on Waybar #5013" reason), and the audit
- [x] `chezmoi apply` + reboot — done 2026-09-01, `configProvider: "lua"` live
- [x] Verify the converted sites on the real session — DPMS both ways, a production
      `session-restore` (4/4 windows), `window-pop`, submaps, hyprsplit as a Lua library.
      Table in `_guides/HYPRLAND_LUA_CUTOVER.md`
- [ ] Still open, needs the hardware: anything multi-monitor (`SUPER+ALT+m`,
      `hl.dsp.workspace.move`'s monitor arg), a bar workspace click, media keys on hyprlock
- [ ] Update `_plans/OMARCHY.md` P1: the blocker was routed around, not resolved upstream

**Exit**: Lua entry point live across a reboot and a `hyprctl reload`; workspace clicks
working from the Quickshell bar; idle DPMS off *and back on*; voxtype submaps entering and
resetting; a session restore round-trip.

**Rollback**: restore the `.chezmoiignore` block — the `.conf` set is still deployed.

### Phase 3 — OSDs

**Status: done, 2026-08-31.**

Volume and brightness overlays. Pure addition: we have none today outside voxtype, so
nothing can regress. Reuses the Pipewire binding and `brightness-set` from Phase 1.

**Exit**: volume/brightness keys show a themed OSD that fades; no interaction with the
voxtype instance.

**How it landed** — one file (`osd/Osd.qml`) plus a `Backlight` singleton lifted out of
`BacklightWidget`, and **no script or keybinding change at all**. Both sources already notify
(Pipewire on the sink; `FileView.watchChanges` on `/sys/class/backlight/*/brightness`), so the
OSD fires on whatever caused the change rather than on a hook attached to one caller. Three
non-obvious pieces, all now in `.claude/rules/quickshell-qml.md`:

| Piece | Why |
|---|---|
| `mask: Region {}` | A layer-shell window with no mask swallows every click over its surface even with nothing interactive in it |
| `armed` flag on a 1s timer | Pipewire's first binding and the first sysfs read land after launch; without it the OSD flashes on every login |
| `screen:` matched by monitor **name** | `HyprlandMonitor` has no `screen` property; `Hyprland.monitorFor(screen)` is the inverse, not this direction |

Placed at `Config.osdMargin` = 160 so it clears voxtype's OSD (a 72-tall card at bottomMargin
72). On a desktop with a DDC monitor there is no sysfs backlight and the brightness half never
fires — the same trade `BacklightWidget` already records, since reading DDC costs a ~200ms
probe per keypress.

The two level ramps (volume, brightness) moved into `Config` as `volumeGlyph()` /
`brightnessGlyph()`, because two surfaces now render them. A glyph that distinguishes one
widget's own states still stays in that widget — Amendment A's re-stated criterion holds.

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

**Status: done, 2026-09-01.** Taken ahead of Phase 4, like 2.5 and 3 — it depends on nothing
Phase 4 builds, and Phase 2 is still held on the `hyprctl dispatch` conversion.

Small, and last because Wofi and wlogout are not hurting anyone.

- Launcher: `DesktopEntries` + a `TextField` + fuzzy filter. Note Wofi also serves
  `cliphist` and `--dmenu` callers (`applications.lua.tmpl`) — those keep using Wofi unless
  a dmenu-compatible IPC entry point is built. Do not remove Wofi.
- Power menu: 6 buttons over the existing `session-save` / `systemctl` paths. Keep the
  confirmation behaviour of the current `wlogout` wrapper.

**Exit as originally written**: `SUPER+D` and `SUPER+SHIFT+Q` land on the Quickshell versions;
Wofi stays installed for dmenu use.

**Exit as met** — the key swap is deliberately *not* done yet:

| Criterion | Result |
|---|---|
| Launcher built | ✅ `launcher/Launcher.qml`. `DesktopEntries` + `TextInput` + ranking compressed from Omarchy's `AppSearch.js`. **Apps mode only** — the artboard's `>`/`=`/`:`/`/`/`?` prefixes and the web-search fallback row are not built |
| Power menu built | ✅ `power/PowerMenu.qml`, over the exact `wlogout/layout` commands |
| Lands on `SUPER+D` / `SUPER+SHIFT+Q` | ✅ **swapped 2026-09-01**, alongside the Phase 2 cutover (same binding files, same log-out/in). Duplicate binds *stack* in Hyprland rather than overriding, so the Wofi and wlogout bindings are **gated off** on `features.quickshell_shell` — which required renaming `system-control.{conf,lua}` to `.tmpl`. Wofi and wlogout both stay installed; retirement is still Phase 6 |
| Wofi stays installed | ✅ never in question — `cliphist` and every `--dmenu` caller |

**Two departures from artboard `1h`, both recorded**: six tiles rather than five (hibernate
does real work on the laptop — the bar's eleven-vs-five rule applies again), and wlogout's own
mnemonics `l u e h r s` rather than the canvas's `l s e r p`, which collides on `s`.

🚨 **"Keep the confirmation behaviour" resolved as: keep the model, add nothing.** The wlogout
wrapper has no confirmation step — a tile fires on one activation. Inventing one here would be
a behaviour change disguised as a redesign. The safe default is carried by the *selection*
instead: Lock is selected on open, so Return alone can never power anything off.

**One script, three surfaces**: `quickshell-toggle` gained an optional target argument
(`bar`|`launcher`|`power`). The hard part is identical for all three — IPC only reaches a
running instance — so a second and third copy of the launch-then-retry dance would have been
the only thing gained by separate scripts.

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
| The Lua cutover's real blast radius is wider than Waybar | **Confirmed and closed 2026-09-01**: 30 sites across 11 files, all converted. Shapes proved in a nested Hyprland in Lua mode before committing; `dpms on` (5 sites) is the one thing a nested instance cannot prove, so `hypridle` is stopped for the first log-in. Inventory and conversion notes in `_research/HYPRLAND_LUA_AUDIT.md` |
| Cleanup removes a fallback too early | Phase 6 is optional, per-tool, and gated on the replacement having lived a month, not on its phase exiting |
| `waybar.css` deleted while it is still the colorset source of truth | `colors.sh` is generated from it and `Theme.qml` reads `colors.sh`. Phase 6 ordering constraint — invert the chain first or keep the file orphaned |
| Notification cutover is not reversible in place | Phase 4 owns its own flag, and the revert (`systemctl --user unmask swaync`) is tested before the cutover, not after |
| `lint:qml` silently passes everything | Three independent causes, all verified: Qt5 `qmllint` on `$PATH` (#10), warnings not affecting exit code (#12), and no `qmlformat --check` (#14). Absolute Qt6 paths + `-W 0` + a `diff`-based format check; Phase 0 exit requires proving the task **fails** on a broken file |
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


---

# Amendment A — layout and structure

**Added 2026-08-31.** Supersedes nothing in Phases 0–1 (both shipped); revises the phase
list from Phase 3 onward and adds a structural contract the shipped bar does not yet meet.

**Source**: Claude Design canvas *"Quickshell Mocha Shell"*, artboards `1a`–`1i` —
<https://claude.ai/design/p/1d494341-deaa-47cb-ac39-32ccb9c23862>. Not vendored; it is a
mockup, and every number that matters is transcribed below.

## 🚨 What is adopted, and what is not

**Adopted: structure only** — geometry, panel anatomy, element hierarchy, what sits where
and at what size. The mockup is a *layout* reference.

**Not adopted: the visual system.** The canvas is drawn in raw Catppuccin Mocha on a
mauve accent, in Geist + JetBrains Mono. **None of that is taken.** Our existing systems
stand unchanged and are the only source of these values:

| Aspect | Stays as | Not from the mockup |
|---|---|---|
| Colour | `Theme.qml` → `themes/current/colors.sh`, 24 semantic vars, 8 themes | ignore every hex in the canvas |
| Font | `Config.guiFont` / `Config.terminalFont` ← `globals.yaml` | ignore Geist / JetBrains Mono |
| Glyphs | our existing Nerd Font picks, via the `nerdfonts-search` skill | the canvas's glyph set is illustrative |
| Contrast rules | `themes/CLAUDE.md`, by hand | — |

A literal `#rrggbb`, a literal font name, or a hardcoded glyph anywhere in a widget file is
the defect. Grep for all three at every phase exit.

The mockup's colour rule — *"exactly one accent marks the focused thing, everything else
neutral, semantic colours only for state"* — is a **structural** observation and is worth
keeping, expressed in our vocabulary: focused/active uses `Theme.accentPrimary`, everything
at rest is `Theme.fgSecondary`/`fgMuted`, and `accentError`/`accentWarning`/`accentSuccess`
appear only for state. The shipped bar does not follow it — `WorkspacesWidget` paints hover,
focus and urgent in three different accents, and the eleven right-side widgets each carry
their own Waybar-inherited colour.

## What the design specifies

| # | Artboard | Status against this plan |
|---|---|---|
| `1a` | Foundations — geometry scale, glyph set | Geometry adopted; palette and type ignored |
| `1b` | Dual-monitor composite | Illustrative; confirms per-screen bars, already built |
| `1c` | Top bar + dock, with widget states | Bar: **restructure** of shipped Phase 1. Dock: **new** |
| `1d` | Launcher — single command bar | Replaces Phase 5's launcher sketch |
| `1e` | Workspace overview — focused carousel | **New**, not in any phase |
| `1f` | Notification centre | Replaces Phase 4's UI, unspecified until now |
| `1g` | Clipboard history | **New**, and in the plan's "Out" table |
| `1h` | Power / session menu | Replaces Phase 5's power-menu sketch |
| `1i` | Lock screen | **New**, and in the plan's "Out" table |

---

## The geometry scale

One scale, defined once in `Config.qml.tmpl`, used by every surface. This is the single
most portable thing in the canvas.

| Token | Value | Applies to |
|---|---|---|
| `radiusPanel` | 12 | bar, launcher, notification centre, popups |
| `radiusTile` | 10 | notification cards, launcher rows, dock icons |
| `radiusChip` | 8 | bar icon buttons, small badges |
| `radiusPill` | 999 | workspace pills, battery pill, mode badges |
| `gap` | 8 | between sibling elements |
| `padTight` / `pad` / `padLoose` | 12 / 16 / 24 | inside tiles / panels / hero areas |
| hairline | 1px, `Theme.bgSecondary` | borders and separators |

Shipped today: a single `radius: 4`, `barSpacing: 4`, `widgetPadding: 8`. The four-step
radius scale is what makes nested surfaces read as nested.

---

## `1c` — the bar

### Geometry

| | Design | Shipped |
|---|---|---|
| Height | 40 | 30 |
| Inset | 8px all round, floating | 0 — full-bleed `left/right/top` |
| Reserved (exclusive zone) | 56 = 40 + 8 + 8 | 30 |
| Radius | `radiusPanel` | 0 |
| Border | 1px hairline | none |

🚨 **The inset breaks the Phase 1 A/B story.** `Config.qml.tmpl` documents its 30px height
as *"mirrors `waybar/config.tmpl` so the two bars stack without a visual jump while both
run"*. A floating 40px bar reserving 56px does not stack with Waybar — it displaces it.
**The restructure is therefore the event that ends the A/B**, which is why it is sequenced
as Phase 2.5 below rather than folded back into Phase 1.

### Three zones

Left and right are anchored rows; **the centre is absolutely positioned, not a third flex
child**. That is deliberate in the canvas and matters: the clock stays optically centred on
the screen regardless of how wide the left and right zones grow.

- **Left**: a launcher/logo chip (26px square, `radiusChip`, accent glyph on a tinted
  accent ground — the one place the accent appears at rest), then the workspace pills.
- **Centre**: `HH:MM` at 14px, then the date at 12px, baseline-aligned, `gap` between them.
  Shipped `Bar.qml` already uses `anchors.centerIn`, so this zone is structurally correct.
- **Right**: icon buttons, grouped, with 1px × 16px hairline separators between groups.

### Workspace pills

The largest single change to a shipped widget. Today: one glyph per state in a 4-radius
rounded square. Design: **a pill carrying the workspace number plus a Nerd Font glyph for
that workspace's top window**, so the layout is readable without switching to it.

| State | Structure |
|---|---|
| focused | h24, `radiusPill`, padded 12, number + app glyph at ~75% opacity |
| visible on another monitor | h24, `radiusPill`, padded 10, number + app glyph |
| occupied | h24, `radiusPill`, padded 10, number + app glyph, dimmer |
| empty | h24 **square** (24×24), `radiusPill`, number only |
| urgent | h24, `radiusPill`, number + a 5px state dot |

Plus a **6px gap dot between non-contiguous workspace ids** — the canvas shows `1 2 3 4 · 6`,
so a missing workspace reads as a gap rather than as a renumbering.

The three colour tiers the canvas uses to separate focused / visible / occupied / empty are
*its* answer to the ramp; ours comes from the semantic colorset. Where the canvas has more
tiers than our ramp offers, collapse them — structure survives, and merging "occupied" and
"visible" into one appearance is a better outcome than inventing a colour.

This needs a **window-class → glyph map**. `workspace.toplevels` is already read for
`hasWindows`, so the data is in hand; the map is new. One lookup object in
`Config.qml.tmpl` with a fallback glyph, not a chain of `if`s in the widget. Pick codepoints
with the `nerdfonts-search` skill, as the shipped widget's glyphs were.

### The right-side widget set

The canvas draws five things (network, bluetooth · volume, notifications · battery) against
the eleven the shipped bar carries. The four script-backed widgets, plus tray, backlight and
media, have no place in the mockup.

**Do not delete them to match the drawing.** They exist because Waybar carried them and they
report real state. The structural instruction is *visual weight*, not membership:

- icon-only at rest, in a 26px `radiusChip` square
- a **pill** (`radiusPill`, own ground) only where a number must actually be read — battery
- hairline separators grouping related widgets
- no per-widget colour at rest

Apply that to all eleven. If the bar still reads crowded, *that* is the moment to collapse
`kanata`/`voxtype`/`idle` into one status cluster — not before.

### Dock — new

Bottom-centre, auto-hiding: h66, `padTight` horizontal, 16 radius, hairline border, drop
shadow. 42px icon tiles at `radiusTile`, `gap` between, a 4px running-indicator dot under
each, a hairline separator, then a trailing launcher button. Reveals on a **4px bottom
hot-edge, 180ms ease-out**.

Genuinely new — nothing today does this job, and Omarchy has no dock to read from. Optional;
sequenced with the overview.

---

## `1d` — launcher

One window, 760 wide, `radiusPanel`, hairline border, drop shadow. **Three stacked regions**,
and the panel grows downward: an empty query shows the input row alone, so the keybind feels
like a prompt rather than a menu.

1. **Input row** — h56, `padLoose`-ish horizontal, hairline bottom border. Leading search
   glyph, then the query at 16px with a caret, then a right-aligned **mode badge** in a
   bordered chip.
2. **Results** — 6px padding around the list. Each row is h48 at `radiusTile`:
   a 30px icon tile (`radiusChip`) · a two-line stack (name 13.5, command/path 10.5) ·
   spacer · a right-aligned `↵` on the selected row only. The selected row is the only one
   with a ground. A hairline separator with 6px margins divides result *groups*
   (e.g. installed apps vs. the web-search fallback).
3. **Footer** — h34, hairline top border, key hints on the left (`↑↓ navigate`, `↵ launch`,
   `⇥ mode`, `esc close`) and a result count + timing on the right.

**Prefix modes** switch without leaving the keyboard: default `apps`, `>` run, `=` calc,
`:` emoji, `/` files, `?` help. The canvas shows them as a pill row under the panel; that row
is a discoverability aid for the mockup, not necessarily shipped chrome.

Scope note unchanged from Phase 5: Wofi still serves `cliphist` and every `--dmenu` caller.
This replaces Wofi as *the app launcher*, nothing more.

---

## `1f` — notification centre

A 440-wide panel, `radiusPanel`, hairline border, drop shadow. Same three-region stack.

1. **Header** — h52, `pad` horizontal, hairline bottom. Title at 13.5 · a **count badge**
   (h19, `radiusPill`, accent ground) · spacer · a DND toggle as a 28px `radiusChip` button ·
   a "Clear" text button.
2. **Body** — 10px padding, `gap` between cards. Each card is `radiusTile` on a distinct
   ground, and **has no coloured left-border stripe** — deliberately, so every card keeps an
   identical silhouette. Card anatomy:
   - **app row**: app glyph · APP NAME in caps at 10.5 with letter-spacing · an optional
     group-count badge · spacer · relative time (`2 min`, `1 h`)
   - **content**: title 12.5 semibold, then body 12 regular, `gap` 4 between
   - **actions** (optional): a row of h28 `radiusChip` buttons — filled for the primary,
     hairline-outlined for "Dismiss"
   - **grouped**: a hairline divider, then each collapsed sibling as one muted 11.5 line
3. **Footer** — h38, hairline top, key/gesture hints.

**Severity is carried by the title colour alone** — `accentError` on the title, card ground
unchanged. That is the structural rule; it is what keeps the silhouette constant.

Phase 4's D-Bus-ownership constraint is unchanged: swaync must be masked before the
Quickshell server can own `org.freedesktop.Notifications`.

---

## `1h` — power / session menu

Centred column, `gap` 30 between its three parts:

1. **Identity** — a 34px round avatar chip, then a two-line stack: `user@host`, then uptime
   and session count at 10.5.
2. **Tile row** — five 124×124 tiles, 14 radius, hairline border, `gap` 14. Each is a
   centred column: a 26px glyph, `gap` 12, a 12px label. **Lock is the safe default** and is
   the only tile with an accent border and glow. **The destructive tile is coloured in its
   glyph only** — the tile ground and border stay neutral so the row keeps one rhythm.
3. **Mnemonic row** — the single-key hints (`l s e r p`), a separator dot, `esc cancel`.

Keep the confirmation behaviour of the current `wlogout` wrapper; the tiles are a front-end
over the existing `session-save` / `systemctl` paths.

---

## `1e` — workspace overview (new, optional)

A carousel, not a grid: the focused workspace stays legible at real proportions while
neighbours are peripheral context. **Scale 1.0 / 0.69 / 0.46, opacity 1 / 0.6 / 0.35, same
falloff in both directions.**

Live window thumbnails need `ScreencopyView`, and it **is present in the installed 0.3.1** —
verified, not assumed: `/usr/lib/qt6/qml/Quickshell/Wayland/_Screencopy/` exports
`ScreencopyView` with `captureSource`, `live`, `hasContent` and `constraintSize`, and
`Wayland/qmldir` line 8 re-exports it, so a plain `import Quickshell.Wayland` reaches it.

⚠️ It arrives through the same underscore-module indirection as `PanelWindow`
(`Quickshell.Wayland._Screencopy`), so expect it to trip qmllint's `uncreatable-type` the
same way. That category is already the tree's one CLI-wide exemption
(`.claude/rules/quickshell-qml.md`) — confirm it still covers this rather than widening the list.

Genuinely optional: nothing today does this job, so nothing regresses if it never ships.

---

## Still out, and why the drawings do not change that

Two artboards draw things this plan's "Out" table declines. A mockup is not a decision.

- **`1i` Lock screen.** Declined for lockout risk, not for lack of a design.
  **Recommendation: still out.** If taken up, it needs its own plan with a recovery path
  verified *before* hyprlock is displaced — not a phase here.
- **`1g` Clipboard history.** Declined because `cliphist` + Wofi covers it. Its one genuinely
  better idea is structural and worth recording: **a three-letter type badge instead of an
  icon** (reads faster at list density), with a real colour swatch or thumbnail for colour
  and image entries. **Recommendation: out for now, revisit after Phase 5** — it is the
  launcher's list widget with a different model, so building it first builds that list twice.

---

## Revised phase list

Phases 0–2 unchanged.

| Phase | Was | Now |
|---|---|---|
| 0 | Skeleton, theme bridge, one widget | **Done** |
| 1 | Bar to Waybar parity | **Done** |
| 2 | Hyprland Lua cutover | **Done and verified live** (2026-09-01). 30 sites converted; entry point running across a reboot |
| **2.5** | — | **Done** (2026-08-31, ahead of Phase 2). Bar restructure. See below |
| 3 | OSDs | **Done** (2026-08-31, also ahead of Phase 2). Inherited 2.5's geometry scale |
| 4 | Notifications | Unchanged in scope; UI now specified by `1f` |
| 5 | Launcher and power menu | **Done** (2026-09-01, ahead of Phase 4). UI from `1d` and `1h`; both on spare keys, coexisting |
| **5.5** | — | **New, optional — workspace overview (`1e`) and dock** |
| 6 | Cleanup of replaced tooling | Unchanged, still optional |

### Phase 2.5 — bar restructure

**Status: done, 2026-08-31.** Taken ahead of Phase 2 rather than after it — Waybar had been
stopped by hand, so the inset had nothing to coexist with, and the Lua cutover was still
blocked on the `hyprctl dispatch` audit.

✅ **Closed 2026-08-31.** "Stopped by hand" is now stopped by config. Both bars moved *out* of
`conf/autostart.{lua,conf}` and out of `conf/bindings/desktop-utilities.{lua,conf}` into their
own drop-ins — `conf.d/waybar.{lua,conf}` beside the existing `conf.d/quickshell.{lua,conf}` —
and `.chezmoiignore` grew an `{{ else }}` branch so exactly one pair deploys. Each drop-in now
carries its own autostart *and* `SUPER+B`; because they are mutually exclusive, both can claim
the same key and the Phase 6 "rebind SUPER+B" step is already done. The sequencing argument
below held for the *Waybar* half; the *Phase 2* half turned out not to bind.

Retrofit `1a`/`1c` onto the shipped bar. Lands after Phase 2 so it does not compete with the
Lua cutover, and after Waybar has stopped being the daily driver so the inset has nothing to
coexist with.

1. `Config.qml.tmpl` — the geometry scale (four radii, three paddings, `gap`), plus
   `barHeight: 40` and `barInset: 8`
2. `Bar.qml` — floating window: inset margins, `radiusPanel`, hairline border,
   exclusive zone accounting for the inset
3. `BarWidget.qml` — icon-only at rest in a 26px `radiusChip` square; hairline group
   separators; **the accent rule enforced once, here, for all eleven widgets**
4. `WorkspacesWidget.qml` — pills: number + top-window glyph, `radiusPill`, the five states,
   the gap dot for non-contiguous ids
5. The window-class → glyph map in `Config.qml.tmpl`
6. Battery becomes the one pill; everything else loses its per-widget colour

**Exit**: no literal hex, font name or inline glyph anywhere under
`private_dot_config/quickshell/` (grep, at exit); all 8 themes render the bar with one accent;
one light and one dark theme both pass the `themes/CLAUDE.md` contrast rules by eye;
`mise run lint:qml` passes **and still fails on a deliberately broken file**.

**Exit as actually met:**

| Criterion | Result |
|---|---|
| No literal hex | ✅ in every widget. `Theme.qml` keeps its 24 Catppuccin fallbacks — those are the fallback mechanism, not a leak |
| No literal font name | ✅ zero |
| No inline glyph | ⚠️ **narrowed.** The window-class map moved to `Config` as step 5 requires, but ten widgets still hold their own state glyphs (battery ramp, wifi bars, mic states). A glyph that exists to distinguish one widget's states is that widget's data; hoisting it to `Config` would centralise nothing and read worse. Criterion re-stated as: *no literal hex, no literal font name, and the window-class map lives in `Config`* |
| One accent across 8 themes | ✅ structurally — `BarWidget.iconColor` defaults to `fgSecondary` and only state overrides it. Not yet eyeballed in all 8 |
| Contrast, one light + one dark | ⏳ not yet checked by eye |
| `lint:qml` passes and still fails when broken | ✅ verified: clean run rc 0; `iconColor` → `iconColorTYPO` gives rc 255 |

**Corrections after reading the design source directly.** The canvas is reachable through
the `DesignSync` MCP tool (project `1d494341-deaa-47cb-ac39-32ccb9c23862`, file
`Quickshell Mocha Shell.dc.html`); `support.js` is generated runtime and holds no design.
Artboard `1a` confirmed the geometry scale transcribed above, verbatim. Artboard `1c`
carried four things the prose had lost:

| Detail | Result |
|---|---|
| The launcher chip | Was missing entirely. Added as `LauncherWidget` — accent glyph on a tinted accent ground, the one place the accent appears at rest |
| Hairline tier | The canvas's `#313244` is `surface0`, i.e. our `BG_TERTIARY`. Bar border, separators and the gap dot were all one tier too dark |
| Numerals | Workspace numbers, battery % and the clock are `JetBrains Mono` in the canvas — our `terminalFont`. They were rendering in `guiFont` |
| Urgent workspace | The canvas colours the number and dot and leaves the ground quiet; it is not a filled red pill. A second filled pill would compete with the focused one |

Two deliberate departures, both forced by `themes/CLAUDE.md` rather than by taste:

- **The "empty" pill stays transparent.** The canvas gives it a faint ground, which would
  make it an elevated surface and force `fg-primary` on the one state that must recede.
- **"Visible on another monitor" and "occupied" share one appearance.** Verified, not
  assumed: `BG_TERTIARY` and `BG_OVERLAY` are the same value in the shipped themes, so the
  fourth tier the canvas uses does not exist here.

A third correction was self-inflicted: `BarWidget`'s rest colour was a fixed `fg-secondary`,
which becomes the banned `fg-secondary`-on-`bg-secondary` pair the moment a hover ground
appears. It now follows a `grounded` flag.

**Found while doing it, unrelated to the restructure**: `BacklightWidget`'s nine brightness
glyphs were all empty string literals, the same silent authoring loss that had blanked the
workspace glyphs. It has therefore happened twice; both `.claude/rules/quickshell-qml.md` and
`private_dot_config/quickshell/CLAUDE.md` now carry it as a trap with a grep.

> Layout-stability note, not a design adoption: the clock currently renders in `guiFont`, a
> proportional face, so the centre zone reflows slightly on every minute tick. Rendering
> digits in `Config.terminalFont` fixes that. Both fonts already come from `globals.yaml`,
> so this changes nothing about which fonts we ship.

---

## Omarchy as tooling reference

The full Omarchy 4 shell source is checked out at `~/Projects/_external/omarchy/shell/`
(currently `v4.0.1`). `_plans/OMARCHY.md` marks it **SKIPPED** — that skip is about adopting
their *artifact*, and remains correct. Reading it for structure is not adoption.

| Building | Read |
|---|---|
| Launcher (`1d`) | `services/AppSearch.js`, `services/AppLibrary.qml`, `plugins/menu/MenuModel.js` — fuzzy ranking and the `.desktop` model, the parts that are tedious rather than hard |
| Notification centre (`1f`) | `plugins/notifications/NotificationLogic.js`, `components/NotificationCard.qml` — grouping and dedup rules |
| Power menu (`1h`) | `plugins/panels/power/` |
| Clipboard (`1g`, if revisited) | `plugins/clipboard/{capture.sh,ClipboardHistory.js}` — the capture side especially, where the UTF-16 and webp decoding bugs live that their v4.0.1 fixed |
| Shared panel base | `Ui/{Panel,PopupCard,PanelKeyCatcher,TextField}.qml` — our `BarWidget`/`BarTooltip` pair is the same idea at smaller scale |

**Do not copy** the `manifest.json` plugin registry or `PluginRegistry.qml`. This plan
already declines a plugin system as YAGNI for one user, and every Omarchy component is shaped
by it. Read their logic, ignore their registration. Their `Commons/Color.qml` is likewise
their theming bridge, not ours — `Theme.qml` already does that job.

They have **no dock and no workspace overview**, so `1c`'s dock and `1e` are written from
scratch. That is a point in favour of leaving both optional.

---

## Risks added by this amendment

| Risk | Mitigation |
|---|---|
| The canvas's Mocha hex values leak into QML | Every value goes through `Theme`/`Config`. A literal `#`, font name or glyph in a widget file is the defect; grep at every phase exit |
| Our 4-step background ramp cannot express the canvas's tier count | Collapse tiers rather than invent colours — merging "occupied" and "visible" beats a hardcoded shade |
| Floating bar's exclusive zone fights Waybar | Phase 2.5 lands after Waybar stops being the daily driver; the restructure *is* the end of the A/B |
| Scope creep via the mockup | `1g` and `1i` are drawn but declined, with reasons recorded above |
| `ScreencopyView` trips `uncreatable-type` like `PanelWindow` | Verified present in 0.3.1; the existing tree-wide exemption should cover it — confirm rather than widen the list |
| Window-class → glyph map rots as apps change | One lookup object with a fallback glyph, so an unknown class renders something rather than nothing |

---

# Amendment B — design update 2026-09-01

**Source**: same Claude Design project, now split into six files — `Foundations.dc.html`,
`Bar - Dock.dc.html`, `Composites.dc.html`, `Launcher - Menu.dc.html`, `Panels.dc.html`,
`Session.dc.html` — replacing the single-file `1a`–`1i` artboard set Amendment A read. Fetched
2026-09-01 via `DesignSync`. Same rule as Amendment A: **structure and semantic-role
assignment are adopted; literal hex/font/glyph values are not** — but this revision draws its
mockups directly against our own token names (`@bg-primary`, `@accent-info`, …), not raw
Mocha hex, which is itself new information, not just a redraw.

## What's genuinely new here

**1. A full 16-role accent table, for the first time.** `Foundations.dc.html` names every
accent role's job:

| Role | Use |
|---|---|
| `accent-primary` | Clock, active workspace |
| `accent-border` | Active window border, focus ring |
| `accent-info` | Network, Bluetooth, charging |
| `accent-success` | Battery normal, positive |
| `accent-warning` | Battery <20%, backlight |
| `accent-error` | Critical, urgent workspace |
| `accent-urgent-secondary` | Battery 20–30% |
| `accent-modification` | Git diff, search match |
| `accent-highlight` | Audio / PulseAudio |
| `accent-media` | Media player controls |
| `accent-secondary` | Tertiary interactive |
| `accent-tertiary` | Lock, logout |
| `accent-performance` | CPU, memory, disk |
| `accent-alternative` | Reboot, extra buttons |
| `accent-special` | Custom modules, rare states |
| `accent-subtle` | Cursors, subtle hints |

All 16 already exist as `Theme.qml` properties — **no theme-bridge change needed.** But
checking the shipped widgets against this table found a real gap:

| Widget | Assigned role | Shipped colour at rest |
|---|---|---|
| `BatteryWidget` | `accent-info` (charging), ramp for level | ✅ already matches |
| `NetworkWidget` | `accent-info` | ❌ neutral when connected; only `accent-error` on fault |
| `BluetoothWidget` | `accent-info` | ❌ uses `accent-primary` when connected — wrong role, and `accent-primary` is reserved for clock/active-workspace only per this table |
| `AudioWidget` | `accent-highlight` | ❌ neutral unless muted |
| `MediaWidget` | `accent-media` | ❌ no role colour at all |

**Decided 2026-09-01: keep current.** Amendment A's bar rule — *"no per-widget colour at
rest"*, battery the sole pill exception — stands. `NetworkWidget`/`BluetoothWidget`/
`AudioWidget`/`MediaWidget` are not changed; the table above is descriptive of the design only.
`accentHighlight`, `accentMedia`, `accentTertiary`, `accentSubtle`, `accentAlternative`,
`accentBorder` remain unused in the tree.

**2. Two concrete Launcher findings**, from `Launcher - Menu.dc.html` `launch-a`, checked
directly against the shipped `launcher/Launcher.qml`:

- **Contrast defect — fixed 2026-09-01.** The exec-string line on the *selected* result row was
  `Theme.fgMuted` unconditionally (`Launcher.qml`, the `row.modelData.execString` `Text`). The
  design's note: a 13%-accent-fill selected row is an elevated ground, and `fgMuted` on it
  drops under 4.5:1 in the light themes — the same class of bug `themes/CLAUDE.md` already bans
  structurally. Now `color: row.current ? Theme.fgPrimary : Theme.fgMuted`.
- **`launch-b` empty-query "quick access" — built 2026-09-01.** `Launcher.qml` now reuses
  Wofi's own usage cache (`~/.cache/wofi-drun`, `"<count> <desktop file path>"` per line)
  instead of building a second frecency tracker: Wofi stays installed regardless (cliphist,
  every `--dmenu` caller) and keeps writing that file, so the data is real, not synthetic. On
  open, the file is re-read and matched against `DesktopEntries` by basename-minus-`.desktop`
  (the only identifier `DesktopEntries` exposes is `id`, not the full path Wofi's cache keys
  on), sorted by count, capped at `Config.launcherMaxResults` (8, already matching the design's
  "8 apps" footer). The input row gains the same "QUICK ACCESS" label the design specifies, and
  the footer switches "N results" / "N apps" depending on mode.
  `ponytail:` **read-only** — launching an app from this launcher does not increment the shared
  cache, so quick access drifts stale if Wofi itself stops being used. Upgrade path: write back
  through the same file once/if that's shown to matter; skipped for now since it would need a
  path-matching heuristic no more reliable than the read side already uses.

**3. A combined CPU+MEM bar pill** (`Bar - Dock.dc.html` `bar-a`), plus a fuller CPU/MEM/DISK
meter block in the new **Control Centre** panel (below). No widget for any of CPU, memory or
disk exists in the tree today — this is new scope, not a restructure of something shipped.
Optional, same footing as the kanata/voxtype/idle consolidation Amendment A already flagged as
"if the bar reads crowded, not before."

**4. Control Centre — new artboard, conflicts with declared scope.** `Panels.dc.html` `pan-c`
draws a full control panel: Wi-Fi/Bluetooth/DND/night-light/power-profile/idle-inhibit tiles,
volume + backlight sliders, a CPU/MEM/DISK meter block, and a now-playing card. This is
exactly what the plan's "Out" table already declines — *"Clipboard manager, emoji picker,
**control panels** — cliphist, wofi and the existing menus cover these."* A mockup existing is
not a decision (same footing as `1g`/`1i` in Amendment A). **Recommendation: still out, by the
existing rule** — flagging it here rather than silently adding or silently ignoring it.

**5. PowerMenu glyph-colour and selection-ring changes**, from `Session.dc.html` `ses-a`,
checked against shipped `power/PowerMenu.qml`:

- Design: every tile's glyph carries a fixed role colour at rest — `accent-tertiary` for Lock
  and Log out, `accent-subtle` for Suspend, `accent-alternative` for Reboot, `accent-error` for
  Shut down — and the selection ring is `accent-border`.
- Shipped: only the destructive tile (Shut down) is coloured (`accentError`); every other tile
  is neutral `fgPrimary` until selected, and the selection ring is `accentPrimary`.
- **Decided 2026-09-01: keep current.** Same reasoning as finding 1 — five colours visible in
  an idle menu is a real visual change from "only the destructive tile is coloured," declined
  for the same reason the bar widgets stayed neutral. `PowerMenu.qml` unchanged.

**6. Confirmed unchanged / still declined** (no plan action needed):

- **System menu** (`menu-a`/`menu-b`, Super+Space) — the design file labels this artboard
  *"EXPLORATORY ONLY: wofi covers this today and control panels are out of Quickshell-port
  scope per `_plans/QUICKSHELL_SHELL.md`"* — the design itself defers to this plan. No change.
- **Clipboard** (`pan-b`) — Amendment A already recommended *"revisit after Phase 5"*; Phase 5
  is now done (`ses-a`/`launch-a` etc. confirm it). Due for a decision, still declined by
  default until one is made — not resolved here.
- **Lock screen** (`ses-b`) — still declined for lockout risk; structural notes (clock
  top-left, credentials bottom-left, media widget mirrors the notification card) recorded for
  if it's ever taken up.
- **Dock** and **workspace overview** (`comp-a`–`comp-d`) — geometry and behaviour unchanged
  from what Amendment A already recorded for `1c`/`1e`; both still optional, Phase 5.5.

## Plan-list impact

No phase moves. Findings 1–5 above were decision points layered onto Phases 2.5 (done), 4
(notifications, unstarted), and the optional Phase 5.5 — not reasons to reopen any of them.
All are now settled: the Launcher contrast fix (finding 2) is applied; the two accent-role
adoptions (findings 1 and 5) are declined, keeping `NetworkWidget`/`BluetoothWidget`/
`AudioWidget`/`MediaWidget`/`PowerMenu.qml` as shipped.
