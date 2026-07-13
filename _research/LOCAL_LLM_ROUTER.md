# Local LLM Router / Multi-Model Serving — Evaluation

**Status**: Research (2026-07-13). Track 2 of the Local LLM Backend research (see `LOCAL_LLM_BACKEND_INDEX.md`).
**Scope**: Whether to put a gateway/router/multi-model serving layer in front of `llama-server` on a single 24 GB GPU — and if so, the lightest one.
**Hardware**: RTX 4090 24 GB (single GPU) + i9-13900K (no AVX-512 → keep inference on GPU). Ample RAM.
**Prior-art lesson**: Manifest (Docker + PostgreSQL + auth + web dashboard) was built and **abandoned** as far too heavy for a single-user box. Nothing in that weight class is acceptable.

---

## Executive summary

**Router: YES — but only a process/VRAM swapper, not a cloud gateway.** Recommend **llama-swap** (single Go binary, zero deps, AUR-packaged) in front of `llama-server`.

**Why a router at all**: The three wanted roles — agentic **coder** (large), **small fast** helper, **embeddings** — do *not* fit in 24 GB at useful context sizes (math below). Something must arbitrate VRAM. Bare llama-server can't; multiple fixed instances can't evict. llama-swap does on-demand load/unload + can keep the two tiny models co-resident and always-on.

**Why NOT a cloud gateway (LiteLLM/Olla/Manifest-class)**: The "single endpoint that also routes to cloud Claude" motivation is **already solved at the consumer layer** — opencode natively lists multiple providers (it already carries `zhipuai`, `minimax`; Claude Code uses profile env vars). Adding a proxy to merge local+cloud re-introduces exactly the gateway weight that got Manifest killed, for a problem the consumer already handles. Keep cloud routing where it is.

**Key architectural insight**: LiteLLM and llama-swap operate at *different layers* and are not substitutes. **LiteLLM does not manage VRAM or process lifecycle** — it only routes to endpoints that are *already running*. So LiteLLM alone cannot solve the 24 GB problem; you'd still need llama-swap underneath it. That makes llama-swap the necessary piece and LiteLLM the optional (deferred) one.

**VRAM conclusion**: coder + helper + embeddings cannot be statically co-resident with real context. But helper (~3 GB) + embeddings (~1 GB) *are* tiny and idle-cheap → keep them in a **persistent, non-swapping group (~4 GB always-on)**, and let the heavy coder **swap** in/out of the remaining ~20 GB. This is precisely llama-swap's group model.

---

## Assumptions challenged (do we even need this?)

Four candidate "do nothing / do less" positions, weighed honestly:

1. **Single model + manual switch (status quo, `ai.models` empty).** Edit `~/.config/llama-server/env`, `systemctl --user restart llama-server`. Zero new software. *Fails* the actual requirement: you can't have a coder session and a shell-helper answer and an embeddings call without a 5–15 s manual restart each time. Embeddings especially want to be *always* available (RAG indexing runs alongside chat). Rejected as the primary mode, but it remains the ultimate fallback.

2. **Multiple `llama-server` systemd instances on fixed ports (coder:8080, helper:8081, embed:8082).** No new dependency — pure systemd. *But*: each instance grabs and holds its VRAM at start. To run all three you must pre-budget so the sum + KV never exceeds 24 GB, which forces the coder down to ~14 B (weak). There is **no eviction**: you cannot have "big coder OR (helper+embed)" — only fixed partitions. A consumer must also know which port = which role (three base URLs), losing the single-endpoint contract. This is the honest main rival to llama-swap and it loses on exactly the thing that matters: dynamic VRAM arbitration.

3. **No router; consumer does provider selection.** For *cloud* routing this is correct and already true (opencode/Claude Code pick providers). But it does nothing for *local multi-model VRAM* — the consumer can't start/stop GPU processes. So this handles motivation #2 (hybrid) but not motivation #1 (three local roles).

