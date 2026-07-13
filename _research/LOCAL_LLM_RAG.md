# Local RAG / Private-Docs Stack — Evaluation

**Focus**: Track 4 of the Local LLM program — embeddings serving + vector store +
retrieval tooling over a personal corpus (dotfiles, notes, technical docs).
**Date**: 2026-07-13
**Hardware**: RTX 4090 24 GB + i9-13900K (no AVX-512), ample RAM.
**Backend**: llama.cpp / `llama-server` (OpenAI-compatible), already wired at
`127.0.0.1:8080` via `.chezmoidata/ai.yaml` + `llama-server.service.tmpl`.
**Priority**: RAG is use case #3 (after agentic coding, shell helpers) → favor
SIMPLE + composable over enterprise frameworks.

> **See**: `_research/LOCAL_LLM_BACKEND_INDEX.md` (program framing),
> `_research/LLM_BACKENDS_RESEARCH.md` (why llama.cpp).

---

## Executive summary (recommended stack)

For a few thousand personal docs on one machine, **skip the RAG framework**.
The recommended stack is four small, decoupled pieces:

1. **Embeddings serving**: a **dedicated second `llama-server` instance** started
   with `--embedding --pooling mean` (or the model's native pooling), serving
   `/v1/embeddings` on a separate port (e.g. `8081`). The main chat model at
   `:8080` **cannot** also serve embeddings — `--embedding` restricts the
   instance to embedding-only. One extra user systemd unit, ~600 MB VRAM.
2. **Embedding model**: **`bge-m3`** (GGUF, MIT, 8k context, multilingual, dense
   retrieval) as the default workhorse; **`nomic-embed-text-v1.5`** as the
   lighter alternative. Both are small enough to sit resident alongside a coding
   model on 24 GB. (Model *selection* detail belongs to Track 3; this doc just
   confirms they serve cleanly via llama-server.)
3. **Vector store**: **`sqlite-vec`** — a single SQLite extension, no server, no
   daemon, brute-force KNN that is *more* than fast enough at this scale, native
   metadata filtering via ordinary SQL, trivially scriptable and backup-able
   (one `.db` file). This is the crux recommendation.
4. **Retrieval/indexing**: a **thin (~100-150 line) POSIX/Python indexer +
   `retrieve` CLI** living in `private_dot_local/lib/scripts/`, matching the
   repo's existing script conventions. No LlamaIndex/txtai/Haystack.

**Reranking**: optional and deferred. A `bge-reranker-v2-m3` served by a *third*
`llama-server --embedding --pooling rank` instance measurably improves top-k
quality, but adds a model + instance. Start without it; add later if retrieval
quality disappoints. It slots in as one extra HTTP call before the LLM sees
context.

**Off-the-shelf shortcut worth knowing**: Simon Willison's `llm` +
`llm embed-multi` already implements "embed a corpus into SQLite + cosine
search" as a CLI. If the goal is *learning the moving parts*, hand-roll the
indexer; if the goal is *fastest working result*, `llm embed-multi` against the
llama-server endpoint is ~20 minutes of work. Both land on SQLite.

---

## Assumptions challenged (framework vs thin script)

**Claim under test**: "For a few thousand personal docs on one machine,
`sqlite-vec` + a ~100-line indexer + the embeddings endpoint is the right answer,
not a framework."

**Verdict: confirmed. A framework is not justified here.** Reasoning:

- **Scale is trivial.** Thousands of docs → tens of thousands of chunks →
  ~10⁴–10⁵ vectors. sqlite-vec's brute-force scan over 10⁵ × 1024-dim vectors is
  single-digit to low-tens of milliseconds. The regime where you *need* an ANN
  index (HNSW/IVF, i.e. LanceDB/Qdrant/faiss territory) starts ~10⁶+ vectors.
  We are 1-2 orders of magnitude below it.
- **Frameworks solve problems we don't have.** LlamaIndex/Haystack/RAGFlow earn
  their weight on: pluggable multi-backend abstraction, distributed indexing,
  document loaders for 100 file types, evaluation harnesses, agentic query
  planning, multi-tenant serving. A single user over markdown + code needs none
  of it, and each adds a Python dependency tree that fights the repo's
  shell/CLI-first, Arch-packaged ethos.
- **Composability is the actual requirement.** The consumer contract is "usable
  from the shell + exposable to the agentic coder as a tool." A CLI that prints
  ranked chunks to stdout satisfies both trivially (pipe it, or wrap it as an
  MCP/opencode tool). A framework's Python object graph does not compose with
  the shell any better than a script does.
- **Hackability / learning goal.** RAG's whole pipeline (chunk → embed → store →
  query → rank → assemble context) is ~150 lines you fully understand and can
  tweak. A framework hides exactly the parts worth learning.
