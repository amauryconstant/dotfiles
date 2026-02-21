# Omarchy v1.3.1 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.3.0
**Commits**: 41
**Source**: GitHub release notes

---

## Summary

v1.3.1 is a bug-fix and polish release with one notable feature addition: a bare install mode for minimal deployments. The remaining changes address missing or broken configurations across Hyprland keybindings, clipboard safety, Waybar fonts, Chromium Wayland support, and wifi daemon installation reliability.

## Features

- **Bare install mode**: New install path via `wget -qO- https://omarchy.org/install-bare | bash` that installs only essential apps, skipping full application suite. Omarchy path: install script (bare variant).
- **Battery warning**: 10% battery threshold warning added. Omarchy path: battery/notification config (likely `~/.config/hypr/` or a dunst/waybar rule).
- **All application keybindings in hyprland.conf**: All app bindings consolidated into the default `~/.config/hypr/hyprland.conf` to simplify app substitutions for users.

## Bug Fixes

- **`.inputrc` not loaded**: Rules such as history-complete-off-partial-command were not being sourced; now fixed. Omarchy path: shell init / `.inputrc` loading.
- **Chromium not starting in Wayland mode from app launcher**: Chromium now launches with correct Wayland flags when invoked from Wofi or equivalent launcher.
- **Basecamp and HEY apps not using web2app**: Default app entries for Basecamp and HEY were not using the `web2app` wrapper like other web applications; corrected to match the standard pattern.
- **Wifi daemon not installed when using ethernet during archinstall**: `iwd` or equivalent wifi network daemon was conditionally skipped if ethernet was active at install time; now installed unconditionally.
- **Hyprlock stylesheet duplication**: Duplicate CSS/style rules in hyprlock config were removed. Omarchy path: `~/.config/hypr/hyprlock.conf` or equivalent stylesheet.
- **wl-clip-persist storing sensitive data**: Clipboard persistence daemon now excludes sensitive content (e.g., password manager entries). Omarchy path: wl-clip-persist launch flags/config.
- **Waybar icon misalignment**: Default Waybar style updated to use `"Caskaydia Mono Nerd Font Propo"` instead of prior font, improving icon alignment. Omarchy path: `~/.config/waybar/style.css`.

## Breaking Changes

*None*

## Improvements

- **Hyprland app binding discoverability**: Consolidating all application keybindings into the default `hyprland.conf` makes it easier for users to find and override bindings without searching multiple files.

## Configuration Changes

- **Waybar font**: `style.css` font changed to `"Caskaydia Mono Nerd Font Propo"` for correct Nerd Font icon rendering and alignment.
- **hyprland.conf**: All application bindings added to the default config file, expanding its scope as the single reference for keybindings.
- **wl-clip-persist**: Launch configuration updated to prevent storage of sensitive clipboard data (likely via `--ignore-primary` or type-filter flags).
- **Hyprlock stylesheet**: Duplicate style rules removed from hyprlock config.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Ensured installed | wifi network daemon (e.g., `iwd`/`networkmanager`) | Wifi support — previously skipped when ethernet was active during archinstall |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add 10% battery warning by @Mane-Pal in #121
* Add bare mode via `wget -qO- https://omarchy.org/install-bare | bash` that only installs essential apps by @dhh
* Add all application bindings to default `~/.config/hypr/hyprland.conf` to make it easier to do app substitutions by @dhh
* Fix that .inputrc rules (like history complete off partial command) wasn't getting loaded by @dhh
* Fix chromium not starting in wayland mode when launched from app launcher by @dhh
* Fix Basecamp + HEY default apps should use web2app like everything else by @dhh
* Fix wifi network daemon wouldn't get installed if using ethernet during archinstall by @rockorager in #122
* Fix stylesheet duplication for hyprlock by @DrInfinite in #119
* Fix wl-clip-persist should never store sensitive data by @roel4d in #113
* Fix default waybar style to use "Caskaydia Mono Nerd Font Propo" for better icon alignment by @dhh

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.3.0...v1.3.1
```

</details>
