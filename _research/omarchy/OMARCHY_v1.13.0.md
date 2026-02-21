# Omarchy v1.13.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.12.1
**Commits**: 92
**Source**: GitHub release notes

---

## Summary

v1.13.0 is a large feature release centered on three themes: expanding the Install menu with curated setups for Gaming, Development, and additional editors/services; revamping how Omarchy locates its own binaries (PATH and `OMARCHY_PATH` via `~/.local/share/omarchy/bin`); and a batch of bug fixes addressing sleep/lock, SSH flakiness, boot delays, and several UI regressions. The PATH change requires users to relaunch Hyprland and re-run Omarchy > Update after upgrading.

---

## Features

- **Install > Gaming**: New menu section for installing Steam, RetroArch, and Minecraft.
- **Install > Development**: New menu section covering many major development environments.
- **Install > Editor options**: Sublime Text and Helix added as editor choices in the Install menu.
- **Install > Service**: New menu section with setup options for Dropbox and Tailscale.
- **Discord default web app**: Discord added as a default web application entry.
- **`~/.local/share/omarchy/bin` in PATH**: System-wide PATH and new `OMARCHY_PATH` variable now include this directory; requires Hyprland relaunch post-update.
- **Fresh-install guard**: Installation now checks for a fresh vanilla Arch on x86_64; an override option is provided.
- **Cloudflare DNS default**: Cloudflare DNS set as default (Google kept as backup).
- **Osaka Jade backgrounds**: Two new background images added for the Osaka Jade theme.
- **Vim navigation in Package browser**: Vim-style hotkeys and description-hiding added to Install/Remove > Package.
- **`omarchy-version` command**: New command reporting the current Omarchy release version from the git tag.
- **1Password screenshare blackout**: `noscreenshare` windowrule added for 1Password so it is blacked out during screensharing.

---

## Bug Fixes

- **Sleep/lock path issue**: Sleep would not lock screen on some installations due to an incorrect path; corrected.
- **SSH flakiness**: Common intermittent SSH failures resolved by default.
- **Chromium save dialogue size**: Chromium save dialogue no longer grows too large.
- **About font size**: About screen font size now respects system font changes.
- **Walker config defaults**: Walker config now only overrides values that differ from upstream defaults, avoiding clobbering user config.
- **Hyprland include order**: Default `~/.config/hypr/hyprland.conf` include order fixed so user edits take precedence over Omarchy defaults.
- **Omarchy logo wrapping**: Logo no longer wraps on some terminal interactions.
- **wiremix launcher icon**: Missing icon for Audio Settings (wiremix) in the application launcher restored.
- **Boot delay on network wait**: Systemd was waiting for a network interface to come online unnecessarily, slowing boot; fixed.
- **mise paths not systemwide**: mise paths now added to uwsm so they are available system-wide.
- **Waybar update-available icon persistence**: Icon indicating an available update no longer lingers after the update completes.

---

## Breaking Changes

- **PATH / `OMARCHY_PATH` revamp**: `~/.local/share/omarchy/bin` is now the canonical location for Omarchy binaries and is added to both PATH and a new `OMARCHY_PATH` variable. Users upgrading must relaunch Hyprland when prompted, then run Omarchy > Update a second time.

---

## Improvements

- **Cloudflare as default DNS**: More reliable and privacy-oriented DNS default over previous configuration; Google retained as backup.
- **Installation guard**: Prevents accidental installation on non-fresh or non-x86_64 systems, reducing support surface.
- **Walker config minimalism**: Reduces diff between Omarchy Walker config and upstream defaults, making future Walker upgrades less disruptive.
- **Hyprland include ordering**: User `hyprland.conf` edits now reliably take precedence over Omarchy-managed includes.

---

## Configuration Changes

- **`~/.config/hypr/hyprland.conf` include order**: Order of `source` / include directives changed so user config files are sourced after Omarchy defaults, giving user edits higher precedence.
- **Walker config**: Trimmed to only override values that differ from Walker upstream defaults; previously overrode all values.
- **uwsm environment**: mise binary paths added to uwsm environment so they propagate system-wide (not just in interactive shells).
- **DNS configuration**: `/etc/resolv.conf` or equivalent now defaults to Cloudflare (`1.1.1.1`, `1.0.0.1`) with Google (`8.8.8.8`) as fallback.

---

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added (optional/menu) | `steam` | Gaming — Steam game client |
| Added (optional/menu) | `retroarch` | Gaming — multi-system emulator frontend |
| Added (optional/menu) | `minecraft-launcher` | Gaming — Minecraft |
| Added (optional/menu) | `sublime-text` | Editor alternative |
| Added (optional/menu) | `helix` | Editor alternative (modal, terminal) |
| Added (optional/menu) | `dropbox` | Service — file sync |
| Added (optional/menu) | `tailscale` | Service — VPN mesh networking |
| Added (default) | Discord web app | Default web application entry |

---

<details><summary>Original release notes</summary>

```
# What changed?

* Add Install > Gaming to ease installation of Steam, RetroArch, and Minecraft by @dhh
* Add Install > Development to ease installation of many major development environments by @dhh
* Add Install > Editor options for Sublime Text + Helix by @dhh
* Add Install > Service with options for Dropbox + Tailscale setup by @dhh
* Add Discord as a default web app by @dhh
* Add system-wide `~/.local/share/omarchy/bin` to PATH and OMARCHY_PATH by @ryanrhughes + @dhh
* Add guard against installing Omarchy on anything but a fresh vanilla Arch on x86_64 (but option to override) by @dhh + @daltonbr
* Add Cloudflare (with Google as backup) as the default DNS setup by @dhh
* Add two new backgrounds for Osaka Jade by @Justikun + @dhh
* Add vim navigation hotkeys + description hiding to Install/Remove > Package by @maxguzenski
* Add omarchy-version command to get the current Omarchy release version (from git tag) by @sailoz
* Add noscreenshare windowrule for 1password so it'll be blacked out during screenshare by @alexperreault
* Fix sleep wouldn't lock screen on some installations due to path issue by @dhh
* Fix common flakiness with SSH by default by @dhh
* Fix Chromium save dialogue getting too big by @dhh
* Fix About font size if system was changed by @sailoz
* Fix Walker config to only override values where we differ from defaults by @ryanrhughes
* Fix order of includes in default `~/.config/hypr/hyprland.conf` so user edits take precedence by @dhh
* Fix that Omarchy logo would wrap on some terminal interactions by @dhh
* Fix missing icon for Audio Settings (wiremix) in application launcher by @dhh
* Fix boot taking forever because systemd was waiting for a network interface to come online by @ryanrhughes
* Fix mise paths not being available systemwide by adding them to uwsm by @ryanrhughes
* Fix update-available icon would hang around after update in Waybar by @LeonardoTrapani

## Updating

This release includes a revamp of the PATH and how Omarchy finds its bins. It's very important that when you are asked to relaunch Hyprland, that you do so, and then run Omarchy > Update again afterwards.

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.12.1...v1.13.0
```

</details>