- **The genuine framework wins we forgo**: sophisticated chunkers
  (semantic/hierarchical splitters), query transformations (HyDE, multi-query),
  and built-in eval. All are addable later as small functions if needed — none
  are load-bearing for a first version.

**Where the thin script *would* break down** (document the tripwires so future-me
knows when to reconsider): corpus > ~500k chunks (→ add an ANN index: LanceDB or
sqlite-vec's future ANN, or DuckDB VSS); needing hybrid dense+sparse fusion
across languages at scale (→ bge-m3's multi-vector mode or a real engine);
multi-user/networked access (→ Qdrant/pgvector server). None apply.

---

## Embeddings serving options

The corpus is embedded through an OpenAI-compatible `/v1/embeddings` endpoint.
Options, evaluated for *this* setup (llama.cpp already the house engine):

| Option | What it is | Pros here | Cons here | Fit |
|--------|-----------|-----------|-----------|-----|
| **`llama-server --embedding`** | Second llama.cpp instance, embedding-only | Zero new engine/deps — reuses installed `llama-server`; GGUF quant control; OpenAI `/v1/embeddings`; same ops story (user systemd unit, `ai.yaml`) | Must be a **separate instance/port** from chat model; throughput lower than Torch servers (irrelevant at this scale) | **RECOMMENDED** |
| **Infinity** (`infinity-emb`) | Torch/ONNX/CTranslate2 embedding server, dynamic batching | Highest throughput; serves embed **and** rerank; broad sentence-transformers support | New Python/Torch stack duplicating llama.cpp; batching irrelevant for single-user incremental indexing | Overkill |
| **text-embeddings-inference (TEI)** | HuggingFace Rust embedding server | Fast, production-grade, rerank support | Another daemon + model cache; HF-centric; no advantage over llama-server at our scale | Overkill |
| **Ollama `/api/embed`** | — | Easy | **Already dropped from this repo** (see LLM_BACKENDS_RESEARCH). Non-starter | Rejected |
| **In-process (fastembed / sentence-transformers)** | Embed inside the indexer, no server | No serving instance at all | Pulls Torch/ONNX into the CLI; loses the "one engine, HTTP contract" cleanliness; cold-start per invocation | Viable fallback only |

**Key architectural constraint (verified against llama.cpp server README):**
`--embedding`/`--embeddings` *restricts* an instance to the embedding use case,
and reranking additionally needs `--pooling rank` with a reranker model. So the
main chat/coding model at `:8080` and the embedding model are **necessarily
different `llama-server` processes**. Practical layout:

- `:8080` — chat/coding model (existing `llama-server.service`).
- `:8081` — embedding model, `--embedding --pooling mean` (new unit).
- `:8082` — (optional) reranker, `--embedding --pooling rank` (new unit).

Pooling modes: `none` (per-token, unnormalized), `mean`, `cls`, `last`, `rank`
(rerank). Use the pooling the chosen embedding model was trained for (bge-m3 =
`cls`/dense; nomic = `mean`). Embeddings returned are L2-normalized, so cosine ==
dot product downstream.

VRAM: bge-m3 (~560M params) or nomic (~137M) quantized are a few hundred MB —
they coexist with a coding model on 24 GB without pressure. Consider
`--n-gpu-layers 99` and a small `--ctx-size`; embedding models don't need large
KV cache.

---

## Vector store landscape & tradeoff table

Ranked by fit for *single-user, embedded, scriptable, Arch-packaged*:

| Store | Embedded? (no server) | Disk footprint | Query speed @ ~10⁵ vecs | Metadata filtering | Scriptability | Arch packaging | Verdict |
|-------|----------------------|----------------|--------------------------|--------------------|----------------|-----------------|---------|
| **sqlite-vec** | ✅ pure SQLite ext | tiny (1 `.db`) | brute-force, ~ms | ✅ full SQL `WHERE` (co-located with vectors) | ✅✅ `sqlite3` CLI, any lang, `jq`-free | ext via AUR/pip; ship `.so` | **PICK** |
| **DuckDB + VSS** | ✅ in-process | tiny | fast (HNSW ext) | ✅ full SQL | ✅ great analytics/SQL | `duckdb` in repos; VSS ext | Strong #2 |
| **LanceDB** | ✅ in-process lib | small (Arrow columnar) | fast (IVF-PQ ANN) | ✅ good | ✅ Python/Rust API | pip only, no clean Arch pkg | Overpowered |
| **usearch** | ✅ single-header lib | tiny | very fast (HNSW) | ⚠️ external (bring your own metadata store) | ⚠️ needs glue for docs/metadata | pip/AUR | ANN-only piece |
| **faiss** | ✅ lib | medium | very fast | ❌ none (vectors only) | ⚠️ Python-heavy, manual id→doc map | AUR (`python-faiss`) | Too low-level |
| **Chroma** | ⚠️ "embedded" but a server/process + Python | medium | fine | ✅ | ✅ Python | pip only | Heavier than needed |
| **Qdrant (embedded/local)** | ❌ really a server (Rust binary/Docker) | medium | fast (HNSW) | ✅✅ rich | ⚠️ HTTP/gRPC client | AUR/binary | Server = wrong shape |
| **pgvector** | ❌ needs PostgreSQL | large (full RDBMS) | fast | ✅✅ SQL | ⚠️ requires PG running | repos | Daemon overkill (echoes the dropped Manifest/Postgres lesson) |

**Why sqlite-vec wins for this repo specifically:**

- **No server, no daemon** — aligns with "drop Manifest/Postgres" prior-art and
  the repo's dislike of extra background services.
- **One file** — the index is `~/.local/share/rag/index.db`; trivially
  backed up by the existing Restic home-backup, trivially `rm`-and-rebuild.
- **Vectors + metadata + text in one SQL query** — `WHERE path LIKE '%hypr%'`
  filtering is free; no second store to keep in sync (usearch/faiss's weakness).
- **Scriptable to the bone** — `sqlite3 index.db` from any shell script; embeds
  in Python via stdlib `sqlite3` + `.load()`. Matches lib/scripts patterns.
- **Brute-force is fine** — at ≤10⁵ vectors the linear scan is a feature (exact
  recall, zero index tuning), not a limitation.

**Runner-up: DuckDB + VSS** — pick this instead only if you also want columnar
analytics over the corpus (SQL over chunk stats, joins to other data). Slightly
heavier extension story; HNSW index adds tuning surface we don't need yet.

**Reject**: server stores (Qdrant/pgvector/Chroma-as-service) reintroduce the
daemon+client complexity this program explicitly walked away from.

---

## Retrieval/indexing tooling & reranking

### Tooling: thin script vs off-the-shelf

| Approach | Deps | Control/learning | Effort | Fit |
|----------|------|------------------|--------|-----|
| **Hand-rolled indexer + `retrieve` CLI** | `sqlite-vec`, `curl`/`httpx` | full | ~150 lines | **RECOMMENDED (learning goal)** |
| **`llm` + `llm embed-multi` (simonw)** | `llm`, `llm-sentence-transformers` *or* point at OpenAI-compat endpoint | medium | ~20 min | Great fast-path / reference |
| **txtai** | Python + Torch | low (opinionated) | small | Reasonable, but bundles its own embed+store |
| **LlamaIndex** | large Python tree | low | small-to-set-up | Rejected: framework tax unjustified |
| **Haystack / RAGFlow / llmware** | large / service-oriented | low | medium | Rejected: enterprise/multi-user shape |

**Position**: hand-roll it. The pipeline is small and the whole point is a clean,
owned, hackable stack. Keep `llm embed-multi` in your back pocket as a working
reference and a fallback if the custom indexer stalls — it proves the SQLite
approach and its source is readable.

### Chunking / indexing strategy (code + markdown)

- **Markdown**: split on heading boundaries (recursive by `#`/`##`/`###`), then
  soft-wrap oversized sections to a target of **~512 tokens with ~64 overlap**.
  Preserve the heading path as metadata (`section` column) — cheap, big
  retrieval-quality win.
- **Code / dotfiles**: split on **structural boundaries** (function/block, or
  simply file-then-fixed-window for config files) rather than blind fixed-size.
  Keep whole small config files as one chunk when under budget. Store `path`,
  `lang`, `line_start/line_end` as metadata.
- **Metadata columns to carry**: `path`, `mtime`, `sha256` (chunk + file),
  `section/symbol`, `lang`. These enable SQL pre-filtering and incremental
  updates.

### Incremental re-index on file change

- **Hash-gated, mirroring the repo's own `run_onchange` idiom**: store each
  file's `sha256` + `mtime`; on index run, skip unchanged files, re-embed only
  changed/new ones, delete rows for removed files. This is the standard
  "hash-comparison fingerprint" incremental pattern and it's a few lines over
  SQLite.
- **Trigger options** (pick per taste): (a) manual `rag index` before querying;
  (b) a `systemd --user` path unit / timer watching the corpus dirs; (c) a git
  post-commit hook in the dotfiles repo. Given the repo already leans on
  `run_onchange` + user timers, a **timer or path-unit** is the idiomatic
  choice; keep the CLI callable standalone regardless.

### Reranking — worth it here?

- **What it buys**: `bge-reranker-v2-m3` (cross-encoder, ~418 MB GGUF, ~72 ms/
  batch, reported ~100% top-k accuracy on small test sets) re-scores the top ~20
  brute-force hits and reorders them, meaningfully improving the *ordering* the
  LLM sees. Most 2026 production RAG stacks pair bge-m3 + bge-reranker-v2.
- **What it costs**: a third `llama-server` instance (`--embedding --pooling
  rank`), a model download, one extra HTTP round-trip per query, and note the
  known llama.cpp caveat that some rerank models (esp. qwen3-rerank) currently
  score incorrectly — **stick to `bge-reranker-v2-m3`**, which is well-tested.
- **Verdict**: **defer, but design for it.** Ship v1 as embed→cosine top-k. Add
  rerank as an optional `--rerank` flag that calls `:8082/v1/rerank` over the
  top-N candidates. Cheap to bolt on precisely because everything is HTTP + SQL.

---

## Recommended minimal architecture (data flow)

```
corpus dirs                 llama-server :8081             sqlite-vec
(dotfiles, notes, docs)     (--embedding --pooling mean)   index.db
        │                            ▲                          │
        │  1. walk + hash            │  2. POST /v1/embeddings   │
        ▼    (skip unchanged)        │     (changed chunks)      ▼
   ┌──────────┐   chunks    ┌────────┴─────┐  vectors   ┌──────────────┐
   │  index   │───────────► │  embed       │──────────► │ INSERT/UPSERT│
   │  (script)│             │  (curl/httpx)│            │ vec + meta   │
   └──────────┘             └──────────────┘            └──────────────┘

   query time:
   "how does darkman switch themes?"
        │  embed query (POST :8081)
        ▼
   sqlite-vec KNN  ──►  top-20  ──►  [optional] rerank (POST :8082)
        │                                   │
        ▼                                   ▼
   top-k chunks (path + section + text) ──► stdout / assembled context
```

Components, all decoupled by HTTP + a SQL file:

- **`index`**: walk corpus → chunk → hash-gate → embed changed → upsert into
  `index.db`. Idempotent; safe to re-run.
- **`index.db`** (sqlite-vec): `chunks(id, path, section, lang, sha256, text)` +
  a `vec` virtual table keyed by `id`.
- **`retrieve`/`rag`**: embed query → KNN → optional rerank → print ranked
  `path:section` + text (JSON or plain) to stdout.

---

## How it plugs into the shell + the agentic coder

- **Shell**: `rag "query"` prints ranked chunks to stdout →
  `rag "..." | head`, pipe into `$EDITOR`, or `rag -q "..." --json | jq`. A `zsh`
  widget / abbreviation can wrap it. Fits `private_dot_local/bin/` wrapper +
  `lib/scripts/` implementation split the repo already uses.
- **Agentic coder (opencode / future `pi`)**: expose `retrieve` as a **tool**.
  Cleanest path is a tiny **MCP server** (or opencode's native tool config) whose
  single tool `search_docs(query, k)` shells out to the CLI and returns JSON.
  Because the CLI already emits structured results, the tool is a ~30-line
  adapter. This makes the private corpus a first-class context provider for the
  coder without the model ever leaving the machine (privacy motivation
  satisfied).
- **Claude (cloud)**: intentionally *not* wired — RAG stays local-only; only the
  local coder consumes it.

---

## Open questions

1. **Embedding model final pick** — bge-m3 (quality, multilingual, 8k) vs
   nomic-embed-text (lighter, mean-pooled) vs Qwen3-Embedding (flexible dims,
   larger). Deferred to Track 3 (models). Confirm the chosen model's native
   pooling and set `--pooling` accordingly.
2. **One embedding instance always-resident, or on-demand?** A resident `:8081`
   costs a few hundred MB VRAM continuously; alternatively socket-activate or
   start-on-index. Given ample VRAM, resident is simplest.
3. **Chunk sizing empirically** — 512/64 is a starting default; worth a small
   eval on a handful of real queries against the actual corpus.
4. **sqlite-vec ANN roadmap** — currently brute-force; if the corpus ever grows,
   track whether sqlite-vec ships ANN or whether DuckDB VSS / LanceDB is the
   migration target.
5. **Should indexing live in the dotfiles repo or a separate data dir?** Index
   `.db` is generated data → belongs in `~/.local/share/rag/`, not the chezmoi
   source tree (don't commit the vector DB).

---

## Dotfiles integration notes

Concrete wiring, matching existing repo conventions (feeds the later plan):

**Packages** (`.chezmoidata/packages.yaml`):
- `sqlite` (present already) + **sqlite-vec extension** — ship the `vec0.so`
  (AUR `sqlite-vec` or pip `sqlite-vec`; pin a version). Prefer a real Arch/AUR
  package over pip per the repo's supply-chain policy.
- Embedding + rerank **GGUF models** are *not* packages — they go through the
  existing `ai.models` download path (`run_onchange_after_install_ai_models`).

**Config** (`.chezmoidata/ai.yaml`) — extend, don't fork:
```yaml
ai:
  server: { port: 8080, host: "127.0.0.1", n_gpu_layers: 99 }   # existing chat
  embeddings:
    enabled: false            # feature-gate like features.voxtype
    port: 8081
    pooling: "mean"           # match chosen model
    model: ""                 # GGUF filename in models_dir
  rerank:
    enabled: false
    port: 8082
    model: ""                 # bge-reranker-v2-m3 GGUF
  rag:
    corpus_dirs:              # what to index
      - "~/.local/share/chezmoi"
      - "~/notes"
    chunk_tokens: 512
    chunk_overlap: 64
    index_db: "~/.local/share/rag/index.db"
```
Gate the new instances behind `ai.embeddings.enabled` / `ai.rerank.enabled` so
the default install stays lean (same pattern as `features.*` toggles).

**Systemd units** (`private_dot_config/systemd/user/`):
- `llama-embed.service.tmpl` — clone of `llama-server.service.tmpl` with
  `--embedding --pooling {{ .ai.embeddings.pooling }}`, port `:8081`, its own
  `~/.config/llama-server/embed.env`.
- `llama-rerank.service.tmpl` (optional) — `--embedding --pooling rank`, `:8082`.
- Register enablement in `.chezmoidata/services.yaml` `user_services`, gated on
  the model file existing (mirror how `llama-server.service` is gated on the
  binary), enabled by `run_once_after_002_configure_system_services`.

**Retrieval CLI** (`private_dot_local/lib/scripts/`):
- New category or under `system/` — e.g. `lib/scripts/ai/` with
  `executable_rag-index` and `executable_rag-query` (shellcheck-clean, gum UI
  per script standards), plus a `bin/` wrapper `rag`. Python is acceptable for
  the indexer if chunking gets non-trivial; keep the query path shell-thin.
- Follow `lib/scripts/CLAUDE.md` standards (set -euo pipefail, log templates in
  any `.tmpl`, no inline examples in docs — reference the script).

**Incremental index trigger**:
- Add `rag-index.{service,timer}` to `services.yaml` `user_timers` (same
  mechanism as `session-autosave`/`wallpaper-cycle`) OR a `systemd --user` path
  unit watching `corpus_dirs`. Keep `rag-index` runnable by hand regardless.
- The index `.db` is generated data → `~/.local/share/rag/`, covered by the
  existing Restic home-backup; **never** commit it to the chezmoi source tree.

**Docs**: on implementation, add a short `lib/scripts/ai/CLAUDE.md` and a
user-facing README note; update `.claude/rules/chezmoi-data.md` with the new
`ai.embeddings`/`ai.rag` keys and `chezmoi-scripts.md`/systemd `CLAUDE.md` with
the new units.

---

## Sources

- llama.cpp server README (embeddings/rerank endpoints, `--embedding`,
  `--pooling` modes, `/v1/rerank`): <https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md>
- llama.cpp rerank output caveat (qwen3-rerank incorrect scores; bge-reranker-v2-m3 OK):
  <https://github.com/ggml-org/llama.cpp/issues/16407>
- llama.cpp reranking support issue/history: <https://github.com/ggml-org/llama.cpp/issues/8555>
- bge-reranker-v2-m3 via llama-server (size/latency/accuracy notes, Lemonade):
  <https://lemonade-server.ai/docs/api/llamacpp/>
- Embedded vector DB comparison (chromem-go vs sqlite-vec vs Bleve vs LanceDB):
  <https://shaharia.com/blog/choosing-embeddable-vector-database-go-application/>
- sqlite-vec local vector search overview:
  <https://dev.to/aairom/embedded-intelligence-how-sqlite-vec-delivers-fast-local-vector-search-for-ai-3dpb>
- RAG inside RDBMS: sqlite-vec vs pgvector:
  <https://dev.to/jonbiz/implementing-a-rag-system-inside-an-rdbms-sqlite-and-postgres-with-sqlite-vec-pgvector-4d5h>
- Infinity embedding server: <https://pypi.org/project/infinity-emb/>
- Best embedding models for RAG 2026 (bge-m3, Qwen3-Embedding, nomic):
  <https://milvus.io/blog/choose-embedding-model-rag-2026.md> ·
  <https://knowledgesdk.com/blog/open-source-embedding-models-rag-2026>
- Simon Willison `llm` + `llm embed-multi` / embeddings in SQLite:
  <https://simonwillison.net/2023/Sep/4/llm-embeddings/> ·
  <https://llm.datasette.io/en/stable/plugins/directory.html>
- Chunking strategies for RAG (2026): <https://www.firecrawl.dev/blog/best-chunking-strategies-rag> ·
  <https://weaviate.io/blog/chunking-strategies-for-rag>
- Incremental indexing (hash-fingerprint updates):
  <https://medium.com/@vasanthancomrads/incremental-indexing-strategies-for-large-rag-systems-e3e5a9e2ced7>
