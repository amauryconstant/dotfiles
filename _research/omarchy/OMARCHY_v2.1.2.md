# Omarchy v2.1.2 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v2.1.1
**Commits**: 4
**Source**: GitHub release notes

---

## Summary

This is a patch release focused entirely on bug fixes. It addresses three regressions or compatibility issues: an unstyled decryption screen introduced in the last day of v2.1.1, a 6GHz Wi-Fi incompatibility, and missing Intel graphics acceleration — the latter two delivered as migrations for existing installations.

## Features

*None*

## Bug Fixes

- **Unstyled decryption screen**: New installations made in the final day of v2.1.1 displayed an unstyled (bare/unthemed) decryption screen. Fixed by @ryanrhughes.
- **6GHz Wi-Fi compatibility**: Existing installations lacked support for 6GHz Wi-Fi bands. Fixed via a migration script by @dhh.
- **Intel graphics acceleration**: Existing installations were missing Intel GPU hardware acceleration. Fixed via a migration script by @dhh.

## Breaking Changes

*None*

## Improvements

*None*

## Configuration Changes

*None*

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

* Fix unstyled decryption screen on new installations made in the last day by @ryanrhughes
* Fix 6Ghz Wi-Fi compatibility on existing installations with a migration by @dhh
* Fix Intel graphics acceleration on existing installations with a migration by @dhh

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v2.1.1...v2.1.2
```

</details>
