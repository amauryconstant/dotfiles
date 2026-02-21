# Omarchy v1.2.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.1.1
**Commits**: 50
**Source**: GitHub release notes

---

## Summary

v1.2.0 is a quality-of-life release focused on Waybar enhancements and usability improvements. It adds a power menu to the top bar, introduces notification hotkeys and bash completions, and fixes several UX issues with fingerprint enrollment and floating dialogs.

## Features

- **Power menu in Waybar**: A wlogout-style power menu is added to the Waybar top bar. Omarchy paths: `~/.config/waybar/config`, `~/.config/waybar/style.css`.
- **Bash completion**: Shell completion support added for omarchy commands. Contributor: @smola (#80).
- **Notification hotkeys**: Three new Hyprland keybindings for dunst notification control. `Super+,` dismisses the latest notification, `Super+Shift+,` dismisses all, `Super+Ctrl+,` toggles Do Not Disturb. Omarchy path: `~/.config/hypr/hyprland.conf`.
- **Video thumbnails in file manager**: Thumbnail generation for video files enabled in the file manager (Thunar or equivalent).
- **Additional input suggestions**: Extra input method suggestions added to the default `~/.config/hypr/hyprland.conf`.

## Bug Fixes

- **Fingerprint enrollment user scope**: `omarchy-enroll-fingerprint` (or equivalent) fixed to enroll for the current user rather than a hardcoded or root user. Contributor: @zdehasek (#69).
- **Floating file dialogs**: File Open/Save overlay windows now float in the center of the screen as expected. Omarchy path: Hyprland window rules config.

## Breaking Changes

*None*

## Improvements

- **Waybar cleanup**: Dropbox and power profile icons removed from the top bar. Both were deemed low-value and cluttered the bar.

## Configuration Changes

- **Waybar config** (`~/.config/waybar/config` and `~/.config/waybar/style.css`): Power menu module added; Dropbox and power profile modules removed. Users who have customized these files must manually merge the changes — running `omarchy-refresh-waybar` overwrites the files entirely.
- **Hyprland config** (`~/.config/hypr/hyprland.conf`): Three new keybind entries for notification control (`Super+,`, `Super+Shift+,`, `Super+Ctrl+,`); additional input suggestion entries added.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `ffmpegthumbnailer` (likely) | Video thumbnail generation in file manager |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add power menu to waybar by @npenza in #65
* Add bash completion by @smola in #80
* Add hotkeys for notifications: `Super+,` to dismiss latest. `Super+Shift+,` to dismiss all. `Super+Ctrl+,` to toggle DND by @ThiaudioTT , @ryanrhughes, and @dhh
* Add thumbnails for videos in the file manager by @dhh
* Add additional input suggestions to default `.config/hypr/hyprland.conf` by @dhh
* Fix fingerprint enrollment to be for current user by @zdehasek in #69
* Fix that File Open/Save overlays should float in center by @dhh
* Remove Dropbox and power profile icons from top bar (not enough value) by @dhh

## Upgrading

You upgrade by running `omarchy-update` in the terminal. If you'd like to get the new power menu in the top bar, you can run `omarchy-refresh-waybar` — but only do that if you have not made changes to `~/.config/waybar/config` or `~/.config/waybar/style.css`! If you have made changes, first back those up, then merge them back in. Or just look how to add the new power menu yourself.

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.1.1...v1.2.0
```

</details>
