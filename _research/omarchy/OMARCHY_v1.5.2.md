# Omarchy v1.5.2 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.5.1
**Commits**: 4
**Source**: GitHub release notes

---

## Summary

This is a small patch release focused on new-install reliability. A missing-directories bug was fixed that blocked fresh installations from starting up, and a Discord community link was added to the failure output to help users who hit installation errors.

## Features

*None*

## Bug Fixes

- **Missing directories on new install**: Directories now required at startup were absent, preventing new installations from completing. PR #233 by @alansikora adds the missing directory creation steps.
- **Discord link on install failure**: When installation fails, Omarchy now prints a link to the community Discord so users can seek help. Added by @dhh.

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
## What's Changed

* Add link to community Discord if installation fails by @dhh
* Fix missing directories now required for startup that was preventing new installs by @alansikora in https://github.com/basecamp/omarchy/pull/233

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.5.1...v1.5.2
```

</details>
