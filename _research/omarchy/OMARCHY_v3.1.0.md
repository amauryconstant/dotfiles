# Omarchy v3.1.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v3.0.2
**Commits**: 217
**Source**: GitHub release notes

---

## Summary

v3.1.0 is a major feature release spanning keybindings, theming, infrastructure, and bug fixes across 217 commits. The release introduces a hooks system for user extensibility, a unified screenshot/screenrecord workflow, live theme propagation to additional applications, and several new install targets. Numerous stability and polish fixes address shutdown speed, app launcher clutter, lock screen rendering, and cross-GPU screen recording.

## Features

### New Keys and Capabilities

- **Universal Copy/Paste**: `Super + C / V` added as universal clipboard shortcuts.
- **Clipboard Manager**: `Super + Ctrl + V` opens clipboard manager.
- **Fullscreen and Tiling Hotkeys**: `Super + F` for fullscreen (replacing F11); `Super + T` to toggle tiling/floating; app hotkeys moved to `Super + Shift + [letter]` (new default; opt-in for existing installs).
- **Tiling Groups**: Hotkeys and styling for tiling groups added.
- **Unified Screenrecord with Webcam**: `Alt + PrtScrn` captures screen with webcam overlay via unified GPU screen recorder (NVIDIA and others supported).
- **Smart Screenshot Selection**: `PrtScr` alone allows region/window/display capture selection.
- **Clipboard Screenshot**: `Shift + PrtScr` captures directly to clipboard.

### New Looks

- **Live Theme Changes — Neovim**: Theme changes propagate live to Neovim.
- **Live Theme Changes — Obsidian**: Theme changes propagate live to Obsidian.
- **Live Theme Changes — Cursor**: Theme changes propagate live to Cursor editor.
- **Live Theme Changes — Helium Browser**: Theme changes propagate live to Helium browser.
- **Aether Theme Creator**: New Aether application for creating custom themes.
- **Flexoki Light**: Added as new default theme.
- **Matte Black Extra Background**: Additional background image for Matte Black theme.
- **Increased Blur**: More blur applied to transparent windows.
- **Apple-Style Brightness Overlay**: Display overlay shown on brightness adjustment.
- **Learn Keybindings Notification**: On new installs, a notification links to the keybinding cheatsheet.

### New Infrastructure

- **Windows VM Install**: `Install > Windows` added for setting up a Windows VM.
- **Walker 2.0**: Replaces previous Walker to fix memory leak and improve launch speed.
- **Default Keyring**: System keyring configured to unlock on login via SDDM.
- **Unified GPU Screen Recorder**: Works across NVIDIA and other GPU vendors.
- **Hooks System**: `~/.config/omarchy/hooks` directory for user hooks: theme set, font set, and post-update hooks.
- **Explicit Timezone Selection**: `Update > Timezone` replaces geoguessing-based timezone detection.
- **Firmware Update**: `Update > Firmware` runs `fwupdmgr update`.
- **Cursor CLI Install**: `Install > AI > Cursor CLI` added.
- **ThinkPad E14 Gen 6 Fingerprint Support**: Fingerprint sensor support added for that model.
- **mailto: Handler**: Configured for the default HEY email client.
- **Btop Vim Keybindings**: Vim navigation keys enabled in btop.
- **Secure Boot Guard**: Install aborts on systems with secure boot enabled.
- **Screencast with Webcam Trigger**: `Trigger > Capture > Screencast > Display + Webcam` added.
- **MSSQL Docker DB**: `Install > Development > Docker DB > MSSQL` added.
- **Node.js Default Install**: Node added by default to support tree-sitter in latest LazyVim.

## Bug Fixes

