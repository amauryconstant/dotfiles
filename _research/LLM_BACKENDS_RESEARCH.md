# LLM Backends Research - February 2026
**Focus**: Local LLM solutions for future two-way conversation
**Phase**: Future (Phase 3)

---

## Executive Summary

**Recommendation for Phase 3**: **Ollama** for simplicity, **llama.cpp** for maximum performance

**Rationale**:
- Ollama: Easiest setup, OpenAI-compatible API, automatic model management
- llama.cpp: Best VRAM efficiency, fastest inference, flexible quantization

---

## Backend Comparison Matrix

| Backend | License | Performance | Ease of Use | Features | VRAM Efficiency | Pros | Cons | Best For |
|---------|----------|-------------|--------------|----------|----------------|-------|-------|----------|
| **Ollama** | MIT | Good | Excellent | High | Good | Simple setup, OpenAI API | Less control | Beginners, quick setup |
| **llama.cpp** | MIT | Excellent | Medium | Medium | Excellent | Fastest, best quantization | C++ codebase | Performance, VRAM optimization |
| **vLLM** | Apache-2.0 | Excellent | Low | Very High | Medium | Highest throughput, multi-user | Complex setup | Production, multi-user |
| **Text Gen WebUI** | AGPL-3.0 | Variable | High | Very High | Variable | All-in-one, extensible | Slower, AGPL | Prototyping, development |

---

## Ollama

### Repository
https://github.com/ollama/ollama

### Status
Latest v0.6+, 162k stars, very active

### Key Features

**Built-in Model Library**:
- Curated models with one-command installation
- Automatic updates and version management
- 100+ models available

**API Compatibility**:
- OpenAI-compatible API (localhost:11434)
- Session-based streaming for ASR workloads
- gRPC server with HTTP/2 multiplexing

**Features**:
- GPU layer offloading (automatic for GGUF models)
- Multimodal support (vision models)
- Cloud models available for larger models
- Streaming responses out of the box

**Models Available**:
- **Gemma 3**: 270M, 1B, 4B, 12B, 27B (QAT models)
- **Llama 4**: Scout 109B, Maverick 400B
- **Qwen 2.5**: 0.5B, 1.5B, 3B, 7B, 14B, 32B, 72B
- **Qwen3-VL**: Vision + text
- **Phi 4**: 14B, Mini 3.8B
- **DeepSeek-R1**: 7B, 671B
- **Mixtral 8x7B**
- **Mistral 7B**

### Performance (GGUF Models)

| Model | Quantization | CUDA | CPU |
|-------|-------------|-------|-----|
| Gemma 3 4B | Q4_K_M | ~40-60 t/s | ~8-15 t/s |
| Qwen 2.5 7B | Q4_K_M | ~35-50 t/s | ~6-12 t/s |
| Llama 3.2 3B | Q4_K_M | ~45-70 t/s | ~10-18 t/s |

### Hardware Requirements

**CPU**: Any modern CPU with 8GB+ RAM for 7B models

**NVIDIA GPU**:
- CUDA 12/13 support
- Requires RTX 3060 or newer
- 8GB VRAM for 7B models, 16GB for 13B models

**AMD GPU**:
- ROCm 6.2+ support
- RDNA2/RDNA3 support

**Apple Silicon**:
- Native Metal acceleration
- M1/M2/M3 supported

### Pros

✅ Excellent for beginners - one-command setup
✅ Built-in OpenAI API compatibility
✅ Automatic model management and versioning
✅ Streaming responses out of the box
✅ Multimodal support for vision-enabled voice assistants
✅ Cloud models available for when local compute insufficient
✅ Excellent LangChain integration (official library)
✅ Lightweight daemon runs in background
✅ Supports multiple concurrent requests

### Cons

❌ Limited customization compared to llama.cpp
❌ Less control over quantization settings
❌ Model library is curated (not all models available)
❌ Memory management less transparent than llama.cpp
❌ Slower than specialized backends for large batch workloads
❌ Less efficient than llama.cpp for very small models (sub-1B)

---

## llama.cpp

