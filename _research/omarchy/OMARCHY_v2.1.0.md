# Omarchy v2.1.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v2.0.5
**Commits**: 89
**Source**: GitHub release notes

---

## Summary

v2.1.0 completes Omarchy's transition to a self-hosted package infrastructure: a Cloudflare-backed Omarchy Mirror replaces the previous chaotic-aur dependency for Arch core/extra/multilib packages, and optional installs (Cursor, Dropbox, VSCode, Claude, Crush, opencode) now also route through the Omarchy Package Repository. Alongside the infrastructure shift, the release adds several new optional installs (Bitwarden, Emacs, WiFi/Bluetooth toggle, Samba) and a set of migration helper commands, plus a substantial round of bug fixes spanning fonts, GPU-accelerated Ollama, audio, display, and gaming.

---

## Features

- **Cloudflare-hosted Omarchy Mirror**: Default source for Arch core/extra/multilib packages is now the Omarchy-operated Cloudflare mirror. Replaces direct Arch mirrors.
- **omarchy-pkg-add/drop/present/missing**: New helper commands for managing packages, intended for use in migration scripts.
- **omarchy-cmd-present/missing**: New helper commands to check for the presence of arbitrary commands, intended for migration use.
- **Bitwarden install option**: Added under Install > Service as an alternative password manager to 1Password.
- **Emacs install option**: Added under Install > Editor.
- **WiFi/Bluetooth rfkill toggle**: Added under Update > Hardware > Wifi/Bluetooth to unblock modules via `rfkill`.
- **Samba drive support**: Samba support added to the file manager (Nautilus).

## Bug Fixes

- **omarchy-migrate skip on failure**: Failed migrations can now be skipped rather than blocking the migration process.
- **ttf-ia-writer restored**: Font package re-added after upstream packaging was resolved.
- **Omarchy pkg repo trailing slash**: Fixed trailing slash in package repository declarations.
- **Battery monitor math**: Fixed incorrect battery percentage calculation.
- **Screensaver pause interval**: Screensaver now pauses 2 seconds after each completed animation (was not pausing correctly).
- **Ollama GPU-accelerated install**: Install > AI > Ollama now selects GPU-accelerated package variants where the hardware supports it.
- **AUR upgrade scope**: Omarchy Update no longer upgrades non-AUR packages when running AUR updates.
- **Alacritty opacity conflict**: Alacritty's own opacity settings no longer stack on top of Hyprland's window opacity rules.
- **Kanagawa theme transparency**: Default terminal background transparency for Kanagawa theme was too high; corrected.
- **About screen icons**: Missing icons for OS Age and Uptime fields in the About screen restored.
- **qt5-wayland missing**: Package now installed by default, fixing display issues in KeepassXC, Nextcloud, Sqlite Browser, and other Qt5 apps under Wayland.
- **JetBrains Nerd Font**: Default JetBrains font install now uses the Nerd Font variant.
- **Steam/RetroArch joypad idle**: Fixed idle-prevention issue when using joypads in Steam and RetroArch.
- **Nautilus navigation icons**: Corrected wrong icons used in Nautilus navigation.
- **Failed installation retry**: A failed install now automatically offers a retry rather than requiring a manual command re-run.
- **Framework Laptop 13 audio input**: Fixed misconfigured audio input for Framework Laptop 13.
- **Optional installs via Omarchy repo**: Cursor, Dropbox, VSCode, Claude, Crush, and opencode optional installs now route through the Omarchy Package Repository instead of external sources.

## Breaking Changes

*None*

## Improvements

- **Package infrastructure consolidation**: All package and mirror activity now routes through the Omarchy-operated Cloudflare setup, removing the chaotic-aur dependency entirely.

## Configuration Changes

- **Arch package mirror source**: Default mirrorlist or pacman configuration now points to the Omarchy Cloudflare mirror for core/extra/multilib repos. Previously pointed to chaotic-aur or standard Arch mirrors.
- **Omarchy Package Repository declarations**: Trailing slash bug fixed in repo URL declarations; existing configurations with trailing slashes required correction.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added (optional) | `bitwarden` | Password manager alternative to 1Password |
| Added (optional) | `emacs` | Text editor / Lisp environment |
| Added | `qt5-wayland` | Qt5 Wayland support for KeepassXC, Nextcloud, Sqlite Browser, etc. |
| Added | `ttf-ia-writer` | iA Writer font (re-added after upstream fix) |
| Removed | chaotic-aur | Replaced by Omarchy's own Cloudflare-backed package repo |
| Changed | `jetbrains-mono` | Replaced with Nerd Font variant |
| Changed (optional) | `ollama` | Now installs GPU-accelerated variant where supported |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add Cloudflare-hosted Omarchy Mirror as the default place to get Arch core/extra/multilib packages by @dhh
* Remove chaotic-aur as a default setup now that we have our own package repo by @dhh
* Add omarchy-pkg-add/drop/present/missing helper commands for migrations in particular by @dhh
* Add omarchy-cmd-present/missing helper commands for migrations in particular by @dhh
* Add Install > Service > Bitwarden as an alternative to 1pw by @crbelaus
* Add Install > Editor > Emacs by @spdawson
* Add Update > Hardware > Wifi/Bluetooth to unblock the modules via rfkill by @dhh
* Add Samba drive support to file manager by @chantastic
* Fix omarchy-migrate when migrations fail so they can be skipped by @Gazler
* Fix bring back ttf-ia-writer now that the package has been sorted by @dhh + @ryanrhughes
* Fix trailing slash in Omarchy pkg repo declarations by @dhh
* Fix battery monitor math by @pipetogrep
* Fix screensaver should pause for 2 seconds after each completed animation by @oppegard
* Fix Install > AI > Ollama to install GPU-accelerated versions where possible by @valbertoenoc
* Fix Omarchy Update: AUR should only upgrade AUR packages by @dhh
* Fix Alacritty adding its own opacity controls on top of Hyprland by @dhh
* Fix Kanagawa transparency being too high with default background on the terminal by @dhh
* Fix missing icons for OS Age + Uptime in About by @theamit-969
* Fix qt5-wayland should be installed so KeepassXC, Nextcloud, Sqlite Browser, and other apps display correctly by @roelandmoors
* Fix JetBrains font installed by default should be Nerd Font version by @ankurkotwal
* Fix steam + retroarch could idle during gaming when using joypads by @JordanAnthonyKing
* Fix wrong navigation icons used by Nautilus by @pipetogrep
* Fix that a failed installation should offer an automatic retry rather than require manual command by @dhh
* Fix Framework Laptop 13 audio input was misconfigured by @ryanrhughes + @dhh
* Fix using Omarchy Package Repository for most optional installs too, like Cursor, Dropbox, VSCode, Claude, Crush, opencode by @ryanrhughes + @dhh

This release completes the transition to having all package and mirror activity hitting our own setup behind Cloudflare.

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v2.0.5...v2.1.0
```

</details>
