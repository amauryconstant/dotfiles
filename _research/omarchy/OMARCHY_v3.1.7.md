# Omarchy v3.1.7 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.1.6
**Commits**: 4
**Source**: GitHub release notes

---

## Summary

Compatibility patch addressing two breakages from an upstream Hyprland update: invalid config rules in `pip.conf` and a package rename (`hyprland-qtutils` → `hyprland-guiutils`).

## Features

*None*

## Bug Fixes

- **Hyprland config rules in pip.conf**: Corrected invalid rule/parameter syntax that became invalid after Hyprland upstream update. Contributed by @sk4rrjin and @mikailbayram.
- **hyprland-qtutils renamed to hyprland-guiutils**: Updated package reference following upstream rename. Contributed by @tibbe.

## Breaking Changes

*None*

## Configuration Changes

- **pip.conf Hyprland window rules**: One or more rule/parameter directives updated to conform to new Hyprland syntax.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Removed | `hyprland-qtutils` | Qt utilities for Hyprland (deprecated name) |
| Added | `hyprland-guiutils` | Qt utilities for Hyprland (renamed package) |

---

<details><summary>Original release notes</summary>

```
# Omarchy 3.1.7

## What's Changed

* Fix hyprland config in pip.conf to address newly invalid rule/parameter errors after hyprland update by @sk4rrjin / @mikailbayram
* Fix hyprland replacing hyprland-qtutils with hyprland-guiutils by @tibbe

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.1.6...v3.1.7
```

</details>