### Repository
https://github.com/ggml-org/llama.cpp

### Status
Latest b7984 (Feb 10, 2026), 94.8k stars, very active

### Key Features

**Implementation**:
- C/C++ implementation with minimal dependencies
- GGUF format with 1.5-8 bit quantization

**Backends**:
- CUDA 12/13 (NVIDIA)
- HIP (AMD ROCm 5.0+)
- Metal (Apple Silicon)
- Vulkan
- SYCL
- CANN
- OpenVINO
- WebGPU

**Features**:
- OpenAI-compatible server API (`llama-server`)
- Streaming responses with `stream: true`
- Speculative decoding support (draft models)
- Multimodal support (LLaVA, vision models)
- KV cache offloading options
- CPU+GPU hybrid inference
- Session-based streaming for interactive workloads
- Grammar/JSON output constraints
- Embedding models support
- LoRA adapter loading
- Prefix caching

### Quantization Options

| Quantization | Bits per weight | VRAM Savings | Quality Loss | Best For |
|--------------|-----------------|---------------|---------------|----------|
| Q2_K | ~2.0 | ~70% | High | Edge/IoT |
| Q3_K | ~2.7 | ~65% | High-Moderate | Edge |
| Q4_0 | ~4.5 | ~60% | Moderate | General use |
| Q4_K_M | ~4.7 | ~58% | Low-Moderate | **Voice (recommended)** |
| Q5_K_M | ~5.5 | ~50% | Low | High-quality |
| Q6_K | ~6.5 | ~45% | Low | Performance |
| Q8_0 | 8 | ~25% | Minimal | Production |

### Performance Benchmarks

| Model | Quantization | GPU | Tokens/sec | VRAM | First Token Latency |
|-------|-------------|-----|------------|-------|-------------------|
| Qwen 2.5 7B | Q4_K_M | RTX 3090 | 55-70 | 4.5GB | 80-150ms |
| Llama 3 2 7B | Q4_K_M | RTX 4090 | 65-90 | 5.2GB | 70-130ms |
| Gemma 3 4B | Q4_K_M | RTX 3090 | 50-75 | 4.8GB | 90-160ms |
| Mistral 7B | Q4_K_M | RTX 3090 | 60-80 | 4.1GB | 85-145ms |

### Hardware Requirements

**CPU**: AVX2 support recommended, 8GB+ RAM

**NVIDIA GPU**:
- Compute Capability: 7.0+ (Kepler/Maxwell/Pascal/Volta/Turing/Ampere/Hopper/Blackwell)
- CUDA: 11.8+ (legacy), 12/13 (modern)

**AMD GPU**:
- ROCm: 5.0+ (RDNA2/RDNA3)

**Apple Silicon**:
- M1/M2/M3 with Metal support

**OpenVINO**: Intel CPUs and integrated GPUs

### Pros

✅ Fastest pure C++ inference engine
✅ Best-in-class quantization quality
✅ Flexible backend support (CUDA, ROCm, Metal, Vulkan)
✅ Streaming with low first-token latency
✅ Supports speculative decoding for speedup
✅ Excellent for edge/embedded devices
✅ Most control over memory and performance
✅ Best VRAM efficiency with quantization
✅ GGUF format with wide model availability

### Cons

❌ C/C++ codebase (harder to customize)
❌ Requires more setup than Ollama
❌ Streaming requires server setup (not built-in CLI)
❌ Limited model management features
❌ Documentation can be technical
❌ GPU support varies by backend
❌ Fewer built-in features for RAG/tool use

---

## vLLM

### Repository
https://github.com/vllm-project/vllm

### Status
Latest v0.15.1 (Feb 4, 2026), 70k stars, very active

### Key Features

**Architecture**: PagedAttention for efficient KV cache management

**Features**:
- Continuous batching for high throughput
- Async scheduling (enabled by default in v0.14)
- CUDA graph execution
- Speculative decoding support
- Multiple quantization options (GPTQ, AWQ, AutoRound, INT4, INT8, FP8, MXFP4)
- OpenAI-compatible API server
- Streaming responses
- Multi-LoRA support
- Prefix caching
- Model inspection view
- Tensor/pipeline/data/expert parallelism
- Tool calling support
- Structured output with Outlines
- gRPC server entrypoint

