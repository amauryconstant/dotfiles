# CPU/RAM Offload Research Deepening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deepen `_research/LOCAL_LLM_PERF_OPS.md` with a new "Part B: CPU/RAM offload for large MoE" section covering whether CPU+RAM offload is viable on the 4090+i9-13900K (no AVX-512) box once a model is too large to fit 24GB VRAM at any quant, given the box's 128GB system RAM.

**Architecture:** Single-file content addition. No code, no config, no chezmoi templates touched — this is research writing only. Each task researches (WebSearch/WebFetch) and drafts one self-contained subsection, then inserts it via `Edit` at a fixed anchor in the existing doc, so later tasks never fight earlier ones for the same insertion point.

**Tech Stack:** Markdown. `WebSearch`/`WebFetch` tools for sourcing. `Edit`/`Read` for the file. `git` for commits.

## Global Constraints

- Every quantitative claim in new content must be either **cited** (inline markdown link to a real source found via research) or explicitly **labeled "projected:"** when derived from the bandwidth formula rather than an external report. Never state a number as fact with no citation and no "projected" label.
- No placeholder text ("TBD", "TODO", "add more detail later") anywhere in the diff.
- No changes to `.chezmoidata/ai.yaml`, any systemd unit, or any other config file — content only, and only within `_research/LOCAL_LLM_PERF_OPS.md`.
- Do not commit to a specific large-MoE model or an alternate backend as *the* recommendation — Part B informs a future decision, consistent with the doc's existing "Open questions" pattern.
- Do not run any actual benchmark — no access to the target box. The "benchmark recipe" subsection documents *how the user would* validate, it does not claim results.
- Source list at the end of the file must grow to include every URL cited in new content; no citation without a matching `## Sources` entry.

---

### Task 1: Structural revisions (header, executive summary, assumptions bullet)

**Files:**
- Modify: `_research/LOCAL_LLM_PERF_OPS.md` (lines 4, 13, 23 in the current version)

**Interfaces:**
- Produces: the phrase `Part B` as the canonical reference name later tasks' inserted section must match (heading text is fixed in Task 2's Step 3 as `## Part B: CPU/RAM offload for large MoE (128GB ceiling)` — Task 1's cross-references must use that exact string).

- [ ] **Step 1: Update the hardware line to include system RAM**

Read the current line first to confirm it hasn't drifted:

```bash
grep -n "RTX 4090 24 GB" _research/LOCAL_LLM_PERF_OPS.md
```

Expected: line 4 matches `**Hardware**: RTX 4090 24 GB (Ada, ~1008 GB/s) + i9-13900K **without AVX-512**. Single GPU, single user.`

Use `Edit` on `_research/LOCAL_LLM_PERF_OPS.md`:

old_string:
```
**Hardware**: RTX 4090 24 GB (Ada, ~1008 GB/s) + i9-13900K **without AVX-512**. Single GPU, single user.
```

new_string:
```
**Hardware**: RTX 4090 24 GB (Ada, ~1008 GB/s) + i9-13900K **without AVX-512**, 128 GB system RAM. Single GPU, single user.
```

- [ ] **Step 2: Scope the executive summary's "keep everything in VRAM" bullet**

old_string:
```
- **Keep everything in VRAM.** On this box, RAM-offloaded layers are a cliff, not a slope: no AVX-512 means CPU matmul falls back to AVX2, roughly halving CPU-side throughput. The 24 GB budget is large enough that the right move is "pick a model + quant + KV-cache config that fits fully in VRAM" rather than "offload N layers." Full offload (`-ngl 99` / `auto`) is already correct in the current unit.
```

new_string:
```
- **Keep everything in VRAM — for anything that fits.** On this box, RAM-offloaded layers are a cliff, not a slope: no AVX-512 means CPU matmul falls back to AVX2, roughly halving CPU-side throughput. For any model/quant that fits fully in 24 GB, the right move is "pick a model + quant + KV-cache config that fits fully in VRAM" rather than "offload N layers." Full offload (`-ngl 99` / `auto`) is already correct in the current unit. This does **not** apply to models too large to fit 24 GB under any reasonable quant (100B+ total-param MoE) — see **Part B** for whether CPU/RAM offload of cold experts is viable there given the box's 128 GB RAM.
```

- [ ] **Step 3: Scope the "offload layers to RAM" assumption-challenged bullet**

