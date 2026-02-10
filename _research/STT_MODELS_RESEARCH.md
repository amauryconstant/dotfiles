# STT Models Research - February 2026
**Focus**: Speech-to-text engines for local voice dictation

---

## Executive Summary

**Recommendation**: **Moonshine Medium Streaming** for Phase 1

**Rationale**:
- Purpose-built for real-time streaming (no 30s window)
- Better accuracy than Whisper Large V3 with 7.5x fewer parameters
- <200ms latency (vs Whisper's 200ms+ minimum)
- Built-in VAD and caching
- Active development (released 2025)

**Backup Option**: **Whisper Turbo** for mature ecosystem fallback

---

## Model Comparison Matrix

| Model | Parameters | VRAM | Latency | Accuracy | Pros | Cons | Best For |
|--------|-----------|-------|----------|-----------|-------|----------|
| **Moonshine Medium** | 200M | ~3GB | <200ms | Better than Large V3 | Newer ecosystem | Real-time dictation |
| **Whisper Turbo** | 809M | ~6GB | ~250ms | Within 1% of Large V3 | Not streaming-optimized | Mature fallback |
| **faster-whisper** | Variable | ~4.5GB | ~200ms | 4x faster, INT8 | Not streaming | Batch processing |
| **whisper.cpp** | Variable | ~1.5GB | ~200ms | CPU-optimized | Less Python-friendly | Edge devices |

---

## Moonshine

### Repository
https://github.com/moonshine-ai/moonshine

### Status
Released Sep 2024, actively maintained

### Key Features

**Streaming Architecture**:
- Flexible input windows (no fixed 30s limit)
- Incremental caching for streaming
- Eliminates redundant compute on repeated audio

**Models Available**:
- **Medium Streaming** (200M params): Recommended for RTX 4090
- **Small Streaming**: Recommended for RTX 1650
- **Tiny Streaming** (26M params): Edge/IoT

**Languages Supported**:
- English, Spanish, Mandarin, Japanese, Korean, Vietnamese, Ukrainian, Arabic
- Separate models per language

**Performance Metrics**:
- **WER**: Lower than Whisper Large V3
- **Latency**: 0ms streaming latency (audio → text)
- **Real-Time Factor**: ~5-10x real-time

**Built-in Features**:
- Voice Activity Detection (VAD)
- Intent recognition
- Line completion events
- Cross-platform (Python, C++, Swift, Java, Go, Rust, WebAssembly)



### Hardware Requirements

**RTX 4090**:
- Model: Medium Streaming (200M)
- VRAM: ~3GB
- Latency: <200ms
- Precision: FP16

**RTX 1650**:
- Model: Small Streaming
- VRAM: ~2GB
- Latency: ~300ms
- Precision: INT8 recommended

### Pros

✅ Purpose-built for real-time (streaming-first design)
✅ Better accuracy than Whisper Large V3
✅ Built-in VAD and caching
✅ Cross-platform support
✅ Active development
✅ Lower VRAM requirements
✅ <200ms latency

### Cons

❌ Newer ecosystem, fewer community examples
❌ Multilingual models require separate downloads
❌ Less mature documentation
❌ Limited third-party tools

---

## Whisper Turbo

### Repository
https://github.com/openai/whisper

### Status
Released 2023, mature, stable, massive ecosystem

### Key Features

**Model Details**:
- **Parameters**: 809M
- **Optimization**: 8x faster than Large V3
- **Accuracy**: Within 1% of Large V3
- **Trade-off**: No translation support (Turbo-only limitation)

**Languages Supported**:
- 99+ languages (single model)
- Excellent multilingual support

**Performance Metrics**:
- **WER**: ~7.75% (vs Large V3: ~7.4%)
- **Latency**: ~250ms (better than Large V3's 2s+)
- **Real-Time Factor**: ~5-8x



### Hardware Requirements

**RTX 4090**:
- VRAM: ~6GB
- Latency: ~250ms
- Precision: FP16

**RTX 1650**:
- VRAM: ~2GB (INT8 quantization)
- Latency: ~400ms
- Precision: INT8 required

### Pros

✅ Mature, well-documented
✅ Massive community support
✅ Multilingual in single model
✅ Translation capability (other models)
✅ Extensive tooling ecosystem
✅ Reliable and stable

### Cons

❌ Not optimized for streaming (30s window)
❌ Higher VRAM requirements
❌ Redundant compute on overlapping chunks
❌ Latency higher than Moonshine

---

## faster-whisper

### Repository
https://github.com/SYSTRAN/faster-whisper

### Status
Actively maintained, production-ready

### Key Features

**Backend**: CTranslate2 (optimized transformer inference)

**Performance**:
- Up to 4x faster than openai/whisper
- Batched transcription: 8x faster for multiple files
- Efficient memory usage

**Features**:
- INT8 quantization support
- Built-in Silero VAD
- Word-level timestamps
- Generator-based API (lazy evaluation)
- Batched inference pipeline



### Benchmarks (13-min audio on RTX 3070 Ti 8GB)

| Implementation | Precision | Beam | Time | VRAM |
|---------------|-----------|------|------|-------|
| openai/whisper | fp16 | 5 | 2m23s | 4708MB |
| whisper.cpp | fp16 | 5 | 1m05s | 4127MB |
| faster-whisper | fp16 | 5 | 1m03s | 4525MB |
| faster-whisper (batch=8) | fp16 | 5 | **17s** | 6090MB |
| faster-whisper (int8) | int8 | 5 | 59s | 2926MB |

### Hardware Requirements

**RTX 4090**:
- VRAM: ~4.5GB (FP16)
- Speed: 55-70 tokens/sec

**RTX 1650**:
- VRAM: ~2.5GB (INT8)
- Speed: 25-35 tokens/sec

### Pros

✅ 4x faster than openai/whisper
✅ INT8 quantization for memory savings
✅ Batched transcription for throughput
✅ Built-in VAD via Silero
✅ Word-level timestamps
✅ Generator-based API (lazy evaluation)

### Cons

❌ Not streaming-optimized (30s window)
❌ Slightly less mature than Whisper
❌ GPU backend complexity (CUDA 12/11 versioning)

---

## whisper.cpp

### Repository
https://github.com/ggml-org/whisper.cpp

### Status
Very active, pure C/C++ implementation

### Key Features

**Implementation**: Pure C/C++ using ggml tensor library

**Performance**:
- Zero runtime memory allocations
- CPU-optimized (AVX, AVX2, AVX512, NEON)
- 4x faster than original Whisper

**Backends**:
- CUDA 12/13 (NVIDIA)
- HIP (AMD ROCm 5.0+)
- Metal (Apple Silicon)
- Vulkan
- OpenVINO (Intel)
- SYCL
- WebGPU

**Quantization**:
- Q2_K, Q3_K, Q4_0, Q4_K_M, Q5_K_M, Q6_K, Q8_0, Q8_0_F16



### Memory Usage

| Model | Disk | RAM |
|-------|------|-----|
| tiny | 75MB | ~273MB |
| base | 142MB | ~388MB |
| small | 466MB | ~852MB |
| medium | 1.5GB | ~2.1GB |
| large | 2.9GB | ~3.9GB |

### Hardware Requirements

**RTX 4090**:
- VRAM: ~1.5GB (Q4 quantization)
- CPU: 55-70 tokens/sec

**RTX 1650**:
- VRAM: Too small for good models
- CPU: ~10-15 tokens/sec (quantized)

### Pros

✅ Zero runtime allocations
✅ CPU-optimized (AVX, AVX2, AVX512)
✅ Multiple GPU backends
✅ Integer quantization support (Q2-Q8)
✅ Pure C/C++, minimal dependencies
✅ Cross-platform support
✅ Small disk footprint

### Cons

❌ Python bindings less mature
❌ No built-in streaming (30s chunks)
❌ Less developer-friendly
❌ Requires more setup than Python options

---

## Recommendation for Voice STT

### Primary: Moonshine Medium Streaming

**Use when**:
- Real-time dictation is required
- Low latency (<200ms) is critical
- Single language focus is acceptable
- Streaming architecture is beneficial

### Backup: Whisper Turbo

**Use when**:
- Moonshine unavailable
- Need broader language support (99+ languages)
- Need translation capability
- Mature ecosystem with extensive tooling is required

### Alternative: faster-whisper

**Use when**:
- Batch transcription of multiple files
- Need word-level timestamps
- INT8 quantization for memory savings
- High-throughput processing is needed

### Edge Device: whisper.cpp

**Use when**:
- Running on CPU or limited GPU
- Minimal memory footprint required
- Cross-platform deployment is needed
- Pure C/C++ implementation is preferred

---

## Performance Comparison (RTX 4090)

| Model | Parameters | VRAM | Latency | Accuracy | Tokens/sec | Use Case |
|-------|-----------|-------|----------|-----------|------------|----------|
| Moonshine Medium | 200M | ~3GB | <200ms | Best than Large V3 | 55-70 | Real-time dictation |
| Whisper Turbo | 809M | ~6GB | ~250ms | -1% vs Large V3 | 45-60 | Mature fallback |
| faster-whisper | Variable | ~4.5GB | ~200ms | Same as Large V3 | 55-70 | Batch processing |
| whisper.cpp (Q4) | Variable | ~1.5GB | ~200ms | Same as Large V3 | 55-70 | Edge/CPU |

---

## Language Support

| Model | English | French | Spanish | Other | Multilingual? |
|-------|---------|---------|---------|-------|--------------|
| Moonshine | ✅ (en) | ❌ | ✅ (es) | 8 langs | No (separate models) |
| Whisper Turbo | ✅ | ✅ | ✅ | 99+ langs | Yes (single model) |
| faster-whisper | ✅ | ✅ | ✅ | 99+ langs | Yes (single model) |
| whisper.cpp | ✅ | ✅ | ✅ | 99+ langs | Yes (single model) |

---

## Streaming Capabilities

| Model | Streaming | Fixed Window | Caching | VAD | Latency |
|-------|-----------|---------------|---------|-----|---------|
| Moonshine | ✅ (built-in) | ❌ | ✅ | ✅ (built-in) | <200ms |
| Whisper Turbo | ❌ | ✅ (30s) | ❌ | ✅ (Silero) | ~250ms |
| faster-whisper | ❌ | ✅ (30s) | ❌ | ✅ (Silero) | ~200ms |
| whisper.cpp | ❌ | ✅ (30s) | ❌ | ✅ (Silero) | ~200ms |

---



---

## Summary

**Phase 1 Recommendation**: Moonshine Medium Streaming

**Why**:
- Purpose-built for real-time dictation
- Better accuracy than Whisper Large V3
- <200ms latency (optimal for dictation)
- Lower VRAM requirements
- Built-in VAD and caching

**Backup Plan**: Whisper Turbo for mature ecosystem fallback

**Future Consideration**: Add faster-whisper for batch processing use cases

---

## References

- Moonshine: https://github.com/moonshine-ai/moonshine
- Whisper: https://github.com/openai/whisper
- faster-whisper: https://github.com/SYSTRAN/faster-whisper
- whisper.cpp: https://github.com/ggml-org/whisper.cpp
- Modal STT Blog: https://modal.com/blog/open-source-stt
- Northflank Benchmarks: https://northflank.com/blog/best-open-source-speech-to-text-stt-model-in-2026-benchmarks
