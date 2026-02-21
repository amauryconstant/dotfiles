# Omarchy v3.1.2 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.1.1
**Commits**: 57
**Source**: GitHub release notes

---

## Summary

v3.1.2 is a feature and polish release focused on Windows VM compatibility improvements, new keyboard shortcuts and notification commands, and several new maintenance/debug utilities. The release also addresses a cluster of update-reliability and bootloader configuration bugs introduced or discovered since v3.1.1.

## Features

- **Dynamic Windows VM resources**: Adds dynamic resolution, sound, microphone, AVC444 graphics, and tiling compatibility to the Windows VM configuration. Contributors: @ATeal, @boozlbork, @garovu, @dhh.
- **Tile-group window navigation**: `Super + Alt + Mouse scrolling` moves between windows within a tile group.
- **omarchy-debug**: New CLI utility to collect and output debug logs for troubleshooting.
- **omarchy-refresh-limine**: New CLI utility to reset Limine bootloader configs to defaults.
- **omarchy-reinstall**: New CLI utility to reset all Omarchy configs (full reinstall).
- **Show time notification**: `Super + Ctrl + T` displays current time as a desktop notification.
- **Show battery notification**: `Super + Ctrl + B` displays current battery level as a desktop notification.
- **Omarchy menu time sync**: New "Update > Time" entry in the Omarchy menu triggers an NTP time sync.
- **omarchy-launch-terminal with fallback**: `omarchy-launch-terminal` now has a fallback path for when environment variables become unset.
- **Right-click terminal launch**: Right-clicking the Omarchy menu icon now launches a terminal, providing access when keybindings are unavailable.

## Bug Fixes

- Remove branch from Omarchy menu
- Fix VSCode self-update disable check
- `Update > Extra Themes` now correctly updates only git-based themes, excluding Aether
- bashrc inclusion now exits early when shell is non-interactive
- Fixed crash in `omarchy-update` when Waybar was not running
- Fixed Limine bootloader to present its default screen on all new installs
- Errors during update process now caught more consistently
- Fixed Neovim syntax highlighting error after initial setup

## Breaking Changes

*None*

## Configuration Changes

- **Limine bootloader**: Config changed so default screen is active for all new installs
- **Omarchy menu**: Branch display removed; "Update > Time" entry added; right-click on menu icon now triggers terminal launch
- **Keybindings**: Three new bindings: `Super + Alt + Scroll` (tile-group navigation), `Super + Ctrl + T` (time notification), `Super + Ctrl + B` (battery notification)

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

## New Additions
* Add dynamic resolution, sound, microphone, AVC444 graphics, and tiling compatibility to Windows VM by @ATeal + @boozlbork + @garovu + @dhh
* Add `Super + Alt + Mouse scrolling` to move between windows in a tile group by @mythz
* Add `omarchy-debug` for obtaining debug logs more easily by @ryanrhughes
* Add `omarchy-refresh-limine` to reset limine configs by @ryanrhughes
* Add `omarchy-reinstall` to reset all Omarchy configs by @dhh + @ryanrhughes
* Add `Super + Ctrl + T` to show time in a notification by @dhh
* Add `Super + Ctrl + B` to show battery level in a notification by @dhh
* Add Update > Time via Omarchy menu to update time with latest sync by @dhh
* Add `omarchy-launch-terminal` with fallback in case envs become unset by @ryanrhughes
* Add terminal launch on right click of the Omarchy menu icon in case keybinds are unavailable by @ryanrhughes

## Fixes
* Remove branch from Omarchy menu by @dhh
* Fix VSCode self-update disable check by @sgruendel
* Fix that `Update > Extra Themes` should only update git themes, not Aether by @dhh
* Fix bashrc inclusion should bail when not interactive by @ryanrhughes
* Fix omarchy update breaking when waybar was not running by @dhh
* Fix limine bootloader screen to be default for all new installs by @ryanrhughes
* Fix catch errors during updates more consistently by @ryanrhughes
* Fix nvim syntax highlighting error after setup by @ryanrhughes

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.1.1...v3.1.2
```

</details>
