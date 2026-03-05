# Omarchy Integration Backlog

Living actionable backlog. Updated by `/omarchy-changes`.
Last updated: 2026-03-05 (through v3.4.1).

**Legend**: `[ ]` pending · `[x]` done · `[SKIPPED]` out of scope

---

## P1 — High Priority

### Hyprland tiling group keybindings (v3.1.0)
**What**: Full tiling group management: toggle group, move in/out, navigate within group with arrows/TAB. Omarchy uses `Super+G` for group toggle; we use it for gap toggle.
**Target files**: `private_dot_config/hypr/conf/bindings/focus-navigation.conf`, `private_dot_config/hypr/conf/bindings/desktop-utilities.conf`
**Conflict**: `SUPER+G` currently bound to gap toggle in `desktop-utilities.conf`. `SUPER+ALT+Arrows` currently bound to monitor focus in `workspace-management.conf`. `SUPER+ALT+TAB` currently bound to empty workspace. Must resolve before adding group bindings.

- [ ] Decide: remap gap toggle to a different binding (e.g., `SUPER+SHIFT+G`) or use a different group toggle key
- [ ] Decide: resolve `SUPER+ALT+Arrows` conflict (monitor focus vs group navigation) — consider `SUPER+CTRL+Arrows` for group navigation (currently used for window resize, also conflict)
- [ ] Add group toggle, move-out, and navigate bindings to `focus-navigation.conf`
- [ ] Add `Super+Alt+Mouse scroll` for group window cycling (v3.1.2, no conflict)

---

### `Super+L` conflict — layout toggle vs lock screen (v3.4.1)
**What**: v3.4.1 adds `Super+L` to toggle between Hyprland's scrolling layout and dwindle. We already bind `Super+L` to lock screen (`hyprlock`). These conflict.
**Target files**: `private_dot_config/hypr/conf/bindings/system-control.conf`
**Conflict**: `SUPER+L` is our lock screen binding. Cannot add layout toggle without remapping one.

- [ ] Decide: remap lock screen to `SUPER+SHIFT+L` (or another free binding) and use `SUPER+L` for layout toggle — or skip layout toggle entirely
- [ ] If adopted: add `bindd = SUPER, L, Toggle scrolling/dwindle layout, exec, <dispatch>` to layout-relevant conf
- [ ] Update lock screen binding reference if remapped

---

### `Super+/` conflict — keybinding help vs display resolution cycling (v3.4.1)
**What**: v3.4.1 maps `Super+/` to cycle display resolutions. We bind `Super+/` to the keybinding cheatsheet script.
**Target files**: `private_dot_config/hypr/conf/bindings/system-control.conf`
**Conflict**: `SUPER+slash` is our keybinding help script.

- [ ] Decide: remap keybinding help to another key (e.g., `SUPER+F1`) and free `SUPER+/` for resolution cycling — or keep current and skip resolution cycling
- [ ] If resolution cycling adopted: implement or script the resolution cycling logic (Omarchy uses `omarchy-cmd-display-resolution`)

---

## P2 — Medium Priority

### Window pinned floating overlay (v3.1.5)
**What**: `Super+O` pops focused window into a pinned floating overlay (always-on-top). Different from PiP (`Super+Shift+P`) — simpler, no resize.
**Target files**: `private_dot_config/hypr/conf/bindings/window-management.conf`
**Conflict**: `SUPER+O` is currently free.

- [ ] Review Omarchy's `omarchy-hyprland-window-pop` implementation for the dispatch used
- [ ] Add `bindd = SUPER, O, Pinned floating overlay, exec, <implementation>` to `window-management.conf`

---

### Tmux integration (v3.4.0)
**What**: Tmux added with tailored config for aesthetics and ergonomics; `t` alias opens it. AI agent layouts: `tdl`, `tdlm`, `tsl` commands. Keybind `Super+Alt+Return` launches terminal in Tmux mode. `Alt+left/right` moves between tmux windows; `Alt+up/down` moves between sessions (v3.4.1).
**Target files**: `.chezmoidata/packages.yaml`, `private_dot_config/hypr/conf/bindings/applications.conf`, `private_dot_config/` (new tmux config)

