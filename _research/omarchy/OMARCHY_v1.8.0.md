# Omarchy v1.8.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.7.0
**Commits**: 1
**Source**: GitHub release notes

---

## Summary

v1.8.0 is a broad feature release centered on font management, migration resilience, and application launcher improvements. It introduces a dedicated font menu and TUI integration for switching terminal fonts, replaces manual font downloads with packaged Nerd Font variants, and hardens the migration system with per-migration tracking. Several UX fixes address the application launcher and decryption screen.

## Features

- **Font menu (`omarchy-font-menu`)**: New command and Omarchy TUI entry (`Themes > Font`) for interactively changing the terminal font. Omarchy path: not confirmed from notes alone.
- **Per-migration tracking**: Migration system now records which individual migrations have run, preventing re-application of already-executed migrations and allowing safe partial upgrades.
- **`Themes > Update` in Omarchy TUI**: New TUI menu action to pull down and refresh extra/community themes without running a full `omarchy-update`.
- **File finder in application launcher**: Prefixing the launcher query with `.` activates a file finder mode within the application launcher (Walker).
- **`$OMARCHY_PATH` environment variable**: New default environment variable exposing the Omarchy installation path for use in user scripts and configs.

## Bug Fixes

- **Application launcher theme pickup**: Fixed a bug where the application launcher (Walker) would not apply a freshly switched theme until restarted.
- **Decryption screen logo**: Corrected the Plymouth decryption screen logo to match the updated Omarchy version branding.

## Breaking Changes

*None*

## Improvements

- **`.bak.$timestamp` strategy in `omarchy-refresh-*` scripts**: Refresh scripts now back up existing configs with a timestamped `.bak` suffix before overwriting, eliminating the risk of losing local modifications during a refresh.

## Configuration Changes

- **Font packages replace manual downloads**: `ttf-cascadia-mono-nerd` and `ttf-ia-writer` are now installed as packaged fonts rather than fetched manually. Any prior manual font file placements for these fonts are superseded by the package-managed versions.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `ttf-cascadia-mono-nerd` | Cascadia Mono Nerd Font, replaces manual download |
| Added | `ttf-ia-writer` | iA Writer fonts, replaces manual download |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add font menu for easily changing terminal fonts via `omarchy-font-menu` and in Omarchy TUI by @dhh
* Add more resilient migration strategy that tracks which migrations you've run by @ardavis
* Add `Themes > Update` to Omarchy TUI to refresh extra themes by @ryanrhughes
* Add .bak.$timestamp strategy to the omarchy-refresh-* scripts to prevent ever losing configs by
* Add file finder to application launcher by using "." as a leader key by @Mohamedsayhii
* Add font packages ttf-cascadia-mono-nerd and ttf-ia-writer instead of manually downloading fonts by @dhh
* Add $OMARCHY_PATH as default env by @dhh
* Fix bug where application launcher wouldn't pickup fresh theme by @dhh
* Fix decryption screen logo to match the updated version by @tahayvr

Update by running `omarchy-update` twice.

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.7.0...v1.8.0
```

</details>
