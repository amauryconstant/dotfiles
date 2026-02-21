# Omarchy Integration Backlog

Living actionable backlog. Updated by `/omarchy-changes`.
Last updated: 2026-02-21 (through v3.3.3).

**Legend**: `[ ]` pending · `[x]` done · `[SKIPPED]` out of scope

---

## P1 — High Priority

### hyprland-guiutils package rename (v3.1.7)
**What**: `hyprland-qtutils` was renamed upstream to `hyprland-guiutils`. Omarchy updated the reference; our setup should do the same to avoid package conflicts on next sync.
**Target files**: `.chezmoidata/packages.yaml`
**Note**: Neither name currently appears in packages.yaml. Verify whether `hyprland-qtutils` is installed on the system and if so, add `hyprland-guiutils` and add `hyprland-qtutils` to the `delete:` list.

- [x] Check if `hyprland-qtutils` is installed: `pacman -Q hyprland-qtutils` — not installed
- [x] Add `hyprland-guiutils` to `desktop_hyprland` module *(done 2026-02-21)*

---

### Hyprland tiling group keybindings (v3.1.0)
**What**: Full tiling group management: toggle group, move in/out, navigate within group with arrows/TAB. Omarchy uses `Super+G` for group toggle; we use it for gap toggle.
**Target files**: `private_dot_config/hypr/conf/bindings/focus-navigation.conf`, `private_dot_config/hypr/conf/bindings/desktop-utilities.conf`
**Conflict**: `SUPER+G` currently bound to gap toggle in `desktop-utilities.conf`. `SUPER+ALT+Arrows` currently bound to monitor focus in `workspace-management.conf`. `SUPER+ALT+TAB` currently bound to empty workspace. Must resolve before adding group bindings.

- [ ] Decide: remap gap toggle to a different binding (e.g., `SUPER+SHIFT+G`) or use a different group toggle key
- [ ] Decide: resolve `SUPER+ALT+Arrows` conflict (monitor focus vs group navigation) — consider `SUPER+CTRL+Arrows` for group navigation (currently used for window resize, also conflict)
- [ ] Add group toggle, move-out, and navigate bindings to `focus-navigation.conf`
- [ ] Add `Super+Alt+Mouse scroll` for group window cycling (v3.1.2, no conflict)

---

## P2 — Medium Priority

### Notification recall keybindings (v3.2.0, v3.2.2)
**What**: `Super+Alt+,` opens last notification; `Super+Shift+Alt+,` restores last dismissed notification.
**Target files**: `private_dot_config/hypr/conf/bindings/system-control.conf` or `desktop-utilities.conf`
**Conflict**: None detected. `Super+Shift+N` (notification panel) is the only existing notification binding.

- [ ] Add `bindd = SUPER ALT, comma, Open last notification, exec, swaync-client --activate-last` to `system-control.conf`
- [ ] Add `bindd = SUPER SHIFT ALT, comma, Restore dismissed notification, exec, swaync-client --activate-last --close-last` to `system-control.conf`
- [ ] Verify exact `swaync-client` flags for these actions

---

### Cross-monitor workspace move (v3.2.0)
**What**: `Super+Shift+Alt+Left/Right` moves current workspace to adjacent monitor. Complements HyprDynamicMonitors.
**Target files**: `private_dot_config/hypr/conf/bindings/workspace-management.conf`
**Conflict**: `SUPER+SHIFT+Left/Right` bound to window movement (arrow keys). `SUPER+SHIFT+ALT+Left/Right` is free.

- [ ] Add `bindd = SUPER SHIFT ALT, left, Move workspace to left monitor, movecurrentworkspacetomonitor, l`
- [ ] Add `bindd = SUPER SHIFT ALT, right, Move workspace to right monitor, movecurrentworkspacetomonitor, r`

---

### WiFi quick-control binding (v3.3.0)
**What**: `Super+Ctrl+W` for Wi-Fi controls (nmtui or impala TUI). Completes the `Super+Ctrl+[letter]` pattern already used for btop (`+T`) and Bluetooth (`+B`).
**Target files**: `private_dot_config/hypr/conf/bindings/desktop-utilities.conf`
**Conflict**: None detected — `SUPER+CTRL+W` is currently free.

- [ ] Add `bindd = SUPER CTRL, W, WiFi settings, exec, ghostty -e nmtui` to `desktop-utilities.conf`
- [ ] Evaluate `impala` package as nmtui alternative (Omarchy uses it since v1.3.0)

---

### Window pinned floating overlay (v3.1.5)
**What**: `Super+O` pops focused window into a pinned floating overlay (always-on-top). Different from PiP (`Super+Shift+P`) — simpler, no resize.
**Target files**: `private_dot_config/hypr/conf/bindings/window-management.conf`
**Conflict**: `SUPER+O` is currently free.

- [ ] Review Omarchy's `omarchy-hyprland-window-pop` implementation for the dispatch used
- [ ] Add `bindd = SUPER, O, Pinned floating overlay, exec, <implementation>` to `window-management.conf`

---

