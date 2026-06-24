# TTS Engines Research - February 2026
**Focus**: Text-to-speech engines for future two-way conversation
**Phase**: Future (Phase 3)

---

## Executive Summary

**Recommendation for Phase 3**: **Chatterbox** for quality, **Kokoro 82M** for lightweight

**Rationale**:
- Chatterbox: Production-grade quality, <200ms latency, MIT license
- Kokoro 82M: Extremely lightweight, Apache license, runs on RTX 1650

---

## Model Comparison Matrix

| Model | Parameters | VRAM | Latency | Quality | Emotion Control | Pros | Cons | Best For |
|--------|-----------|-------|----------|----------|----------------|-------|-------|----------|
| **Chatterbox** | 0.5B | 4-8GB | <200ms | Excellent | ✅ | Limited streaming | Production voice |
| **Kokoro 82M** | 82M | 2-4GB | Fast | Good | Limited | ✅ Lightweight | Edge/IoT |
| **Coqui XTTS v2** | ~2B | 4-8GB+ | <200ms | Very Good | ✅ | Large VRAM | Mature ecosystem |
| **Qwen3-TTS** | 1.7B | 8-12GB | ~97ms | SOTA | ✅ (NL) | Large model | Quality-critical |
| **VibeVoice** | 0.5B | 2-4GB | ~300ms | Good | ✅ | Research only | Ultra-fast |
| **Fish Speech S1** | 4B | 12-16GB | Good | SOTA | ✅ (30+) | Huge VRAM | Best quality |

---

## Chatterbox

### Repository
https://huggingface.co/ResembleAI/chatterbox

### Status
Released Sep 2024 (Chatterbox Multilingual, Turbo Dec 2025), actively maintained

### Key Features

**Model Details**:
- **Parameters**: 0.5B Llama backbone
- **License**: MIT (commercial use allowed)
- **Languages**: 23 (Arabic, Danish, German, Greek, English, Spanish, Finnish, French, Hebrew, Hindi, Italian, Japanese, Korean, Malay, Dutch, Norwegian, Polish, Portuguese, Russian, Swedish, Swahili, Turkish, Chinese)

**Performance**:
- Outperforms ElevenLabs in side-by-side evaluations
- Trained on 0.5M hours of cleaned data
- Ultra-low latency (<200ms in production)

**Voice Cloning**:
- Zero-shot voice cloning with 10-30 second samples
- Tone color cloning
- Flexible style control (emotion, accent, rhythm, pauses, intonation)

**Emotion Control**:
- Exaggeration control parameter (0-5 default)
- Built-in PerTh watermarking for responsible AI

### Hardware Requirements

**RTX 4090**:
- VRAM: ~4-8GB
- Latency: <200ms
- Quality: Production-grade

**RTX 1650**:
- VRAM: Too small for 0.5B model
- Recommendation: Use Kokoro 82M instead

### Pros

✅ Production-grade quality (comparable to ElevenLabs)
✅ Excellent emotion control
✅ Strong multilingual support (23 languages)
✅ MIT license for commercial use
✅ Ultra-low latency (<200ms)
✅ Zero-shot voice cloning

### Cons

❌ Limited streaming support in base version
❌ Requires moderate GPU resources (4-8GB VRAM)
❌ Too large for RTX 1650

---

## Kokoro 82M

### Repository
https://github.com/hexgrad/kokoro
https://huggingface.co/hexgrad/Kokoro-82M

### Status
Released Jan 27, 2025, Apache-2.0 license

### Key Features

**Model Details**:
- **Parameters**: 82M (extremely lightweight)
- **License**: Apache-2.0
- **Languages**: 54 voices across multiple languages
- **Architecture**: StyleTTS 2 + iSTFTNet

**Performance**:
- Comparable quality to larger models
- 7x faster than larger models
- Cost-effective deployment (~$0.06 per hour of audio)

**Training**:
- ~$1000 for 1000 hours of A100 80GB GPU training
- Few hundred hours of permissive/non-copyrighted audio

