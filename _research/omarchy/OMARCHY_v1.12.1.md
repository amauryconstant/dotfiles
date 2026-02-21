# Omarchy v1.12.1 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.12.0
**Commits**: 34
**Source**: GitHub release notes

---

## Summary

v1.12.1 is a feature and polish release focused on the Omarchy menu system. It adds three new menu sections (Install > AI, Install > Style, Update > Process), improves visual feedback with selection highlighting, and resolves six bugs spanning icon rendering, menu UX, path issues, and a tray margin regression.

## Features

- **Install > AI menu**: New menu section under Install offering install suggestions for Claude, Gemini, LM Studio, Crush, and Opencode. Omarchy path: menu/install (inferred).
- **Install > Style menu**: New menu section grouping Theme, Font, and Background options under Install, mirroring the existing Setup > Style layout.
- **Update > Process menu**: Exposes `omarchy-restart-*` scripts via the Omarchy menu under an Update > Process section.
- **Selection highlighting**: Current selection is highlighted in Style > Font, Style > Theme, and Setup > Power Profile menus.

## Bug Fixes

- **Missing windowrule comma**: Missing comma in the `windowrule` entry for the About window was corrected.
- **Top bar tray margin**: Incorrect margin for the top bar tray area was fixed.
- **upgrade-icon path**: `upgrade-icon` failed to launch `omarchy-upgrade` due to a missing executable path; path is now resolved correctly.
- **Menu exit behavior**: Update, Install, and Remove menu options no longer exit immediately — they now wait for a keypress before returning to the menu.
- **omarchy-update terminal output**: Running `omarchy-update` directly in a terminal no longer wraps output in presentation chrome intended for the menu context.
- **About page OS icon**: The About page was displaying a Windows icon for the OS field; corrected to a Linux icon.

## Breaking Changes

*None*

## Improvements

- **Menu UX consistency**: Install > Style mirrors the Setup > Style grouping, making the two entry points structurally consistent.
- **Visual feedback**: Selection highlighting across Font, Theme, and Power Profile pickers makes the current active choice visible at a glance.

## Configuration Changes

*None*

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add Install > AI with suggestions for claude, gemini, LM studio, crush, and opencode by @dhh
* Add Install > Style to group Theme/Font/Background like we do in Setup > Style by @dhh
* Add Update > Process to make the omarchy-restart-* scripts available via the Omarchy menu by @dhh
* Add highlight of current selection in Style > Font, Style > Theme, Setup > Power Profile by @dhh
* Fix missing comma in windowrule for about by @dhh
* Fix margin for the top bar tray by @dhh
* Fix upgrade-icon wouldn't launch omarchy-upgrade due to missing path by @dhh
* Fix that Update/Install/Remove options from the menu should not exit until user has pressed a key by @dhh
* Fix that omarchy-update run in the terminal should not have presentation output around it by @dhh
* Fix About page used a freaking windows icon for OS by @dhh

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.12.0...v1.12.1
```

</details>
