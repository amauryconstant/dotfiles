# Local LLM Backend — Research Index

**Status**: Research in progress (dispatched 2026-07-13). Plan creation to follow.
**Scope**: The **LLM backend and its accompanying tooling** — NOT the consumers.

## Framing

- **Hardware**: RTX 4090 (24 GB VRAM) + i9-13900K (**no AVX-512** → CPU offload is weak; keep inference on GPU). Ample system RAM.
- **Current state**: llama.cpp / `llama-server` decided and wired (OpenAI-compatible, `127.0.0.1:8080`, user systemd unit, data-driven via `.chezmoidata/ai.yaml`, models in `~/.local/share/models`). `ai.models` is currently **empty** — nothing is actually served yet.
- **Use-case priority**: (1) agentic coding [primary consumer = `opencode`; `pi` future; `claude` stays cloud], (2) shell/CLI helpers, (3) RAG over private docs, (4) voice back-half only (Voxtype already owns STT).
- **Local's role**: experiment/learn — working, hackable, documented > beating cloud.
- **Consumer contract** (constraint, not a research subject): backend must expose an OpenAI-compatible API with **tool/function calling + streaming + embeddings**.
- **Prior-art lessons**: Manifest (Docker + PostgreSQL + auth gateway) dropped as too heavy for single-user; continue.dev dropped; Ollama replaced by llama.cpp.

## Research tracks → output docs

| # | Track | Output doc |
|---|-------|-----------|
| 0 | Prior-art & constraints (mine git history) | `_research/LOCAL_LLM_PRIOR_ART.md` |
| 1 | Serving engine capabilities + engine alternatives | `_research/LOCAL_LLM_SERVING_ENGINE.md` |
| 2 | Gateway/router & multi-model serving | `_research/LOCAL_LLM_ROUTER.md` |
| 3 | Model landscape & selection (per role) | `_research/LOCAL_LLM_MODELS.md` |
| 4 | RAG / embeddings stack | `_research/LOCAL_LLM_RAG.md` |
| 5 | Shell/CLI helper tools + voice back-half | `_research/LOCAL_LLM_CLI_TOOLS.md` |
| 6 | Performance tuning + observability/ops | `_research/LOCAL_LLM_PERF_OPS.md` |

Every doc must: challenge the current assumptions in its domain, evaluate the full software landscape with tradeoffs, give an evidence-based recommendation, and end with a "Dotfiles integration notes" section (feeding the later plan) plus cited sources.
