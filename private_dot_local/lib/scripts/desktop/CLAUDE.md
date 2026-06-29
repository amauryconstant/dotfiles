# Desktop Scripts - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/desktop/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Hyprland desktop utilities
- **UI Pattern**: notify-send for user feedback (keybinding-triggered)
- **Integration**: Hyprland bindings, theme system
- **Naming**: files are extensionless (`.sh` below is illustrative; actual scripts have no extension, e.g. `theme-apply-firefox`)

## Theme Application Scripts

### Firefox Theme Integration

**Script**: `theme-apply-firefox.sh`
**Method**: CSS symlink injection via userChrome.css
**Status**: ✅ Working

**Manual Requirement** (one-time setup):
1. Open Firefox
2. Navigate to `about:config`
3. Search: `toolkit.legacyUserProfileCustomizations.stylesheets`
4. Set to: `true`
5. Restart Firefox

**How it works**:
- Theme files: `~/.config/themes/{variant}/firefox-userChrome.css` (one per theme)
- Script creates symlink: `~/.mozilla/firefox/{profile}/chrome/userChrome.css` → `~/.config/themes/current/firefox-userChrome.css`
- Firefox restart required to see theme changes
- All theme CSS files exist (Catppuccin, Rose Pine, Gruvbox, Solarized)

**CSS Structure** (per theme ~30 lines):
- Semantic CSS variables (--bg-primary, --fg-primary, --accent-primary, etc.)
- Styles: Tab bar, URL bar, navigation bar, sidebar

---

### Spotify Theme Integration

**Script**: `theme-apply-spotify.sh`
**Method**: spicetify-cli configuration
**Status**: ✅ Fully automated (Flatpak support)

**Automated Setup**: Configured via `run_onchange_after_configure_spicetify.sh.tmpl`
- Detects Flatpak install location (system `/var/lib/flatpak` or user `~/.local/share/flatpak`)
- Sets `spotify_path` automatically
- Detects and sets `prefs_path` (checks both `~/.var/app/com.spotify.Client/config/spotify/prefs` and `~/.config/spotify/prefs`)
- Handles permissions (prompts for sudo if system Flatpak)
- **Installs spicetify marketplace** automatically (CustomApp for browsing themes/extensions)
- Enables marketplace in spicetify config
- Runs `spicetify backup apply` automatically
- Hash-triggered (re-runs if packages.yaml changes)

**Theme Installation** (via marketplace):
1. Open Spotify (marketplace will be in sidebar)
2. Click "Marketplace" tab
3. Browse and install themes:
   - Search for: catppuccin
   - Search for: Rosé-Pine
   - Search for: Gruvbox
   - Search for: Solarized
4. Themes auto-apply via `theme-switcher.sh`

**Troubleshooting**:
- If prefs not found: Run Spotify once to generate preferences file, then re-run `chezmoi apply`
- If permissions fail: Check sudo access for system Flatpak location (`/var/lib/flatpak`)
- After Spotify updates: Re-run `chezmoi apply` to trigger reconfiguration

**How it works**:
- Script reads current theme from `~/.config/themes/current` symlink
- Maps dotfiles theme to spicetify theme + color_scheme:
  - catppuccin-latte → theme: catppuccin, scheme: latte
  - catppuccin-mocha → theme: catppuccin, scheme: mocha
  - rose-pine-dawn → theme: Rosé-Pine, scheme: dawn
  - rose-pine-moon → theme: Rosé-Pine, scheme: moon
  - gruvbox-light → theme: Gruvbox, scheme: light
  - gruvbox-dark → theme: Gruvbox, scheme: dark
  - solarized-light → theme: Solarized, scheme: light
  - solarized-dark → theme: Solarized, scheme: dark
- Runs `spicetify config` + `spicetify apply`
- Changes apply immediately (no restart needed)

---

### opencode Theme Integration

**Script**: `theme-apply-opencode.sh`
**Method**: Custom JSON theme files with symlink management
**Status**: ✅ Fully integrated

**Requirements**:
- opencode installed via mise (v1.0.193+)
- Theme JSON files in each theme directory

**How it works**:
- Script reads current theme from `~/.config/themes/current` symlink
- Verifies theme has `opencode.json` file
- Creates symlink: `~/.config/opencode/themes/current.json` → theme's opencode.json
- Updates `opencode.jsonc` via jaq: Sets `"theme": "current"`
- Silent failure if opencode not installed

**Theme files**: `~/.config/themes/{variant}/opencode.json` (one per theme).

**JSON structure**:
- **defs**: semantic color variables (bg-primary, fg-primary, accent-*, etc.)
- **theme**: opencode properties mapped to those semantic variables
- Supports both light and dark variants via "light"/"dark" keys

**Reload behavior**:
- Theme applies to new opencode sessions only
- Running instances keep old theme (TUI limitation)
- User restarts opencode to see new theme

---

### claude-code CLI Theme Integration

**Script**: `theme-apply-claude-code.sh`
**Method**: Direct JSON config modification
**Status**: ✅ Fully integrated

**Requirements**:
- claude-code CLI installed (global npm package)
- `~/.claude.json` configuration file

**How it works**:
- Script reads current theme from `~/.config/themes/current` symlink
- Maps theme to light/dark mode
- Updates `~/.claude.json` via jaq: Sets `"theme": "light"` or `"theme": "dark"`
- Silent failure if claude-code not installed

