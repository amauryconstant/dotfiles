# Omarchy Integration Backlog

Living actionable backlog. Updated by `/omarchy-changes`.
Last updated: 2026-05-13 (through v3.8.0). Batch 1 implemented 2026-05-04.

**Legend**: `[ ]` pending · `[x]` done · `[SKIPPED]` out of scope

---

## P1 — High Priority

*(All P1 items resolved — moved to Skipped section)*

---

## P2 — Medium Priority

### VRR removed from default monitor line (v3.6.0)
**What**: v3.6.0 drops `vrr,1` from the default `monitor=,preferred,auto,auto,vrr,1` line to avoid small input lag. Our `monitor.conf.tmpl` uses `monitor=DP-1,3840x2160@144,0x0,1.25` (explicit config, no VRR flag) so we're not affected by the default line — but worth confirming VRR is not implicitly set.
**Target files**: `private_dot_config/hypr/conf/monitor.conf.tmpl`
**Effort**: Low

- [x] Confirm no `vrr,1` in our `monitor.conf.tmpl` entries (explicit per-monitor lines don't use the catch-all default anyway)
- [x] If any catch-all `monitor=,...,vrr,1` line exists, remove `vrr,1`

---

### Persistent Hyprland toggle system (v3.6.0)
**What**: Named flag configs persisted to `~/.local/state/omarchy/toggles/hypr/` and sourced on every `hyprctl reload`. Survives restarts. Powers touchpad toggle, display toggle, etc.
**Target files**: `private_dot_config/hypr/hyprland.conf.tmpl` (add source glob), new state directory
**Effort**: Medium
**Adapt from**: `bin/omarchy-hyprland-toggle`, `default/hypr/toggles/flags.conf`

- [ ] Add `source = ~/.local/state/dotfiles/toggles/hypr/*.conf` (adapted path, not omarchy) to `hyprland.conf.tmpl`
- [ ] Create `~/.local/state/dotfiles/toggles/hypr/` in the `create_necessary_directories` script
- [ ] Implement `hypr-toggle` script that copies/removes flag conf files to state dir and runs `hyprctl reload`
- [ ] Use as foundation for touchpad toggle (see P3 item below)

---

### `mise activate bash --shims` in uwsm/env (v3.4.2)
**What**: Omarchy changed `~/.config/uwsm/env` to use `mise activate bash --shims` instead of `mise activate bash`. The `--shims` flag ensures mise-managed tools are available in non-interactive Wayland session environments (e.g., for apps launched from Hyprland that don't spawn a login shell).
**Target files**: `private_dot_config/uwsm/env` (new managed file)
**Effort**: Low

- [x] Create `private_dot_config/uwsm/env` managed by chezmoi
- [x] Set `mise activate bash --shims` in that file
- [ ] Verify mise-managed tools (e.g., node, ruby) are visible to Wayland-launched apps

---

### LocalSend minimum window size rule (v3.4.2)
**What**: LocalSend opens with a small default window. A `windowrulev2` with `minsize` fixes this.
**Target files**: `private_dot_config/hypr/conf/windowrules.conf`
**Effort**: Low

- [x] Add window rule for LocalSend: `windowrule = match:class localsend, minsize 600 400`
- [ ] Confirm localsend class name: `hyprctl clients | grep -A5 -i localsend`

---

### colors.toml theme generation pattern (v3.3.0, v3.3.1)
**What**: Single `colors.toml` (24 semantic color fields) generates all app configs via templates. Directly parallels our 24-variable semantic architecture. Could reduce per-theme manual maintenance (currently each theme has 13 separate config files).
**Target files**: `private_dot_config/themes/`
**Effort**: High
**Note**: Monitor as Omarchy's implementation stabilizes (v3.3.1 still fixing regressions in the template system). Not a direct copy — adapt the generation pattern to work with our chezmoi template system.

- [ ] Review final `colors.toml` format in Omarchy (post v3.3.1 stabilization)
- [ ] Prototype: extend `generate-theme-shell-colors.sh` to output a `colors.toml` alongside existing shell format
- [ ] Evaluate whether template-driven per-app generation would reduce maintenance burden vs current symlink approach

---

### Lid open/close display control (v3.6.0)
**What**: Internal display auto-toggles via Hyprland `bindl` on `switch:on:Lid Switch` (off) and `switch:off:Lid Switch` (on). Only relevant on laptops (`chassisType == "laptop"`).
**Target files**: `private_dot_config/hypr/conf/bindings/desktop-utilities.conf` (or new `hardware.conf`)
**Effort**: Low

- [ ] Add `bindl = , switch:on:Lid Switch, exec, <internal-monitor-off>` and `bindl = , switch:off:Lid Switch, exec, <internal-monitor-on>` (conditioned on `chassisType == "laptop"`)
- [ ] Wire to `hypr-toggle` or a lightweight script to disable/enable `eDP` output via `hyprctl`
- [ ] Guard against disabling only active display

---

### Audio switch `wpctl set-default` fix (v3.6.0)
**What**: Our `audio-switch` script uses `pactl set-default-sink` which doesn't persist via WirePlumber. Should use `wpctl set-default <wpid>` so the configured sink is actually updated in WirePlumber state.
**Target files**: `private_dot_local/lib/scripts/desktop/executable_audio-switch`
**Effort**: Low

- [x] Replace `pactl set-default-sink "$next_sink"` with `wpctl set-default` using PipeWire object ID from pactl JSON `.index` field *(done 2026-05-04)*
- [ ] Test: switch audio device, close session, reopen — sink should persist

---

### Live weather in Waybar (v3.8.0)
**What**: `custom/weather` module polls a weather script every 60 seconds and shows current conditions in the bar. Notification on `Super+Ctrl+Alt+W`. The CSS block and config comment are already present in our Waybar files — just need the weather script and to uncomment the module.
**Target files**: `private_dot_config/waybar/config.tmpl`, `private_dot_config/waybar/style.css.tmpl`, new `private_dot_local/lib/scripts/desktop/executable_waybar-weather`
**Effort**: Medium
**Adapt from**: `default/waybar/weather.sh` (Omarchy)

- [ ] Implement weather script using `wttr.in` or `open-meteo.com` (local units, icon + temp output)
- [ ] Uncomment `"custom/weather"` in `modules-center` in `config.tmpl`
- [ ] Uncomment `#custom-weather` CSS block in `style.css.tmpl` (already present as comment)
- [ ] Add `Super+Ctrl+Alt+W` binding to show full weather notification
- [ ] Set poll interval to 60 seconds in module config

---

## P3 — Low Priority / Evaluate

### Scratchpad slide-in animation (v3.4.2)
**What**: Omarchy adds `animation = specialWorkspace, 1, 4, easeOutQuint, slidevert` for a smooth vertical slide-in when toggling the scratchpad. We have this line commented out in `animations.conf` with a different curve (`default`).
**Target files**: `private_dot_config/hypr/conf/animations.conf`
**Effort**: Low

- [x] Enable `animation = specialWorkspace, 1, 4, easeOutQuint, slidevert` + `bezier = easeOutQuint, 0.23, 1, 0.32, 1`
- [ ] Test visually — scratchpad toggle should animate vertically

---

### `hyprland-preview-share-picker` default page (v3.4.2)
**What**: Setting `default_page: outputs` in `~/.config/hyprland-preview-share-picker/config.yaml` makes screen share picker default to display outputs rather than individual windows. More natural for most sharing scenarios.
**Target files**: `private_dot_config/hyprland-preview-share-picker/config.yaml` (new managed file)
**Effort**: Low

- [x] Create `private_dot_config/hyprland-preview-share-picker/config.yaml` with `default_page: outputs`

---

### Automatic power profile on AC plug/unplug (v3.4.0, v3.5.1)
**What**: Power profile switches automatically based on AC state. v3.5.1 adds `omarchy-powerprofiles-init` for boot-time profile application (udev rules only fire on state changes, not at boot). Our setup has manual power profile switching in the menu.
**Target files**: Systemd udev rule or hook
**Effort**: Medium
**Adapt from**: `bin/omarchy-ac-present`, `bin/omarchy-powerprofiles-init`

- [ ] Review Omarchy's implementation: udev rules for AC plug/unplug + `systemd-run --no-block` for daemon availability
- [ ] Add a boot-time autostart that applies the correct profile based on current AC state (fixes "stuck on balanced at boot" issue)
- [ ] Evaluate whether to add automatic switching for plug/unplug events alongside existing manual control

---

### Sticky CWD when opening new terminal (v2.0.0)
**What**: New terminal windows inherit the current working directory from an existing terminal. Quality-of-life improvement.
**Target files**: Ghostty config or terminal keybinding exec command
**Effort**: Medium

- [ ] Investigate Ghostty's `--working-directory` flag or `HYPRLAND_INSTANCE_SIGNATURE`-based approach
- [ ] If feasible: update terminal launch binding in `applications.conf.tmpl`

---

### ALT+TAB window cycling (v1.7.0)
**What**: `Alt+Tab` cycles between windows on active workspace including floating. Currently not bound.
**Target files**: `private_dot_config/hypr/conf/bindings/focus-navigation.conf`
**Effort**: Low
**Note**: May conflict with application-level Alt+Tab if Hyprland intercepts it globally.

- [ ] Evaluate whether global `Alt+Tab` intercept is desirable given application usage
- [ ] If yes: add `bindd = ALT, Tab, Cycle windows, cyclenext` and `bindd = ALT SHIFT, Tab, Cycle windows backward, cyclenext, prev`

---

### Screensaver (hypridle/hyprlock) tuning (v1.10.0)
**What**: Omarchy tested battery notification persistence at 30 seconds. Our idle timeout values are intentionally more relaxed (5/10/15min vs Omarchy's 2.5/5/5.5min), but the notification duration may differ.
**Target files**: dunst or swaync config
**Effort**: Low

- [ ] Review battery notification duration in dunst/swaync config — confirm 30s persistence or adjust to taste

---

### Fuller battery status notification — minutes unit fix (v3.4.2, v3.5.0)
**What**: On-demand notification (`Super+Ctrl+Alt+B`) showing battery percentage, time remaining (charging or discharging), power draw in watts, and battery capacity in Wh. v3.5.0 fixes a parser bug: `upower` can report time in minutes (e.g. `45.0 minutes`) rather than decimal hours — the unit field must be checked. Our `battery-status` script uses `awk '/time to empty/ {print $4, $5}'` which already prints the unit word, so it may handle this already — needs verification.
**Target files**: `private_dot_local/lib/scripts/desktop/executable_battery-status`
**Effort**: Low

- [x] Implemented as `battery-status` script using `upower` output
- [x] Added `Super+Ctrl+Alt+B` binding to `desktop-utilities.conf`
- [x] Verified: `awk '/time to empty/ {print $4, $5}'` prints both value and unit — handles both "1.5 hours" and "45.0 minutes" correctly *(confirmed 2026-05-04)*

---

### Screen recording notification thumbnail + open (v3.4.2, v3.5.0, v3.6.0)
**What**: After stopping a screen recording, generates a thumbnail via `ffmpeg` and sends a desktop notification. v3.5.0 fixes webcam overlay crop (`crop=iw/2:ih` before scaling). v3.6.0 adds audio normalization: single-pass ffmpeg `loudnorm=I=-14:TP=-1.5:LRA=11` after recording stops (only when audio stream present).
**Target files**: `private_dot_local/lib/scripts/desktop/executable_screenrecord`
**Effort**: Medium
**Adapt from**: `bin/omarchy-capture-screenrecording` (renamed from `omarchy-cmd-screenrecord` in v3.7.0)

- [ ] Add thumbnail generation: `ffmpeg -ss 0 -vframes 1 -i "$output_file" "$thumb_file"` after recording stops
- [ ] Add `notify-send` with thumbnail icon and open action (clicking opens in `mpv`)
- [ ] Add `Super+Alt+,` open-last-recording binding to `screenshots.conf`
- [ ] Add audio normalization pass: `ffmpeg -i input -af loudnorm=I=-14:TP=-1.5:LRA=11` (check for audio stream first; rename file)

---

### `sff` shell function — send file via scp with fzf (v3.5.0)
**What**: Shell function using fzf to select a file and send it over scp. Usage: `sff <destination>`. Lightweight, uses tools already installed.
**Target files**: `private_dot_config/zsh/dot_zshrc.d/`
**Effort**: Low
**Adapt from**: `default/bash/aliases` (`sff` function)

- [x] Implemented `sff` as zsh function in `aliases.zsh` *(done 2026-05-04)*

---

### FUSE filesystem hang on suspend fix (v3.5.0)
**What**: A `system-sleep` hook lazy-unmounts `gvfsd-fuse` filesystems before suspend/hibernate and restarts `gvfs-daemon.service` on wake. Prevents system hangs when suspending with mounted FUSE filesystems.
**Target files**: `/etc/systemd/system-sleep/` (system-level hook, via a lifecycle script)
**Effort**: Medium
**Adapt from**: `default/systemd/system-sleep/unmount-fuse`

- [ ] Evaluate if gvfsd-fuse is relevant to our setup (used by Nautilus/GNOME Keyring)
- [ ] If yes: create `run_once_after_setup_fuse_suspend_hook.sh.tmpl` to install the sleep hook script
- [ ] Hook: lazy-unmount `$(pgrep -a gvfsd-fuse | awk '{print $NF}')` before sleep; restart `gvfs-daemon.service` on wake

---

### Touchpad toggle with OSD and persistence (v3.6.0)
**What**: `omarchy-toggle-touchpad` with `on`/`off`/`toggle` subcommands. State persisted to toggle system (see P2 persistent toggle item). Hardware keyboard keys `XF86TouchpadOn/Off/Toggle` plus explicit binding. Useful primarily on laptops.
**Target files**: `private_dot_config/hypr/conf/bindings/hardware.conf` (new), `private_dot_local/lib/scripts/desktop/`
**Effort**: Medium
**Adapt from**: `bin/omarchy-hw-touchpad`

- [ ] Depends on: persistent Hyprland toggle system (P2 item)
- [ ] Implement `touchpad-toggle` script: `hyprctl keyword device[synps/2 synaptics touchpad].enabled false/true` + `notify-send` OSD
- [ ] Persist state via toggle conf file (e.g., `~/.local/state/dotfiles/toggles/hypr/touchpad-disabled.conf`)
- [ ] Add `bindl = , XF86TouchpadToggle, exec, touchpad-toggle toggle` to hardware bindings (laptop only)

---

### Voxtype `pause_media` default (v3.6.0)
**What**: Omarchy's voxtype config now sets `pause_media = true` under `[audio]`, pausing MPRIS players while dictating. Our voxtype setup handles submap and push-to-talk bindings but we don't manage the voxtype `config.toml` directly.
**Target files**: `~/.config/voxtype/config.toml` (not currently managed by chezmoi)
**Effort**: Low

- [x] Added `pause_media = true` to `[audio]` section; file now chezmoi-managed at `private_dot_config/voxtype/config.toml` *(done 2026-05-04)*
- [ ] Note: `voxtype setup systemd` may overwrite parts of the config; verify approach

---

### `dosfstools` for FAT filesystem repair (v3.7.0)
**What**: `dosfstools` provides `fsck.fat` and `mkfs.fat` for /boot FAT partition repair. Useful when /boot is on a FAT partition (EFI system partition). Lightweight, no conflicts.
**Target files**: `.chezmoidata/packages.yaml`
**Effort**: Low

- [ ] Add `dosfstools` to an appropriate module in `packages.yaml` (e.g., `system_utilities`)

---

### OCR text extraction from screen region (v3.7.0)
**What**: Freeze screen with `hyprpicker`, select region with `slurp`, capture with `grim`, extract text with `tesseract`, copy to clipboard. `tesseract` and `tesseract-data-eng` need to be installed.
**Target files**: `.chezmoidata/packages.yaml`, `private_dot_local/lib/scripts/desktop/`, `private_dot_config/hypr/conf/bindings/screenshots.conf`
**Effort**: Low
**Adapt from**: `bin/omarchy-capture-text-extraction`

- [ ] Add `tesseract` and `tesseract-data-eng` to `packages.yaml`
- [ ] Implement `capture-text-extraction` script: `hyprpicker -r -z` to freeze, `slurp` to select, `grim -g` to capture, `tesseract` to extract, `wl-copy` to clipboard
- [ ] Add binding (e.g. `Super+Ctrl+PrtScr`) to `screenshots.conf`

---

### `ic`/`ix`/`icx` tdl alias replacements (v3.7.0)
**What**: Omarchy replaced `i='tdl c cx'` with three focused aliases: `ic='tdl c'`, `ix='tdl cx'`, `icx='tdl c cx'`. If we use `tdl` (task download/list tool), our aliases should be updated to match this more granular split.
**Target files**: `private_dot_config/zsh/dot_zshrc.d/aliases.zsh`
**Effort**: Low

- [ ] Check if `i='tdl c cx'` or `tdl` aliases exist in our `aliases.zsh`
- [ ] If yes: replace with `ic`, `ix`, `icx` per v3.7.0 pattern

---

### Reminder system (v3.8.0)
**What**: CLI to set one-shot reminders via systemd timers with desktop notifications. Three operations: set (`Super+Ctrl+R`), show all, clear all. Lightweight; only needs systemd (already present) and notify-send.
**Target files**: `private_dot_local/lib/scripts/desktop/`, `private_dot_config/hypr/conf/bindings/desktop-utilities.conf`
**Effort**: Medium
**Adapt from**: `bin/omarchy-reminder`

- [ ] Implement `reminder` script: parse duration input (e.g. "30m", "2h"), create one-shot `systemd-run --user` timer with `notify-send` on fire
- [ ] Add list and clear subcommands (`systemctl --user list-timers | grep reminder`)
- [ ] Add bindings: `Super+Ctrl+R` to set, `Super+Ctrl+Alt+R` to list, `Super+Ctrl+Shift+R` to clear all

---

### Video-to-GIF / transcode utilities (v3.7.0, v3.8.0)
**What**: v3.7.0 adds a `transcode-video-gif` shell function. v3.8.0 expands to `omarchy-transcode` covering video (mp4, gif), audio, and pictures. Useful for sharing screen recordings as GIFs.
**Target files**: `private_dot_local/lib/scripts/desktop/` or `private_dot_config/zsh/dot_zshrc.d/`
**Effort**: Low
**Adapt from**: `bin/omarchy-transcode`

- [ ] Implement `video-to-gif` function/script using `ffmpeg` (palette generation + dither for quality GIFs)
- [ ] Consider whether full transcode menu (audio, picture) is worth adding or just GIF conversion

---

### Middle-click paste (GTK primary selection) (v3.8.0)
**What**: `gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true` enables middle-click paste in GTK apps and Chromium. Not currently applied in our setup.
**Target files**: A lifecycle script or hook
**Effort**: Low

- [ ] Add `gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true` to an appropriate `run_once_after_*` script or hook
- [ ] Verify it takes effect in GTK apps (Nautilus, etc.) and Chromium

---

### Idle lock display-off improvement (v3.8.0)
**What**: `omarchy-system-lock` now powers off display 3 seconds after locking if hyprlock is still running, and `omarchy-system-wake` re-enables display on wake. Improves the lock experience by ensuring display turns off (DPMS) promptly.
**Target files**: `private_dot_config/hypr/conf/hypridle.conf` or a lock script
**Effort**: Low
**Adapt from**: `bin/omarchy-system-lock`, `bin/omarchy-system-wake`

- [ ] Check current hypridle config for DPMS timeout after lock
- [ ] If no post-lock display-off: add a 3-second post-lock `hyprctl dispatch dpms off` (e.g. via hypridle `on-lock` event or a wrapper script)
- [ ] Ensure display wakes correctly on resume

---

## Completed

- [x] **Audio switch `wpctl` persistence fix** (v3.6.0) — replaced `pactl set-default-sink` with `wpctl set-default` using PipeWire object ID from pactl JSON *(done 2026-05-04)*
- [x] **`sff` shell function** (v3.5.0) — `sff() { local f; f=$(fzf) && scp "$f" "$1"; }` added to `aliases.zsh` *(done 2026-05-04)*
- [x] **Battery status minutes-unit handling** (v3.5.0) — confirmed `awk '/time to empty/ {print $4, $5}'` handles both hours and minutes correctly *(confirmed 2026-05-04)*
- [x] **VRR removal confirmed** (v3.6.0) — no `vrr,1` in `monitor.conf.tmpl`; explicit per-monitor lines unaffected *(confirmed 2026-05-04)*
- [x] **Notification grouping** (v3.8.0) — `"notification-grouping": true` already present in `swaync/config.json` *(confirmed 2026-05-13)*
- [x] **`sof-firmware`** (v3.8.0) — already in `packages.yaml` as Intel audio DSP firmware *(confirmed 2026-05-13)*
- [x] **Scratchpad keybindings** (v3.1.4) — `Super+S` toggle scratchpad, `Super+Shift+S` move to scratchpad already implemented in `window-management.conf` *(confirmed 2026-02-21)*
- [x] **Smart screenshot selection** (v3.1.0) — `Print` smart screenshot, `Shift+Print` clipboard screenshot already implemented in `screenshots.conf` *(confirmed 2026-02-21)*
- [x] **`Super+Ctrl+T` Activity / `Super+Ctrl+B` Bluetooth** (v3.1.2, v3.3.0) — Both already implemented in `desktop-utilities.conf` *(confirmed 2026-02-21)*
- [x] **`hyprsunset` night light** (v1.10.0) — `hyprsunset` in packages.yaml; `Super+N` nightlight toggle already implemented in `desktop-utilities.conf` *(confirmed 2026-02-21)*
- [x] **Hyprland 0.53 windowrule/layerrule syntax** (v3.3.0) — Already resolved; `windowrules.conf` uses new `match:` syntax *(confirmed 2026-02-21)*
- [x] **`ghostty` as primary terminal** (v3.2.0) — In packages, used as default terminal *(confirmed 2026-02-21)*
- [x] **`starship` prompt** (v2.0.0) — In packages, configured *(confirmed 2026-02-21)*
- [x] **`dust` disk usage TUI** (v2.0.0) — In packages (`terminal_tools` module) *(confirmed 2026-02-21)*
- [x] **`satty` screenshot annotation** (v1.6.0) — In packages and used in screenshot workflow *(confirmed 2026-02-21)*
- [x] **`swayosd` OSD overlay** (v1.6.1) — In packages (`desktop_hyprland` module) *(confirmed 2026-02-21)*
- [x] **`gpu-screen-recorder-git`** (v2.0.0) — In packages (`desktop_hyprland` module) *(confirmed 2026-02-21)*
- [x] **`cliphist` clipboard manager** (v3.1.0) — In packages; `Super+C` opens clipboard history via wofi *(confirmed 2026-02-21)*
- [x] **`polkit-gnome`** (v1.3.0) — In packages (`desktop_hyprland` module) *(confirmed 2026-02-21)*
- [x] **`gnome-keyring`** (v1.3.0) — In packages (`system_utilities` module) *(confirmed 2026-02-21)*
- [x] **`uwsm`** (v1.4.0) — In packages (`desktop_hyprland` module) *(confirmed 2026-02-21)*
- [x] **`qt5-wayland`** (v2.1.0) — In packages (`system_utilities` module) *(confirmed 2026-02-21)*
- [x] **`ttf-firacode-nerd`** (v1.8.0) — In packages (`fonts` module) *(confirmed 2026-02-21)*
- [x] **`voxtype-bin`** (v3.3.0) — In packages; `Super+T` dictation implemented in `voice.conf` *(confirmed 2026-02-21)*
- [x] **`swaync` notification daemon** (v1.2.0) — In packages; `Super+Shift+N` notification panel *(confirmed 2026-02-21)*
- [x] **`docker-buildx`** (v1.5.0) — In packages (`development_core` module) *(confirmed 2026-02-21)*
- [x] **`usage` package** (v3.2.0) — In packages (`terminal_tools` module) *(confirmed 2026-02-21)*
- [x] **`btop` vim keybindings** (v3.1.0) — Noted; btop in packages, config managed separately *(confirmed 2026-02-21)*
- [x] **`localsend`** (v3.0.0) — In packages (`desktop_gui_apps` module) *(confirmed 2026-02-21)*
- [x] **`tailscale`** (v1.13.0) — In packages (`network` module) *(confirmed 2026-02-21)*
- [x] **hyprland-guiutils package rename** (v3.1.7) — Added `hyprland-guiutils` to `desktop_hyprland` module *(done 2026-02-21)*
- [x] **BlueTUI as Bluetooth backend** (v3.2.0) — Evaluated; kept `blueman` for GUI, added `bluetui` for TUI *(done 2026-02-21)*
- [x] **`ffmpegthumbnailer` for video thumbnails** (v1.2.0) — Added to `system_utilities` module *(done 2026-02-21)*
- [x] **`nodejs` package for tree-sitter** (v3.1.0) — Already managed via mise *(confirmed 2026-02-21)*
- [x] **VSCode auto-update disable** (v3.1.0) — Added `"update.mode": "none"` to settings.json *(done 2026-02-21)*
- [x] **`wl-clip-persist` sensitive data exclusion** (v1.3.1) — `clipboard-store` wrapper filters by window class/title *(done 2026-02-21)*
- [x] **`fontconfig/fonts.conf` defaults** (v1.4.0) — Added `fonts.conf` with FiraCode Nerd, Fira Sans, Liberation Serif *(done 2026-02-21)*
- [x] **`hyprpicker` for HDR screenshots** (v3.4.0) — Already in packages.yaml *(confirmed 2026-03-05)*
- [x] **Numlock enabled by default** (v2.1.1) — Added `numlock_by_default = true` to `input.conf` *(done 2026-03-05)*
- [x] **Cross-monitor workspace move** (v3.2.0) — `SUPER+SHIFT+ALT+Left/Right` added to `workspace-management.conf` *(done 2026-03-05)*
- [x] **WiFi quick-control `Super+Ctrl+W`** (v3.3.0) — Added `ghostty -e nmtui` binding to `desktop-utilities.conf` *(done 2026-03-05)*
- [x] **Docker socket activation** (v3.4.0) — Switched to `docker.socket` in `configure_system_services.sh.tmpl` *(done 2026-03-05)*
- [x] **Screen recording with audio** (v2.1.1) — `ALT+SHIFT+Print` and `CTRL+ALT+SHIFT+Print` added to `screenshots.conf` *(done 2026-03-05)*
- [x] **`eff` + `ff` aliases** (v3.4.0) — Added to `aliases.zsh` *(done 2026-03-05)*
- [x] **SSH port forwarding `fip`/`dip`/`lip`** (v3.4.0) — Added to `ssh-port-forwarding.zsh` (`dip` = disconnect, not dynamic) *(done 2026-03-05)*
- [x] **Tmux integration** (v3.4.0) — Package added, `tmux.conf` created, `t` alias + `tdl`/`tdlm`/`tsl` functions added; `Super+Alt+Return` binding skipped per bindings freeze *(done 2026-03-05)* — **superseded**: replaced by zellij
- [x] **Waybar idle-lock indicator** (v3.4.0) — `idle-indicator` script + Waybar module + CSS; DND already covered by `custom/swaync` *(done 2026-03-05)*
- [x] **`try` package** (v3.2.0) — Added to `terminal_tools` in packages.yaml *(done 2026-03-05)*

---

## Skipped / Out of Scope

- [SKIPPED] **Walker launcher** (v1.6.0+) — uses Wofi, not Walker
- [SKIPPED] **Aether theme creator** (v3.1.0) — Omarchy-specific app
- [SKIPPED] **Helium browser** (v3.0.2) — out of scope
- [SKIPPED] **Voxtype `Super+Ctrl+X`** (v3.3.0) — we use `Super+T` push-to-talk (different UX model)
- [SKIPPED] **SDDM keyring unlock** (v3.1.0) — uses sddm for login; our setup uses different login flow
- [SKIPPED] **SDDM styling** (v3.4.0, v3.7.0, v3.8.0) — not using SDDM
- [SKIPPED] **Windows VM** (v3.1.0+) — out of scope
- [SKIPPED] **Omarchy ISO/installer** (v2.0.0, v3.0.0, v3.5.1, v3.7.0, v3.8.0) — not applicable (includes encryption-free install, Colemak layout option)
- [SKIPPED] **OPR (Omarchy Package Repository)** (v2.0.0+) — uses standard Arch + AUR
- [SKIPPED] **Limine bootloader + Snapper rollback** (v2.0.0) — uses systemd-ukify + Timeshift (Btrfs)
- [SKIPPED] **Omarchy hooks system** (`~/.config/omarchy/hooks`) (v3.1.0, v3.8.0) — uses our own hooks at `~/.config/dotfiles/hooks/`; v3.8.0 adds `.d/` directory drop-in support and `omarchy-hook-install` — concept is covered by our existing hook system
- [SKIPPED] **`omarchy-launch-browser`/`omarchy-launch-webapp`** (v2.0.0) — Omarchy-specific launcher scripts
- [SKIPPED] **Chaotic-AUR** (v1.6.2) — already in packages.yaml; decision to keep or remove is independent
- [SKIPPED] **Dictation `Super+Ctrl+X`** (v3.3.0) — uses `Super+T` push-to-talk already
- [SKIPPED] **`omarchy-menu` / Walker menu system** (v1.11.0+) — Walker-specific; *workflow pattern* (system quick-action menu) is partially covered by our Wofi system-menu. v3.6.0 adds `Super+Ctrl+H` hardware toggles menu — concept covered by our `Super+Space` menu system
- [SKIPPED] **T1/T2 MacBook support** (v3.0.0) — not applicable hardware
- [SKIPPED] **Omarchy Chromium fork** (v2.0.0) — uses upstream Chromium
- [SKIPPED] **`~/.config/omarchy/extensions/menu.sh`** (v3.3.0, v3.4.0) — Omarchy-specific extension point
- [SKIPPED] **`colors.toml` generation (immediate adoption)** — monitor as the pattern stabilizes; tracked under P2 for future evaluation
- [SKIPPED] **Hyprland tiling group keybindings** (v3.1.0) — `Super+G` stays as gap toggle; group navigate already covered by `Super+Ctrl+H/L`; no new keybindings preference
- [SKIPPED] **`Super+L` layout toggle** (v3.4.1) — lock screen binding takes priority; layout toggle not needed
- [SKIPPED] **`Super+/` display resolution cycling** (v3.4.1) — keybinding help takes priority; resolution cycling not needed
- [SKIPPED] **Monitor focus cycling `Ctrl+Alt+Tab`** (v3.6.0) — no new keybindings preference; mouse sufficient for monitor focus
- [SKIPPED] **Window pinned floating overlay `Super+O`** (v3.1.5) — no new keybindings preference
- [SKIPPED] **Toggle menu `Super+Ctrl+O`** (v3.4.1, v3.7.0) — no new keybindings preference; v3.7.0 `Super+Ctrl+O` is now Direct Boot toggle (Limine-specific, not applicable)
- [SKIPPED] **Monitor scaling cycle keybinding** (v3.4.0, v3.6.0) — no new keybindings preference
- [SKIPPED] **`ga`/`gd` git worktree helpers** (v3.4.2) — user does not use git worktrees via CLI
- [SKIPPED] **`ff` alias kitty icat preview** (v3.5.0) — Kitty is backup terminal only; Ghostty doesn't support icat
- [SKIPPED] **Voxtype dictation features** — out of scope per permanent skip list
- [SKIPPED] **Asus/Slimbook/Tuxedo/Surface hardware drivers** (v3.4.0, v3.5.0) — hardware-specific, not applicable
- [SKIPPED] **NVIDIA GeForce Now installer** (v3.4.0) — out of scope
- [SKIPPED] **Alacritty as default terminal** (v3.4.0) — using Ghostty as primary terminal
- [SKIPPED] **Walker crash fix** (v3.4.0, v3.5.1) — not using Walker
- [SKIPPED] **`omarchy-drive-select` partition info** (v3.4.0) — Omarchy-specific script
- [SKIPPED] **Remove Preinstalls menu** (v3.4.0) — Omarchy-specific menu system
- [SKIPPED] **Audio soft mixer toggle** (v3.4.0) — Asus Zephyrus-specific
- [SKIPPED] **Favicon extraction for web apps** (v3.4.0) — Omarchy-specific web app creation
- [SKIPPED] **Scala installer** (v3.4.0) — not in current dev stack
- [SKIPPED] **NordVPN installer** (v3.4.0) — uses Tailscale, not NordVPN
- [SKIPPED] **Google DNS option** (v3.4.0) — DNS config handled separately
- [SKIPPED] **User theme override system** (v3.4.0) — Omarchy-specific theme mechanism
- [SKIPPED] **`omarchy-cmd-screenshot` geometry fix** (v3.4.0) — Omarchy-specific script
- [SKIPPED] **fcitx5 double auto-start fix** (v3.4.1, v3.5.1) — not using fcitx5
- [SKIPPED] **SDDM password field overflow** (v3.4.1) — not using SDDM
- [SKIPPED] **`OMARCHY_PATH` SSH environment export** (v3.4.1) — Omarchy-specific env var
- [SKIPPED] **`omarchy-launch-or-focus` jq fix** (v3.4.1) — Omarchy-specific script; concept tracked in P3
- [SKIPPED] **Screensaver `slidein` animation** (v3.4.1) — minor, Omarchy-specific default
- [SKIPPED] **Copilot key remapping via makima** (v3.4.2) — hardware-specific (Copilot key keyboards only); `makima-bin` not applicable; v3.5.1 removes makima entirely, Copilot key now native Hyprland
- [SKIPPED] **Tmux navigation keybinds** (v3.4.1) — using zellij, not tmux
- [SKIPPED] **`Alt+Shift+Arrow` tmux window swap** (v3.4.2) — using zellij, not tmux
- [SKIPPED] **Tmux automatic window renaming** (v3.4.2) — using zellij, not tmux
- [SKIPPED] **Tmux zoom indicator** (v3.4.2) — using zellij, not tmux
- [SKIPPED] **Tmux copy-mode indicator** (v3.5.0) — using zellij, not tmux
- [SKIPPED] **`Super+Shift+Return` browser shortcut** (v3.4.2) — we already have `Super+W` for browser; redundant binding
- [SKIPPED] **`plocate` AC-only indexing** (v3.4.2) — `plocate` not in our packages
- [SKIPPED] **Intel Panther Lake/Arc/PTL GPU fixes** (v3.4.2, v3.5.0, v3.5.1, v3.6.0, v3.7.0, v3.8.0) — hardware-specific, NVIDIA setup
- [SKIPPED] **`wayfreeze-git` migration cleanup** (v3.4.2) — `wayfreeze-git` still in our packages (intentional)
- [SKIPPED] **Limine bootloader cmdline / Direct Boot** (v3.4.2, v3.5.0, v3.5.1, v3.6.0, v3.7.0, v3.7.1) — not using Limine bootloader; v3.7.1 patch (stale `xe.enable_panel_replay` param) is also Limine-specific
- [SKIPPED] **LM Studio downgrade fix** (v3.4.2) — LM Studio not in our packages
- [SKIPPED] **wireless-regdb** (v2.1.1) — No 6GHz hardware detected
- [SKIPPED] **impala TUI** — Depends directly on `iwd` binary, incompatible with our NM+iwd backend setup
- [SKIPPED] **Hypridle timing tuning** — Our 5/10/15min is intentionally more relaxed than Omarchy's 2.5/5/5.5min
- [SKIPPED] **Intel thermald / intel-lpmd** (v3.5.0) — Intel-specific power management, NVIDIA setup
- [SKIPPED] **Intel media driver / VPL** (v3.5.0, v3.6.0) — Intel-specific hardware video acceleration
- [SKIPPED] **Dell XPS hardware fixes** (v3.5.0, v3.5.1, v3.8.0) — Dell-specific hardware (including haptic touchpad control)
- [SKIPPED] **ONCE installer** (v3.5.0) — `once-bin` is an Omarchy-specific service manager, not applicable
- [SKIPPED] **npx lazy-install stubs** (v3.5.0, v3.5.1, v3.8.0) — Omarchy-specific approach; we use mise for Node tool management
- [SKIPPED] **`omarchy-sudo-passwordless`** (v3.5.0, v3.7.0) — security-sensitive; passwordless sudo toggle is a footgun we don't want
- [SKIPPED] **Battery-low hook** (v3.5.0) — Omarchy hooks system; we use our own hook system at `~/.config/dotfiles/hooks/`; *concept* (run script on low battery) could be added as a user hook but not urgent
- [SKIPPED] **`omarchy-setup-makima`** (v3.5.0) — makima removed entirely in v3.5.1
- [SKIPPED] **Logitech MX Keys binding examples** (v3.5.1) — hardware-specific commented examples; not applicable to our hardware
- [SKIPPED] **Dell XPS mic mute LED sync** (v3.5.1) — Dell XPS-specific hardware script
- [SKIPPED] **ThinkPad mic mute LED sync** (v3.6.0) — ThinkPad-specific hardware script; v3.7.0 unifies into `omarchy-audio-input-mute` but hardware LED sync is still device-specific
- [SKIPPED] **Resume performance boost** (v3.5.1) — Intel Panther Lake-specific; removed in v3.6.0 as workaround no longer needed
- [SKIPPED] **Internal monitor recovery service** (v3.6.0) — `omarchy-recover-internal-monitor.service` + `omarchy-hw-recover-internal-monitor`; *concept* is worth noting but requires the persistent toggle system first and is heavy machinery for desktop use
- [SKIPPED] **Monitor watch daemon** (v3.6.0) — `omarchy-hyprland-monitor-watch` via socat; desktop-focused (single monitor), not needed
- [SKIPPED] **Vantablack theme** (v3.6.0) — not a theme variant we use
- [SKIPPED] **Lumon Industries / Retro 82 themes** (v3.5.0) — not theme variants we use
- [SKIPPED] **Snapper /home snapshots drop + btrfs quota disable** (v3.6.0) — we use Timeshift, not Snapper; btrfs quotas and snapshot strategy managed separately
- [SKIPPED] **Voxtype GPU acceleration via Vulkan** (v3.5.0, v3.6.0) — Omarchy-specific setup script; our voxtype is configured via `run_once_after_setup_optional_services.sh.tmpl`
- [SKIPPED] **Gaming installers** (v3.7.0) — Steam, RetroArch, Lutris, Heroic, Moonlight, Xbox Cloud, Xbox Controllers — gaming suite out of scope; individual games/launchers managed separately if needed
- [SKIPPED] **`cliamp` TUI music player** (v3.7.0) — not in our workflow; using other media tools
- [SKIPPED] **`ghui` GitHub TUI** (v3.7.0) — using `gh` CLI + other GitHub tooling
- [SKIPPED] **Plymouth unlock theming** (v3.7.0) — `omarchy-plymouth-*` scripts; we use Timeshift + systemd-ukify, not Limine/Plymouth in the same way
- [SKIPPED] **Omarchy logo backgrounds** (v3.7.0) — Omarchy-branded assets; we use our own theme backgrounds
- [SKIPPED] **Apple display brightness control** (v3.7.0) — Apple external display-specific; not applicable to current hardware
- [SKIPPED] **Helix editor theming** (v3.7.0, v3.8.0) — `omarchy-install-helix` and improved contrast; not using Helix editor
- [SKIPPED] **gum theming** (v3.7.0) — Omarchy-specific gum theme integration; we use gum but without Omarchy theme coupling
- [SKIPPED] **Brave Origin browser theming** (v3.7.0) — Brave Origin not in our browser setup
- [SKIPPED] **Monitor mirroring keybind `Super+Ctrl+Alt+Del`** (v3.7.0) — `Super+Ctrl+Alt+Del` is a hostile keybind; monitor mirroring handled via other means
- [SKIPPED] **Voxtype push-to-talk `F5` binding** (v3.7.0) — we use `Super+T`; Tier 1 permanent skip
- [SKIPPED] **ASUS hardware support** (v3.7.0, v3.8.0) — ASUS Panther Lake / Zenbook / ROG-specific; not applicable hardware
- [SKIPPED] **`omarchy-default-browser`/`terminal`/`editor` CLIs** (v3.8.0) — Omarchy-specific defaults system; we manage defaults via `globals.yaml` in chezmoi data
- [SKIPPED] **`omarchy-install-browser`/`omarchy-remove-browser`** (v3.8.0) — Omarchy-specific browser installer; we manage browsers via `packages.yaml`
- [SKIPPED] **Foot terminal** (v3.8.0) — using Ghostty (primary) and Kitty (baseline); no need for a third terminal
- [SKIPPED] **Zed editor theming** (v3.8.0) — `omazed` package; not using Zed editor
- [SKIPPED] **ASCII screensaver/about screen** (v3.8.0) — `omarchy-branding-screensaver`, `omarchy-branding-about`; Omarchy-specific branding tool
- [SKIPPED] **Voxtype post-boot install offer** (v3.8.0) — Omarchy hooks + post-boot notification; voxtype already installed; Tier 1 permanent skip for dictation workflow
- [SKIPPED] **`pi` coding agent light/dark sync** (v3.8.0) — not using pi agent
- [SKIPPED] **Chromium VAAPI flags migration** (v3.8.0) — VAAPI flags not in our Chromium config; Intel-specific issue; not applicable
- [SKIPPED] **`omarchy-notification-send` helper** (v3.8.0) — Omarchy-internal notification wrapper; we use `notify-send` directly
- [SKIPPED] **`omarchy-setup-security-fido2/fingerprint` refactor** (v3.8.0) — Omarchy-specific security setup scripts; we handle FIDO2/fingerprint separately
- [SKIPPED] **Lenovo Yoga Pro bass speaker fix** (v3.8.0) — hardware-specific; not applicable

---

## Version Coverage

| Version | Research doc | Reviewed |
|---------|-------------|---------|
| v1.2.0 | `_research/omarchy/OMARCHY_v1.2.0.md` | 2026-02-21 |
| v1.3.0 | `_research/omarchy/OMARCHY_v1.3.0.md` | 2026-02-21 |
| v1.3.1 | `_research/omarchy/OMARCHY_v1.3.1.md` | 2026-02-21 |
| v1.3.2 | `_research/omarchy/OMARCHY_v1.3.2.md` | 2026-02-21 |
| v1.4.0 | `_research/omarchy/OMARCHY_v1.4.0.md` | 2026-02-21 |
| v1.4.1 | `_research/omarchy/OMARCHY_v1.4.1.md` | 2026-02-21 |
| v1.5.0 | `_research/omarchy/OMARCHY_v1.5.0.md` | 2026-02-21 |
| v1.5.1 | `_research/omarchy/OMARCHY_v1.5.1.md` | 2026-02-21 |
| v1.5.2 | `_research/omarchy/OMARCHY_v1.5.2.md` | 2026-02-21 |
| v1.6.0 | `_research/omarchy/OMARCHY_v1.6.0.md` | 2026-02-21 |
| v1.6.1 | `_research/omarchy/OMARCHY_v1.6.1.md` | 2026-02-21 |
| v1.6.2 | `_research/omarchy/OMARCHY_v1.6.2.md` | 2026-02-21 |
| v1.7.0 | `_research/omarchy/OMARCHY_v1.7.0.md` | 2026-02-21 |
| v1.8.0 | `_research/omarchy/OMARCHY_v1.8.0.md` | 2026-02-21 |
| v1.9.0 | `_research/omarchy/OMARCHY_v1.9.0.md` | 2026-02-21 |
| v1.10.0 | `_research/omarchy/OMARCHY_v1.10.0.md` | 2026-02-21 |
| v1.11.0 | `_research/omarchy/OMARCHY_v1.11.0.md` | 2026-02-21 |
| v1.12.0 | `_research/omarchy/OMARCHY_v1.12.0.md` | 2026-02-21 |
| v1.12.1 | `_research/omarchy/OMARCHY_v1.12.1.md` | 2026-02-21 |
| v1.13.0 | `_research/omarchy/OMARCHY_v1.13.0.md` | 2026-02-21 |
| v2.0.0 | `_research/omarchy/OMARCHY_v2.0.0.md` | 2026-02-21 |
| v2.0.1 | `_research/omarchy/OMARCHY_v2.0.1.md` | 2026-02-21 |
| v2.0.2 | `_research/omarchy/OMARCHY_v2.0.2.md` | 2026-02-21 |
| v2.0.3 | `_research/omarchy/OMARCHY_v2.0.3.md` | 2026-02-21 |
| v2.0.4 | `_research/omarchy/OMARCHY_v2.0.4.md` | 2026-02-21 |
| v2.0.5 | `_research/omarchy/OMARCHY_v2.0.5.md` | 2026-02-21 |
| v2.1.0 | `_research/omarchy/OMARCHY_v2.1.0.md` | 2026-02-21 |
| v2.1.1 | `_research/omarchy/OMARCHY_v2.1.1.md` | 2026-02-21 |
| v2.1.2 | `_research/omarchy/OMARCHY_v2.1.2.md` | 2026-02-21 |
| v3.0.0 | `_research/omarchy/OMARCHY_v3.0.0.md` | 2026-02-21 |
| v3.0.1 | `_research/omarchy/OMARCHY_v3.0.1.md` | 2026-02-21 |
| v3.0.2 | `_research/omarchy/OMARCHY_v3.0.2.md` | 2026-02-21 |
| v3.1.0 | `_research/omarchy/OMARCHY_v3.1.0.md` | 2026-02-21 |
| v3.1.1 | `_research/omarchy/OMARCHY_v3.1.1.md` | 2026-02-21 |
| v3.1.2 | `_research/omarchy/OMARCHY_v3.1.2.md` | 2026-02-21 |
| v3.1.3 | `_research/omarchy/OMARCHY_v3.1.3.md` | 2026-02-21 |
| v3.1.4 | `_research/omarchy/OMARCHY_v3.1.4.md` | 2026-02-21 |
| v3.1.5 | `_research/omarchy/OMARCHY_v3.1.5.md` | 2026-02-21 |
| v3.1.6 | `_research/omarchy/OMARCHY_v3.1.6.md` | 2026-02-21 |
| v3.1.7 | `_research/omarchy/OMARCHY_v3.1.7.md` | 2026-02-21 |
| v3.2.0 | `_research/omarchy/OMARCHY_v3.2.0.md` | 2026-02-21 |
| v3.2.1 | `_research/omarchy/OMARCHY_v3.2.1.md` | 2026-02-21 |
| v3.2.2 | `_research/omarchy/OMARCHY_v3.2.2.md` | 2026-02-21 |
| v3.2.3 | `_research/omarchy/OMARCHY_v3.2.3.md` | 2026-02-21 |
| v3.3.0 | `_research/omarchy/OMARCHY_v3.3.0.md` | 2026-02-21 |
| v3.3.1 | `_research/omarchy/OMARCHY_v3.3.1.md` | 2026-02-21 |
| v3.3.2 | `_research/omarchy/OMARCHY_v3.3.2.md` | 2026-02-21 |
| v3.3.3 | `_research/omarchy/OMARCHY_v3.3.3.md` | 2026-02-21 |
| v3.4.0 | `_research/omarchy/OMARCHY_v3.4.0.md` | 2026-03-05 |
| v3.4.1 | `_research/omarchy/OMARCHY_v3.4.1.md` | 2026-03-05 |
| v3.4.2 | `_research/omarchy/OMARCHY_v3.4.2.md` | 2026-03-12 |
| v3.5.0 | `_research/omarchy/OMARCHY_v3.5.0.md` | 2026-05-04 |
| v3.5.1 | `_research/omarchy/OMARCHY_v3.5.1.md` | 2026-05-04 |
| v3.6.0 | `_research/omarchy/OMARCHY_v3.6.0.md` | 2026-05-04 |
| v3.7.0 | `_research/omarchy/OMARCHY_v3.7.0.md` | 2026-05-13 |
| v3.7.1 | `_research/omarchy/OMARCHY_v3.7.1.md` | 2026-05-13 |
| v3.8.0 | `_research/omarchy/OMARCHY_v3.8.0.md` | 2026-05-13 |
