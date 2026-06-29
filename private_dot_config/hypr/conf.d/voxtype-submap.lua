-- ============================================================================
-- Voxtype compositor integration (recording submap)
-- ============================================================================
-- Fixes modifier key interference when using compositor keybindings.
--
-- voxtype_recording: active during recording/transcription. F12 cancels.
-- bindr entries mirror voice.lua — required because pre_recording_command
-- switches to this submap BEFORE the key is released, so the default submap's
-- release bind for SUPER+T never fires. voxtype resets via post_output_command.
--
-- voxtype_suppress is omitted: only needed for mode = "type" (wtype), not
-- clipboard mode (writes via wl-copy — modifier keys cannot interfere).
-- ============================================================================

hl.define_submap("voxtype_recording", function()
	-- F12 cancels recording/transcription and returns to the default submap
	hl.bind("F12", hl.dsp.exec_cmd("voxtype record cancel"))
	hl.bind("F12", hl.dsp.submap("reset"))

	-- Stop push-to-talk on key release (mirrors voice.lua)
	hl.bind("SUPER + T", hl.dsp.exec_cmd("voxtype record stop"), { release = true })
	hl.bind("SUPER + CTRL + T", hl.dsp.exec_cmd("voxtype record stop"), { release = true })

	-- Streaming toggle: start lives in the default submap; this stops it from inside
	hl.bind("SUPER + ALT + T", hl.dsp.exec_cmd("voxtype record toggle"))
end)
