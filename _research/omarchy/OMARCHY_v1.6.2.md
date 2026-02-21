# Omarchy v1.6.2 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.6.1
**Commits**: 85
**Source**: GitHub release notes

---

## Summary

v1.6.2 is a feature and polish release adding timezone auto-detection via IP geolocation, Chaotic-AUR support for precompiled packages, and several quality-of-life additions to the app launcher, screenshot/screenrecord tooling, and installer UI. The release also addresses a cluster of visual and stability bugs including waybar stacking after sleep, disappearing backgrounds on theme change, and mismatched notification/OSD colors across themes.

## Features

- **Timezone auto-update via geo IP**: Right-clicking the clock triggers a timezone update using IP-based geolocation. Omarchy path: waybar clock module config.
- **Chaotic-AUR support**: Chaotic-AUR repository added as a package source, enabling precompiled AUR packages (e.g., Pinta) without local compilation.
- **Calculator leader key in app launcher**: Typing `=` as a prefix in the app launcher (wofi) triggers inline calculation (e.g., `=5+5` returns `10`).
- **Screenshot/screenrecord output directory overrides**: Environment variables `OMARCHY_SCREENSHOT_DIR` and `OMARCHY_SCREENRECORD_DIR` allow overriding the default output paths for screenshot and screen recording commands.
- **Bare install memory**: The installer now remembers whether a bare install was selected, persisting that choice across sessions.
- **Color terminal installer UI**: The installer is refactored into 5 distinct segments with colored terminal text effects.
- **Updated Omarchy logo**: A cleaned-up version of the Omarchy logo contributed by community members.

## Bug Fixes

- **Waybar stacking after sleep/lock**: Waybar is reloaded on wake/unlock to prevent duplicate bar instances stacking.
- **Background disappearing on theme change**: `swaybg` was exiting after a theme change, causing the wallpaper to disappear; this is now handled to keep the background active.
- **Screenshot stacking on rapid hotkey**: Pressing the screenshot hotkey twice in quick succession no longer results in stacked/duplicate screenshot captures.
- **Mismatched mako/swayosd colors**: Color inconsistencies between mako (notifications) and swayosd (OSD overlay) for certain themes are corrected.
- **Neovim color display**: Replaced the matte black neovim plugin usage with inline color coding for correct color rendering.
- **XDG_DIRS respect for non-English locales**: Screenshot and screenrecord commands now correctly use XDG directory paths for locales other than English.
- **fzf completion path**: Fixed an incorrect fzf completion script path.

## Breaking Changes

*None*

## Improvements

- **Installer UX**: Installer output is segmented into 5 labeled phases with color formatting, improving readability during setup.

## Configuration Changes

- **`OMARCHY_SCREENSHOT_DIR` / `OMARCHY_SCREENRECORD_DIR` env vars**: New optional environment variables control output directories for screenshot and screenrecord commands. Previously these paths were hardcoded. Setting these variables in shell config overrides the defaults.
- **Waybar clock module**: Right-click action on the clock now invokes a geo-IP timezone update script rather than being unbound.
- **Chaotic-AUR pacman source**: `pacman.conf` or equivalent package setup now includes Chaotic-AUR as a repository source.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | Chaotic-AUR repository | Provides precompiled AUR packages (e.g., Pinta image editor) without local AUR build overhead |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add updating timezone (using geo by IP) by right-clicking on the clock by @dhh
* Add color terminal text effects for the installer and break it into 5 distinct segments by @dhh
* Add a cleaned-up version of the Omarchy logo by @tahayvr and @seanmitchell
* Add Chaotic-AUR support for precompiled installations of dependencies like Pinta by @saullrb
* Add = as the leader key for calculations in app launcher (so type =5+5 to get 10) by @ryanrhughes
* Add options to override output from screenshot and screenrecord commands using `OMARCHY_SCREENRECORD_DIR` and `OMARCHY_SCREENSHOT_DIR` by @benhoman
* Add that bare installs are remembered by @JaxonWright
* Fix waybar stacking after sleep/locking by reloading waybar by @dhh
* Fix background would sometimes disappear after changing theme (because swaybg would exit) by @dhh
* Fix screenshot stacking if hitting hotkey twice by @ryanrhughes
* Fix mismatched colors for mako and swayosd for some themes by @dhh
* Fix using matte black neovim plugin instead of inline color coding by @tahayvr
* Fix respect XDG_DIRS for languages other than English for screenshot/screenrecord commands by @michaldziurowski
* Fix fzf completion path by @anagrius

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.6.1...v1.6.2
```

</details>
