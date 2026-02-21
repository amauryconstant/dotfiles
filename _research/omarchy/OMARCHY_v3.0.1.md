# Omarchy v3.0.1 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v3.0.0
**Commits**: 2
**Source**: Commit log fallback

---

## Summary

This is a small patch release addressing two bugs introduced in or prior to v3.0.0. It corrects a file permission issue and fixes a color/theme rendering problem in the Osaka Jade theme variant for the Ghostty terminal emulator.

## Features

*None*

## Bug Fixes

- **Permission fix**: Corrected file permissions on one or more files in the omarchy setup. Likely affected executable scripts or config files with incorrect mode bits.
- **Osaka Jade theme for Ghostty**: Fixed the Osaka Jade color theme as applied to Ghostty terminal. The prior state produced incorrect colors; this commit restores expected rendering.

## Breaking Changes

*None*

## Improvements

*None*

## Configuration Changes

- **Ghostty theme file (osaka-jade)**: The Osaka Jade theme configuration for Ghostty was corrected. File likely resides under omarchy's themes directory (e.g., `themes/osaka-jade/ghostty` or equivalent). Exact field corrections unknown without diff access.

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
## Commit Summary

- Fix permissions
- Fix osaka jade theme for ghostty
```

</details>