old_string:
```
- **"Offload some layers to RAM to fit a bigger model."** Not on this CPU. Lacking AVX-512, CPU-resident layers use AVX2 kernels; every token must round-trip through PCIe + slow CPU matmul, and llama.cpp runs the whole graph at the pace of its slowest layers. Real-world reports put a handful of offloaded layers at a 3–10x end-to-end slowdown vs full-VRAM. Prefer: smaller quant, quantized KV, or smaller model — anything to stay 100% on-GPU. (For MoE specifically there is a nuance below.)
```

new_string:
```
- **"Offload some layers to RAM to fit a bigger model."** Not on this CPU, *for models that could otherwise fit in VRAM*. Lacking AVX-512, CPU-resident layers use AVX2 kernels; every token must round-trip through PCIe + slow CPU matmul, and llama.cpp runs the whole graph at the pace of its slowest layers. Real-world reports put a handful of offloaded layers at a 3–10x end-to-end slowdown vs full-VRAM. Prefer: smaller quant, quantized KV, or smaller model — anything to stay 100% on-GPU. **This changes once the model is too big for VRAM at any quant** (large sparse MoE): see **Part B** — offloaded-expert compute is memory-bandwidth-bound rather than AVX-bound, which is a materially different case than dense CPU-resident layers.
```

- [ ] **Step 4: Verify no stray references to the old bullet text remain and the file still parses as valid markdown structure**

```bash
grep -n "Part B" _research/LOCAL_LLM_PERF_OPS.md
```

Expected: two new hits, both inside the lines just edited (Executive summary bullet + Assumptions bullet), pointing at Part B. No hit yet for a Part B heading itself — that's created in Task 2.

- [ ] **Step 5: Commit**

```bash
git add _research/LOCAL_LLM_PERF_OPS.md
git commit -m "Scope VRAM-only guidance to models that fit; point to new Part B"
```

---

### Task 2: Part B intro — why the calculus changes + the bandwidth bottleneck

**Files:**
- Modify: `_research/LOCAL_LLM_PERF_OPS.md` (insert after the speculative decoding section, before the current `## Part B: Observability` heading)

**Interfaces:**
- Consumes: nothing from Task 1 except the "Part B" cross-reference name already used in the executive summary/assumptions bullets.
- Produces: the `## Part B: CPU/RAM offload for large MoE (128GB ceiling)` heading and its first two subsections (`### Why the calculus changes for large MoE`, `### The real bottleneck is RAM bandwidth, not AVX-512`). Task 3 appends immediately after this task's content, so this task must end with the doc still ending exactly at `### The real bottleneck...` content followed by the `---` separator that currently precedes `## Part B: Observability`.

- [ ] **Step 1: Research the two claims this subsection needs to support**

Run these searches (WebSearch) and note the source URL + one-line finding for each:
1. `"llama.cpp" "--n-cpu-moe" OR "-ot exps=CPU" MoE offload benchmark` — confirm the mechanism (offload sparse expert FFN tensors to CPU, keep attention/shared/dense layers on GPU) and that CPU compute per token scales with *active* params, not total.
2. `AVX-512 vs AVX2 llama.cpp CPU inference memory bandwidth bound` — confirm/refute that MoE-offload token generation is memory-bandwidth-bound (low arithmetic intensity: read expert weights once, do one matmul, discard) versus the dense-CPU-layer case (compute-bound enough for AVX-512 width to matter).
3. `i9-13900K DDR5 dual channel real world memory bandwidth GB/s benchmark` — get a real sustained-bandwidth figure (not the theoretical peak) for a 13900K class DDR5 dual-channel setup, to ground the Task 3 worked example. Note whether 4-DIMM (128GB) configs commonly run slower than 2-DIMM.

If a claim from these searches contradicts the "why calculus changes" framing (e.g. if offload turns out still compute-bound in some regime), write the finding as-is — do not force the narrative.

- [ ] **Step 2: Draft `### Why the calculus changes for large MoE`**

Required content (as bullet or prose, your choice, but must include all of):
- Restate the mechanism from the existing doc's line 24 (`--n-cpu-moe` / offload-experts-only) in one sentence, with a forward reference removed (it currently says "there is no reason to offload experts here" for the 30B-A3B case — that stays true, this new section is about models where it *isn't* optional).
- State explicitly: CPU-side compute for expert-offloaded inference is proportional to **active params per token**, not total params. Give the concrete example: a 235B-A22B model offloading experts does ~22B-equivalent FFN math per token on CPU, not 235B.
- One sentence on why this matters: it means large sparse MoE is structurally different from the dense-offload case the rest of the doc (correctly) warns against.

