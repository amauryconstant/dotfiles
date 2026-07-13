# Local LLM Performance Tuning & Observability

**Status**: Research / decision input (2026-07). Repo-only, not deployed.
**Hardware**: RTX 4090 24 GB (Ada, ~1008 GB/s) + i9-13900K **without AVX-512**. Single GPU, single user.
**Backend**: llama.cpp / `llama-server` (OpenAI-compatible), user systemd unit, config via `.chezmoidata/ai.yaml`.
**Workload**: agentic coding (long-ish contexts, tool calling, bursty), shell helpers, embeddings.
**Design lesson carried forward**: keep observability LIGHT — the Manifest Docker+Postgres+Grafana stack was dropped on purpose.

---

## Executive summary

- **Keep everything in VRAM.** On this box, RAM-offloaded layers are a cliff, not a slope: no AVX-512 means CPU matmul falls back to AVX2, roughly halving CPU-side throughput. The 24 GB budget is large enough that the right move is "pick a model + quant + KV-cache config that fits fully in VRAM" rather than "offload N layers." Full offload (`-ngl 99` / `auto`) is already correct in the current unit.
- **Turn on the three cheap wins**: Flash Attention (`--flash-attn on`), **q8_0 KV cache** (`--cache-type-k q8_0 --cache-type-v q8_0`), and an explicit context size. FA is a prerequisite for KV quantization and is a near-free speed/VRAM win on Ada. q8_0 KV roughly halves KV VRAM at perplexity cost of ~0.002–0.05 (imperceptible), buying context headroom.
- **Model sweet spots on a 4090**: a **30B MoE (~3B active)** coder (Qwen3-Coder-30B-A3B class) is the best speed/quality trade — fits at Q4 with room for context, ~70–90 tok/s in coding use. A **32B dense** at Q4 fits but is tight (~22 GB weights, little KV room) and runs ~30–40 tok/s. **7–8B dense** at Q4 runs ~90–110 tok/s and is the shell-helper tier.
- **Speculative decoding** helps dense targets most (32B dense + 0.5–4B draft → ~1.5–2.5x on code, up to ~3x on boilerplate/JSON). It helps a fast MoE far less and can even hurt. **Same-vocabulary drafts only** — cross-vocab drafts silently corrupt tool-call/JSON boundaries.
- **Observability**: `llama-server` already exposes `/health`, `/props`, `/slots`, and (with `--metrics`) a Prometheus `/metrics` endpoint, plus a built-in web UI. That is enough. Recommended surface = `Restart=on-failure` (already set) + a lightweight `ExecStartPost` readiness gate, a `system-health` section that curls `/health` and reads VRAM via `nvidia-smi`, and a Waybar/`menu-ai` glyph. **Skip Prometheus+Grafana** unless a learning exercise is the explicit goal — it is heavier than the whole backend.

---

## Assumptions challenged

- **"Offload some layers to RAM to fit a bigger model."** Not on this CPU. Lacking AVX-512, CPU-resident layers use AVX2 kernels; every token must round-trip through PCIe + slow CPU matmul, and llama.cpp runs the whole graph at the pace of its slowest layers. Real-world reports put a handful of offloaded layers at a 3–10x end-to-end slowdown vs full-VRAM. Prefer: smaller quant, quantized KV, or smaller model — anything to stay 100% on-GPU. (For MoE specifically there is a nuance below.)
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

## Part B: Observability endpoints & lightweight monitoring

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
