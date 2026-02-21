# Omarchy v1.12.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.11.0
**Commits**: 28
**Source**: GitHub release notes

---

## Summary

v1.12.0 significantly expands the Omarchy menu with new Install and Setup sections covering editors, fonts, and power profiles, and elevates font management from a shell-out to a first-class Walker interface that propagates changes to Waybar, SwayOSD, and fontconfig. The release also adds media transcoding shell functions and resolves several menu and system-level bugs including a stuck Walker service, broken mDNS printer config, and screensaver cursor visibility.

## Features

- **Osaka Jade theme**: New theme added to the default collection. Omarchy path: `themes/` (contributed by @Justikun).
- **Style > Font as Walker interface**: Font selection is now handled via a Walker walker interface inside the Omarchy menu instead of shelling out to an external command.
- **Font changes propagate system-wide**: Selecting a font via Style > Font now updates Waybar, SwayOSD, and fontconfig in addition to the terminal/app target.
- **Install > Editor section**: New Omarchy menu section providing one-shot install options for VSCode, Cursor, and Zed.
- **Install > Font section**: New Omarchy menu section with install options for Meslo, Fira Code, Victor Code, and Bitstream Vera fonts.
- **Setup > Power Profiles**: New Omarchy menu section to switch `powerprofilesctl` profiles (e.g. balanced, performance, power-saver).
- **Media transcoding functions**: Three new shell functions added — `transcode-video-1080p`, `transcode-video-4k`, and `transcode-png2jpg` — for common media conversion workflows.

## Bug Fixes

- **Wrong workspace number descriptions**: Corrected incorrect workspace number labels in Hyprland default keybind descriptions (fix by @pastr).
- **Broken multicast DNS printer config**: Fixed mDNS configuration that was preventing printer discovery (fix by @oppegard).
- **Escape from Install/Remove > Package triggers sudo**: Escaping out of the Install > Package or Remove > Package flows no longer incorrectly prompts for sudo.
- **Stuck Omarchy menu**: Resolved a Walker service hang by upgrading to the latest Walker release and restarting the service.
- **Remove > Theme selector broken**: Fixed the Remove > Theme selector which was not functioning correctly (fix by @gyllen and @xadcv).
- **Screensaver cursor visibility**: Screensaver now always uses a black background and hides the cursor (fix by @manuel1618).

## Breaking Changes

*None*

## Improvements

- **Walker-native font picker**: Font selection flow is more integrated and reliable by using Walker's walker interface instead of subprocess shell-outs.
- **Font change scope**: A single font selection action now consistently applies across Waybar, SwayOSD, and fontconfig, reducing manual follow-up steps.

## Configuration Changes

- **Hyprland default binds**: Workspace number descriptions corrected in the default binds config file. No format change — descriptive comment strings only.
- **Screensaver config**: Updated to enforce black background and cursor hiding. Omarchy path: screensaver-related config (exact file determinable via diff).
- **mDNS/printer config**: Multicast DNS configuration corrected. Omarchy path: printer setup scripts or config (exact file determinable via diff).
- **Fontconfig integration**: Font selection now writes to fontconfig in addition to existing targets.
- **Walker service**: Omarchy menu startup/restart logic updated to accommodate latest Walker version.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Upgraded | `walker` | Latest Walker version required to fix stuck Omarchy menu |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add Osaka Jade theme to default collection by @Justikun
* Add Style > Font as a walker interface in Omarchy menu rather than shelling out by @dhh
* Add Style > Font changes will now be reflected in Waybar, SwayOSD, fontconfig as well by @dhh
* Add Install > Editor section in Omarchy menu with common options for VSCode, Cursor, and Zed by @dhh
* Add Install > Font with options for Meslo, Fira Code, Victor Code, Bitstream Vera common options by @dhh
* Add Setup > Power Profiles to change powerprofilectl options via Omarchy menu by @dhh
* Add transcode-video-1080p, transcode-video-4k, transcode-png2jpg functions for common media workflows by @dhh
* Fix wrong workspace number descriptions in hyprland default binds by @pastr
* Fix broken multicast dns config for printers by @oppegard
* Fix that escaping out of Install > Package and Remove > Package shouldn't ask for sudo in Omarchy menu by @dhh
* Fix the stuck Omarchy menu by upgrading to latest Walker and restarting the service by @dhh
* Fix Remove > Theme selector wasn't working right by @gyllen + @xadcv
* Fix screensaver should always use a black background and hide the cursor by @manuel1618

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.11.0...v1.12.0
```

</details>