### Performance Benchmarks (H100 GPU)

| Model | Precision | Throughput | Latency (p90) | VRAM |
|-------|-----------|------------|----------------|-------|
| Llama 3.2 70B | FP8 | 980 t/s | 45ms | 80GB |
| Qwen 2.5 72B | FP8 | 850 t/s | 50ms | 144GB |
| Mixtral 8x7B | FP8 | 1120 t/s | 55ms | 56GB |
| Gemma 3 27B | FP8 | 720 t/s | 65ms | 108GB |

### KV Cache Features

- PagedAttention: Non-contiguous KV cache allocation
- Prefix caching: Cache prompts to avoid recomputation
- KV cache offloading to CPU/NVMe
- FP8 KV cache options (per-tensor, per-attention-head)
- Configurable block sizes

### Hardware Requirements

**CPU**: AVX2 support, 16GB+ RAM recommended

**NVIDIA GPU**: Compute Capability 7.0+ (Pascal+), Blackwell support

**AMD GPU**: ROCm 5.0+ with HIP backend

**Intel GPU**: Data Center Max (Xe) series with oneAPI

**TPU**: Google Cloud TPU v5 support

### Pros

✅ Highest throughput among all backends (980+ tokens/sec)
✅ Excellent for concurrent users (continuous batching)
✅ Async scheduling reduces latency
✅ PagedAttention optimal for long conversations
✅ Best choice for production voice assistants with multiple users
✅ Excellent model support (400+ models)
✅ Streaming with minimal overhead
✅ Tool calling and structured output support

### Cons

❌ More complex setup than Ollama/llama.cpp
❌ Higher memory overhead for small models
❌ Python-only (no C API)
❌ Requires more VRAM for optimal performance
❌ CUDA graphs can increase first-token latency
❌ More resource-intensive for single-user scenarios
❌ Requires PyTorch as dependency

---

## Text Generation WebUI

### Repository
https://github.com/oobabooga/text-generation-webui

### Status
Latest v3.23 (Jan 8, 2026), 46k stars, very active

### Key Features

**Multiple Backends**:
- llama.cpp (Best for GGUF models, low resource usage)
- ExLlamaV3 (Fastest for NVIDIA GPUs with Flash Attention)
- ExLlamaV2 (Good alternative for NVIDIA GPUs)
- Transformers (Broadest model support, good for CPU)
- TensorRT-LLM (Maximum performance on NVIDIA)

**Gradio-Based Web UI**:
- Chat mode with character support
- Instruct mode for task completion
- Extensions system (voice input, TTS, translation, RAG)

**Features**:
- OpenAI-compatible API
- File attachments (PDF, docs, images)
- Multimodal support
- Automatic GPU layer configuration
- Streaming responses
- Custom LoRA loading
- Multiple sampling parameters

### Extensions for Voice

- `tts` - Text-to-speech integration (multiple TTS engines)
- `silero` - Voice input support (WebRTC-based)
- `openai` - OpenAI API compatibility extension
- `translation` - Real-time translation
- `multimodal` - Image attachment support
- `chat` - Character creation and management
- `notebook` - Free-form generation interface
- `superbooga` - Advanced model control

### Performance by Backend

| Backend | Model | Hardware | Tokens/sec | VRAM | Notes |
|----------|-------|----------|------------|-------|-------|
| ExLlamaV3 | Qwen 2.5 7B | RTX 4090 | 75-95 | 4.2GB | Flash Attention |
| llama.cpp | Qwen 2.5 7B | RTX 3090 | 55-70 | 4.5GB | Quantized |
| ExLlamaV2 | Llama 3.2 7B | RTX 4090 | 60-85 | 5.2GB | Good balance |
| Transformers | Gemma 3 4B | RTX 3090 | 25-35 | 4.8GB | CPU: ~6-8 t/s |

### Hardware Requirements

