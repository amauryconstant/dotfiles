# Omarchy v3.5.1 — Release Research

**Date researched**: 2026-05-04
**Previous version**: v3.5.0
**Commits**: 67
**Source**: GitHub release notes

---

## Summary

v3.5.1 is a large hardware-focused release with particular depth for Dell XPS systems on Intel Panther Lake. It adds mic mute LED sync, haptic touchpad improvements, internal display toggle, and resume performance boosting, while also fixing a broad range of power management, update flow, and browser configuration issues across 59 changed files.

## Breaking Changes

*None*

## Features

- **Dell XPS mic mute key with hardware LED sync**: New `omarchy-cmd-mic-mute-xps` script toggles the default audio source via `wpctl`, syncs the ALSA capture switch to keep the hardware mic LED in sync, and shows an OSD notification. The generic `omarchy-cmd-mic-mute` dispatcher routes to the XPS variant on matching hardware. Omarchy path: `bin/omarchy-cmd-mic-mute-xps`
- **Resume performance boost for Panther Lake**: A new `system-sleep` hook script switches to the performance power profile on wake, then restores the previous profile after 10 seconds via `systemd-run`. Installed only on Intel systems. Omarchy path: `default/systemd/system-sleep/resume-boost`
- **Trigger > Toggle > Laptop Display**: New menu entry calls `omarchy-hyprland-monitor-internal-toggle`, which finds the `eDP` monitor via `hyprctl`, toggles it off or back on, and guards against disabling the only active display. Omarchy path: `bin/omarchy-hyprland-monitor-internal-toggle`
- **Update > Hardware > Trackpad**: Existing trackpad restart expanded to cover both `i2c_hid_acpi` (DesignWare I2C) and `intel_quicki2c` (THC) driver paths; previously only reloaded `intel_quicki2c`. Omarchy path: `bin/omarchy-restart-trackpad`
- **Logitech MX Keys binding examples**: Commented examples for Print Screen, Dictation, and Emoji hardware keys added to `config/hypr/bindings.conf` for new installs. Omarchy path: `config/hypr/bindings.conf`

## Bug Fixes

