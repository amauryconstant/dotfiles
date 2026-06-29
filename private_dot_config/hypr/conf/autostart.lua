-- ============================================================================
-- Autostart Applications
-- ============================================================================
-- Applications and services to launch when Hyprland starts.
-- o.exec_on_start(cmd) wraps hl.on("hyprland.start", ...) and runs cmd via the
-- shell, so &&, ;, eval, $(...) and ~ all work inside a single string.
-- (exec-once equivalent: runs once at startup, not on config reload.)
-- ============================================================================

-- Waybar - Status bar (workspaces, system info, tray icons)
o.exec_on_start("waybar")

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

-- Polkit Authentication Agent - GUI privilege elevation
-- polkit-gnome (stable) over hyprpolkitagent (Qt platform plugin crashes)
o.exec_on_start("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

-- Clipboard History Manager - watch clipboard, store items in history db
o.exec_on_start("wl-paste --watch ~/.local/lib/scripts/media/clipboard-store")

-- Idle Management Daemon - screen lock + power management
o.exec_on_start("hypridle")

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
-- ============================================================================