**Theme mappings**:
- **Light themes** → `"theme": "light"`: catppuccin-latte, rose-pine-dawn, gruvbox-light, solarized-light
- **Dark themes** → `"theme": "dark"`: catppuccin-mocha, rose-pine-moon, gruvbox-dark, solarized-dark

**Reload behavior**:
- Theme applies to new claude-code sessions only
- Running instances keep old theme (CLI limitation)
- User restarts claude-code to see new theme

---

### Other theme-apply scripts

Same pattern (read `current` symlink → map → apply; silent skip if app absent):
- `theme-apply-gtk` — GTK theme/color-scheme
- `theme-apply-qt` — Qt (qt5ct/qt6ct)
- `theme-apply-neovim` — Neovim colorscheme
- `theme-apply-zellij` — Zellij theme (`~/.config/themes/{variant}/zellij.kdl`)

---

## Theme Switcher

**Script**: `theme-switcher.tmpl`
**Integration**: Central orchestrator

**Execution flow**:
1. Updates `~/.config/themes/current` symlink
2. Reloads core apps (Hyprland, Waybar, Swaync, Ghostty)
3. Calls theme-apply scripts (Firefox, Spotify, opencode, claude-code, gtk, qt, neovim, zellij)
4. Triggers `theme-change` user hook
5. Updates wallpaper randomly from theme collection
6. Sends desktop notification

**User commands**:
```bash
theme switch catppuccin-mocha    # Switch to specific theme
theme list                        # List all themes
theme current                     # Show active theme
theme-menu                        # Interactive menu (Wofi)
```

**Keybindings**:
- `Super+Shift+Y` - Toggle between two themes
- `Super+Shift+Ctrl+Space` - Theme menu

---

## Window Management

**launch-or-focus.sh**: Single-instance app launcher
- Focus if window exists, launch if not
- Integration: `Super+E` → dolphin
- Pattern: `launch-or-focus.sh dolphin` or `launch-or-focus.sh btop "ghostty -e btop"`

**keybindings.sh**: Keybinding reference (`Super+?`)

---

## Display & Monitors

**Scripts**: monitor-switch.sh, monitor-mirror.sh, monitor-*.sh
- Display configuration management
- All use `notify-send` for feedback
- Keybinding-triggered utilities

---

## Appearance & Style

**Waybar**: waybar-toggle.sh, waybar-style.sh
**Night light**: nightlight-toggle.sh, nightlight-config.sh
**Workspace gaps**: workspace-gaps-toggle.sh, workspace-gaps-reset.sh
**Idle management**: idle-toggle.sh

All use `notify-send` for user feedback.

---

## Other Utilities

**audio-switch**: Audio device switching
**battery-status**: Battery/power status output
**screenrecord**: Screen recording
**system-settings**: Launch system settings
**wlogout**: Logout menu launcher
**window-pop**: toggle a window to/from a floating "pop" state
**zoom-cursor**: cursor magnifier
**voice-meeting**: meeting voice helper
**immediate-lock**: lock screen immediately
**idle-indicator**, **idle-toggle**: idle/inhibit state + toggle
**recover-workspaces**: re-assign orphaned windows to workspaces

**Keyboard (Kanata)**: `kanata-layer`, `kanata-layer-toggle` — query/switch layers via the kanata daemon (laptop; see `systemd/user/CLAUDE.md`).

---

## Session Management

**Scripts**: `session-save`, `session-restore`, `session-prompt`, `hypr-session` (CLI wrapper)
**State**: `~/.local/state/dotfiles/hyprland-session-<slot>.json` (+ `hyprdrover` index)

**Save** (`session-save`): captures `hyprctl clients`, enriches each window with a
launch command, terminal CWD (`/proc/<pid>/cwd`), and monitor name. Launch command
resolution order: explicit class map → Flatpak app-ID → `/proc/<pid>/cmdline` argv[0]
(on PATH) → lowercased class. Browser classes are deduped to one window (the app
restores the rest). The full `hyprctl` object is kept, so `initialClass`/`initialTitle`
are persisted for matching.

**Restore** (`session-restore`): launches saved apps, then places each window via the
Hyprland `socket2` event stream (`nc -U`, openbsd-netcat) — correlating each
`openwindow` event to a pending slot (exact `initialTitle` match, else class FIFO by
workspace) and moving it immediately. `post_restore_workspace_fix()` is a **fallback**,
run only for windows the event stream didn't place (or when socket2 is unavailable);
it is pre-seeded with already-placed addresses so it never disturbs correct windows.

**Env vars**: `DOTFILES_SESSION_QUIET=1` (suppress notifications — used by the
autosave timer), `DOTFILES_SESSION_CORR_TIMEOUT` (socket2 correlation budget, default
8s), `DOTFILES_SESSION_LAUNCH_DELAY`, `DOTFILES_SESSION_SETTLE_DELAY`.

**Auto-save**: `session-autosave.timer` (15min) → `autosave` slot. See
`systemd/user/CLAUDE.md`. Config: `~/.config/dotfiles/session-{denylist,browsers,single-instance-apps}.conf`.

**Debug**: `journalctl --user -t hypr-session -f` (both scripts log richly via `logger`).

---

## UI Pattern

**All desktop scripts** use `notify-send` for user feedback (not gum-ui library).

**Rationale**: Keybinding-triggered background utilities, minimal overhead, native notifications.

**See**: `../CLAUDE.md` for UI pattern standards by category.
