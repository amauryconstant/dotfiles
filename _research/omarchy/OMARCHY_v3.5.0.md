# Omarchy v3.5.0 — Release Research

**Date researched**: 2026-05-04
**Previous version**: v3.4.2
**Commits**: 141
**Source**: GitHub release notes

---

## Summary

The "Panther Lake Edition" adds full hardware compatibility for Intel Panther Lake machines via a patched kernel and IPU7 camera driver, along with broader Intel performance management tooling. The release also ships two new themes (Lumon Industries and Retro 82), several new productivity tools (ONCE installer, LocalSend Nautilus integration, npx lazy-install stubs), and a significant reorganization of the hardware config install scripts into per-vendor subdirectories.

## Breaking Changes

*None*

## Features

- **Intel Panther Lake support**: Installs `linux-ptl` and `linux-ptl-headers` (patched 6.19.10 kernel) on Panther Lake hardware, replaces stock `linux`/`linux-headers`, and sets Limine boot order to PTL kernel. Omarchy path: `install/config/hardware/intel/ptl-kernel.sh`
- **IPU7 camera driver**: Installs IPU7 camera driver for webcam support on Panther Lake machines. Omarchy path: `install/config/hardware/intel/ipu7-camera.sh`
- **Intel thermald**: Installs and enables `thermald` on Intel Sandy Bridge (model >= 42) and newer laptop CPUs for improved thermal throttling. Omarchy path: `install/config/hardware/intel/thermald.sh`
- **Intel LPMD**: Installs `intel-lpmd` for optimized P/E core selection on Alder Lake (151/154), Raptor Lake (183/186/191), Meteor Lake (170/172), Lunar Lake (189), and Panther Lake (204) laptop CPUs. Omarchy path: `install/config/hardware/intel/lpmd.sh`
- **LocalSend Nautilus action**: Adds a right-click "Send via LocalSend" action in the Nautilus file manager via a nautilus-python extension. Supports both native binary and Flatpak installations. Omarchy path: `default/nautilus-python/extensions/localsend.py`
- **`sff` function**: Shell function using fzf to select a file and send it over scp. Usage: `sff <destination>`. Omarchy path: `default/bash/aliases`
- **`ff` image previews in Kitty**: When `$TERM` is `xterm-kitty`, the `ff` fzf alias renders image files using `kitty icat` in the preview pane; other terminals fall back to `bat`. Omarchy path: `default/bash/aliases`
- **ONCE installer**: Adds `omarchy-install-once` script that installs `once-bin`, enables `once-background.service`, and launches the TUI. Omarchy path: `bin/omarchy-install-once`
- **`omarchy-sudo-passwordless-toggle`**: New script that grants the current user passwordless sudo for 15 minutes via a sudoers drop-in and a `systemd-run` expiry timer. A second invocation disables it early. Requires `gum` for confirmation prompt. Omarchy path: `bin/omarchy-sudo-passwordless-toggle`
- **npx lazy-install stubs**: Adds `omarchy-npx-install <package> [command-name]` which writes an `npx --yes` wrapper to `~/.local/bin`. Pre-installed stubs cover Opencode, Gemini, Codex, Copilot, and Playwright CLIs. Omarchy path: `bin/omarchy-npx-install`
- **Battery-low hook**: New `battery-low.sample` hook called with the current battery percentage when the low battery notification fires. Sample implementation plays a freedesktop warning sound via `mpv`. Omarchy path: `config/omarchy/hooks/battery-low.sample`
- **Lumon Industries theme**: Full theme with `colors.toml`, `hyprland.conf`, `waybar.css`, `btop.theme`, `swayosd.css`, `neovim.lua`, `vscode.json`, `chromium.theme`, `icons.theme`, and two wallpapers. Omarchy path: `themes/lumon/`
- **Retro 82 theme**: Full theme with the same file set as Lumon, plus eight wallpapers. Omarchy path: `themes/retro-82/`
- **Additional Gruvbox backgrounds**: Three new wallpapers added (flower-basket, village-square, idyllic-procession); the existing `2-leaves.jpg` was renumbered to `5-leaves.jpg`. Omarchy path: `themes/gruvbox/backgrounds/`
- **Consistent theme previews**: All included themes received updated `preview.png` files in a modern, consistent format.
- **Tmux copy-mode indicator**: Adds a `COPY` highlight in tmux status bar when in copy mode. Omarchy path: `config/tmux/tmux.conf`
- **Makima key remapping as opt-in setup**: `omarchy-setup-makima` installs `makima-bin`, copies the keyboard config, and enables the systemd service. Previously auto-installed; now user-initiated via `Setup > Key Remapping`. Omarchy path: `bin/omarchy-setup-makima`

## Bug Fixes

