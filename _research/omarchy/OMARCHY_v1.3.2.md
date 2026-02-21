# Omarchy v1.3.2 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.3.1
**Commits**: 5
**Source**: GitHub release notes

---

## Summary

v1.3.2 is a two-fix patch release addressing regressions from the binding file subdivision introduced in a prior version. The `omarchy-menu-keybindings` script now correctly displays keybindings loaded from the split binding files, and the Nautilus image preview window (`Space` in file manager) is now properly floated and centered.

## Features

*None*

## Bug Fixes

- **Keybindings menu with subdivided files**: `omarchy-menu-keybindings` (`bin/omarchy-menu-keybindings`) reads live bindings via `hyprctl -j binds`, which queries all currently loaded Hyprland bindings regardless of source file. The fix ensures the menu correctly reflects bindings defined across the split files: `default/hypr/bindings/media.conf`, `clipboard.conf`, `tiling-v2.conf`, and `utilities.conf`.
- **Nautilus image preview float/center**: Pressing `Space` in Nautilus opens `org.gnome.NautilusPreviewer`. The window rule in `default/hypr/apps/system.conf` now tags `org.gnome.NautilusPreviewer` with `+floating-window`, causing it to float and center via the existing `floating-window` tag rules (`float on`, `center on`, `size 875 600`).

## Breaking Changes

*None*

## Improvements

*None*

## Configuration Changes

- **`default/hypr/apps/system.conf`**: `org.gnome.NautilusPreviewer` added to the `+floating-window` tag rule match list, so the Nautilus spacebar preview window inherits float, center, and size constraints.
- **`default/hypr/apps/system.conf`**: `org.gnome.NautilusPreviewer` also added to the no-transparency opacity override list (`tag -default-opacity` + `opacity 1 1`), consistent with other media viewer windows.

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

* Fix show keybindings for the new subdivided files by @dhh
* Fix nautilus image previews (`Space` when in the file manager) should float and center the preview by @dhh

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.3.1...v1.3.2
```

</details>
