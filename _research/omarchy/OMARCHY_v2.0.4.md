# Omarchy v2.0.4 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v2.0.3
**Commits**: 13
**Source**: GitHub release notes

---

## Summary

v2.0.4 is a pure bug-fix release addressing four regressions introduced in or before v2.0.3. The fixes cover a now-unnecessary package pin (removed following a repo shrink), an iwd service that incorrectly started during installation, a keyboard layout issue at install time, and a broken battery icon click action that failed to open the power menu.

## Features

*None*

## Bug Fixes

- **Remove obsolete package pin**: A package was pinned to work around a constraint that no longer exists after the Omarchy repo was shrunk. The pin has been removed.
- **iwd service not started during installation**: The `iwd` (wireless daemon) service was being started during the install phase when it should not be. Corrected so iwd does not start at install time.
- **Keyboard layout at install**: The keyboard layout was not applied correctly during installation. Fixed so the selected layout is honoured from the start of the install process.
- **Battery icon opens power menu on click**: Clicking the battery icon in the status bar did not open the power menu as expected. The click binding has been restored/corrected.

## Breaking Changes

*None*

## Improvements

*None*

## Configuration Changes

- **Battery icon click binding**: The Waybar battery module configuration was updated to wire the click action to the power menu launcher. Relevant file is the Waybar config within the Omarchy repo (exact path: `install/waybar/` or equivalent battery module config).

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Removed (pin) | *(unnamed pinned package)* | Pin was no longer needed after Omarchy repo shrink; package itself remains but version pin dropped |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Fix pinning package no longer needed after we shrinked the Omarchy repo by @dhh
* Fix iwd service shouldn't start during installation by @dhh
* Fix keyboard layout at install by @bastnic in https://github.com/basecamp/omarchy/pull/1188
* Fix clicking on the battery icon should open the power menu by @cstrickjacke in https://github.com/basecamp/omarchy/pull/1178

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v2.0.3...v2.0.4
```

</details>
