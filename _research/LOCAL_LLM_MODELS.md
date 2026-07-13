# Local LLM Models — Landscape & Selection (2026)

**Focus**: Which GGUF models to *serve* on a single RTX 4090 (24GB) for agentic
coding, a fast shell helper, and RAG embeddings.
**Backend**: llama.cpp / `llama-server` (GGUF, OpenAI-compatible) — already decided
(see `_research/LLM_BACKENDS_RESEARCH.md`).
**Date**: 2026-07 · **Hardware**: RTX 4090 24GB + i9-13900K (no AVX-512 → keep
weights on GPU; CPU offload of prompt processing is slow) + ample system RAM.

> This doc supersedes the model picks in `LLM_BACKENDS_RESEARCH.md` (which were
> voice-framed and dated: Qwen 2.5, Gemma 3). Serving roster below is coding-first
> with current (mid-2026) models.

---

## Executive summary (recommended roster per role)

| Role | Default pick | GGUF quant | On-disk | Fits 24GB? | Why |
|------|-------------|-----------|---------|-----------|-----|
| **Agentic coder** (primary) | **GLM-4.7-Flash 30B-A3B** | UD-Q4_K_XL (~18GB) | ~18GB | ✅ fully | MoE 3.6B active → fast multi-round-trip; 59.2% SWE-bench Verified; MIT; 202k ctx |
| Agentic coder (accuracy alt) | **Devstral-Small-2-24B-2512** | Q5_K_M 16.8 / Q6_K 19.3 | ~17–19GB | ✅ fully | Dense, purpose-built agentic; **68% SWE-bench**; Apache-2.0; slower (dense) |
| Agentic coder (mature-ecosystem alt) | **Qwen3-Coder-30B-A3B** | UD-Q4_K_XL 17.7 | ~18GB | ✅ fully | MoE, best tool-call tooling (Qwen Code, Cline); 50.3% SWE-bench; Apache-2.0 |
| **Shell helper** (fast) | **Qwen3-4B-Instruct-2507** | Q5_K_M (~3GB) | ~3GB | ✅ trivially | Snappy, solid tool calling, 256k ctx; non-thinking = low latency |
| Shell helper (code-leaning alt) | Qwen2.5-Coder-7B-Instruct | Q5_K_M (~5.4GB) | ~5GB | ✅ | Best pure-code completion at small size |
| **Embeddings** | **bge-m3** | Q8_0/F16 (~0.6–1.2GB) | ~1GB | ✅ | MIT, 1024-dim, dense+sparse+ColBERT, 8k ctx, battle-tested |
| Embeddings (top-MTEB alt) | Qwen3-Embedding-0.6B | Q8_0/F16 (~1.2GB) | ~1GB | ✅ | #1-class MTEB, 1024-dim, MRL (32–1024), 32k ctx |

**One-line recommendation**: serve **GLM-4.7-Flash UD-Q4_K_XL** as the primary
agentic coder (fits fully, fast, MIT), keep **Devstral-Small-2-24B Q5_K_M** on disk
as the accuracy fallback, **Qwen3-4B-Instruct-2507** as the shell helper, and
**bge-m3** for RAG. Total disk ≈ 40–50GB.

---

## Assumptions challenged

### MoE (30B-A3B) vs dense on 24GB — and is RAM offload worth it?
- **The 4090 has enough VRAM to fit a good coder fully — do that.** Every model in
  the roster runs 100% on-GPU. On this box, CPU offload is a trap: the i9-13900K
  has **no AVX-512**, so tensors spilled to RAM make prompt processing (the
  dominant cost in agentic loops with long tool outputs) crawl.
