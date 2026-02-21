# Omarchy v2.0.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v1.13.0
**Commits**: 402
**Source**: GitHub release notes

---

## Summary

v2.0.0 is a major release introducing a custom ISO installer, a self-hosted package repository (OPR) replacing AUR dependencies, and Limine bootloader integration with Btrfs snapshots for rollback support. The release also adds a Chromium micro-fork with live theme switching, a Starship shell prompt, and numerous TUI expansions, hotkeys, and bug fixes accumulated across 402 commits since v1.13.0.

## Features

- **Omarchy ISO Installer**: New online installer using the Omarchy Configurator front-end layered over `archinstall`. Omarchy path: installer/configurator tooling.
- **Omarchy Package Repository (OPR)**: Self-hosted package repository on Cloudflare replacing AUR for all default packages. All prior AUR-sourced default packages migrated to OPR.
- **Limine + Snapper Integration**: Btrfs snapshots taken automatically before `omarchy-update`; Limine bootloader exposes snapshots for rollback. Available to new installations only — existing installs retain their bootloader.
- **Omarchy Chromium Fork**: Micro-fork of Chromium enabling live theme switching without closing browser windows.
- **Starship Prompt**: Minimal Starship shell prompt added to terminal configuration.
- **Install > TUI**: New TUI wrapper for the installer, parallel to the existing Install > Web App interface.
- **Setup > DNS**: TUI to configure DNS system-wide — options: Cloudflare, DHCP, or custom server.
- **Omarchy Menu Icon**: New Omarchy icon added to the About screen and top-left menu button.
- **Tailscale TUI + Web Admin**: Tailscale installer extended with a TUI and Tailscale Web Admin webapp.
- **System > Screensaver**: New TUI entry to start the screensaver; Toggle > Screensaver controls auto-start behavior.
- **Style > Screensaver / Style > About**: Controls for customizing ASCII art used in the screensaver and `fastfetch`.
- **Install > Development > Elixir — Phoenix**: Phoenix framework added under Elixir development installer.
- **Install > Development > Docker DB — MongoDB**: MongoDB added to Docker DB installer options.
- **Disk Usage TUI**: New disk usage viewer using `dust`.
- **Image Conversion Helpers**: `img2jpg`, `img2jpg-small`, `img2png` shell functions added.
- **Discord QR Code**: QR code linking to the Discord support server displayed when the installer encounters errors.
- **New Wallpapers**: Additional wallpapers added to default themes.

## Bug Fixes

- **Zoom**: Replaced buggy native Zoom app with a web app.
- **Screen Recording on Intel**: Fixed to use `wf-recorder` instead of the previous recorder when running on Intel graphics.
- **Waybar Stacking**: Eliminated Waybar stacking by removing all `SIGUSR1`/`SIGUSR2` usage.
- **Wi-Fi / Bluetooth on Sleep**: Fixed Setup > Wi-Fi and Setup > Bluetooth turning off radios when opened after sleep or low-battery events.
- **Brave Browser**: Fixed Brave to run under Wayland and use Chrome-like opacity settings.
- **JetBrains Window Sizing**: Fixed window sizing for JetBrains IDEs.
- **Floating Window Size**: All system floating windows standardized to 800x600.
- **Walker Memory Leak**: Fixed by disabling the Walker service.
- **Docker Firewall Rules**: Fixed firewall to permit non-default Docker bridge networks.
- **Lock Screen Flash**: Fixed lock screen briefly flashing screen content on wake from sleep.
- **Orphan Package Cleanup**: `omarchy-update` now removes orphan packages.
- **Bare Mode Removed**: "Bare mode" removed as it violated the Omakase Computing Doctrine.

## Breaking Changes

- **Bare Mode Removed**: The "bare mode" feature has been removed entirely. No migration path provided; users relying on it must adapt their workflow.
- **Limine + Snapper**: Available only to new installations. Existing installations upgrading via `omarchy-update` retain their previous bootloader and do not gain snapshot-based rollback.

## Improvements

- **`omarchy-launch-browser` / `omarchy-launch-webapp`**: New launchers that respect the system default browser setting across the whole system.
- **Multiselect in Install/Remove**: Tab-key multiselect added to Install > Package/AUR and Remove > Package.
- **AUR Network Check**: Network availability verified before attempting AUR operations.
- **Sticky CWD in Terminal**: New terminal windows launched from an existing one inherit the current working directory.
- **Sudo Fail Threshold**: Raised from 3 to 10 failed attempts; `omarchy-reset-sudo` added to reset the counter after fat-fingered password entries.
- **Multi-select Web App Removal**: Remove > Web Apps now supports multi-select.

## Configuration Changes

