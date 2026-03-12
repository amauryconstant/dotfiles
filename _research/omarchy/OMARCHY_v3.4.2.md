# Omarchy v3.4.2 — Release Research

**Date researched**: 2026-03-12
**Previous version**: v3.4.1
**Commits**: 63
**Source**: GitHub release notes

---

## Summary

This release adds significant quality-of-life improvements across tmux, battery status, screen recording, and Hyprland input. It also includes a broad set of hardware fixes targeting Intel Panther Lake/Arc GPUs, Apple T2 Macs, and limine boot configurations, alongside the introduction of `makima-bin` for Copilot key remapping.

## Features

- **Fuller battery status notification**: New `Super+Ctrl+Alt+B` notification shows percentage, time remaining (charging or discharging), power draw in watts, and battery capacity in Wh. Implemented via three new scripts: `bin/omarchy-battery-status`, `bin/omarchy-battery-remaining-time`, `bin/omarchy-battery-capacity`.
- **Screen recording preview + open**: After stopping a recording, a thumbnail is generated via `ffmpeg` and shown in the notification. Clicking the notification or pressing `Super+Alt+,` opens the video in `mpv`. Omarchy path: `bin/omarchy-cmd-screenrecord`.
- **Git worktree helpers `ga` / `gd`**: `ga <branch>` creates a new worktree at `../<repo>--<branch>`, runs `mise trust`, and `cd`s into it. `gd` removes the current worktree and branch after a `gum confirm` prompt. Omarchy path: `default/bash/fns/worktrees`.
- **Scratchpad slide-in animation**: `specialWorkspace` animation added to Hyprland config (`slidevert`, easeOutQuint, duration 4). Omarchy path: `default/hypr/looknfeel.conf`.
- **Copilot key remapping via makima**: The Copilot hardware key on supported keyboards is remapped to the Omarchy Menu key using `makima`. Omarchy path: `default/makima/AT Translated Set 2 keyboard.toml`, `install/config/makima.sh`.
- **Touchpad gesture suggestions for scrolling layout**: Commented-out gesture bindings added for 3-finger left/right to move focus. Omarchy path: `config/hypr/input.conf`.
- **`Alt+Shift+Arrow` tmux window swap**: `M-S-Left` / `M-S-Right` swap tmux windows and follow focus. Omarchy path: `config/tmux/tmux.conf`.
- **Tmux automatic window renaming**: Windows auto-rename to the basename of the current directory. Format: `#{b:pane_current_path}`. Omarchy path: `config/tmux/tmux.conf`.
- **Tmux zoom indicator**: Status bar right segment now shows `ZOOM` when a pane is zoomed (`#{?window_zoomed_flag,ZOOM ,}`). Omarchy path: `config/tmux/tmux.conf`.

## Bug Fixes

- **Nvim transparency preserving foreground colors**: `transparency.lua` now uses `nvim_get_hl` to copy existing highlight attributes and only clears `bg`, preventing snacks.nvim GitHub integration crashes. Omarchy path: `~/.config/nvim/plugin/after/transparency.lua` (migration `1772389838.sh`).
- **Display scaling cycle preserving resolution/refresh rate**: `bin/omarchy-hyprland-monitor-scaling-cycle` fixed to not reset configured resolution and refresh rate when cycling scale.
- **Intel Panther Lake (Xe3) display at 10Hz**: New script disables Xe power-saving kernel parameters (`xe.enable_psr=0 xe.enable_panel_replay=0 xe.enable_fbc=0 xe.enable_dc=0`) via limine drop-in config. Omarchy path: `install/config/hardware/fix-intel-panther-lake-display.sh`.
- **`try` interactive selector on bashrc re-source**: Fixed `try` appearing unexpectedly when re-sourcing `.bashrc`. Omarchy path: `default/bash/init`.
- **`intel-media-driver` for Arc 130T/140T (Intel 255H)**: Install script corrected for these GPU variants. Omarchy path: `install/config/hardware/intel.sh`.
- **LM Studio downgrading to legacy package**: Fixed install selecting wrong (older) package version.
- **LocalSend small window size**: Window rule added to set correct minimum size. Omarchy path: `default/hypr/apps/localsend.conf`.
- **Omarchy themes menu in elephant provider list**: `omarchy_themes.lua` fixed to exclude omarchy themes from appearing as AI providers. Omarchy path: `default/elephant/omarchy_themes.lua`.
- **Omarchy menu toggling when already open**: `bin/omarchy-menu` fixed to detect open state and not re-trigger.
- **`wayfreeze-git` not removed in migration**: Migration `1762156000.sh` updated to also remove `wayfreeze-git`.
- **Limine kernel cmdline spacing for hibernation and T2 Mac configs**: `install/config/hardware/fix-apple-t2.sh` and related limine config fixed for correct spacing.
- **`limine-snapper` drop-in kernel cmdline append**: `install/login/limine-snapper.sh` updated to properly append drop-in configs rather than overwrite.
- **`mise` shim activation in `uwsm/env`**: `~/.config/uwsm/env` now uses `mise activate bash --shims` instead of `mise activate bash` (migration `1772632144.sh`).
- **`tmux attach` before new session**: `Super+Alt+Return` binding changed from `tmux new` to `bash -c "tmux attach || tmux new -s Work"`, attaching to an existing session if available. Omarchy path: `config/hypr/bindings.conf`.
- **Missing Intel GPU hardware acceleration drivers**: Migration `1772981757.sh` installs correct Intel VA-API/VDPAU drivers if an Intel GPU is detected.