- **Prior-art Manifest config was mis-sized.** It tried Qwen3.6-35B-A3B **Q8_0
  (~36.9GB), RAM-offloaded at ~50/N gpu layers** — i.e. ~40% of weights on CPU.
  That's the wrong knob: the *same family* at **Q4_K_XL fits fully in ~24GB at 65k
  context and runs ~80–140 t/s** (empirical, RTX 3090 — a 4090 is faster). Q8 buys
  almost nothing for coding vs a good dynamic Q4 (see cliffs below) and RAM offload
  throws away most of the speed. **Verdict: drop the RAM-offload config; pick a
  model that fits fully.**
- **MoE gives you the speed win *while* fitting.** GLM-4.7-Flash and
  Qwen3-Coder-30B-A3B are 30B-total / ~3–3.6B-active. Weights (~18GB Q4) fit; only
  ~3B params are active per token, so throughput is dense-7B-class (fast) with
  30B-class knowledge. This is the sweet spot for agentic loops.
- **When RAM offload *is* worth it**: only to reach a genuinely stronger tier that
  can't fit — e.g. **GLM-4.5-Air (106B/12B active, 64.2% SWE-bench)** needs RAM
  offload on 24GB (only IQ2/IQ3 fit fully). Expect ~10–20 t/s and slow prefill.
  Worth it *only* if you specifically want its quality and tolerate the latency;
  not a fit for fast interactive tool-calling. **Qwen3-Coder-Next (80B/3B active)**
  is even further out (smallest IQ4_XS = 42.7GB) — RAM offload mandatory, skip for
  interactive use.

### Quant quality cliffs (coding / tool-calling)
- **Q4_K_M is the practical floor** for reliable code + tool-call JSON. Below Q4
  (Q3_K/IQ3) tool-call formatting and code correctness degrade noticeably,
  especially for MoE where each of the ~3B active params carries more weight.
- **Use Unsloth "UD" dynamic quants** (UD-Q4_K_XL): they selectively keep sensitive
  tensors higher-bit. Evidence: Qwen3-Coder UD-Q4_K_XL scored **60.9% vs 61.8% for
  full bf16** on Aider Polyglot — under a 1-point gap at ~1/50th the size.
- **Q5/Q6 gains are real but small** for these models; take them only if the model
  still leaves ≥4–6GB for KV cache at your target context. For dense Devstral-24B,
  Q5_K_M (16.8GB) or Q6_K (19.3GB) both fit with usable context.
- **Skip Q8_0 for the coder** on 24GB: it eats the KV-cache headroom for a quality
  gain you won't notice in coding, and forces context down or RAM offload.

### Context vs VRAM (KV cache eats the budget)
- Agentic coding wants **≥32k, ideally 64k+**. KV cache scales linearly with
  context and can rival weight size at long context.
- **Quantize the KV cache**: `--cache-type-k q8_0 --cache-type-v q8_0` + flash
  attention roughly halves KV footprint with negligible quality loss. This is what
  lets a ~19GB-weights model hold 64k context inside 24GB. (Empirically: Qwen3.6-35B
  Q4 + q8 KV holds **65k ctx in ~24GB**; without it, f16 KV at 65k adds 10–15GB and
  blows the budget.)

---

## Coder models — shortlist