### colors.toml theme generation pattern (v3.3.0, v3.3.1)
**What**: Single `colors.toml` (24 semantic color fields) generates all app configs via templates. Directly parallels our 24-variable semantic architecture. Could reduce per-theme manual maintenance (currently each theme has 13 separate config files).
**Target files**: `private_dot_config/themes/`
**Note**: Monitor as Omarchy's implementation stabilizes (v3.3.1 still fixing regressions in the template system). Not a direct copy — adapt the generation pattern to work with our chezmoi template system.

- [ ] Review final `colors.toml` format in Omarchy (post v3.3.1 stabilization)
- [ ] Prototype: extend `generate-theme-shell-colors.sh` to output a `colors.toml` alongside existing shell format
- [ ] Evaluate whether template-driven per-app generation would reduce maintenance burden vs current symlink approach

---

### BlueTUI as Bluetooth backend (v3.2.0)
**What**: TUI Bluetooth manager replacing `blueman-manager`. Consistent with btop/yazi/lazygit terminal-first philosophy. Already in packages.yaml partially (check).
**Target files**: `.chezmoidata/packages.yaml`, `private_dot_config/hypr/conf/bindings/desktop-utilities.conf`
**Note**: `blueman` is currently in `desktop_hyprland` module. `bluetui` not present.

- [x] Evaluate `bluetui` (AUR) vs `blueman-manager` — both installed, TUI and GUI available *(done 2026-02-21)*
- [x] Add `bluetui` to packages — kept `blueman` for GUI, added `bluetui` for TUI *(done 2026-02-21)*
- [x] No binding added — run directly via `ghostty -e bluetui` *(decided 2026-02-21)*

---

### Screen recording with audio keybindings (v2.1.1)
**What**: `Alt+Shift+Print` for region recording with audio; `Ctrl+Alt+Shift+Print` for full-screen with audio. We have screen recording but need to check if audio capture is wired in.
**Target files**: `private_dot_config/hypr/conf/bindings/screenshots.conf`
**Conflict**: Check existing `Alt+Print` binding — Omarchy uses this for webcam+screen since v3.1.0.

- [ ] Review current `screenshots.conf` for any `Alt+Print` variants
- [ ] Add audio recording variants if not present: `ALT SHIFT, Print` and `CTRL ALT SHIFT, Print`
- [ ] Verify `gpu-screen-recorder-git` supports audio capture (already in packages)

---

### Numlock enabled by default (v2.1.1)
**What**: `numlock_by_default = true` in Hyprland input config. Simple ergonomic improvement.
**Target files**: `private_dot_config/hypr/conf/input.conf`

- [ ] Add `numlock_by_default = true` to `input.conf` under the `input {` section
- [ ] Validate with `chezmoi diff`

---

### `ffmpegthumbnailer` for video thumbnails (v1.2.0)
**What**: Enables thumbnail generation for video files in file manager (Thunar/Dolphin). `tumbler` is already in packages and handles images; this adds video.
**Target files**: `.chezmoidata/packages.yaml`

- [x] Add `ffmpegthumbnailer` to `system_utilities` module *(done 2026-02-21)*
- [x] Verify `tumbler` picks it up automatically — works out of box with tumbler *(confirmed 2026-02-21)*

---

## P3 — Low Priority / Evaluate

### `nodejs` package for tree-sitter (v3.1.0)
**What**: Node.js added to support tree-sitter in LazyVim. May already be covered by `mise`.
**Target files**: `.chezmoidata/packages.yaml`

- [x] Verify: `mise which node` — already managed via mise *(confirmed 2026-02-21)*

---

### `try` command (v3.2.0)
**What**: Experiment namespacing tool by @tobi, organizes quick code attempts under `~/Work/tries`. Low overhead addition.
**Target files**: `.chezmoidata/packages.yaml`

- [ ] Evaluate: install `try` from AUR/OPR and assess utility in daily workflow
- [ ] If adopted: add to `terminal_tools` module

---

### VSCode auto-update disable (v3.1.0)
**What**: VSCode's built-in auto-update conflicts with pacman management. Disable in VSCode settings to prevent pacman conflicts on next upgrade.
**Target files**: VSCode settings (likely managed separately or not in chezmoi)

- [x] Check if VSCode settings are managed in chezmoi — yes, `Code - OSS/User/modify_settings.json` *(confirmed 2026-02-21)*
- [x] Add `"update.mode": "none"` to settings.json *(done 2026-02-21)*

---

### `wl-clip-persist` sensitive data exclusion (v1.3.1)
**What**: Clipboard persistence daemon should exclude content from password managers. We use `cliphist` not `wl-clip-persist`, but same principle applies.
**Target files**: Autostart config, `cliphist` invocation

- [x] Review `cliphist` invocation in autostart — uses wrapper script with window-class detection *(done 2026-02-21)*
- [x] Add window-class and title-based filtering for Bitwarden (Firefox), KeepassXC, etc. *(done 2026-02-21)*
- **Implementation**: `~/.local/lib/scripts/media/clipboard-store` wrapper filters by `hyprctl activewindow` class/title

---

### `fontconfig/fonts.conf` defaults (v1.4.0)
**What**: Ships `.config/fontconfig/fonts.conf` setting Liberation Sans/Serif and Cascadia Cove as system font fallbacks. Improves font consistency in GTK apps.
**Target files**: `private_dot_config/fontconfig/fonts.conf` (new file)

