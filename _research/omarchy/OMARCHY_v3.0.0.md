# Omarchy v3.0.0 — Release Research

**Date researched**: 2026-02-20
**Previous version**: v2.1.2
**Commits**: 130
**Source**: GitHub release notes

---

## Summary

v3.0.0 is a major release introducing an offline installation ISO (sub-2-minute install on fast hardware) and MacBook compatibility (pre-M models with T1/T2 chips and Broadcom wifi). The release also adds a large number of new features spanning application launching, hotkeys, theming, and terminal/editor configuration, alongside multiple bug fixes inherited from v2.1.x.

## Features

- **Offline installation ISO**: All-inclusive ISO requiring no internet connection for new installs. Styled install flow with centered logo and tailed logging. On failure, logs can be uploaded to `0x0.st`. Post-install prompts for wifi setup and system update.
- **Precompiled LazyVim for Neovim**: LazyVim included precompiled in the ISO to avoid network downloads during install.
- **T2 MacBook support**: Custom kernel and drivers for Apple T2 security chip Macs. Omarchy path: install scripts.
- **T1 MacBook keyboard support**: T1 keyboards work on the decryption (pre-boot) screen.
- **Broadcom BCM4360 wifi**: Compatibility added for 2013–2015 MacBooks with Broadcom BCM4360 chipsets.
- **Screen recording indicator**: Top bar indicator appears during screen recording; clicking it stops the recording.
- **Chromium Google account sync**: `Install > Service > Chromium Account` allows signing into a Google account for settings sync.
- **`omarchy-launch-or-focus`**: New binary/script that either launches or focuses an application; applied to several default key bindings.
- **Default `~/Work` directory**: Created on new installations.
- **AUR PKGBUILD preview**: `Alt+B` under `Install > AUR` shows PKGBUILD before installing a package.
- **Zoom meeting link support**: Zoom web app now handles `zoom://` meeting links.
- **System-wide terminal and editor default**: Configurable via `~/.config/uwsm/default`; accessible under `Setup > Defaults`.
- **Terminal picker**: `Install > Terminal` menu for choosing between Alacritty, Ghostty, and Kitty as fully-themed default.
- **Zig language server**: Added when installing from `Install > Development`.
- **Branch switching**: `Update > Branch` to switch between `master` and `dev` branches.
- **Walker service restored**: Application launcher and Omarchy Menu start times improved by re-adding the Walker service.

## Bug Fixes

- **Waybar flashing/disappearing**: Fixed waybar flashing or disappearing when update-available icon triggered an update.
- **GNOME dark mode on first install**: Fixed setting GNOME dark mode and themes during initial installation.
- **Hyprland 0.51 `workspace_swipe` warning**: Fixed config error from Hyprland 0.51 removing `workspace_swipe`.
- **freetype2/plymouth incompatibility**: Fixed incompatibility introduced by a freetype2 update breaking Plymouth.
- **fcitx5 Obsidian IME**: Fixed fcitx5 issue with non-Latin languages in Obsidian by launching it with `--wayland-ime`.
- **Intel screen recording acceleration**: Screen recording on Intel now uses accelerated graphics.
- **Screensaver workspace persistence**: Fixed screensaver persisting in workspace after switching workspaces.
- **Power profile with Python via mise**: Fixed power profile menu not opening when Python was installed via mise.

## Breaking Changes

- **Ghostty requires 1.2.0**: Ghostty theming/compatibility requires Ghostty 1.2.0, which is not yet released in the Arch repository at time of this release.

## Improvements

- **New hotkeys**:
  - `Alt+Shift+L` — copy current URL from Chromium or frameless webapps
  - `Ctrl+Super+S` — LocalSend share clipboard/file/folder
  - `Super+Backspace` — toggle window transparency on/off
  - `Super+Shift+B` — launch browser in private mode
  - `Super+Ctrl+Tab` — switch to previous workspace
  - `Alt+F11` — toggle full-width on a window
  - Calculator key — open default calculator

## Configuration Changes

- **`~/.config/uwsm/default`**: New file (or newly documented) for setting system-wide terminal and editor defaults. Managed under `Setup > Defaults`.
- **`~/.config/hypr/looknfeel.conf`**: Added to new installations as a reference file for customizing Hyprland aesthetics (border radius, gaps, animations, etc.).

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `walker` | Application launcher service (restored) for faster launch/menu times |
| Added | `zls` | Zig language server, installed via `Install > Development` |
| Added | Custom T2 kernel/drivers | Apple T2 security chip support on MacBooks |
| Added | `broadcom-wl` or equivalent | Broadcom BCM4360 wifi support (2013–2015 MacBooks) |

