# Local LLM Performance Tuning & Observability

**Status**: Research / decision input (2026-07). Repo-only, not deployed.
**Hardware**: RTX 4090 24 GB (Ada, ~1008 GB/s) + i9-13900K **without AVX-512**, 128 GB system RAM. Single GPU, single user.
**Backend**: llama.cpp / `llama-server` (OpenAI-compatible), user systemd unit, config via `.chezmoidata/ai.yaml`.
**Workload**: agentic coding (long-ish contexts, tool calling, bursty), shell helpers, embeddings.
**Design lesson carried forward**: keep observability LIGHT — the Manifest Docker+Postgres+Grafana stack was dropped on purpose.

---

## Executive summary

- **Keep everything in VRAM — for anything that fits.** On this box, RAM-offloaded layers are a cliff, not a slope: no AVX-512 means CPU matmul falls back to AVX2, roughly halving CPU-side throughput. For any model/quant that fits fully in 24 GB, the right move is "pick a model + quant + KV-cache config that fits fully in VRAM" rather than "offload N layers." Full offload (`-ngl 99` / `auto`) is already correct in the current unit. This does **not** apply to models too large to fit 24 GB under any reasonable quant (100B+ total-param MoE) — see **Part B** for whether CPU/RAM offload of cold experts is viable there given the box's 128 GB RAM.
- **Turn on the three cheap wins**: Flash Attention (`--flash-attn on`), **q8_0 KV cache** (`--cache-type-k q8_0 --cache-type-v q8_0`), and an explicit context size. FA is a prerequisite for KV quantization and is a near-free speed/VRAM win on Ada. q8_0 KV roughly halves KV VRAM at perplexity cost of ~0.002–0.05 (imperceptible), buying context headroom.
- **Model sweet spots on a 4090**: a **30B MoE (~3B active)** coder (Qwen3-Coder-30B-A3B class) is the best speed/quality trade — fits at Q4 with room for context, ~70–90 tok/s in coding use. A **32B dense** at Q4 fits but is tight (~22 GB weights, little KV room) and runs ~30–40 tok/s. **7–8B dense** at Q4 runs ~90–110 tok/s and is the shell-helper tier.
- **Speculative decoding** helps dense targets most (32B dense + 0.5–4B draft → ~1.5–2.5x on code, up to ~3x on boilerplate/JSON). It helps a fast MoE far less and can even hurt. **Same-vocabulary drafts only** — cross-vocab drafts silently corrupt tool-call/JSON boundaries.
- **Observability**: `llama-server` already exposes `/health`, `/props`, `/slots`, and (with `--metrics`) a Prometheus `/metrics` endpoint, plus a built-in web UI. That is enough. Recommended surface = `Restart=on-failure` (already set) + a lightweight `ExecStartPost` readiness gate, a `system-health` section that curls `/health` and reads VRAM via `nvidia-smi`, and a Waybar/`menu-ai` glyph. **Skip Prometheus+Grafana** unless a learning exercise is the explicit goal — it is heavier than the whole backend.

---

## Assumptions challenged

- **"Offload some layers to RAM to fit a bigger model."** Not on this CPU, *for models that could otherwise fit in VRAM*. Lacking AVX-512, CPU-resident layers use AVX2 kernels; every token must round-trip through PCIe + slow CPU matmul, and llama.cpp runs the whole graph at the pace of its slowest layers. Real-world reports put a handful of offloaded layers at a 3–10x end-to-end slowdown vs full-VRAM. Prefer: smaller quant, quantized KV, or smaller model — anything to stay 100% on-GPU. **This changes once the model is too big for VRAM at any quant** (large sparse MoE): see **Part B** — offloaded-expert compute is memory-bandwidth-bound rather than AVX-bound, which is a materially different case than dense CPU-resident layers.
- **"MoE with `--n-cpu-moe` to keep experts on CPU is a good fit."** This is the one place CPU offload is sometimes advocated (offload only the sparse expert FFNs to RAM, keep attention on GPU). But it *still* leans on CPU matmul throughput, which AVX-512-less Raptor Lake is weak at. Given a 30B-A3B MoE fits fully in 24 GB at Q4 anyway, there is no reason to offload experts here — keep it all in VRAM and enjoy the full ~70–90 tok/s.
- **"KV-cache quantization is risky."** q8_0 is effectively free (perplexity delta ~0.002–0.05; "nobody notices"). q4_0 is where quality starts to show, and the **K cache is more sensitive than V** — so if you ever push further, quantize V harder than K (e.g. K q8_0 / V q4_0) rather than the reverse. For an agentic/tool-calling workload, stay at q8_0/q8_0 as the default; only drop to q4 KV to reach very long contexts (32K+) where it is the difference between fitting and not.
- **"`--parallel` / slots matter."** For a single user, no. Keep `--parallel 1` (one slot) so the *entire* KV budget backs one long context instead of being split N ways. Continuous batching stays on (it is default and harmless), but you are not optimizing throughput — you are optimizing single-stream latency and max context.
- **"Speculative decoding always helps."** It is a *latency* optimization that trades VRAM (second model) and compute (verification) for fewer sequential target steps. It shines on slow, predictable, dense targets (32B). On an already-fast MoE it often nets to break-even or a loss because the target step is cheap and draft overhead + occasional rejects dominate. Measure before committing VRAM to a draft model.

---

## Part A: Performance tuning — recommended `llama-server` flags

Defaults below assume the primary agentic-coding model is a **30B-A3B MoE coder at Q4_K_M** fully in VRAM.

