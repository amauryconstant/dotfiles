# Systemd User Services - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/systemd/user/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: User-level systemd services and timers
- **Location**: `~/.config/systemd/user/`
- **Control**: `systemctl --user`
- **Setup**: `run_once_after_004_enable_user_timers.sh.tmpl`

## Services & Timers

| Unit | Type | Purpose | Setup Script |
|------|------|---------|-------------|
| `wallpaper-cycle.{service,timer}` | timer | Random wallpaper every 30min | after_004 |
| `system-health-check.{service,timer}` | timer | System health monitoring every 15min | after_004 |
| `home-backup.{service,timer}` | timer | Restic home backup daily at 9am | after_010 |
| `hyprdynamicmonitors.service` | service | Monitor profile manager daemon | before_008 |
| `hyprdynamicmonitors-prepare.service` | service | Pre-Hyprland monitor prep | before_008 |
| `hyprwhenthen.service` | service | Event-driven window automation | before_008 |
| `darkman.service` | service | Solar-based auto theme switching | after_006 |
| `wallpaper-cycle.service` | oneshot | Wallpaper rotation execution | after_004 |
| `voxtype.service.d/` | drop-in | Voxtype GPU config override | after_010 |
| `app-blueman@autostart.service.d/` | drop-in | Suppress blueman tray on desktop | static |
| `app-nm-applet@autostart.service.d/` | drop-in | Suppress nm-applet tray on desktop | static |

## Wallpaper Cycle Service

**Units**:
- `wallpaper-cycle.timer` - Timer (30 min intervals)
- `wallpaper-cycle.service` - Service execution

**Setup**: `.chezmoiscripts/run_once_after_006_setup_wallpaper_timer.sh.tmpl`

### Service Configuration

**Timer** (`wallpaper-cycle.timer`):
- **Interval**: 30 minutes with 2-minute random delay
- **Boot delay**: 5 minutes after boot
- **Purpose**: Prevents timing conflicts, distributes load

**Service** (`wallpaper-cycle.service`):
- **Type**: oneshot (completes and exits)
- **Command**: `/home/%u/.local/bin/random-wallpaper`
- **Restart**: on-failure with 30s backoff
- **Logging**: systemd journal

**Setup**: `.chezmoiscripts/run_once_after_004_enable_user_timers.sh.tmpl`

### Script Integration

**Script**: `~/.local/bin/random-wallpaper` → `~/.local/lib/scripts/media/random-wallpaper.sh`

**Lock file protection**:
```bash
LOCK_FILE="$XDG_RUNTIME_DIR/random-wallpaper.lock"

# Check for existing lock
if [ -f "$LOCK_FILE" ]; then
    # Cleanup stale locks (>2 minutes old)
    if [ $(($(date +%s) - $(stat -c %Y "$LOCK_FILE"))) -gt 120 ]; then
        rm "$LOCK_FILE"
    else
        exit 0  # Another instance running
    fi
fi

# Create lock
touch "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT
```

**Dependency checks**:
```bash
# Validate required tools
for cmd in swww wallust find shuf; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd not found" >&2
        exit 1
    fi
done
```

## Timer Management

**Enable timer**:
```bash
systemctl --user enable --now wallpaper-cycle.timer
```

**Disable timer**:
```bash
systemctl --user disable --now wallpaper-cycle.timer
```

**Status**:
```bash
systemctl --user status wallpaper-cycle.timer
systemctl --user status wallpaper-cycle.service
```

**List next run**:
```bash
systemctl --user list-timers wallpaper-cycle.timer
```

**Manual trigger**:
```bash
systemctl --user start wallpaper-cycle.service
```

## Service Logs

**View logs**:
```bash
journalctl --user -u wallpaper-cycle.service
```

**Follow logs**:
```bash
journalctl --user -u wallpaper-cycle.service -f
```

**Recent errors**:
```bash
journalctl --user -u wallpaper-cycle.service -p err -n 20
```

**Filter by date**:
```bash
journalctl --user -u wallpaper-cycle.service --since today
journalctl --user -u wallpaper-cycle.service --since "2024-01-01"
```

## Setup Script

**File**: `.chezmoiscripts/run_once_after_004_enable_user_timers.sh.tmpl`

**Actions**:
1. Copy units to `~/.config/systemd/user/`
2. Reload systemd daemon (`systemctl --user daemon-reload`)
3. Enable timer (`systemctl --user enable wallpaper-cycle.timer`)
4. Start timer (`systemctl --user start wallpaper-cycle.timer`)

**Validation**:
- Check units exist
- Verify service executable
- Test dependency availability

## Troubleshooting

**Timer issues**:
```bash
systemctl --user status wallpaper-cycle.timer
systemctl --user enable --now wallpaper-cycle.timer
```

**Service failures**:
```bash
journalctl --user -u wallpaper-cycle.service -n 50
which swww wallust find shuf
~/.local/bin/random-wallpaper
```

**Lock file**: Remove stale lock at `$XDG_RUNTIME_DIR/random-wallpaper.lock`

## Other Timers

**system-health-check** (every 15min):
```bash
systemctl --user status system-health-check.timer
journalctl --user -u system-health-check.service -n 20
```

**home-backup** (daily 9am):
```bash
systemctl --user status home-backup.timer
systemctl --user start home-backup.service   # Manual run
journalctl --user -u home-backup.service -n 20
```

## Autostart Drop-ins

`app-blueman@autostart.service.d/` and `app-nm-applet@autostart.service.d/` suppress tray icons on desktop chassis (`{{ if eq .chassisType "desktop" }}`). These override GNOME autostart services that Hyprland doesn't need.

## Integration Points

- **Wallust**: `~/.config/wallust/` (color extraction)
- **Scripts**: `~/.local/lib/scripts/media/` (random-wallpaper, set-wallpaper)
- **Wallpapers**: `~/Pictures/wallpapers/` (image source)
- **SWWW**: Wallpaper daemon (smooth transitions)
- **Desktop**: Hyprland, Waybar, Wofi (color theming)
- **Restic**: Home backup target (`~/.local/share/restic-home/`)
