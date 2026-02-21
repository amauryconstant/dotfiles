# Omarchy v1.6.1 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.6.0
**Commits**: 20
**Source**: GitHub release notes

---

## Summary

v1.6.1 is a focused polish release adding themed on-screen displays (OSD) for brightness, volume, and media player controls. It expands database options in Docker setups, hardens authentication limits, and fixes several small bugs across screenshot tools, package management, input handling, and UI styling.

## Features

- **Themed on-screen displays (brightness/volume)**: New OSD overlays for brightness and volume changes, styled with the active theme. Omarchy path: not confirmed from notes alone.
- **Player controls in OSD**: Media player controls (play/pause/skip) integrated into the on-screen display component.
- **Sunset Lake background for Tokyo Night**: A new wallpaper ("Sunset Lake") added as the first background option for the Tokyo Night theme variant.
- **MariaDB in Docker DB setups**: MariaDB added as a selectable database option alongside existing choices in Docker-based database configuration scripts.
- **Increased PAM lock limit**: The `pamlock` failure threshold raised from 3 to 10 attempts to reduce inadvertent sudo lockouts.

## Bug Fixes

- **Satty screenshot window size**: The Satty screenshot manipulation window is now forced to a fixed size, preventing layout issues.
- **NVIDIA package DB refresh**: Fixed package database refresh step during NVIDIA driver installation.
- **inputrc interactive-only loading**: `inputrc` is now loaded only on interactive terminals, preventing it from affecting non-interactive shell sessions.
- **Walker CSS URL**: Corrected a broken URL reference in the Walker launcher CSS.

## Breaking Changes

*None*

## Improvements

- **PAM authentication resilience**: Raising the lockout threshold from 3 to 10 reduces friction for users who mistype passwords under sudo without disabling lockout protection entirely.

## Configuration Changes

- **inputrc conditional loading**: The `inputrc` configuration is now guarded to load only in interactive terminals. Files affected: `inputrc` (or its sourcing hook in shell init). No format change — loading condition added.
- **PAM lockout limit**: `pamlock` limit value changed from `3` to `10` in the relevant PAM configuration file.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `mariadb` (Docker option) | Alternative relational DB for Docker DB setups |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add themed on-screen displays for brightness and volume by @aifrim
* Add player controls to on-screen display by @precision
* Add Sunset Lake as the first background for Tokyo Night by @dhh
* Add MariaDB as option for Docker DB setups by @spdawnson
* Add an increased pamlock limit from 3->10 to prevent sudo errors by @dhh
* Fix Satty screenshot manipulation window should be a fixed size by @mtk3d
* Fix package db refresh for nvidia install by @abenz1267
* Fix inputrc should only load on interactive terminals by @dhh
* Fx walker css url by @ludo237

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.6.0...v1.6.1
```

</details>
