# Voxtype Research - February 2026
**Focus**: Omarchy's Voxtype dictation vs custom Voice STT plan

---

## Executive Summary

**Recommendation**: Build the custom Voice STT plan — do NOT adopt Voxtype

**Rationale**:
- Voxtype uses Whisper base.en (~300-400ms) vs plan's Moonshine (~200ms) — 33-50% slower
- Voxtype types via wtype (risky auto-insertion); plan uses clipboard (safe, explicit)
- Voxtype is a black-box binary with no extensibility
- Plan is the foundation for Phase 2-5 (TTS, LLM, streaming)
- No keybinding conflict: Voxtype uses Super+Ctrl+X, plan uses Super+T

**One pattern worth borrowing**: `bindd`/`binddr` press-to-talk interaction model as an alternative binding style.

---

## Voxtype Technical Profile

**Package**: `voxtype-bin` (AUR pre-built binary) + `wtype` (required dependency)

**Installation**:
```bash
omarchy-pkg-add wtype voxtype-bin
voxtype setup --download --no-post-install
voxtype setup systemd   # Creates systemd user service
```

**Architecture**: Systemd daemon (always running)
- Not a CLI toggle — runs as `voxtype.service`
- Hotkey sends commands to daemon: `voxtype record start` / `voxtype record stop`

**Keybinding** (`default/hypr/bindings/utilities.conf`):
```conf
bindd  = SUPER CTRL, X, Start dictation, exec, voxtype record start
binddr = SUPER CTRL, X, Stop dictation, exec, voxtype record stop
```
- `bindd` / `binddr`: press-to-record, release-to-stop (push-to-talk model)
- **No conflict** with plan's `SUPER+T` toggle

**Configuration** (`~/.config/voxtype/config.toml`):
```toml
[hotkey]
enabled = false

[audio]
device = "default"
sample_rate = 16000
max_duration_secs = 60

[whisper]
model = "base.en"
language = "en"
translate = false

[output]
mode = "type"                 # Primary: types into focused window via wtype
fallback_to_clipboard = true  # Fallback: wl-clipboard
type_delay_ms = 1
```

**Output mode**: Types text directly into the focused window via `wtype` — no paste step needed, but risky (auto-inserts into whatever is focused).

---

## Comparison Matrix

| Aspect | Voxtype | Voice STT Plan |
|--------|---------|----------------|
| **Package** | `voxtype-bin` AUR | Custom Python + chezmoi external |
| **Architecture** | Systemd daemon | CLI toggle (no daemon) |
| **Keybinding** | Super+Ctrl+X (push-to-talk) | Super+T (toggle) |
| **Output** | Types via wtype | Clipboard (clipman) |
| **STT Engine** | Whisper only | Moonshine primary + Whisper Turbo backup |
| **Default model** | base.en (~140M) | Medium Streaming (200M) |
| **Latency** | ~300-400ms | <200ms |
| **GPU profiles** | Not configurable | RTX 4090 (FP16) / RTX 1650 (INT8) |
| **Config format** | TOML (static) | YAML (chezmoi template) |
| **Extensibility** | None (binary) | Full Python source |
| **Future roadmap** | None | Phase 2-5 (TTS, LLM, RAG) |
| **Chezmoi integration** | Manual config copy | Native external git-repo + packages.yaml |

---

## Interaction Model Comparison

**Voxtype** (press-to-talk):
```
Hold Super+Ctrl+X → speak → release → text typed at cursor
```
- Pros: No latency between stop and output; hands-free not possible
- Cons: Accidental input if released in wrong window; no clipboard history

**Plan** (toggle):
```
Super+T → speak → Super+T → text in clipboard → Ctrl+V where needed
```
- Pros: Safe (explicit paste); clipboard history via clipman; Moonshine spinner feedback
- Cons: Extra paste step; requires focus management

**Potential hybrid**: Offer both modes in the plan's CLI (`--mode type` vs `--mode clipboard`).

---

## What Voxtype Handles That Plan Must Implement

Since Voxtype is a complete pre-built solution, it validates these as solved problems:

1. **PipeWire audio capture at 16kHz** — confirmed working via `sounddevice`/PipeWire
2. **Systemd user service** — valid architecture (Voxtype proves daemon model works)
3. **wtype for direct insertion** — viable alternative output mode for the plan
4. **Model download on first run** — `voxtype setup --download` pattern is ergonomic

---

## Decision: Build the Plan

Voxtype is production-ready for simple use cases. The custom plan is the right choice because:

1. **Performance**: Moonshine <200ms vs Voxtype ~300-400ms
2. **Safety**: Clipboard output vs dangerous auto-type
3. **Hardware optimization**: Per-GPU profiles (RTX 4090 FP16, RTX 1650 INT8)
4. **Future-proofed**: Phases 2-5 require Python source access (TTS, LLM, RAG)
5. **Chezmoi-native**: External git-repo + packages.yaml = reproducible across machines

**Voxtype = reference implementation, not replacement.**

---

## References

- Omarchy install script: `~/Projects/omarchy/bin/omarchy-voxtype-install`
- Omarchy remove script: `~/Projects/omarchy/bin/omarchy-voxtype-remove`
- Omarchy keybinding: `~/Projects/omarchy/default/hypr/bindings/utilities.conf` (lines 55-57)
- Omarchy config template: `~/Projects/omarchy/default/voxtype/config.toml`
- Voice STT plan: `_plans/VOICE_STT_IMPLEMENTATION_PLAN.md`
- STT models comparison: `_research/STT_MODELS_RESEARCH.md`
