# Themes - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/themes/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: Theme assets (wallpapers, icons, cursors)
- **Organization**: Category-based subdirectories
- **Wallpapers**: Source for wallust color extraction
- **Target**: `~/.config/themes/`

## Directory Structure

```
~/.config/themes/
├── wallpapers/         # Wallpaper images
│   ├── landscapes/
│   ├── abstract/
│   └── minimal/
├── icons/              # Icon themes
├── cursors/            # Cursor themes
└── fonts/              # Custom fonts
```

## Wallpaper Organization

**Source directory**: `~/Pictures/wallpapers/` (symlinked or moved)

**Categories** (examples):
- `landscapes/` - Nature, scenery
- `abstract/` - Abstract art
- `minimal/` - Minimal designs
- `dark/` - Dark themes
- `light/` - Light themes

**Format support**: JPG, PNG, WEBP

**Resolution**: Varied (wallust scales)

## Wallpaper System Integration

**Random selection**:
```bash
random-wallpaper
# Selects from ~/Pictures/wallpapers/**/*.{jpg,png,webp}
```

**Manual selection**:
```bash
set-wallpaper /path/to/wallpaper.jpg
```

**Color extraction**: wallust analyzes selected wallpaper

**Output**: 9 color templates for desktop components

## Icon Themes

**Location**: `themes/icons/`

**Standard structure**:
```
icons/
└── theme-name/
    ├── index.theme
    ├── scalable/
    └── symbolic/
```

**Application**: GTK/Qt apps

## Cursor Themes

**Location**: `themes/cursors/`

**Standard structure**:
```
cursors/
└── theme-name/
    ├── index.theme
    └── cursors/
```

**Application**: X11/Wayland cursors

## Font Organization

**Location**: `themes/fonts/`

**Categories**:
- `monospace/` - Terminal, code
- `sans-serif/` - UI, documents
- `serif/` - Documents
- `icon-fonts/` - Icon glyphs

**Format**: TTF, OTF

## Integration Points

- **Wallust**: `~/.config/wallust/` (color extraction)
- **Wallpaper scripts**: `~/.local/lib/scripts/media/` (random-wallpaper, set-wallpaper)
- **Systemd timer**: `~/.config/systemd/user/wallpaper-cycle.timer` (rotation)
- **GTK**: `~/.config/gtk-3.0/settings.ini` (icon theme)
- **Hyprland**: `~/.config/hypr/conf/environment.conf` (cursor theme)
