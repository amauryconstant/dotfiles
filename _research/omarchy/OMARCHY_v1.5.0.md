# Omarchy v1.5.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.4.1
**Commits**: 59
**Source**: GitHub release notes

---

## Summary

v1.5.0 is a broad release spanning security hardening, theme system expansion, and user experience polish. Notable additions include light theme support with Rose Pine as the first bundled light theme, Fido2/fingerprint improvements, and a default UFW firewall config with Docker protection. A large number of bug fixes address waybar stacking on wake, btop live theming, docker-buildx packaging, and wifi network service setup.

## Features

- **Light theme support**: New `theme/light.mode` file flag enables light mode theming. Omarchy path: `theme/light.mode`.
- **Rose Pine light theme**: Rose Pine added as the first bundled light mode theme.
- **Fido2 sudo authentication**: Fido2 hardware key setup added for sudo authentication. Omarchy path: `installers/fido2` (inferred).
- **UFW firewall with Docker protection**: Default firewall configuration using ufw added, including rules to protect Docker-exposed ports. Related to PR #201.
- **git stash/pop in omarchy-update**: `omarchy-update` now stashes user changes before updating and pops them after, reducing intervention on local modifications. Omarchy path: `bin/omarchy-update`.
- **Fingerprint removal**: `omarchy-setup-fingerprint --remove` flag added to remove fingerprint setup; also accessible via the TUI. Omarchy path: `bin/omarchy-setup-fingerprint`.
- **Update confirmation prompt**: `omarchy-update` now prompts for confirmation before applying system package updates. Omarchy path: `bin/omarchy-update`.
- **Theme picker in TUI**: The Omarchy TUI options menu now includes theme selection. Omarchy path: `bin/omarchy` or TUI entry point.

## Bug Fixes

- **Nautilus preview transparency**: Nautilus file previews incorrectly had transparency applied; fixed.
- **Installer shebang lines**: All installers now have a `#!/usr/bin/env bash` shebang line for consistent shell interpretation.
- **uwsm app launch preference**: Apps now prefer `uwsm app -- [app]` invocation when running under uwsm. Related to PR #182.
- **Theme backgrounds included locally**: All theme backgrounds are now bundled in the repo instead of downloaded at apply time, matching third-party theme layout expectations.
- **Waybar stacking on wake**: Waybar is now fully killed (rather than sent USRSIG2) on wake to fix the waybar stacking/duplication issue after suspend/resume.
- **Waybar config syntax highlighting**: Config file renamed from `config` to `config.jsonc` to enable proper JSON with comments syntax highlighting in editors. Related to PR #169. Omarchy path: `.config/waybar/config.jsonc`.
- **docker-buildx missing package**: `docker-buildx` package added to the package list. Related to PR #206.
- **btop live theme updates**: btop now picks up theme changes without requiring a restart. Related to PR #211.
- **Pinta install failure**: Pinta package installation made skippable during first setup to handle upstream packaging issues cleanly.
- **Wifi network services on ethernet install**: Fixed broken wifi network service installation when archinstall was performed over ethernet rather than wifi. Related to PR from @t0gun.

## Breaking Changes

*None*

## Improvements

- **omarchy-update resilience**: Combining git stash/pop and confirmation prompt makes unattended update runs safer and less likely to clobber local changes.
- **Waybar config discoverability**: Renaming to `.jsonc` improves editor tooling support without functional change.

## Configuration Changes

- **Waybar config filename**: Renamed from `.config/waybar/config` to `.config/waybar/config.jsonc`. Any external references to the old filename (editor settings, scripts) need updating.
- **Theme directory layout**: All theme backgrounds now stored locally in the repo rather than fetched remotely. Third-party themes are expected to follow the same layout.
- **UFW rules file**: New default firewall config file added for ufw, including Docker port protection rules.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `docker-buildx` | Docker build plugin, was missing from package list |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add support for light themes with the `theme/light.mode` file flag by @dhh
* Add Rose Pine as the first included light mode theme by @dhh
* Add Fido2 setup with sudo authentication by @icehunt
* Add default firewall config w/ Docker protection using ufw by @dhh in #201
* Add git stash/pop before `omarchy-update` to preserve more user changes without intervention by @dhh
* Add `omarchy-setup-fingerprint --remove` to remove fingerprint setup (also available through TUI) by @dhh
* Add confirmation before updating system packages on `omarchy-update` by @dhh
* Add theme picking to the Omarchy TUI options by @dhh
* Fix nautilus previews shouldn't have transparency by @dhh
* Fix that all installers should have a bash shebang line by @dhh
* Fix that starting apps with `uwsm app -- [app]` is preferred when running under uwsm by @abenz1267 in #182
* Fix that all theme backgrounds are included instead of downloaded to match 3rd party theme layouts by @dhh
* Fix killing waybar fully instead of using USRSIG2 to attempt fixing the stacking waybar on wake problem by @dhh
* Fix lack of syntax highlight with waybar config editing by renaming to `.config/waybar/config.jsonc` by @nullndr in #169
* Fix missing docker-buildx package by @Shaps in #206
* Fix btop theme should live update by @tahayvr in #211
* Fix that Pinta package isn't installing cleanly so make it skippable during first setup by @dhh
* Fix installing wifi network services if ethernet was used archinstall was broken by @t0gun

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.4.1...v1.5.0
```

</details>
