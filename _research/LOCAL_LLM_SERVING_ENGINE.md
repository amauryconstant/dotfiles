# Local LLM Serving Engine — Evaluation

**Dispatched**: 2026-07-13 (Research track 1 of `_research/LOCAL_LLM_BACKEND_INDEX.md`)
**Scope**: The inference/serving engine only — NOT the router/gateway (track 2), models (track 3), or RAG (track 4).
**Hardware**: RTX 4090 24GB + i9-13900K (**no AVX-512** → keep inference on GPU). Ample system RAM.
**Use case**: Single-user **agentic coding** (multi-step tool-calling loops; `opencode` = reference consumer). Shell helpers + embeddings later.
**Contract**: OpenAI-compatible API with **tool/function calling + streaming + embeddings**.
**Current state**: `llama.cpp` / `llama-server`, `127.0.0.1:8080`, user systemd unit, `.chezmoidata/ai.yaml`, GGUF in `~/.local/share/models`. `ai.models` empty — nothing served yet.

---

## Executive summary

**Verdict: KEEP llama.cpp / `llama-server`.** It is the correct engine for this profile and no alternative clears the bar for a switch. The decision is right, but the *current configuration is under-specified* and would produce a broken agentic experience out of the box — the real work is fixing flags, not swapping engines.

Rationale in one paragraph: for a single-user, 24GB, experiment-first agentic setup, the binding constraints are **VRAM efficiency, tool-calling reliability, headless/systemd friendliness, and Arch packaging/maintenance burden** — not throughput (where vLLM/SGLang/TRT-LLM win and where we have zero need). llama.cpp is the only engine that is a single C++/CUDA binary in the Arch repos, hot-swappable via a tiny Go sidecar (`llama-swap`), runs the widest quant range at the smallest VRAM footprint, and has *mature, native, model-specific* tool-call parsing plus grammar/JSON-schema constrained decoding. Its weaknesses (a genuine streaming-tool-call bug in reasoning mode, no built-in multi-model hot-swap, one-model-per-process for embeddings) are all addressable with config/sidecars, not an engine change.

**But three config fixes are mandatory before local agents work at all** (details in the capabilities and integration sections):
1. Add `--jinja` (tool calling is effectively off without it).
2. Add flash attention `-fa` and an explicit `--ctx-size`; the current unit sets neither, so KV cache and context are wrong.
3. Pick the right `--reasoning-format` per model and be aware of the streaming reasoning→tool_calls corruption bug for Qwen3 *thinking* models — prefer non-thinking / `-Instruct` coder variants for the agent loop.

**The single biggest reliability lever is the model, not the engine** — every source that tested tool-calling reliability found model *generation/training* dominated parameter count and dominated engine choice. Engine selection is a second-order effect here.

---

## Assumptions challenged

**"llama.cpp was the right pick over Ollama/vLLM."** — Confirmed for Ollama (Ollama *is* a llama.cpp wrapper; adopting it re-adds a daemon + curated-model overhead we deliberately dropped). Confirmed for vLLM/SGLang/TRT-LLM for *this* workload: they are throughput engines whose advantages (continuous batching, PagedAttention/RadixAttention, high concurrency) are irrelevant to one user, while their costs (Python/CUDA dependency trees, larger VRAM floor, weaker Arch packaging, per-model compile for TRT-LLM) are real. **Not a mistake.**

**"Grammar-constrained tool calling (llama.cpp) is less reliable than native parsers (vLLM/SGLang/TabbyAPI)."** — This is the crux and the claim is **largely false, and where true it is fixable**. llama.cpp does *both*: native model-specific parsers (Llama 3.x, Qwen 2.5/3, Mistral Nemo, Hermes, Functionary, Command-R, DeepSeek-R1) *and* GBNF grammar / JSON-schema constrained decoding via `LlamaGrammar.from_json_schema()`, plus PEG-based tool-call parsing and JSON healing for streaming. Constrained decoding is if anything the *stronger* guarantee — it enforces token-level validity so a model literally cannot emit malformed JSON args, which independent testing showed lifting a 9B model's task completion from 30%→55%. The real llama.cpp tool-calling failures in the wild trace to (a) `--jinja` not enabled, (b) wrong/buggy chat template, (c) aggressive KV-cache quant degrading tool calls, or (d) the streaming-reasoning bug — all config, not architecture. TabbyAPI, by contrast, is *template-parse* based (not constrained) and its own wiki warns of OpenCode gibberish from forced top-P=1.0 sampling. **Verdict: the assumption does not justify a switch.**

