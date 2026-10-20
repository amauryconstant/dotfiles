# Local LLM Backend — Research Index

**Status**: Sub-project A (backend core) **implemented** 2026-07-14 (ae9a5b7); its design doc is `_plans/archive/LOCAL_LLM_BACKEND_CORE.md`. Tracks 0–2 are archived; tracks 3–6 stay live as reference for the unstarted sub-projects below.
**Scope**: The **LLM backend and its accompanying tooling** — NOT the consumers.

## Framing

- **Hardware**: RTX 4090 (24 GB VRAM) + i9-13900K (**no AVX-512** → CPU offload is weak; keep inference on GPU). Ample system RAM.
- **Current state**: llama.cpp behind **llama-swap** (`llama-swap.service`, OpenAI-compatible, host/port from `.chezmoidata/ai.yaml`). The roster (roles `coder`/`helper`/`embed`, macros, `resident`/`heavy` groups) is `private_dot_config/llama-swap/config.yaml`; models are pulled into `~/.local/share/models` with `llama-models pull`. `llama-server.service` stays installed but disabled as a fallback (`.chezmoidata/services.yaml`). Packages: `llama-cpp`, `ggml-cuda`, `llama-swap-bin`.
- **Use-case priority**: (1) agentic coding [primary consumer = `opencode`; `pi` future; `claude` stays cloud], (2) shell/CLI helpers, (3) RAG over private docs, (4) voice back-half only (Voxtype already owns STT).
- **Local's role**: experiment/learn — working, hackable, documented > beating cloud.
- **Consumer contract** (constraint, not a research subject): backend must expose an OpenAI-compatible API with **tool/function calling + streaming + embeddings**.
- **Prior-art lessons**: Manifest (Docker + PostgreSQL + auth gateway) dropped as too heavy for single-user; continue.dev dropped; Ollama replaced by llama.cpp.

## Research tracks → output docs

| # | Track | Output doc | State |
|---|-------|-----------|-------|
| 0 | Prior-art & constraints (mine git history) | `_research/archive/LOCAL_LLM_PRIOR_ART.md` | archived |
| 1 | Serving engine capabilities + engine alternatives | `_research/archive/LOCAL_LLM_SERVING_ENGINE.md` | archived (implemented) |
| 2 | Gateway/router & multi-model serving | `_research/archive/LOCAL_LLM_ROUTER.md` | archived (phase 1 implemented) |
| 3 | Model landscape & selection (per role) | `_research/LOCAL_LLM_MODELS.md` | live — roster rationale |
| 4 | RAG / embeddings stack | `_research/LOCAL_LLM_RAG.md` | dormant (sub-project C) |
| 5 | Shell/CLI helper tools + voice back-half | `_research/LOCAL_LLM_CLI_TOOLS.md` | dormant (sub-project B) |
| 6 | Performance tuning + observability/ops | `_research/LOCAL_LLM_PERF_OPS.md` | dormant (parts B, C) |

The June survey `_research/archive/LLM_BACKENDS_RESEARCH.md` predates this split and is archived.

## Next (not started; carried over from the archived backend-core plan)

- **B** — CLI helper: `aichat` + zsh Alt-E widget + `menu-ai` entry (`LOCAL_LLM_CLI_TOOLS.md`).
- **C** — RAG: sqlite-vec + indexer + `retrieve` CLI; populates the `embed` role (`LOCAL_LLM_RAG.md`).
- **D** — Observability surface: `system-health` block, `menu-ai` enrichment, a Quickshell status surface (the plan said Waybar glyph; Waybar is retired), optional `llama-health-check.timer` (`LOCAL_LLM_PERF_OPS.md` Part C).
- **E** — Consumer wiring: opencode `local` provider (`modify_opencode.jsonc` has none yet); Voxtype meeting-summary repoint is moot (voxtype 1.0 dropped that block).
- Large-MoE CPU/RAM offload experiments (`LOCAL_LLM_PERF_OPS.md` Part B).
- Per-model `--reasoning-format` / thinking-mode tuning.
- Known stale consumer: `private_dot_local/lib/scripts/user-interface/executable_menu-ai.tmpl` still checks the disabled `llama-server.service` instead of `llama-swap.service`.

Every research doc: challenge the current assumptions in its domain, evaluate the full software landscape with tradeoffs, give an evidence-based recommendation, and end with a "Dotfiles integration notes" section plus cited sources.
