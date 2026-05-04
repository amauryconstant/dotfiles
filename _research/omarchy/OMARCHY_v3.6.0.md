# Omarchy v3.6.0 — Release Research

**Date researched**: 2026-05-04
**Previous version**: v3.5.1
**Commits**: 89
**Source**: GitHub release notes

---

## Summary

This release (branded "Panther Lake Plus Extreme Efficiency Edition") focuses on three major themes: Panther Lake hardware optimization via an updated custom kernel and removal of now-unnecessary workarounds, a persistent toggle system for Hyprland flags that survives reloads and restarts, and improved laptop hardware management including lid-triggered display switching, touchpad control with OSD, and an internal monitor recovery service. It also tightens snapshot management by dropping /home snapshots and btrfs quotas entirely.

## Breaking Changes

- **Snapshot strategy change**: /home snapper config and all its snapshots are dropped. btrfs quotas are disabled. Root snapshots are kept to a maximum of 5 (timeline disabled). The migration script (`1776927490.sh`) handles this automatically and prompts before deleting /home snapshots if they appear to contain manually-created entries. Omarchy path: `default/snapper/root`, migration `migrations/1776927490.sh`.

- **VRR removed from default monitor line**: `vrr,1` is dropped from `monitor=,preferred,auto,auto,vrr,1` in `~/.config/hypr/monitors.conf` to avoid small input lag. Migration `1776781957.sh` patches existing installs.

## Features

- **Persistent Hyprland toggle system**: New `omarchy-hyprland-toggle` script copies named flag configs from `default/hypr/toggles/` into `~/.local/state/omarchy/toggles/hypr/` and calls `hyprctl reload`. Flags survive reloads and restarts. `hyprland.conf` is extended to source `~/.local/state/omarchy/toggles/hypr/*.conf`. Omarchy paths: `bin/omarchy-hyprland-toggle`, `default/hypr/toggles/flags.conf`, `install/config/omarchy-toggles.sh`.

- **Touchpad enable/disable/toggle with OSD and persistence**: New `omarchy-toggle-touchpad` with `on`/`off`/`toggle` subcommands. State persisted to `~/.local/state/omarchy/toggles/hypr/touchpad-disabled.conf`. Uses `XF86TouchpadOn/Off/Toggle` keysyms and `omarchy-swayosd-client` for feedback. Omarchy path: `bin/omarchy-toggle-touchpad`.

- **Lid open/close display control**: Internal display is toggled automatically via Hyprland `bindl` on `switch:on:Lid Switch` (off) and `switch:off:Lid Switch` (on). Omarchy path: `default/hypr/bindings/utilities.conf`.

- **Internal monitor recovery service**: New systemd user service `omarchy-recover-internal-monitor.service` re-enables the internal display at login if no external display is connected and the toggle flag is set. Omarchy path: `config/systemd/user/omarchy-recover-internal-monitor.service`, `bin/omarchy-hyprland-monitor-internal`, `bin/omarchy-hw-recover-internal-monitor`.

- **Monitor watch daemon**: New `omarchy-hyprland-monitor-watch` binary started at login via `socat` to detect external display unplug events and automatically recover the internal display. Depends on `socat` (now in base packages). Omarchy path: `bin/omarchy-hyprland-monitor-watch`.

- **1.25x scaling option and reverse scaling cycle**: Scaling cycle is now `1 → 1.25 → 1.6 → 2 → 3`. Reverse direction available via `Super + Alt + /`. Omarchy path: `bin/omarchy-hyprland-monitor-scaling-cycle`, `default/hypr/bindings/tiling-v2.conf`.

- **Screen recording audio normalization**: After recording stops, `omarchy-cmd-screenrecord` runs a single-pass ffmpeg with `loudnorm=I=-14:TP=-1.5:LRA=11` to lift quiet recordings to -14 LUFS. Only applied when the file has an audio stream. Omarchy path: `bin/omarchy-cmd-screenrecord`.

