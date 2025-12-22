# Desktop Scripts - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/desktop/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Hyprland desktop utilities
- **Count**: 20 scripts
- **UI Pattern**: notify-send for user feedback (keybinding-triggered)
- **Integration**: Hyprland bindings, theme system

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
- Theme files: `~/.config/themes/{variant}/firefox-userChrome.css` (8 variants)
- Script creates symlink: `~/.mozilla/firefox/{profile}/chrome/userChrome.css` → `~/.config/themes/current/firefox-userChrome.css`
- Firefox restart required to see theme changes
- All 8 theme CSS files exist (Catppuccin, Rose Pine, Gruvbox, Solarized)

**CSS Structure** (per theme ~30 lines):
- 24 semantic CSS variables (--bg-primary, --fg-primary, --accent-primary, etc.)
- Styles: Tab bar, URL bar, navigation bar, sidebar

---

### VSCode Theme Integration

**Script**: `theme-apply-vscode.sh`
**Method**: Direct JSON settings modification
**Status**: ✅ Script working, extensions installed via extensions.yaml

**Requirements**:
- VSCode theme extensions (automatic via `.chezmoidata/extensions.yaml`)
- Extensions: catppuccin.catppuccin-vsc, mvllow.rose-pine, jdinhlife.gruvbox, ginfuru.ginfuru-better-solarized-dark-theme

**How it works**:
- Script updates `~/.config/Code/User/settings.json`
- Modifies `workbench.colorTheme` property via jaq (JSON processor)
- Theme mapping:
  - catppuccin-latte → "Catppuccin Latte"
  - catppuccin-mocha → "Catppuccin Mocha"
  - rose-pine-dawn → "Rosé Pine Dawn"
  - rose-pine-moon → "Rosé Pine Moon"
  - gruvbox-light → "Gruvbox Light Hard"
  - gruvbox-dark → "Gruvbox Dark Hard"
  - solarized-light → "Solarized Light"
  - solarized-dark → "Solarized Dark"
- Changes apply immediately (no restart needed)

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

## Theme Switcher

**Script**: `theme-switcher.sh.tmpl`
**Integration**: Central orchestrator

**Execution flow**:
1. Updates `~/.config/themes/current` symlink
2. Reloads core apps (Hyprland, Waybar, Dunst, Ghostty)
3. Calls theme-apply scripts (VSCode, Firefox, Spotify)
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

**audio-switch.sh**: Audio device switching
**screenrecord.sh**: Screen recording
**system-settings.sh**: Launch system settings
**wlogout.sh**: Logout menu launcher

---

## UI Pattern

**All desktop scripts** use `notify-send` for user feedback (not gum-ui library).

**Rationale**: Keybinding-triggered background utilities, minimal overhead, native notifications.

**See**: `../CLAUDE.md` for UI pattern standards by category.
