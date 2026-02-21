# Omarchy v3.3.3 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.3.2
**Commits**: 2
**Source**: GitHub release notes

---

## Summary

Single-fix hotfix release. Patches `omarchy-update` to skip upgrading `gcc14` due to a known conflict.

## Features

*None*

## Bug Fixes

- **Ignore gcc14 in omarchy-update**: `omarchy-update` now explicitly excludes `gcc14` from upgrade cycle to avoid update errors/conflicts. Contributed by @ryanrhughes.

## Breaking Changes

*None*

## Configuration Changes

*None*

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Excluded from updates | `gcc14` | Excluded from `omarchy-update` upgrade cycle to avoid conflicts |

---

<details><summary>Original release notes</summary>

```
# What changed?

## Fixes
* Hotfix to ignore updating `gcc14` via `omarchy-update` by @ryanrhughes

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.3.2...v3.3.3
```

</details>