4. **A full gateway (LiteLLM/Olla/Manifest).** Solves cloud routing elegantly but (a) still needs a swapper underneath for VRAM, and (b) is the abandoned weight class (LiteLLM's headline features — virtual keys, spend tracking, admin UI — require Postgres; without a DB it's a "limited passthrough" that duplicates what opencode already does). Rejected as default.

**Verdict**: The genuine unmet need is **local VRAM arbitration across 3 roles**, not cloud routing. That need is real and small. The lightest tool that fills exactly it is llama-swap.

---

## The 24 GB multi-model VRAM problem (budgeting math)

Weights only, GGUF Q4_K_M unless noted; KV cache is *extra* and grows with context. Figures from the backend research + current model sizes.

| Role | Candidate | Weights (Q4_K_M) | KV @ 32k ctx | Notes |
|------|-----------|------------------|--------------|-------|
| Coder (dense) | Qwen2.5-Coder-32B | ~19 GB | ~3–4 GB | 32B dense; strong but KV pushes it **over 24 GB** at 32k |
| Coder (MoE) | Qwen3-Coder-30B-A3B | ~18 GB | ~2–3 GB | 3B active → much faster; still ~20–21 GB with modest ctx |
| Coder (smaller) | Qwen2.5-Coder-14B | ~9 GB | ~2 GB | Fits comfortably; weaker agentic coding |
| Helper (fast) | Qwen2.5-3B / Llama-3.2-3B | ~2–3 GB | <1 GB | Shell/CLI one-liners, low latency |
| Embeddings | bge-m3 / nomic-embed-text | ~0.3–1.5 GB | negligible | RAG indexing + query |

**Naive sum (big coder + helper + embed):** 19 + 3 + 1 = **23 GB weights, zero headroom for KV** → not viable at any real context. Even the MoE coder leaves only ~2 GB for the coder's own KV — impractical for agentic (long) sessions.

**Three viable strategies:**

