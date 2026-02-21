# Omarchy v3.1.5 — Release Research

**Date researched**: 2026-02-21
**Previous version**: v3.1.4
**Commits**: 28
**Source**: GitHub release notes

---

## Summary

Bug-fix and stability release with one new feature. Primary themes: hardening the upgrade path (walker meta package, xdg-terminal-exec fallback), fixing phantom system notifications (recording indicator, battery alerts), and correcting package source routing (gemini-cli, optional packages moved from AUR to OPR/extra).

## Features

- **Floating overlay keybind**: `Super + O` pops a window out into a pinned, floating overlay.
- **Terminal via xdg-terminal-exec**: Ensures a working terminal is always launchable, preventing scenarios where no terminal is available.

## Bug Fixes

- **walker/elephant upgrade brick**: Introduced `omarchy-walker` meta package to prevent walker/elephant from bricking on upgrade.
- **Phantom recording indicator**: Fixed a phantom recording indicator that appeared incorrectly.
- **Phantom battery low alerts**: Fixed spurious battery low notifications.
- **omarchy-launch-editor with missing editor**: Fixed crash when a missing editor was specified.
- **gemini-cli package source**: Now installed from `arch/extra` instead of AUR.
- **VSCode theme on new installs**: Current theme now correctly applied to new VSCode installations.
- **nvim as default editor**: nvim set as default editor for most text mimetypes.
- **eza theme symlinks**: Removed stale symlinks left after eza themes were dropped.
- **Optional packages from OPR**: More optional packages now sourced from OPR instead of AUR.

## Breaking Changes

*None*

## Configuration Changes

- **xdg-terminal-exec integration**: Terminal launch now routes through `xdg-terminal-exec`.
- **nvim mimetype defaults**: nvim registered as default handler for most text mimetypes.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `omarchy-walker` | Meta package wrapping walker/elephant to prevent upgrade breakage |
| Changed source | `gemini-cli` | Moved from AUR to `arch/extra` |

---

<details><summary>Original release notes</summary>

```
# Omarchy 3.1.5

## What changed?
* Add `Super + O` to pop a window out into a pinned and floating overlay by @ryrobes
* Fix possibility for walker/elephant to brick on upgrading by introducing omarchy-walker meta package by @ryanrhughes
* Add Terminal execution via xdg-terminal-exec to ensure you can't end up without a working terminal by @ryanrhughes
* Fix phantom recording indicator by @davidszp
* Fix phantom battery low alerts by @joshuafouch
* Fix omarchy-launch-editor when a missing editor has been specified by @killeik
* Fix gemini-cli should now be installed from arch/extra not AUR by @maromalo
* Fix current theme should be applied to new VSCode installations by @brianblakely
* Fix nvim should be default editor for most text mimetypes out of the box by @ryanrhughes
* Fix that eza themes should no longer be symlinked since we dropped them by @miharekar
* Fix more optional packages to come from OPR instead of AUR by @ryanrhughes

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v3.1.4...v3.1.5
```

</details>
