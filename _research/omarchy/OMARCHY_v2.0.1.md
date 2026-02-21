# Omarchy v2.0.1 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v2.0.0
**Commits**: 21
**Source**: GitHub release notes

---

## Summary

v2.0.1 is a pure bug-fix release with no new features. It addresses ten distinct issues introduced or exposed in v2.0.0, spanning browser transparency rules, launcher cleanup, UI consistency in selection menus, font filtering, and keybinding correctness.

## Features

*None*

## Bug Fixes

- **AMI BIOS bricking bug**: Fixed a bug that could brick systems with AMI BIOS. Contributor: @ryanrhughes.
- **omarchy-launch-browser / omarchy-launch-webapp on Nix home manager**: Both scripts failed for users running Nix home manager; fixed to resolve correctly in that environment. Contributor: @manofcolombia.
- **Update > Omarchy icon**: The Update menu entry for Omarchy was displaying the Arch Linux icon instead of the Omarchy-specific icon. Contributor: @tahayvr.
- **Remove > Web App and Remove > TUI multi-word entries**: Removing entries whose names contain spaces was broken; fixed for both Web App and TUI removal flows. Contributor: @jopesh.
- **Remove > Web App and Remove > TUI selection indicator**: Selection in these menus was incorrectly using a checkmark glyph; changed to an `x` to reflect removal intent. Contributor: @hipsterusername.
- **Emoji picker keybindings description**: The emoji picker entry in the keybindings overview had an incorrect description. Contributor: @AdiY00.
- **Browser transparency rules**: Chromium-based and Firefox-based browsers now share consistent transparency rules; previously only a subset of browsers was covered. Contributors: @joshleblanc, @dhh.
- **omarchy-icon font in Style > Font menu**: The omarchy-icon font was appearing as a selectable option in the font picker; it is now excluded. Contributor: @WToa.
- **Workspace tabbing keybinding**: Workspace tab switching was using the wrong binding directive; corrected to use `bindd`. Contributor: @arcbjorn.
- **Stale launcher entries (About, Activity, Audio Settings)**: Older installations retained About, Activity, and Audio Settings entries in the launcher after those were moved to the Omarchy Menu in v2.0.0; these are now cleaned up. Contributor: @dhh.

## Breaking Changes

*None*

## Improvements

*None*

## Configuration Changes

- **Browser transparency rules**: Transparency rule configuration was extended to cover all Chromium-based and Firefox-based browsers uniformly rather than only select browsers.
- **Workspace tabbing**: Keybinding for workspace tab switching changed from a standard `bind` directive to `bindd` in the Hyprland config.
- **Launcher entries cleanup**: About, Activity, and Audio Settings `.desktop` entries removed from the launcher for existing installations (previously only new installs lacked them).

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

* Fix AMI bios bricking bug by @ryanrhughes
* Fix omarchy-launch-browser and omarchy-launch-webapp for folks using Nix home manager by @manofcolombia
* Fix Update > Omarchy should use our new icon instead of Arch by @tahayvr
* Fix Remove > Web App and Remove > TUI for removing multi-word entries by @jopesh
* Fix Remove > Web App and Remove > TUI should use an x instead of checkmark for selection by @hipsterusername
* Fix emoji picker description in keybindings overview by @AdiY00
* Fix that all chromium-based and firefox-based browser should have the same transparency rules by @joshleblanc + @dhh
* Fix that omarchy-icon font shouldn't show up as an option in the Style > Font menu by @WToa
* Fix workspace tabbing should use `bindd` by @arcbjorn
* Fix old installations still had About, Activity, Audio Settings apps in launcher that we've moved to Omarchy Menu by @dhh

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v2.0.0...v2.0.1
```

</details>