- **A. Swap the heavy one (RECOMMENDED).** Persistent group `{helper 3B + embed 1B}` ≈ 4 GB always loaded. Coder (30B-A3B or 32B) swaps into the remaining ~20 GB with full KV budget. When you invoke the coder, llama-swap evicts nothing small (they're 4 GB) — it just loads the coder alongside; if a *second* heavy model is ever requested, the swap group unloads the first. Cold-load cost paid once per coder session (see latency below).
- **B. Budget everything resident.** Coder-14B (9 GB) + helper (3 GB) + embed (1 GB) = 13 GB, ~11 GB left for KV — all three concurrent, no swapping. Simpler, but you permanently give up the 30B-class coder.
- **C. Fixed instances (strategy #2 above).** Same budget as B but via three systemd units; no ability to trade up to the big coder on demand.

Strategy A is strictly more capable than B/C because it lets you run the *big* coder when you want it and reclaim its VRAM when you don't, while the cheap-and-always-useful helper+embeddings never pay swap latency. Only llama-swap (or an equivalent process manager) delivers A.

---

## Landscape & tradeoff table

Scored for this single-user local box. "Weight" penalizes Docker/Postgres/Python-stack hard (the Manifest lesson).

| Tool | Layer | Hot-swap / VRAM mgmt | Local+cloud routing | OpenAI + tools + embeddings passthrough | Weight / deps | systemd fit | Hackability | Verdict |
|------|-------|----------------------|---------------------|------------------------------------------|---------------|-------------|-------------|---------|
| **Bare llama-server** (1 model) | engine | ❌ manual restart | ❌ | ✅ native | none (already have) | ✅ have unit | n/a | Fallback only |
| **N× llama-server** (fixed ports, systemd) | engine | ⚠️ static partition, **no eviction** | ❌ | ✅ but N base URLs | none | ✅ trivial | ✅ | Rival to A; loses on dynamic VRAM + single endpoint |
| **llama-swap** | process/VRAM proxy | ✅ **on-demand load/unload, groups, TTL, persist** | ❌ (swaps local upstreams only) | ✅ **transparent** (`/v1/...` + Anthropic `/v1/messages` + `/v1/embeddings`) | **1 Go binary, zero deps**, AUR (`llama-swap-bin`) | ✅ one user unit | ✅ YAML, hackable | **RECOMMENDED** |
| **LiteLLM proxy** | cloud gateway | ❌ (routes to running endpoints; no VRAM mgmt) | ✅ 100+ providers, fallbacks | ✅ (translates formats) | Python + `[proxy]` extra; **Postgres for keys/spend/UI** (DB-less = degraded passthrough) | ⚠️ Python venv unit | ⚠️ config-heavy | Deferred; overkill, echoes Manifest |
| **Olla** | cloud gateway / LB | ❌ (no process mgmt) | ✅ + can front LiteLLM | ✅ | **1 Go binary, ~50 MB RAM, <2 ms** | ✅ | ✅ | Lighter LiteLLM alt if cloud-in-proxy ever needed |
| **Ollama** (as swapper) | engine + swapper | ✅ auto load/unload | ❌ | ✅ but its own API dialect; less quant control | Go daemon, model registry | ✅ | ⚠️ opinionated | Rejected earlier (backend research); no reason to re-add |
| **GPUStack** | cluster manager | ✅ but cluster-scale | ⚠️ | ✅ | heavy (worker/server, web UI, DB) | ❌ | ⚠️ | Overkill (multi-node product) |
| **Manifest** (prior art) | gateway | ❌ | ✅ | ✅ | **Docker + Postgres + auth + dashboard** | ❌ | ❌ | **Abandoned — reference for "too heavy"** |

---

## Deep dive: llama-swap and LiteLLM

### llama-swap (github.com/mostlygeek/llama-swap)

- **What it is**: A ~single Go binary, zero runtime deps, that presents **one OpenAI- and Anthropic-compatible front door** and maps each requested `model` name to a command that launches the right upstream (`llama-server`, vLLM, etc.). On request it reads the `model` field, starts the backend if not running, and proxies. Actively maintained (v200+ series shipping through 2026; ~3k+ stars). AUR: `llama-swap` (source) and `llama-swap-bin` (binary).
- **Config** (`config.yaml`): per-model `cmd` (the full `llama-server ...` line), optional `proxy`/`ttl`/`env`/`aliases`; a `${PORT}` macro auto-assigns ports so several models can run concurrently; reusable `macros`. Example shape:
  ```yaml
  macros:
    llama: "/usr/bin/llama-server --host 127.0.0.1 --port ${PORT} --n-gpu-layers 99"
  models:
    coder:
      cmd: "${llama} --model ${HOME}/.local/share/models/qwen3-coder-30b-a3b-q4_k_m.gguf --ctx-size 32768"
      ttl: 900          # unload after 15 min idle, freeing ~20 GB
    helper:
      cmd: "${llama} --model .../qwen2.5-3b-instruct-q4_k_m.gguf --ctx-size 8192"
    embed:
      cmd: "${llama} --model .../bge-m3-q4_k_m.gguf --embeddings"
  ```
- **VRAM budgeting / eviction**: `groups` control concurrency. `swap: false` group = all members stay co-resident; `swap: true` = one member at a time; `persistent: true` = never evicted. The winning layout: a **persistent, non-swap group** `{helper, embed}` (always on, ~4 GB) + the **coder** free to load into remaining VRAM and auto-unload via `ttl`. A newer **"swap matrix"** DSL exists for heterogeneous VRAM combos if groups get too coarse.
- **Cold-swap latency**: first hit on an unloaded model pays *launch llama-server + mmap/load GGUF into VRAM* — roughly a few seconds for small models, ~5–15 s for a 20 GB coder off NVMe (one-time per session; subsequent requests are warm). Mitigation: hit `/upstream/<model>` to **pre-warm** before the first real request; give small models no `ttl` (stay resident); give the coder a generous `ttl` so a work session doesn't reload mid-flow.
- **OpenAI / tool-calling / embeddings pass-through**: **transparent** — llama-swap is an HTTP proxy, so tool/function-calling, streaming, and JSON schemas are whatever the upstream `llama-server` supports; llama-swap doesn't rewrite bodies. Endpoints include `/v1/chat/completions`, `/v1/completions`, `/v1/embeddings`, `/v1/models`, plus **Anthropic `/v1/messages`** and llama.cpp rerank/completion. This preserves the consumer contract exactly.
- **systemd fit**: one user unit runs `llama-swap --config ...`; it *becomes the parent* of the `llama-server` subprocesses (replaces the current single-model `llama-server.service`). Listens on the canonical `127.0.0.1:8080`.
- **Hackability**: plain YAML, readable Go, local web UI for status; trivial to add/remove roles by editing the map. Fits the "experiment/learn" goal.
- **Limitation**: swaps *local upstreams only* — it does **not** call out to cloud Claude/OpenAI. That's fine: cloud routing lives in the consumer.

### LiteLLM (github.com/BerriAI/litellm)

- **What it is**: The most widely adopted OSS LLM gateway — 100+ providers, format translation, fallback chains, virtual keys, spend tracking, guardrails, logging. Python SDK + proxy (`litellm[proxy]`).
- **Local+cloud**: genuinely good at it — register `llama-server` as one provider and Anthropic as another behind one `:4000/v1` endpoint, with `fallbacks:` (e.g. try local, fall back to cloud on error) and per-provider cooldown.
- **The catch (weight)**: the features that justify LiteLLM — **virtual keys, spend tracking, admin UI — require PostgreSQL** (set `DATABASE_URL`; Prisma migrations). Run it **DB-less** and you get only "limited passthrough" routing — i.e. the part opencode already does natively. So for this box LiteLLM is either (a) Manifest-weight (Postgres + Python service), or (b) redundant with the consumer. Either way it does **no VRAM/process management**, so it can never replace llama-swap; at best it sits *in front of* llama-swap.
- **When it would earn its place**: only if a future consumer *cannot* do its own provider selection and you truly need one URL for local+cloud with fallback. Even then, **Olla** (single Go binary, ~50 MB, <2 ms overhead, can itself front LiteLLM) is the lighter way to get local+cloud unification, and it too would sit above llama-swap.

---

## Hybrid local↔cloud routing (how, and key management)

**Recommendation: do it at the consumer, not in a proxy.** Rationale:

- opencode already declares multiple providers in `modify_opencode.jsonc` (`zhipuai`, `minimax`, each with its own base URL / key). Adding **local** llama-swap is just one more provider entry (`baseURL: http://127.0.0.1:8080/v1`, dummy key). The user selects model/provider per session — which is exactly what agentic coding wants (deliberate "use the big cloud model for this hard task").
- Claude Code uses **profile env vars** (`ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN` in `private_dot_config/claude/profiles/*.json.tmpl`) to point at Anthropic or Anthropic-compatible clouds. Same pattern; no proxy needed.
- This keeps the local side dumb and fast (llama-swap, no cloud egress) and avoids a always-on gateway holding cloud keys in memory.

**Key management fit (age-encrypted keys)**: The repo already decrypts keys **at chezmoi render time** into consumer configs — see `modify_opencode.jsonc`:
```
{{- $minimaxKey := joinPath .chezmoi.sourceDir "private_dot_keys" "encrypted_private_minimax-key.txt.age" | include | decrypt | trim -}}
```
`private_dot_keys/encrypted_private_anthropic-key.txt.age` already exists. The clean pattern: the **cloud key is decrypted into the consumer config** (opencode provider / Claude profile) via the same `include | decrypt | trim` idiom — never into the local proxy. llama-swap needs **no secrets at all** (local upstreams, dummy key). This is the tidiest possible key story and avoids putting an age-decrypted cloud key into a long-running proxy's environment.

**If a unified endpoint is ever mandated** (Phase 2 below), the age key would be decrypted into a LiteLLM/Olla config file the same way — but note that means a plaintext key on disk in a service config, a downgrade from render-time-into-consumer. Prefer to avoid.

---

## Recommendation (+ phased fallback)

**Adopt llama-swap as the local serving layer. Keep cloud routing in the consumers. Do not add a cloud gateway.**

- **Phase 0 (fallback / today)**: single `llama-server` unit, manual model switch. Already wired; `ai.models` empty. Keep as the always-works floor.
- **Phase 1 (recommended target)**: `llama-swap.service` (user unit) on `127.0.0.1:8080`, replacing the single-model `llama-server.service`. Roles as models: persistent `{helper, embed}` group (~4 GB always-on) + swappable `coder` (`ttl` ~15 min). Consumers keep pointing at the one endpoint; they just vary the `model` name. `ai.yaml` grows a models-as-roles schema (below).
- **Cloud (parallel, unchanged)**: opencode/Claude select cloud providers themselves; Anthropic key decrypted into their configs at render time.
- **Phase 2 (deferred, only if a real need appears)**: if a consumer emerges that can't do provider selection and a single local+cloud URL with fallback becomes necessary, add **Olla** (preferred, 1 Go binary) or **LiteLLM DB-less** *in front of* llama-swap. Explicitly *not* Postgres-backed LiteLLM (Manifest weight). Revisit only on evidence.

**Why this is the lightest thing that works**: one extra Go binary, one systemd unit, one YAML file, zero daemons/DBs/containers, keeps the exact OpenAI+Anthropic+tools+embeddings contract, and solves the one genuinely unmet need (24 GB arbitration) while leaving the already-solved need (cloud routing) alone.

---

## Open questions

- **Coder choice drives the swap budget**: Qwen3-Coder-30B-A3B (MoE, faster, ~18 GB) vs Qwen2.5-Coder-32B (dense, stronger, ~19 GB + heavier KV) vs 14B (fits resident, weaker). Decided in the *models* track (`LOCAL_LLM_MODELS.md`), but it determines whether Strategy A (swap) or B (all-resident 14B) is even a choice.
- **Cold-load tolerance**: is a ~5–15 s coder warm-up per session acceptable, or should the coder also be `persistent` (then helper/embed must shrink/share)? Depends on real usage cadence.
- **Embeddings concurrency during coder load**: if RAG indexing runs while the coder is swapping, confirm llama-swap keeps the persistent embed model serving uninterrupted (expected with `swap:false persistent`, worth a smoke test).
- **KV cache quantization** (`--cache-type-k/v q8_0`) could claw back several GB and make a 30B coder + more context fit — tuning question for the perf track.
- **llama-swap config schema drift**: v200+ has evolved group/routing keys; pin to the installed version's docs when writing the actual config (the snippets here are illustrative).
- **Anthropic `/v1/messages` for Claude Code → local**: llama-swap exposes it, so Claude Code *could* point at local models via a profile. Worth validating if desired, but not required.

---

## Dotfiles integration notes

Feeds the later implementation plan. Nothing here is applied yet.

### Packages (`.chezmoidata/packages.yaml`)
- Add `llama-swap-bin` (AUR, binary — avoids Go build) to the same "Local AI inference" group as `llama.cpp-bin` / `cuda`. Respect the package-security policy (AUR review) in `private_dot_local/lib/scripts/system/CLAUDE.md`.

### systemd (`private_dot_config/systemd/user/`)
- **New** `llama-swap.service.tmpl`: `ExecStart=/usr/bin/llama-swap --config %h/.config/llama-swap/config.yaml --listen {{ .ai.server.host }}:{{ .ai.server.port }}`. `After=network-online.target`, `Restart=on-failure`, `WantedBy=default.target`. It parents the `llama-server` subprocesses.
- **Retire/keep** `llama-server.service.tmpl`: llama-swap launches `llama-server` itself, so the standalone unit becomes redundant in Phase 1. Options: (a) delete it, or (b) keep it behind a `services.yaml` toggle as the Phase-0 fallback. Recommend keeping it but disabled (`enabled: false`) so the fallback path stays one flag away.
- Update `services.yaml` `user_services`: add `llama-swap.service` (`requires_command: llama-swap`), flip `llama-server.service` to `enabled: false`. Enablement flows through `run_once_after_002_configure_system_services` (the `requires_command` gate already exists).
- Update `private_dot_config/systemd/user/CLAUDE.md` table (currently documents `llama-server.service`).

### Config generation (`ai.yaml` → llama-swap `config.yaml`)
- Evolve `.chezmoidata/ai.yaml` `models: []` into **models-as-roles**, e.g.:
  ```yaml
  ai:
    server: { host: "127.0.0.1", port: 8080, n_gpu_layers: 99 }
    models_dir: "~/.local/share/models"
    roles:
      coder:   { file: qwen3-coder-30b-a3b-q4_k_m.gguf, url: "https://huggingface.co/...", ctx: 32768, ttl: 900, group: heavy }
      helper:  { file: qwen2.5-3b-instruct-q4_k_m.gguf, url: "...", ctx: 8192, group: resident }
      embed:   { file: bge-m3-q4_k_m.gguf, url: "...", embeddings: true, group: resident }
    groups:
      resident: { swap: false, persistent: true }
      heavy:    { swap: true }
  ```
- Render `~/.config/llama-swap/config.yaml` from `ai.roles`/`ai.groups` via a new `.tmpl` (mirror how `run_onchange_after_install_ai_models` already generates `~/.config/llama-server/env`). Reuse the existing resumable `wget -c` model-download logic for `roles[].url`.
- Trigger: extend/replace `run_onchange_after_install_ai_models.sh.tmpl` with a hash over `{{ .ai | toJson | sha256sum }}` so config + downloads re-run on role changes. Update `.claude/rules/chezmoi-data.md` (`ai.yaml` row) and `chezmoi-scripts.md` accordingly.

### Consumers (unchanged endpoint, new model names)
- opencode: add a `local` provider (`baseURL http://127.0.0.1:8080/v1`, dummy key) alongside existing cloud providers in `modify_opencode.jsonc`; reference `coder`/`helper` by model name.
- Cloud keys keep the render-time `include | decrypt | trim` pattern already used for `minimax`; `encrypted_private_anthropic-key.txt.age` decrypts into the *consumer* config, never into llama-swap.

### Age-key wiring
- **llama-swap: no keys.** Do not wire any age secret into the proxy unit or config.
- If Phase 2 (LiteLLM/Olla) is ever adopted, decrypt the cloud key into *its* config via `joinPath .chezmoi.sourceDir "private_dot_keys" "encrypted_private_anthropic-key.txt.age" | include | decrypt | trim` — but note this writes plaintext into a service config and is a reason to prefer the consumer-side approach.

---

## Sources

- llama-swap — https://github.com/mostlygeek/llama-swap
- llama-swap configuration — https://github.com/mostlygeek/llama-swap/blob/main/docs/configuration.md , https://github.com/mostlygeek/llama-swap/blob/main/config.example.yaml
- llama-swap groups & swapping policies — https://deepwiki.com/mostlygeek/llama-swap/3.4-groups-and-swapping-policies
- llama-swap quickstart — https://www.glukhov.org/llm-hosting/llama-swap/
- llama-swap setup guide (2026) — https://modelslab.com/blog/api/hot-swap-local-llms-instantly-llama-swap-setup-guide-2026
- llama-swap AUR — https://aur.archlinux.org/packages/llama-swap , https://aur.archlinux.org/packages/llama-swap-bin
- llama.cpp Anthropic Messages API — https://huggingface.co/blog/ggml-org/anthropic-messages-api-in-llamacpp
- LiteLLM — https://github.com/BerriAI/litellm , https://docs.litellm.ai/docs/proxy/configs , https://docs.litellm.ai/docs/proxy/deploy
- LiteLLM DB-less limits — https://docs.litellm.ai/docs/proxy/prod , https://github.com/BerriAI/litellm/issues/2532
- Olla vs LiteLLM — https://thushan.github.io/olla/compare/litellm/ , https://tensorfoundry.io/blog/olla-vs-litellm , https://thushan.github.io/olla/
- LLM gateway landscape — https://blog.openziti.io/comparing-open-source-llm-gateways , https://www.truefoundry.com/blog/litellm-alternatives