**Minimum**: 8GB RAM, 6GB VRAM (for 7B models)

**Recommended**: 16GB RAM, 12GB+ VRAM (for 13B+ models)

**GPU**:
- ExLlamaV3: CUDA 11.8+ or ROCm 5.0+
- Transformers: CUDA 11.8+ for NVIDIA, ROCm for AMD

### Pros

✅ All-in-one solution with GUI
✅ Easy model management and switching
✅ Extensive extension ecosystem
✅ Built-in voice input (silero)
✅ Multiple backends allow optimization
✅ Chat mode perfect for conversational AI
✅ File attachments enable document-aware conversations
✅ Good for prototyping and development

### Cons

❌ Gradio UI can be slower than native apps
❌ More resource-intensive than CLI tools
❌ Extensions add complexity
❌ Requires more setup than pure backends
❌ AGPL-3.0 license (not permissive)
❌ Not ideal for production deployments
❌ Slower than specialized backends for raw inference

---

## LM Studio

### Repository
Proprietary product (free for personal/commercial use)

### Status
Latest 0.4.2, desktop app

### Key Features

**Cross-Platform Desktop App**:
- Windows, macOS, Linux support

**Features**:
- Built-in model library with search
- Download and manage models
- Chat interface with history
- OpenAI-compatible API server
- Streaming responses
- GGUF and PyTorch model support
- System prompt configuration
- Temperature and parameter tuning
- API server for external access
- "llmster" CLI for headless deployments
- Anthropic API compatibility

### Hardware Requirements

**OS**: Windows 10+, macOS 12+, Ubuntu 20.04+, Arch Linux

**RAM**: 8GB minimum (16GB recommended for 7B+ models)

**GPU**: NVIDIA GPU with 4GB+ VRAM (6GB+ recommended)

**Storage**: 5GB+ for models

### Performance

- Similar to Ollama for same models (uses similar backend)
- GGUF models: ~40-60 tokens/sec (RTX 3060+)
- PyTorch models: ~35-50 tokens/sec (RTX 3060+)
- Optimization features for large models

### Pros

✅ Most user-friendly option (GUI)
✅ Excellent model management
✅ Good for non-technical users
✅ Built-in chat interface
✅ Streaming responses with minimal latency
✅ Good for personal/home assistant setups
✅ Cross-platform support
✅ API server for integrating with other tools

### Cons

❌ Proprietary (not open source)
❌ Less control than CLI tools
❌ Higher resource overhead
❌ Less customizable than raw backends
❌ Not ideal for embedded/edge deployments
❌ Limited automation capabilities
❌ Desktop-bound (no headless on all platforms)

---

## Recommended Models for Voice/Conversational Use

### Gemma 3 (Google)

**Variants & Sizes**:
- Gemma 3-270M: Ultra-fast, <1GB VRAM (Q4_K_M)
- Gemma 3-1B: Fast, ~1GB VRAM (QAT models)
- **Gemma 3-4B**: Recommended for voice, ~5GB VRAM (Q4_K_M, QAT)
- Gemma 3-12B: Powerful, ~13GB VRAM (Q4_K_M, QAT)
- Gemma 3-27B: Maximum, ~30GB VRAM (Q4_K_M, QAT)

**Best for Voice (Gemma 3-4B-Instruct)**:
- Multimodal: Vision + text (for visual voice assistants)
- Context window: 128,000 tokens
- 140+ languages
- Streaming-optimized: Low latency
- Performance: 50-75 tokens/sec (Q4_K_M, RTX 3090)
- VRAM: 4.8GB (Q4_K_M), 5.5GB (QAT)
- Latency: 90-160ms to first token
- QAT models: Preserve BF16 quality at 3x less memory

**Pros**:
- Excellent instruction following
- Strong multilingual support
- Good at maintaining conversation context
- Fast inference with good quality
- Well-tested and stable
- Wide range of sizes available
- Strong coding and math capabilities

**Cons**:
- May require longer context for complex conversations
- Not as creative as some alternatives
- Chinese model (may have cultural bias)

