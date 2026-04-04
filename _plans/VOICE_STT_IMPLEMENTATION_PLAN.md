# Voice STT Implementation Plan

**Last revised**: 2026-04-04
**Status**: ✅ Phase 1 Complete (via voxtype) — see below

---

## Architecture Decision (April 2026)

**Original plan**: Build a custom Python `voice-stt` tool backed by Moonshine, hosted on GitLab, managed as a chezmoi external.

**Revised decision**: Use **voxtype** (`voxtype-bin`, AUR) instead.

Voxtype shipped everything Phase 1 planned, and more:

| Phase 1 requirement | voxtype capability |
|---------------------|--------------------|
| Push-to-talk (SUPER+T) | ✅ `bindd`/`binddr` in `voice.conf` |
| Hyprland compositor hooks | ✅ `voxtype-submap.conf`, pre/post commands |
| Clipboard output | ✅ `mode = "clipboard"` |
| Dunst notifications | ✅ `[output.notification]` |
| Waybar status widget | ✅ `custom/voxtype` with `--follow` |
| VAD | ✅ `voxtype setup vad` (Silero) |
| Multiple STT engines | ✅ 7 engines: Whisper, Parakeet, Moonshine, SenseVoice, Paraformer, Dolphin, Omnilingual |
| GPU acceleration | ✅ Vulkan (all GPUs) + ONNX CUDA/ROCm |
| Meeting transcription | ✅ `voxtype meeting` mode (Pro feature) |

No Python code, no GitLab repo, no maintenance burden. The chezmoi external approach is dropped entirely.

---

## Current State (April 2026)

### What's done

- `voxtype-bin` installed and running as systemd user service
- SUPER+T push-to-talk bindings in `conf/bindings/voice.conf`
- Compositor submaps in `conf.d/voxtype-submap.conf` (sourced via `hyprland.conf.tmpl`)
- Waybar `custom/voxtype` module with nerd-font icons + CSS animation
- Config at `private_dot_config/voxtype/config.toml.tmpl`
- Audio feedback, spoken punctuation, clipboard output

### Engine status

| Engine | Status | Binary |
|--------|--------|--------|
| Whisper small.en | ✅ Downloaded | `voxtype-vulkan` (current) |
| Whisper large-v3-turbo | ✅ Downloaded | available |
| Parakeet ONNX CUDA | ⏳ Pending model download | `voxtype-onnx-cuda` available |
| Moonshine | ⏳ Pending model download | `voxtype-onnx-cuda` (same binary) |

---

## Next Steps

### 1. Switch to ONNX engine + Parakeet (immediate)

```bash
sudo voxtype setup onnx --enable     # switches to voxtype-onnx-cuda
voxtype setup model                  # interactive: select Parakeet model
```

Update `config.toml.tmpl`:
```toml
engine = "parakeet"
```

### 2. Add Moonshine as secondary model (optional)

Moonshine is an encoder-decoder ONNX model optimized for edge/low-memory. Useful as secondary with a modifier key for French or quick dictation.

```bash
voxtype setup model                  # interactive: also download Moonshine
```

Config addition:
```toml
secondary_model = "moonshine-tiny"   # hold Shift during SUPER+T
```
paired with `--model-modifier LEFTSHIFT` in the systemd service or config.

### 3. Enable VAD (optional)

Silero VAD filters silence before transcription — reduces false starts.

```bash
voxtype setup vad
```

Add to config:
```toml
[vad]
enabled = true
threshold = 0.5
```

### 4. Update setup script for ONNX path

`run_once_after_010` needs to call `voxtype setup onnx --enable` instead of
the current Vulkan-only path. See the script for the GPU detection block to update.

---

## What's No Longer Needed

These were planned in the original implementation plan and are now obsolete:

- ❌ Private GitLab repository `voice-stt`
- ❌ Python implementation (moonshine.py, audio/capture.py, etc.)
- ❌ chezmoi external git-repo integration
- ❌ `private_dot_config/voice-stt/config.yaml.tmpl`
- ❌ Rich terminal UI / CLI framework
- ❌ `lib/scripts/` STT integration
- ❌ Custom GPU detection/model selection logic

---

## Future Phases (revised)

All future STT work is voxtype configuration, not custom development.

| Phase | Goal | Mechanism |
|-------|------|-----------|
| Engine tuning | Benchmark Parakeet vs Moonshine for daily use | `voxtype --engine` CLI flag |
| French support | Evaluate Moonshine French model vs Whisper multilingual | `language = "auto"` + secondary model |
| Meeting mode | Structured long-form transcription | `voxtype meeting` |
| TTS | Text-to-speech responses | Separate tool — see TTS_ENGINES_RESEARCH.md |
| LLM | Voice → LLM → voice pipeline | Separate integration, not STT scope |

**See**: `VOICE_STT_FUTURE_PHASES.md` is archived — content superseded by voxtype's native feature set.
