# Omarchy v3.2.2 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.2.1
**Commits**: 18
**Source**: GitHub release notes

---

## Summary

Polish and bugfix release with no breaking changes. Two new keybindings for notification and workspace management, plus six bug fixes spanning repository sync, emoji picker, cursor theming, screensaver compatibility, keyboard layout locking, and theme list ordering.

## Features

- **Restore last dismissed notification**: `Super + Shift + Alt + ,` restores the most recently dismissed notification.
- **Silent window move to numbered workspace**: `Super + Shift + Alt + [number]` moves active window to a numbered workspace without switching focus.

## Bug Fixes

- **Repository DB sync on channel switch**: Switching from `edge` to `stable` channel caused 404 errors due to stale repository DB state. Fixed.
- **Emoji picker column layout leak**: 3-column layout was leaking into other Walker menus. Now scoped to emoji picker only.
- **Ristretto theme cursor text visibility on Ghostty**: Fixed contrast/color values for cursor text.
- **Screensaver compatibility with TTE 0.14.1**: Fixed compatibility with updated TTE API.
- **Keyboard layout on lock screen**: Lock screen now always uses the first configured layout.
- **Theme removal list ordering**: "Remove > Theme" list now sorted alphabetically.

## Breaking Changes

*None*

## Configuration Changes

- **Walker emoji picker layout**: 3-column layout config scoped to emoji picker only.

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

## Additions
* Add `Super + Shift + Alt + ,` to restore the last dismissed notification by @vander00
* Add `Super + Shift + Alt + [number]` to silently move active window to numbered workspace by @Traap

## Fixes
* Fix repository DBs being out of sync with the current channel (switching from edge to stable would give 404s) by @dhh
* Fix emoji picker would use a 3-column layout that would leak into other Walker menus by @dhh
* Fix cursor text visibility with Ristretto theme on Ghostty by @jbnunn
* Fix screensaver compatibility with TTE 0.14.1 by @dhh
* Fix first keyboard layout should always be used when computer is locked by @Ziryt
* Fix Remove > Theme list should be ordered alphabetically by @jbnunn

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.2.1...v3.2.2
```

</details>