- [ ] **Step 3: Draft `### The real bottleneck is RAM bandwidth, not AVX-512`**

Required content:
- State the core finding from Step 1's research: offloaded-expert token generation is memory-bandwidth-bound (stream weights from RAM once per token, low arithmetic intensity), not compute-bound — cite the source(s) found.
- Contrast with why AVX-512 mattered for the *dense*-offload case discussed elsewhere in the doc (compute-bound enough that instruction width matters).
- State the conclusion this licenses: the AVX2-vs-AVX-512 gap matters much less for MoE expert offload than the rest of the doc's blanket "no AVX-512 = avoid offload" framing would suggest — but bandwidth itself is still a hard ceiling (sets up Task 3's formula).
- Note the real DDR5 bandwidth figure found in Step 1, cited, plus the 4-DIMM/2-DIMM caveat if found.

- [ ] **Step 4: Insert the heading and both subsections**

Use `Edit` on `_research/LOCAL_LLM_PERF_OPS.md`. Anchor on the existing separator before the Observability section:

old_string:
```
**Bottom line for this box**: if the daily driver is the 30B MoE, **skip speculative decoding** (keep the VRAM for context). If you switch to a **32B dense** coder for quality, **add a 0.5B same-family draft** — that is where the 1.5–2.5x lives. Always A/B with `/metrics` acceptance stats before committing.

---

## Part B: Observability endpoints & lightweight monitoring
```

new_string:
```
**Bottom line for this box**: if the daily driver is the 30B MoE, **skip speculative decoding** (keep the VRAM for context). If you switch to a **32B dense** coder for quality, **add a 0.5B same-family draft** — that is where the 1.5–2.5x lives. Always A/B with `/metrics` acceptance stats before committing.

---

## Part B: CPU/RAM offload for large MoE (128GB ceiling)

The guidance above ("stay in VRAM") holds for anything that fits in 24 GB at a usable quant. It stops being the relevant question once a candidate model is too large to fit under any reasonable quant — e.g. a 100B+ total-param MoE. This box has 128 GB system RAM, which reopens the question for that regime specifically.

### Why the calculus changes for large MoE

[Task 2 Step 2 content goes here]

### The real bottleneck is RAM bandwidth, not AVX-512

[Task 2 Step 3 content goes here]

---

## Part C: Observability endpoints & lightweight monitoring
```