### Hardware Requirements

**RTX 4090**:
- VRAM: ~2-4GB
- Latency: Fast
- Quality: Good for model size

**RTX 1650**:
- VRAM: ~1-2GB (workable)
- Latency: Fast
- Quality: Acceptable

### Pros

✅ Extremely lightweight (82M params)
✅ Fast and cost-efficient inference
✅ Apache license for commercial use
✅ Good quality for model size
✅ Works on RTX 1650

### Cons

❌ Limited emotion control vs newer models
❌ Fewer voices than larger models
❌ Quality lower than Chatterbox

---

## Coqui XTTS v2

### Repository
https://github.com/coqui-ai/TTS

### Status
Released Dec 2023 (v0.22.0), battle-tested (44.5k GitHub stars)

### Key Features

**Model Details**:
- **License**: MPL-2.0
- **Languages**: 16 with streaming
- **Models**: VITS, VITS2, Glow-TTS, Tacotron2, FastPitch, FastSpeech2, YourTTS, Tortoise, Bark, Fairseq MMS (~1100 languages)

**Performance**:
- Streaming with <200ms latency
- Fine-tuning code available

**Voice Cloning**:
- YourTTS: Multi-speaker TTS with voice cloning
- XTTS v2: 16 languages, zero-shot voice cloning, emotion control

### Hardware Requirements

**RTX 4090**:
- VRAM: ~4-8GB+
- Latency: <200ms
- Quality: Very Good

**RTX 1650**:
- VRAM: Too small for XTTS v2
- Recommendation: Use Kokoro 82M

### Pros

✅ Battle-tested production TTS framework
✅ Extensive model library covering multiple architectures
✅ Streaming support for real-time applications
✅ Wide language support
✅ Mature ecosystem

### Cons

❌ Some models require significant VRAM
❌ Maintenance slower than newer alternatives
❌ Too large for RTX 1650

---

## Qwen3-TTS

### Repository
https://github.com/QwenLM/Qwen3-TTS
https://huggingface.co/Qwen/

### Status
Released Jan 2026 (arXiv:2601.15621), Apache-2.0 license

### Key Features

**Model Details**:
- **Versions**: Qwen3-TTS-12Hz-1.7B-CustomVoice, 0.6B-VoiceDesign, Base variants
- **Release**: Jan 2026
- **License**: Apache-2.0
- **Languages**: 10 major languages (Chinese, English, Japanese, Korean, German, French, Russian, Portuguese, Spanish, Italian)

**Architecture**:
- Transformer-based with Qwen3-TTS-Tokenizer-12Hz (discrete multi-codebook LM)
- Diffusion head
- Dual-track hybrid streaming

**Performance**:
- **Latency**: ~97ms end-to-end
- **Context**: Up to 8K tokens
- **Benchmarks**: Best on most language tests

**Voice Control**:
- Emotion control via natural language instructions
- Zero-shot voice cloning in 3 seconds
- CustomVoice variant with 9 premium timbres

### Benchmarks (WER on Seed-TTS, lower is better)

| Language | Qwen3-TTS | CosyVoice3 | MiniMax |
|----------|------------|--------------|----------|
| Chinese | 0.777 | 0.777 | 0.836 |
| English | 0.708 | 0.836 | 0.928 |
| German | 0.634 (best) | - | - |
| Italian | 0.948 | - | - |
| Portuguese | 1.331 | - | - |
| Spanish | 1.029 | - | - |
| Japanese | 3.519 | - | - |
| Korean | 1.741 | - | - |
| French | 3.080 | - | - |
| Russian | 4.444 | - | - |

### Hardware Requirements

**RTX 4090**:
- VRAM: ~8-12GB+
- Latency: ~97ms
- Quality: SOTA benchmarks

**RTX 1650**:
- VRAM: Too small for 1.7B model
- Recommendation: Use smaller 0.6B variant (if available)

### Pros

