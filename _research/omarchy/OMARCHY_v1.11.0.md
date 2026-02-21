# Omarchy v1.11.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.10.0
**Commits**: 90
**Source**: GitHub release notes

---

## Summary

v1.11.0 is a significant structural release centered on the replacement of the legacy `omarchy` TUI with a new unified `omarchy-menu` system accessible via `Super + Alt + Space` and a persistent desktop icon. Alongside the menu overhaul, the Hyprland configuration has been split from a single `hyprland.conf` into multiple dedicated files to support direct in-menu editing. Several long-standing bug fixes address hypridle timing, picture-in-picture window placement, hyprpicker toggle behavior, and fido2 error handling.

## Features

- **Unified Omarchy menu (`omarchy-menu`)**: Replaces the old `omarchy` TUI with a single consolidated interface for controlling system settings. Launched via `Super + Alt + Space` or a new icon in the upper-left corner of the desktop. Omarchy path: not confirmed from notes alone.
- **Touchpad gestures in Chrome**: Chrome now receives touchpad gesture support. Omarchy path: not confirmed from notes alone.
- **In-menu `omarchy-update`**: Starting from this version, system updates can be triggered directly from within the Omarchy menu, in addition to the existing `omarchy-update` CLI command.

## Bug Fixes

- **Picture-in-picture window positioning**: Fixed incorrect placement of picture-in-picture windows.
- **Hypridle screensaver timing**: Fixed a bug where the screensaver would activate after 2.5 minutes instead of the configured interval.
- **Hyprpicker toggle behavior**: Fixed hyprpicker stacking on repeated invocations; it now toggles correctly.
- **Fido2 setup error handling**: Fixed error handling in the fido2 setup flow.

## Breaking Changes

- **`hyprland.conf` split into multiple files**: `~/.config/hypr/hyprland.conf` has been divided into several dedicated files. During `omarchy-update`, the user is prompted to confirm the new layout. Accepting resets Hyprland config to Omarchy defaults; prior customizations are backed up to `~/.config/hypr/hyprland.conf/bak.$timestamp`. Users must manually copy their settings from the backup to the appropriate new file(s).
- **`omarchy` TUI retired**: The `omarchy` command and its TUI have been replaced by `omarchy-menu`. Scripts or keybindings that invoke `omarchy` directly will no longer function as before.

## Improvements

- **Omarchy menu consolidation**: The majority of system-control commands have been reworked and unified under `omarchy-menu`, reducing the number of discrete entry points for configuration.

## Configuration Changes

- **`hyprland.conf` restructured**: Single monolithic `~/.config/hypr/hyprland.conf` split into multiple dedicated config files within `~/.config/hypr/`. This enables the Omarchy menu to perform direct targeted edits. The update script backs up the existing file to `~/.config/hypr/hyprland.conf/bak.$timestamp` before applying the new layout.
- **New keybinding for Omarchy menu**: `Super + Alt + Space` now launches `omarchy-menu` (replacing whatever invoked the old `omarchy` TUI).

## Package Changes

*None* (no explicit package additions or removals identified in release notes)

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add new unified Omarchy menu system by @dhh
* Add touchpad gestures to Chrome by @ryanrhughes
* Fix picture-in-picture window positioning by @ElFitaFlores + @dhh
* Fix hypridle screensaver starting after actually 2.5 minutes by @rmacklin
* Fix hyprpicker should toggle not stack by @dhh
* Fix error handling in fido2 setup by @DavidHoenisch

Update using `omarchy-update`. From this version forward, you can update via the Omarchy menu.

The old `omarchy` TUI has been replaced by `omarchy-menu`. You can start it using `Super + Alt + Space` or from the new icon in the upper left corner.

Note: The `~/.config/hypr/hyprland.conf` has been divided into several dedicated files. The update process will ask you to confirm that you want the new layout (which enables some direct editing via the new menu system). If you say yes, you'll be reset to Omarchy defaults, but your own settings will still be in `~/.config/hypr/hyprland.conf/bak.$timestamp`, and you can just copy them to the right place.

### New unified Omarchy menu system

The old Omarchy TUI has been retired, a ton of the commands have been reworked, and we now have a single way to control just about everything about the system.

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.10.0...v1.11.0
```

</details>
