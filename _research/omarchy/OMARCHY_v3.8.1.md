# Omarchy v3.8.1 — Release Research

**Date researched**: 2026-06-08
**Previous version**: v3.8.0
**Commits**: 4
**Source**: GitHub release notes

---

## Summary

v3.8.1 is a small hotfix release following v3.8.0. Its sole notable change pins the `omarchy-reinstall-git` helper to the `master` branch to prevent installations from accidentally tracking the `dev` branch. Update is applied via `Update > Omarchy` from the Omarchy menu (`Super + Alt + Space`).

## Breaking Changes

*None*

## Bug Fixes

- **Pin `omarchy-reinstall-git` to `master`**: Hotfix that pins the `omarchy-reinstall-git` reference to the `master` branch, preventing installations from accidentally switching to the `dev` branch during reinstall/update operations (contributed by @ryanrhughes).
