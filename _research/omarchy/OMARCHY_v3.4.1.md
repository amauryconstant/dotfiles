# Omarchy v3.4.1 — Release Research

**Date researched**: 2026-03-05
**Previous version**: v3.4.0
**Commits**: 48
**Source**: GitHub release notes

---

## Summary

v3.4.1 adds a new Hyprland scrolling layout (togglable with `Super + L`), a display resolution cycling keybind, and an expanded toggle menu. The release addresses ten bug fixes spanning Hyprland 0.54 compatibility, SSH environment availability, input method startup duplication, screen recording on high-DPI displays, and several UI/UX regressions.

## Features

- **Hyprland scrolling layout toggle**: `Super + L` switches between Hyprland's new scrolling layout and the existing dwindle layout. Omarchy path: Hyprland keybind config.
- **Display resolution cycling**: `Super + /` cycles through available display resolutions, replacing the previous `Super + Ctrl + Alt + Backspace` shortcut. Omarchy path: Hyprland keybind config.
- **Toggle menu (`Super + Ctrl + O`)**: A new toggle menu is accessible via `Super + Ctrl + O`, consolidating controls for Window Gaps, 1-Window Ratio, and Display Scaling. Omarchy path: launcher/menu script.
- **tmux navigation keybinds**: `Alt + left/right` moves between tmux windows; `Alt + up/down` moves between tmux sessions. Omarchy path: tmux config.

## Bug Fixes

- **Hyprland 0.54 compatibility**: Resolved breakage introduced by the Hyprland 0.54 release.
- **fcitx5 double auto-start**: fcitx5 was being started twice on login; corrected to a single invocation.
- **SSH environment variables**: `OMARCHY_PATH` and `PATH` were not available in SSH sessions into Omarchy machines; now exported correctly.
- **omarchy-launch-or-focus**: Breakage caused by a `jq` replacement was fixed.
- **ASUS mic unmute at install**: ASUS device microphone was not being unmuted during installation; corrected.
- **SDDM password field overflow**: Visual overflow in the SDDM login screen password field resolved.
- **Hyprland update reboot prompt**: Omarchy updates that include a new Hyprland version now offer a reboot prompt.
- **Screen recording on 4K+ displays**: Screen recording was broken on 4K and higher-resolution displays; also switched to constant frame-rate output for easier post-editing without transcoding.
- **Terminal output without trailing newline**: Terminal output lacking a trailing newline was silently dropped; now handled correctly.
- **Screensaver animation**: Screensaver now uses `slidein` instead of `popin` animation.

## Breaking Changes

*None*

## Improvements

- **Display resolution shortcut ergonomics**: `Super + /` replaces the previous multi-modifier `Super + Ctrl + Alt + Backspace` shortcut, reducing hand strain for a common operation.
- **Toggle menu consolidation**: Window Gaps, 1-Window Ratio, and Display Scaling controls are now grouped in a single accessible menu rather than separate keybinds.
- **Screen recording output quality**: Constant frame-rate recording simplifies post-production by eliminating the need to transcode before editing.

## Configuration Changes

- **Hyprland keybinds**: `Super + /` now maps to display resolution cycling (previously `Super + Ctrl + Alt + Backspace`). `Super + L` added for layout toggle. `Super + Ctrl + O` added for toggle menu.
- **tmux config**: `Alt + left/right` and `Alt + up/down` binds added for window and session navigation.
- **fcitx5 autostart**: Startup configuration deduplicated to prevent double invocation.
- **SSH environment**: `OMARCHY_PATH` added to SSH-forwarded environment variables.

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
## What's Changed

Update existing installations using `Update > Omarchy` from Omarchy menu (`Super + Alt + Space`).

Install on new machines with the ISO:
- Download: https://iso.omarchy.org/omarchy-3.4.1-2.iso
- SHA256: bad8ccd14a715ec5d67ab61c9e8258c1cee44176cf35050e72e047506f1c1120

## Additions

- Add `Super + L` to toggle between the new Hyprland scrolling layout and the existing dwindle layout by @dhh
- Add `Super + /` to cycle display resolutions (instead of the awkward `Super + Ctrl + Alt + Backspace`) by @dhh
- Add `Super + Ctrl + O` to open the new toggle menu (which now includes Window Gaps, 1-Window Ratio, Display Scaling) by @dhh
- Add `Alt + left/right` for moving between tmux windows and `alt + up/down` to move between sessions by @dhh, @marcotroisi

## Fixes

- Fix compatibility with Hyprland 0.54 by @dhh
- Fix fcitx5 being auto-started twice by @pomartel
- Fix OMARCHY_PATH and PATH not being available when SSH'ing into Omarchy machines by @dhh, @alexpgates
- Fix omarchy-launch-or-focus breakage on jq replacemeny by @garethson
- Fix ASUS mic unmute at installation time by @KrisKind75
- Fix SDDM password field overflow by @dhh
- Fix Omarchy updates that include new Hyprland should offer a reboot by @dhh
- Fix screenrecording on 4K+ displays and use constant frame-rate for easier post-editing without transcoding by @dhh
- Fix terminal output without a newline would be swallowed by @dhh
- Fix screensaver should use slidein instead of popin animation by @ieocin
```

</details>
