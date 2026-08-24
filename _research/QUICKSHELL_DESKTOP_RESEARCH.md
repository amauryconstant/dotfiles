# Quickshell Custom Desktop Research

**Created**: June 2026 · **Revised**: 2026-08-24 (Omarchy 4.0.0)
**Focus**: Migrating the desktop shell (bar, launcher, notifications, power menu, OSDs, optionally lock) to a custom [Quickshell](https://quickshell.org/) (QtQuick/QML) stack
**Phase**: Exploration — no decision made. Doors deliberately kept open.

---

## Why This Is On The Table

Motivations (all four selected during brainstorming):

- **Unified, cohesive shell** — replace the Waybar/Wofi/swaync/wlogout patchwork with one consistent QML codebase + visual language.
- **Capability / interactivity** — richer dynamic widgets (animations, popups, custom panels) that Waybar/Wofi can't express.
- **Deeper theming control** — pixel-level, reactive look & feel beyond CSS-on-Waybar.
- **Consolidate / reduce deps** — lean on Quickshell (already installed) instead of 4–5 separate tools.

**Quickshell is already present** in the repo: installed via `packages.yaml`, currently driving only the **voxtype waveform OSD overlay** (`private_dot_config/voxtype/config.toml.tmpl`). So the runtime is proven here; this is about scope expansion.

**Upstream source vendored for reference**: the Quickshell framework source is checked in at `_ai/quickshell/` (git subtree of `git.outfoxxed.me/quickshell/quickshell`, repo-only — added to `.chezmoiignore`, *not* deployed). Use it to verify the real QML API instead of guessing. Quickshell is **LGPL-3**; the framework binary is the only compiled dependency and is already vetted/installed.

---

## What A Migration Replaces

Current desktop stack and its Quickshell-era fate:

| Component | Current tool | Notes |
|-----------|--------------|-------|
| Status bar | **Waybar** | 504-line `config.tmpl` + 625-line `style.css.tmpl` |
| App launcher | **Wofi** | |
| Notifications | **swaync** | incl. persistent history panel |
| Power menu | **wlogout** | |
| OSDs | (waybar/scripts) + Quickshell (voxtype) | volume/brightness |
| Lock screen | **hyprlock** | security-sensitive — replace last, if at all |
| Idle daemon | **hypridle** | keep; not a shell-widget concern |
| Compositor | **Hyprland** | stays |

---

## Two Structural Tensions (the crux of any decision)

> **Both tensions weakened substantially in August 2026.** Omarchy 4.0.0 "Quattro"
> (2026-08) replaced its entire desktop shell with Quickshell — and it is *curated +
> semantically themed* with *no compiled components*, which is the exact combination this
> section was written to say did not exist. Each tension below carries an updated verdict.
> See "Omarchy 4 as reference implementation" below.

### 1. Theming philosophy clash

- **This repo**: 8 *hand-curated* themes (Catppuccin latte/mocha, Rosé Pine dawn/moon, Gruvbox light/dark, Solarized light/dark) built on a **semantic-variable abstraction**, switched via symlink (`~/.config/themes/current`), solar auto-switch via darkman. Desktop apps consume theme files via **CSS** (`@import`/`!include`).
- **The famous Quickshell shells** (Caelestia, DankMaterialShell): **wallpaper-dynamic** color extraction (Material You / matugen). Opposite model.
- **Consequence**: Quickshell is QML, which **cannot consume CSS**. Any migration needs a new bridge from the semantic variables into QML (e.g. generate a QML `Colors` singleton / JSON from `themes/current/colors.sh`). This bridge is mandatory regardless of approach and is *core work*, not a footnote.

**Updated verdict (2026-08)**: the *premise* — that every mature Quickshell shell is
wallpaper-dynamic — no longer holds. Omarchy 4 ships a **24-key semantic `colors.toml`**
(`mode`, `accent`, `selection`, `muted`, four `*background`, four `*foreground`, named
colors + `bright_*` variants) that maps closely onto our own `BG_*`/`FG_*`/`ACCENT_*`
schema. The CSS→QML bridge is still mandatory work, but it is no longer *unprecedented*
work: there is now a shipped, curated-theme implementation to read.

### 2. Build & supply-chain friction

- The repo enforces an AUR PKGBUILD-diff tripwire + package security policy (`private_dot_local/lib/scripts/system/CLAUDE.md`).
- Mature shells ship compiled components and `-git` AUR packages:
  - Caelestia ≈ 28% **C++** (native beat-detector plugin, CMake/Ninja) + `caelestia-cli`.
  - DankMaterialShell ≈ 28% **Go** (matugen/dank16 pipeline).
- A from-scratch / pure-QML config avoids most of this (Quickshell itself is the only compiled dep, already vetted/installed).

**Updated verdict (2026-08)**: unchanged as a constraint, but Omarchy 4's shell has **no
C++ or Go component** to inherit — it is QML over stock Quickshell. Worth stating the cost
concretely: `_guides/PACKAGE_SUPPLY_CHAIN_SECURITY.md` records that there are currently
**no locally-built `-git` packages** in this repo, and adding one requires vendoring a
reviewed `#commit=<sha>` pin. That is the real price of Approach C for Caelestia/DMS, and
Omarchy 4 does not charge it.

---

## Native Quickshell Capabilities (from vendored source `_ai/quickshell/src/`)

A lot of the hard system-integration plumbing is **built into Quickshell** as first-class QML modules — so "build your own" does *not* mean reimplementing daemons. Inventory:

| Module path | Provides | Replaces / enables |
|-------------|----------|--------------------|
| `services/notifications` | Freedesktop notification **server** (`org.freedesktop.Notifications`) | **swaync** (daemon + custom history panel in QML) |
| `services/mpris` | Media player control | Bar/dashboard media widget |
| `services/status_notifier` | System tray (StatusNotifierItem) | Waybar tray |
| `services/pipewire` | Audio nodes / volume | Volume OSD + control |
| `services/upower` | Battery / power | Battery widget |
| `services/pam` + `services/greetd` | PAM auth + greeter | Real authentication for a custom lock |
| `services/polkit` | Polkit agent | Privilege prompts |
| `wayland/hyprland` | Native Hyprland IPC (workspaces, toplevels, events) | Waybar `hyprland/*` modules |
| `wayland/session_lock` | Secure `ext-session-lock` surface | Credible **hyprlock** replacement (with PAM above) |
| `wayland/idle_notify` + `idle_inhibit` | Idle detection / inhibition | hypridle-style logic (music inhibit, auto-lock) |
| `wayland/wlr_layershell` | Layer-shell surfaces | Bars, panels, OSD overlays |
| `wayland/toplevel`, `screencopy`, `shortcuts_inhibit` | Window list, screenshots, shortcut grabs | Dock/overview, screenshot tools |

**Implication for approach selection**: this narrows the gap between "from-scratch" and "adopt a mature shell." The differentiator of Caelestia/DMS is *polish + curated UX*, not access to system internals — those internals are equally available to a hand-rolled config. Strengthens the case for **Approach A**.

---

## Landscape Survey

### Tier 1 — Full "distro-like" shells (mature, wallpaper-dynamic)

| Project | Stars | Stack | Compositors | Theming |
|---------|-------|-------|-------------|---------|
| [caelestia-dots/shell](https://github.com/caelestia-dots/shell) | ~10k | QML + C++ | Hyprland-centric | Wallpaper-dynamic (Material You) |
| [AvengeMedia/DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) | ~7k | QML + Go | niri, Hyprland, Sway, labwc, MangoWC, Miracle, Scroll | Wallpaper-dynamic (matugen + dank16) |

Both feature-complete: bar, launcher, dashboard, notifications, OSDs, lock, control center, MPRIS, system monitoring, plugin systems. Both clash with the curated-theme model and both add a compiled toolchain + `-git` package. **DankMaterialShell is the more portable** (multi-compositor, one-command install) if Hyprland is ever left behind; Caelestia is the more Hyprland-integrated and most-starred.

### Tier 2 — Closest to *this repo's* philosophy (curated themes, modular)

| Project | Why relevant |
|---------|--------------|
| [basecamp/omarchy](https://github.com/basecamp/omarchy) **4.0.0+** | **Strongest match as of 2026-08.** Curated + semantic (24-key `colors.toml`), *not* wallpaper-dynamic. Pure QML, **no C++/Go**. Ships a complete shell — bar, launcher, menu, notifications, OSDs, control panels, lock, polkit agent — plus a plugin system. Crucially it **renders app themes from templates**, which is the theming-bridge problem solved end to end. Already tracked release-by-release in `_research/omarchy/`. Caveat: distributed as Arch packages under `/usr/share/omarchy` with an ALPM update guard, so it is a **reference to read, not a thing to install** (see `_plans/OMARCHY.md` → Skipped). |
| [doannc2212/quickshell-config](https://github.com/doannc2212/quickshell-config) | **206 curated themes / 6 families**, *not* wallpaper-dynamic. Modular — bar, launcher, notif daemon each work standalone ("take what you like"). Syncs kitty + system dark/light. Was the strongest philosophical match before Omarchy 4; still the better example of *many* themes and of taking one module in isolation. |
| [bgibson72/yahr-quickshell](https://github.com/bgibson72/yahr-quickshell) | 13 fixed themes, instant switching, glassmorphism, automated installer. Full Arch+Hyprland DE. |

### Tier 3 — Clean architecture references (for build-your-own)

| Project | Why study it |
|---------|--------------|
| [tripathiji1312/quickshell](https://github.com/tripathiji1312/quickshell) | Modular; explicit separation of UI / system logic / user settings. |
| [MJBgood/quickshell](https://github.com/MJBgood/quickshell) | Service-oriented, reactive state management — good pattern reference. |
| [Shanu-Kumawat/quickshell-overview](https://github.com/Shanu-Kumawat/quickshell-overview) | A *single* composable module (workspace overview) — example of adopting one piece without the whole shell. |

### Learning resources

- [quickshell.org](https://quickshell.org/) — official docs
- [tonybtw.com Quickshell tutorial](https://www.tonybtw.com/tutorial/quickshell/) — "build your own bar" walkthrough

---

## Omarchy 4 as reference implementation (added 2026-08)

Omarchy 4.0.0 "Quattro" (2026-08) rewrote the whole shell in Quickshell, dropping Waybar,
Walker, Mako, SwayOSD, hyprlock, hypridle, swaybg and polkit-gnome for one long-running
QML process. We are **not adopting it** — it is delivered as Arch packages with an ALPM
guard, and `_plans/OMARCHY.md` records the whole shell as Skipped. Its value here is as the
first shipped answer to the questions this doc leaves open.

Full per-release detail: `_research/omarchy/OMARCHY_v4.0.0.md` (§Configuration Changes).

### The theming bridge, solved (Open Question #1 / mapping blocker #3)

`QUICKSHELL_COMPONENT_MAPPING.md` lists the `colors.sh` → QML bridge as blocker #3,
"mechanism undecided". Omarchy's mechanism:

- one semantic `colors.toml` per theme is the single source of truth;
- `default/themed/*.tpl` templates render **17 outputs** from it — btop, neovim, VS Code,
  Helix, Chromium, foot, ghostty, kitty, alacritty, `hyprland.lua`, and `shell.toml`;
- placeholders are `{{ key }}`, `{{ key_strip }}` (no `#`), `{{ key_rgb }}` (comma triple),
  plus `{{ mix background foreground 15% }}` and gradient helpers;
- the shell **watches `shell.toml`** and re-flows live on edit — so theme switching needs
  no restart, which is what our darkman solar switch would want;
- a hand-written per-theme file **wins over** the generated one — the escape hatch that
  makes generation tolerable when a theme has deliberate manual tuning.

### Why this matters here specifically

Our theme system is 8 themes × ~20 hand-maintained per-app files, and
`private_dot_config/themes/CLAUDE.md` requires that **any new file be added to every theme
directory**. So adding QML theming the current way costs 8 more hand-written files, one per
theme, maintained in parallel forever. Omarchy generates 17 outputs from one source.

Note also that our `colors.sh` is itself already generated — its header says
*"Auto-generated from waybar.css"*. The source of truth is therefore **CSS**, which is
exactly the format QML cannot consume. Any QML shell work would want that inverted: a
format-neutral colorset as the root, with CSS as one rendered output among several. That
is a prerequisite worth doing on its own merits, and it is already tracked independently
as a P2 item in `_plans/OMARCHY.md` ("Semantic `colors.toml` + template-rendered app
themes").

### Coupling with the Hyprland Lua migration

Not previously recorded anywhere. Our Hyprland Lua config is complete and deployed, but its
*entry point* is held back by `.chezmoiignore` for exactly one reason: Waybar's workspace
clicks need PR #5013, which is merged upstream (2026-05-04) but absent from the latest
release (0.15.0, 2026-02-06). See `_plans/OMARCHY.md` P1.

**Waybar is therefore the sole blocker on Lua mode.** A Quickshell bar would remove that
blocker as a side effect — it would talk to Hyprland over native IPC
(`wayland/hyprland`, already inventoried above) rather than through the dispatch-string
path that broke. If this project ever leaves exploration, that is a concrete argument for
sequencing **the bar first**, ahead of launcher or notifications.

---

## Strategic Approaches (not yet chosen)

| Approach | Gist | Pros | Cons |
|----------|------|------|------|
| **A. Reference / from-scratch** | Build own Quickshell config; use **Omarchy 4** (2026-08, curated + semantic) as the primary design reference, Caelestia/doannc2212 secondary. Start small (bar), grow. | True "custom"; fits theming + security model cleanly; no `-git`/C++ fork | Most work; reinvent solved problems |
| **B. Fork & customize** | Fork Caelestia (or DMS); rip out wallpaper-dynamic theming → bridge to semantic vars; prune features | Big head start; keeps cohesion | Maintain a fork vs 2500+ upstream commits; inherit C++/Go build; merge churn |
| **C. Adopt wholesale** | Install `caelestia-shell`/DMS as-is; manage JSON config via chezmoi; disable Waybar/Wofi/etc. | Fastest, most mature | Inherits wallpaper-dynamic theming; "custom" only via JSON; AUR `-git` + extra CLI |

**Leaning (not decided):** Approach **A**, which is the only option that satisfies *all four* motivations without fighting the repo's theming + supply-chain conventions. To be confirmed when the project moves out of exploration.

**Updated 2026-08**: the reference to seed Approach A is now **Omarchy 4**, not doannc2212
— it is curated + semantic like ours, has no compiled components, and has already solved
the theming bridge (above). doannc2212 remains the better read for many-theme handling and
for adopting a single module standalone. Note this changes only *what to read*: Omarchy 4
is packaged in a way that rules out Approaches B and C for it specifically.

---

## Open Questions For "Further Down The Road"

1. ~~**Theming bridge**~~ — **largely answered 2026-08** by Omarchy 4 (see above): one semantic colorset as source of truth, templates rendering per-app outputs, the shell watching its own theme file for live reload, and hand-written per-theme files overriding generated ones. What remains open is narrower: inverting our own `colors.sh` so it is no longer generated *from* `waybar.css`, and deciding whether rendering runs at chezmoi-apply time or theme-switch time.
2. **Scope sequencing**: bar + launcher first (prove the pattern), then notifications → power menu → OSD consolidation → (maybe) lock screen last.
3. **Lock screen**: replace hyprlock at all? Security-sensitive; lowest reward, highest risk. Note Quickshell *does* provide the primitives (`wayland/session_lock` + `services/pam`), so it's technically credible — but correctness/lockout risk still argues for doing it last, if ever.
4. **chezmoi integration**: QML lives in `~/.config/quickshell/<name>/`; how to template + theme-link it; which pieces are `.tmpl` vs static + symlinked like other theme assets.
5. **Coexistence / rollback**: run Quickshell bar alongside Waybar during migration; keep wlogout/swaync until replacements are proven. `git checkout HEAD~1 && chezmoi apply` as the escape hatch.
6. **Portability**: does multi-compositor support matter (DMS angle), or is Hyprland-lock-in acceptable?

---

## Status

Exploration only — still no decision, and no `_plans/` entry. What changed in 2026-08 is
that a reference implementation now exists rather than a set of imperfect candidates.

Next step is **not** implementation. When ready:

1. Read Omarchy 4's shell and theming — highest-value first read, replacing doannc2212 in
   that role. The clone at `~/Projects/_external/omarchy` is used by the release tracker
   and its working tree sits on an older tag, so read the v4.0.0 blobs directly:

   ```sh
   git -C ~/Projects/_external/omarchy show v4.0.0:docs/omarchy-shell.md
   git -C ~/Projects/_external/omarchy show v4.0.0:docs/theming.md
   git -C ~/Projects/_external/omarchy ls-tree --name-only v4.0.0 default/themed/
   ```

2. Prototype a single Quickshell **bar** module alongside Waybar (coexistence, per the
   established preference for keeping the old tool working) — the bar first, because it is
   also what unblocks Hyprland Lua mode.

Revision history: created June 2026 (exploration). Revised 2026-08-24 after Omarchy 4.0.0 —
both structural tensions downgraded, Tier 2 gains Omarchy 4, theming bridge largely
answered, Waybar/Lua coupling recorded.
