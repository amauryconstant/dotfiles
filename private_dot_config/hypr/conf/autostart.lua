-- ============================================================================
-- Autostart Applications
-- ============================================================================
-- Applications and services to launch when Hyprland starts.
-- o.exec_on_start(cmd) wraps hl.on("hyprland.start", ...) and runs cmd via the
-- shell, so &&, ;, eval, $(...) and ~ all work inside a single string.
-- (exec-once equivalent: runs once at startup, not on config reload.)
-- ============================================================================

-- NOTE: the status bar is NOT started here. Waybar and the Quickshell bar are
-- mutually exclusive (the Quickshell one floats and reserves 56px, which
-- Waybar's full-bleed bar cannot stack with), so each lives in its own
-- conf.d drop-in and .chezmoiignore deploys exactly one, keyed on
-- features.quickshell_shell: conf.d/waybar.lua or conf.d/quickshell.lua.

-- awww - Wayland wallpaper daemon with smooth transitions (renamed from swww)
o.exec_on_start("awww-daemon")

-- D-Bus activation environment update (Wayland integration + screen sharing)
o.exec_on_start(
	"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"
)

-- Nextcloud - Cloud sync client (background, no window at startup)
o.exec_on_start("nextcloud --background")

-- Gnome Keyring - Secret storage for WiFi/SSH/GPG (needed by nmtui/NetworkManager)
o.exec_on_start("eval $(/usr/bin/gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh)")

-- NOTE: the polkit agent is NOT started here. A session may have exactly one,
-- and the Quickshell shell ships its own (dotfiles/polkit/PolkitDialog.qml), so
-- the two are mutually exclusive -- like the status bar above. .chezmoiignore
-- deploys conf.d/polkit-gnome.lua only when features.quickshell_polkit is off.

-- Session-type guard. Outside uwsm, graphical-session.target is never reached,
-- so quickshell, hypridle, darkman and the monitor daemons never start, and
-- uwsm/env (the whole session environment) was never sourced. hyprctl notify,
-- not notify-send: in that session nothing owns org.freedesktop.Notifications.
o.exec_on_start(
	'[ -n "$UWSM_FINALIZE_VARNAMES" ] || hyprctl notify 0 30000 0 '
		.. '"Not a uwsm session: no bar, idle lock or notifications. Log out and pick Hyprland (uwsm-managed)."'
)

-- Clipboard History Manager - watch clipboard, store items in history db
o.exec_on_start("wl-paste --watch ~/.local/lib/scripts/media/clipboard-store")

-- NOTE: hypridle is a systemd user service (hypridle.service), not exec-once.
-- Reload after config changes: systemctl --user restart hypridle
-- o.exec_on_start("hypridle")

-- Session restore prompt (5s delay ensures Hyprland is fully initialized)
o.exec_on_start("sleep 5 && ~/.local/lib/scripts/desktop/session-prompt")

-- Session start hook - notify user hooks a new session started
o.exec_on_start("sleep 5 && ~/.local/lib/scripts/core/hook-runner session-start")

-- NOTE: `hyprpm reload -n` was dropped — under the Lua config hyprsplit loads
-- via require("hyprsplit"), and no other hyprpm (C++) plugins are used.
-- o.exec_on_start("hyprpm reload -n")

-- COMMON ADDITIONS (uncomment as needed):
-- o.exec_on_start("blueman-applet")  -- Bluetooth tray icon

-- ============================================================================
-- SERVICE REFERENCE (run via systemd, NOT exec_on_start)
-- ============================================================================
-- SwayNotificationCenter : D-Bus activated (org.freedesktop.Notifications) —
--   DO NOT add o.exec_on_start("swaync"); conflicts with SystemdService=.
-- HyprDynamicMonitors    : systemctl --user enable hyprdynamicmonitors-prepare.service
-- hyprwhenthen           : systemctl --user enable hyprwhenthen.service
-- Quickshell shell       : systemctl --user enable quickshell.service — supervised because it
--   owns the bar, the OSD, the launcher AND org.freedesktop.Notifications, so an unsupervised
--   exec_on_start loses all of them at once. Reload with `systemctl --user restart`.
-- ============================================================================
