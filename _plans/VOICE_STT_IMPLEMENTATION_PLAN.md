# Voice STT Implementation Plan

**Last revised**: 2026-06-17
**Status**: ✅ Operational on voxtype 0.7.x (repaired + upgraded)

---

## Architecture Decision (April 2026)

**Original plan**: custom Python `voice-stt` tool backed by Moonshine, hosted on GitLab as a chezmoi external.

**Decision**: use **voxtype** (`voxtype-bin`, AUR). It ships everything Phase 1 planned and more — no Python, no GitLab repo, no maintenance burden. The chezmoi-external approach is dropped entirely.

---

## 0.7.x Repair + Upgrade (June 2026)

### The breakage

voxtype-bin auto-upgraded to **0.7.5**. v0.7.0 renamed/split every binary and reset the active `/usr/bin/voxtype` symlink to the CPU default (`voxtype-avx2`, no Parakeet). With `engine = "parakeet"` configured, the daemon crashed on every start (`Parakeet engine requested but voxtype was not compiled with --features parakeet`); `voxtype status` returned `stopped`; the Waybar module — which hid `stopped` with `opacity:0` — vanished.

**Root flaw**: engine/GPU selection lived in `run_once_after_010`, which ran once at install and never recovered from a package upgrade.

### The fix (self-healing)

- Engine/GPU/model/OSD setup extracted into **`run_onchange_after_configure_voxtype.sh.tmpl`**. Its hash embeds the installed voxtype version (`output` template func), so it **re-runs on every upgrade** and re-selects the correct ONNX variant.
- Variant selection uses the 0.7.x surface: `sudo voxtype setup onnx --enable`, then `sudo voxtype setup gpu --enable` **only when the CPU has AVX-512 + an NVIDIA GPU**. Idempotent via `readlink -f /usr/bin/voxtype`.

> **Hardware note (this host = i9-13900K):** the ONNX *GPU* binaries (`voxtype-onnx-cuda-*`, `-migraphx`) are built with **AVX-512**, which Intel 12th–14th gen consumer CPUs lack. So this box runs **`voxtype-onnx-avx2` (CPU)** — all chosen ONNX engines (Parakeet, Cohere, Moonshine, streaming, ML diarization) work on the CPU; only ONNX *GPU* accel is unavailable. The 13900K keeps Parakeet dictation snappy. (Whisper+Vulkan would use the GPU but loses every ONNX engine — not worth it here.)
- Service is **restarted** (not just enabled) so variant/config changes take effect.
- Waybar `stopped` now renders a dim mic-off glyph (`󰍭`) instead of hiding — a dead daemon stays visible; click restarts.

---

## Current State (June 2026)

### Engine map (Hyprland bindings — `conf/bindings/voice.conf`)

| Binding | Engine | Mode | Notes |
|---------|--------|------|-------|
| `SUPER+T` | Parakeet | push-to-talk | fast English, ONNX (CPU on this host) — daily |
| `SUPER+ALT+T` | Parakeet | streaming toggle | live incremental text (v0.7.2) |
| `SUPER+SHIFT+T` | Moonshine | push-to-talk | alternate English, low VRAM |
| `SUPER+CTRL+T` | Cohere | push-to-talk | multilingual, #1 Open ASR (v0.7.0) |
| `SUPER+ALT+M` | — | meeting toggle | `voice-meeting` CLI + Ollama summaries |

### Features enabled

- **OSD overlay**: `[osd] frontend = "quickshell"` — waveform + engine status (`quickshell` pkg + `voxtype setup quickshell`).
- **Streaming**: `[parakeet] streaming_chunk_secs / streaming_left_context_secs / streaming_right_context_secs`; toggle binding has a matching stop entry inside `voxtype_recording` submap.
- **Cohere multilingual**: `[cohere] model = "cohere-transcribe-q4f16"` (download is interactive-only via `voxtype setup model`).
- **Meeting mode**: `[meeting]` + `[meeting.diarization] backend = "ml"` (ECAPA-TDNN) + `[meeting.summary] backend = "ollama"`.
- **Filler-word filtering**: `[text] filter_filler_words = true`.
- **Modifier-release guard**: `[output] wait_for_modifier_release`, `modifier_release_timeout_ms = 750`.

### Models present (`~/.local/share/voxtype/models/`)

parakeet-tdt-0.6b-v3, moonshine-base, ggml-large-v3-turbo, ggml-small.en.
Streaming auto-uses `parakeet-unified-en-0.6b` on first toggle; Cohere needs an interactive download.

---

## Key files

- `.chezmoiscripts/run_onchange_after_configure_voxtype.sh.tmpl` — self-healing setup
- `private_dot_config/voxtype/config.toml.tmpl` — all engine/feature config
- `private_dot_config/hypr/conf/bindings/voice.conf` + `conf.d/voxtype-submap.conf` — bindings
- `private_dot_config/waybar/{config,style.css}.tmpl` — status module
- `private_dot_local/lib/scripts/desktop/executable_voice-meeting` — meeting helper
- `.chezmoidata/{features,packages}.yaml` — toggle + `quickshell`/`voxtype-bin`/`wtype`/`cuda`

---

## Verifying / troubleshooting

```bash
voxtype info variants                 # active: voxtype-onnx-avx2 (AVX2 host) / -cuda-13 (AVX-512 host)
systemctl --user is-active voxtype    # active
voxtype status                        # idle (not stopped)
journalctl --user -u voxtype -n 30    # daemon errors
```

If the icon disappears again after an upgrade: `chezmoi apply` re-runs the configure script (version hash changed) and re-selects the ONNX variant. Manual one-liner (sudo only for the /usr/bin symlink swap; drop the `gpu` step on AVX2-only CPUs): `sudo voxtype setup onnx --enable && systemctl --user restart voxtype`.

---

## Out of scope

TTS and voice→LLM→voice pipelines remain separate efforts (see `TTS_ENGINES_RESEARCH.md`). `VOICE_STT_FUTURE_PHASES.md` is archived — superseded by voxtype's native feature set.
