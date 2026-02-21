# Omarchy v1.6.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.5.2
**Commits**: 159
**Source**: GitHub release notes

---

## Summary

v1.6.0 is a large feature release (159 commits) adding screenshot/screenrecording tooling, replacing Wofi with Walker as the app launcher, introducing on-screen brightness/volume overlays, and adding several TUI-driven setup workflows for Dropbox and Docker databases. The release also ships a new Catppuccin Latte light theme and includes a significant number of bug fixes spanning Hyprland config, NeoVim theming, keyboard layout propagation, and upgrade behavior.

## Features

- **Screenshot annotation with Satty**: Post-capture image manipulation tool integrated into the screenshot workflow.
- **Screenrecording keybinds**: `ALT + PrintScreen` records a selected region; `ALT + CTRL + PrintScreen` records the whole display.
- **Walker app launcher**: Replaces Wofi for application launching and menus.
- **Catppuccin Latte theme**: Added as the second light theme option.
- **Third Tokyo Night wallpaper**: Additional background image added to the Tokyo Night theme set.
- **Wiremix audio TUI**: Terminal UI for audio settings, replacing the previous GUI audio tool.
- **On-screen brightness/volume overlays**: Visual overlays displayed when adjusting brightness or volume.
- **Discord link on install failure**: Install failure messages now include a link to the community Discord.
- **Hyprlock failed-attempts counter**: Shows a failed attempts counter and lockout message in the lock screen.
- **Dropbox setup command**: `omarchy-setup-dropbox` added as a dedicated setup command, also accessible via TUI. Previously only installed dependencies without completing setup.
- **Docker DBs via TUI**: TUI > Setup now includes options to run MySQL, PostgreSQL, and Redis in Docker containers.

## Bug Fixes

- **omarchy-refresh-* creates .bak files**: Refresh commands now create `.bak` backup files instead of prompting, easing the default upgrade flow.
- **Auto-stash on updates**: Fixed auto-stash behavior to not pop pre-existing stashes.
- **uwsm app restart**: Apps managed by uwsm are now correctly restarted under uwsm.
- **Migration execution reliability**: Fixed approach to running migrations to reduce the chance they are missed.
- **hypridle.conf cleanup**: Removed AI-hallucinated options from `hypridle.conf`.
- **Dancing workspace numbers**: Fixed a visual glitch causing workspace numbers to animate unexpectedly.
- **Zoom missing from default install**: Zoom was unintentionally absent from the default package set.
- **NeoVim matte black theme comment contrast**: Fixed low-contrast comment colors in NeoVim for the matte black theme.
- **Theme background handling**: Fixed incorrect application of theme backgrounds.
- **Keyboard layout carry-over**: Keyboard layout configured in archinstall now carries over to Omarchy correctly.
- **Hyprshot screenshot border**: Removed the 1px window border from being included in screenshots.
- **F11 fullscreen**: F11 now correctly fullscreens all applications.

## Breaking Changes

*None*

## Improvements

- **Walker over Wofi**: Walker replaces Wofi as the launcher, providing app launching and menu access.
- **Wiremix over GUI audio**: Audio settings moved to a TUI, removing the dependency on a GUI audio tool.

## Configuration Changes

- **hypridle.conf**: Removed invalid/hallucinated options from the idle config file. Existing installations using a custom `hypridle.conf` may have had those options silently ignored or may need to reconcile against the cleaned-up default.
- **Hyprland keybinds**: New keybinds added for screenrecording (`ALT + PrintScreen`, `ALT + CTRL + PrintScreen`). Existing keybind configs may need refresh.
- **omarchy-refresh-* behavior**: Now writes `.bak` files on conflict instead of prompting interactively. Affects the upgrade flow for users who previously relied on the interactive prompt.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `satty` | Screenshot annotation/image manipulation |
| Added | `walker` | App launcher and menu (replaces Wofi) |
| Removed | `wofi` | Replaced by Walker |
| Added | `wiremix` | Terminal UI for audio settings |
| Added | `zoom` | Video conferencing (restored to default install) |
| Added | `dropbox` (full setup) | Cloud storage with complete setup flow |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add screenshot image manipulation with satty by @dhh
* Add screenrecording on `ALT + PrintScreen` for region, `ALT + CTRL + PrintScreen` for whole display by @dhh
* Add Walker for app launcher and menus instead of wofi by @ryanrhughes
* Add Cappuccin Latte as the second light theme by @ryanyogan
* Add third Tokyo Night background image by @dhh
* Add audio settings TUI via wiremix to replace the GUI by @roel4d
* Add on-screen overlays for adjusting brightness and volume by @mtk3d, @roel4d
* Add link to community Discord if install fails by @dhh
* Add failed attempts counter and lockout message in hyprlock by @jhosdev
* Add Dropbox as `omarchy-setup-dropbox` or via TUI instead of just installing dependencies that still require setup by @dhh
* Add Docker DBs to TUI > Setup to run MySQL, PostgreSQL, and Redis in Docker DBs by @dhh
* Fix omarchy-refresh-* will now create .bak files instead of prompting to ease upgrades for default flow by @dhh
* Fix auto-stash behavior on updates to not pop existing stashing by @rmacklin
* Fix apps managed by uwsm should also be restarted under uwsm by @dhh
* Fix approach to running migrations to attempt that they won't be missed by @rmacklin
* Fix cleanup hypridle.conf to remove AI-hallucinated options by @dhh
* Fix dancing workspace numbers by @npenza
* Fix zoom was accidentally missing as a default install for a while by @saullbrandao
* Fix the low contrast colors for comments in NeoVim for matte black theme by @tahayvr
* Fix using theme backgrounds correctly by @dhh
* Fix that keyboard layout from archinstall should carry over to Omarchy by @saullrb
* Fix 1px border shouldn't be part of hyprshot screenshots by @al3rez
* Fix F11 should full screen all apps by @saullrb

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.5.2...v1.6.0
```

</details>
