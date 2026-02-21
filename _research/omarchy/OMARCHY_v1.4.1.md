# Omarchy v1.4.1 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.4.0
**Commits**: 16
**Source**: GitHub release notes

---

## Summary

v1.4.1 is a patch release focused on wofi customization and bug fixes. The headline change introduces fully user-editable wofi styles under `.config/wofi`, making the launcher appearance directly extensible without touching Omarchy internals. The remaining changes fix a matte black theme detection regression, wofi menu toggle behavior, a TUI manual-open bug, and duplicated Waybar config entries from a botched merge.

## Features

- **User-editable wofi styles**: Wofi CSS styles are now placed in `.config/wofi`, making them directly editable by the user without modifying Omarchy source files. Omarchy path: `.config/wofi/` (style.css and related files).

## Bug Fixes

- **Matte black theme not picked up**: The matte black theme variant was not being detected for some users; fixed so theme selection applies correctly on those systems.
- **Wofi menus stacking instead of toggling**: All wofi menu bindings (app launcher, power menu, etc.) now toggle the menu closed when the binding is pressed again, rather than opening additional instances.
- **Manual open from Omarchy TUI**: Opening the manual from the Omarchy TUI when launched from a command line context was broken; the open action now functions correctly in that context.
- **Duplicated Waybar config entries**: A botched merge had introduced repeated configuration blocks in the Waybar config file; duplicates removed. Contributed by @mrtnin.

## Breaking Changes

*None*

## Improvements

*None*

## Configuration Changes

- **Wofi styles moved to user-space**: Style files for wofi are now located under `.config/wofi/` rather than being managed exclusively inside Omarchy's internal theme files, allowing direct user edits to persist.
- **Waybar config deduplicated**: Duplicate config blocks removed from the Waybar configuration file introduced by a prior merge error.

## Package Changes

*None*

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add fully user-editable wofi styles in .config/wofi by @dhh
* Fix matte black theme wasn't getting picked up for some users by @dhh
* Fix all wofi menus should toggle on their binding instead of stack by @dhh
* Fix opening manual from Omarchy TUI on command line by @dhh
* Fix repeated configs in waybar config from a botched merge by @mrtnin

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.4.0...v1.4.1
```

</details>
