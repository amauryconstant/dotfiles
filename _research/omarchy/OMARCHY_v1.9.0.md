# Omarchy v1.9.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.8.0
**Commits**: 54
**Source**: GitHub release notes

---

## Summary

v1.9.0 is a broad quality-of-life release spanning screensaver support, system-state notifications (update available, reboot required), icon theme improvements, and a large set of bug fixes. It touches Waybar, the power menu (Walker), workspace visuals, theme configuration, and several application-level compatibility issues.

## Features

- **Screensaver auto-start**: Screensaver activates after 1 minute of inactivity by default and is integrated into the power menu. Omarchy path: likely `install/` and Walker power menu config.
- **Update available notification**: A Waybar icon invites the user to update Omarchy when a new version is available. Omarchy path: Waybar config and/or an omarchy-update script.
- **Reboot prompt after kernel upgrade**: After running `omarchy-update`, the system invites a reboot when the Linux kernel has been upgraded. Omarchy path: `omarchy-update` script.
- **Faded numbers for empty workspaces**: Hyprland/Waybar workspace indicators display faded numbers for inactive/empty workspaces. Omarchy path: Waybar workspace style config.
- **Yaru-based icon themes**: Icon themes using Yaru colors are added to all default Omarchy themes. Omarchy path: theme directories.
- **Custom icon theme override**: Each theme now supports a `icons.theme` file that can specify a custom icon theme name. Omarchy path: per-theme config directory.
- **Inline diff for config updates**: When Omarchy updates config files with new defaults, an inline diff is shown to the user. Omarchy path: omarchy-refresh or update scripts.
- **Backup timestamps for omarchy-refresh**: `omarchy-refresh-*` scripts now include timestamps in backup filenames to prevent overwriting previous backups. Omarchy path: `omarchy-refresh-*` scripts.

## Bug Fixes

- **Waybar stacking (again)**: Waybar stacking in certain situations was fixed again (prior fix was incomplete). Omarchy path: Waybar launch/configuration.
- **Power menu sort codes in non-English locales**: Walker power menu options displayed sorting codes when the system language was not English; the codes have been removed since Walker does not require them.
- **Walker file finder migration**: Fixed a migration script that adds the file finder entry to Walker's configuration.
- **bat system theme**: Fixed `bat` so it uses the system theme rather than a hardcoded or default theme. Omarchy path: bat config.
- **Screensaver vertical shift between animations**: Fixed the screensaver shifting upward between animation transitions. Omarchy path: screensaver config.
- **Decryption screen logo centering**: Fixed the LUKS/decryption screen logo being off-center on some monitor configurations. Omarchy path: Plymouth or initramfs theme.
- **Ristretto neovim plugin compatibility**: Fixed a ristretto configuration that caused incompatibility with some Neovim plugins. Omarchy path: ristretto config.
- **Screensaver key cancellation**: Fixed that pressing any key should cancel the screensaver (previously did not reliably dismiss it). Omarchy path: screensaver config.

## Breaking Changes

*None*

## Improvements

- **omarchy-refresh-* backup safety**: Backup filenames now include timestamps, preventing clobbering when the refresh script is run multiple times.
- **Inline diff visibility**: Config file updates from Omarchy defaults now show a diff inline, giving users visibility into what changed before accepting.

## Configuration Changes

- **icons.theme file**: Each theme directory now supports an `icons.theme` file. Setting a value in this file overrides the icon theme name used for that theme. This is a new optional file; existing installations without it continue to use the Yaru-based defaults added in this release.
- **Screensaver idle timeout**: Idle timeout defaulting to 1 minute is a new default. No user file is required unless overriding. Omarchy path: screensaver/hypridle config.
- **Walker power menu**: Sorting codes removed from power menu option labels. Existing custom Walker configs with sorting codes may display differently but functionally are unaffected.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | screensaver (hypridle/hyprlock or equivalent) | Idle screensaver support added by default |

*Note: exact package name not specified in release notes; inferred from screensaver feature addition.*

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add starting screensaver after 1 minute by default and include it in the power menu by @dhh
* Add invitation to update Omarchy when a new version is available via waybar icon by @dhh
* Add invitation to reboot the system when the Linux kernel has been upgraded after `omarchy-update` by @dhh
* Add faded numbers for empty workspaces by @brink-lab
* Add icon themes using Yaru colors to all default themes by @dhh
* Add option for all themes to put a custom icon theme name in `icons.theme` file by @dhh
* Add inline diff when config files are updated with new Omarchy defaults by @dhh
* Add backup timestamps to omarchy-refresh-* to prevent clobbering by @ardavis
* Fix (again) that Waybar would stack in certain situations by @ryanrhughes
* Fix power menu options showing sorting codes in languages other than English by removing them (walker doesn't need them) by @dhh
* Fix migration for adding file finder to Walker by @ardavis
* Fix that bat should use system theme by @cannikin
* Fix screensaver shifting up between animations by @ryanrhughes
* Fix decryption screen logo being off-center on some monitors by @ryanrhughes
* Fix ristretto neovim compatibility with some plugins by @gthelding
* Fix that pressing any key should cancel the screensaver by @dhh

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.8.0...v1.9.0
```

</details>