- [ ] Add `tmux` to packages.yaml (e.g., `terminal_tools` module)
- [ ] Create `private_dot_config/tmux/` with tailored config (aesthetics, `Alt+arrows` nav)
- [ ] Add `t` alias to zsh aliases
- [ ] Add `Super+Alt+Return` binding to launch terminal in tmux mode
- [ ] Evaluate `tdl`/`tdlm`/`tsl` layout scripts for AI agent workflows

---

### Waybar idle-lock and notification-silencing icons (v3.4.0)
**What**: Two new Waybar status indicators: idle-lock state and notification-silencing (DND) state. Complements existing `Super+I` idle toggle.
**Target files**: `private_dot_config/waybar/config.tmpl`, `private_dot_config/waybar/style.css.tmpl`

- [ ] Review Omarchy's Waybar module implementation for these two indicators
- [ ] Add idle-lock status module to Waybar config
- [ ] Add notification-silencing (DND) status module to Waybar config
- [ ] Add corresponding CSS for both indicators

---

### SSH port forwarding shell functions (v3.4.0)
**What**: `fip` (forward IP port), `dip` (dynamic IP port), `lip` (local IP port) — convenience functions for web development port forwarding over SSH.
**Target files**: `private_dot_config/zsh/dot_zshrc.d/` (new functions file or additions to existing)

- [ ] Review Omarchy's implementation of `fip`/`dip`/`lip` for exact function signatures
- [ ] Add to zsh functions or aliases file

---

### `eff` command — fuzzy-find to editor (v3.4.0)
**What**: Opens fuzzy-find results directly in the configured editor. Similar to `fzf` + `$EDITOR` integration.
**Target files**: `private_dot_config/zsh/dot_zshrc.d/` or `private_dot_local/bin/`

- [ ] Review Omarchy's `eff` implementation
- [ ] Add to shell functions or as a local bin script

---

### Toggle menu `Super+Ctrl+O` (v3.4.1)
**What**: Consolidates Window Gaps, 1-Window Ratio, and Display Scaling controls into a single wofi/menu invocation. Replaces having separate bindings for each.
**Target files**: `private_dot_config/hypr/conf/bindings/desktop-utilities.conf`, new menu script
**Conflict**: `SUPER+CTRL+O` is currently free.

- [ ] Design a wofi-based toggle menu covering gaps, window ratio, and display scaling
- [ ] Add `bindd = SUPER CTRL, O, Toggle menu, exec, <menu-script>` to `desktop-utilities.conf`

---

### colors.toml theme generation pattern (v3.3.0, v3.3.1)
**What**: Single `colors.toml` (24 semantic color fields) generates all app configs via templates. Directly parallels our 24-variable semantic architecture. Could reduce per-theme manual maintenance (currently each theme has 13 separate config files).
**Target files**: `private_dot_config/themes/`
**Note**: Monitor as Omarchy's implementation stabilizes (v3.3.1 still fixing regressions in the template system). Not a direct copy — adapt the generation pattern to work with our chezmoi template system.

- [ ] Review final `colors.toml` format in Omarchy (post v3.3.1 stabilization)
- [ ] Prototype: extend `generate-theme-shell-colors.sh` to output a `colors.toml` alongside existing shell format
- [ ] Evaluate whether template-driven per-app generation would reduce maintenance burden vs current symlink approach

---

## P3 — Low Priority / Evaluate

### Monitor scaling cycle keybinding (v3.4.0)
**What**: `Super+Ctrl+Backspace` cycles through 1x, 1.6x, 2x, 3x monitor scaling. Useful for HiDPI workflows.
**Target files**: `private_dot_config/hypr/conf/bindings/desktop-utilities.conf`
**Conflict**: `SUPER+CTRL+Backspace` is currently free.

