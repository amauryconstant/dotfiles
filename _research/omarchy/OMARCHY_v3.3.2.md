# Omarchy v3.3.2 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.3.1
**Commits**: 7
**Source**: GitHub release notes

---

## Summary

Focused maintenance release: fixes a silent NVIDIA driver installation failure that prevented `mkinitcpio` from building, and adds an update log for debuggability.

## Features

*None*

## Bug Fixes

- **NVIDIA mkinitcpio silent failure**: Fixed driver installation issue where errors during `mkinitcpio` rebuild were silently swallowed, causing initramfs build failure with no error output. Contributed by @ryanrhughes and @PhaedrusFlow.

## Breaking Changes

*None*

## Improvements

- **omarchy-update.log**: `omarchy-update` now writes a log file capturing output for post-hoc debugging and error inspection. Contributed by @ryanrhughes.

## Configuration Changes

*None*

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

## Fixes
* Fix Nvidia driver installation issue causing silent error failing mkinitcpio build by @ryanrhughes + @PhaedrusFlow

## Additions
* Add omarchy-update.log to the update process for debugging and error checking by @ryanrhughes

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.3.1...v3.3.2
```

</details>