- **JetBrains Hyprland rules removed**: Deleted `default/hypr/apps/jetbrains.conf` (41 lines of custom window rules) since JetBrains IDEs now use Wayland natively. The source line was removed from `default/hypr/apps.conf`. Omarchy path: `default/hypr/apps.conf`
- **Voxtype GPU acceleration**: After install, `voxtype setup gpu --enable` is called when Vulkan is available (`omarchy-hw-vulkan` check). Omarchy path: `bin/omarchy-voxtype-install`
- **Battery remaining time with minutes unit**: `upower` can report time in minutes (e.g. `45.0 minutes`) rather than decimal hours. The parser now checks the unit field and formats accordingly. Omarchy path: `bin/omarchy-battery-remaining-time`
- **FUSE filesystem hang on suspend**: Adds a `system-sleep` hook that lazy-unmounts `gvfsd-fuse` filesystems before suspend/hibernate and restarts `gvfs-daemon.service` for each logged-in user after wake. Omarchy path: `default/systemd/system-sleep/unmount-fuse`
- **Moonlight fullscreen and idle inhibit**: New `moonlight.conf` Hyprland window rule forces Moonlight fullscreen and sets `idle_inhibit = fullscreen`. Omarchy path: `default/hypr/apps/moonlight.conf`
- **Firmware update UEFI capsule**: `omarchy-update-firmware` now installs `/usr/lib/fwupd/efi/fwupdx64.efi` to `/boot/EFI/arch/fwupdx64.efi` before running `fwupdmgr update`, fixing capsule delivery under the Limine bootloader. Omarchy path: `bin/omarchy-update-firmware`
- **Webcam overlay vertical framing**: Screen recording webcam overlay now applies `crop=iw/2:ih` before scaling, giving a vertically-framed crop instead of a wide crop. Omarchy path: `bin/omarchy-cmd-screenrecord`
- **VS Code Insiders theme**: `omarchy-theme-set-vscode` now also applies the active theme to VS Code Insiders (`~/.config/Code - Insiders/User/settings.json`). Omarchy path: `bin/omarchy-theme-set-vscode`
- **Screenshot directory creation**: Instead of failing with a critical notification when the screenshot output directory is missing, the script now creates it with `mkdir -p` and sends an informational notification. Omarchy path: `bin/omarchy-cmd-screenshot`
- **Update progress visibility**: `omarchy-update-perform` now runs inside a PTY via `script -qefc` (with `OMARCHY_UPDATE_LOGGED=1` guard) so pacman/yay keep showing live download progress while still writing the full session to `/tmp/omarchy-update.log`. Omarchy path: `bin/omarchy-update-perform`
- **Dell XPS 2026+ Wifi 7**: On Intel BE200/BE211 cards (PCI IDs `8086:e440` and `8086:272b`), disables WiFi 7 EHT mode via `iwlwifi disable_11be=Y` modprobe option (broken RX rate adaptation in current driver). Omarchy path: `install/config/hardware/intel/fix-wifi7-eht.sh`
- **Dell XPS 2026+ haptic trackpad**: Adds a systemd service (`dell-xps-haptic-touchpad.service`) that runs a daemon sending HID haptic feature reports for the Synaptics haptic touchpad (06CB:D01A). Also sets I2C runtime PM to `on` via udev rules to prevent state loss across suspend. Omarchy path: `install/config/hardware/dell/fix-xps-haptic-touchpad.sh`
- **Tuxedo/Slimbook keyboard backlighting**: Installs `tuxedo-drivers-nocompatcheck-dkms` on Tuxedo and Slimbook (Clevo chassis) hardware, and blacklists `clevo_xsm_wmi` which conflicts with the Tuxedo driver's WMI GUID registration. Omarchy path: `install/config/hardware/fix-tuxedo-backlight.sh`
- **T2 Mac fan curve**: `t2fand.conf` now uses `low_temp=55`, `high_temp=75`, `speed_curve=linear`, `always_full_speed=false` to better match original MacBook fan behavior. Omarchy path: `install/config/hardware/apple/fix-t2.sh`
- **T2 Mac Bluetooth**: `hci_bcm4377` added to `/etc/modules-load.d/t2.conf` to load the BCM4377 Bluetooth driver at boot. Omarchy path: `install/config/hardware/apple/fix-t2.sh`
- **T2 Mac keyboard backlight controls**: `tiny-dfr` package and service added to T2 Mac installation for Touch Bar / keyboard backlight control; user added to `video` group. Omarchy path: `install/config/hardware/apple/fix-t2.sh`

## Improvements

- **Hardware install script reorganization**: `install/config/hardware/` scripts reorganized into per-vendor subdirectories: `intel/`, `dell/`, `asus/`, `framework/`, `apple/`. `all.sh` updated with new paths and makima removed from automatic install.
- **`omarchy-sudo-reset` rename**: `bin/omarchy-reset-sudo` renamed to `bin/omarchy-sudo-reset` for naming consistency.

## Configuration Changes

- **Makima no longer auto-installed**: Removed from `install/config/all.sh`; now invoked explicitly via `omarchy-setup-makima` through the `Setup > Key Remapping` menu entry. Omarchy path: `install/config/all.sh`

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added (Intel PTL) | `linux-ptl`, `linux-ptl-headers` | Patched 6.19.10 kernel for Panther Lake hardware |
| Added (Intel thermal) | `thermald` | Thermal throttling daemon for Sandy Bridge+ Intel laptops |
| Added (Intel power) | `intel-lpmd` | Low Power Mode Daemon for hybrid Intel CPUs (Alder Lake+) |
| Added (Intel video) | `intel-media-driver` | Hardware video acceleration (replaces/supplements prior Intel video script) |
| Added (Tuxedo) | `tuxedo-drivers-nocompatcheck-dkms`, `linux-headers` | Keyboard backlighting for Tuxedo/Slimbook laptops |
| Added (ONCE) | `once-bin` | ONCE task service (installed via `omarchy-install-once`) |
| Added (makima) | `makima-bin` | Copilot key remapping (now opt-in via `omarchy-setup-makima`) |
| Added (T2 Mac) | `tiny-dfr` | Touch Bar / keyboard backlight control for T2 MacBooks |