- **Voxtype `pause_media` default**: `default/voxtype/config.toml` now sets `pause_media = true` under `[audio]`, pausing MPRIS players while dictating. Migration `1776615976.sh` patches existing configs. Omarchy path: `default/voxtype/config.toml`.

- **Intel VPL video encoding**: `intel-media-driver`, `libvpl`, and `vpl-gpu-rt` are now installed together for HD/UHD/Xe/Iris/Arc GPUs, enabling Quick Sync H264/H265 (required for Kdenlive exports on modern Intel CPUs). Omarchy path: `install/config/hardware/intel/video-acceleration.sh`.

- **Voxtype GPU migration**: Migration `1775241210.sh` detects Vulkan availability and enables GPU acceleration in voxtype, then re-runs `voxtype setup systemd` to update the service file.

- **Hardware toggles menu (`Super + Ctrl + H`)**: New `omarchy-menu hardware` sub-menu accessible via the new keybinding. Shows laptop display toggle always; hybrid GPU and touchpad options shown only when hardware is present. Omarchy path: `bin/omarchy-menu`.

- **Monitor focus cycling**: `Ctrl + Alt + Tab` / `Ctrl + Alt + Shift + Tab` cycle focus through monitors. Omarchy path: `default/hypr/bindings/tiling-v2.conf`.

- **ThinkPad mic mute LED sync**: New `omarchy-cmd-mic-mute-thinkpad` script toggles mic mute via `wpctl` and syncs the `platform::micmute` LED via `brightnessctl`. Omarchy path: `bin/omarchy-cmd-mic-mute-thinkpad`.

- **Mako restart in Update > Process menu**: Mako is now listed alongside Hypridle, Hyprsunset, Swayosd, Walker, and Waybar in the process restart sub-menu. Omarchy path: `bin/omarchy-menu`.

- **Vantablack true-black and default background**: `background`, `selection_foreground`, and `color0` changed from `#0d0d0d` to `#000000`. A default background image `0-dot-hands.jpg` is added. Omarchy paths: `themes/vantablack/colors.toml`, `themes/vantablack/backgrounds/0-dot-hands.jpg`.

- **Faster window movement and special workspace animations**: Window animation duration reduced from 4.79 to 3.79; special workspace slide from 4 to 3. Omarchy path: `default/hypr/looknfeel.conf`.

- **Panther Lake custom kernel 6.19.13 patches**: Additional efficiency patches applied to the `linux-ptl` custom kernel build. Omarchy path: `install/config/hardware/intel/ptl-kernel.sh`.

## Bug Fixes

- **Orphaned `voxtype status --follow` processes**: `omarchy-voxtype-status` now traps `EXIT` with `kill 0` to clean up the child `voxtype status --follow` process when Waybar reloads. Omarchy path: `bin/omarchy-voxtype-status`.

- **`omarchy-update` hanging on Chromium/Brave**: The blocking `--refresh-platform-policy` call is skipped when Chromium/Brave is not running, preventing indefinite hang.

- **Keyboard layout reset after `omarchy-refresh-hyprland`**: Layout detection is re-run after the refresh. Omarchy path: `bin/omarchy-refresh-hyprland`.

- **Default audio sink not persisting**: `omarchy-cmd-audio-switch` now uses `wpctl set-default <wpid>` instead of `pactl set-default-sink` so WirePlumber's configured sink is actually updated. Omarchy path: `bin/omarchy-cmd-audio-switch`.

- **Typora print dialog not floating**: New `default/hypr/apps/typora.conf` adds `windowrule` to float and center the Typora print dialog. Omarchy path: `default/hypr/apps/typora.conf`.

- **Lumon theme selected text visibility**: `accent` color changed from `#f2fcff` (near-white) to `#8bc9eb` (mid-blue) for better contrast. Omarchy path: `themes/lumon/colors.toml`.