✅ State-of-the-art benchmarks
✅ Streaming with <100ms latency
✅ Strong emotion control via natural language instructions
✅ Multi-speaker support
✅ Zero-shot voice cloning

### Cons

❌ Large model size (1.7B) requires significant VRAM
❌ Commercial API available but self-hosted is Apache licensed

---

## VibeVoice-Realtime

### Repository
https://github.com/microsoft/VibeVoice
https://huggingface.co/microsoft/

### Status
Released Aug 2025 (Realtime 0.5B), MIT license

### Key Features

**Model Details**:
- **Parameters**: 0.5B (realtime), 1.5B (TTS 1.5B), 32K context (Large)
- **License**: MIT
- **Languages**: Primary English with experimental multilingual support
- **Architecture**: LLM-based (Qwen2.5-0.5B) + acoustic tokenizer + diffusion decoding head

**Performance**:
- **Latency**: ~300ms first audio latency
- **Streaming**: Dual-track hybrid streaming
- **Benchmarks**: Seed-TTS WER 2.00 (English)

**Features**:
- Streaming text input support
- Built-in watermarking for responsible use

### Hardware Requirements

**RTX 4090**:
- VRAM: ~2-4GB
- Latency: ~300ms
- Quality: Good

**RTX 1650**:
- VRAM: ~1.5-3GB (workable)
- Latency: ~350ms
- Quality: Acceptable

### Pros

✅ Extremely lightweight (0.5B for realtime)
✅ ~300ms first audio latency
✅ Streaming text input support
✅ MIT licensed
✅ Built-in watermarking

### Cons

❌ English-primary (other languages experimental)
❌ Research purposes only (per Microsoft)

---

## Fish Speech S1

### Repository
https://github.com/fishaudio/fish-speech

### Status
Released May 31, 2025 (v1.5.1), Apache-2.0 license

### Key Features

**Model Details**:
- **Parameters**: 4B (full), 0.5B (S1-mini)
- **License**: Apache-2.0 (code), CC-BY-NC-SA-4.0 (model weights)
- **Languages**: English, Japanese, Korean, Chinese, French, German, Spanish, Arabic, Russian, Dutch, Italian, Polish, Portuguese

**Architecture**:
- Based on VITS2 with iSTFTNet vocoder
- LLaMA backbone

**Performance**:
- **Benchmarks**: #1 on TTS-Arena2
- **WER**: 0.008, CER: 0.004 on English
- **Real-time factor**: ~1:7 on RTX 4090

**Voice Cloning**:
- Zero-shot and few-shot TTS with 10-30 second vocal sample
- Cross-lingual voice cloning
- 54+ voices available

**Emotion Control**:
- **30+ fine-grained emotions**: angry, sad, excited, surprised, satisfied, delighted, scared, worried, upset, nervous, frustrated, depressed, empathetic, embarrassed, disgusted, moved, proud, relaxed, grateful, confident, interested, curious, confused, joyful, disdainful, unhappy, anxious, hysterical, indifferent, impatient, guilty, scornful, panicked, furious, reluctant, keen, disapproving, negative, denying, astonished, serious, sarcastic, conciliative, comforting, sincere, sneering, hesitating, yielding, painful, awkward, amused
- **Tone markers**: in a hurry tone, shouting, screaming, whispering, soft tone
- **Audio effects**: laughing, chuckling, sobbing, crying loudly, sighing, panting, groaning, crowd laughing

### Hardware Requirements

