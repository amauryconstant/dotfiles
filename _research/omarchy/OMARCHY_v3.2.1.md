# Omarchy v3.2.1 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.2.0
**Commits**: 24
**Source**: GitHub release notes

---

## Summary

Bugfix-heavy patch release with 10 fixes and 2 additions. Fixes address screensaver fullscreen rendering, window management edge cases, Bluetooth TUI state, and installer UX for Vulkan backend selection.

## Features

- **Package release channel + last update date on About screen**: About screen now shows release channel and last update date for installed packages.
- **Copy URL to clipboard in Brave**: `Alt + Shift + L` copies current URL to clipboard in Brave browser.

## Bug Fixes

- Screensaver now truly fullscreen on Ghostty/Kitty (was already correct on Alacritty)
- `omarchy-refresh-pacman` now backs up `/etc/pacman.conf` and `/etc/pacman.d/mirrorlist` before overwriting
- PDF viewer now opens in floating mode (consistent with image/video viewers)
- Steam + Zed installers now prompt for correct Vulkan backend
- Experimental `dev_worm` screensaver effect excluded (too slow)
- Remove > TUI fixed to work with new xdg-terminal setup
- Window pop fixed: was applying wrong tag and required double invocation to undo
- Bluetooth icon now reflects off state when BT adapter disabled in BlueTUI
- `omarchy-refresh-walker` now ensures Elephant service is running and Walker is in autostart
- Wifi prompt suppressed during ISO install

## Breaking Changes

*None*

## Configuration Changes

*None*

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

## Additions
* Add release channel and last update date for packages to the About screen by @dhh
* Add copy-url-to-clipboard (hotkey `Alt + Shift + L`) for Brave by @Blinkuu

## Fixes
* Fix screensaver to be truly fullscreen on Ghostty/Kitty as it is on Alacritty by @felixzsh
* Fix `omarchy-refresh-pacman` should backup `/etc/pacman.conf` and `/etc/pacman.d/mirrorlist` before overwriting by @dhh
* Fix PDF viewer should start in floating mode (like image and video viewers) by @dhh
* Fix Steam + Zed installers to give user a chance to pick the correct vulkan backend for their system by @dhh
* Fix screensaver should not include the new experimental (and very slow) `dev_worm` effect by @MirasMustimov
* Fix Remove > TUI to work with new xdg-terminal setup by @neurapy
* Fix window pop wasn't applying the right tag and required double invocation to undo by @dhh
* Fix Bluetooth icon wouldn't switch to off when turning off the BT adapter in BlueTUI by @dhh
* Fix `omarchy-refresh-walker` should ensure that Elephant service is running + add Walker to autostart by @dhh
* Fix prevent wifi prompt from showing during ISO install by @ryanrhughes

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.2.0...v3.2.1
```

</details>