- **Elephant menu crash on themes without preview**: `omarchy_themes.lua` now falls back to the default theme's directory for the preview image when a user-customized theme lacks one. Omarchy path: `default/elephant/omarchy_themes.lua`.

- **iA Writer Typora dark theme OLED fix**: `config/Typora/themes/ia_typora_night.css` updated for better OLED rendering.

- **`cx` alias broken flag**: Updated from `--allow-dangerously-skip-permissions` to `--permission-mode bypassPermissions` to match Claude Code's current API. Omarchy path: `default/bash/aliases`.

- **Screensharing overlay hide button broken**: Fixed in the screensharing overlay UI. Omarchy path: `bin/omarchy-menu` or related share UI.

- **`omarchy-theme-install` not lowercasing theme name**: `tr '[:upper:]' '[:lower:]'` appended to the `sed` pipeline so theme directory names are always lowercase. Omarchy path: `bin/omarchy-theme-install`.

- **Dell XPS Panther Lake display workarounds removed**: `xe.enable_psr=0` kernel cmdline and disabled VRR are no longer needed. Migration `1776617403.sh` removes the drop-in and updates Limine. The install script `install/config/hardware/dell/fix-xps-ptl-display.sh` is deleted.

- **Resume-boost workaround removed**: The `system-sleep/resume-boost` hook is deleted. Migration `1776784497.sh` removes it from existing installs. Omarchy path: `default/systemd/system-sleep/resume-boost` (deleted).

## Improvements

- **Lazy initialization of `try` command**: `default/bash/init` wraps `try` in a shell function that defers `eval "$(try init ...)"` until first invocation, speeding up bash startup. Omarchy path: `default/bash/init`.

- **Kernel reboot detection fix**: `omarchy-update-restart` now detects a new kernel by checking for a `vmlinuz` newer than uptime start, replacing the fragile `/usr/lib/modules/$(uname -r)` directory check. Omarchy path: `bin/omarchy-update-restart`.

- **`omarchy-cmd-audio-switch` refactored to use `omarchy-swayosd-client`**: Removes direct `swayosd-client --monitor` calls in favor of the wrapper. Omarchy path: `bin/omarchy-cmd-audio-switch`.

- **`omarchy-hyprland-monitor-internal` replaces `omarchy-hyprland-monitor-internal-toggle`**: The old toggle-only script is replaced with a unified `on`/`off`/`toggle`/`recover` interface backed by the persistent toggle system. Omarchy path: `bin/omarchy-hyprland-monitor-internal`.

## Configuration Changes

- **Snapper root config**: New `default/snapper/root` ships `NUMBER_LIMIT=5`, `NUMBER_LIMIT_IMPORTANT=5`, `TIMELINE_CREATE=no`. This replaces any prior timeline-based config. Omarchy path: `default/snapper/root`.

- **`hyprland.conf` gains toggle flag sourcing**: `source = ~/.local/state/omarchy/toggles/hypr/*.conf` added so persistent toggle files are loaded on every reload. Migration `1776410469.sh` patches existing installs. Omarchy path: `config/hypr/hyprland.conf`.

- **`monitors.conf` default line strips VRR**: `monitor=,preferred,auto,auto,vrr,1` becomes `monitor=,preferred,auto,auto`. Migration `1776781957.sh`. Omarchy path: `config/hypr/monitors.conf`.

- **Voxtype `config.toml` adds `pause_media = true`**: Added under `[audio]` section. Migration `1776615976.sh` patches existing files. Omarchy path: `default/voxtype/config.toml`.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `socat` | IPC socket relay for `omarchy-hyprland-monitor-watch` (detect external display unplug) |
| Added | `libvpl` | Intel Video Processing Library for Quick Sync H264/H265 encoding |
| Added | `vpl-gpu-rt` | Intel VPL GPU runtime, enables hardware encode in Kdenlive on modern Intel GPUs |
