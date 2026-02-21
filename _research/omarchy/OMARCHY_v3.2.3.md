# Omarchy v3.2.3 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.2.2
**Commits**: 63
**Source**: GitHub release notes

---

## Summary

Broad stabilization release. Introduces update channel switching (stable/edge/dev), restores Alacritty as fallback terminal, and resolves a large number of issues across screensaver reliability, multi-display, Walker launcher, limine bootloader, lock screen, snapper disk usage, and web app restoration.

## Features

- **Update Channel Switching**: `Update > Channel` menu to switch between stable/edge/dev channels.
- **Alacritty Restored as Default Package**: Re-added as fallback terminal for systems that don't support Ghostty.
- **Iosevka Optional Font**: Added as an optional font install.
- **Ethereal Theme New Background**: New background image for Ethereal theme.
- **Fizzy Default Web App**: Added as default web app on new installations.
- **Grouped Window Navigation**: `Super + Ctrl + Arrows` navigates inside grouped windows.
- **Better Portal Share Picker**: Improved portal-based screen/window share picker.
- **Walker Emergency Entries**: Emergency entries added to allow easy Walker/Elephant restart.
- **Thunderbolt Plymouth Module**: Supports thunderbolt devices at Plymouth login screen.

## Bug Fixes

- Reboot now offered when kernel updated during channel change
- Lock screen no longer accepts empty submissions
- Screensaver now stops on mouse movement
- Screensaver layout shift fixed (uses floating terminal)
- Screensaver fixed on multi-display setups
- Walker autostart fixed for new installations
- Default Kitty config updated to remove deprecated/removed settings
- Post-install notification expand icon fixed
- T2 services now auto-start on install
- Web apps correctly restored in `omarchy-refresh-applications`
- Mullvad Browser private window launch fixed
- Bitwarden window now floats by default (consistent with 1Password)
- Urgent notifications now show on top of full-screen windows
- Pacman index DBs updated on Omarchy updates (prevents drift from stable repos)
- Screensaver and system locking suppressed during Omarchy updates
- `omarchy-restart-walker` fixed to restart updated services correctly
- Limine logic now checks all `.conf` locations
- `omarchy-refresh-limine` UKI directory checks corrected
- Snapper retention fixed to prevent disk exhaustion
- Hyprlock faillock attempt threshold raised to 10
- Screensaver now closes Walker before starting

## Breaking Changes

*None*

## Configuration Changes

- **Kitty Config**: Deprecated/removed settings removed from default config
- **Hyprlock Faillock**: Attempt threshold raised to 10
- **Hyprland Keybinds**: `Super + Ctrl + Arrows` added for grouped window navigation

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `alacritty` | Fallback terminal for systems without Ghostty support |
| Added | `iosevka` (optional) | Additional font choice |
| Added | `fizzy` (web app) | Default web app on new installations |

---

<details><summary>Original release notes</summary>

```
# What changed?

## Additions

* Add Alacritty back as a default package to provide a fallback for systems that do not support Ghostty by @dhh
* Add Iosevka as an optional font install by @Ibreede
* Add new background image for Ethereal theme by @s-pra1ham
* Add Fizzy as a default web app on new installations by @dcchambers
* Add `Super + Ctrl + Arrows` to navigate inside grouped windows by @dhh
* Add better portal share picker by @ryanrhughes
* Add emergency entries for Walker to allow easy restart if there's an issue with Walker / Elephant by @ryanrhughes
* Add thunderbolt module to support thunderbolt devices on Plymouth login by @sgruendel & @ryanrhughes
* Add Update > Channel to switch between stable/edge/dev channels by @dhh

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.2.2...v3.2.3
```

</details>
