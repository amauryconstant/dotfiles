# Omarchy v3.8.3 — Release Research

**Date researched**: 2026-08-24
**Previous version**: v3.8.2
**Commits**: 25
**Source**: GitHub release notes

---

## Summary

Terminal/tmux ergonomics release: `Alt+Enter` pane splits backed by CSI-u `Shift+Return` encoding wired into all four shipped terminals (Alacritty, Foot, Ghostty, Kitty), plus tmux window titles carrying the hostname. The rest is hardware-fix work — Intel SOF audio firmware widened beyond Panther Lake, Mesa Vulkan driver backfill, LUKS-prompt keymap in the initramfs, and a power-profile udev rule fix for USB-C-only laptops. Four migration scripts ship to retrofit existing installs.

## Breaking Changes

*None*

## Features

- **CSI-u `Shift+Return` / `Alt+Shift+Return` encoding across terminals**: All four shipped terminals now emit `CSI 13;2u` for `Shift+Enter` and `CSI 13;4u` for `Alt+Shift+Enter`, so TUIs can distinguish these from plain `Enter` / `Alt+Enter`. Alacritty previously sent a bare `ESC CR` (indistinguishable from `Alt+Return`). Omarchy paths: `config/alacritty/alacritty.toml`, `config/foot/foot.ini` (new `[text-bindings]` section), `config/ghostty/config`, `config/kitty/kitty.conf`.
- **tmux pane controls on `Alt`**: `M-Enter` vertical split, `M-S-Enter` horizontal split, `M-Escape` kill-pane — all prefix-less (`bind -n`), alongside the existing prefixed `h`/`v`/`x`. Omarchy path: `config/tmux/tmux.conf`.
- **tmux window titles with hostname**: `set -g set-titles on` + `set -g set-titles-string '#h:#W'`, aiding identification of remote sessions inside Hyprland window groups. Omarchy path: `config/tmux/tmux.conf`.
- **`cy` alias**: `codex -s danger-full-access -a never` — Codex with full local access, no approval prompts. Omarchy path: `default/bash/aliases`.
- **`mup` alias**: `MISE_MINIMUM_RELEASE_AGE=0 mise up` — updates mise tools bypassing the release-age guard. Omarchy path: `default/bash/aliases`.
- **Dell XPS 13 (DX13260, 2026) text scaling**: New first-run step sets `org.gnome.desktop.interface text-scaling-factor` to `0.95` when `omarchy-hw-match "DX13260"` matches (2560x1600 panel). Omarchy paths: `install/first-run/text-scaling.sh`, invoked from `bin/omarchy-first-run`.
- **`omarchy-hw-intel-sof` detector**: New helper returning success when `lspci` reports an Intel `Multimedia audio controller` or `Audio device` (Skylake-and-later SOF DSP platforms). Omarchy path: `bin/omarchy-hw-intel-sof`.

## Bug Fixes

- **LUKS prompt keyboard layout on Plymouth 26**: `FILES+=(/etc/vconsole.conf)` appended to the mkinitcpio hooks drop-in so the console keymap is present in the initramfs. Omarchy paths: `install/login/limine-snapper.sh`, migration `migrations/1783355853.sh` (appends the line and runs `limine-mkinitcpio` if present).
- **Missing Mesa Vulkan drivers on older installs**: Hardware-aware backfill maps `lspci` VGA/Display vendor to `vulkan-intel` / `vulkan-radeon` / `vulkan-asahi` for systems installed before `vulkan.sh` existed. Omarchy path: `migrations/1783625095.sh`.
- **Power-profile udev rule failing on wakeup (USB-C-only laptops)**: Dropped the fixed `--unit=omarchy-power-profile` transient unit name from both `Mains` and `USB` rules; the fixed name collided when the unit still existed from a prior trigger. Omarchy path: `install/config/powerprofilesctl-rules.sh`.
- **Missing `sof-firmware` on Intel SOF DSP platforms**: Install guard widened from `omarchy-hw-intel-ptl && ! omarchy-hw-match "XPS"` to `omarchy-hw-intel-sof`, covering Arrow Lake, Meteor Lake, Tiger Lake, Alder Lake, Wildcat Lake, Panther Lake. Without the firmware the DSP fails to boot and PipeWire exposes only a Dummy Output sink. Migration sets `omarchy-state set reboot-required` when the firmware is newly installed. Omarchy paths: `install/config/hardware/intel/sof-firmware.sh`, `migrations/1783834201.sh`.
- **Repeated fingerprint setup failing with `libfprint-git` installed**: Pre-removal now tests `pacman -Qq libfprint` for an exact match instead of `omarchy-pkg-present libfprint`, which matched `libfprint-git` via its `provides`. Omarchy path: `bin/omarchy-setup-security-fingerprint`.
- **Package removal targeting provider names**: `omarchy-pkg-drop` switched from `pacman -Q "$pkg"` to `pacman -Qq | grep -Fxq "$pkg"`, so removal migrations no longer target a package name that is merely *provided* by an installed package. Omarchy path: `bin/omarchy-pkg-drop`.
- **Hyprland 0.55+ `togglesplit` compatibility**: `SUPER+J` changed from the bare `togglesplit` dispatcher to `layoutmsg, togglesplit`. Omarchy path: `default/hypr/bindings/tiling.conf`. (Not listed in the release notes; commits `8e031516` / `9a5e80f2`.)

