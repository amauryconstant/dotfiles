# Design: Local LLM Backend Core (llama-swap multi-model serving)

**Status**: Approved, ready for implementation-plan.
**Type**: chezmoi config + shell CLI + systemd + docs (no research changes).
**Sub-project A** of the Local LLM Backend program (see `_research/LOCAL_LLM_BACKEND_INDEX.md`
and tracks 0–6). This is the foundational piece — nothing else works until the backend
actually serves a model.

## Motivation

The current `main` ships a correct-but-dormant llama.cpp skeleton: `ai.models: []`, so
`llama-server` never starts (its `ConditionPathExists` env file is never created). The single
biggest gap (per `LOCAL_LLM_PRIOR_ART.md`) is **nothing is served**, and the single unit can
serve only one model, while the wanted roles — agentic **coder**, fast **helper**, **embeddings** —
do not co-fit in 24 GB VRAM at useful context (see `LOCAL_LLM_ROUTER.md` budgeting math).

This design makes the backend serve models via **llama-swap** (one Go binary, on-demand
VRAM arbitration), with the tuned flags that agentic tool-calling actually requires, and
relocates the **model roster** out of chezmoi template data into an editable
`~/.config/llama-swap/config.yaml`. It also reconciles the live Ollama/Manifest debt the
prior-art audit flagged.

Research backing: `LOCAL_LLM_SERVING_ENGINE.md` (keep llama.cpp; fix flags),
`LOCAL_LLM_ROUTER.md` (llama-swap; groups; not a cloud gateway),
`LOCAL_LLM_PERF_OPS.md` (flags, KV quant, systemd hardening, observability).

## Scope decisions made during brainstorming