- **DNS Configuration**: New Setup > DNS TUI writes DNS settings system-wide. Supports Cloudflare, DHCP, and custom server entries.
- **Screensaver Toggle**: Toggle > Screensaver now controls auto-start; System > Screensaver provides manual start. ASCII art for screensaver and `fastfetch` configurable via Style menu.
- **Brave / Chromium Flags**: Brave updated with Wayland and opacity flags. Omarchy Chromium fork requires separate binary from upstream Chromium.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `starship` | Minimal shell prompt |
| Added | `dust` | Disk usage TUI |
| Added | `limine` | Bootloader for snapshot rollback (new installs only) |
| Added | `snapper` | Btrfs snapshot management before updates |
| Added | `wf-recorder` | Screen recording on Intel graphics |
| Added | `tailscale` (expanded) | TUI + Web Admin webapp bundled with installer |
| Replaced | `zoom` (native) → Zoom web app | Avoid native app bugs |
| Replaced | AUR default packages → OPR | All default AUR packages migrated to Omarchy Package Repository |
| Added | `phoenix` (Elixir) | Phoenix framework under Elixir dev installer |
| Added | `mongodb` (Docker) | MongoDB under Docker DB installer |

---

<details><summary>Original release notes</summary>

```
# What changed?

## Major additions

* Add new Omarchy ISO online installer using the Omarchy Configurator front-end to archinstall
* Add new Omarchy Package Repository (OPR) as replacement for AUR hosted on Cloudflare for all default packages
* Add Limine/Snapper setup which snapshots before `omarchy-update` and allow for rollbacks in Limine bootloader
* Add Omarchy Chromium micro-fork that gives us live theme switching in the browser without having to close all windows
* Add minimal Starship prompt to terminal by @tobi + @dhh
* Add Install > TUI as a new TUI-wrapper like Install > Web App by @dhh + @ryanrhughes
* Add new Omarchy icon to About and top-left Omarchy Menu icon by @tahayvr
* Add Setup > DNS to easily use Cloudflare, DHCP, or Custom DNS server across the system by @jardahrazdera

## Minor additions

* Add `omarchy-launch-browser` and `omarchy-launch-webapp` so we can respect the default browser across the system
* Add multiselect using tab to Install > Package/AUR and Remove > Package by @jardahrazdera + @dhh
* Add network check to ensure AUR is available before trying any AUR operations by @dhh
* Add sticky cwd when launching new terminal windows off an existing one by @halilozercan + @dhh
* Add Tailscale TUI + Tailscale Web Admin webapp to Tailscale installer by @ryanrhughes + @dhh
* Add higher sudo fail threshold (10 instead of 3) and `omarchy-reset-sudo` for when you've fat fingered your sudo password by @manuel1618
* Add System > Screensaver to start screensaver and make Toggle > Screensaver control whether it should start automatically by @manuel1618
* Add Style > Screensaver and Style > About to allow changing the ASCII art used for screensaver and fastfetch by @dhh
* Add Phoenix under Install > Development > Elixir by @johanneserhardt
* Add MongoDB under Install > Development > Docker DB by @valbertoenoc
* Add removal of orphan packages on Omarchy Update by @dhh
* Add multi-select removal of web apps under Remove > Web Apps by @dhh
* Add `img2jpg`, `img2jpg-small`, `img2png` functions by @dhh
* Add Disk Usage TUI using dust by @tobi + @dhh
* Add QR code to join the Discord for help when the installer breaks
* Add new wallpapers to default themes

## New hotkeys

* Add `Ctrl + Super + E` to bring up Walker Emoji selector by @dhh
* Add `Super + Mute` for switching between audio outputs by @chriopter
* Add `Ctrl + Alt + Delete` for closing all windows by @chriopter
* Add `ALT + [Volume/Brightness Up/Down]` to apply 1% increments by @zaborowskimichal
* Add `Super + Tab` and `Super + Alt + Tab` to move forward and backward through workspaces by @iamobservable
* Add power button override to bring up Omarchy Power Menu instead of turning off computer by @v3rtx

## Fixes

* Fix Zoom's buggy native app by replacing it with a web app by @dhh
* Fix use wf-recorder for screen recordings when on Intel graphics by @alansikora
* Fix Waybar stacking by not using SIGUSR1 or SIGUSR2 anywhere by @ryanrhughes + @dhh
* Fix wifi + bluetooth getting turned off from sleep/low battery when opening Setup > Wi-Fi and Setup > Bluetooth by @dhh
* Fix Brave to use wayland and use Chrome-like opacity by @dhh
* Fix window sizing for JetBrains editors by @MikeVeerman, @sailoz, @vlofgren
* Fix all system windows that float should use the same 800x600 size by @dhh
* Fix Walker memory leak by removing service for now by @dhh
* Fix firewall rules to allow non-default docker bridge networks by @samuelpecher
* Fix all default AUR packages by switching them over to the OPR by @dhh
* Fix lock screen flashing content of screen on wake from sleep by @remshams
* Remove "bare mode" as it violated the Omakase Computing Doctrine by @dhh

## Updating to 2.0

Existing installations can upgrade by running Update > Omarchy from the Omarchy Menu (or `omarchy-menu` if they're still on a version predating that). Everything will be brought up to the latest EXCEPT the switch to limine bootloader and snapper snapshot restoring. That is currently only available to new installations.

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v1.13.0...v2.0.0
```

</details>
