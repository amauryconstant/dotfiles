-- ============================================================================
-- Screenshots
-- ============================================================================
-- Screenshot tools with Satty annotation editor integration.
-- ============================================================================

-- Smart screenshot with Satty editor (auto-snaps to window if selection tiny)
o.bind("Print", "Smart screenshot", "~/.local/lib/scripts/media/screenshot smart")

-- Quick screenshot to clipboard (bypasses editor for speed)
o.bind("SHIFT + Print", "Quick screenshot to clipboard", "~/.local/lib/scripts/media/screenshot smart clipboard")

-- Color picker (pick color → hex to clipboard)
o.bind("SUPER + Print", "Color picker", "pkill hyprpicker || hyprpicker -a")

-- Fullscreen screenshot with editor
o.bind("SUPER + SHIFT + Print", "Fullscreen screenshot", "~/.local/lib/scripts/media/screenshot fullscreen")

-- Screen recording with audio (toggle)
o.bind("ALT + SHIFT + Print", "Screen recording with audio", "~/.local/lib/scripts/desktop/screenrecord --with-audio")

-- Fullscreen recording with audio (toggle)
o.bind(
	"CTRL + ALT + SHIFT + Print",
	"Fullscreen recording with audio",
	"~/.local/lib/scripts/desktop/screenrecord --with-audio"
)

-- Region/window screenshot without smart-snap
o.bind("SUPER + CTRL + Print", "Region screenshot", "~/.local/lib/scripts/media/screenshot region")
o.bind("SUPER + ALT + Print", "Window screenshot", "~/.local/lib/scripts/media/screenshot windows")

-- QR code / OCR capture from a screen region
o.bind("CTRL + Print", "Capture QR code", "~/.local/lib/scripts/media/capture-qr")
o.bind("SUPER + CTRL + SHIFT + Print", "Capture text (OCR)", "~/.local/lib/scripts/media/capture-text-extraction")
