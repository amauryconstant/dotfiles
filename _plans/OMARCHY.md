# Omarchy Integration Backlog

Living actionable backlog. Updated by `/omarchy-changes`.
Last updated: 2026-03-12 (through v3.4.2). Skipped items re-audited 2026-03-12.

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

### Toggle menu `Super+Ctrl+O` (v3.4.1)
**What**: Consolidates Window Gaps, 1-Window Ratio, and Display Scaling controls into a single wofi/menu invocation. Replaces having separate bindings for each.
**Target files**: `private_dot_config/hypr/conf/bindings/desktop-utilities.conf`, new menu script
**Conflict**: `SUPER+CTRL+O` is currently free.

- [ ] Design a wofi-based toggle menu covering gaps, window ratio, and display scaling
- [ ] Add `bindd = SUPER CTRL, O, Toggle menu, exec, <menu-script>` to `desktop-utilities.conf`

---

### `mise activate bash --shims` in uwsm/env (v3.4.2)
**What**: Omarchy changed `~/.config/uwsm/env` to use `mise activate bash --shims` instead of `mise activate bash`. The `--shims` flag ensures mise-managed tools are available in non-interactive Wayland session environments (e.g., for apps launched from Hyprland that don't spawn a login shell).
**Target files**: `private_dot_config/uwsm/env` (new managed file)

- [ ] Create `private_dot_config/uwsm/env` managed by chezmoi
- [ ] Set `mise activate bash --shims` (or equivalent for zsh) in that file
- [ ] Verify mise-managed tools (e.g., node, ruby) are visible to Wayland-launched apps

---

### LocalSend minimum window size rule (v3.4.2)
**What**: LocalSend opens with a small default window. A `windowrulev2` with `minsize` fixes this.
**Target files**: `private_dot_config/hypr/conf/windowrules.conf`

- [ ] Add window rule for LocalSend: `windowrulev2 = minsize 600 400, class:(localsend)` (verify correct class name with `hyprctl clients`)
- [ ] Confirm localsend class name: `hyprctl clients | grep -A5 -i localsend`

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

### Scratchpad slide-in animation (v3.4.2)
**What**: Omarchy adds `animation = specialWorkspace, 1, 4, easeOutQuint, slidevert` for a smooth vertical slide-in when toggling the scratchpad. We have this line commented out in `animations.conf` with a different curve (`default`).
**Target files**: `private_dot_config/hypr/conf/animations.conf`

- [ ] Uncomment/enable `animation = specialWorkspace, 1, 4, easeOutQuint, slidevert` (requires `bezier = easeOutQuint` to be defined, or use built-in)
- [ ] Test visually — scratchpad toggle should animate vertically

---

### Git worktree helpers `ga`/`gd` (v3.4.2)
**What**: Shell functions `ga <branch>` (create worktree at `../<repo>--<branch>`, run `mise trust`, cd in) and `gd` (remove current worktree + branch with `gum confirm`). Lightweight, no external deps beyond mise and gum (both already installed).
**Target files**: `private_dot_config/zsh/zshrc.d/` or `private_dot_local/lib/scripts/`

- [ ] Implement `ga` and `gd` as zsh functions (adapt from Omarchy's `default/bash/fns/worktrees` — switch bash-isms to zsh-compatible)
- [ ] Add to appropriate zsh functions file

---

### `hyprland-preview-share-picker` default page (v3.4.2)
**What**: Setting `default_page: outputs` in `~/.config/hyprland-preview-share-picker/config.yaml` makes screen share picker default to display outputs rather than individual windows. More natural for most sharing scenarios.
**Target files**: `private_dot_config/hyprland-preview-share-picker/config.yaml` (new managed file)

- [ ] Create `private_dot_config/hyprland-preview-share-picker/config.yaml` with `default_page: outputs`

---

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

### Screensaver (hypridle/hyprlock) tuning (v1.10.0)
**What**: Omarchy tested battery notification persistence at 30 seconds. Our idle timeout values are intentionally more relaxed (5/10/15min vs Omarchy's 2.5/5/5.5min), but the notification duration may differ.
**Target files**: dunst or swaync config
**Effort**: Low

- [ ] Review battery notification duration in dunst/swaync config — confirm 30s persistence or adjust to taste

### Fuller battery status notification (v3.4.2)
**What**: On-demand notification (`Super+Ctrl+Alt+B`) showing battery percentage, time remaining (charging or discharging), power draw in watts, and battery capacity in Wh. Three scripts in Omarchy: `omarchy-battery-status`, `omarchy-battery-remaining-time`, `omarchy-battery-capacity`.
**Target files**: `private_dot_local/bin/` or `private_dot_local/lib/scripts/desktop/`, `private_dot_config/hypr/conf/bindings/desktop-utilities.conf`
**Effort**: Low
**Adapt from**: `bin/omarchy-battery-status`, `bin/omarchy-battery-remaining-time`, `bin/omarchy-battery-capacity`

- [ ] Review Omarchy's three battery scripts for data sources (likely `upower -i $(upower -e | grep BAT)`)
- [ ] Implement as a single shell script using `upower` output
- [ ] Add `Super+Ctrl+Alt+B` binding to `desktop-utilities.conf`

---

### Screen recording notification thumbnail + open (v3.4.2)
**What**: After stopping a screen recording, generates a thumbnail via `ffmpeg` and sends a desktop notification. Pressing `Super+Alt+,` (or clicking the notification action) opens the video in `mpv`. Wraps the existing `gpu-screen-recorder-git` workflow.
**Target files**: `private_dot_local/bin/` (new wrapper script), `private_dot_config/hypr/conf/bindings/screenshots.conf`
**Effort**: Medium
**Adapt from**: `bin/omarchy-cmd-screenrecord`

- [ ] Review Omarchy's `omarchy-cmd-screenrecord` for thumbnail generation approach (`ffmpeg -ss 0 -vframes 1`)
- [ ] Implement wrapper: start/stop recording, extract thumbnail frame, send `notify-send` with open action
- [ ] Update screen recording binding in `screenshots.conf` to use new wrapper
- [ ] Add `Super+Alt+,` open-last-recording binding

---

### Tmux navigation keybinds (v3.4.1)
**What**: `Alt+Left/Right` moves between tmux windows; `Alt+Up/Down` moves between tmux sessions. Tmux is installed and configured.
**Target files**: `private_dot_config/tmux/tmux.conf` (or equivalent managed path)
**Effort**: Low

- [ ] Add `bind -n M-Left previous-window` / `bind -n M-Right next-window` to tmux config
- [ ] Add `bind -n M-Up switch-client -p` / `bind -n M-Down switch-client -n` for session navigation
- [ ] Verify no conflict with zsh/terminal Alt+Arrow keybinds

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
- [x] **`eff` + `ff` aliases** (v3.4.0) — Added to `aliases.zsh` *(done 2026-03-05)*
- [x] **SSH port forwarding `fip`/`dip`/`lip`** (v3.4.0) — Added to `ssh-port-forwarding.zsh` (`dip` = disconnect, not dynamic) *(done 2026-03-05)*
- [x] **Tmux integration** (v3.4.0) — Package added, `tmux.conf` created, `t` alias + `tdl`/`tdlm`/`tsl` functions added; `Super+Alt+Return` binding skipped per bindings freeze *(done 2026-03-05)*
- [x] **Waybar idle-lock indicator** (v3.4.0) — `idle-indicator` script + Waybar module + CSS; DND already covered by `custom/swaync` *(done 2026-03-05)*
- [x] **`try` package** (v3.2.0) — Added to `terminal_tools` in packages.yaml *(done 2026-03-05)*

---

## Skipped / Out of Scope

- [SKIPPED] **Walker launcher** (v1.6.0+) — uses Wofi, not Walker
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
- [SKIPPED] **`omarchy-menu` / Walker menu system** (v1.11.0+) — Walker-specific; *workflow pattern* (system quick-action menu) is partially covered by our Wofi system-menu
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
- [SKIPPED] **`omarchy-launch-or-focus` jq fix** (v3.4.1) — Omarchy-specific script; concept tracked in P3
- [SKIPPED] **Screensaver `slidein` animation** (v3.4.1) — minor, Omarchy-specific default
- [SKIPPED] **Copilot key remapping via makima** (v3.4.2) — hardware-specific (Copilot key keyboards only); `makima-bin` not applicable to our hardware
- [SKIPPED] **`Alt+Shift+Arrow` tmux window swap** (v3.4.2) — using zellij, not tmux
- [SKIPPED] **Tmux automatic window renaming** (v3.4.2) — using zellij, not tmux
- [SKIPPED] **Tmux zoom indicator** (v3.4.2) — using zellij, not tmux
- [SKIPPED] **`Super+Shift+Return` browser shortcut** (v3.4.2) — we already have `Super+W` for browser; redundant binding
- [SKIPPED] **`plocate` AC-only indexing** (v3.4.2) — `plocate` not in our packages
- [SKIPPED] **Intel Panther Lake/Arc GPU fixes** (v3.4.2) — hardware-specific, NVIDIA setup
- [SKIPPED] **`wayfreeze-git` migration cleanup** (v3.4.2) — `wayfreeze-git` still in our packages (intentional)
- [SKIPPED] **Limine cmdline spacing fixes** (v3.4.2) — not using Limine bootloader
- [SKIPPED] **LM Studio downgrade fix** (v3.4.2) — LM Studio not in our packages
- [SKIPPED] **wireless-regdb** (v2.1.1) — No 6GHz hardware detected
- [SKIPPED] **impala TUI** — Depends directly on `iwd` binary, incompatible with our NM+iwd backend setup
- [SKIPPED] **Hypridle timing tuning** — Our 5/10/15min is intentionally more relaxed than Omarchy's 2.5/5/5.5min

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
