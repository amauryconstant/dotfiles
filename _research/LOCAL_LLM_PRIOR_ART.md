# Local LLM Backend — Prior Art & Constraints

**Status**: Git-archaeology record (compiled 2026-07-13). Track 0 of the Local LLM research effort — see `_research/LOCAL_LLM_BACKEND_INDEX.md`.
**Purpose**: Document every past attempt at a local LLM backend in this repo, why each was abandoned, and the hard constraints those failures impose on future work.
**Method**: Mined `git log --all` + per-commit diffs. Facts are sourced to commit SHAs; judgement calls are labelled **[inferred]**.

> **Date caveat**: Commit author-dates in this repo are unreliable. The Ollama/continue.dev era is stamped **2025-05 → 2025-08**, the llama.cpp/Manifest era **2026-05 → 2026-06**. Some clocks are clearly wrong (the llama.cpp migration is stamped a day *before* Ollama's fix commits in wall-clock terms). Treat the **relative ordering within each era** as reliable, absolute dates as approximate.

---

## Executive summary

There have been **four** distinct local-LLM efforts, all now dead or superseded:

1. **Ollama era** (2025-05) — Ollama daemon + `qwen2.5-coder` + `nomic-embed-text`, consumed by **continue.dev** in VS Code. Worked as an autocomplete/embed backend with cloud Claude for chat.
2. **Submodule/separate-repo saga** (2025-07 → 2025-08) — AI config repeatedly moved out to a git submodule and back. Pure infrastructure churn, ~6 weeks, ended by deleting the submodule. Nothing about *inference* changed.
3. **llama.cpp migration** (2026-05) — Ollama ripped out, replaced by `llama-server` (this is the surviving baseline). continue.dev/VS Code decommissioned around the same window.
4. **Manifest router** (2026-05, branch `manifest-server`) — a Docker-Compose gateway (Manifest + PostgreSQL + auth + web dashboard) fronting `llama-server` with a 35B Q8_0 model. **Never merged to main**; abandoned on a side branch.

The current `main` ships a **minimal, correct llama.cpp skeleton with zero models configured** (`ai.models: []`) — nothing is actually served yet. The heavyweight gateway experiment (Manifest) and the IDE-plugin experiment (continue.dev) were both tried and rejected. The consistent trajectory is **toward less infrastructure**: daemon → thin systemd unit; gateway+DB → nothing; IDE plugin → editor-agnostic OpenAI endpoint.

---

## Timeline of attempts

| # | Attempt | What it was | When (approx) | Fate | Why dropped |
|---|---------|-------------|---------------|------|-------------|
| 1 | **Ollama** | `ollama` pkg + user service; `ai.yaml` models list (`qwen2.5-coder:1.5b`, `nomic-embed-text`) | 2025-05-12 (`67fee9d`) | Replaced by llama.cpp | **Fact**: "better VRAM efficiency" (`183cfac`). **[inferred]** curated model mgmt + background daemon unnecessary for single user; less quant control |
| 2 | **continue.dev** | VS Code plugin: Ollama for autocomplete+embed, cloud Claude 3.5 for chat/edit; rich context providers | 2025-05-12 (`a43746c`) | Archived then deleted | **Fact**: config archived (`e7974d9`), VS Code AI extensions removed (`89b95cc`). **[inferred]** IDE-plugin coupling abandoned in favour of editor-agnostic OpenAI endpoint (opencode/claude-code) |
| 3 | **AI-as-submodule** | AI config/scripts moved to a separate git repo + submodule, then moved back | 2025-07-14 → 2025-08-25 (`9659224`…`2e93048`) | Reverted; submodule deleted | **Fact**: submodule scripts "were not being executed during chezmoi apply … deployed as static files" (`0fb8c04`). Split repo broke chezmoi's script lifecycle |
| 4 | **llama.cpp (AUR CUDA)** | `llama-cpp-cuda` + `llama-server.service`; `ai.yaml` restructured (server cfg + empty models) | 2026-05-05 (`183cfac`) | Superseded by binary pkg | **Fact**: `llama-cpp-cuda` (AUR) failed to compile under gcc15 (`6ae137f`) |
| 5 | **llama.cpp (`llama.cpp-bin`)** | Swap AUR source build → pre-compiled binary; fix printf templating | 2026-05-06 (`6ae137f`) | **Current baseline** | — |
| 6 | **Manifest router** | Docker-Compose: Manifest gateway + PostgreSQL + auth + dashboard, fronting llama-server; Qwen3.6-35B-A3B Q8_0 | 2026-05-06 (`2d31be1`, branch `manifest-server`) | **Never merged**; abandoned side branch | **[inferred]** Docker + Postgres + auth + generated secrets = far too heavy for a single-user local box; 35B Q8_0 (36.9 GB) doesn't fit 24 GB VRAM |
| 7 | **Data-driven llama.cpp** | Template host/port from `ai.yaml` (fix 8100/8080 drift); resumable download; strip stale Ollama refs | 2026-06-24 (`4b3d802`) | **Current baseline** | — |
| 8 | **Decision record** | Wrote `LLM_BACKENDS_RESEARCH.md` decision section | 2026-06-24 (`9e087c8`) | Current | — |

---

## Attempt deep-dives

### 1 + 2. Ollama + continue.dev era (2025-05)

**Stack** (`67fee9d`, `33839a6`, `a43746c`):
- `ollama` added to Arch packages; `ollama.service` user unit; `run_once_after_003_configure_ollama.sh.tmpl`.
- `ai.yaml` started as a bare model list — first `qwen2.5-coder:32b`, then downgraded to `qwen2.5-coder:1.5b` + `nomic-embed-text:latest` (`a43746c`).
- `dot_continue/config.yaml.tmpl` wired three roles: **autocomplete** → Ollama `qwen2.5-coder:1.5B`, **embed** → Ollama `nomic-embed-text`, **chat/edit/apply/summarize/rerank** → cloud `claude-3-5-sonnet-latest` (API key via `age`-decrypted `encrypted_just-anthropic-key.txt.age`). Context providers: code, docs, diff, terminal, problems, folder, codebase.

**Reading of it**: This was the only era where a local model was *actually configured and consumed* end-to-end. The design was already hybrid — local for cheap high-frequency tasks (autocomplete, embeddings), cloud for reasoning. The 32B→1.5B downgrade is telling: **[inferred]** 32B autocomplete was impractically slow/large, so it was cut to a 1.5B model that fits comfortably and responds fast enough for inline completion.

**Fate**: continue.dev config archived (`e7974d9`, "Remove Continue IDE configuration" → moved to `archives/`), then VS Code AI extensions removed wholesale (`89b95cc`). **[inferred]** The user moved off IDE-embedded assistants toward terminal-native agentic tools (opencode, claude-code), which the current `menu-ai` confirms. The lesson carried forward: **don't couple the backend to one editor's plugin** — expose a neutral OpenAI endpoint and let any consumer attach.

### 3. Submodule / separate-repo saga (2025-07 → 2025-08)

A ~6-week detour with **no inference changes** — purely *where the AI config lives*:
- `9659224` moved AI config to a separate repo; introduced an `ai_enabled` prompt and stripped destination-conditionals so "AI features are wanted when included."
- Followed by submodule migration commits (`bd1228e`, `068c16f`), URL/name changes (`43fd114` HTTPS→SSH, `d21fa1f`), "AI drift" re-alignment (`6416945`).
- `0fb8c04` **moved everything back into the main repo**, with the money-quote in the commit body: *"Fix AI script execution issue where submodule scripts were deployed as static files … AI scripts in the submodule were not being executed during chezmoi apply."*
- `2e93048` finally "Remove AI submodule and simplify project documentation."

**Reading of it (fact + inference)**: **Fact** — chezmoi does not run `run_*` lifecycle scripts that live inside a git submodule; they land as inert files. **[inferred]** the whole external-repo idea was an attempt to make AI config optional/shareable, and it cost weeks for negative value. This is a strong, concrete constraint (see Constraint 4).

### 4. llama.cpp migration (2026-05)

- `183cfac` "Replace Ollama with llama.cpp for better VRAM efficiency": added `llama-cpp-cuda`, removed `ollama` from mise, created `llama-server.service` (user unit, `127.0.0.1:8080`, OpenAI-compatible), restructured `ai.yaml` into `server{}` + empty `models[]`, dropped the local Ollama models from Continue (kept Claude), removed the Ollama system-service migration block.
  - **Oddity worth flagging**: the commit body says *"improved performance on RTX **1650**"* — not the RTX 4090 of the shared context. **[inferred]** the "VRAM efficiency" motivation originated on a much weaker 4 GB GPU where Ollama's overhead genuinely hurt; that rationale was then carried onto the 4090 where it is far less pressing. Re-examine "VRAM efficiency" as the *primary* justification on 24 GB hardware — the stronger surviving reasons are quant control, no daemon telemetry, and a plain systemd unit.
- `6ae137f` swapped `llama-cpp-cuda` (AUR, source build) for `llama.cpp-bin` (pre-compiled) because **AUR compilation failed under gcc15**, and fixed template variable substitution with `printf`.

### 6. Manifest router (2026-05, `manifest-server` branch — NEVER on main)

**Confirmed**: `git merge-base main manifest-server` = `e7bb2b2` (current main HEAD); the only commit on the branch beyond main is `2d31be1`. It still exists as `origin/manifest-server` (last pushed ~2026-05-06). **It was never merged and is not in main's history.**

**What it added** (`2d31be1`):
- `.chezmoidata/ai.yaml`: a real model — `qwen3.6-35b-a3b`, file `Qwen3.6-35B-A3B-Q8_0.gguf` from an unsloth HF repo — and `n_gpu_layers` cut **99 → 50** with the inline comment: *"Q8_0 (36.9 GB) on RTX 4090 (24 GB): ~52 layers on GPU, rest RAM-offloaded."* Plus a `manifest{port:2099,host:127.0.0.1}` block.
- `private_dot_config/manifest/docker-compose.yml.tmpl`: two networks (internal + frontend), `postgres:16-alpine` with a healthcheck + named volume, and `manifestdotbuild/manifest:latest` exposing `2099:3001`, `host.docker.internal` extra-host, `depends_on` postgres-healthy.
- `private_dot_config/systemd/user/manifest.service`: oneshot `docker compose up -d` / `down`.
- `run_onchange_after_install_ai_models.sh.tmpl`: generates **three secrets on first run** (`BETTER_AUTH_SECRET`, `MANIFEST_ENCRYPTION_KEY`, `POSTGRES_PASSWORD` + `DATABASE_URL`) via `openssl rand`, written `chmod 600` to `~/.config/manifest/.env`.
- `services.yaml`: `manifest.service` requiring the `docker` command; `menu-ai`: Manifest Status + Dashboard (`xdg-open`) entries.

**Why it was abandoned** (**[inferred]** — the branch has no revert commit or note; reasoning from the diff + constraints):
1. **Wildly disproportionate for a single-user local box.** A full auth gateway (better-auth), a PostgreSQL database, secret generation, and a two-network Docker topology exist to solve *multi-tenant, multi-user, provider-key-management* problems this machine does not have. One user talking to one llama-server needs none of it.
2. **The model doesn't fit.** Q8_0 35B = 36.9 GB against 24 GB VRAM forced `n_gpu_layers` down to ~50 with the remainder **CPU-offloaded** — and the i9-13900K has **no AVX-512**, so CPU offload is exactly this box's weakest path. The chosen model actively fought the hardware.
3. **Operational weight**: Docker daemon dependency, Postgres lifecycle, container image pulls, dashboard — a lot of moving parts to keep a hobby/learning inference stack alive.
4. The router's job (route to multiple models/providers, hold keys) is real but **[inferred]** better served by a lightweight OpenAI-compatible proxy (e.g. LiteLLM-class) than a DB-backed web app. This is exactly the question deferred to research Track 2 (`LOCAL_LLM_ROUTER.md`).

---

## Current implemented baseline (on `main` today)

What exists and is correct:
- **`.chezmoidata/ai.yaml`** — `server{port:8080, host:127.0.0.1, n_gpu_layers:99}`, `models_dir: ~/.local/share/models`, **`models: []`** (empty, with a commented example schema `{name,file,url}`).
- **`private_dot_config/systemd/user/llama-server.service.tmpl`** — user unit, `EnvironmentFile=%h/.config/llama-server/env`, `ConditionPathExists` on that env file (won't start without it), host/port templated from `ai.yaml`, `--n-gpu-layers ${N_GPU_LAYERS:-99}`, `Restart=on-failure`.
- **`.chezmoiscripts/run_onchange_after_install_ai_models.sh.tmpl`** — hash-triggered on `.ai.models`; creates `models_dir`; if models configured, checks for `llama-server`, downloads each GGUF with resumable `wget -c` (`.part` → rename), and writes `~/.config/llama-server/env` from the **first** model (`MODEL_FILE`, `N_GPU_LAYERS`). No-op with a warning when `models` is empty.
- **`menu-ai`** (wofi submenu) — opencode, claude-code, and "llama-server Status" (`systemctl --user status`). Terminal via `{{ .globals.applications.terminal }}`.
- **Package**: `llama.cpp-bin` (pre-compiled, not AUR source).
- **Decision record**: `_research/LLM_BACKENDS_RESEARCH.md` (canonical: llama.cpp chosen; Ollama dropped; port 8080).

### Gaps / rough edges in the baseline
- **No model served.** `ai.models` empty → `llama-server` never starts (env file never created → `ConditionPathExists` false). The whole stack is dormant. This is the single biggest gap.
- **Single-model only.** The env file is generated from `ai.models[0]`; the unit serves exactly one model. No multi-model, no per-role (coding vs embed vs chat) routing, no model swapping. Priorities 1–4 (agentic coding, CLI helpers, RAG, voice) will each want different models — the current one-model unit can't satisfy them simultaneously. **This is the gap Manifest tried (and failed the right way) to fill.**
- **No embeddings path.** `nomic-embed-text` died with Ollama; RAG (priority 3) has no embedding server today. llama.cpp can serve embeddings but nothing is wired.
- **No tool/function-calling verification.** The consumer contract (opencode/pi) requires OpenAI-compatible **tool calling + streaming**; llama-server supports these but it's unproven here with no model loaded.
- **Stale references still on main**: `chezmoi-data.md` names `ollama.service` as an example user unit; `chezmoi-scripts.md` still labels the install script "Ollama models"; `voxtype/config.toml.tmpl` (lines 81–93) configures meeting-summary via **Ollama** (`localhost:11434`, `llama3.2`) — a live Ollama dependency that contradicts the "Ollama removed" decision. `.claude/settings.local.json` still allow-lists `WebFetch(domain:manifest.build)`.
- **`n_gpu_layers: 99` assumes the model fits.** Fine for a right-sized model; the Manifest branch already proved a too-big model silently forces slow CPU offload.

---

## Hard constraints & lessons (these gate all future work)

1. **No heavyweight gateway for a single user.** Do **not** reintroduce a Docker + PostgreSQL + auth + dashboard stack (Manifest and its class). Auth, DBs, and multi-tenant provider management solve problems one local user does not have. If multi-model routing is needed, use a lightweight in-process/OpenAI-proxy approach — evaluate in Track 2, but the DB-backed-web-app shape is pre-rejected. *(from attempt 6)*

2. **Right-size the model to 24 GB VRAM; keep inference on the GPU.** The i9-13900K has **no AVX-512** → CPU offload is this box's weakest path. Any model + quant + context that spills past ~24 GB and forces `n_gpu_layers` down into CPU-offload territory (as Q8_0 35B did) is disqualified for interactive use. Prefer quant/size combos that fully GPU-resident. *(from attempt 6; INDEX framing)*

3. **Keep the backend editor-agnostic — one OpenAI-compatible endpoint, many consumers.** Do not couple inference to a specific IDE plugin (continue.dev's fate). `llama-server` on `127.0.0.1:8080` speaking OpenAI is the contract; opencode/claude-code/pi/Voxtype all attach to that. *(from attempts 1–2)*

4. **AI config lives in the main chezmoi repo — never a submodule.** chezmoi does **not execute** `run_*` lifecycle scripts that live in a git submodule; they deploy as inert files. The separate-repo experiment cost ~6 weeks for negative value. Keep `ai.yaml`, scripts, and units in-tree. *(from attempt 3, `0fb8c04`)*

5. **Prefer pre-compiled binaries over AUR source builds for the inference engine.** `llama-cpp-cuda` (AUR) broke on a gcc15 toolchain bump and had to be swapped for `llama.cpp-bin`. Source-built CUDA packages are a recurring breakage/rebuild-time liability on a rolling Arch box. *(from attempts 4→5)*

6. **Data-driven, single source of truth in `ai.yaml`; no hardcoded drift.** The 8100/8080 port drift between the systemd unit and the data file had to be fixed by templating (`4b3d802`). Host/port/layers/models all flow from `ai.yaml`; the unit and scripts template off it. Preserve this. *(from attempt 7)*

7. **The trajectory is toward *less* infrastructure, and each simplification stuck.** Daemon (Ollama) → thin systemd unit; gateway+DB (Manifest) → nothing; IDE plugin → neutral endpoint. Every attempt to add a management layer was reverted; every subtraction survived. Bias new work the same way — justify any new component against this track record. *(cross-cutting)*

8. **Hybrid local+cloud is the proven working shape.** The only end-to-end-working era (continue.dev) used local for cheap high-frequency work (autocomplete, embeddings) and cloud Claude for reasoning. Local's stated role is experiment/learn, not beating cloud — design for coexistence, not replacement. *(from attempt 2; INDEX framing)*

9. **Clean up the stale Ollama/Manifest references before building.** Live contradictions remain — notably `voxtype/config.toml.tmpl` still points meeting-summaries at an Ollama daemon on `:11434`. Any new backend work must reconcile these (voice back-half is priority 4 and will consume the new endpoint). *(current-state audit)*

---

## Open questions for the user

1. **Multi-model serving** is the central unsolved problem: agentic coding, CLI helpers, RAG-embeddings, and voice each want a different model, but today's unit serves exactly one. Acceptable approaches: (a) a lightweight OpenAI router in front of one/several llama-servers, (b) llama-server's own multi-model/`-hf` swapping, (c) a couple of parallel units on different ports? (Deferred to Track 2, but your preference bounds it.)
2. **Was Manifest abandoned for the reasons inferred here** (too heavy / model didn't fit), or for another reason (bug, lost interest, better option found)? The branch has no note.
3. The llama.cpp migration cites **"RTX 1650"** — is any of the current tuning (e.g. defaults, quant assumptions) a holdover from weaker hardware that should be revisited for the 4090?
4. **Voxtype's Ollama dependency** (meeting-mode summaries → `llama3.2` on `:11434`): migrate it onto the new llama-server endpoint, or is that a separate track?
5. Should the abandoned **`manifest-server` branch be deleted** from `origin` to avoid confusion, now that it's documented here?

---

## Sources

**Commits (main unless noted):**
- `67fee9d` Install ollama · `33839a6` install continue extension · `a43746c` continue.dev config (Ollama + Anthropic)
- `9659224` move AI to separate repo · `bd1228e`/`068c16f` submodule migration · `43fd114`/`d21fa1f` submodule URL/name · `6416945` re-align after AI drift · `0fb8c04` move scripts back to main (submodule-not-executed quote) · `2e93048` remove AI submodule · `89b95cc` remove VS Code AI extensions
- `183cfac` Replace Ollama with llama.cpp (RTX 1650 note) · `6ae137f` llama.cpp-bin (gcc15 AUR failure) · `e7974d9` remove Continue IDE config
- `2d31be1` Add Manifest LLM router — **branch `manifest-server` only, never merged** (merge-base with main = `e7bb2b2` = current HEAD)
- `4b3d802` Templatize llama-server + data-driven · `9e087c8` record decision

**Current-state files:** `.chezmoidata/ai.yaml`, `.chezmoidata/services.yaml`, `private_dot_config/systemd/user/llama-server.service.tmpl`, `.chezmoiscripts/run_onchange_after_install_ai_models.sh.tmpl`, `private_dot_local/lib/scripts/user-interface/executable_menu-ai.tmpl`, `private_dot_config/voxtype/config.toml.tmpl` (stale Ollama), `_research/LLM_BACKENDS_RESEARCH.md`, `_research/LOCAL_LLM_BACKEND_INDEX.md`.

**Branches:** `origin/manifest-server` (abandoned, ~2026-05-06).