- **Slow Reboots/Shutdowns**: Service stop timeout cut to 5 seconds.
- **Polkit Error After Install**: Fixed polkit error occurring post-install.
- **Application Not Responding Timeout**: Extended from ~2s to ~5s to reduce false positives.
- **Reboot Flag Not Clearing**: Manually rebooting or relaunching after `omarchy-update` prompted a reboot now correctly clears the flag.
- **Electron 36/37 Icons in App Launcher**: Useless icons no longer appear.
- **Limine Restore Icons in App Launcher**: `jconsole`/`jshell` icons no longer appear.
- **"Open in Nvim" from File Manager**: Fixed broken action.
- **AirPod Source "(null)" Display**: Audio switch no longer shows `(null)` for AirPod source name.
- **Current Working Directory**: Fixed cases where `cwd` returns a non-real directory.
- **App Launch Speed**: Switched from `"uwsm app"` to `uwsm-app` binary for faster launches.
- **Helix Editor Launch**: Fixed launching Helix as the editor.
- **Ghostty SSH Session Integration**: Fixed SSH session detection in Ghostty.
- **Ghostty Tab Design**: Tab bar styled to better integrate with system design.
- **Lock Screen Text and Fingerprint Fail Message**: Fixed text placement and fail message reveal.
- **Calculator Float**: Calculator now floats by default for correct sizing.
- **MacBook Login Keyboard and Suspend/Wake**: Fixed issues on MacBook hardware.
- **Catppuccin Theme Colors**: Corrected to proper Mocha palette values.
- **Chromium Multi-Monitor Crash**: Fixed crash when moving Chromium windows between monitors.
- **App Launcher Icons for X and GitHub**: Icons now work correctly with light mode.
- **VSCode Auto-Update Conflict**: VSCode's own auto-update disabled to prevent pacman conflicts.
- **Symlinked Backgrounds in Rotation**: Symlinked backgrounds now included in background/theme rotation.
- **Brave Live Theme**: Fixed live theme setting for Brave browser.
- **Waybar Icon Spacing**: Fixed icon spacing for new setups.

## Breaking Changes

*None* (app hotkeys move to `Super + Shift + [letter]` is opt-in for existing installs; new default only for fresh installs.)

## Improvements

- **Walker 2.0**: Memory leak eliminated; application launcher execution faster.
- **Blur**: Transparent windows have increased blur depth.
- **GPU Screen Recorder**: Unified recorder replaces separate NVIDIA/non-NVIDIA paths.
- **Timezone**: Explicit selection replaces unreliable geoguessing.

## Configuration Changes

- **Hooks System**: New directory `~/.config/omarchy/hooks` created. Supported hook files: theme set, font set, post-update. These are user-owned scripts invoked by omarchy at defined lifecycle points.
- **Hyprland Keybindings**: `Super + F` replaces F11 for fullscreen; `Super + T` added for tiling toggle; app hotkeys reorganized to `Super + Shift + [letter]` (opt-in for existing installs).
- **SDDM Keyring**: Keyring unlock-on-login configured at the system level.
- **Service Timeout**: Systemd service stop timeout reduced to 5 seconds.
- **Btop Config**: Vim keybinding navigation enabled.
- **VSCode Config**: Built-in auto-update disabled to avoid pacman conflicts.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `walker` (2.0) | Application launcher (replaces prior Walker version) |
| Added | `node` | JavaScript runtime, required by tree-sitter / LazyVim |
| Added | `fwupdmgr` (firmware-manager integration) | Firmware update support via `Update > Firmware` |
| Added | GPU screen recorder (unified) | Screencast with webcam, NVIDIA + other GPU support |

---

<details><summary>Original release notes</summary>

