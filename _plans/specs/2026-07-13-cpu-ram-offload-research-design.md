# Design: Deepen CPU/RAM offload research in LOCAL_LLM_PERF_OPS.md

**Status**: Approved, ready for implementation.
**Target file**: `_research/LOCAL_LLM_PERF_OPS.md`
**Type**: Research content addition (no code/config changes).

## Motivation

`LOCAL_LLM_PERF_OPS.md` currently treats CPU/RAM offload as effectively disqualified on the 4090 + i9-13900K (no AVX-512) box, on the grounds that CPU-resident layers fall back to AVX2 and community reports put full offload at a 3–10x slowdown. That conclusion is correct for the box's current use case (models that fit in 24GB VRAM at some quant — 30B-A3B MoE, 32B dense, 7-8B dense).

It stops being the relevant question once a candidate model is too large to fit in 24GB VRAM under any reasonable quant — e.g. a 100B+ total-param MoE. The 4090 box has 128GB system RAM (confirmed against the 4090/13900K box specifically, not the 32GB machine also referenced during scoping). This design adds research covering that regime: is CPU+RAM offload of a large MoE's cold experts viable on this hardware despite lacking AVX-512, and if so, which models/configs are worth trying.

## Scope decisions made during brainstorming

- **Target model class**: undecided/general — the research should establish the ceiling (what's the biggest/best model viable with partial offload) rather than assume one specific model.
- **RAM ceiling**: 128GB, on the 4090+13900K desktop.
- **Backend scope**: mainline llama.cpp (already the repo's backend) **plus** a survey of forks/projects known for better CPU-offload performance (ik_llama.cpp, ktransformers) — as a comparison/ceiling reference, not a proposal to switch backends now. Adopting an alt backend is out of scope; it's a separate future integration decision (packaging, systemd unit, supply-chain trust per this repo's security-first posture).
- **Research depth**: desk synthesis + a concrete self-validation benchmark recipe (not full empirical validation — no access to run it on the actual box, and downloading 100GB+ model weights mid-research isn't reasonable). Every throughput number must be labeled "sourced" (cited) or "projected" (derived from the bandwidth formula) — no invented precision presented as fact.

## Structural changes to the doc

1. **Header (line 4)**: add system RAM (128GB) to the hardware line — currently unstated, now a governing constraint for this new material.
2. **Executive summary bullet 1**: keep "stay in VRAM" as the guidance for anything that fits at a reasonable quant; add a pointer to the new Part B for models that don't fit regardless of quant.
3. **Assumptions challenged bullet 1**: same treatment — the "offload is a cliff" framing stays correct for the current use case, gets scoped rather than reversed.
4. **New section**: insert **"Part B: CPU/RAM offload for large MoE (128GB ceiling)"** between the existing "Speculative decoding deep dive" and the current "Part B: Observability & lightweight monitoring" (which is renumbered to "Part C"). Update the "Open questions" and "Sources" sections at the end accordingly.

## New Part B — content outline

1. **Why the calculus changes for large MoE**: recap the existing `--n-cpu-moe`/`-ot` mechanism — offloaded CPU compute scales with *active* params per token, not total params. A 235B-A22B model offloading experts does ~22B-equivalent FFN math per token on CPU, not 235B. This is why large sparse MoE is the one regime where offload was already flagged (line 23 of the current doc) as worth a second look.
2. **The real bottleneck is RAM bandwidth, not AVX-512**: offloaded-expert inference is memory-bandwidth-bound (stream weights from RAM, low arithmetic intensity per byte), not compute-bound. AVX-512 mainly accelerates compute-bound kernels — so the AVX2-vs-512 gap matters much less here than it does for the dense-CPU-inference case the current doc is right to warn against. This is the key nuance being added, and the main partial-revision to the existing blanket claim.
3. **Worked throughput model**: `tok/s ≈ RAM_bandwidth / (active_bytes_per_token)`, with a worked numeric example using the box's actual (or reasonably assumed, pending the open question below) DDR5 bandwidth, cross-checked against real community numbers for comparable rigs (4090 + high-capacity DDR5, no AVX-512) running large MoE with partial offload.
4. **Alternative backends survey**: ik_llama.cpp (AVX2-tuned quant kernels, reportedly smarter MoE offload than mainline) and ktransformers (hybrid CPU+GPU MoE serving) — with an explicit note that ktransformers' AMX fast path is Xeon-only and does not apply to the 13900K. Framed as "here's the ceiling other tooling claims," not a switch recommendation.
5. **RAM budget table**: candidate large-MoE models (e.g. Qwen3-235B-A22B, GLM-4.5-Air/106B-A12B, gpt-oss-120b) — total weight size per quant vs the 128GB ceiling, and an estimate of how much lands in VRAM (attention + shared layers + a few hot experts + KV) vs system RAM (cold experts).
6. **Benchmark recipe**: concrete `llama-server`/`llama-bench` invocation using `-ot "exps=CPU"` or `--n-cpu-moe N` to keep attention/shared layers on GPU and offload only expert FFNs, plus what to measure (`/metrics`, `llama-bench` decode tok/s). Recommend trialing on a smaller MoE first (e.g. artificially forcing partial offload on the existing 30B-A3B) before pulling 100GB+ of weights for an untested config.
7. **Decision framework**: a table translating "candidate model's weight size at chosen quant" into "full VRAM (existing guidance) / partial offload worth trying / not worth it on this hardware," anchored to an explicit usability tok/s floor to compare projected numbers against.

## Sourcing approach

- Live research (WebSearch/WebFetch) during write-up to find real reports for Qwen3-235B-A22B / GLM-4.5-Air / gpt-oss-120b CPU+GPU partial-offload throughput on comparable non-AVX-512 rigs, and for ik_llama.cpp/ktransformers claims — not relying on unverified training-data recall for numbers that may be stale.
- New entries added to the **Sources** list for whatever is actually cited.

## New open question to add

- **DDR5 bandwidth on the 128GB box is unknown** (speed, channel/DIMM population — 4-DIMM 128GB configs commonly run slower than 2-DIMM due to signal integrity on Raptor Lake boards). This materially changes the worked throughput example. Needs an empirical check (`sudo dmidecode --type 17` or `lshw -C memory`) before trusting the numbers — flag this explicitly rather than assuming a speed.

## Out of scope

- No changes to `.chezmoidata/ai.yaml`, the systemd unit, or any actual config — this is research content only.
- No commitment to a specific large-MoE model or backend switch — Part B informs a future decision, it doesn't make one.
- No actual benchmark run performed as part of this work (no access to the target box).
