-- ============================================================================
-- Media Keys
-- ============================================================================
-- Hardware media keys for volume, brightness, and playback control.
-- Volume/brightness use { locked = true, repeating = true } (work on lock
-- screen + repeat while held); playback uses { locked = true }.
-- ============================================================================

-- Volume control (pamixer)
o.bind("XF86AudioRaiseVolume", "Volume up", "pamixer -i 5", { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "pamixer -d 5", { locked = true, repeating = true })
o.bind("XF86AudioMute", "Toggle mute", "pamixer -t", { locked = true, repeating = true })

-- Brightness control (laptop)
o.bind("XF86MonBrightnessUp", "Brightness up", "brightnessctl set +10%", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", "brightnessctl set 10%-", { locked = true, repeating = true })

-- Media playback (playerctl — any MPRIS player: Spotify, Firefox, mpv, ...)
o.bind("XF86AudioPlay", "Play/pause", "playerctl play-pause", { locked = true })
o.bind("XF86AudioPause", "Pause", "playerctl pause", { locked = true })
o.bind("XF86AudioNext", "Next track", "playerctl next", { locked = true })
o.bind("XF86AudioPrev", "Previous track", "playerctl previous", { locked = true })
