# Omarchy v1.7.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.6.2
**Commits**: 32
**Source**: GitHub release notes

---

## Summary

v1.7.0 is a feature and polish release across three themes: new user-facing functionality (screensaver shortcut, ALT+TAB window cycling, a new brown "ristretto" theme), better system metadata exposure (Omarchy version in the About app), and a round of fixes to defaults, window behavior, and UI presentation. The release includes contributions from seven distinct contributors.

## Features

- **Screensaver shortcut**: Pressing `SUPER + ALT + SPACE` activates an Omarchy screensaver. Added by @dhh.
- **Ristretto brown theme**: A new built-in color theme named "ristretto" with a warm brown palette. Added by @gthelding.
- **ALT+TAB window cycling**: `ALT+TAB` now cycles between windows on the active workspace, including floating windows. Added by @c4software.
- **Omarchy version in About app**: The About application now displays the current Omarchy version. Added by @tahayvr.

## Bug Fixes

- **About app float and center**: The About app now correctly floats and centers on screen.
- **Update logos cleaned up**: Application logos updated to use a cleaned-up version. Fixed by @seanmitchell.
- **Default monitors.conf expanded**: The default `monitors.conf` now includes more commented examples to guide configuration. Fixed by @dhh.
- **Default .bashrc improved**: The default `.bashrc` now includes examples and explanatory comments. Fixed by @dhh.
- **Theme menu picker sorting**: The theme selection menu is now sorted. Fixed by @dhh.
- **Steam window centering scoped**: Steam centering rule now applies only to the Steam main window, not all Steam windows. Fixed by @sobran.

## Breaking Changes

*None*

## Improvements

- **ALT+TAB includes floating windows**: Window cycling via `ALT+TAB` is not restricted to tiled windows; floating windows on the active workspace are included in the cycle.
- **monitors.conf discoverability**: Additional examples in the default `monitors.conf` reduce the configuration burden for users with non-standard monitor setups.

## Configuration Changes

- **`monitors.conf` default**: More example entries added to the default monitors configuration file to document common setups.
- **`.bashrc` default**: Default `.bashrc` updated with usage examples and inline comments explaining the available configuration options.

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add new Omarchy screensaver on SUPER + ALT + SPACE by @dhh
* Add a beautiful brown ristretto theme by @gthelding
* Add ALT+TAB to cycle between windows, including floating ones, on the active workspace by @c4software
* Add Omarchy version to About app by @tahayvr
* Fix About should float and center
* Fix update logos to use the cleaned up version by @seanmitchell
* Fix default monitors.conf to include more examples by @dhh
* Fix default .bashrc to offer examples and explanation by @dhh
* Fix sorting of the theme menu picker by @dhh
* Fix restricting Steam centering to only the main window by @sobran

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.6.2...v1.7.0
```

</details>
