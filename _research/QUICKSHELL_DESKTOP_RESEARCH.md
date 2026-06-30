# Quickshell Custom Desktop Research
**Created**: June 2026
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

### 1. Theming philosophy clash
- **This repo**: 8 *hand-curated* themes (Catppuccin latte/mocha, Rosé Pine dawn/moon, Gruvbox light/dark, Solarized light/dark) built on a **semantic-variable abstraction**, switched via symlink (`~/.config/themes/current`), solar auto-switch via darkman. Desktop apps consume theme files via **CSS** (`@import`/`!include`).
- **The famous Quickshell shells** (Caelestia, DankMaterialShell): **wallpaper-dynamic** color extraction (Material You / matugen). Opposite model.
- **Consequence**: Quickshell is QML, which **cannot consume CSS**. Any migration needs a new bridge from the semantic variables into QML (e.g. generate a QML `Colors` singleton / JSON from `themes/current/colors.sh`). This bridge is mandatory regardless of approach and is *core work*, not a footnote.

### 2. Build & supply-chain friction
- The repo enforces an AUR PKGBUILD-diff tripwire + package security policy (`private_dot_local/lib/scripts/system/CLAUDE.md`).
- Mature shells ship compiled components and `-git` AUR packages:
  - Caelestia ≈ 28% **C++** (native beat-detector plugin, CMake/Ninja) + `caelestia-cli`.
  - DankMaterialShell ≈ 28% **Go** (matugen/dank16 pipeline).
- A from-scratch / pure-QML config avoids most of this (Quickshell itself is the only compiled dep, already vetted/installed).

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
| [doannc2212/quickshell-config](https://github.com/doannc2212/quickshell-config) | **206 curated themes / 6 families**, *not* wallpaper-dynamic. Modular — bar, launcher, notif daemon each work standalone ("take what you like"). Syncs kitty + system dark/light. **Strongest philosophical match** to the semantic-theme + darkman setup; best candidate to study for the theming bridge. |
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

## Strategic Approaches (not yet chosen)

| Approach | Gist | Pros | Cons |
|----------|------|------|------|
| **A. Reference / from-scratch** | Build own Quickshell config; use Caelestia/doannc2212 as design reference. Start small (bar), grow. | True "custom"; fits theming + security model cleanly; no `-git`/C++ fork | Most work; reinvent solved problems |
| **B. Fork & customize** | Fork Caelestia (or DMS); rip out wallpaper-dynamic theming → bridge to semantic vars; prune features | Big head start; keeps cohesion | Maintain a fork vs 2500+ upstream commits; inherit C++/Go build; merge churn |
| **C. Adopt wholesale** | Install `caelestia-shell`/DMS as-is; manage JSON config via chezmoi; disable Waybar/Wofi/etc. | Fastest, most mature | Inherits wallpaper-dynamic theming; "custom" only via JSON; AUR `-git` + extra CLI |

**Leaning (not decided):** Approach **A**, seeded by studying **doannc2212** for the curated-theme bridge, is the only option that satisfies *all four* motivations without fighting the repo's theming + supply-chain conventions. To be confirmed when the project moves out of exploration.

---

## Open Questions For "Further Down The Road"
1. **Theming bridge**: generate a QML `Colors` singleton from `themes/current/colors.sh`? Regenerate on `theme switch` + darkman events? How do `*.tmpl` semantic vars map to QML properties?
2. **Scope sequencing**: bar + launcher first (prove the pattern), then notifications → power menu → OSD consolidation → (maybe) lock screen last.
3. **Lock screen**: replace hyprlock at all? Security-sensitive; lowest reward, highest risk. Note Quickshell *does* provide the primitives (`wayland/session_lock` + `services/pam`), so it's technically credible — but correctness/lockout risk still argues for doing it last, if ever.
4. **chezmoi integration**: QML lives in `~/.config/quickshell/<name>/`; how to template + theme-link it; which pieces are `.tmpl` vs static + symlinked like other theme assets.
5. **Coexistence / rollback**: run Quickshell bar alongside Waybar during migration; keep wlogout/swaync until replacements are proven. `git checkout HEAD~1 && chezmoi apply` as the escape hatch.
6. **Portability**: does multi-compositor support matter (DMS angle), or is Hyprland-lock-in acceptable?

---

## Status
Exploration only. Next step is **not** implementation — when ready, deep-dive a candidate (doannc2212's theming approach is the highest-value first read) and/or prototype a single Quickshell bar module alongside Waybar before committing to an approach.
