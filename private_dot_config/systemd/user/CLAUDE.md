# Systemd User Services - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_config/systemd/user/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: User-level systemd services and timers
- **Key service**: wallpaper-cycle (dynamic wallpaper rotation)
- **Location**: `~/.config/systemd/user/`
- **Control**: `systemctl --user`

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

**Setup**: `.chezmoiscripts/run_once_after_006_setup_wallpaper_timer.sh.tmpl`

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

**File**: `.chezmoiscripts/run_once_after_006_setup_wallpaper_timer.sh.tmpl`

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

## Integration Points

- **Wallust**: `~/.config/wallust/` (color extraction)
- **Scripts**: `~/.local/lib/scripts/media/` (random-wallpaper.sh, set-wallpaper.sh)
- **Wallpapers**: `~/Pictures/wallpapers/` (image source)
- **SWWW**: Wallpaper daemon (smooth transitions)
- **Desktop**: Hyprland, Waybar, Wofi (color theming)