**RTX 4090**:
- VRAM: ~12-16GB+ (4B model)
- Latency: Good
- Quality: SOTA (TTS-Arena2 #1)

**RTX 1650**:
- VRAM: Too small for 4B model
- Recommendation: Use S1-mini (0.5B) if available

### Pros

✅ Human-level quality (best on TTS-Arena2)
✅ Excellent emotion control (30+ emotions)
✅ Cross-lingual capability
✅ Good streaming performance
✅ Apache license (model weights)

### Cons

❌ 4B model requires significant VRAM (12-16GB+)
❌ Weights under NC license (non-commercial attribution required)
❌ Too large for RTX 1650

---

## Quality Benchmarks

### TTS-Arena2 Rankings

**Top Rankings** (as of early 2026):
1. **FishAudio-S1** - #1 with Elo rating
2. **VibeVoice-Realtime-0.5B**
3. **Qwen3-TTS-12Hz-1.7B-CustomVoice**
4. **CosyVoice3**
5. **VALL-E2**
6. **MiniMax-Speech**
7. **Chatterbox**

### Word Error Rate (WER) Comparison

| Model | WER (lower better) | Quality Rating |
|-------|------------------|---------------|
| Fish Speech S1 | 0.008 | SOTA |
| Qwen3-TTS | 0.708 (English) | SOTA |
| VibeVoice | 2.00 (English) | Very Good |
| Chatterbox | Unknown | Excellent |
| Coqui XTTS v2 | Unknown | Very Good |
| Kokoro 82M | Unknown | Good |

---

## Real-Time Performance

| Model | First Audio Latency | Real-Time Factor | VRAM | Quality | Use Case |
|-------|-------------------|-----------------|-------|----------|----------|
| VibeVoice-Realtime | ~300ms | ~3.3x | 2-4GB | Good | Real-time streaming |
| Chatterbox | <200ms | ~5x | 4-8GB | Excellent | Production voice |
| Coqui XTTS v2 | <200ms | ~5x | 4-8GB+ | Very Good | Production voice |
| Qwen3-TTS | ~97ms | ~10x | 8-12GB+ | SOTA | Quality-critical |
| Kokoro 82M | <100ms | ~10x | 2-4GB | Good | Edge/Low-resource |

---

## Voice Cloning Comparison

| Model | Voice Cloning | Sample Length | Zero-Shot | Cross-Lingual | Pros |
|-------|---------------|---------------|-----------|---------------|------|
| Chatterbox | ✅ Tone color | 10-30s | ✅ | ✅ | Production-grade |
| Fish Speech S1 | ✅ Full | 10-30s | ✅ | ✅ | 30+ emotions |
| Coqui XTTS v2 | ✅ Full | Variable | ✅ | ✅ | Mature ecosystem |
| Qwen3-TTS | ✅ Voice Design | 3s | ✅ | ✅ | NL instruction control |
| Kokoro 82M | ❌ Limited | - | - | - | Lightweight |

---

## Emotion Control Comparison

| Model | Emotion Control | Granularity | Method | Pros |
|-------|----------------|-------------|---------|------|
| Fish Speech S1 | ✅ Excellent | 30+ emotions + tone markers + audio effects | Built-in | Most expressive |
| Qwen3-TTS | ✅ Excellent | Natural language instructions | NL input | Flexible |
| Chatterbox | ✅ Good | Exaggeration parameter (0-5) | Built-in | Simple |
| Coqui XTTS v2 | ✅ Good | Emotion parameter | Built-in | Mature |
| VibeVoice | ✅ Good | Built-in | Built-in | Research quality |
| Kokoro 82M | ❌ Limited | - | - | Lightweight |

---

## Language Support

| Model | Languages | Multilingual? | License |
|-------|-----------|--------------|----------|
| Chatterbox | 23 | Yes (single model) | MIT |
| Coqui XTTS v2 | 16 | Yes (single model) | MPL-2.0 |
| Qwen3-TTS | 10 | Yes (single model) | Apache-2.0 |
| VibeVoice | English (primary) | Partial (experimental) | MIT |
| Fish Speech S1 | 14+ | Yes (single model) | Apache-2.0 (NC) |
| Kokoro 82M | 54 voices | Yes | Apache-2.0 |

---

## Hardware Compatibility

### RTX 4090

| Model | VRAM | Latency | Quality | Recommended |
|-------|-------|----------|----------|-------------|
| Chatterbox | 4-8GB | <200ms | Excellent | ✅ Production |
| Qwen3-TTS 1.7B | 8-12GB+ | ~97ms | SOTA | ✅ Quality-critical |
| Fish Speech S1 (4B) | 12-16GB+ | Good | SOTA | ⚠️ Extreme VRAM |
| VibeVoice-Realtime | 2-4GB | ~300ms | Good | ✅ Fast |
| Kokoro 82M | 2-4GB | <100ms | Good | ✅ Lightweight |

### RTX 1650

| Model | VRAM | Latency | Quality | Recommended |
|-------|-------|----------|----------|-------------|
| Kokoro 82M | 1-2GB | <100ms | Good | ✅ Primary |
| VibeVoice-Realtime | 1.5-3GB | ~350ms | Good | ✅ Secondary |
| Chatterbox | Too small | - | - | ❌ Not workable |
| Qwen3-TTS | Too small | - | - | ❌ Not workable |
| Fish Speech S1 | Too small | - | - | ❌ Not workable |

---

### Chatterbox
```bash
pip install chatterbox-tts
```

### Coqui TTS
```bash
pip install TTS
```

### Kokoro
```bash
pip install -q kokoro>=0.9.2 soundfile
apt-get install espeak-ng
```

### Qwen3-TTS
```bash
pip install -U qwen-tts

# Optional FlashAttention 2
pip install -U flash-attn --no-build-isolation
```

### Fish Speech
```bash
pip install fish-speech

# Or with Docker
docker compose up
```

---

## Recommendations

### For Phase 3 (Two-Way Conversation)

**RTX 4090 (Primary)**:
1. **Primary**: **Chatterbox** - Production-grade quality, MIT license
2. **Backup**: **Qwen3-TTS 1.7B** - SOTA quality, streaming

**RTX 1650 (Laptop)**:
1. **Primary**: **Kokoro 82M** - Lightweight, Apache license, runs on 4GB VRAM
2. **Backup**: **VibeVoice-Realtime** - Ultra-fast, MIT license

### Quality vs Speed Trade-off

| Priority | Model | Latency | Quality | VRAM |
|----------|-------|----------|----------|-------|
| Maximum quality | Qwen3-TTS 1.7B | ~97ms | SOTA | 8-12GB+ |
| Production quality | Chatterbox | <200ms | Excellent | 4-8GB |
| Fast real-time | VibeVoice-Realtime | ~300ms | Good | 2-4GB |
| Lightweight | Kokoro 82M | <100ms | Good | 2-4GB |

---

## Future Considerations

### Streaming Capabilities
- **Phase 3**: Add streaming TTS for real-time feedback
- **Latency Target**: <200ms end-to-end
- **Approach**: Use Chatterbox Turbo or VibeVoice-Realtime

### Voice Cloning
- **Phase 4**: Add custom voice support
- **Approach**: Use Fish Speech S1 or Qwen3-TTS voice design
- **Requirements**: 10-30s sample, ~100MB storage per voice

### Multi-Model Support
- **Phase 5**: Switch between TTS models dynamically
- **Configuration**: GPU profile-based selection
- **Fallback**: Auto-select based on VRAM availability

---

## Summary

**Phase 3 Recommendation**: **Chatterbox** (RTX 4090) + **Kokoro 82M** (RTX 1650)

**Why**:
- Chatterbox: Production-grade quality, MIT license, excellent emotion control
- Kokoro 82M: Lightweight, Apache license, runs on RTX 1650
- Both support streaming for real-time conversation
- Good balance of quality and speed

---

## References

- Chatterbox: https://huggingface.co/ResembleAI/chatterbox
- Coqui TTS: https://github.com/coqui-ai/TTS
- Kokoro: https://github.com/hexgrad/kokoro
- Qwen3-TTS: https://github.com/QwenLM/Qwen3-TTS
- VibeVoice: https://github.com/microsoft/VibeVoice
- Fish Speech: https://github.com/fishaudio/fish-speech
- TTS-Arena2: https://arena.speechcolab.org/
- Qwen3-TTS Paper: https://arxiv.org/abs/2601.15621
