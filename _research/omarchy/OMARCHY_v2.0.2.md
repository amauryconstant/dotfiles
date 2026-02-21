# Omarchy v2.0.2 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v2.0.1
**Commits**: 13
**Source**: GitHub release notes

---

## Summary

v2.0.2 is a hotfix release targeting a critical black-screen-of-death regression caused by a broken `abseil-cpp` package published on 2025-08-26. The release also fixes two minor UI issues in the About screen related to info display and font sizing.

## Features

*None*

## Bug Fixes

- **Black-screen-of-death on fresh installs**: A breaking `abseil-cpp` package release at 2025-08-26 22:15 UTC caused Omarchy ISO installs to fail with a black screen after installation. Fixed by @dhh. A patch script was provided for affected users (those who installed between 2025-08-26 22:15 UTC and 2025-08-27 12:50 UTC) accessible via `CTRL + ALT + F2` login recovery.
- **About info display**: Fixed incorrect or missing information display in the About screen. Fixed by @tahayvr.
- **About font size**: Fixed font size in the About screen when the system font size had been changed from its default. Fixed by @dhh.

## Breaking Changes

*None*

## Improvements

*None*

## Configuration Changes

*None*

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Fixed | `abseil-cpp` | Dependency that caused installation failures when a broken upstream release was published; Omarchy pinned or worked around the broken version |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Fix black-screen-of-death installs following abseil-cpp package release at 2025-08-26 that broke installs by @dhh
* Fix About info display by @tahayvr
* Fix font size for About when system font size has changed by @dhh

## Fixing black-screen-of-death installs

If you installed Omarchy via the ISO between 2025-08-26 22:15 UTC and 2025-08-27 12:50 UTC, you'll likely have hit the black-screen-of-death after installation. Fix: CTRL + ALT + F2, login, then run the patch script.

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v2.0.1...v2.0.2
```

</details>