## Breaking Changes

*None*

## Improvements

- **`plocate` indexing restricted to AC power**: Prevents `plocate` from triggering CPU/disk activity after sleep on battery. Implemented via `install/config/plocate-ac-only.sh` (migration `1772964511.sh`).
- **`hyprland-preview-share-picker` defaults to outputs page**: `default_page` changed from `windows` to `outputs` in `~/.config/hyprland-preview-share-picker/config.yaml` (migration `1772981555.sh`).
- **`Super+Shift+Return` browser shortcut added**: Additional keybinding `Super+Shift+Return` maps to `omarchy-launch-browser`. Omarchy path: `config/hypr/bindings.conf`.

## Configuration Changes

- **`config/tmux/tmux.conf`**: Added `M-S-Left`/`M-S-Right` swap-window bindings; added `automatic-rename on` and `automatic-rename-format '#{b:pane_current_path}'`; added `ZOOM` indicator to `status-right`.
- **`config/hypr/input.conf`**: Added commented-out `gesture = 3, left/right, dispatcher, movefocus` entries for optional scrolling layout navigation.
- **`config/hypr/bindings.conf`**: `Super+Alt+Return` now runs `tmux attach || tmux new -s Work`; `Super+Shift+Return` added as browser shortcut.
- **`default/hypr/looknfeel.conf`**: Added `animation = specialWorkspace, 1, 4, easeOutQuint, slidevert`.
- **`default/hypr/bindings/utilities.conf`**: `Super+Ctrl+Alt+B` now calls `omarchy-battery-status` (was inline `omarchy-battery-remaining`).
- **`config/uwsm/env`**: `mise activate bash` changed to `mise activate bash --shims`.
- **`config/hyprland-preview-share-picker/config.yaml`**: `default_page: windows` → `default_page: outputs`.

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `makima-bin` | Keyboard key remapping (Copilot key → Omarchy Menu) |

---

<details><summary>Original release notes</summary>

```
# What changed?

Update existing installations using `Update > Omarchy` from Omarchy menu (`Super + Alt + Space`).

Install on new machines with the ISO:
- Download: https://iso.omarchy.org/omarchy-3.4.2-2.iso
- SHA256: cf5ff60b7a9de4b4b82512bc6068e450bf0e9ff77c7082ae6624d022ec6faa33

## Additions

- Add fuller battery status notification showing percentage, time remaining, and power draw when using `Super + Ctrl + Alt + B` by @dhh
- Add preview + invoke-to-open for the screenrecording notification by @dhh
- Add `ga` / `gd` worktree helper functions for creating and removing git worktrees by @dhh
- Add scratchpad slide-in animation by @shelldandy
- Add Copilot key remapping to Omarchy Menu key via makima by @dhh
- Add suggested touchpad gestures for scrolling layout focus navigation by @dhh
- Add `Alt+Shift+Arrow` keybindings for swapping tmux windows by @dhh
- Add tmux automatic window renaming based on current directory by @jadonwb
- Add tmux zoom indicator in status bar by @dhh

## Fixes

- Fix nvim transparency to preserve foreground colors, resolving snacks.nvim GitHub integration crashes by @jorgemanrubia
- Fix display scaling cycle to preserve configured resolution and refresh rate by @Cammisuli
- Fix Panther Lake (Xe3) GPU display issues by disabling power-saving features by @dhh
- Fix `try` interactive selector appearing on bashrc re-source by @davidguttman
- Fix `intel-media-driver` install for Arc 130T/140T (Intel 255H) by @Riddlerrr
- Fix LM Studio install downgrading to legacy package by @timohubois
- Fix small LocalSend window size by @justindotdevv
- Fix omarchy themes menu appearing in elephant provider list by @dhh
- Fix omarchy menu toggling when already open by @dhh
- Fix `wayfreeze-git` not being removed in migration by @dhh
- Fix limine kernel cmdline spacing for hibernation and T2 Mac configs by @dhh
- Fix limine-snapper to append drop-in kernel cmdline configs by @dhh
- Fix mise shim activation in uwsm/env by @dhh
- Fix `tmux attach` before creating new session by @dhh
- Fix missing Intel GPU hardware acceleration drivers by @dhh
```

</details>