- [x] Check if `~/.config/fontconfig/fonts.conf` exists on system — did not exist *(confirmed 2026-02-21)*
- [x] Add `fonts.conf` with our font preferences: FiraCode Nerd (mono), Fira Sans (sans), Liberation Serif (serif) *(done 2026-02-21)*

---

### Sticky CWD when opening new terminal (v2.0.0)
**What**: New terminal windows inherit the current working directory from an existing terminal. Quality-of-life improvement.
**Target files**: Ghostty config or terminal keybinding exec command

- [ ] Investigate Ghostty's `--working-directory` flag or `HYPRLAND_INSTANCE_SIGNATURE`-based approach
- [ ] If feasible: update terminal launch binding in `applications.conf.tmpl`

---

### ALT+TAB window cycling (v1.7.0)
**What**: `Alt+Tab` cycles between windows on active workspace including floating. Currently not bound.
**Target files**: `private_dot_config/hypr/conf/bindings/focus-navigation.conf`
**Note**: May conflict with application-level Alt+Tab if Hyprland intercepts it globally.

- [ ] Evaluate whether global `Alt+Tab` intercept is desirable given application usage
- [ ] If yes: add `bindd = ALT, Tab, Cycle windows, cyclenext` and `bindd = ALT SHIFT, Tab, Cycle windows backward, cyclenext, prev`

---

### `wireless-regdb` for 6GHz Wi-Fi (v2.1.1)
**What**: Regulatory database enabling 6GHz band support. Only relevant if hardware supports 6GHz.
**Target files**: `.chezmoidata/packages.yaml`

- [ ] Check hardware: `iw list | grep -i 6ghz` or `iw phy | grep 6000`
- [ ] If 6GHz hardware present: add `wireless-regdb` to `network` module

---

### Screensaver (hypridle/hyprlock) tuning (v1.10.0)
**What**: Omarchy idle timeout settled at 2.5 minutes. Battery notification persistence at 30 seconds. Check our hypridle config against these values.
**Target files**: `private_dot_config/hypridle.conf` or equivalent

- [ ] Review hypridle timeout values in our config
- [ ] Review battery notification duration in dunst/swaync config
- [ ] Align with Omarchy's tested values if different

---

### Impala TUI for Wi-Fi (v1.3.0)
**What**: TUI for Wi-Fi network selection. More ergonomic than nmtui for switching networks.
**Target files**: `.chezmoidata/packages.yaml`, WiFi binding exec

- [ ] Evaluate `impala` (AUR) — check if it supports NetworkManager backend (we use NM, not iwd directly)
- [ ] If compatible: add to packages and use as default Wi-Fi TUI

---

## Completed

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

---

## Skipped / Out of Scope

- [SKIPPED] **Walker launcher** (v1.6.0+) — uses Wofi, not Walker
- [SKIPPED] **`omarchy-*` scripts** — not applicable to chezmoi setup
- [SKIPPED] **Aether theme creator** (v3.1.0) — Omarchy-specific app
- [SKIPPED] **Helium browser** (v3.0.2) — out of scope
- [SKIPPED] **Voxtype `Super+Ctrl+X`** (v3.3.0) — we use `Super+T` push-to-talk (different UX model)
- [SKIPPED] **SDDM keyring unlock** (v3.1.0) — uses sddm for login; our setup uses different login flow
- [SKIPPED] **Windows VM** (v3.1.0+) — out of scope
- [SKIPPED] **Omarchy ISO/installer** (v2.0.0, v3.0.0) — not applicable
- [SKIPPED] **OPR (Omarchy Package Repository)** (v2.0.0+) — uses standard Arch + AUR
- [SKIPPED] **Limine bootloader + Snapper rollback** (v2.0.0) — uses systemd-ukify + Timeshift (Btrfs)
- [SKIPPED] **Omarchy hooks system** (`~/.config/omarchy/hooks`) (v3.1.0) — uses our own hooks at `~/.config/dotfiles/hooks/`
- [SKIPPED] **`omarchy-launch-browser`/`omarchy-launch-webapp`** (v2.0.0) — Omarchy-specific launcher scripts
- [SKIPPED] **Chaotic-AUR** (v1.6.2) — already in packages.yaml; decision to keep or remove is independent
- [SKIPPED] **Dictation `Super+Ctrl+X`** (v3.3.0) — uses `Super+T` push-to-talk already
- [SKIPPED] **`omarchy-menu` / Walker menu system** (v1.11.0+) — Omarchy-specific; uses Wofi-based system-menu
- [SKIPPED] **T1/T2 MacBook support** (v3.0.0) — not applicable hardware
- [SKIPPED] **Omarchy Chromium fork** (v2.0.0) — uses upstream Chromium
- [SKIPPED] **`~/.config/omarchy/extensions/menu.sh`** (v3.3.0) — Omarchy-specific extension point
- [SKIPPED] **`colors.toml` generation (immediate adoption)** — monitor as the pattern stabilizes; tracked under P2 for future evaluation

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
