# Omarchy v3.1.1 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v3.1.0
**Commits**: 10
**Source**: GitHub release notes

---

## Summary

v3.1.1 is a patch release focused on bug fixes and minor ergonomic improvements to keybindings. It addresses locale-dependent RAM detection, a workspace mouse-scroll regression, and a walker migration that was not running universally. Two small UX additions round out the release: a tiled fullscreen toggle binding and clipboard keybind descriptions.

## Features

- **Tiled fullscreen toggle binding**: A new Hyprland keybinding for toggling tiled fullscreen mode was added. Omarchy path: likely `hyprland.conf` or a keybindings include file.
- **Clipboard keybind descriptions**: Descriptions were added to existing clipboard keybindings, improving discoverability in keybind help overlays.
- **Terminal install error fallback**: An error fallback path was added for cases where the terminal emulator was not installed successfully during setup.

## Bug Fixes

- **Mouse-scroll workspace switching**: Fixed regression where changing workspaces via mouse scroll was broken.
- **Universal RAM detection**: Fixed RAM detection to be locale-independent, resolving failures on systems with non-English locale formatting for numeric output.
- **Update walker migration**: Fixed the walker migration so it runs for all users, not just a subset.

## Breaking Changes

*None*

## Improvements

*None*

## Configuration Changes

*None*

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What's Changed

* Add binding for tiled full screen toggle by @brianblakely
* Fix changing workspace with mousescroll by @dhh
* Add descriptions to clipboard keybinds by @timohubois
* Add error fallback if terminal was not installed successfully by @jondkinney
* Fix universal RAM detection (locale-independent) by @brunoh3art
* Fix update walker migration to run for everyone by @ryanrhughes

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.1.0...v3.1.1
```

</details>
