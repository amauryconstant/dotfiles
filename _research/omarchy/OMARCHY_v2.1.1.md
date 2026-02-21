# Omarchy v2.1.1 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v2.1.0
**Commits**: 67
**Source**: GitHub release notes

---

## Summary

v2.1.1 is a broad patch release with 26 changes spanning new features, bug fixes, and package additions. The majority of changes are bug fixes targeting Hyprland keybindings, package sourcing, Firefox rendering, network/DNS resolution, and config file correctness. New capabilities include screen recording with audio, 6GHz Wi-Fi support, LUKS/user password management, and expanded developer tooling (Clojure, PHP Debugger).

## Features

- **Screen recording with audio (region)**: Triggered via `ALT + SHIFT + PRINT`. Omarchy path: likely `hypr/keybindings.conf` or equivalent.
- **Screen recording with audio (full screen)**: Triggered via `CTRL + ALT + SHIFT + PRINT`.
- **6GHz Wi-Fi support**: Added `wireless-regdb` package to enable 6GHz band regulatory support.
- **Audio output switch feedback**: Visual feedback displayed when cycling audio outputs via `Super + Mute`.
- **LUKS & user password management**: New "Update > Password" menu entry for setting a new LUKS drive encryption password and the user account password.
- **Clojure install option**: Added "Install > Development > Clojure" to the install menu.
- **PHP Debugger**: Bundled as part of the existing PHP install path.
- **Matte Black theme ship-at-sea background**: New background image added to the Matte Black theme.
- **Numlock enabled by default**: Added numlock setting to new `hypr/input.conf` files.

## Bug Fixes

- **Ristretto cursor coloring**: Fixed cursor color inside selection in the Ristretto image viewer.
- **Firewall persistence**: Firewall service was not staying enabled after restart; now correctly persists.
- **Screenshots against frozen screen**: Screenshots now capture a frozen frame rather than live screen state.
- **`omarchy-install-docker-dbs` CLI parameters**: Script now accepts parameters when run from CLI directly.
- **Docker DB PostgreSQL version**: PostgreSQL Docker DB install corrected to use `pgsql17`.
- **Gemini AI install source**: "Install > AI > Gemini" now sources from AUR instead of an incorrect source.
- **Minecraft install source**: "Install > Gaming > Minecraft" now sources from AUR.
- **Package/AUR install backtrace**: Package/AUR installer now shows a backtrace when a package fails to install.
- **VPN DNS resolution in DHCP mode**: Fixed DNS resolution through VPN when using DHCP mode.
- **`new-terminal` cwd with spaces**: Fixed current working directory not being passed correctly when the path contains spaces.
- **Waybar clock locale**: Clock now uses locally correct day and month names instead of hardcoded English.
- **Firefox opacity**: Fixed opacity rendering problems that occurred in some situations.
- **YouTube opacity on subdomains**: Opacity setting now applies to all YouTube subdomains, not just the root domain.
- **Mako config duplication**: Removed duplicate entries in the mako notification daemon config.
- **Git config default location**: Git configs now default to `~/.config/gitconfig` rather than `~/.gitconfig`. Omarchy path: `git/gitconfig` or equivalent config template.
- **Intel GPU video acceleration**: Fixed hardware video acceleration on Intel GPUs.
- **Direct menu exit**: Accessing direct menus (system, theme) now exits directly as expected.
- **mDNS resolution for CUPS**: Fixed `.local` domain mDNS resolution for network printer setup via CUPS.

## Breaking Changes

*None*

## Improvements

- **Install menu backtrace on failure**: Package installation errors now surface a full backtrace, improving debuggability.
- **Audio output switching feedback**: Added visual confirmation when toggling audio outputs, reducing ambiguity.

## Configuration Changes

- **`hypr/input.conf`**: New files include `numlock_by_default = true` (or equivalent Hyprland input directive).
- **Git config path**: Default git config location changed to `~/.config/gitconfig`. Users with existing `~/.gitconfig` may need to migrate or reconcile.
- **Mako config**: Duplicate entries removed; existing customizations that rely on duplicated keys should be reviewed.
- **Waybar clock**: Clock format or locale settings updated to use system locale for day/month names.
- **Firefox opacity**: Firefox-specific opacity rules adjusted; the fix may affect custom CSS overrides.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `wireless-regdb` | Regulatory database enabling 6GHz Wi-Fi band support |
| Added | Clojure (AUR or community) | Clojure language install via "Install > Development > Clojure" |
| Added | PHP Debugger | Bundled with PHP install path |
| Changed | `pgsql17` (was prior version) | PostgreSQL Docker DB corrected to version 17 |
| Changed | Gemini AI package (AUR) | Sourcing corrected from non-AUR to AUR |
| Changed | Minecraft (AUR) | Sourcing corrected from non-AUR to AUR |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add screenrecordings with audio on `ALT + SHIFT + PRINT` for region and `CTRL + ALT + SHIFT + PRINT` for full screen by @dhh
* Add support for 6GHz Wi-Fi via wireless-regdb by @eclecticc
* Add visual feedback when switching between audio outputs on `Super + Mute` by @cluah
* Add Update > Password for setting a new LUKS drive encryption password and setting user password by @dhh
* Add Install > Development > Clojure by @naxels
* Add PHP Debugger as part of PHP install by @roberto-aguilar
* Add new ship-at-sea background for Matte Black theme by @dhh
* Add numlock by default in new `hypr/input.conf` files by @bftanase
* Fix ristretto cursor inside selection coloring by @ollymarkey
* Fix firewall wouldn't stay on after a restart by @martinmose
* Fix screenshots should happen against a frozen screen by @rsd
* Fix omarchy-install-docker-dbs should work from cli with parameters by @roberto-aguilar
* Fix Install > Docker DB > PostgresSQL should use pgsql17 by @aliismayilov
* Fix Install > AI > Gemini should source from AUR by @keyfer
* Fix Install > Gaming > Minecraft should source from AUR by @roberto-aguilar
* Fix Install > Package/AUR should show backtrace when package fails to install by @dhh
* Fix VPN DNS resolution in DHCP mode by @jardahrazdera
* Fix new-terminal cwd when your current directory has spaces by @dhh
* Fix waybar clock should use local correct names for the day/month by @arni1981
* Fix Firefox opacity problems in some situations by @typeshaper
* Fix YouTube opacity setting for all subdomains by @mgbaron
* Fix mako config duplication by @pipetogrep
* Fix git configs should be kept in `~/.config/gitconfig` by default by @esteban_ba
* Fix video acceleration on Intel GPUs by @eclecticc
* Fix accessing direct menus, like system and theme, should exit directly by @iccodes
* Fix mDNS resolution for .local domains for CUPS printer setup by @jardahrazdera

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v2.1.0...v2.1.1
```

</details>
