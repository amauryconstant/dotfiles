# hyprwhenthen - Window Event Automation

## Purpose

Automatically respond to Hyprland events (title changes, focus changes, etc.) for dynamic window behavior.

## Quick Reference

- **Validate config**: `hyprwhenthen validate`
- **Debug mode**: `hyprwhenthen run --debug`
- **Logs**: `journalctl --user -u hyprwhenthen`

## Current Handlers

### OAuth Popups (auto-float and center)

**Matches**: "Sign In - Google Accounts", "Sign in - Google/Microsoft/GitHub"
**Action**: Float window, resize to 50% screen, center on screen

## Adding New Handlers

Edit `~/.config/hyprwhenthen/config.toml`:

```toml
[[handler]]
on = "EVENT_TYPE"              # windowtitlev2, openwindow, etc.
when = "REGEX_PATTERN"        # Match event data
then = "COMMAND_TO_RUN"       # $REGEX_GROUP_1 for captured groups
```

## Common Event Types

- `windowtitlev2` - Window title changes (dynamic popups)
- `openwindow` - New window opens
- `closewindow` - Window closes
- `activewindow` - Window focused
- `workspace` - Workspace switched
- `monitoradded` / `monitorremoved` - Monitor connection changes

## Regex Capture Groups

Use `$REGEX_GROUP_N` in commands:

```toml
[[handler]]
on = "windowtitlev2"
when = "(.*),Mozilla Firefox"  # Capture window address
then = "notify-send 'Firefox window: $REGEX_GROUP_1'"
```

- `$REGEX_GROUP_0` - Full matched string
- `$REGEX_GROUP_1` - First capture group (window address)
- `$REGEX_GROUP_2`+ - Additional groups

## Script Library

Scripts live in `~/.config/hyprwhenthen/scripts/`:

### float-and-center.sh

Auto-float and center OAuth popups.

**Usage**: Called by hyprwhenthen automatically
```bash
~/.config/hyprwhenthen/scripts/float-and-center.sh <window_address>
```

**Creating new scripts**:
```bash
# 1. Create script
nano ~/.config/hyprwhenthen/scripts/my-handler.sh

# 2. Make executable
chmod +x ~/.config/hyprwhenthen/scripts/my-handler.sh

# 3. Reference in config.toml
then = "~/.config/hyprwhenthen/scripts/my-handler.sh $REGEX_GROUP_1"
```

## Testing

### Test OAuth handler

1. Visit Google login page
2. Observe window auto-floating and centering
3. Check logs: `journalctl --user -u hyprwhenthen -f`

### Test manually

```bash
# Run handler directly
~/.config/hyprwhenthen/scripts/float-and-center.sh 12345678

# Test with debug mode
hyprwhenthen run --debug
```

## Troubleshooting

### Handler not firing

```bash
# Check logs
journalctl --user -u hyprwhenthen -f

# Validate config
hyprwhenthen validate

# Test event stream (see events in real-time)
hyprwhenthen run --debug
```

### Script not executing

```bash
# Check executable bit
ls -l ~/.config/hyprwhenthen/scripts/

# Fix permissions
chmod +x ~/.config/hyprwhenthen/scripts/float-and-center.sh

# Test script directly
~/.config/hyprwhenthen/scripts/float-and-center.sh 12345678
```

### Regex not matching

```bash
# Test regex (example)
echo "0x12345678,Sign In - Google Accounts" | grep -E "(.*),Sign In.*"

# Use online regex testers for complex patterns
```

## Configuration File Structure

```
~/.config/hyprwhenthen/
├── config.toml                 # Handler definitions
└── scripts/
    └── float-and-center.sh     # Automation scripts
```

## Common Patterns

### Auto-float dialogs

```toml
[[handler]]
on = "openwindow"
when = "pavucontrol|blueman-manager"
then = "hyprctl dispatch togglefloating"
```

### Move apps to specific workspaces

```toml
[[handler]]
on = "openwindow"
when = "spotify"
then = "hyprctl dispatch movetoworkspacesilent 9"
```

### Picture-in-Picture detection

```toml
[[handler]]
on = "windowtitlev2"
when = "(.*),Picture-in-Picture"
then = "hyprctl dispatch togglefloating address:0x$REGEX_GROUP_1"
```

## Documentation

See: [GitHub repository](https://github.com/fiffeek/hyprwhenthen)