- **Fcitx5 icon in Waybar**: Instead of deleting the system autostart file, a `Hidden=true` XDG override is now placed at `~/.config/autostart/org.fcitx.Fcitx5.desktop`. The old `install/config/remove-fcitx5-autostart.sh` is removed. Omarchy path: `config/autostart/org.fcitx.Fcitx5.desktop`
- **Intel Panther Lake display freezes and glitches**: `install/config/hardware/dell/fix-xps-ptl-display.sh` now disables both `xe.enable_psr=0` and `xe.enable_panel_replay=0` (OLED panels) or only PSR (IPS panels) via a Limine drop-in. The kernel cmdline parameter is also patched in existing installs by migration `1775954402.sh`.
- **Haptic touchpad detection breadth**: `omarchy-haptic-touchpad` and its installer now match any Synaptics touchpad with vendor `06CB` rather than a single specific model string, broadening XPS compatibility. Omarchy path: `install/config/hardware/dell/fix-xps-haptic-touchpad.sh`
- **Hyprland config errors during git update**: `omarchy-update-git` now calls `hyprctl keyword debug:suppress_errors true` before pulling and runs `hyprctl reload` after, preventing spurious parse errors on config files mid-pull. Omarchy path: `bin/omarchy-update-git`
- **Double sudo prompt during updates**: PTY logging wrapper moved earlier in the update flow in `bin/omarchy-update`.
- **Intel LPMD not enabled after installation**: `install/config/hardware/intel/lpmd.sh` now calls `sudo systemctl enable intel_lpmd.service` (previously missing). Migration `1775546086.sh` enables the service on existing installs.
- **Power profile rules running on every update**: `install/config/powerprofilesctl-rules.sh` is simplified; rule logic is now split into `omarchy-powerprofiles-set` (profile selection) and `omarchy-powerprofiles-init` (boot-time application). The udev rules use `systemd-run` to avoid races.
- **npx wrappers using system Node**: `bin/omarchy-npx-install` updated so npx runs through mise-managed `node@latest`. Migration `1775236589.sh` re-runs the npx install script on existing machines.
- **Starship prompt in dumb bash sessions**: `default/bash/init` guards `starship init` with `[[ $- == *i* ]] && [[ ${TERM:-} != "dumb" ]]`, preventing init errors during `scp`/`rsync`.
- **Display scaling cycle notification warnings**: `omarchy-hyprland-monitor-scaling-cycle` no longer emits Hyprland scale notification; the two-line block was removed.
- **Chromium default appearance**: Chromium initial preferences set `color_scheme: 0` (device/system) instead of dark. Browser theme setter (`omarchy-theme-set-browser`) sets `BrowserColorScheme: device` for both Chromium and Brave. Migration `1775946416.sh` patches existing Chromium `Default/Preferences`.
- **btop.conf for v1.4.6**: `config/btop/btop.conf` updated to match the new format expected by btop 1.4.6 (120-line diff). Omarchy path: `config/btop/btop.conf`
- **Hibernation btrfs resume offset lookup**: `omarchy-hibernation-setup` now handles a failed `btrfs inspect-internal map-swapfile` gracefully instead of leaving an empty `resume_offset` in the Limine drop-in. Migration `1775954402.sh` retroactively patches broken installs.
- **Chromium/Brave stderr noise during theme switch**: `omarchy-theme-set-browser` redirects `--refresh-platform-policy` output to `/dev/null`. Omarchy path: `bin/omarchy-theme-set-browser`
- **AC power udev rules failing silently at boot**: Rules in `install/config/powerprofilesctl-rules.sh` and `install/config/wifi-powersave-rules.sh` now wrap `powerprofilesctl set` calls with `systemd-run --no-block` so the power-profiles daemon is guaranteed to be available. Migration `1775897694.sh` reinstalls the updated rules.
- **Intel video acceleration migration referencing renamed path**: Path corrected in the relevant migration script.
- **Browser launcher not recognizing new Brave origin**: `omarchy-launch-browser` updated to detect the new Brave binary/origin string.
- **Walker app launcher sluggishness**: `omarchy-launch-walker` now starts the walker GApplication service with `env GSK_RENDERER=cairo` to force the Cairo software renderer, avoiding GPU-related sluggishness on some systems. Omarchy path: `bin/omarchy-launch-walker`
- **Performance power profile on AC boot**: New `omarchy-powerprofiles-init` script runs at boot to apply the correct profile based on current power state (udev rules only fire on state changes). Omarchy path: `bin/omarchy-powerprofiles-init`

## Improvements

- **makima removed**: The makima key-remapping service is disabled and uninstalled for existing users via migration `1776246235.sh`; the Copilot key is now handled natively by Hyprland. `omarchy-restart-makima` and `omarchy-setup-makima` binaries and the `default/makima/` config are deleted.
- **AC presence detection script**: New `omarchy-ac-present` binary reads `/sys/class/power_supply/AC*` and `ADP*` sysfs nodes, used by `omarchy-powerprofiles-init`. Omarchy path: `bin/omarchy-ac-present`
- **Focused monitor helper**: New `omarchy-hyprland-monitor-focused` binary returns the name of the currently focused monitor, used by OSD commands. Omarchy path: `bin/omarchy-hyprland-monitor-focused`
- **ISO available**: New installer ISO `omarchy-3.5.1-2.iso` published at `https://iso.omarchy.org/`.

## Configuration Changes

- **btop.conf**: Full rewrite for btop v1.4.6 compatibility; format and key names changed. Omarchy path: `config/btop/btop.conf`
- **Hyprland media bindings**: `XF86AudioMicMute` now calls `omarchy-cmd-mic-mute` (dispatch wrapper) instead of a direct `wpctl` call. Omarchy path: `default/hypr/bindings/media.conf`
- **Hyprland looknfeel.conf**: Minor change (1 line); likely related to scaling notification removal. Omarchy path: `default/hypr/looknfeel.conf`
- **Hyprland autostart.conf**: One entry added; likely the `omarchy-powerprofiles-init` or resume-boost setup hook. Omarchy path: `default/hypr/autostart.conf`
- **Fcitx5 autostart**: Mechanism changed from system-file deletion to user-level XDG `Hidden=true` override at `~/.config/autostart/org.fcitx.Fcitx5.desktop`.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Removed | `makima-bin` | Key remapping service replaced by native Hyprland handling |