---

### Qwen 2.5 (Alibaba Cloud)

**Variants & Sizes**:
- Qwen2.5-0.5B: Ultra-fast, ~2GB VRAM (Q4_K_M)
- Qwen2.5-1.5B: Fast, ~3GB VRAM (Q4_K_M)
- Qwen2.5-3B: Balanced, ~5GB VRAM (Q4_K_M)
- **Qwen2.5-7B-Instruct**: Recommended for voice, ~8GB VRAM (Q4_K_M)
- Qwen2.5-14B: Powerful, ~14GB VRAM (Q4_K_M)
- Qwen2.5-32B: Maximum quality, ~28GB VRAM (Q4_K_M)
- Qwen2.5-72B: Production, ~144GB VRAM (Q4_K_M)

**Best for Voice (Qwen2.5-7B-Instruct)**:
- Context window: 131,072 tokens (full), 32,768 tokens (default)
- Max generation: 8,192 tokens
- Multilingual: 29+ languages
- Instruction following: Excellent
- Long context: Good for document-aware conversations
- Performance: 35-50 tokens/sec (Q4_K_M, RTX 3090)
- VRAM: 4.5GB (Q4_K_M), 8GB (Q4_0)
- Latency: 80-150ms to first token

**Pros**:
- Excellent instruction following
- Strong multilingual support
- Good at maintaining conversation context
- Fast inference with good quality
- Well-tested and stable
- Wide range of sizes available
- Strong coding and math capabilities

**Cons**:
- May require longer context for complex conversations
- Not as creative as some alternatives
- Chinese model (may have cultural bias)

---

### Phi-4 (Microsoft)

**Variants**:
- Phi-4-mini: ~3.8B parameters
- Phi-4: 14B parameters

**Best for Voice (Phi-4-mini)**:
- Lightweight: Suitable for edge/embedded
- Fast inference: 60-80 tokens/sec (Q4_K_M, RTX 3060)
- Low VRAM: ~3-2GB (Q4_K_M)
- Good quality for conversation
- Low latency: 70-130ms to first token
- Excellent instruction following

**Pros**:
- Very efficient for resource-constrained devices
- Good balance of speed and quality
- Strong instruction following
- Microsoft support and documentation

**Cons**:
- Limited context (typically 4K-8K tokens)
- Smaller knowledge base than larger models
- May struggle with complex reasoning

---

## Performance Comparison (7B Models, RTX 3090, 24GB VRAM)

| Backend | Model | Quantization | Tokens/sec | VRAM | First Token Latency | CPU Usage |
|----------|-------|-------------|------------|-------|-------------------|------------|
| vLLM | Qwen 2.5 | FP8 | 85-95 | 9.2GB | 95ms | 40% |
| vLLM | Llama 3.2 | FP8 | 90-110 | 10.1GB | 85ms | 42% |
| llama.cpp | Qwen 2.5 | Q4_K_M | 55-70 | 4.5GB | 80ms | 35% |
| llama.cpp | Gemma 3 | Q4_K_M | 50-75 | 4.8GB | 90ms | 32% |
| Ollama | Qwen 2.5 | Q4_K_M | 45-60 | 4.5GB | 110ms | 55% |

---

## Hardware Compatibility

### RTX 4090

**Recommended Backend**: vLLM (highest throughput)

**Recommended Configuration**:
- Model: Llama 3.2 7B or Qwen 2.5 7B
- Quantization: FP8 (vLLM) or Q4_K_M (llama.cpp)
- Batch size: 16 (for concurrent users)
- GPU memory utilization: 90%
- Expected performance: 85-110 tokens/sec
- First token latency: 70-130ms

### RTX 1650

**Recommended Backend**: llama.cpp (best VRAM efficiency)

**Recommended Configuration**:
- Model: Gemma 3 4B (QAT) or Phi-4-mini
- Quantization: Q4_K_M or Q5_K_M
- Batch size: 1 (limited VRAM)
- GPU memory utilization: 80%
- Expected performance: 25-35 tokens/sec
- First token latency: 120-200ms

---