Replace the two `[Task 2 Step N content goes here]` placeholders with the actual drafted prose from Steps 2–3 before applying the edit — those bracketed markers must never appear in the committed file. Note the existing `## Part B: Observability` heading is renumbered to `## Part C:` as part of this same edit (keeps the doc's part-lettering sequential; Task 6 will double check nothing else references the old "Part B: Observability" name).

- [ ] **Step 5: Verify structure and citation discipline**

```bash
grep -n "^## Part" _research/LOCAL_LLM_PERF_OPS.md
```

Expected: three hits — `Part A: Performance tuning...`, `Part B: CPU/RAM offload for large MoE...`, `Part C: Observability...` — in that order.

```bash
grep -n "TBD\|TODO\|\[Task" _research/LOCAL_LLM_PERF_OPS.md
```

Expected: no output.

Manually re-read the two new subsections: every numeric/factual claim must trace to a source noted in Step 1, or be explicitly marked `(projected)`/`(estimate)`.

- [ ] **Step 6: Commit**

```bash
git add _research/LOCAL_LLM_PERF_OPS.md
git commit -m "Add Part B intro: MoE offload calculus and bandwidth bottleneck"
```

---

### Task 3: Worked throughput model with sourced real-world numbers

**Files:**
- Modify: `_research/LOCAL_LLM_PERF_OPS.md` (insert immediately after Task 2's `### The real bottleneck is RAM bandwidth, not AVX-512` subsection, before the `---` / `## Part C` boundary)

**Interfaces:**
- Consumes: the DDR5 bandwidth figure sourced in Task 2 Step 1.3 — reuse it rather than re-deriving; if Task 2 found no solid figure, this task's Step 1 must find one.
- Produces: `### Worked throughput model` subsection ending with the same `---` / `## Part C` boundary Task 2 left in place (this task inserts *before* that boundary, not after).

- [ ] **Step 1: Research real-world offload throughput reports**

Run these searches and record source URL + reported tok/s + hardware config for each usable hit:
1. `ktransformers DeepSeek R1 tokens per second RTX 4090 DDR5 CPU offload`
2. `llama.cpp "-ot" OR "--n-cpu-moe" Qwen3-235B-A22B tokens per second benchmark`
3. `GLM-4.5-Air CPU GPU offload tokens per second consumer hardware`
4. `gpt-oss-120b CPU offload tokens per second consumer GPU`

Prioritize reports on hardware comparable to this box (single 24GB-class GPU, non-AVX-512 or explicitly AVX2-only CPU, DDR5). Discard reports on server/Xeon/AMX hardware or multi-GPU rigs — they don't transfer.

- [ ] **Step 2: Draft the bandwidth formula**

Required content:
```
tok/s ≈ RAM_bandwidth_bytes_per_sec / (active_params × bytes_per_param)
```
Explain each term in one line: `active_params` = the model's active-parameter count (not total); `bytes_per_param` depends on quant (~0.5–0.55 B for Q4_K_M, ~1 B for Q8_0 — cite the doc's own existing KV-cost convention at line 52 for consistency of units).

- [ ] **Step 3: Draft one fully worked numeric example**

Pick one concrete model from Step 1's results with a known active-param count (e.g. if a 235B-A22B or 106B-A12B model was found in Step 1, use it). Show the arithmetic: `active_params × bytes_per_param` = bytes/token, divided into the sourced DDR5 bandwidth figure = projected tok/s ceiling. Label this line `(projected, from formula)`.

- [ ] **Step 4: Cross-check the projection against Step 1's sourced numbers**

State whether the sourced real-world reports land above, below, or near the formula's projected ceiling, and give the one-sentence likely reason for any gap (e.g. real configs don't offload 100% of experts, some hot experts stay resident in VRAM and don't hit the RAM path every token, or the sourced rig had faster/slower RAM than assumed).

- [ ] **Step 5: Insert the subsection**

Use `Edit`. Anchor on Task 2's inserted boundary:

old_string:
```
### The real bottleneck is RAM bandwidth, not AVX-512

[content from Task 2]

---

## Part C: Observability endpoints & lightweight monitoring
```

(Use the actual text Task 2 committed, not the bracket placeholder — read the file first to get the exact current content for the old_string match.)

new_string: same content, with a new `### Worked throughput model` subsection (containing Steps 2–4's content) inserted between the end of `### The real bottleneck...` and the `---` separator.

- [ ] **Step 6: Verify**

```bash
grep -n "TBD\|TODO\|\[Task" _research/LOCAL_LLM_PERF_OPS.md
```

Expected: no output.

Re-read the new subsection: confirm the formula, the worked example, and the cross-check all cite sources or are labeled `(projected)`.

- [ ] **Step 7: Commit**

```bash
git add _research/LOCAL_LLM_PERF_OPS.md
git commit -m "Add worked RAM-bandwidth throughput model for MoE offload"
```

---

### Task 4: Alternative backends survey (ik_llama.cpp, ktransformers)

**Files:**
- Modify: `_research/LOCAL_LLM_PERF_OPS.md` (insert immediately after Task 3's `### Worked throughput model` subsection)

**Interfaces:**
- Consumes: nothing structural from Task 3 beyond the insertion anchor.
- Produces: `### Alternative backends` subsection.

- [ ] **Step 1: Research the two named forks**

Run these searches:
1. `ik_llama.cpp vs llama.cpp CPU MoE offload performance benchmark`
2. `ik_llama.cpp AVX2 quant kernels IQ quantization CPU speed`
3. `ktransformers AMX Xeon requirement consumer CPU non-server`
4. `ktransformers RTX 4090 DeepSeek CPU GPU hybrid inference tokens per second`

For each project, capture: (a) what it claims to do differently from mainline llama.cpp for CPU/MoE offload, (b) whether its speedup claims depend on server-only instruction sets (AMX, AVX-512) that the 13900K lacks, (c) at least one concrete tok/s comparison if available.

- [ ] **Step 2: Draft the subsection**

Required content:
- One paragraph per backend (ik_llama.cpp, ktransformers): what it is, what it claims, whether the claims apply to this CPU specifically (flag explicitly if a claimed speedup relies on AMX/AVX-512 the 13900K doesn't have).
- One sentence on the supply-chain/trust angle: both are third-party forks, not the packaged `llama.cpp-bin`; adopting either would need to go through this repo's package security policy (`private_dot_local/lib/scripts/system/CLAUDE.md` → "Package Security Policy") as a separate future decision — this section surveys the ceiling, it does not propose switching.
- Close with one sentence stating whether either backend's claims change the Part B conclusion (i.e. does the mainline `-ot`/`--n-cpu-moe` path already capture most of the achievable throughput, or is there a large gap worth a future dedicated evaluation).

- [ ] **Step 3: Insert the subsection**

Use `Edit`, anchoring on the end of Task 3's inserted content (read the file first for the exact current text to match against) and inserting the new `### Alternative backends` subsection before the `---` / `## Part C` boundary.

- [ ] **Step 4: Verify**

```bash
grep -n "TBD\|TODO\|\[Task" _research/LOCAL_LLM_PERF_OPS.md
```

Expected: no output. Re-read the subsection for citation discipline (every claim sourced or labeled).

- [ ] **Step 5: Commit**

```bash
git add _research/LOCAL_LLM_PERF_OPS.md
git commit -m "Add alternative CPU-offload backend survey (ik_llama.cpp, ktransformers)"
```

---

### Task 5: RAM budget table, benchmark recipe, decision framework

**Files:**
- Modify: `_research/LOCAL_LLM_PERF_OPS.md` (insert immediately after Task 4's `### Alternative backends` subsection, still before the `## Part C` boundary)

**Interfaces:**
- Consumes: the active-param/quant conventions established in Task 3 Step 2.
- Produces: `### RAM budget for candidate models`, `### Benchmark recipe`, `### Decision framework` subsections — the last content inserted before `## Part C`.

- [ ] **Step 1: Research candidate model sizes**

Run these searches to get GGUF file sizes / active+total param counts per quant:
1. `Qwen3-235B-A22B GGUF Q4_K_M file size total`
2. `GLM-4.5-Air 106B A12B GGUF quantization size`
3. `gpt-oss-120b MXFP4 size GGUF active parameters`

- [ ] **Step 2: Draft `### RAM budget for candidate models`**

Build a markdown table with columns: `Model | Total params | Active params | Quant | Total weight size | Est. VRAM-resident (attn+shared+KV) | Est. RAM-resident (cold experts) | Fits 128GB?`. Fill one row per model found in Step 1. Every size figure cites its source; where a figure is derived (not directly reported), label the cell `(derived)`. Leave the VRAM/RAM split estimate labeled `(projected)` since it's derived from the doc's own attention-vs-expert-parameter reasoning, not directly sourced.

- [ ] **Step 3: Draft `### Benchmark recipe`**

Required content — a concrete, runnable recipe:
```bash
# Keep attention/shared/dense layers on GPU, offload only expert FFN tensors to CPU
llama-server \
  --model <path-to-gguf> \
  -ngl 99 \
  --n-cpu-moe <N>  # or: -ot "exps=CPU" for the regex-tensor-override form
  --cache-type-k q8_0 --cache-type-v q8_0 \
  --flash-attn on \
  -c 8192 \
  --metrics
```
Explain `--n-cpu-moe N` vs `-ot "exps=CPU"` in one line each (N = number of expert layers to push to CPU, tunable to trade VRAM for offload amount; the `-ot` regex form offloads by tensor name pattern and is the more surgical option). State what to measure: `curl -s http://127.0.0.1:8080/metrics | grep tokens_predicted` for decode tok/s, or `llama-bench` for a controlled comparison. Recommend trialing the flag mechanics first on the existing 30B-A3B model (forcing a few experts to CPU artificially) to confirm the flags behave as documented on the installed build, before spending time downloading a 100GB+ model to test an unfamiliar config.

- [ ] **Step 4: Draft `### Decision framework`**

A markdown table with columns: `Candidate weight size @ chosen quant | Recommendation`. Rows:
- `≤ ~20 GB` → "Full VRAM — existing Part A guidance applies, no offload needed."
- `~20–90 GB (fits with headroom for OS + context in 128GB RAM)` → "Partial expert offload worth trialing via the benchmark recipe above; expect throughput to degrade roughly with the fraction of active-param bytes that must be read from RAM per token."
- `Fits only with < ~10 GB headroom, or projected tok/s (via the Task 3 formula) is below your usability floor` → "Not worth it on this hardware — stick to a VRAM-fit model instead."
State explicitly that "usability floor" is a personal threshold (e.g. 5–10 tok/s for asynchronous/reasoning use vs 20+ for interactive) and isn't asserted by this doc — the user needs to pick their own number before applying the table.

- [ ] **Step 5: Insert all three subsections**

Use `Edit`, anchoring on the end of Task 4's content (read the file first for exact current text) and inserting before the `---` / `## Part C` boundary.

- [ ] **Step 6: Verify**

```bash
grep -n "TBD\|TODO\|\[Task" _research/LOCAL_LLM_PERF_OPS.md
```

Expected: no output.

Check every table row in both new tables has the same number of `|` pipe separators as its header row (malformed tables are a common markdown bug):

```bash
awk '/^\| Model \| Total params/{p=1} p && /^\|/{print gsub(/\|/,"|")} /^$/{p=0}' _research/LOCAL_LLM_PERF_OPS.md
```

Expected: a consistent pipe-count per line within each table block.

- [ ] **Step 7: Commit**

```bash
git add _research/LOCAL_LLM_PERF_OPS.md
git commit -m "Add RAM budget table, benchmark recipe, and decision framework for MoE offload"
```

---

### Task 6: Finalize — open questions, sources, full-doc consistency pass

**Files:**
- Modify: `_research/LOCAL_LLM_PERF_OPS.md` (the `## Open questions` and `## Sources` sections near the end of the file)

**Interfaces:**
- Consumes: every source URL cited across Tasks 2–5 (collect them by re-reading the file's new Part B section).

- [ ] **Step 1: Collect every citation added in Tasks 2–5**

```bash
grep -n "\](http" _research/LOCAL_LLM_PERF_OPS.md
```

Cross-reference this list against the existing `## Sources` section (currently lines 176–191) — identify which URLs are new and not yet listed there.

- [ ] **Step 2: Add the new open question about DDR5 bandwidth**

old_string:
```
- **Flag-name stability**: speculative/KV draft flag names have changed across llama.cpp releases; pin the installed version's `--help` output before templating them into the unit.
```

new_string:
```
- **Flag-name stability**: speculative/KV draft flag names have changed across llama.cpp releases; pin the installed version's `--help` output before templating them into the unit.
- **Actual DDR5 bandwidth on the 128GB box is unverified**: Part B's worked throughput model assumes a bandwidth figure sourced from general 13900K benchmarks, not this specific box's DIMM count/speed. 4-DIMM 128GB configs commonly run slower than 2-DIMM due to signal integrity on Raptor Lake boards. Confirm with `sudo dmidecode --type 17` or `lshw -C memory` before trusting the Part B numbers for a real decision.
```

- [ ] **Step 3: Append all new source URLs to the Sources list**

Use `Edit` to add one bullet per new URL identified in Step 1, in the existing list's style (`- [Descriptive title](url)`), appended after the existing last entry (currently the systemd watchdog guide).

- [ ] **Step 4: Full-document consistency read-through**

Read the entire file top to bottom. Confirm:
- `## Part A`, `## Part B`, `## Part C` appear in that order with no leftover "Part B: Observability" text.
- The executive summary and assumptions-challenged bullets from Task 1 correctly point to the final Part B heading text.
- No bracketed `[Task N ...]` placeholder markers remain anywhere.
- Every table in Part B renders with consistent column counts.

```bash
grep -n "TBD\|TODO\|\[Task\|Part B: Observability" _research/LOCAL_LLM_PERF_OPS.md
```

Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add _research/LOCAL_LLM_PERF_OPS.md
git commit -m "Finalize Part B: open questions and source citations"
```

---

## Self-Review Notes

**Spec coverage**: Task 1 = structural revisions (spec §"Structural changes" items 1–3). Task 2 = spec Part B outline items 1–2. Task 3 = item 3. Task 4 = item 4. Task 5 = items 5–7. Task 6 = spec's "Sourcing approach" + "New open question to add" + Part B outline item 4 (structural change item 4: renumbering, closed out in Task 2 Step 4). All spec sections have a task.

**Placeholder scan**: bracketed `[Task N Step content goes here]` markers appear only as *instructions to the implementer* inside code fences describing what to replace before committing — each task's own verification step explicitly greps to confirm none survive in the actual file. No bare TBD/TODO anywhere.

**Type consistency**: "Part B" / "Part C" naming is fixed once in Task 2 Step 4 and referenced identically (verified via grep) in Tasks 1, 2, and 6. The bandwidth formula's variable names (`active_params`, `bytes_per_param`, `RAM_bandwidth_bytes_per_sec`) are defined once in Task 3 Step 2 and reused as-is in Task 5's decision framework — no renaming across tasks.