| Flag | Recommended value | Why | Tradeoff / notes |
|------|-------------------|-----|------------------|
| `-ngl, --n-gpu-layers` | `99` (or omit; default `auto`) | Full offload — mandatory on this CPU. | Already set. `99` = "all layers" idiom; `auto` also works on modern builds. |
| `--flash-attn` | `on` | Faster attention, less KV memory on Ada; **required** to quantize KV. Default is `auto` (usually enables it) — set `on` to be explicit. | None meaningful on a 4090. Without it, quantized KV gets dequantized every step = slower. |
| `--cache-type-k` | `q8_0` | Halves K-cache VRAM; ~free quality. | Needs FA on. K is the sensitive one — do not go below q8_0 for coding. |
| `--cache-type-v` | `q8_0` | Halves V-cache VRAM. | V tolerates more; can drop to `q4_0` only to chase very long ctx. |
| `-c, --ctx-size` | `32768` (start), up to `65536` if VRAM allows | Agentic coding needs headroom; default (0 = model's trained max) can over-allocate KV or be too small. Set explicitly. | KV VRAM scales linearly with ctx × layers × heads. See KV cost note below. |
| `-np, --parallel` | `1` | Single user — give the whole KV budget to one context. | >1 splits KV across slots; only useful for concurrency you do not have. |
| `-cb, --cont-batching` | on (default) | Harmless; helps if you ever issue overlapping requests. | Leave default. |
| CUDA graphs | on (automatic) | llama.cpp CUDA backend uses CUDA graphs automatically for decode; measurable decode speedup on Ada. | No flag needed. Disable only for debugging via `GGML_CUDA_DISABLE_GRAPHS=1`. |
| `--mlock` | **off** | Pins weights in RAM to prevent swap. Irrelevant when weights live in VRAM; wastes RAM. | Only relevant for RAM-resident/offloaded setups — which we avoid. |
| `--no-mmap` | **off** (keep mmap) | mmap lets the model page in fast and share pages; fine for full-VRAM load. | Use `--no-mmap` only if diagnosing load issues. |
| `-t, --threads` | leave default (`-1`) or set to P-core count (~8) | With full GPU offload the CPU only does sampling/glue; threads barely matter. | Do **not** count E-cores or hyperthreads; more threads ≠ faster here. Given no AVX-512, do not expect CPU threads to rescue throughput. |
| `--metrics` | **on** | Enables Prometheus `/metrics`. Cheap; enables Part B. | Slot metrics only; negligible overhead. |
| `--slots` | on (default) | Per-slot introspection for `/slots`. | Disable (`--no-slots`) only if you consider slot sampler params sensitive. |
| `--host` / `--port` | `127.0.0.1` / `8080` | Loopback only (already set). | Keep off the network; no auth by default. |

**KV VRAM cost rule of thumb**: KV bytes ≈ `2 (K+V) × ctx × n_layer × n_kv_head × head_dim × bytes_per_elem`. f16 = 2 B/elem; q8_0 ≈ 1 B/elem (~half); q4_0 ≈ 0.5 B/elem. Concretely a 32B dense at long context can want several GB of KV — q8_0 is what makes 32K+ context coexist with 22 GB of weights. MoE has fewer KV heads relative to its total size, so KV is cheaper there.

---

## Realistic throughput expectations (single RTX 4090, Q4-class, single stream)

| Model class | Fits in 24 GB? | Decode tok/s (typical) | Notes |
|-------------|----------------|------------------------|-------|
| **7–8B dense** (Llama-3.1-8B, Qwen3-8B) Q4_K_M | Easily (~5–6 GB + KV) | **~90–110 tok/s** | Shell-helper / fast-tool tier. Lots of ctx headroom. |
| **30B MoE, ~3B active** (Qwen3-30B-A3B / Coder) Q4 | Yes (~18 GB + KV) | **~70–90 tok/s** (general MoE has hit ~150–196 tok/s in synthetic single-token benches; coder in real use ~73–87) | **Best speed/quality trade** for agentic coding. Quality ≈ 14B dense, speed ≈ 8B. |
| **32B dense** (Qwen2.5/3-32B, Qwen3-Coder-32B) Q4_K_M | Tight (~22 GB weights) | **~30–40 tok/s** | Highest single-model quality that fits, but little KV room → pair with q8_0 KV and/or speculative decoding. |
| **32B dense at Q5** | Barely / spills | ~25–35 tok/s if it fits | Usually not worth it vs Q4 + more context. |

Prompt-processing (prefill) is much faster than decode on a 4090 (hundreds–thousands tok/s), so long agent contexts cost mostly first-token latency, not per-token speed. These are single-stream, real-workload figures; peak/synthetic numbers run higher.

**RAM-offload penalty, quantified**: dropping even ~10–20% of layers to CPU on this AVX-512-less i9 typically cuts end-to-end decode to a *fraction* of the full-VRAM rate (community reports commonly 3–10x slower once the CPU/PCIe path is on the critical path). Treat any config that reports layers on CPU as a misconfiguration to fix, not a tuning knob.

---

## Speculative decoding deep dive

**Mechanism**: a small **draft** model proposes N tokens; the large **target** verifies them in one batched forward pass. Accepted tokens are "free." Net win requires: (1) high acceptance (draft agrees with target), (2) draft much cheaper than target, (3) target decode expensive enough that skipping steps matters.

**Hard rule — same vocabulary**: draft and target must share a tokenizer/vocab family. Cross-vocab "token translation" (as some forks advertise) **silently corrupts edge tokens — JSON braces, list separators, quote escapes, tool-call boundaries** — while still reporting high tok/s. For an agentic/tool-calling workload this is disqualifying. Use a draft from the *same model family* (e.g. Qwen3-Coder target + Qwen3 small draft).

**Flags** (mainline llama.cpp): `--model-draft FNAME`, `--spec-draft-n-max N` (draft tokens/round, default 3; try 4–8 for code), `--spec-draft-n-min N`, `--spec-draft-p-min P` (accept-probability floor), plus draft KV controls (`--cache-type-k-draft` etc.). Note flag names have churned across versions — verify against `llama-server --help` on the installed build before wiring into config.

**Recommended pairings**:

| Target | Draft | Context | Expected result | When |
|--------|-------|---------|-----------------|------|
| **32B dense coder** | 0.5B same-family (Qwen2.5-Coder-0.5B) | 8–16K, q8_0 KV | ~1.5–2.5x on code; up to ~3x on boilerplate/JSON | Best ROI: slow dense target benefits most. Draft is tiny (~0.5 GB). |
| **~27–30B coder** | ~4B same-family, Q4 | 8K, q8 KV | ~40+ tok/s mean / ~67 peak, 6/6 quality pass in one 4090 recipe (mainline llama.cpp) | Larger draft = higher acceptance but more VRAM; 8K ctx kept it in budget. |
| **7–8B dense** | (none) | — | Not worth it | Target already fast; draft overhead ≈ savings. |
| **30B-A3B MoE** | (none, usually) | — | Often break-even/negative | MoE target step is already cheap; verification + draft cost eats the gain. Only try if measured. |

**Context caveat**: at long context (32K+), speculative setups have been reported to hang unless *both* target and draft KV are dropped to q4 — a fit/stability constraint, not a speed one.

**Bottom line for this box**: if the daily driver is the 30B MoE, **skip speculative decoding** (keep the VRAM for context). If you switch to a **32B dense** coder for quality, **add a 0.5B same-family draft** — that is where the 1.5–2.5x lives. Always A/B with `/metrics` acceptance stats before committing.

---

## Part B: CPU/RAM offload for large MoE (128GB ceiling)

The guidance above ("stay in VRAM") holds for anything that fits in 24 GB at a usable quant. It stops being the relevant question once a candidate model is too large to fit under any reasonable quant — e.g. a 100B+ total-param MoE. This box has 128 GB system RAM, which reopens the question for that regime specifically.

### Why the calculus changes for large MoE

Elsewhere in this doc, `--n-cpu-moe` (or the equivalent `-ot "exps=CPU"` tensor-override syntax) offloads only the sparse **expert FFN** tensors to CPU/system RAM while attention, dense FFN, and shared-expert tensors stay resident on GPU ([Doctor-Shotgun, MoE offload guide](https://huggingface.co/blog/Doctor-Shotgun/llamacpp-moe-offload-guide)). The doc's assumptions-challenged section is right that there is no reason to use this for the 30B-A3B case — it fits fully in 24 GB already. This new section is about the regime where that mechanism stops being optional: a **100B+ total-param MoE** that does not fit under any reasonable quant on a 24 GB card has no VRAM-only path at all.

What makes that regime viable rather than a guaranteed cliff is that CPU-side compute for expert-offloaded inference is proportional to **active params per token**, not total params — only the experts a token's router actually selects are read and multiplied; the rest of the model sits untouched in RAM. For gpt-oss-120b (117B total params — the HF model card's figure; "120B" in the model name is the commonly used rounded figure) this active-param count is reported at two different scopes: the HF model card's **5.1B active params/token** is the *total* active count (attention + router + selected-expert FFN combined), while a narrower worked example breaks that down further into ~1.5B of always-on dense/attention/router mass plus **~3.5B of selected-expert FFN** — the part that actually gets offloaded to, and read from, system RAM under `--n-cpu-moe` ([Understanding MoE Offloading](https://dev.to/someoddcodeguy/understanding-moe-offloading-5co6)). The two figures aren't a contradiction, just different scopes; see the Worked throughput model below for which one the formula uses and why. Concretely, **Qwen3-235B-A22B** — 235B total params, 22B active per token ([Hugging Face model card](https://huggingface.co/Qwen/Qwen3-235B-A22B)) — offloading its experts to CPU does roughly **22B-equivalent FFN math per token on CPU, not 235B**.

That decoupling is why large sparse MoE is structurally different from the dense-offload case this doc otherwise (correctly) warns against: a dense CPU-resident layer computes over *all* of its parameters on every token, so its RAM footprint and its per-token CPU compute cost are the same number. For a sparse MoE they are not — RAM has to *hold* the full 235B params, but the CPU only has to *compute* ~22B params' worth per token.

### The real bottleneck is RAM bandwidth, not AVX-512

Token generation with offloaded experts is memory-bandwidth-bound, not compute-bound: each step reads the selected experts' weights from RAM once and performs one matmul per expert per token, i.e. low arithmetic intensity (few FLOPs per byte read) — the CPU spends more time waiting on RAM than computing ([PartnerInAI, `--n-cpu-moe` performance](https://partnerinai.com/blogs/llamacpp-n-cpu-moe-performance-why-speedups-happen): "fast system RAM is important since the expert layers will be read from your DDR4 or DDR5, and higher bandwidth memory will directly impact your token generation speed"). This matches the general finding that single-stream llama.cpp CPU inference plateaus on RAM bandwidth regardless of instruction set — even AVX-512-equipped CPUs cap out around 10–15 tok/s on an 8B-class dense model at Q4, and a faster CPU alone buys little because the wall is data movement, not FLOPs ([llama.cpp CPU benchmarks](https://www.myaihardware.com/llama-cpp-benchmarks)). (Some sources instead frame per-token offload overhead as CPU↔GPU PCIe round-trip latency for the small activation vector rather than RAM bandwidth directly — e.g. [Doctor-Shotgun's guide](https://huggingface.co/blog/Doctor-Shotgun/llamacpp-moe-offload-guide) — so treat "RAM-bandwidth-bound" as the dominant factor, not the only one.)

Contrast that with why AVX-512 matters for this doc's *dense*-offload warning: a dense CPU-resident layer must push its *entire* weight set through the FLOP pipeline every token, so the CPU has to sustain a much higher compute rate against the same RAM stream — that's where AVX2's narrower vector width shows up as a real practical penalty, on top of dense offload also streaming more total bytes per token (previous subsection).

The conclusion this licenses: because expert offload does far less CPU-side arithmetic per token, the AVX2-vs-AVX-512 gap matters much less here than the doc's blanket "no AVX-512 → avoid offload" framing (written for the dense case) implies. But bandwidth itself is still a hard ceiling. Real-world (not theoretical-peak) dual-channel DDR5 bandwidth on 13900K-class platforms measures roughly **67–70 GB/s at DDR5-5600** (AIDA64, vs. an ~89.6 GB/s theoretical peak) ([13900K review, AIDA64 memory benchmark](https://www.thefpsreview.com/2022/10/20/intel-core-i9-13900k-cpu-review/4/)). The same review also reports an AIDA64-measured **~95 GB/s at DDR5-6000** on a faster kit — a genuine benchmark result, not a spec-sheet figure — but it lands almost exactly at DDR5-6000's own ~96 GB/s theoretical ceiling (2 channels × 8 B/transfer × 6000 MT/s, the same formula that produces DDR5-5600's 89.6 GB/s), unlike the DDR5-5600 result's clear ~22–25% gap below its theoretical peak. That near-zero measured/theoretical gap is consistent with AIDA64's sequential-read subtest running close to peak while under-representing the gather-style, non-sequential access pattern that MoE expert reads actually produce — so treat the ~95 GB/s DDR5-6000 figure as an optimistic, near-ceiling estimate, not a sustained number validated the same way the DDR5-5600 figure is. Populating all four DIMM slots for 128 GB commonly forces a slower stable speed than a 2-DIMM kit on this platform — one documented case runs a 13900K + Z790 4×32 GB (128 GB) kit stable only at 4800 MT/s against a 6000 MT/s rating ([Tom's Hardware forum report](https://forums.tomshardware.com/threads/i-am-struggling-to-match-128gb-ddr5.3805390/) — anecdotal, not a controlled benchmark, but the failure mode is consistent with dual-rank 4-DIMM stability limits on this platform generation). The DDR5-5600 sustained figure — the one with a real measured/theoretical gap — is the primary ceiling the Worked throughput model below builds from; the DDR5-6000 figure is carried through as a secondary, less-conservative estimate.

### Worked throughput model

**The formula:**

```
tok/s ≈ RAM_bandwidth_bytes_per_sec / (active_params × bytes_per_param)
```

- `active_params` — the model's active-parameter count *per token*, not total, per the previous subsection: only the experts the router actually selects get read from RAM on a given step.
- `bytes_per_param` — set by quantization, using the same bytes-per-element convention as this doc's KV-cost rule of thumb above (line 52): ~0.5–0.55 B/param for Q4_K_M, ~1 B/param for Q8_0.
- This models a **batch=1, single-stream** ceiling: each token's expert read sits on the critical path (nothing to amortize it across concurrent requests), and it excludes the attention/dense-FFN compute that stays resident on GPU — that path never touches system RAM.

**Worked example — gpt-oss-120b:**

gpt-oss-120b has 117B total parameters and 5.1B active parameters per token, natively quantized to MXFP4 (4.25 bits/param ≈ 0.53 B/param — inside the Q4_K_M range this doc already uses) ([Hugging Face model card](https://huggingface.co/openai/gpt-oss-120b)).

This uses the HF card's 5.1B *total*-active figure rather than the narrower ~3.5B expert-FFN-only figure from the previous subsection. Strictly, only the expert-FFN portion is physically read from system RAM under offload, so ~3.5B is the more literal match for the formula's stated RAM-bytes-only scope. But the cross-check below shows 5.1B is the figure that reproduces the measured real-world throughput (~25 tok/s) almost exactly, while ~3.5B would project a materially higher, unmatched throughput (~1.855 GB/token → ~36–38 tok/s at DDR5-5600 sustained bandwidth) — plausibly because router computation, KV-cache paging, and other per-token RAM traffic outside the pure expert weights still consume bandwidth that the narrower figure doesn't account for. 5.1B is kept here as the empirically-calibrated input, not as a claim that GPU-resident attention weights are re-read from RAM every token.

```
bytes/token = 5.1×10⁹ params × 0.53 B/param ≈ 2.71 GB/token
```

Dividing into this doc's own sourced DDR5-5600 sustained-bandwidth figure (67–70 GB/s, previous subsection):

```
tok/s ≈ 67–70 GB/s ÷ 2.71 GB/token ≈ 25–26 tok/s   (projected, from formula)
```

At the DDR5-6000 figure (~95 GB/s — measured but near that speed's theoretical ceiling, and thus the less conservative of the two bandwidth inputs; see previous subsection): `tok/s ≈ 95 ÷ 2.71 ≈ 35 tok/s (projected, from formula, optimistic upper bound)`.

**Cross-check against a sourced real-world report:**

A consumer rig in a directly comparable hardware class — Intel i5-12600K (non-AVX-512-class consumer Intel, same Alder-Lake-derived family as this box's 13900K), RTX 4070 12 GB, 64 GB DDR5 — ran gpt-oss-120b-MXFP4 with expert offload via `llama.cpp`. With DDR5 accidentally running at 2000 MT/s (~32 GB/s theoretical) it measured ~10–11 tok/s; after fixing an XMP misconfiguration to reach DDR5-6000 (~96 GB/s theoretical) it reached ~30 tok/s at burst and **~25 tok/s stable sustained** ([carteakey.dev, "Optimizing gpt-oss-120b speed on consumer hardware"](https://carteakey.dev/blog/local-inference/optimizing-gpt-oss-120b-local-inference/)).

That result lines up closely with this doc's formula **when the formula is fed a sustained-bandwidth figure rather than a near-ceiling one**: the misconfigured-RAM case, 32 GB/s theoretical ÷ 2.71 GB/token ≈ 11.8 tok/s projected vs. ~10–11 tok/s actual — a near match, because at that low a speed theoretical and sustained bandwidth converge. At full speed, this doc's own 67–70 GB/s DDR5-5600 *sustained* figure ÷ 2.71 GB/token ≈ 25–26 tok/s projected vs. **~25 tok/s actual stable** — also a near match. But feeding the formula either near-ceiling DDR5-6000 figure — this doc's own AIDA64-measured ~95 GB/s or carteakey's spec-sheet ~96 GB/s theoretical peak, which land within 1% of each other for the reason given in the previous subsection — projects ≈35 tok/s either way (95 ÷ 2.71 ≈ 35; 96 ÷ 2.71 ≈ 35), overshooting the reported ~25–30 tok/s by roughly 15–40% depending on whether it's compared to the burst or stable figure. That confirms the DDR5-6000 branch of the worked example above is the less reliable of the two projections: it tracks the *ceiling* the RAM could theoretically sustain, not what expert-offload's gather-style access pattern actually achieves. The gap is explained by real single-stream MoE-offload traffic never reaching spec-sheet peak — non-expert compute shares the same memory controller, each token's activation makes a PCIe round trip to the GPU, and gather-style expert reads don't hit the idealized sequential-access pattern memory benchmarks assume. That is exactly why the previous subsection treats the DDR5-5600 sustained figure — not either DDR5-6000 number — as the planning ceiling for this box.

### Alternative backends

This doc's Part B is scoped to mainline llama.cpp's `-ot`/`--n-cpu-moe` offload mechanism because that is what the packaged `llama.cpp-bin` provides. Two third-party forks are frequently cited for CPU-offload performance claims beyond what mainline achieves; this subsection surveys what they claim, and whether those claims apply to this box's specific silicon (no AMX, no AVX-512).

**ik_llama.cpp** ([ikawrakow/ik_llama.cpp](https://github.com/ikawrakow/ik_llama.cpp)) is a maintained fork of an older llama.cpp base built around new "IQK" quantization/GEMM kernels, fused MoE ops, and a GPU-offload batching threshold that scales with `total_experts / active_experts` instead of mainline's fixed 32-token trigger, avoiding wasted GPU copies of expert weights for small batches ([PR #520](https://github.com/ikawrakow/ik_llama.cpp/pull/520)). Its headline CPU speedups are real and, encouragingly, don't require AVX-512 or AMX: a benchmark on a Ryzen 7950X deliberately restricted to the **AVX2** code path (not that chip's AVX-512 capability) showed up to 5.18x faster prompt processing and up to 2.1x faster token generation vs. mainline on IQ-quant formats ([ik_llama.cpp Discussion #164](https://github.com/ikawrakow/ik_llama.cpp/discussions/164)) — good news for a 13900K, since AVX2 is exactly what this box has. But that benchmark used a **dense** 8B model (LLaMA-3.1-8B-Instruct), not the sparse-MoE CPU-offload workload Part B is about. For the closer analog — Qwen3 MoE at IQ4_XS with CPU expert-offload on AVX2-only, no-AVX-512 hardware (a Ryzen 5800X, Zen3) — the one documented data point runs the other way: ik_llama.cpp measured *slower* than mainline llama.cpp on both prompt processing (118.79 vs 239.81 tok/s, ~2x slower) and generation (10.40 vs 15.69 tok/s, ~1.5x slower), an open, unresolved regression report ([ik_llama.cpp Issue #1699](https://github.com/ikawrakow/ik_llama.cpp/issues/1699)). So the one workload-matched data point available today argues against, not for, a win on this box.

**ktransformers** ([kvcache-ai/ktransformers](https://github.com/kvcache-ai/ktransformers)) is a CPU/GPU heterogeneous-inference framework from Tsinghua's kvcache-ai group, purpose-built to run very large sparse MoE models (DeepSeek-R1/V3-671B class) under a small GPU VRAM budget by keeping attention/MLA on GPU and routing expert compute through custom CPU kernels — conceptually similar to `--n-cpu-moe` but with its own kernel implementation. Its headline numbers — up to 27.79x faster prefill (10.31 → up to 286.55 tok/s) and up to 3.03x faster decode (4.51 → up to 13.69 tok/s) vs. llama.cpp on DeepSeek-V3 — were measured on a dual-socket **Intel Xeon Gold 6454S** (Sapphire Rapids, AMX-capable) with 1 TB server DDR5-4800 and an RTX 4090D, with the top prefill figure specifically attributed to AMX-optimized kernels ([ktransformers DeepSeek-R1/V3 tutorial](https://github.com/kvcache-ai/ktransformers/blob/main/doc/en/DeepseekR1_V3_tutorial.md)). AMX (Advanced Matrix Extensions) requires Sapphire Rapids-class 4th-gen Xeon Scalable or later — silicon this box's Raptor Lake 13900K lacks entirely, alongside AVX-512 ([ktransformers AMX.md](https://github.com/kvcache-ai/ktransformers/blob/main/doc/en/AMX.md)). The scale of that dependency shows in the project's own AMX-vs-no-AMX comparison on the *same* Xeon-4 rig: ~347 tok/s prefill with AMX active vs. ~91 tok/s falling back to a non-AMX kernel path, roughly a 3.8x gap from AMX alone (same source). The project does document a consumer-class run on hardware in the 13900K's own family — an i9-14900KF (Raptor Lake, no AMX/AVX-512) + RTX 4090 + dual-channel DDR5-4000 running Qwen3-235B-A22B — but reports it only qualitatively as "smooth performance," with no tok/s figure given (same source). A March 2026 release (v0.5.3) added an AVX2-only CPU backend ("KT-Kernel") explicitly targeting CPUs lacking AMX/AVX-512, including "current and recent generation Intel Core (Ultra) processors" — a class the 13900K falls into — but coverage of that release still notes AMX/AVX-512 hardware yields "much greater" throughput, and no published benchmark yet quantifies the AVX2 fallback path on a 13900K-class chip ([Phoronix, "KTransformers Adds AVX2 MoE Support"](https://www.phoronix.com/news/KTransformers-0.5.3)).

Both are third-party forks/frameworks outside the packaged `llama.cpp-bin` this box actually runs, so adopting either would mean building or installing unvetted third-party CUDA-touching code and would need review under this repo's package security policy (`private_dot_local/lib/scripts/system/CLAUDE.md` → "Package Security Policy") as its own separate future decision — this section surveys the ceiling, it does not propose a switch.

Neither backend's evidence overturns Part B's worked-model conclusion for this box: ik_llama.cpp's only workload-matched (MoE, CPU-offload, AVX2-only) data point is a regression, and ktransformers' large advertised gains are AMX-driven numbers from Xeon Scalable server hardware that the 13900K structurally cannot reproduce, with its new AVX2-only path still unbenchmarked on comparable consumer silicon — so mainline llama.cpp's `-ot`/`--n-cpu-moe` path remains the best-evidenced option for this box today, and nothing surveyed here rises to the bar of a large enough gap to justify a dedicated future evaluation on its own.

### RAM budget for candidate models

Using this doc's active/total-param and bytes-per-param convention (see Worked throughput model above), here's where the RAM math actually lands for three concrete 100B+ MoE candidates a user might try on this box. Total/active param counts and expert-routing config come from each model's HF `config.json` (primary source); GGUF weight sizes come from published quant repos.

The VRAM/RAM split column is **(projected)**, not sourced: it's derived by solving `total_params = x + n_experts × p` and `active_params = x + n_experts_per_tok × p` for `x` (the always-resident attention + shared-expert + dense-layer parameter mass — the part that stays on GPU under `-ot "exps=CPU"`-style offload) and `p` (per-routed-expert size), then scaling `x`'s share by the quant's total byte size. That likely *undercounts* real VRAM bytes: K-quants commonly keep attention/shared tensors at a higher bit-width than the bulk of the MoE tensors, so actual GPU-resident bytes probably run above the raw parameter-count fraction. Treat the split as directional, not exact — always confirm with the benchmark recipe below.

| Model | Total params | Active params | Quant | Total weight size | Est. VRAM-resident (attn+shared+KV) | Est. RAM-resident (cold experts) | Fits 128GB? |
|---|---|---|---|---|---|---|---|
| **gpt-oss-120b** | 117B, 128 experts ([HF model card](https://huggingface.co/openai/gpt-oss-120b); [config.json](https://huggingface.co/openai/gpt-oss-120b/blob/main/config.json)) | 5.1B/token, top-4 of 128 ([config.json](https://huggingface.co/openai/gpt-oss-120b/blob/main/config.json)) | MXFP4 (native) | ~63.4 GB (derived) ([ggml-org/gpt-oss-120b-GGUF file listing](https://huggingface.co/ggml-org/gpt-oss-120b-GGUF/tree/main)) | ~2–4 GB + KV (derived, projected) | ~59–61 GB (projected) | Yes — comfortable |
| **GLM-4.5-Air** | 106B, 128 routed + 1 shared expert ([HF model card](https://huggingface.co/zai-org/GLM-4.5-Air); [config.json](https://huggingface.co/zai-org/GLM-4.5-Air/blob/main/config.json)) | 12B/token, top-8 of 128 + shared ([config.json](https://huggingface.co/zai-org/GLM-4.5-Air/blob/main/config.json)) | Q4_K_M | 73 GB ([unsloth/GLM-4.5-Air-GGUF](https://huggingface.co/unsloth/GLM-4.5-Air-GGUF)) | ~5–9 GB + KV (derived, projected) | ~64–68 GB (projected) | Yes — with headroom |
| **Qwen3-235B-A22B** | 235B, 128 experts ([HF model card](https://huggingface.co/Qwen/Qwen3-235B-A22B); [config.json](https://huggingface.co/Qwen/Qwen3-235B-A22B/blob/main/config.json)) | 22B/token, top-8 of 128 ([config.json](https://huggingface.co/Qwen/Qwen3-235B-A22B/blob/main/config.json)) | Q4_K_M | 142.65 GB ([bartowski/Qwen_Qwen3-235B-A22B-Instruct-2507-GGUF](https://huggingface.co/bartowski/Qwen_Qwen3-235B-A22B-Instruct-2507-GGUF)) | ~6–12 GB + KV (derived, projected) | ~131–137 GB (projected) | **No** — total weight size alone exceeds 128 GB RAM before OS/context overhead; a lower quant such as Q3_K_M (~107 GB, same source) would fit with modest headroom |

The Qwen3-235B-A22B row is the useful negative result: at the quant this doc otherwise treats as baseline (Q4_K_M), the model does not fit this box's RAM ceiling at all — the file itself is bigger than the RAM budget. gpt-oss-120b and GLM-4.5-Air both fit with real headroom, which is what makes them the more realistic offload candidates for this specific box. See the decision framework below for how to reason about a candidate's weight size generically, without needing to redo this table for every model.

### Benchmark recipe

Every number above the line is projected or cross-checked against someone else's rig, not this one. Before trusting any of it for a real decision, validate on this hardware — this recipe documents *how* to measure, it is not a claimed result.

```bash
# Keep attention/shared/dense layers on GPU, offload only expert FFN tensors to CPU
# --n-cpu-moe <N> below: or use -ot "exps=CPU" for the regex-tensor-override form
llama-server \
  --model <path-to-gguf> \
  -ngl 99 \
  --n-cpu-moe <N> \
  --cache-type-k q8_0 --cache-type-v q8_0 \
  --flash-attn on \
  -c 8192 \
  --metrics
```

`--n-cpu-moe N` pushes the expert tensors of the first `N` MoE layers to CPU — a single tunable integer to trade VRAM headroom against offload amount. `-ot "exps=CPU"` is the more surgical form: a regex tensor-name override matching any tensor whose name contains `exps` (expert weights), pinned to CPU regardless of layer — reach for it when the layer-count knob can't express what you want (e.g. full-model expert offload, or a non-uniform split).

**What to measure**: `curl -s http://127.0.0.1:8080/metrics | grep tokens_predicted` for live decode tok/s off a running server, or `llama-bench` for a controlled, repeatable comparison across configs (varying `-ngl` / `--n-cpu-moe`, quant, context size).

**Trial order — cheap before expensive**: don't burn a 60–140 GB download to validate flag mechanics on an unfamiliar build. Force a few experts of the existing 30B-A3B model onto CPU artificially (e.g. `--n-cpu-moe 2`, even though that model already fits fully in VRAM) and confirm `/metrics` shows the expected offload/throughput drop on the installed `llama.cpp-bin` first. Only download a 100B+ candidate once the flag behavior is confirmed on hardware already in hand.

### Decision framework

This box's RAM budget maps onto three bands. Apply this after computing (or looking up, per the table above) a candidate model's file size at the quant under consideration.

| Candidate weight size @ chosen quant | Recommendation |
|---|---|
| ≤ ~20 GB | Full VRAM — existing Part A guidance applies, no offload needed. |
| ~20–90 GB (fits with headroom for OS + context in 128 GB RAM) | Partial expert offload worth trialing via the benchmark recipe above; expect throughput to degrade roughly with the fraction of active-param bytes that must be read from RAM per token. |
| Fits only with < ~10 GB headroom, or projected tok/s (via the Worked throughput model above) is below your usability floor | Not worth it on this hardware — stick to a VRAM-fit model instead. |

"Usability floor" is a number this doc deliberately does not set — it's a personal threshold, not an assertion this doc makes on the user's behalf. Asynchronous/reasoning workloads (send a prompt, walk away, come back) commonly tolerate 5–10 tok/s; interactive chat or an agentic tool-calling loop typically wants 20+ tok/s to stay usable. Pick a number from that range (or outside it, for your own use case) *before* applying the table — the framework only tells you which band a candidate falls into, not whether that band is good enough for you.

---

## Part C: Observability endpoints & lightweight monitoring

`llama-server` ships enough introspection that no external agent is needed.

| Endpoint | Auth/flag | Returns | Use for |
|----------|-----------|---------|---------|
| `GET /health` | public | `200 {"status":"ok"}` when ready; `503` while model loads | Liveness/readiness probe — the primitive for everything below. |
| `GET /metrics` | needs `--metrics` | Prometheus text: `llamacpp:prompt_tokens_total`, `llamacpp:tokens_predicted_total`, throughput gauges (tokens/s), active/idle slot gauges, KV-cache usage, avg busy slots per decode | Scrape or one-shot curl for tok/s, queue depth, KV pressure. |
| `GET /props` | public (POST needs `--props`) | model path, total slots, ctx size, chat template, modalities, default sampler, sleeping status | Confirm which model/ctx is actually loaded; sanity-check config drift. |
| `GET /slots` | on unless `--no-slots` | per-slot ctx, task id, processing state, sampler params, token counts | See if a request is stuck/processing; live activity. |
| **Built-in web UI** | served at `http://127.0.0.1:8080/` | chat playground + model/slot info | Manual poke-testing; no extra install. |

**VRAM / GPU**: `llama-server` does not report GPU memory — use `nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu,temperature.gpu --format=csv,noheader,nounits` for a scriptable one-liner, or `nvtop` for an interactive view (add to packages if not present).

**Logs**: `journalctl --user -u llama-server.service` (add `-f` to follow, `-e` to jump to end, `--since "10 min ago"`). llama.cpp logs load, per-request timings, and slot activity to stderr → captured by the user journal automatically.

**Prometheus + Grafana?** For a single-user learning box this is heavier than the workload it observes (a scrape stack + dashboards + retention to watch one process). **Recommendation: do not deploy it as ops.** If wanted purely as a *learning* exercise, keep it opt-in behind a `features.yaml` toggle and out of the default path — the `/metrics` endpoint is already there to point a scraper at later. The lightweight surface below covers real day-to-day needs.

---

## Recommended ops surface

1. **Restart policy (systemd)** — already `Restart=on-failure`, `RestartSec=5`. Good. Add:
   - `StartLimitIntervalSec` / `StartLimitBurst` so a crash-loop backs off instead of hammering (e.g. burst 5 / interval 60s).
   - Optional **readiness gate**: `ExecStartPost=/usr/bin/sh -c 'for i in $(seq 1 60); do curl -sf http://127.0.0.1:8080/health && exit 0; sleep 1; done; exit 1'` so `systemctl start` only "succeeds" once the model is actually loaded and `/health` is green. Keep `Type=simple`.
   - **Watchdog note**: true `sd_notify` `WATCHDOG=1` self-healing (`Type=notify` + `WatchdogSec`) requires the *program* to send heartbeats. `llama-server` does **not** implement sd_notify, so a native watchdog is not available. The lightweight equivalent is a periodic external `/health` probe (below) that restarts on failure — do not set `Type=notify`/`WatchdogSec` against a binary that never notifies (it would false-kill).
   - Optional **health timer**: a small `llama-health-check.timer` (mirroring the existing `system-health-check.timer`) that curls `/health` and runs `systemctl --user try-restart llama-server` on failure — an external stand-in for the watchdog.

2. **`system-health` extension** — the CLI (`private_dot_local/lib/scripts/system/executable_system-health`) is a bash function using `ui_*` helpers with `--brief`/`--check` modes. Add a small `llama-server` block:
   - In `--brief`: if the unit is active, curl `/health`; show `ui_success "llama-server: ready"` or `ui_warning`. Optionally append VRAM used/total from `nvidia-smi`.
   - In `--check` (threshold/notify mode): fire `notify-send` if the unit is `active` but `/health` is not `ok` within a short timeout, or if VRAM is pinned at ~100% (OOM risk). Gate the whole block on `command -v llama-server` / unit existence so non-AI hosts stay silent.
   - `system-health-dashboard` can grow a matching panel (unit state + `/health` + VRAM + last tok/s from `/metrics`).

3. **`menu-ai` extension** — currently the "llama-server Status" entry just runs `systemctl --user status`. Enrich it: add entries for **Health** (`curl -s /health`), **Metrics/tok-s** (curl `/metrics`, grep the throughput/predicted-tokens lines), **VRAM** (`nvidia-smi`), **Open Web UI** (`xdg-open http://127.0.0.1:8080`), and **Restart** (`systemctl --user restart llama-server`). A glyph like `󰋼`/`󰓅` fits the existing style.

4. **Waybar / status glyph** — a tiny custom module: exit-code of `curl -sf /health` → colored brain/chip glyph (green ready / yellow loading / red down). Optional tooltip = current model (`/props`) + tok/s (`/metrics`). Poll every ~10s. This is the "is my LLM up?" at-a-glance signal, matching the repo's existing Waybar custom-module pattern.

---

## Open questions

- **Primary daily model**: commit to a 30B-A3B MoE coder (speed, skip speculative) vs a 32B dense (quality, add draft)? Decides whether speculative-decoding config keys are worth adding to `ai.yaml`.
- **Context default**: 32K vs 64K — depends on measured KV VRAM after weights for the chosen model at q8_0 KV. Needs one empirical `nvidia-smi` check post-load.
- **Model swapping**: single static unit vs an on-demand swapper (e.g. llama-swap) for coder-vs-embeddings-vs-8B-helper. Multiple concurrent models will not co-fit in 24 GB, so some swap/route mechanism may be wanted — separate design question.
- **Embeddings**: run as a second small `llama-server --embeddings` instance (extra VRAM, always-on) or fold into the swapper? Affects VRAM budgeting.
- **Flag-name stability**: speculative/KV draft flag names have changed across llama.cpp releases; pin the installed version's `--help` output before templating them into the unit.
- **Actual DDR5 bandwidth on the 128GB box is unverified**: Part B's worked throughput model assumes a bandwidth figure sourced from general 13900K benchmarks, not this specific box's DIMM count/speed. 4-DIMM 128GB configs commonly run slower than 2-DIMM due to signal integrity on Raptor Lake boards. Confirm with `sudo dmidecode --type 17` or `lshw -C memory` before trusting the Part B numbers for a real decision.

---

## Dotfiles integration notes

**`.chezmoidata/ai.yaml` — proposed tuning keys** (extend `server:`; keep flat and hackable):
```yaml
ai:
  server:
    host: "127.0.0.1"
    port: 8080
    n_gpu_layers: 99
    ctx_size: 32768
    flash_attn: "on"          # on | off | auto
    cache_type_k: "q8_0"      # f16 | q8_0 | q4_0
    cache_type_v: "q8_0"
    parallel: 1               # single user
    metrics: true             # enable /metrics
    # speculative (optional; only for dense targets):
    # draft_model: "qwen2.5-coder-0.5b-q4_k_m.gguf"
    # draft_n_max: 6
```
The `llama-server.service.tmpl` `ExecStart` then renders these flags conditionally (omit speculative block when `draft_model` unset; omit `--cache-type-*` implicitly requires `--flash-attn on`). Validate with `chezmoi execute-template` and `chezmoi cat` before apply, per repo standards.

**systemd unit hardening** (`private_dot_config/systemd/user/llama-server.service.tmpl`):
- Add `StartLimitIntervalSec=60` / `StartLimitBurst=5` (crash-loop backoff).
- Add the `/health` `ExecStartPost` readiness gate (above).
- Keep `Type=simple`, `Restart=on-failure`, `RestartSec=5`. Do **not** add `Type=notify`/`WatchdogSec` (binary lacks sd_notify).
- Consider light sandboxing that does not break CUDA: `NoNewPrivileges=true`, `ProtectSystem=strict` + `ReadWritePaths=%h/.local/share/models`, `PrivateTmp=true`. Verify CUDA/`/dev/nvidia*` access still works (GPU device access can conflict with `PrivateDevices=true` — do **not** set that one).

**`system-health` + `menu-ai`**: extend as described in "Recommended ops surface" — reuse `ui_*` helpers, gate on `command -v llama-server`, no new heavy deps. Optionally add a `llama-health-check.{service,timer}` mirroring the existing `system-health-check.{service,timer}` pair.

**Packages** (`.chezmoidata/packages.yaml`): `llama.cpp-bin` (CUDA) and `cuda` already present. Add **`nvtop`** for interactive VRAM/GPU monitoring if not installed; `curl` is already a base dep. No Prometheus/Grafana packages (kept lightweight by decision).

---

## Sources

- [llama.cpp server README (endpoints + flags)](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md)
- [llama-server(1) manpage (Debian)](https://manpages.debian.org/unstable/llama.cpp-tools/llama-server.1.en.html)
- [llama.cpp speculative decoding docs](https://github.com/ggml-org/llama.cpp/blob/master/docs/speculative.md)
- [llama-swap speculative-decoding examples (Qwen2.5-Coder 32B + 0.5B draft, speedup)](https://github.com/mostlygeek/llama-swap/tree/main/docs/examples/speculative-decoding)
- [Speculative decoding on consumer GPUs — llama.cpp discussion #10466](https://github.com/ggml-org/llama.cpp/discussions/10466)
- [qwen36-4090-recipes — reproducible 4090 configs + silent-corruption (cross-vocab draft) warning](https://github.com/outsourc-e/qwen36-4090-recipes)
- [MTP speculative decoding + KV optimization deep-dive (Qwen3.6-27B)](https://dredyson.com/how-i-mastered-mtp-speculative-decoding-with-llama-cpp-and-qwen3-6-27b-a-complete-technical-deep-dive-into-draft-tokens-turboquant-kv-cache-optimization-and-production-serving-benchmarks-for-local/)
- [Home GPU LLM leaderboard — tok/s by VRAM tier](https://awesomeagents.ai/leaderboards/home-gpu-llm-leaderboard/)
- [RTX 4090 / 3090 / M3 Max tokens-per-second benchmarks (2026)](https://mustafa.net/llm-tokens-per-second-benchmarks/)
- [KV cache quantization quality/perplexity (Q4–Q8, 2026)](https://runaihome.com/blog/quantization-q4-q5-q6-q8-quality-loss-2026/)
- [Bringing K/V context quantisation to Ollama — K more sensitive than V](https://smcleod.net/2024/12/bringing-k/v-context-quantisation-to-ollama/)
- [Asymmetric KV q8/q4 cache discussion #23470](https://github.com/ggml-org/llama.cpp/discussions/23470)
- [systemd watchdog / sd_notify (freedesktop)](https://www.freedesktop.org/software/systemd/man/latest/sd_notify.html)
- [systemd watchdog + Restart health-check guide (2026)](https://oneuptime.com/blog/post/2026-03-02-how-to-configure-systemd-watchdog-for-service-health-checks-on-ubuntu/view)
- [Doctor-Shotgun, MoE offload guide (llama.cpp `-ot`/`--n-cpu-moe`)](https://huggingface.co/blog/Doctor-Shotgun/llamacpp-moe-offload-guide)
- [Understanding MoE Offloading (active vs total params, worked example)](https://dev.to/someoddcodeguy/understanding-moe-offloading-5co6)
- [Qwen3-235B-A22B model card (Hugging Face)](https://huggingface.co/Qwen/Qwen3-235B-A22B)
- [Qwen3-235B-A22B config.json (total/active params, expert routing)](https://huggingface.co/Qwen/Qwen3-235B-A22B/blob/main/config.json)
- [PartnerInAI — `--n-cpu-moe` performance and why speedups happen](https://partnerinai.com/blogs/llamacpp-n-cpu-moe-performance-why-speedups-happen)
- [llama.cpp CPU benchmarks (RAM-bandwidth plateau across instruction sets)](https://www.myaihardware.com/llama-cpp-benchmarks)
- [i9-13900K review — AIDA64 DDR5 memory bandwidth benchmark](https://www.thefpsreview.com/2022/10/20/intel-core-i9-13900k-cpu-review/4/)
- [Tom's Hardware forum — 128GB DDR5 4-DIMM stability on 13900K/Z790](https://forums.tomshardware.com/threads/i-am-struggling-to-match-128gb-ddr5.3805390/)
- [gpt-oss-120b model card (Hugging Face)](https://huggingface.co/openai/gpt-oss-120b)
- [gpt-oss-120b config.json (total/active params, expert routing)](https://huggingface.co/openai/gpt-oss-120b/blob/main/config.json)
- [carteakey.dev — Optimizing gpt-oss-120b speed on consumer hardware (real-world DDR5 bandwidth cross-check)](https://carteakey.dev/blog/local-inference/optimizing-gpt-oss-120b-local-inference/)
- [ik_llama.cpp — llama.cpp fork (IQK kernels, fused MoE ops)](https://github.com/ikawrakow/ik_llama.cpp)
- [ik_llama.cpp PR #520 — GPU-offload batching threshold scaling](https://github.com/ikawrakow/ik_llama.cpp/pull/520)
- [ik_llama.cpp Discussion #164 — AVX2 speedup benchmarks (dense 8B model)](https://github.com/ikawrakow/ik_llama.cpp/discussions/164)
- [ik_llama.cpp Issue #1699 — MoE CPU-offload regression vs mainline on AVX2-only hardware](https://github.com/ikawrakow/ik_llama.cpp/issues/1699)
- [ktransformers — CPU/GPU heterogeneous inference framework](https://github.com/kvcache-ai/ktransformers)
- [ktransformers DeepSeek-R1/V3 tutorial — benchmark numbers (AMX Xeon rig)](https://github.com/kvcache-ai/ktransformers/blob/main/doc/en/DeepseekR1_V3_tutorial.md)
- [ktransformers AMX.md — AMX hardware requirements](https://github.com/kvcache-ai/ktransformers/blob/main/doc/en/AMX.md)
- [Phoronix — KTransformers Adds AVX2 MoE Support (v0.5.3)](https://www.phoronix.com/news/KTransformers-0.5.3)
- [gpt-oss-120b GGUF file listing (ggml-org)](https://huggingface.co/ggml-org/gpt-oss-120b-GGUF/tree/main)
- [GLM-4.5-Air model card (Hugging Face)](https://huggingface.co/zai-org/GLM-4.5-Air)
- [GLM-4.5-Air config.json (total/active params, expert routing)](https://huggingface.co/zai-org/GLM-4.5-Air/blob/main/config.json)
- [GLM-4.5-Air GGUF quant repo (unsloth)](https://huggingface.co/unsloth/GLM-4.5-Air-GGUF)
- [Qwen3-235B-A22B-Instruct-2507 GGUF quant repo (bartowski)](https://huggingface.co/bartowski/Qwen_Qwen3-235B-A22B-Instruct-2507-GGUF)
