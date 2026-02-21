# Omarchy v1.10.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.9.0
**Commits**: 38
**Source**: GitHub release notes

---

## Summary

v1.10.0 is a broad quality-of-life release spanning desktop ergonomics, peripheral support, and screensaver reliability. Major additions include hyprsunset-based night light toggling, automatic network printer discovery, Android file access over USB, and human-readable keybinding descriptions in the cheat sheet. A cluster of screensaver fixes addresses display coverage, font weight, and idle timeout, while several longstanding UX papercuts in battery warnings, the keybinding viewer, and the `refresh-compose` command are resolved.

---

## Features

- **Night light toggle**: Adds `SUPER + CTRL + N` keybinding to toggle display color temperature via `hyprsunset`. Omarchy path: keybindings config (likely `hypr/keybindings.conf` or equivalent).
- **Auto-discovery of network printers**: Network printers are now detected and configured automatically without manual setup steps.
- **Human-readable keybinding descriptions**: The dynamic keybindings cheat sheet (`SUPER + K`) now displays human-readable descriptions alongside each binding.
- **Android USB file access**: Files on Android phones connected via USB are now accessible through the file manager (MTP support added or wired in).
- **`OMARCHY_REPO` option in boot.sh**: A new environment variable `OMARCHY_REPO` allows pointing the boot script at a custom repository, enabling testing of forks or pre-release branches. Omarchy path: `boot.sh`.

---

## Bug Fixes

- **Migration state on new installs**: New installations now have migration state pre-set for the current release, preventing spurious migration runs.
- **Screensaver multi-display coverage**: Screensaver now starts on all connected displays, not just the primary.
- **Screensaver font size**: Screensaver uses a larger font, reducing CPU usage during idle.
- **Screensaver idle delay**: Screensaver now waits 2.5 minutes before starting automatically, up from 1 minute.
- **`refresh-compose` renamed**: The `refresh-compose` shell function is replaced by `omarchy-refresh-xcompose`, consistent with the naming convention used by all other omarchy commands.
- **Keybinding cheat sheet element cap**: The cheat sheet (`SUPER + K`) was truncating at 50 elements; the cap is removed or raised so all bindings are shown.
- **Battery warning duration**: Battery low notification now persists for 30 seconds instead of 2 seconds, making it harder to miss.
- **Waybar version icon**: A missing Waybar update is applied so the new-version notification icon appears correctly in the top bar.

---

## Breaking Changes

- **`refresh-compose` removed**: The `refresh-compose` function no longer exists; users or scripts calling it must use `omarchy-refresh-xcompose` instead.

---

## Improvements

- **Screensaver timing**: Idle threshold raised from 1 minute to 2.5 minutes, reducing unintended activation during short pauses.
- **Battery notification visibility**: 30-second sticky notification replaces the 2-second transient, improving awareness of low battery states.
- **Keybinding cheat sheet completeness**: All dynamically discovered keybindings are now visible, not just the first 50.

---

## Configuration Changes

- **`OMARCHY_REPO` variable in boot.sh**: `boot.sh` now reads an `OMARCHY_REPO` environment variable to override the default repository URL. Previously hardcoded.
- **Screensaver configuration**: Idle timeout and font size parameters changed in the screensaver config (likely `hyprlock` or `swayidle` config). Old timeout: 1 minute. New timeout: 2.5 minutes.
- **Waybar config updated**: Waybar configuration updated to include the new-version icon display.

---

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `hyprsunset` | Night light / display color temperature control |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add toggling nightlight display temperature via hyprsunset on `SUPER + CTRL + N` by @JaxonWright
* Add auto-discovery of network printers by @rockorager + @dhh
* Add human descriptions to dynamically discovered keybindings cheat sheet (`SUPER + K`) by @spdawson
* Add support for accessing Android files via file manager when phone is connected via USB by @erik-brueggemann
* Add `OMARCHY_REPO` options to boot.sh for testing custom repos by @ryanrhughes
* Fix new installations should already have the migration state set for that release by @dhh
* Fix screensaver should start on all displays by @precision
* Fix screensaver should use a bigger font to be less CPU intensive by @precision
* Fix screensaver should wait 2.5 minutes instead of 1 minute before starting automatically by @dhh
* Fix `refresh-compose` function should just be a `omarchy-refresh-xcompose` like everything else by @dhh
* Fix keybindings cheat sheet would only show the first 50 elements by @abenz1267 + @dhh
* Fix battery warning notification to stick around for 30 seconds instead of 2 to be harder to miss by @dhh
* Fix missing waybar update needed to get the new-version icon in the top bar by @dhh

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.9.0...v1.10.0
```

</details>
