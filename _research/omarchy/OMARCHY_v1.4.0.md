# Omarchy v1.4.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.3.2
**Commits**: 74
**Source**: GitHub release notes

---

## Summary

v1.4.0 is a large feature release focused on two major areas: a comprehensive TUI management interface and an expanded theme system with third-party theme support. It also ships a wave of quality-of-life fixes covering boot transitions, notification placement, emoji input, fingerprint sensors, and package install reliability.

## Features

- **Omarchy TUI**: Interactive terminal UI for theme switching, setup, updates, and manual access. Omarchy path: likely `install/omarchy` or a top-level launcher script.
- **Menu-based theme switcher**: GUI-driven theme selection, implemented as a menu overlay separate from the TUI. Omarchy path: `themes/` or `bin/`.
- **Theme installer for git-based third-party themes**: Allows installing themes hosted in external git repositories, not just bundled ones. Omarchy path: `themes/` installer script.
- **New matte black theme**: Additional built-in theme variant added to the theme catalog. Omarchy path: `themes/matte-black/` (inferred).
- **Collapsing tray for Dropbox/Keyboard/Zoom icons**: Top bar systray section now collapses icons for those three applications. Omarchy path: Waybar config.
- **Three volume increment icons**: Top bar volume indicator uses distinct icons for low/medium/high volume states. Omarchy path: Waybar config.
- **Default `fonts.conf`**: Ships `.config/fontconfig/fonts.conf` setting Liberation Sans, Liberation Serif, and Caskaydia Cove (Nerd Font) as system-wide font fallbacks. Omarchy path: `config/fontconfig/fonts.conf`.
- **User-editable `wofi/style.css`**: Exposes `.config/wofi/style.css` as a user-owned file for launcher appearance customization. Omarchy path: `config/wofi/style.css`.
- **uwsm integration**: Adds `uwsm` (Universal Wayland Session Manager) to manage Hyprland session startup, eliminating line noise on the boot screen transition. Omarchy path: session launch scripts.
- **Colorized pacman installer output**: The Arch package installer script gains color and pacman-themed visual output.

## Bug Fixes

- **Theme switcher real-directory support**: Theme switcher previously only worked with symlinks; fixed to handle actual directories as theme roots.
- **Active window focus on URL click**: URLs clicked in terminal windows now correctly open in the browser by ensuring the target window receives focus. (PR #152)
- **XCompose emoji and shortcut support**: Fixed XCompose input method compatibility so emoji and shortcuts work in Typora.
- **Fingerprint setup script compatibility**: Broadened fingerprint enrollment script to support a wider range of sensor hardware. (contributors: deanpcmad, anagrius)
- **Removed unnecessary `xdg-data-dir` env for wofi**: The variable was set but not needed by wofi, and caused breakage with Wine and Flatpak applications. (PR #184)
- **Keyserver fallback for Spotify/Zoom GPG keys**: Flaky installs caused by unavailable keyservers are mitigated by adding backup keyserver entries. (PR #180)

## Breaking Changes

*None*

## Improvements

- **Notification margin**: Notifications are offset further from the top-right edge of the screen to avoid overlapping application chrome. (PR #160)
- **Waybar theme color integration**: Better mapping of theme color variables into Waybar's styling, improving visual consistency when switching themes.

## Configuration Changes

- **`fonts.conf` added**: New file at `.config/fontconfig/fonts.conf` sets Liberation Sans/Serif and Caskaydia as default fonts. Systems without this file previously had no Omarchy-managed fontconfig defaults.
- **`wofi/style.css` promoted to user-editable**: Previously managed or absent; now explicitly provided as a user customization point.
- **Waybar config**: Extended for collapsing tray, three-state volume icons, and improved theme color variable usage.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `uwsm` | Universal Wayland Session Manager for clean Hyprland boot transition |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add menu-based theme switcher by @npenza in #154
* Add collapsing tray for dropbox/keyboard/zoom icons in top bar by @leonhazen in #130
* Add new matte black theme by @tahayvr
* Add Omarchy TUI for easier theme/setup/update/manual access by @npenza and @dhh in #116
* Add theme installer for git-based third-party themes by @npenza in #150
* Add margin to the notifications to better offset them from top-right application by @ryanrhughes in #160
* Add uwsm to improve boot screen transition to Hyprland without line noise by @ryanrhughes in #140
* Add three different icons for increasing volume in top bar by @kieeps in #158
* Add default .config/fontconfig/fonts.conf to set Liberation Sans/Serif + Caskaydia as defaults in more places by @dhh
* Add color and pacman fun to pacman installer by @rockorager
* Add user-editable `.config/wofi/style.css` by @cannikin
* Add better theme color setting for waybar by @DrInfinite in #156
* Fix theme switcher to work with real directories, not just symlinks by @dhh
* Fix that active window to receive focus so URLs clicked in terminals actual show in browser by @apiguy in #152
* Fix XCompose emoji and shortcut support for Typora by @dhh
* Fix fingerprint setup script compatibility with more sensors by @deanpcmad and @anagrius
* Fix xdg-data-dir env not being necessary for wofi and causing problems with wine/flatpak by @abenz1267 in #184
* Fix flaky installs of spotify/zoom/etc that need a keyserver by adding backups by @abradburne in #180

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.3.2...v1.4.0
```

</details>