## Improvements

- **tmux kitty extended keys appended, not overwritten**: `set -ag terminal-features "xterm-kitty:extkeys"` uses `-a` (append) so it does not clobber previously set terminal features (commit `efcd7805`).
- **Idempotent config migrations**: `migrations/1783833508.sh` guards every `sed` insertion with a `grep -Fq` check, so re-running does not duplicate tmux pane bindings or create a second `[text-bindings]` section in `foot.ini`. It calls `omarchy-restart-tmux` after editing.
- **SOF firmware promotion limited to kernel transitions**: Final iteration of the sof-firmware work restricts firmware promotion rather than installing unconditionally (commit `96fb7df4`).

## Configuration Changes

- **tmux**: Added `bind -n M-Enter split-window -v -c "#{pane_current_path}"`, `bind -n M-S-Enter split-window -h -c "#{pane_current_path}"`, `bind -n M-Escape kill-pane` under `# Pane Controls`; added `set -ag terminal-features "xterm-kitty:extkeys"` after `set -g extended-keys-format csi-u`; added `set -g set-titles on` and `set -g set-titles-string '#h:#W'`. Omarchy path: `config/tmux/tmux.conf`.
- **Alacritty**: Old — a single `Shift+Return` binding sending `ESC CR` (`\r`). New — `Shift+Return` sends `[13;2u` and a second binding `mods = "Alt|Shift"` sends `[13;4u`. Omarchy path: `config/alacritty/alacritty.toml`.
- **Foot**: New `[text-bindings]` section with `\x1b[13;2u=Shift+Return` and `\x1b[13;4u=Mod1+Shift+Return`. Omarchy path: `config/foot/foot.ini`.
- **Ghostty**: Added `keybind = shift+enter=csi:13;2u` and `keybind = alt+shift+enter=csi:13;4u`. Omarchy path: `config/ghostty/config`.
- **Kitty**: Added `map shift+enter send_text all \e[13;2u` and `map alt+shift+enter send_text all \e[13;4u`. Omarchy path: `config/kitty/kitty.conf`.
- **mkinitcpio drop-in**: `FILES+=(/etc/vconsole.conf)` added below the existing `HOOKS=(...)` line in `/etc/mkinitcpio.conf.d/omarchy_hooks.conf`. Omarchy path: `install/login/limine-snapper.sh`.
- **Power-profile udev rules**: `systemd-run` invocation in `/etc/udev/rules.d/99-power-profile.rules` lost `--unit=omarchy-power-profile`; retains `--no-block --collect --property=After=power-profiles-daemon.service`. Omarchy path: `install/config/powerprofilesctl-rules.sh`.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added (conditional) | `sof-firmware` | Intel SOF audio DSP firmware; guard widened from Panther-Lake-only to all Intel SOF platforms via `omarchy-hw-intel-sof` |
| Added (backfill) | `vulkan-intel` | Mesa Vulkan driver for Intel GPUs on installs predating `vulkan.sh` |
| Added (backfill) | `vulkan-radeon` | Mesa Vulkan driver for AMD GPUs on installs predating `vulkan.sh` |
| Added (backfill) | `vulkan-asahi` | Mesa Vulkan driver for Apple Silicon GPUs on installs predating `vulkan.sh` |
| Removed (conditional) | `libfprint` | Pre-removed with `pacman -Rdd` only when the exact package (not `libfprint-git`) is installed, so `libfprint-git` installs without a conflict prompt |