---

## Theme Changes

- **VS Code**: Theme switching support added.
- **eza**: Theme switching support added.
- **Kitty terminal**: Theme switching support added.
- **Brave browser**: Theme switching support added.
- **Lock screen**: Blurred theme background added.
- **`Style > Hyprland`**: New menu entry to tweak Hyprland look-and-feel from the Omarchy menu.

---

<details><summary>Original release notes</summary>

```
# What changed?

Omarchy 3.0 is a major upgrade for new installations and a wonderful level-up for existing users. The new ISO doesn't require internet at all, and you can install it in less than two minutes on the fastest systems.

You can now also install Omarchy on most pre-M MacBooks with support for keyboards, wifi, and the T1 and T2 security chips.

### New super-fast installation ISO

* Add everything needed for new all-inclusive ISO that doesn't need internet by @ryanrhughes
* Add new styled install flow with centered logo and tailed logging by @ryanrhughes
* Add option to upload install logs to 0x0.st if installation fails by @ryanrhughes
* Add invitation to setup wifi and update system on new ISO installations by @dhh
* Add precompiled lazyvim installation for nvim by @ryanrhughes

### MacBook Compatibility

* Add support for T2 macs with custom kernel and drivers by @ryanrhughes + @nunix
* Add compatibility with T1 MacBook keyboards so they work on the decryption screen by @joelgaff
* Add compatibility with Broadcom BCM4360 MacBooks (2013-2015) to get working wifi by @ryanrhughes

### New features

* Add screen recording indicator to the top bar when recording (clicking will stop) by @eifr + @dhh
* Add option to sign into Google account for settings sync in Chromium via Install > Service > Chromium Account by @hjanuschka
* Add `omarchy-launch-or-focus` to either launch or focus an app and apply it to several binding defaults by @v-oleg
* Add default `~/Work` directory by @ryanrhughes
* Add option to view PKGBUILD before installing AUR packages on alt+b under Install > AUR by @rajayonin
* Add support for zoom meeting links in the zoom web app by @ATeal
* Add support for changing terminal and editor system-wide in `~/.config/uwsm/default` (see Setup > Defaults) by @eifr + @dhh
* Add Install > Terminal for picking between Alacritty, Ghostty, Kitty as your fully-themed default terminal by @dhh
* Add Zig language server when installing from Install > Development by @DoKoB0512
* Add Update > Branch to switch between master and dev branch by @dhh
* Add Walker service back to get faster application launcher and Omarchy Menu start times

### New hotkeys

* Add `Alt + Shift + L` to copy current URL from Chromium and the frameless webapps by @jankeesvw
* Add `Ctrl + Super + S` for using LocalSend to share clipboard/file/folder quickly by @guilhermetk
* Add `Super + Backspace` to toggle transparency on/off for any window by @dhh
* Add `Super + Shift + B` to start browser in private mode by @kodnin
* Add `Super + Ctrl + Tab` to go to the former workspace by @zaborowskimichal
* Add `Alt + F11` to toggle full width on a window by @c4software
* Add calculator key binding for default calculator by @SamrudhNelli

### Aesthetics

* Add blurred theme background to the lock screen by @dhh
* Add theme switching for VS Code by @OmarSkalli
* Add theme switching for eza by @sgruendel
* Add theme switching for Kitty terminal by @vyrx-dev
* Add theme switching for Brave by @hjanuschka + @dhh
* Add `~/.config/hypr/looknfeel.conf` to new installations to suggest ways to change the Hyprland aesthetics by @dhh
* Add Style > Hyprland to tweak Hyprland look'n'feel from the menu by @med502

### Bug fixes

* Fix waybar flashing or disappearing after update-available icon kicked off an update by @dhh
* Fix setting gnome dark mode and themes on first install by @dhh
* Fix config error warning from Hyprland 0.51 yanking workspace_swipe by @dhh
* Fix incompatibility with freetype2 update and plymouth by @ryanrhughes
* Fix fcitx5 issue with other languages in Obsidian by running it with --wayland-ime by @ashutoshbw
* Fix screenrecording on Intel should now use accelerated graphics by @eifr
* Fix screensaver would persists in workspace after using other workspaces by @manuel1618
* Fix power profile not opening after folks had installed Python via mise by @dhh

Note: Ghostty compatibility requires Ghostty 1.2.0, which is still not released on the Arch repository.

**Full Changelog**: https://github.com/basecamp/omarchy/compare/v2.1.2...v3.0.0
```

</details>
