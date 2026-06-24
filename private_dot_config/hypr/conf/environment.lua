-- ============================================================================
-- Environment Variables
-- ============================================================================
-- Environment variables for Hyprland session.
-- Syntax: hl.env("VARIABLE", "value")
--
-- These variables are set before Hyprland starts and affect all child processes.
-- Changes require Hyprland restart (logout/login) to take effect.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- NVIDIA-specific settings (nvidia-open drivers)
-- ----------------------------------------------------------------------------
-- These variables enable proper Wayland support with NVIDIA GPUs.
-- REMOVE/MODIFY these if switching to AMD or Intel GPU.

-- Hardware video acceleration driver for NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia")

-- VA-API backend for NVIDIA (requires libva-nvidia-driver package)
-- Enables hardware-accelerated video decoding in browsers and media players
hl.env("NVD_BACKEND", "direct")

-- Explicitly set session type to Wayland (informs applications)
hl.env("XDG_SESSION_TYPE", "wayland")

-- Graphics Buffer Manager backend for NVIDIA DRM
hl.env("GBM_BACKEND", "nvidia-drm")

-- OpenGL vendor library for NVIDIA
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- Hardware cursor support (test mode for modern NVIDIA drivers 580+)
-- Legacy value: 1 (disabled) - Previous workaround for NVIDIA cursor bugs
-- Modern value: 0 (enabled) - Newer drivers (580+) may have fixed rendering issues
-- If cursor issues occur (invisible cursor, rendering artifacts), revert to 1
hl.env("WLR_NO_HARDWARE_CURSORS", "0")

-- Prevent screen tearing with VSync (NVIDIA-specific)
hl.env("__GL_SYNC_TO_VBLANK", "1")

-- ----------------------------------------------------------------------------
-- Qt/GTK Application Theming
-- ----------------------------------------------------------------------------

-- Qt theme engine (qt5ct for manual theming)
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

-- Force Qt applications to use Wayland (instead of XWayland fallback)
hl.env("QT_QPA_PLATFORM", "wayland")

-- Disable Qt's client-side decorations (use Hyprland's window decorations)
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- Force GTK applications to use Wayland backend
-- Fallback to x11 if Wayland support is broken: hl.env("GDK_BACKEND", "wayland,x11")
hl.env("GDK_BACKEND", "wayland")

-- Disable GTK4 Settings portal — makes ~/.config/gtk-4.0/settings.ini the primary
-- configuration source for icon theme, font, cursor, gtk-theme.
-- Without this, the Wayland portal overrides settings.ini for all org.gnome.desktop.interface keys.
-- Note: libadwaita apps read color-scheme via their own portal connection (unaffected).
-- Note: GTK4 native file choosers fall back to built-in widget (Qt apps unaffected).
hl.env("GDK_DEBUG", "no-portals")

-- ----------------------------------------------------------------------------
-- Cursor Configuration
-- ----------------------------------------------------------------------------
-- Cursor size in pixels (default: 24)
-- Common values: 24 (standard), 32 (large), 48 (HiDPI)
hl.env("XCURSOR_SIZE", "24")

-- Cursor theme (uncomment and set if using custom cursor theme)
-- hl.env("XCURSOR_THEME", "Adwaita")

-- ----------------------------------------------------------------------------
-- Browser & Application Wayland Support
-- ----------------------------------------------------------------------------
-- Force Firefox to use native Wayland (better performance than XWayland)
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Enable Wayland support for Electron apps (VS Code, Slack, Discord, etc.)
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Enable explicit sync (syncobj) for Electron/CEF apps (Electron 35+/Chromium 134+)
-- Resolves all flickering issues with NVIDIA GPUs
-- Requires: Hyprland with syncobj support, modern Electron/Chromium versions
hl.env("ELECTRON_FLAGS", "--enable-features=WaylandLinuxDrmSyncobj")

-- ----------------------------------------------------------------------------
-- HiDPI Scaling (uncomment and adjust as needed)
-- ----------------------------------------------------------------------------
-- hl.env("QT_SCALE_FACTOR", "1.5")    -- Qt global scaling (HiDPI displays)
-- hl.env("GDK_SCALE", "2")            -- GTK global scaling (integer only)
-- hl.env("GDK_DPI_SCALE", "0.5")      -- GTK DPI scaling (compensate GDK_SCALE)
