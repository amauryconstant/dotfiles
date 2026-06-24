-- ============================================================================
-- Input Configuration
-- ============================================================================
-- Keyboard, mouse, and touchpad settings.
-- Documentation: https://wiki.hypr.land/Configuring/Variables/#input
-- ============================================================================

hl.config({
    input = {
        -- Keyboard --------------------------------------------------------
        kb_layout  = "us",   -- ISO 639-1 language code (us, fr, de, jp)
        kb_variant = "",     -- Layout variant (dvorak, colemak, azerty)
        kb_model   = "",     -- Keyboard model (usually auto-detected)
        kb_options = "",     -- e.g. "grp:alt_shift_toggle", "caps:escape"
        kb_rules   = "",     -- XKB rules file (advanced)

        numlock_by_default = true,   -- Enable numpad on startup
        -- repeat_rate  = 25,        -- Characters per second when holding
        -- repeat_delay = 600,       -- Milliseconds before repeat starts

        -- Mouse -----------------------------------------------------------
        -- follow_mouse: 0=click-to-focus, 1=focus follows mouse,
        --               2=follows + click floating brings to front,
        --               3=follows but new-monitor cursor keeps focus
        follow_mouse = 1,
        sensitivity  = 0,    -- -1.0 (slow) .. 0 (none) .. 1.0 (fast)
        -- accel_profile = "flat",  -- Force no acceleration (raw input)

        -- Touchpad --------------------------------------------------------
        touchpad = {
            -- natural_scroll: true=macOS/mobile style, false=traditional
            natural_scroll = false,
            -- tap_to_click          = true,
            -- disable_while_typing  = true,
            -- middle_button_emulation = false,
            -- drag_lock             = false,
        },
    },
})

-- ============================================================================
-- Additional Input Devices (per-device, uncomment and modify)
-- Find device names with: hyprctl devices
-- ============================================================================
-- hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })
-- hl.device({ name = "external-keyboard", kb_layout = "us", kb_variant = "colemak" })