**"We might need a heavier engine later for embeddings/RAG."** — No. llama.cpp serves `/v1/embeddings` (`--embeddings`, `--pooling mean|cls|rank`) and even `/v1/rerank`. The only limitation is one model per process, solved by a second `llama-server` instance on another port (or `llama-swap`), not by a different engine.

**"Throughput matters."** — It does not. Single user, single request in flight. `--parallel > 1` mainly *splits* KV cache and can *hurt* effective context for one user; leave it at 1.

---

## llama-server capabilities for agentic workloads (detailed)

### Tool / function calling (the crux)
- **Enabled by `--jinja`.** Without it, tool calling largely does not work — the server won't apply the model's tool-use chat template. This is the #1 silent misconfiguration and is **missing from our current unit**.
- **Two parsing paths**: *native* format handlers for recognized templates (Llama 3.1/3.2/3.3 incl. builtin tools, Qwen 2.5 / Qwen 2.5-Coder / Qwen3, Mistral Nemo, Functionary v3.1/v3.2, Hermes 2/3, FireFunction v2, Command-R7B, DeepSeek-R1) → fewer tokens, more efficient; *generic* fallback for unrecognized templates → works but heavier and less reliable.
- **Constrained decoding**: JSON-schema → GBNF grammar enforced at sampling time guarantees structurally-valid tool arguments. Also exposed generically via `response_format` (json / json_schema).
- **Parallel tool calls**: supported on capable models but **off by default**; opt in per-request with `"parallel_tool_calls": true`.
- **Custom templates**: `--chat-template-file` (llama.cpp ships fixed templates e.g. `llama-cpp-deepseek-r1.jinja`; DeepSeek-R1's official template has known bugs that these work around).
- **Reliability caveats**: extreme KV-cache quant (`-ctk q4_0`) *substantially degrades* tool calling; DeepSeek-R1 is documented as reluctant to call tools; generic-format models are less reliable than native.

### Reasoning / thinking-tag handling
- Server splits reasoning into a separate `reasoning_content` field (OpenAI/DeepSeek-style) vs `content`. Controlled by `--reasoning-format` (`deepseek` default splits `<think>…</think>`; `none` returns raw tags inline). `--think` forces reasoning extraction on any model.
- **KNOWN BUG (important for us)**: the streaming reasoning transformer **corrupts tool-call argument JSON deltas** for models that go reasoning→tool_calls in *thinking* mode (Qwen3 family especially). Mitigation: for the agent loop prefer *non-thinking* / `-Instruct` coder variants, or disable thinking, or don't stream tool args from a thinking model. This is the one llama.cpp defect that materially affects agentic coding.

### Streaming
- SSE streaming of content, reasoning, and tool-call deltas, with JSON healing to keep partial structured output parseable. Fine outside the thinking-mode bug above.

### Embeddings & rerank
- `/v1/embeddings` via `--embeddings` + `--pooling {mean,cls,rank}`; `/v1/rerank` for reranker models (`pooling=rank`). **One model per process** — run a second instance (e.g. embeddings on `:8082`) alongside the chat server.

### VRAM / context / KV cache
- `--n-gpu-layers 99` = all layers on GPU (correct for 24GB; CPU offload is weak here anyway — no AVX-512).
- **KV cache is the hidden VRAM sink** and scales with `--ctx-size`. Our unit sets no `--ctx-size`, so it inherits the model default (often small, e.g. 4k) — too short for agentic coding. Set it explicitly (e.g. 32k–40k) and size KV against remaining VRAM after weights.
- **Flash attention `-fa`** cuts KV memory and speeds attention — **missing from our unit**; add it (caveat: some advise disabling FA for certain MoE models — validate per model).
- **KV-cache quantization** (`--cache-type-k/-v q8_0`, q4_0) trades VRAM for quality; **q4 measurably degrades tool calling** — prefer q8_0 if quantizing KV at all, or leave f16 given 24GB headroom.

### Speculative decoding
- `--model-draft` + a small draft model (e.g. Qwen 1.5B drafting for a larger target) → ~25% tok/s uplift, at the cost of extra VRAM for the draft. Optional tuning, not required.

### Model hot-loading / switching
- **llama-server itself does NOT hot-swap models** — one model per process. The idiomatic fix is **`llama-swap`** (mostlygeek): a tiny zero-dependency Go proxy that fronts multiple `llama.cpp`/vLLM backends and swaps the loaded model on demand (<~30s), presenting one OpenAI/Anthropic endpoint. This is the natural building block for the router (track 2) and lets one GPU host coder + embeddings + draft models by rotation.

---

## Engine landscape & tradeoff table

Scores: ●●● strong / ●● adequate / ● weak, for **this** profile (24GB, single-user, agentic tool-calling, headless Arch, experiment-first). Throughput deliberately down-weighted.

| Engine | Tool-call quality | Streaming | Embeddings | VRAM eff. @24GB | Quant formats | Throughput (N/A) | Spec. decode | systemd/headless | Arch packaging | Maint. burden | Single-user fit |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **llama.cpp / llama-server** | ●●● native+grammar | ●●● (1 bug) | ●●● (+rerank) | ●●● best | ●●● GGUF, K/IQ | ● | ●● | ●●● 1 binary | ●●● repo/AUR | ●●● low | ●●● |
| **llama-swap** (sidecar, not an engine) | inherits | inherits | inherits | inherits | inherits | — | inherits | ●●● Go binary | ●● AUR | ●●● | ●●● multi-model |
| **vLLM** | ●●● native parsers + guided | ●●● | ●●● | ●● (higher floor) | ●● AWQ/GPTQ/FP8, some GGUF | ●●● | ●● | ●● Python svc | ● pip/conda | ● heavy deps | ● overkill |
| **SGLang** | ●●● grammar-cache edge | ●●● | ●● | ●● | ●● | ●●● | ●● | ●● Python svc | ● pip | ● heavy | ● overkill |
| **TabbyAPI (ExLlamaV2/V3)** | ●● template-parse (not constrained) | ●● | ● limited | ●●● EXL3 excellent | ●● EXL2/EXL3 only | ●● | ● | ●● Python svc | ● AUR/pip | ●● | ●● |
| **HF TGI** | ●● | ●●● | ●● | ●● | ●● | ●●● | ● | ●● | ● | ● **maintenance mode 2026** | ● |
| **Ollama** | ●● (llama.cpp under hood, less control) | ●●● | ●● | ●● (opaque KV/quant) | ●● GGUF (curated) | ● | ● | ●●● daemon | ●●● repo | ●●● but telemetry/daemon | ●● (already rejected) |
| **KoboldCpp** | ●● (llama.cpp core, RP-focused) | ●●● | ● | ●●● | ●●● GGUF | ● | ●● | ●● single binary | ●● AUR | ●● | ●● wrong focus |
| **ik_llama.cpp** | ●●● (llama.cpp lineage) | ●●● | ●● | ●●● (CPU/hybrid MoE) | ●●● IQ/K/Trellis, Bitnet | ● | ●● | ●● | ● source build | ● fork, manual | ●● niche |
| **TensorRT-LLM** | ●● | ●● | ● | ●● | ● engine-compiled | ●●● peak | ●● | ● | ● NVIDIA stack | ● **1–2wk setup, per-model compile** | ● wrong tool |
| **LM Studio server** | ●● (llama.cpp core) | ●●● | ●● | ●● | ●● GGUF/MLX | ● | ● | ● GUI-first, proprietary | ● non-free | ●● | ● GUI-oriented |

**Reading the table**: llama.cpp (+ llama-swap) is the only row with no ● in the columns that matter for us (tool-calls, VRAM, systemd, Arch, maintenance, single-user). vLLM/SGLang are ●●● only in the one column we don't care about (throughput) while being ● on packaging/maintenance/fit. TabbyAPI is the sole *quality* rival (EXL3 VRAM efficiency is best-in-class) but its tool calling is template-parse rather than constrained, its embeddings story is weak, and packaging is Python. TGI and TensorRT-LLM are effectively disqualified (maintenance mode / specialist-only).

---

## Deep dive: tool-calling reliability across engines

**What the evidence actually shows** (2025–2026):

1. **The model dominates.** A 7-model Rust-coding-agent test found 4 pass / 3 fail with failures tracking model *generation*, not size: all three Qwen2.5 variants failed (one output tool JSON as a markdown code block making zero real calls; another read a file then *asked the user* instead of editing; a third looped the same broken call ~5×, burning ~30k tokens) while Qwen3-8B/14B, Devstral-Small-2, and GLM-4.7-Flash passed. Notably that test ran on **Ollama** (i.e. llama.cpp underneath) — the *engine* wasn't the failure axis. Corollary: pick an agent-trained model (Qwen3-Coder, Devstral, GLM-4.x), not a general or older one.

2. **Constrained decoding is a reliability *asset*, not a liability.** Forcing schema-valid JSON lifted a 9B model 30%→55% task completion. llama.cpp exposes exactly this (GBNF from JSON schema), so the "native parsers are more reliable" narrative inverts: llama.cpp gives you *both* native parsing *and* the stronger token-level guarantee.

3. **Where llama.cpp genuinely stumbles** is narrow and fixable: `--jinja` omitted; buggy/DeepSeek-R1 templates (worked around upstream); q4 KV cache degrading tool calls; and the **streaming reasoning→tool_calls delta-corruption bug** for Qwen3 *thinking* models. That last one is the only archit.-adjacent defect and is dodged by using `-Instruct`/non-thinking coder models in the loop.

4. **vLLM/SGLang** do have clean native parsers (`--enable-auto-tool-choice --tool-call-parser hermes`, `--reasoning-parser deepseek_r1`) plus guided decoding, and SGLang's grammar-caching shaves 10–20ms/call on repeated schemas (an *agent-loop* pattern). Real, but a latency optimization at our scale, not a reliability delta that beats constrained llama.cpp — and vLLM's own tracker has an open RFC to *unify/robustify* tool-call parsing, i.e. it isn't a solved-superior story either.

5. **TabbyAPI** parses template output rather than constraining it, and warns of OpenCode gibberish from top-P=1.0 forcing — i.e. its tool reliability is sampling-sensitive, arguably *below* constrained decoding.

**Position**: The premise that switching engines buys better agentic tool-calling is not supported. llama.cpp's tool-calling ceiling (native parser + constrained decoding) is at least as high as any alternative; realized reliability is gated by **model choice and 3–4 flags**, both of which we control without leaving the engine.

---

## Recommendation (+ fallback)

**Primary: KEEP llama.cpp / `llama-server`, and fix the configuration.**
- Add `--jinja`, `-fa`, explicit `--ctx-size` (~32k–40k), correct `--reasoning-format` per model.
- Serve an **agent-trained model** (track 3 decides; Qwen3-Coder-30B-A3B-Instruct, Devstral-Small, or GLM-4.x-Flash class fit 24GB well) — prefer *non-thinking* variants for the tool loop to sidestep the streaming bug.
- Adopt **`llama-swap`** as the multi-model front (chat + embeddings + optional draft) — this is also the natural answer to track 2 (router). Keep the single OpenAI endpoint contract.
- Embeddings later: second `llama-server --embeddings` instance (or a llama-swap entry) on a separate port; `/v1/rerank` available if needed.

**Fallback / if a real limitation surfaces:**
- **TabbyAPI (ExLlamaV3)** is the only worthwhile "switch" candidate, and *only* if (a) VRAM pressure from a specific larger model forces EXL3's superior 24GB packing, or (b) llama.cpp's thinking-mode tool-call bug proves unavoidable for a must-have model. Cost: Python service, weaker embeddings (keep llama.cpp for those), sampling-sensitive tool calls.
- **vLLM** only if the use case ever grows a genuine concurrency/throughput need (it won't for one user) — it is the "graduation" path, not a sidegrade.
- **ik_llama.cpp** worth a benchmark *only* if a specific MoE/hybrid-offload model needs it; not a default.
- Explicitly **do not** pursue TGI (maintenance mode), TensorRT-LLM (per-model compile, 1–2wk setup), Ollama (re-adds rejected daemon), LM Studio (GUI/non-free), KoboldCpp (RP focus).

---

## Open questions

1. Exact per-model `--reasoning-format` + whether the chosen coder model has a *thinking* mode that trips the streaming tool-arg bug (validate against `opencode` directly).
2. KV-cache budget: with weights for the chosen 24–30B-class quant loaded, how much context fits at f16 KV before needing q8_0 KV? Needs a real VRAM measurement.
3. Does `opencode`'s tool-call contract expect OpenAI `tool_calls` native format, and does it stream tool args (if so, the thinking-mode bug matters more)?
4. `llama-swap` vs a second static instance for embeddings — decide in track 2 (router), not here.
5. Speculative decoding: is the ~25% uplift worth the draft-model VRAM given 24GB is already tight with a 30B-class model? Benchmark before adopting.
6. Arch packaging: `llama.cpp` CUDA build source — official repo `llama.cpp-cuda` vs AUR vs self-build for latest tool-calling fixes (upstream fixes land fast; staleness risks the very bugs above).

---

## Dotfiles integration notes

### systemd unit (`private_dot_config/systemd/user/llama-server.service.tmpl`)
Current `ExecStart` is missing the flags that make agentic tool-calling work. Target shape (templated from `ai.yaml`):
```
ExecStart=/usr/bin/llama-server \
  --model %h/.local/share/models/${MODEL_FILE} \
  --host {{ .ai.server.host }} --port {{ .ai.server.port }} \
  --n-gpu-layers ${N_GPU_LAYERS:-99} \
  --jinja \                              # REQUIRED for tool calling
  -fa \                                  # flash attention (KV savings/speed)
  --ctx-size ${CTX_SIZE:-32768} \        # agentic loops need long context
  --reasoning-format ${REASONING_FORMAT:-deepseek}
```
Keep `--parallel` unset (=1) for single-user. Consider a second unit/instance (or `llama-swap`) for embeddings on a separate port. Validate MoE + `-fa` interaction per model.

### `.chezmoidata/ai.yaml`
Extend `ai.server` with the new tunables so the unit stays data-driven (matches existing `n_gpu_layers` pattern):
```yaml
ai:
  server:
    port: 8080
    host: "127.0.0.1"
    n_gpu_layers: 99
    ctx_size: 32768          # NEW
    flash_attention: true    # NEW
    reasoning_format: deepseek  # NEW (per-model override)
    parallel: 1              # NEW (explicit single-user)
    # kv_cache_type: f16     # optional; avoid q4 (degrades tool calls)
    # draft_model: ...       # optional speculative decoding
```
The env-file generator (`run_onchange_after_install_ai_models.sh.tmpl`) should emit `CTX_SIZE`, `REASONING_FORMAT`, etc. alongside `MODEL_FILE`/`N_GPU_LAYERS`. Changing these values re-triggers the hashed script (good).

### `.chezmoidata/packages.yaml`
- Chat/embeddings engine: `llama.cpp` **CUDA** build. Confirm the current package provides `/usr/bin/llama-server` built with CUDA (the unit hardcodes that path). Prefer an actively-updated source — upstream tool-calling fixes land continuously and staleness reintroduces the bugs documented above.
- If adopting the router now: add **`llama-swap`** (AUR / Go binary) as the multi-model front.
- CUDA runtime deps (`cuda`/`nvidia` stack) must be present — coordinate with the existing NVIDIA driver logic (`.chezmoi.yaml.tmpl` `nvidiaDriverType`, preflight scripts). Keep everything GPU-resident; CPU/hybrid offload is a dead end on this i9 (no AVX-512).

### CUDA / hardware
- All layers on GPU (`--n-gpu-layers 99`); never rely on CPU offload here.
- Watch the KV-cache VRAM budget when sizing `ctx_size` against the chosen model quant (track 3 + open question 2).

---

## Sources

- llama.cpp function calling docs — https://github.com/ggml-org/llama.cpp/blob/master/docs/function-calling.md
- llama.cpp server README — https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md
- llama.cpp speculative decoding — https://github.com/ggml-org/llama.cpp/blob/master/docs/speculative.md
- Function calling / grammar layer (llama-cpp-python) — https://zread.ai/abetlen/llama-cpp-python/15-function-calling-and-tool-use
- Structured output & function calling (DeepWiki) — https://deepwiki.com/qualcomm/llama.cpp/8-structured-output-and-function-calling
- Streaming reasoning→tool_calls delta corruption bug — https://github.com/musistudio/claude-code-router/issues/1397
- DeepSeek-R1 reasoning_content / --reasoning-format PR — https://app.semanticdiff.com/gh/ggml-org/llama.cpp/pull/11607/overview
- Correct llama.cpp + Qwen3 flags — https://blog.gopenai.com/the-only-correct-way-to-use-llama-cpp-with-qwen3-6-27b-d550bd0605a7
- Qwen3-Coder tool-calling fixes (Unsloth) — https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/discussions/10 · https://unsloth.ai/docs/models/tutorials/qwen3-coder-how-to-run-locally
- Tool-calling guide for local LLMs (Unsloth) — https://unsloth.ai/docs/basics/tool-calling-guide-for-local-llms
- vLLM tool calling — https://docs.vllm.ai/en/latest/features/tool_calling/ · unify RFC https://github.com/vllm-project/vllm/issues/39848
- SGLang vs vLLM (structured output / grammar caching) — https://particula.tech/blog/sglang-vs-vllm-inference-engine-comparison · https://www.yottalabs.ai/post/vllm-vs-sglang-which-inference-engine-should-you-use-in-2026
- Structured output / function calling inference guide — https://www.spheron.network/blog/structured-output-function-calling-inference-guide/
- TabbyAPI tool calling wiki — https://github.com/theroyallab/tabbyAPI/wiki/10.-Tool-Calling · repo https://github.com/theroyallab/tabbyAPI
- ExLlamaV3 + TabbyAPI accuracy/speed — https://kaitchup.substack.com/p/serving-exllamav3-with-tabbyapi-accuracy
- 7 local models + Rust coding agent (tool-call failure modes) — https://dev.to/kuroko1t/what-happens-when-local-llms-fail-at-tool-calling-testing-7-models-with-a-rust-coding-agent-cep
- Local agents: what works / fails 2026 — https://www.promptquorum.com/power-local-llm/autonomous-local-agents-actually-work · https://earezki.com/ai-news/2026-05-17-why-your-local-llm-aces-benchmarks-but-fails-real-terminal-tasks/
- llama-swap (model hot-swap) — https://github.com/mostlygeek/llama-swap · spec-decode examples https://github.com/mostlygeek/llama-swap/tree/main/docs/examples/speculative-decoding
- llama.cpp hot-swap / KV cache field notes — https://note.com/samehadaonsen/n/na9ba5ef8c660?hl=en
- ik_llama.cpp — https://github.com/ikawrakow/ik_llama.cpp · CPU/MoE regression discussion https://github.com/ikawrakow/ik_llama.cpp/issues/1699
- MoE hybrid CPU+GPU optimization guide — https://gist.github.com/DocShotgun/a02a4c0c0a57e43ff4f038b46ca66ae0
- llama-server embeddings/rerank config — https://github.com/fabiomatricardi/llama-server-embeddings · https://gist.github.com/VooDisss/42bce4eb5c76d3c325633886c5e348ee
- TGI maintenance mode / TensorRT-LLM tradeoffs — https://www.marktechpost.com/2025/11/19/vllm-vs-tensorrt-llm-vs-hf-tgi-vs-lmdeploy-a-deep-technical-comparison-for-production-llm-inference/ · https://jarvislabs.ai/blog/vllm-sglang-trtllm-comparison
- Ollama vs llama.cpp (local coding) — https://docs.bswen.com/blog/2026-03-27-llama-cpp-vs-ollama-local-coding/
- KoboldCpp / local runner comparison — https://inventivehq.com/blog/ollama-vs-lm-studio-vs-llama-cpp
