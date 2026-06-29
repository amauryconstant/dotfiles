# Media Scripts - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/media/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **UI pattern**: screenshot uses notify-send; wallpaper templates use log templates; clipboard-store is silent

## Scripts

| Script | Purpose | UI | Notes |
|--------|---------|-----|-------|
| `screenshot` | Multi-mode capture with Satty annotation | notify-send | 4 modes |
| `random-wallpaper.tmpl` | Random wallpaper from theme collection | log templates | systemd timer |
| `set-wallpaper.tmpl` | Set specific wallpaper via swww | log templates | triggers hook |
| `clipboard-store` | Filter clipboard before storing in cliphist | silent | security filter |
| `organize-wallpapers-by-color` | Sort wallpapers by color match to themes | gum-ui | **one-time use** |

## screenshot

4 modes via `screenshot [mode] [output]`:

| Mode | Behavior |
|------|---------|
| `smart` (default) | Selection with auto-snap: if selection <20px, snaps to window at cursor |
| `region` | Free-form slurp selection |
| `windows` | Snap to window boundaries (`slurp -r`) |
| `fullscreen` | Active monitor only (no selection) |

**Tools**: wayfreeze (screen freeze), grim (capture), slurp (selection), satty (annotation editor)
**Output**: `~/Pictures/screenshot-YYYY-MM-DD_HH-MM-SS.png` (XDG_PICTURES_DIR)

**Keybindings**: See `hypr/conf/bindings/screenshots.conf`

## random-wallpaper.tmpl + set-wallpaper.tmpl

Both are chezmoi templates (use `{{ includeTemplate "log_*" }}` for output, not notify-send).

**set-wallpaper triggers hook**: `hook-runner wallpaper-change "$wallpaper_path"` after setting.

**swww must be running**: Daemon started by `hypr/conf/autostart.conf`. Both scripts require swww active.

**random-wallpaper** has lock file protection (`$XDG_RUNTIME_DIR/random-wallpaper.lock`) to prevent concurrent runs from systemd timer.

## clipboard-store

Silent filter script piped to `cliphist store`. Drops clipboard content from:
- Password manager windows (Bitwarden, KeePassXC, 1Password, etc.)
- Browser windows on auth/login pages
- Terminal sessions with sensitive patterns

**Integration**: Called from `~/.config/hypr/conf/autostart.conf` via `wl-paste --watch clipboard-store | cliphist store`.

## organize-wallpapers-by-color

⚠️ **One-time use** — wallpapers are already sorted by color and committed to the repo. Do NOT re-run unless adding new wallpapers to `~/.config/wallpapers/`.

Scores wallpapers by 4-signal color similarity to each theme using ImageMagick + Python Delta E (LAB color space). Moves wallpapers into `~/.config/wallpapers/{theme}/` subdirectories.

## Integration Points

- **Systemd timer**: `wallpaper-cycle.{service,timer}` calls `random-wallpaper`
- **swww**: Required for wallpaper transitions (smooth fade)
- **cliphist**: `clipboard-store` filters before cliphist stores
- **Hook system**: `set-wallpaper` triggers `wallpaper-change` hook
- **Hyprland bindings**: `screenshots.conf` maps screenshot modes to keys
