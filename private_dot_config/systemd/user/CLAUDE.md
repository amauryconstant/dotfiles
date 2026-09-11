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
| `quickshell.service` | service | Desktop shell — bar, OSD, launcher, pickers **and `org.freedesktop.Notifications`**. Supervised because one process owns all of them; see "Non-obvious details" | `services.yaml` user_services → `after_002` |
| `hypridle.service` | service | Idle/lock daemon. `ExecStart` reads `HYPRIDLE_CONF`, defaulted via `Environment=` and overridden by the optional `EnvironmentFile=-%t/hypridle-mode.env` that `idle-toggle-nolock` writes (later directive wins). See `lib/scripts/desktop/CLAUDE.md` → Idle & Lock | `services.yaml` user_services → `after_002` |
| `llama-swap.service.tmpl` | service | llama-swap on-demand multi-model LLM proxy (`:8080`, parents `llama-server` subprocesses) | `services.yaml` user_services → `after_002` (gated on `llama-swap` present) |
| `llama-server.service.tmpl` | service | **Phase-0 fallback** (single static model), `enabled: false` — superseded by `llama-swap` | `services.yaml` (disabled; flip to re-enable) |
| `kanata.service` | service | Kanata keyboard remapper (port 5829, `~/.config/kanata/kanata.kbd`) | `after_010`, gated on `features.kanata.enabled` + **laptop** chassis + `uinput` module |
| `voxtype.service.d/` | drop-in | Voxtype GPU config override | `after_010` |
| `app-blueman@autostart.service.d/`, `app-nm-applet@autostart.service.d/` | drop-in | Suppress tray icons on **desktop** chassis | static (`{{ if eq .chassisType "desktop" }}`) |

Timer schedules/enable logic are driven by `.chezmoidata/services.yaml` (`user_timers`, `user_services`) — add new timers there, not by hand-editing the setup scripts.

## Non-obvious details

**quickshell** (the shell, and the only unit whose failure takes the desktop with it):

- **`Restart=always`, not `on-failure`.** A clean exit still leaves the user with no bar, no
  launcher and no notification daemon. `quickshell -c dotfiles kill` is therefore a *restart*.
- **`StartLimitIntervalSec=60` + `StartLimitBurst=5`** — Omarchy's give-up budget
  (`bin/omarchy-launch-shell`) as directives rather than a bash loop. Once spent, `start` is
  refused until `reset-failed`, which `desktop/quickshell-toggle` does before starting: `SUPER+B`
  is the only route back when there is no bar left to ask with.
- **`ConditionPathExists=%h/.config/quickshell/dotfiles/shell.qml`** is the whole Waybar-branch
  gate. `.chezmoiignore` already drops `.config/quickshell` when `features.quickshell_shell` is
  off, so the unit goes inert instead of restart-looping — no second gate, and no `run_onchange`
  script to keep the two in sync.
- **`PartOf=graphical-session.target`** is what Omarchy needs an explicit `compositor_alive()`
  probe for: the session going down stops the unit rather than burning its restart budget.
- **`Environment=QS_DISABLE_FILE_WATCHER=1`.** `chezmoi apply` replaces files by rename, which
  Quickshell's per-file watch does not survive, and its one directory-triggered reload can land
  mid-apply on a half-written tree. `systemctl --user restart quickshell` is the only reload path.
  Measurements: `.claude/rules/quickshell-qml.md`.
- **Not `-d`** (forks and `setsid()`s, so `Type=simple` would see the parent exit) and **not `-n`**
  (`--no-duplicate` exits 0, which `Restart=always` would spin on).
- Quickshell re-execs **itself** on a crash signal (`src/crash/handler.cpp`), so the unit exists
  for what that cannot reach: `_exit()` on a lost Wayland connection, a crash inside 10s of launch
  (its own crash-loop guard), `SIGKILL`, and a QML tree that will not load.

**session-autosave** (the other unit with subtle wiring):
- Runs `session-save autosave` with `DOTFILES_SESSION_QUIET=1`; writes **only** the `autosave` slot, never manual `default`/named slots (`hypr-session list` shows it).
- Requires `HYPRLAND_INSTANCE_SIGNATURE` in the systemd user env (imported via `dbus-update-activation-environment` in `hypr/conf/autostart.conf`) so `hyprctl` can reach the compositor — the service gates on it via `ExecCondition`. Without that import the service silently no-ops.

**Autostart drop-ins** override GNOME-style `app-*@autostart` services Hyprland doesn't need; chassis-gated so laptops keep their tray applets.

**random-wallpaper** (wallpaper-cycle target): `~/.local/lib/scripts/media/random-wallpaper`, lock at `$XDG_RUNTIME_DIR/random-wallpaper.lock` — remove a stale lock if cycling stalls.

## Integration Points

- **Scripts**: `~/.local/lib/scripts/media/` (random-wallpaper, set-wallpaper)
- **Wallpapers**: `~/.config/wallpapers/` (theme-organized)
- **Themes**: `~/.config/themes/current/`
- **Restic**: home backup target `~/.local/share/restic-home/`