| Model | Type / active | Quant that fits | Weights | Native ctx | Tool use | SWE-bench Verified | License | GGUF source |
|-------|--------------|-----------------|---------|-----------|----------|--------------------|---------|-------------|
| **GLM-4.7-Flash** | MoE 30B / ~3.6B | UD-Q4_K_XL / Q4_K_M | ~18.3GB | 202k | ✅ (agentic-tuned) | **59.2%** | MIT | `unsloth/GLM-4.7-Flash-GGUF` |
| **Devstral-Small-2-24B-2512** | Dense 24B | Q5_K_M / Q6_K | 16.8 / 19.3GB | 256k | ✅ (OpenHands-built) | **68.0%** | Apache-2.0 | `unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF` |
| **Qwen3-Coder-30B-A3B** | MoE 30.5B / ~3.3B | UD-Q4_K_XL / IQ4_XS | 17.7 / 16.4GB | 256k (1M YaRN) | ✅ (Qwen Code, Cline) | 50.3% | Apache-2.0 | `unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF` |
| Qwen2.5-Coder-32B | Dense 32B | Q4_K_M | ~20GB | 128k | ⚠️ weaker agentic | (strong code-completion; weak agent) | Apache-2.0 | `bartowski/Qwen2.5-Coder-32B-Instruct-GGUF` |
| GLM-4.5-Air | MoE 106B / 12B | IQ2/IQ3 full, else RAM-offload | ~40GB+ Q4 | 128k | ✅ | 64.2% | MIT | `unsloth/GLM-4.5-Air-GGUF` |
| Qwen3-Coder-Next | MoE 80B / 3B | none fit (IQ4_XS 42.7GB) | 42.7GB+ | 256k | ✅ | n/a | Apache-2.0 | `unsloth/Qwen3-Coder-Next-GGUF` |

**Notes on the numbers**
- Devstral's 68% is measured with the OpenHands agent scaffold (it was co-built with
  All Hands AI) — real-world agentic strength is its selling point, but the headline
  number is scaffold-assisted. Predecessor Devstral-Small-1.1 (2507) was 53.6%.
- GLM-4.7-Flash also posts GPQA 75.2 / AIME25 91.6 — strong reasoning for a 30B MoE.
- Qwen3-Coder-30B-A3B has the most mature *client* tooling for tool-calling (Qwen
  Code, Cline, llama.cpp/Ollama tool-call templates were explicitly fixed).
- Qwen2.5-Coder-32B is excellent at single-shot code completion but predates the
  agentic-tuning wave; weaker at multi-step tool loops than the three leaders.

**Throughput expectations (RTX 4090, rough)**
- MoE ~3B active (GLM-4.7-Flash, Qwen3-Coder-30B): **~90–140 t/s** generation,
  fast prefill — ideal for many tool round-trips.
- Dense 24B (Devstral): **~30–50 t/s** — noticeably slower in long agent loops but
  higher single-response quality.

---

## VRAM math — worked examples

Approximate KV-cache cost per model (K+V, flash-attn on). Formula:
`bytes ≈ ctx × layers × kv_heads × head_dim × 2 × bytes_per_elem`
(`bytes_per_elem` = 2 for f16, ~1 for `q8_0` cache).

**Devstral-Small-2-24B** (≈40 layers, GQA 8 KV heads, head_dim 128 → ~0.16 MB/token f16):
| Context | KV f16 | KV q8_0 | + Q5_K_M weights (16.8GB) | Fits 24GB? |
|--------|--------|---------|---------------------------|-----------|
| 32k | ~5.1GB | ~2.6GB | ~19.4GB (q8 KV) | ✅ comfortable |
| 64k | ~10.2GB | ~5.1GB | ~21.9GB (q8 KV) | ✅ tight |
| 128k | ~20GB | ~10GB | ~26.8GB (q8 KV) | ❌ needs Q4 weights or less ctx |

**Qwen3-Coder-30B-A3B / GLM-4.7-Flash** (≈48 layers, GQA ~4 KV heads → ~0.09 MB/token f16):
| Context | KV f16 | KV q8_0 | + UD-Q4_K_XL weights (~18GB) | Fits 24GB? |
|--------|--------|---------|------------------------------|-----------|
| 32k | ~3.0GB | ~1.5GB | ~19.5GB | ✅ lots of headroom |
| 64k | ~6.0GB | ~3.0GB | ~21.0GB | ✅ comfortable |
| 128k | ~12GB | ~6.0GB | ~24GB | ⚠️ borderline; drop to ~96k |

**Empirical anchor**: Qwen3.6-35B-A3B Q4_K_XL + `q8_0` KV held **65k ctx in
24.2GB** on a 24GB card at ~80–140 t/s — consistent with the MoE table above.