- [ ] Implement a monitor scaling cycle script (or use Omarchy's `omarchy-cmd-display-scaling` logic)
- [ ] Add binding to `desktop-utilities.conf`

---

### Zoom keybindings (v3.4.0)
**What**: `Super+Ctrl+Z` zooms in (repeatable); `Super+Ctrl+Alt+Z` zooms out. Uses Hyprland's cursor zoom feature.
**Target files**: `private_dot_config/hypr/conf/bindings/desktop-utilities.conf`
**Conflict**: Neither binding is currently in use.

- [ ] Add `bindd = SUPER CTRL, Z, Zoom in, exec, hyprctl keyword misc:cursor_zoom_factor <val>` (or the correct dispatch)
- [ ] Add `bindd = SUPER CTRL ALT, Z, Zoom out, exec, <inverse>`

---

### `nautilus-python` for "Open in Ghostty" (v3.4.0)
**What**: Adds a "Open in Ghostty" context menu entry in Nautilus. Quality-of-life for file manager users.
**Target files**: `.chezmoidata/packages.yaml`

- [ ] Add `nautilus-python` to packages.yaml (e.g., `desktop_gui_apps` module)
- [ ] Verify the extension is auto-loaded after package install

---

### Automatic power profile on AC plug/unplug (v3.4.0)
**What**: Power profile switches automatically based on AC state. We already have manual power profile switching in the menu-setup script.
**Target files**: Systemd udev rule or `~/.config/` trigger

- [ ] Review Omarchy's implementation (likely a udev rule or UPower hook)
- [ ] Evaluate whether to add automatic switching alongside the existing manual control

---

### `try` command (v3.2.0)
**What**: Experiment namespacing tool by @tobi, organizes quick code attempts under `~/Work/tries`. Low overhead addition.
**Target files**: `.chezmoidata/packages.yaml`

- [ ] Evaluate: install `try` from AUR/OPR and assess utility in daily workflow
- [ ] If adopted: add to `terminal_tools` module

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
- [SKIPPED] **Notification recall keybindings** (v3.2.0, v3.2.2) — `swaync-client` lacks `--activate-last`/`--close-last` flags in current version

---

## Skipped / Out of Scope

- [SKIPPED] **Walker launcher** (v1.6.0+) — uses Wofi, not Walker
- [SKIPPED] **`omarchy-*` scripts** — not applicable to chezmoi setup
- [SKIPPED] **Aether theme creator** (v3.1.0) — Omarchy-specific app
- [SKIPPED] **Helium browser** (v3.0.2) — out of scope
- [SKIPPED] **Voxtype `Super+Ctrl+X`** (v3.3.0) — we use `Super+T` push-to-talk (different UX model)
- [SKIPPED] **SDDM keyring unlock** (v3.1.0) — uses sddm for login; our setup uses different login flow
- [SKIPPED] **SDDM styling** (v3.4.0) — not using SDDM
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
- [SKIPPED] **`~/.config/omarchy/extensions/menu.sh`** (v3.3.0, v3.4.0) — Omarchy-specific extension point
- [SKIPPED] **`colors.toml` generation (immediate adoption)** — monitor as the pattern stabilizes; tracked under P2 for future evaluation
- [SKIPPED] **Voxtype dictation features** — out of scope per permanent skip list
- [SKIPPED] **Asus/Slimbook/Tuxedo/Surface hardware drivers** (v3.4.0) — hardware-specific, not applicable
- [SKIPPED] **NVIDIA GeForce Now installer** (v3.4.0) — out of scope
- [SKIPPED] **Alacritty as default terminal** (v3.4.0) — using Ghostty as primary terminal
- [SKIPPED] **Walker crash fix** (v3.4.0) — not using Walker
- [SKIPPED] **`omarchy-drive-select` partition info** (v3.4.0) — Omarchy-specific script
- [SKIPPED] **Remove Preinstalls menu** (v3.4.0) — Omarchy-specific menu system
- [SKIPPED] **Audio soft mixer toggle** (v3.4.0) — Asus Zephyrus-specific
- [SKIPPED] **Favicon extraction for web apps** (v3.4.0) — Omarchy-specific web app creation
- [SKIPPED] **Scala installer** (v3.4.0) — not in current dev stack
- [SKIPPED] **NordVPN installer** (v3.4.0) — uses Tailscale, not NordVPN
- [SKIPPED] **Google DNS option** (v3.4.0) — DNS config handled separately
- [SKIPPED] **User theme override system** (v3.4.0) — Omarchy-specific theme mechanism
- [SKIPPED] **`omarchy-cmd-screenshot` geometry fix** (v3.4.0) — Omarchy-specific script
- [SKIPPED] **fcitx5 double auto-start fix** (v3.4.1) — not using fcitx5
- [SKIPPED] **SDDM password field overflow** (v3.4.1) — not using SDDM
- [SKIPPED] **`OMARCHY_PATH` SSH environment export** (v3.4.1) — Omarchy-specific env var
- [SKIPPED] **`omarchy-launch-or-focus` jq fix** (v3.4.1) — Omarchy-specific script
- [SKIPPED] **Screensaver `slidein` animation** (v3.4.1) — minor, Omarchy-specific default

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
