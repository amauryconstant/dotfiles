# Omarchy v2.0.5 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v2.0.4
**Commits**: 14
**Source**: GitHub release notes

---

## Summary

v2.0.5 is a pure bugfix release addressing seven issues across package management, UI display, dependency handling, and system integration. Fixes span package repository ordering, Font Awesome migration to v7.0, Waybar restart behavior, and btrfs/snapper compatibility for custom setups.

## Features

*None*

## Bug Fixes

- **Package repository order**: Arch default repositories now take precedence over the Omarchy Package Repository, preventing conflicts where Omarchy-sourced packages incorrectly overrode official Arch packages.
- **Branch name in About screen**: The Omarchy branch name was not being exposed correctly in the About screen; this is now resolved.
- **Node.js dependency for Laravel**: `node.js` was missing from the full Laravel installation dependency set and has been added.
- **Font Awesome package rename**: New installs now use `woff2-font-awesome` instead of `ttf-font-awesome`, reflecting the Font Awesome 7.0 package rename in the Arch repositories.
- **walker-bin missing**: A case where `walker-bin` disappeared from the system was identified and fixed.
- **Waybar restart on unlock**: Waybar was incorrectly restarting after screen unlock; this is suppressed now that the underlying Waybar stacking issue has been resolved.
- **Snapper with custom btrfs setups**: `snapper` usage was broken for users with custom btrfs subvolume layouts; the integration now handles non-standard configurations.

## Breaking Changes

*None*

## Improvements

*None*

## Configuration Changes

- **Waybar unlock behavior**: The post-unlock Waybar restart trigger has been removed or disabled, affecting the Waybar service/restart configuration in Omarchy's Hyprland lock integration.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Removed | `ttf-font-awesome` | Replaced by renamed Font Awesome 7.0 package |
| Added | `woff2-font-awesome` | Font Awesome 7.0 (new package name for woff2 format) |
| Added | `nodejs` | Required for full Laravel installation support |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Fix package repository order so Arch defaults come before Omarchy Package Repository by @dhh
* Fix Omarchy branch name should be exposed in the About screen by @dhh
* Fix node.js is needed for a full Laravel installation by @roberto-aguilar
* Fix new installs should use woff2-font-awesome instead of ttf-font-awesome per Font Awesome 7.0 by @dhh
* Fix strange case where walker-bin went missing by @dhh
* Fix Waybar shouldn't restart after unlock now that we've fixed the stacking problem by @dhh
* Fix snapper usage for custom btrfs setups by @michielryvers + @ryanrhughes

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v2.0.4...v2.0.5
```

</details>