**Takeaway**: at **UD-Q4_K_XL + q8_0 KV cache**, the MoE coders give a genuine
**64k agentic context fully in VRAM**. Dense Devstral at Q5 fits 32k comfortably /
64k tight — plenty for opencode sessions, and its quality-per-token is higher.

---

## Small helper models (1.5B–8B, snappy)

| Model | Quant | Size | Ctx | Notes | Source |
|-------|-------|------|-----|-------|--------|
| **Qwen3-4B-Instruct-2507** | Q5_K_M | ~3GB | 256k | Non-thinking (low latency), good tool calling, strong for size | `unsloth/Qwen3-4B-Instruct-2507-GGUF` |
| Qwen2.5-Coder-7B-Instruct | Q5_K_M | ~5.4GB | 128k | Best pure-code completion at small size | `bartowski/Qwen2.5-Coder-7B-Instruct-GGUF` |
| Qwen3-1.7B / 4B (newer 3.5-4B) | Q4_K_M | ~1.5–3GB | 256k | Even snappier; Qwen3.5-4B is the freshest tiny model | `unsloth/Qwen3.5-4B-*` (verify at pull time) |

**Pick**: **Qwen3-4B-Instruct-2507** as the default shell helper — fast, reliable
tool calling, negligible VRAM so it can co-reside with the coder if you run two
`llama-server` instances (helper on a second port). Use **Qwen2.5-Coder-7B** instead
if the helper's job is mostly inline code rather than shell/agent glue.

---

## Embedding models (RAG)

| Model | Dim | Ctx | MTEB (multiling) | License | GGUF / llama-server | Notes |
|-------|-----|-----|------------------|---------|---------------------|-------|
| **bge-m3** | 1024 | 8k | strong | MIT | ✅ (`--embedding`) | Dense + sparse + ColBERT in one; the 2026 production default |
| **Qwen3-Embedding-0.6B** | 1024 (MRL 32–1024) | 32k | #1-class family | Apache-2.0 | ✅ (`Qwen/Qwen3-Embedding-0.6B-GGUF`) | Instruction-aware; long-doc chunking; tiny |
| Qwen3-Embedding-4B | 2560 (MRL) | 32k | 69.45 | Apache-2.0 | ✅ | Higher quality, ~heavier; overkill for most local RAG |
| nomic-embed-text-v2-moe | 768 | 8k (native, set num_ctx) | 62-class | Apache-2.0 | ✅ | Fastest tier, tiny memory; good for large corpora |

**Pick**: **bge-m3** as the robust default (MIT, hybrid retrieval, well-supported
in llama.cpp). Use **Qwen3-Embedding-0.6B** if you want top-of-leaderboard dense
quality with a 32k context for long-document chunking, or **nomic-embed-text-v2**
for fastest bulk ingestion.