- **Backend shape**: adopt **llama-swap now** (research's recommended Phase 1), not a single
  static unit — reach the real multi-role target directly.
- **Model roster is model-agnostic data, and it lives in `~/.config`, not `.chezmoidata`.**
  The *backend/architecture* (unit, package, enablement) stays at chezmoi's level; the *model
  configuration* (which GGUFs, per-role flags, groups) is user territory in the config tree.
  Concrete models named below are **placeholders/defaults**, not part of what this spec locks in
  (final picks deferred; see `LOCAL_LLM_MODELS.md`).
- **Data boundary**: **self-contained `config.yaml`** — llama-swap's native config holds macros
  (tuning flags) + roster + groups as one editable, versioned, plain (non-template) file.
  `.chezmoidata/ai.yaml` shrinks to `server: { host, port }` only (the unit's `--listen`).
- **Model downloads**: **on-demand CLI** (`llama-models pull`), not apply-time automation.
  Single source of truth (config.yaml); downloads are an explicit user action.
- **Cleanup in scope**: dead-ref cleanup (docs + settings) **and** the Voxtype Ollama repoint.
- **Cleanup out of scope**: deleting the `origin/manifest-server` branch (documented, harmless).
- **Config.yaml ownership**: managed & versioned under `private_dot_config/` (edit-in-repo or
  `chezmoi edit`), deployed to `~/.config/llama-swap/` — matches "live in ~/.config *and its
  equivalent in this repository*".

## Component design

### 1. `.chezmoidata/ai.yaml` — shrink to architecture only

Reduce to what the systemd unit and endpoint consumers need:

```yaml
ai:
  server:
    host: "127.0.0.1"
    port: 8080
```

Remove `n_gpu_layers`, `models_dir`, `models: []`, and the commented model schema — all of that
moves into `config.yaml`. `models_dir` becomes a convention (`~/.local/share/models`) referenced
by `config.yaml` cmd paths and the CLI default.

### 2. `private_dot_config/llama-swap/config.yaml` — native, self-contained, plain file

Deploys to `~/.config/llama-swap/config.yaml`. Not a `.tmpl` (needs nothing from chezmoi data;
`${HOME}` covers paths). Shape:

```yaml
macros:
  llama: "/usr/bin/llama-server --host 127.0.0.1 --port ${PORT}
          --n-gpu-layers 99 --jinja -fa
          --cache-type-k q8_0 --cache-type-v q8_0 --metrics"
models:
  coder:
    # url: https://huggingface.co/unsloth/GLM-4.7-Flash-GGUF/resolve/main/GLM-4.7-Flash-UD-Q4_K_XL.gguf
    cmd: "${llama} --model ${HOME}/.local/share/models/GLM-4.7-Flash-UD-Q4_K_XL.gguf --ctx-size 65536"
    ttl: 900
    group: heavy
  helper:
    # url: https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF/resolve/main/Qwen3-4B-Instruct-2507-Q5_K_M.gguf
    cmd: "${llama} --model ${HOME}/.local/share/models/Qwen3-4B-Instruct-2507-Q5_K_M.gguf --ctx-size 8192"
    group: resident
  embed:
    # url: <verify at pull time>
    cmd: "/usr/bin/llama-server --host 127.0.0.1 --port ${PORT} --n-gpu-layers 99 --embedding --pooling mean --model ${HOME}/.local/share/models/<embed>.gguf"
    group: resident
groups:
  resident: { swap: false, persistent: true }   # helper + embed always-on (~4 GB)
  heavy:    { swap: true }                        # coder swaps in/out of the remaining ~20 GB
```

Key points:
- Chat roles use the `llama` macro (gets `--jinja -fa` + q8_0 KV + metrics). The **embed** role
  does **not** use `--jinja`/ctx and adds `--embedding --pooling` (per `LOCAL_LLM_RAG.md`).
- The download URL rides as a per-model **`# url:` comment** the CLI parses (llama-swap's schema
  has no url field; a comment avoids risking strict-parse rejection of an unknown key).
- The `embed` role ships with its file/url unset by default (empty roles are simply not pulled /
  not usable) — RAG (sub-project C) populates it.
- Pin the exact group/routing keys to the **installed llama-swap version's docs** when writing
  (v200+ schema has drifted; snippet is illustrative).

### 3. `llama-models` CLI — on-demand downloads

- `private_dot_local/lib/scripts/ai/executable_llama-models` + `private_dot_local/bin/llama-models`
  wrapper (lazy-load pattern per `private_dot_local/CLAUDE.md`).
- Subcommands: `pull` (download GGUFs referenced by config.yaml but missing from models_dir,
  resumable, skip present/empty), `list` (roster + presence), `status` (unit + `/health`).
- Parses `~/.config/llama-swap/config.yaml` — model filename from each `cmd`'s `--model` path,
  URL from the adjacent `# url:` comment (`yq` + light shell).
- Follows `lib/scripts/CLAUDE.md` standards: `set -euo pipefail`, `gum`/`ui_*` helpers,
  shellcheck-clean; reuse the existing resumable `wget -c` (`.part` → rename) idiom.
- **Retire** `.chezmoiscripts/run_onchange_after_install_ai_models.sh.tmpl` (downloads are now
  explicit; nothing else it did — models_dir creation — is needed at apply time; the CLI mkdirs).

### 4. systemd — `private_dot_config/systemd/user/llama-swap.service.tmpl`

New user unit; becomes parent of the `llama-server` subprocesses; listens on the canonical
`:8080`. Templated only for host/port:

```
ExecStart=/usr/bin/llama-swap --config %h/.config/llama-swap/config.yaml \
  --listen {{ .ai.server.host }}:{{ .ai.server.port }}
```

Hardening (from `LOCAL_LLM_PERF_OPS.md` "Recommended ops surface"):
- `Type=simple`, `Restart=on-failure`, `RestartSec=5`, `StartLimitBurst=5`, `StartLimitIntervalSec=60`.
- `ExecStartPost` `/health` readiness gate (poll up to ~60 s) so `start` succeeds only when ready.
- **Do not** set `Type=notify`/`WatchdogSec` (binary lacks sd_notify) or `PrivateDevices=true`
  (breaks CUDA). Light sandboxing that preserves GPU: `NoNewPrivileges=true`,
  `ProtectSystem=strict` + `ReadWritePaths=%h/.local/share/models`, `PrivateTmp=true` — verify
  `/dev/nvidia*` access survives.
- `WantedBy=default.target`.

**Keep** `llama-server.service.tmpl` on disk but **disabled** — one-flag Phase-0 fallback.

### 5. Enablement + package

- `.chezmoidata/services.yaml` `user_services`: add
  `{ name: llama-swap.service, enabled: true, start: false, requires_command: llama-swap }`;
  flip existing `llama-server.service` to `enabled: false`. Enablement flows through
  `run_once_after_002_configure_system_services` (the `requires_command` gate already exists).
- `.chezmoidata/packages.yaml`: add `llama-swap-bin` (AUR, binary) to the AI/LLM group —
  subject to the repo's AUR supply-chain review (`lib/scripts/system/CLAUDE.md` → Package
  Security Policy).

### 6. Legacy cleanup (approved)

- **Dead refs**:
  - `.claude/rules/chezmoi-data.md`: `ai.yaml` row now describes `server` only; replace the
    `ollama.service` example user-unit mention with `llama-swap.service`.
  - `.claude/rules/chezmoi-scripts.md`: remove the retired `install_ai_models` /
    "Ollama models" row.
  - `private_dot_config/systemd/user/CLAUDE.md`: update the unit table (add `llama-swap.service`,
    mark `llama-server.service` fallback/disabled).
  - `.claude/settings.local.json`: remove the `WebFetch(domain:manifest.build)` allowlist entry.
- **Voxtype repoint**: `private_dot_config/voxtype/config.toml.tmpl` meeting-summary → the new
  endpoint (`{{ .ai.server.host }}:{{ .ai.server.port }}`, OpenAI-compatible, `helper` model)
  instead of Ollama `:11434`/`llama3.2`. **Verify during impl** that Voxtype's config accepts an
  OpenAI-compatible base URL + model name; if not, note the constraint and adjust.

### 7. Docs

- New `private_dot_local/lib/scripts/ai/CLAUDE.md` (CLI purpose, subcommands, references the
  script — no inline examples).
- Brief note on the `~/.config/llama-swap/` config (macros/roster/groups; `# url:` convention)
  — either a short `private_dot_config/llama-swap/CLAUDE.md` or a section in the ai scripts doc.
- Root `CLAUDE.md` / `.claude/rules/` tables updated per §6.

## Data flow

```
config.yaml (roster + macros + groups)   ~/.config/llama-swap/
        │                                        │
        ├─ llama-models pull ──► wget -c GGUFs ──► ~/.local/share/models/
        │
        └─ llama-swap.service ──► spawns llama-server subprocesses
                                    ├─ resident group (persistent): helper + embed  (~4 GB)
                                    └─ heavy group (swap, ttl 900): coder            (~18 GB)
                                  one OpenAI+Anthropic endpoint at 127.0.0.1:8080
```

## Verification

- **Repo-side (Claude runs, read-only/validation)**: `chezmoi execute-template` on
  `llama-swap.service.tmpl` and `voxtype/config.toml.tmpl`; `yq` validate `config.yaml`;
  `shellcheck` the `llama-models` CLI; `chezmoi diff` for the full change set.
- **Live (user runs via `!`, state-mutating)**: install `llama-swap-bin` → `chezmoi apply` →
  `llama-models pull` (populate at least the coder role) → `systemctl --user start llama-swap`
  → `curl -sf http://127.0.0.1:8080/health` → a `curl` tool-calling smoke test (verify `--jinja`
  path returns `tool_calls`).

## Out of scope (later sub-projects)

- **B** — CLI helper: `aichat` + zsh Alt-E widget + `menu-ai` entry (`LOCAL_LLM_CLI_TOOLS.md`).
- **C** — RAG: sqlite-vec + indexer + `retrieve` CLI; populates the `embed` role
  (`LOCAL_LLM_RAG.md`).
- **D** — Observability surface: `system-health` block, `menu-ai` enrichment, Waybar glyph,
  optional `llama-health-check.timer` (`LOCAL_LLM_PERF_OPS.md` Part C).
- **E** — Consumer wiring: opencode `local` provider; Voxtype as a full consumer beyond the
  meeting-summary repoint.
- Large-MoE CPU/RAM offload experiments (`LOCAL_LLM_PERF_OPS.md` Part B).
- Cloud gateway (LiteLLM/Olla) — cloud routing stays in the consumers (`LOCAL_LLM_ROUTER.md`).
- Final model selection and per-model `--reasoning-format` / thinking-mode tuning
  (`LOCAL_LLM_MODELS.md`, `LOCAL_LLM_SERVING_ENGINE.md`).
