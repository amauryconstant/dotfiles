# Omarchy v3.0.2 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v3.0.1
**Commits**: 46
**Source**: GitHub release notes

---

## Summary

v3.0.2 is a broad bug-fix and compatibility release covering theme corrections, hardware support, and utility improvements contributed by multiple community members. Fixes span Ghostty terminal configuration, VSCode theme handling, macOS hardware drivers, and ISO build tooling. No new major features are introduced; the release focuses on correctness and compatibility.

## Features

- **Helium browser support**: `omarchy-launch-webapp` now recognises Helium as a supported browser. Omarchy path: `bin/omarchy-launch-webapp` (inferred).
- **Apple SPI keyboard support**: MacBook8,1, MacBook9,1, and MacBook10,1 models gain Apple SPI keyboard driver support.
- **Broadcom BCM4331 chipset support**: BCM4331 added alongside the existing BCM4360 for MacBook Wi-Fi compatibility.
- **Audio restart command**: A new "Update > Hardware > Audio" TUI entry restarts the PipeWire service.

## Bug Fixes

- **Osaka Jade theme Ghostty**: Corrected Ghostty colour config for the osaka-jade theme variant.
- **Matte Black theme Ghostty and VSCode**: Fixed Ghostty and VSCode config entries for the matte-black theme.
- **Ghostty config comment typo**: Corrected a comment typo in the Ghostty configuration file.
- **Ghostty scrollfactor**: Adjusted scroll factor value in Ghostty config.
- **omarchy-launch-or-focus pattern**: Narrowed the window-matching regex to prevent incorrect matches against unrelated windows.
- **Hyprland cursor hidden while typing**: Cursor is now hidden during keyboard input via Hyprland config.
- **AirPod source null display**: Fixed `(null)` appearing in AirPod audio source selection UI.
- **omarchy-tui-install TERMINAL variable**: Fixed the install TUI not preserving the `$TERMINAL` environment variable.
- **Screen recording geometry**: `omarchy-record` (or equivalent) now uses output display or region geometry rather than a fixed region.
- **libyaml before Ruby install**: Installation order corrected so `libyaml` is installed before Ruby to avoid build failures.

## Breaking Changes

*None*

## Improvements

- **theme-set-vscode JSONC and symlink support**: `theme-set-vscode` script now handles `.jsonc` file format and correctly follows symlinks when writing theme configuration.

## Configuration Changes

- **Ghostty scrollfactor**: Numeric scroll factor value adjusted in Ghostty config (exact file: `config/ghostty` or equivalent within omarchy).
- **Hyprland cursor-on-typing**: A hide-cursor-while-typing directive added to Hyprland input config (exact key: likely `input { hide_cursor_when_typing = true }` in `hypr/hyprland.conf`).

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `libyaml` | Required build dependency for Ruby; install order enforced before Ruby |
| Added | `alsa-firmware` (ISO only) | Missing firmware for ALSA audio in ISO image |

---

<details><summary>Original release notes</summary>

```
## What's Changed
* Fix osaka jade theme for Ghostty by @dhh
* Adjust Ghostty scrollfactor by @dhh
* Limit matching pattern of omarchy-launch-or-focus to prevent incorrect matches by @ryanrhughes
* Improve theme-set-vscode to support jsonc and respect symlinks by @OmarSkalli
* Hide hyperland cursor while typing by @js
* Fix Matte Black theme Ghostty and vscode configs by @tahayvr
* Fix ghostty config comment typo by @John-Lin
* Add Update > Hardware > Audio for restarting pipewire service by @dhh
* Install libyaml before attempting to install ruby by @vrinek
* Add Helium browser to supported browsers list in omarchy-launch-webapp by @Furyfree
* Add Apple SPI keyboard support for MacBook8,1, MacBook9,1, MacBook10,1 by @e-minguez + @joelgaff
* Add support for Broadcom BCM4331 chipset alongside BCM4360 for MacBooks by @mrlarsendk
* Fix for '(null)' display on AirPod source selection by @shawnyeager
* Fix omarchy-tui-install not keeping $TERMINAL by @djordje
* Use output display or region geometry to record by @iamobservable

### ISO Updates
* Add missing alsa-firmware by @ryanrhughes
* Fix hanging issue for normal boot when using Ventoy by @ryanrhughes
* Update to archiso v86 by @ryanrhughes
* Update to archinstall v3.0.11 by @ryanrhughes
* Fix invalid keyboard options by @ryanrhughes + @rixlabs + @CastilhoBorges

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.0.1...v3.0.2
```

</details>