## OpenAI-Compatible API Integration

All backends support OpenAI-compatible APIs:

```python
# Ollama (http://localhost:11434)
import requests

response = requests.post("http://localhost:11434/v1/chat/completions", json={
    "model": "gemma3:4b",
    "messages": [
        {"role": "system", "content": "You are a helpful voice assistant."},
        {"role": "user", "content": user_input}
    ],
    "stream": True
})

# vLLM (http://localhost:8000/v1)
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="dummy-key"
)

completion = client.chat.completions(
    model="Qwen/Qwen2.5-7B-Instruct",
    messages=[{"role": "user", "content": "Hello"}],
    stream=True
)

# llama.cpp (http://localhost:8080/v1)
# Server provides same API endpoints
```

---

## Recommendations

### For Personal/Home Voice Assistant

**Best Stack**:
- **Backend**: Ollama (simplest setup)
- **Model**: Gemma 3 4B (balance of speed/quality/vision)
- **STT**: Faster Whisper (medium model)
- **TTS**: Edge TTS (fastest, good enough quality)
- **Frontend**: Python Flask/FastAPI with WebSocket

**Why**:
- Ollama is easiest to set up and manage
- Gemma 3's multimodal capabilities enable visual interactions
- Edge TTS provides sub-200ms latency for near-real-time
- Good balance of quality and resource usage

**Recommended Hardware**:
- CPU: 8+ cores, 16GB+ RAM
- GPU: RTX 3060 12GB or better
- Storage: 20GB+ SSD

---

### For Production Voice Assistant

**Best Stack**:
- **Backend**: vLLM (highest throughput)
- **Model**: Qwen 2.5 7B or Llama 3.2 7B (quality + speed)
- **STT**: Whisper.cpp (server mode)
- **TTS**: Kokoro v2 (best quality)
- **API**: vLLM OpenAI-compatible server

**Why**:
- vLLM handles multiple concurrent users
- PagedAttention optimizes long conversations
- Best throughput for production workloads
- Async scheduling reduces latency

**Recommended Hardware** (per concurrent user):
- CPU: 16+ cores, 32GB+ RAM
- GPU: RTX 4090 24GB or better per 4 users
- Network: 10Gbps for concurrent streams

---

### For Edge/IoT Voice Assistant

**Best Stack**:
- **Backend**: llama.cpp (smallest, fastest)
- **Model**: Phi-4-mini or Gemma 3 1B (smallest high-quality)
- **STT**: Faster Whisper tiny model
- **TTS**: Edge TTS or piper (smallest)
- **Optimization**: Q2_K or Q3_K quantization

**Why**:
- Minimal resource requirements
- Fastest inference
- Good enough quality for basic tasks
- Can run on <8GB RAM

**Recommended Hardware**:
- CPU: 4+ cores, 4GB+ RAM
- GPU: Optional (Jetson or similar for acceleration)
- Storage: 8GB+ eMMC/SSD

---

## Summary

**Phase 3 Recommendation**: **Ollama** (primary) + **llama.cpp** (performance option)

**Why**:
- Ollama: Simplest setup, OpenAI API compatibility, automatic model management
- llama.cpp: Best VRAM efficiency, fastest inference, most control
- Both support streaming for real-time conversation
- Both integrate with Pipecat for voice assistant
- Both work with Moonshine STT

**Hardware-Specific Recommendations**:
- **RTX 4090**: vLLM for multi-user, Ollama for simplicity
- **RTX 1650**: llama.cpp for VRAM optimization, Phi-4-mini for speed

---

## References

- Ollama: https://docs.ollama.com
- llama.cpp: https://github.com/ggml-org/llama.cpp
- vLLM: https://docs.vllm.ai
- Text Gen WebUI: https://github.com/oobabooga/text-generation-webui
- Gemma 3: https://ai.google.dev/gemma
- Qwen 2.5: https://huggingface.co/Qwen
- Phi 4: https://huggingface.co/microsoft
- OpenAI API Spec: https://github.com/openai/openai-openapi
- LangChain: https://python.langchain.com
