-- ============================================================================
-- Voice STT - Speech-to-Text Dictation (voxtype)
-- ============================================================================
-- Push-to-talk: hold combo, speak, release to transcribe (text → clipboard).
-- Streaming:    tap to start, tap to stop; text appears live as you speak.
--
-- SUPER+T      → Cohere   push-to-talk (DEFAULT — multilingual incl. FR)
-- SUPER+ALT+T  → Parakeet streaming toggle (live incremental text, English)
-- SUPER+CTRL+T → Parakeet push-to-talk (fast English-only alternative)
-- SUPER+ALT+M  → Meeting  mode toggle (continuous transcription + AI summary)
--
-- binddr (stop on key release) → o.bind(..., { release = true }).
-- NOTE: recording start switches to the `voxtype_recording` submap (see
-- ../../conf.d/voxtype-submap.lua) to neutralise modifier interference.
-- ============================================================================

-- Cohere — default engine, push-to-talk (multilingual, daily driver)
-- "voxtype-record" (not "voxtype record") wraps start/toggle so the daemon
-- restarts transparently if voxtype-idle-unload.timer stopped it (see
-- systemd/user/CLAUDE.md). Stop doesn't need this — it only fires after a
-- successful start, so the daemon is already running.
-- Full path required: Hyprland's exec dispatcher doesn't see the zsh PATH
-- that adds ~/.local/lib/scripts/desktop (see other bindings in this repo).
o.bind("SUPER + T", "Start voice dictation (Cohere)", "~/.local/lib/scripts/desktop/voxtype-record start")
o.bind("SUPER + T", "Stop voice dictation (Cohere)", "voxtype record stop", { release = true })

-- Parakeet — streaming dictation, toggle (live incremental text, English)
o.bind("SUPER + ALT + T", "Toggle streaming dictation (Parakeet)", "~/.local/lib/scripts/desktop/voxtype-record toggle")

-- Parakeet — fast English-only push-to-talk
o.bind("SUPER + CTRL + T", "Start voice dictation (Parakeet)", "~/.local/lib/scripts/desktop/voxtype-record start --model parakeet-tdt-0.6b-v3")
o.bind("SUPER + CTRL + T", "Stop voice dictation (Parakeet)", "voxtype record stop", { release = true })

-- Meeting mode — continuous transcription with speaker diarization + AI summary
o.bind("SUPER + ALT + M", "Toggle meeting transcription", "~/.local/lib/scripts/desktop/voice-meeting toggle")
