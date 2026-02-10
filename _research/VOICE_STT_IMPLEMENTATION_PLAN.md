# Voice STT Implementation Plan

**Date**: February 10, 2026
**Target**: CLI-based speech-to-text tool for Arch Linux + Hyprland

---

## Project Status

**Research Phase**: ✅ Complete
**Implementation Phase**: ⏳ Pending (awaiting GitLab repo creation)
**Current Blocker**: User needs to create private GitLab repository `voice-stt`

**Estimated Timeline**: 8-10 days for Phase 1 (core STT implementation)

---

## Executive Summary

Building a local-first voice-to-text CLI tool using modern STT models with the following characteristics:

- **Primary**: Moonshine Medium Streaming (200M params, <200ms latency)
- **Backup**: Whisper Turbo (809M params, 8x faster than Large V3)
- **Hardware**: Optimized for RTX 4090 (primary) and RTX 1650 (laptop)
- **Architecture**: Hybrid chezmoi external git-repo + local data
- **UI**: CLI with Rich terminal formatting, spinner feedback
- **Integration**: Hyprland hotkey (SUPER+T), Wayland clipboard, dunst notifications
- **Scope**: First iteration - STT only, future-proofed for TTS/LLM addition

---

## Table of Contents

1. [Technology Stack](#technology-stack)
2. [Repository Architecture](#repository-architecture)
3. [Implementation Phases](#implementation-phases)
4. [Hardware Compatibility](#hardware-compatibility)
5. [Chezmoi Integration](#chezmoi-integration)
6. [Testing Strategy](#testing-strategy)
7. [Documentation Plan](#documentation-plan)

**For Research**: See separate research files:

- STT_MODELS_RESEARCH.md - STT engine comparison and benchmarks
- FUTURE_PHASES.md - Phase 2+ implementation patterns and TTS/LLM frameworks

---

## Technology Stack

### Core Components

| Component         | Choice                                     | Reason                                                                                                        |
| ----------------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| **STT Engine**    | Moonshine Medium Streaming                 | Purpose-built for real-time, <200ms latency, better accuracy than Whisper Large V3 with 7.5x fewer parameters |
| **Backup STT**    | Whisper Turbo                              | Mature ecosystem, 8x faster than Large V3, excellent multilingual support                                     |
| **CLI Framework** | Rich                                       | Terminal formatting, progress bars, status indicators, spinner support                                        |
| **Audio Backend** | PipeWire (primary), ALSA (fallback)        | Native to Hyprland ecosystem, better Wayland support                                                          |
| **VAD**           | Built-in Moonshine VAD                     | Eliminates dependencies, optimized integration                                                                |
| **Clipboard**     | clipman (primary), wl-clipboard (fallback) | Wayland-native, clipboard history support                                                                     |
| **Notifications** | dunst                                      | Already in dotfiles, Wayland-compatible                                                                       |
| **Config Format** | YAML                                       | Human-readable, chezmoi template-friendly                                                                     |
| **Python Deps**   | pyav, sounddevice, rich, pyyaml            | Audio I/O, terminal UI, config management                                                                     |

### Performance Characteristics

**RTX 4090 (Primary)**:

- Moonshine Medium: ~3GB VRAM, <200ms latency, 55-70 tokens/sec
- Whisper Turbo: ~6GB VRAM, ~250ms latency, 45-60 tokens/sec

**RTX 1650 (Laptop)**:

- Moonshine Small: ~2GB VRAM, ~300ms latency, 30-40 tokens/sec
- Whisper Turbo INT8: ~2GB VRAM, ~400ms latency, 25-35 tokens/sec

---

## Repository Architecture

### Component 1: voice-stt GitLab Repository

**Location**: Private GitLab (you'll create)
**Path**: `~/.local/share/voice-stt/`
**Purpose**: Application code (version controlled)

```
voice-stt/
├── .git/                          # Git version control
├── lib/
│   ├── __init__.py
│   ├── main.py                      # CLI entry point
│   ├── audio/
│   │   ├── __init__.py
│   │   ├── capture.py               # PipeWire audio capture
│   │   └── vad.py                   # VAD interface
│   ├── stt/
│   │   ├── __init__.py
│   │   ├── base.py                  # Abstract STT interface
│   │   └── moonshine.py            # Moonshine implementation
│   ├── output/
│   │   ├── __init__.py
│   │   ├── formatter.py             # Text formatting
│   │   └── clipboard.py             # clipman + wl-clipboard
│   └── config/
│       ├── __init__.py
│       ├── models.py                # Model definitions
│       └── loader.py               # Config loader
├── bin/
│   └── voice-stt                   # Main executable (755)
├── venv/                           # Python virtual environment (excluded)
├── install.sh                      # Installation script
├── requirements.txt                 # Python dependencies
├── pyproject.toml                  # Python package metadata
├── README.md                       # Basic usage guide
└── .gitignore                      # Exclude venv, data, cache
```

### Component 2: Chezmoi Dotfiles

**Location**: Existing chezmoi repo
**Purpose**: Configuration and integration

```
~/.local/share/chezmoi/
├── private_dot_config/voice-stt/
│   └── config.yaml.tmpl            # User settings template
├── private_dot_config/hypr/conf/bindings/
│   └── voice-stt.conf             # Hyprland keybindings (NEW)
└── .chezmoiexternal.toml            # External git-repo integration
```

### Component 3: Application Data

**Location**: `~/.local/share/voice-stt-data/`
**Purpose**: Models, cache, sessions (excluded from git)

```
voice-stt-data/
├── models/                          # Downloaded STT models
├── cache/                           # Model cache, temporary files
├── sessions/                         # Optional: Saved transcripts (future)
└── logs/                            # Error logs (optional)
```

---

## Implementation Phases

### Phase 1: Repository Setup (Day 1)

**Objectives**:

- Create private GitLab repository
- Set up directory structure
- Create configuration files
- Write documentation

**Tasks**:

1. [ ] Create GitLab repository `voice-stt`
2. [ ] Create directory structure
3. [ ] Write `requirements.txt` with dependencies
4. [ ] Write `pyproject.toml` with project metadata
5. [ ] Create `.gitignore` (exclude venv, models, cache)
6. [ ] Write `README.md` with basic usage instructions
7. [ ] Initialize Git repository

**Deliverables**:

- Ready-to-clone GitLab repository
- Basic documentation
- Python package structure

---

### Phase 2: Core STT Implementation (Day 2-4)

**Objectives**:

- Implement audio capture (PipeWire)
- Implement Moonshine STT wrapper
- Implement clipboard integration
- Create CLI with Rich UI

**Tasks**:

#### Day 2: Audio & Config

- [ ] Implement `lib/audio/capture.py` (PipeWire integration)
  - 16kHz mono recording
  - Chunk-based streaming (200-500ms)
  - ALSA fallback detection
  - Error handling (mic disconnected)
- [ ] Implement `lib/config/loader.py`
  - YAML config loading
  - Default configuration
  - Validation

#### Day 3: STT Engine

- [ ] Implement `lib/stt/base.py`
  - Abstract STT interface
  - Common methods: `transcribe()`, `cleanup()`
- [ ] Implement `lib/stt/moonshine.py`
  - Moonshine Transcriber wrapper
  - Line completion events
  - Auto language detection
  - Error handling

#### Day 4: Output & CLI

- [ ] Implement `lib/output/clipboard.py`
  - clipman primary
  - wl-clipboard fallback
  - Error handling
- [ ] Implement `lib/output/formatter.py`
  - Text, markdown, JSON output
  - Timestamp formatting (future)
- [ ] Implement `lib/main.py`
  - argparse CLI
  - Rich console setup
  - Spinner status
  - Toggle logic

**Deliverables**:

- Working STT transcription
- CLI with Rich UI
- Clipboard integration

---

### Phase 3: Chezmoi Integration (Day 5)

**Objectives**:

- Integrate with chezmoi external system
- Add Hyprland keybindings
- Create configuration templates
- Update packages.yaml

**Tasks**:

- [ ] Create `.chezmoiexternal.toml` in chezmoi repo
  - git-repo type
  - GitLab URL
  - Refresh period (168h)
- [ ] Create `private_dot_config/hypr/conf/bindings/voice-stt.conf`
  - SUPER+T hotkey
  - toggle command
- [ ] Update `private_dot_config/hypr/hyprland.conf.tmpl`
  - Add voice-stt.conf sourcing
- [ ] Create `private_dot_config/voice-stt/config.yaml.tmpl`
  - Full user configuration
  - chezmoi template variables
- [ ] Update `.chezmoidata/packages.yaml`
  - Add voice_stt module
  - Python, audio, STT packages

**Deliverables**:

- Complete chezmoi integration
- Hyprland keybinding (SUPER+T)
- Automatic installation workflow

---

### Phase 4: Testing & Refinement (Day 6-7)

**Objectives**:

- Test on RTX 4090
- Verify all features work end-to-end
- Refine error handling
- Optimize performance

**Tasks**:

#### Day 6: RTX 4090 Testing

- [ ] Test installation via `chezmoi apply`
  - Verify external git-repo clone
  - Verify dependency installation
  - Verify venv creation
- [ ] Test audio capture
  - Test PipeWire microphone access
  - Verify 16kHz sampling
  - Test chunk recording
- [ ] Test Moonshine transcription
  - Verify model download
  - Test English transcription
  - Test French transcription (auto-detect)
  - Measure latency
- [ ] Test clipboard integration
  - Verify clipman copy
  - Verify wl-clipboard fallback
- [ ] Test hotkey (SUPER+T)
  - Verify start/stop behavior
  - Verify spinner UI
  - Verify dunst notifications
- [ ] Test error handling
  - Test with mic disconnected
  - Test with no GPU
  - Test with OOM

#### Day 7: Refinement

- [ ] Optimize VAD parameters
  - Adjust speech/silence thresholds
  - Test in different environments
- [ ] Improve error messages
  - Add helpful hints
  - Suggest solutions
- [ ] Performance profiling
  - Measure end-to-end latency
  - Profile GPU memory usage
- [ ] Documentation updates
  - Update README with tested commands
  - Add troubleshooting section

**Deliverables**:

- Fully tested RTX 4090 setup
- Optimized configuration
- Comprehensive documentation

---

### Phase 5: Documentation & Handoff (Day 8-10)

**Objectives**:

- Complete documentation
- Prepare for RTX 1650 testing
- Document future enhancement paths

**Tasks**:

- [ ] Update `README.md`
  - Add installation instructions
  - Add usage examples
  - Add troubleshooting guide
- [ ] Create `CONFIGURATION.md`
  - Document all config options
  - Explain GPU profiles
  - Show examples
- [ ] Create `TROUBLESHOOTING.md`
  - Common issues
  - Solutions
  - Debug commands
- [ ] Create `ROADMAP.md`
  - Phase 1 complete (STT)
  - Phase 2 (TTS addition)
  - Phase 3 (LLM integration)
  - Phase 4 (Streaming UI)

**Deliverables**:

- Complete documentation set
- Clear roadmap for enhancements
- Handoff for laptop testing

---

## Hardware Compatibility

### RTX 4090 (Primary - Desktop)

**GPU Specs**:

- VRAM: 24GB GDDR6X
- Compute Capability: 8.9 (Blackwell)
- CUDA: 12.x support

**Recommended Configuration**:

- STT Engine: Moonshine Medium Streaming (primary), Whisper Turbo (backup)
- Model: medium-streaming (200M params)
- Precision: FP16 (full precision)
- Chunk Duration: 200-500ms
- Expected Latency: 150-250ms
- VRAM Usage: ~3-4GB

**Performance Targets**:

- End-to-end latency: <250ms
- Transcription quality: Better than Whisper Large V3
- Language detection: Auto (English/French)

| Metric                | Target                       | Measurement Method            |
| --------------------- | ---------------------------- | ----------------------------- |
| End-to-end latency    | <250ms                       | Audio capture → transcription |
| Transcription quality | Better than Whisper Large V3 | WER comparison                |
| VRAM usage            | ~3GB                         | nvidia-smi                    |
| First token latency   | <100ms                       | Moonshine timing              |

### RTX 1650 (Secondary - Laptop)

**GPU Specs**:

- VRAM: 4GB GDDR5
- Compute Capability: 7.5 (Turing)
- CUDA: 11.8+ support

**Recommended Configuration**:

- STT Engine: Moonshine Small Streaming (primary), Whisper Turbo INT8 (backup)
- Model: small-streaming
- Precision: INT8 quantization
- Chunk Duration: 500-800ms
- Expected Latency: 400-600ms
- VRAM Usage: ~2-3GB

**Performance Targets**:

- End-to-end latency: <600ms
- Transcription quality: Good for dictation
- Language detection: Auto

| Metric                | Target                | Measurement Method            |
| --------------------- | --------------------- | ----------------------------- |
| End-to-end latency    | <600ms                | Audio capture → transcription |
| Transcription quality | Good for dictation    | User testing                  |
| VRAM usage            | ~2GB                  | nvidia-smi                    |
| Stability             | No thermal throttling | nvidia-smi monitoring         |

### GPU Detection & Auto-Selection

**Detection Logic**:

```python
import subprocess

def detect_gpu():
    result = subprocess.run(
        ["nvidia-smi", "--query-gpu=name,memory.total"],
        capture_output=True, text=True
    )
    # Parse and return GPU info
    return {"name": "...", "vram_gb": 24}
```

**Model Selection**:

```python
GPU_PROFILES = {
    "rtx4090": {
        "preferred_models": ["medium-streaming"],
        "precision": "float16"
    },
    "rtx1650": {
        "preferred_models": ["small-streaming", "tiny-streaming"],
        "precision": "int8"
    }
}
```

---

## Chezmoi Integration

### Chezmoi Integration Commands

#### Initial Setup

```bash
# Apply all changes (downloads voice-stt from GitLab, installs dependencies)
chezmoi apply
```

#### Update Voice STT

```bash
# Force refresh externals (git pull voice-stt repo)
chezmoi -R apply
```

#### Check Configuration

```bash
# View rendered configuration
chezmoi cat ~/.config/voice-stt/config.yaml
```

#### Test Template

```bash
# Validate template syntax
chezmoi execute-template < private_dot_config/voice-stt/config.yaml.tmpl
```

### External Git Repository

**`.chezmoiexternal.toml`**:

```toml
["voice-stt"]
type = "git-repo"
url = "https://gitlab.com/amaury/voice-stt.git"
refreshPeriod = "168h"  # Update once per week
```

**How It Works**:

1. First run: `git clone` to `~/.local/share/voice-stt/`
2. Update: `git pull` every 168h or with `-R` flag
3. Force update: `chezmoi -R apply`

### Hyprland Keybindings

**`private_dot_config/hypr/conf/bindings/voice-stt.conf`**:

```conf
# ============================================================================
# Voice STT - Speech-to-Text Transcription
# ============================================================================
bindd = SUPER, T, Toggle STT transcription, exec, voice-stt toggle
```

**Integration into `hyprland.conf.tmpl`**:

```conf
# ... after desktop-utilities.conf ...
source = ~/.config/hypr/conf/bindings/voice-stt.conf
# ... before windowrules.conf ...
```

### Configuration Template

**`private_dot_config/voice-stt/config.yaml.tmpl`**:

```yaml
# Voice STT Configuration
# Managed by chezmoi template

stt:
  engine: "moonshine"
  language: "auto"
  moonshine:
    model: "medium-streaming"
    cache_enabled: true

audio:
  sample_rate: 16000
  channels: 1
  chunk_duration_ms: 500
  device: "pipewire"
  vad:
    enabled: true
    min_speech_duration_ms: 250
    min_silence_duration_ms: 500

output:
  format: "text"
  auto_copy_to_clipboard: true
  clipboard:
    primary: "clipman"
    fallback: "wl-clipboard"

hotkeys:
  enabled: true
  toggle_binding: "SUPER+T"

performance:
  auto_detect_gpu: true
  auto_select_model: true
  gpu_profiles:
    rtx4090:
      preferred_models: ["medium-streaming"]
      compute_precision: "float16"
    rtx1650:
      preferred_models: ["small-streaming"]
      compute_precision: "int8"

paths:
  models: "{{ .chezmoi.dataDir }}/voice-stt-data/models"
  cache: "{{ .chezmoi.dataDir }}/voice-stt-data/cache"

notifications:
  enabled: true
  daemon: "dunst"
```

### Package Dependencies

**`.chezmoidata/packages.yaml`**:

```yaml
voice_stt:
  enabled: true
  description: "Speech-to-text CLI tool (Moonshine)"
  packages:
    - python
    - python-pip
    - pipewire
    - pipewire-pulse
    - wireplumber
    - python-pyav
    - python-sounddevice
    - python-rich
    - python-pyyaml
    - clipman
    - wl-clipboard
    - python-moonshine-voice
    - dunst
```

---

## Testing Strategy

### RTX 4090 Testing (Primary)

**Test Checklist**:

- [ ] Installation via `chezmoi apply`
  - Verify external git-repo clone
  - Verify venv creation
  - Verify dependency installation
- [ ] Audio capture
  - Test PipeWire microphone access
  - Verify 16kHz sampling
  - Test chunk recording (200-500ms)
- [ ] Moonshine transcription
  - Verify model download
  - Test English transcription
  - Test French transcription (auto-detect)
  - Measure end-to-end latency
- [ ] Clipboard integration
  - Verify clipman copy
  - Verify text appears in clipboard
  - Test wl-clipboard fallback
- [ ] Hotkey (SUPER+T)
  - Verify start behavior
  - Verify stop behavior
  - Test multiple toggles
- [ ] Rich UI
  - Verify spinner display
  - Verify status updates
  - Verify error formatting
- [ ] Dunst notifications
  - Verify transcription complete notification
  - Verify error notifications
  - Verify icon display
- [ ] Error handling
  - Test with microphone disconnected
  - Test with no GPU
  - Test with OOM
  - Verify stop and notify behavior

### RTX 1650 Testing (Secondary - Post Phase 5)

**Test Checklist** (same as RTX 4090, plus):

- [ ] INT8 quantization
- [ ] Small streaming model
- [ ] VRAM usage optimization
- [ ] Thermal throttling detection

---

## Documentation Plan

### README.md (Phase 5)

**Structure**:

- Features list
- Installation instructions (chezmoi apply)
- Usage examples (voice-stt toggle, SUPER+T hotkey)
- Configuration reference
- Troubleshooting guide
- Links to detailed docs

---

## Summary

**Phase 1 Status**: Ready to begin implementation

**Timeline**: 8-10 days for Phase 1 (core STT implementation)

**Phase 1 Deliverable**:

- Working voice STT CLI with Moonshine
- Rich terminal UI with spinner feedback
- Wayland clipboard integration (clipman + wl-clipboard fallback)
- Hyprland hotkey integration (SUPER+T)
- Dunst notifications
- Chezmoi integration workflow
- Testing on RTX 4090

**Phase 1 Scope**:

- Moonshine Medium Streaming STT engine
- PipeWire audio capture
- CLI with Rich terminal formatting
- Clipboard-only output (no file saving yet)
- Auto language detection (English/French)
- GPU auto-detection (RTX 4090/1650)
- Error handling (stop and notify)
- Basic configuration via YAML template

**Future Phases**: See FUTURE_PHASES.md for Phase 2+ details

---

**Next Steps**:

1. Create GitLab repository `voice-stt`
2. Begin Phase 1 implementation (Repository Setup)
3. Follow implementation plan through phases 2-5
4. Test on RTX 4090
5. Prepare for RTX 1650 testing (post Phase 5)

## References

### Documentation Links

- Moonshine: https://github.com/moonshine-ai/moonshine
- Whisper: https://github.com/openai/whisper
- Rich: https://github.com/Textualize/rich
- Chezmoi: https://www.chezmoi.io/user-guide/include-files-from-elsewhere/
- Hyprland: https://wiki.hyprland.org/

### Research Sources

- Modal Open-Source STT Blog: https://modal.com/blog/open-source-stt
- Northflank STT Benchmarks 2026: https://northflank.com/blog/best-open-source-speech-to-text-stt-model-in-2026-benchmarks

### Implementation References

- Voice STT Future Phases: See FUTURE_PHASES.md
- STT Models Research: See STT_MODELS_RESEARCH.md
- CLI Implementation Patterns: See FUTURE_PHASES.md
- Audio Processing: See FUTURE_PHASES.md