**llama-server caveats (important)**:
- Run a **separate** `llama-server` instance with `--embedding` (embeddings and
  chat can't share one server cleanly).
- `llama-server` currently **does not honor `--embd-normalize`** for the Qwen3
  embedding GGUFs — **normalize output vectors client-side** before cosine search.
- Qwen3-Embedding uses instruction prefixes (query vs document) — apply them for
  best retrieval.

---

## Recommendation (default + alternates, exact GGUF files)

**Coder (default — best speed/quality/fit balance)**
- `GLM-4.7-Flash-UD-Q4_K_XL.gguf` — repo `unsloth/GLM-4.7-Flash-GGUF`
  (`GLM-4.7-Flash-Q4_K_M.gguf` = 18.3GB alternative). MIT. 202k ctx.
  Serve with `--cache-type-k q8_0 --cache-type-v q8_0 -fa -c 65536`.

**Coder (accuracy alternate — highest SWE-bench, dense)**
- `Devstral-Small-2-24B-Instruct-2512-Q5_K_M.gguf` (16.8GB) or `-Q6_K.gguf`
  (19.3GB) — repo `unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF`. Apache-2.0.
  Serve at `-c 32768` (or 64k tight) with q8 KV.

**Coder (mature-tooling alternate)**
- `Qwen3-Coder-30B-A3B-Instruct-UD-Q4_K_XL.gguf` (17.7GB) — repo
  `unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF`. Apache-2.0. Best if opencode/Cline
  tool-call templates work most smoothly for you.

**Shell helper (default)**
- `Qwen3-4B-Instruct-2507-Q5_K_M.gguf` (~3GB) — repo
  `unsloth/Qwen3-4B-Instruct-2507-GGUF`.

**Embeddings (default)**
- bge-m3 GGUF (F16 or Q8, ~0.6–1.2GB), e.g. `bge-m3-Q8_0.gguf`. Alternate:
  `Qwen3-Embedding-0.6B` GGUF from `Qwen/Qwen3-Embedding-0.6B-GGUF`.

---

## Open questions

1. **opencode tool-call format**: verify which of GLM-4.7-Flash / Devstral-2512 /
   Qwen3-Coder-30B has the smoothest tool-call parsing in *opencode* specifically
   (harness matters as much as the model). Test all three on the same agent task.
2. **One server or two?**: run coder + helper + embeddings as three `llama-server`
   instances (ports 8080/8081/8082) vs on-demand swapping. Three small instances
   fit if helper+embed are tiny, but the coder alone wants most of the 24GB with
   64k ctx. Likely: coder always-on, helper+embed on demand or on CPU.
3. **Devstral vision**: the 2512 GGUF reportedly carries vision weights — confirm
   whether the text-only path is unaffected / whether a text-only quant is lighter.
4. **KV cache quant quality**: confirm `q8_0` KV doesn't hurt tool-call reliability
   on your workloads before committing to 64k+ context.
5. **Freshness churn**: this space moves monthly (Qwen3.5/3.6, GLM-4.7, Devstral-2).
   Re-check for a Qwen3-Coder refresh and GLM-4.7-Flash successors at pull time.

---

## Dotfiles integration notes

Config lives in `.chezmoidata/ai.yaml` (`ai.models` list, each `{name, file, url}`);
`ai.models_dir` = `~/.local/share/models`; downloaded by
`run_onchange_after_install_ai_models.sh.tmpl` (resumable `wget -c`, skip-existing).
The server env (`~/.config/llama-server/env`) is generated from the **first**
configured model (`MODEL_FILE`, `N_GPU_LAYERS`).

Proposed `ai.models` entries (roles-as-models; first entry = the served coder):

```yaml
ai:
  server:
    port: 8080
    host: "127.0.0.1"
    n_gpu_layers: 99          # keep everything on GPU (no AVX-512 → avoid CPU offload)
  models_dir: "~/.local/share/models"
  models:
    # --- agentic coder (primary, served) ---
    - name: glm-4.7-flash
      file: GLM-4.7-Flash-UD-Q4_K_XL.gguf
      url: https://huggingface.co/unsloth/GLM-4.7-Flash-GGUF/resolve/main/GLM-4.7-Flash-UD-Q4_K_XL.gguf
    # --- accuracy alternate (kept on disk) ---
    - name: devstral-small-2-24b
      file: Devstral-Small-2-24B-Instruct-2512-Q5_K_M.gguf
      url: https://huggingface.co/unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF/resolve/main/Devstral-Small-2-24B-Instruct-2512-Q5_K_M.gguf
    # --- shell helper ---
    - name: qwen3-4b-2507
      file: Qwen3-4B-Instruct-2507-Q5_K_M.gguf
      url: https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF/resolve/main/Qwen3-4B-Instruct-2507-Q5_K_M.gguf
    # --- embeddings (run as a separate --embedding server) ---
    - name: bge-m3
      file: bge-m3-Q8_0.gguf
      url: https://huggingface.co/<verify-repo>/bge-m3-Q8_0.gguf
```

**Server flags to add** (not yet templated in `llama-server.service.tmpl` — the env
only sets `MODEL_FILE`/`N_GPU_LAYERS`): consider surfacing
`--ctx-size`, `--flash-attn`, `--cache-type-k q8_0 --cache-type-v q8_0`, and a
`--jinja`/tool-call template flag in `ai.yaml` so the coder gets 64k ctx + quantized
KV without editing the unit. Verify exact URLs (`resolve/main/<file>`) at pull time —
filenames above match the repos as of 2026-07.

**Disk budget**: GLM-4.7-Flash ~18GB + Devstral Q5 ~17GB + Qwen3-4B ~3GB +
bge-m3 ~1GB ≈ **~39GB**. Add Qwen3-Coder-30B (~18GB) if you keep all three coders →
~57GB. Ensure `~/.local/share/models` has headroom.

---

## Sources

- Qwen3-Coder-30B-A3B GGUF (sizes, tool calling, Apache-2.0): https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF
- Qwen3-Coder run guide / Aider Polyglot UD-Q4_K_XL 60.9% vs bf16 61.8%: https://unsloth.ai/docs/models/tutorials/qwen3-coder-how-to-run-locally
- Qwen3.5/3.6-35B-A3B on 24GB (empirical VRAM, KV quant, throughput): https://aminrj.com/posts/llamacpp-qwen36-35b/
- Devstral-Small-2-24B-2512 GGUF (sizes, 68% SWE-bench, 256k, Apache-2.0): https://huggingface.co/unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF
- Devstral 2 run guide: https://unsloth.ai/docs/models/tutorials/devstral-2
- Devstral 1.1 (2507) SWE-bench 53.6%: https://huggingface.co/unsloth/Devstral-Small-2507-GGUF
- GLM-4.7-Flash run guide (30B-A3B, 59.2% SWE-bench, 202k, 24GB): https://unsloth.ai/docs/models/tutorials/glm-4.7-flash
- GLM-4.7-Flash GGUF (Q4_K_M 18.3GB, MIT): https://huggingface.co/unsloth/GLM-4.7-Flash-GGUF
- GLM-4.7-Flash on 24GB (backends comparison): https://www.agentnative.dev/blog/glm-4-7-flash-on-24gb-gpu-llama-ccp-vllm-sglang-transformers
- GLM-4.5 / GLM-4.5-Air (106B/12B, 64.2% SWE-bench, MIT): https://huggingface.co/zai-org/GLM-4.5-Air · https://arxiv.org/abs/2508.06471
- GLM-4.5-Air GGUF: https://huggingface.co/unsloth/GLM-4.5-Air-GGUF
- Qwen3-Coder-Next (80B/3B, sizes — does NOT fit 24GB): https://huggingface.co/unsloth/Qwen3-Coder-Next-GGUF
- gpt-oss-20b GGUF / MXFP4 / llama.cpp: https://huggingface.co/unsloth/gpt-oss-20b-GGUF · https://github.com/ggml-org/llama.cpp/discussions/15396
- Qwen3-4B-Instruct-2507 GGUF (helper): https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF
- Qwen2.5-Coder-7B GGUF: https://huggingface.co/bartowski/Qwen2.5-Coder-7B-Instruct-GGUF
- Qwen3-Embedding-0.6B GGUF (1024-dim, MRL, llama-server normalize caveat): https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF
- Embedding model comparison (bge-m3 / Qwen3-Embedding / nomic 2026): https://www.morphllm.com/ollama-embedding-models
- llama.cpp VRAM guide (quant sizing rule): https://localllm.in/blog/llamacpp-vram-requirements-for-local-llms
- Best local coding models 2026 (landscape): https://insiderllm.com/guides/best-local-coding-models-2026/ · https://www.kdnuggets.com/top-7-coding-models-you-can-run-locally-in-2026
