# Network Scripts - Claude Code Reference

**Location**: `/home/amaury/.local/share/chezmoi/private_dot_local/lib/scripts/network/`
**Parent**: See `../CLAUDE.md` for script library overview
**Root**: See `/home/amaury/.local/share/chezmoi/CLAUDE.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Count**: 5 scripts
- **UI pattern**: Mixed — tailscale + network-info + wifi-switch use gum-ui; vpn-toggle + vpn-switch use notify-send/fzf
- **CLI alias**: `ts` → `tailscale.sh` (via `bin/executable_ts` wrapper)

## Scripts

| Script | CLI | Purpose | UI |
|--------|-----|---------|-----|
| `tailscale.sh` | `ts` | Interactive Tailscale TUI with exit node support | gum-ui |
| `vpn-switch` | `vpn-switch` | Interactive Tailscale account/tailnet switcher | fzf + notify-send |
| `vpn-toggle` | `vpn-toggle` | Toggle Tailscale on/off | notify-send |
| `wifi-switch` | `wifi-switch` | Interactive WiFi network switcher (nmcli) | gum-ui |
| `network-info` | `network-info` | Display local IP + Tailscale peer info | gum-ui |

## tailscale.sh (ts wrapper)

**Non-obvious**: `bin/executable_ts` is a thin subcommand router that calls this script. Direct usage:
```bash
ts                          # Interactive menu
ts connect                  # Connect without exit node
ts connect my-exit-node     # Connect via exit node
ts disconnect               # Disconnect
ts status                   # Show status + peers
```

Auto-starts `tailscaled` systemd service if not running.

## vpn-switch

Switches between Tailscale accounts/tailnets. Uses `fzf` for selection (not wofi), `sudo tailscale switch`.

## vpn-toggle

Simple on/off toggle. If connected → `tailscale down`. If disconnected → `tailscale up`. Sends notify-send.

## wifi-switch

Lists available WiFi networks via `nmcli`, connects to selected via `nmcli device wifi connect`. Uses gum-ui for selection.

## network-info

Shows local IP (from `ip route get 1`) and Tailscale IP/peers. Falls back gracefully if Tailscale not connected.

## Integration Points

- **ts wrapper**: `bin/executable_ts` routes subcommands to this script
- **tailscaled**: System service (not user service) — auto-started by tailscale.sh if needed
