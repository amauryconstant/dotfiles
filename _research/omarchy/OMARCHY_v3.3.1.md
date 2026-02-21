# Omarchy v3.3.1 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.3.0
**Commits**: 17
**Source**: GitHub release notes

---

## Summary

Pure bug-fix release. All 8 fixes address regressions from the theme system overhaul in v3.3.0: NVIDIA hardware detection, theme templating, input migration, VSCode theming consolidation, terminal cursor shapes, and Chromium startup on fresh installs.

## Features

*None*

## Bug Fixes

- **NVIDIA older workstation card detection**: Detection logic failed to recognize older professional workstation GPUs. Fix by @Nm1ss.
- **Mako and SwayOSD accent color**: Accent color not applied correctly in theme templates for both apps.
- **Touchpad scroll input rule migration**: Migration of old `input scroll` touchpad rules was broken. Fix by @timohubois.
- **VSCode derivative theming**: Unreliable for VSCode-derived editors (Cursor, VSCodium). All VSCode theme logic now centralized in `omarchy-theme-set-vscode`.
- **colors.toml redundant definitions**: Needless `active_border_color` and `active_tab_background` removed; now derived from `accent`.
- **Kitty cursor shape**: Was not a block; corrected to match Alacritty and Ghostty defaults.
- **Chromium singleton lock on new installs**: archiso installer was leaving a singleton lock file, preventing Chromium from starting after fresh install.
- **Custom theme migration**: Users with a non-default theme selected before v3.3.0 ended up on the wrong theme after upgrading. Migration now preserves previously selected theme.

## Breaking Changes

*None*

## Configuration Changes

- **colors.toml**: `active_border_color` and `active_tab_background` fields removed; apps now derive them from `accent`.
- **VSCode theming**: Centralized into `omarchy-theme-set-vscode`.

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

## Fixes

* Fix nvidia detection of older professional workstation cards by @Nm1ss
* Fix use of accent color in mako and SwayOSD theme templates by @dhh
* Fix migration of old input scroll touchpad rules by @timohubois
* Fix complicated VSCode derivative theming by centralizing all in omarchy-theme-set-vscode by @dhh
* Fix needless active_border_color/active_tab_background definitions in colors.toml and replace with just accent by @dhh
* Fix Kitty cursor shape to be a block like Alacritty/Ghostty by @dhh
* Fix chromium wouldn't start after new installs because the archiso installer would own the singleton by @dhh
* Fix migration to new theme setup for people who had a custom theme selected by @dhh

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.3.0...v3.3.1
```

</details>