```
# What changed?

## New keys and capabilities

* Add universal copy/paste on `Super + C / V` by @ryanrhughes
* Add clipboard manager on `Super + Ctrl + V` by @dhh
* Add `Super + F` for fullscreen (instead of F11), `Super + T` to toggle tiling/floating, and move app hotkeys to `Super + Shift + [letter]` as new defaults and opt-in for existing installs by @dhh
* Add tiling groups hotkeys and styling by @reshadman
* Add screenrecording with webcam to new unified `Alt + PrtScrn` hotkey by @ryanrhughes
* Add smart screenshot selection so region/window/display can be capture by `PrtScr` alone by @ryanrhughes
* Add straight-to-clipboard screenshot capture on `Shift + PrtScr` by @dhh

## New looks

* Add live theme changes to neovim by @ryanrhughes
* Add live theme changes to Obsidian by @darcy
* Add live theme changes to Cursor by @ludagoo
* Add live theme changes to helium browser by @CantC0unt
* Add Aether application for creating your own theme by @bjarneo
* Add Flexoki Light as new default theme by @euandeas
* Add extra background image for Matte Black theme by @vaqMAD
* Add more blur to the transparent windows by @vyrx-dev
* Add Apple brightness adjustment display overlay by @miharekar
* Add Learn Keybindings notification that links to cheatsheet for new installations by @dhh

## New infrastructure

* Add Install > Windows for easily setting up a Windows VM by @sspaeti + @ryanrhughes
* Add Walker 2.0 to prevent memory leak and speed up execution by @ryanrhughes + @abenz1267
* Add default keyring that unlocks on login through sddm by @ryanrhughes
* Add unified gpu screen recorder that works for nvidia and others by @ryanrhughes
* Add hooks system under `~/.config/omarchy/hooks` for theme set, font set, and post update by @dhh
* Add explicit timezone selection to Update > Timezone instead of attempting to geoguess by @dhh
* Add Update > Firmware to run `fwupdmgr update` by @efir
* Add Install > AI > Cursor CLI by @rajofearth
* Add support for Thinkpad E14 Gen 6 fingerprint sensor by @aislandener
* Add mailto: handler for default HEY email client by @ryanrhughes
* Add vim keybindings to btop navigation by @martinmose
* Add guard against installing on systems with secure boot enabled by @killeik
* Add Trigger > Capture > Screencast > Display + Webcam to record screen with a webcam overlay in the corner by @ryanrhughes
* Add MSSQL to Install > Development > Docker DB > MSSQL by @johannesnormannjensen
* Add node by default to appease tree-sitter in latest lazyvim by @ryanrhughes

## Fixed stuff

* Fix slow reboots/shutdowns by cutting timeout limit for services to 5 seconds by @ryanrhughes
* Fix polkit error after install by @ryanrhughes
* Fix overeager "application is not responding" timeout by setting it to ~5s instead of 2s by @dhh
* Fix manually rebooting or relaunching after omarchy-update flagged the need wouldn't clear it by @alexperreault
* Fix electron36/37 useless icons would show up in app launcher by @sgruendel
* Fix jconsole/jshell icons added for limine restore shouldn't show up in the app launcher by @dhh
* Fix "open in nvim" from file manager by @dharmavagabond
* Fix '(null)' display on AirPod source selection via audio switch by @shawnyeager
* Fix current working directory in cases where a real directory isn't returned by cwd by @matt-h
* Fix using uwsm-app instead of "uwsm app" to speedup launching apps by @woopstar
* Fix launching helix as editor by @Cammisuli
* Fix ssh session integration for Ghostty by @mirzap
* Fix ghostty tab design to look better integrated with rest of system design by @scossar + @Thundernirmal
* Fix text placement and fingerprint fail message reveal on lock screen by @mlombardi96
* Fix calculator sizing by making it float by default by @gkurts
* Fix MacBook issues with login keyboard and suspend/wake-up by @wey-gu
* Fix Catpuccin theme to use proper Mocha colors by @qasimsk20
* Fix Chromium crash when moving windows between monitors by @d-cas
* Fix app launcher icons for X and GitHub to work with light mode by @nqst
* Fix VSCode's own auto-update clashing with pacman by turning it off by @sgruendel
* Fix symlinked backgrounds should be included in background/theme rotation by @giovantenne
* Fix live theme setting for Brave by @CantC0unt
* Fix icon spacing in waybar for new setups by @brink-lab

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.0.2...v3.1.0
```

</details>
