# Omarchy v3.3.0 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.2.3
**Commits**: 142
**Source**: GitHub release notes

---

## Summary

v3.3.0 is a large release (142 commits) focused on Hyprland 0.53 compatibility, new opt-in system features (dictation, hibernation, suspend), expanded AI tooling, and a theme system overhaul via `colors.toml` and template-based configs. It also ships significant bug-fix work across nvidia compatibility, waybar stability, screensaver behavior, and menu/script resilience.

## Features

- **Voxtype dictation**: Opt-in voice dictation via Install > AI > Dictation. Keybind: `Super + Ctrl + X`.
- **Hibernation support**: Opt-in via Setup > System Sleep > Enable Hibernate.
- **Suspend restore option**: Re-enable suspend via Setup > System Sleep > Enable Suspend.
- **OpenCode alias**: Terminal alias `c` mapped to OpenCode.
- **colors.toml + template-based theme configs**: New `colors.toml` file and template-driven configuration to simplify theme setup.
- **New Gruvbox background**: Impressionist painting "The Backwater, 1903" added for the Gruvbox theme.
- **New keybinds**:
  - `Super + Ctrl + T` — Activity monitor
  - `Super + Ctrl + A` — Audio controls
  - `Super + Ctrl + B` — Bluetooth controls
  - `Super + Ctrl + W` — Wi-Fi controls
  - `Super + Ctrl + L` — Lock system
- **Google Maps web app**: Added as a default web app.
- **Omarchy skill for Claude**: A skill definition added for Claude and compatible models to assist with config tailoring.
- **Copilot CLI install option**: Added under Install > AI.
- **Remove > Development menu**: New removal flow for development environments installed via Install > Development.
- **Menu extension point**: `~/.config/omarchy/extensions/menu.sh` can now overwrite any sub-menu function in the Omarchy Menu.

## Bug Fixes

- **Hyprland 0.53 compatibility**: Config syntax updated to match Hyprland 0.53 breaking changes (windowrules/layerrules syntax).
- **Older NVIDIA Pascal cards**: Restored compatibility after NVIDIA dropped Pascal support in 590 drivers.
- **RDP readiness check**: Fixed check performed before launching a new Windows VM.
- **Missing dotnet-runtime-9.0**: Added for Pinta image editor.
- **Waybar tray expander crash**: Fixed crash bug triggered by scrolling in the tray expander.
- **Screensaver + Bluetooth mice**: Removed mouse-to-wake behavior that prevented screensaver from activating with Bluetooth mice.
- **OpenAI Codex package suggestion**: Corrected the suggested package name.
- **noidle not turning off**: Fixed noidle remaining active after updating Omarchy from terminal.
- **PostgreSQL version**: Install > Development > Docker DB > PostgreSQL now uses version 18.
- **Fresh editor compatibility**: Fixed omarchy-launch-editor stub compatibility with the fresh editor.
- **Ctrl+C to abort**: Fixed abort behavior during install/remove flows for web apps and TUIs.
- **omarchy-cmd-shutdown/reboot**: Fixed these commands when invoked from a terminal.
- **omarchy-reinstall**: Made more resilient and comprehensive.
- **copy-url extension manifest**: Fixed manifest version field.
- **Waybar volume icon**: Fixed icon display when audio is routed through headphones.
- **Fingerprint setup**: Setup > Security > Fingerprint now works with all sensors recognized by fprintd.
- **hyprctl crash on screensaver termination**: Fixed crash when screensaver process was terminated.
- **Node install from menu**: Fixed broken node installation via Omarchy Menu.
- **User background image location**: User backgrounds now stored in `~/.config/omarchy/backgrounds` instead of inside the Omarchy system folder.
- **omarchy-restart-walker resiliency**: Improved error handling and resiliency.

## Breaking Changes

- **Hyprland windowrule/layerrule syntax**: Hyprland 0.53 introduced a new syntax for `windowrules` and `layerrules`. Omarchy's built-in rules are updated, but any user-defined custom rules must be manually converted. Conversion tool: https://itsohen.github.io/hyprrulefix/. Temporary Hyprland config errors are expected during the update and clear after a system restart.
- **User background image path**: User-supplied backgrounds must now reside in `~/.config/omarchy/backgrounds` rather than inside the Omarchy system directory. Existing custom backgrounds in the old location will need to be moved.

## Configuration Changes

- **colors.toml**: New file introduced as part of the theme system. Provides TOML-based color definitions feeding template-driven config generation.
- **Hyprland windowrule/layerrule syntax**: All Omarchy Hyprland configs updated to Hyprland 0.53 rule syntax.
- **User backgrounds path**: Updated to `~/.config/omarchy/backgrounds`.
- **Menu extension hook**: `~/.config/omarchy/extensions/menu.sh` is now a documented override point.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `voxtype` (or equivalent) | Opt-in voice dictation |
| Added | `dotnet-runtime-9.0` | Runtime dependency for Pinta image editor |
| Added | PostgreSQL 18 (Docker image) | Docker DB option under Install > Development |
| Added | Copilot CLI | AI coding assistant, Install > AI option |

---

<details><summary>Original release notes</summary>

```
# What changed?

## New features
* Add Voxtype dictation via Install > AI > Dictation (Super + Ctrl + X)
* Add hibernation support via Setup > System Sleep > Enable Hibernate
* Add suspend restore option via Setup > System Sleep > Enable Suspend
* Add OpenCode alias c
* Add colors.toml + template-based theme configs
* Add new Gruvbox background
* Add Super + Ctrl + T/A/B/W/L keybinds for system controls
* Add Google Maps as default web app
* Add Omarchy skill for Claude
* Add Copilot CLI install option
* Add Remove > Development menu
* Add menu extension point via ~/.config/omarchy/extensions/menu.sh

## Fixes
* Fix Hyprland 0.53 compatibility (windowrules/layerrules syntax)
* Fix older NVIDIA Pascal card compatibility
* Fix RDP readiness check
* Add missing dotnet-runtime-9.0 for Pinta
* Fix Waybar tray expander crash on scroll
* Fix screensaver activation with Bluetooth mice
* Fix OpenAI Codex package suggestion
* Fix noidle not turning off after omarchy-update from terminal
* Fix PostgreSQL version to 18
* Fix Fresh editor compatibility
* Fix Ctrl+C abort during install/remove flows
* Fix omarchy-cmd-shutdown/reboot from terminal
* Fix omarchy-reinstall resiliency
* Fix copy-url extension manifest version
* Fix Waybar volume icon with headphones
* Fix fingerprint setup for all fprintd sensors
* Fix hyprctl crash on screensaver termination
* Fix node install from Omarchy Menu
* Move user backgrounds to ~/.config/omarchy/backgrounds
* Fix omarchy-restart-walker resiliency

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.2.3...v3.3.0
```

</details>
