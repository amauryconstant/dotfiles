# Omarchy v3.1.3 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v3.1.2
**Commits**: 2
**Source**: GitHub release notes

---

## Summary

v3.1.3 is a targeted hotfix addressing a false error state in the update workflow. When no orphaned packages exist on the system, the updater was incorrectly entering an error state; this release prevents that condition from triggering an error.

## Features

*None*

## Bug Fixes

- **Orphaned package check false error**: The update process displayed an error state when no orphaned packages were found. The fix prevents treating an empty orphan list as an error condition. Omarchy path: update/orphan-removal logic (exact file not confirmed from release notes).

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

## Fixes
- Hotfix: Prevent showing an error state on update when no orphaned packages exist by @ryanrhughes

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.1.2...v3.1.3
```

</details>
