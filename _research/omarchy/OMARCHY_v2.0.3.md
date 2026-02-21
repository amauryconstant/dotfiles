# Omarchy v2.0.3 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v2.0.2
**Commits**: 13
**Source**: GitHub release notes

---

## Summary

v2.0.3 is a pure bug-fix release targeting stability of the top bar and the upgrade workflow. Four issues are resolved: two related to the update-available icon in the top bar behaving incorrectly, one faulty migration guard for `bindings.conf`, and one unsafe `pacman -Sy` invocation that could cause partial system updates.

## Features

*None*

## Bug Fixes

- **Top bar disappears on upgrade**: The top bar would vanish when triggering an upgrade via the update-available icon. Fixed in the upgrade flow.
- **Phantom update-available icon**: Git network errors during the update check caused a false-positive update-available indicator in the top bar. The error path now suppresses the icon when a network failure is the cause.
- **Duplicate `--working-directory` migration**: The migration script that adds `--working-directory` to `bindings.conf` would incorrectly re-insert the flag if it was already present. Guard added to skip if already present.
- **Partial system update via `pacman -Sy`**: A bare `pacman -Sy` (sync without upgrade) was used, which is unsafe on Arch Linux as it can lead to partial upgrades and broken dependencies. Replaced with the correct invocation (`pacman -Syu` or equivalent safe form).

## Breaking Changes

*None*

## Improvements

*None*

## Configuration Changes

- **`bindings.conf` migration guard**: The migration that inserts `--working-directory` into `bindings.conf` now checks for prior existence of the flag before inserting, preventing duplicate entries.

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

* Fix top bar would disappear when running upgrade from the update-available icon by @dhh
* Fix phantom update-available icon in top bar showing up due to git network errors by @dhh
* Fix migration to add --working-directory to bindings.conf if its already there by @dhh
* Fix non-kosher use of pacman -Sy that would cause partial system updates by @dhh

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v2.0.2...v2.0.3
```

</details>
