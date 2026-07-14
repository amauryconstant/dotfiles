# Systemd User Services

**Location**: `private_dot_config/systemd/user/` → `~/.config/systemd/user/`
**Parent**: See `../CLAUDE.md` for XDG config overview
**Control**: `systemctl --user` / `journalctl --user -u <unit>` (standard)

## Units & how they get enabled

| Unit | Type | Purpose | Enabled by |
|------|------|---------|-----------|
| `wallpaper-cycle.{service,timer}` | timer | Random wallpaper every 30 min | `after_004_enable_user_timers` |
| `system-health-check.{service,timer}` | timer | Health monitoring every 15 min | `after_004` |
| `session-autosave.{service,timer}` | timer | Hyprland session autosave every 15 min | `after_004` |
| `home-backup.{service,timer}` | timer | Restic home backup daily 9am | `after_010` (Restic feature) |
| `hyprdynamicmonitors.service` + `-prepare.service` | service | Monitor profile daemon + pre-Hyprland prep | `before_008` |
| `hyprwhenthen.service` | service | Event-driven window automation | `before_008` |
| `darkman.service` | service | Solar auto theme switching | `after_006` |
| `llama-swap.service.tmpl` | service | llama-swap on-demand multi-model LLM proxy (`:8080`, parents `llama-server` subprocesses) | `services.yaml` user_services → `after_002` (gated on `llama-swap` present) |
| `llama-server.service.tmpl` | service | **Phase-0 fallback** (single static model), `enabled: false` — superseded by `llama-swap` | `services.yaml` (disabled; flip to re-enable) |
| `kanata.service` | service | Kanata keyboard remapper (port 5829, `~/.config/kanata/kanata.kbd`) | `after_010`, gated on `features.kanata.enabled` + **laptop** chassis + `uinput` module |
| `voxtype.service.d/` | drop-in | Voxtype GPU config override | `after_010` |
| `app-blueman@autostart.service.d/`, `app-nm-applet@autostart.service.d/` | drop-in | Suppress tray icons on **desktop** chassis | static (`{{ if eq .chassisType "desktop" }}`) |

Timer schedules/enable logic are driven by `.chezmoidata/services.yaml` (`user_timers`, `user_services`) — add new timers there, not by hand-editing the setup scripts.

## Non-obvious details

**session-autosave** (the only unit with subtle wiring):
- Runs `session-save autosave` with `DOTFILES_SESSION_QUIET=1`; writes **only** the `autosave` slot, never manual `default`/named slots (`hypr-session list` shows it).
- Requires `HYPRLAND_INSTANCE_SIGNATURE` in the systemd user env (imported via `dbus-update-activation-environment` in `hypr/conf/autostart.conf`) so `hyprctl` can reach the compositor — the service gates on it via `ExecCondition`. Without that import the service silently no-ops.

**Autostart drop-ins** override GNOME-style `app-*@autostart` services Hyprland doesn't need; chassis-gated so laptops keep their tray applets.

**random-wallpaper** (wallpaper-cycle target): `~/.local/lib/scripts/media/random-wallpaper`, lock at `$XDG_RUNTIME_DIR/random-wallpaper.lock` — remove a stale lock if cycling stalls.

## Integration Points

- **Scripts**: `~/.local/lib/scripts/media/` (random-wallpaper, set-wallpaper)
- **Wallpapers**: `~/.config/wallpapers/` (theme-organized)
- **Themes**: `~/.config/themes/current/`
- **Restic**: home backup target `~/.local/share/restic-home/`
