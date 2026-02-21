# Omarchy v1.5.1 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.5.0
**Commits**: 1
**Source**: GitHub release notes

---

## Summary

This is a single-commit patch release fixing a UX regression where the boot/loader screen would hang with a long black screen. The root cause was Docker network interface initialization causing timeouts that blocked the loader from completing promptly.

## Features

*None*

## Bug Fixes

- **Docker network timeout causing black screen**: Long black screens after the Omarchy loader were caused by Docker network operations timing out during startup. PR #223 by @ryanrhughes resolves the delay.

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

* Fix long black screen waits after loader due to Docker network timeouts by @ryanrhughes in #223

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.5.0...v1.5.1
```

</details>
