---
description: Check for new Omarchy releases, generate per-release research docs, and update the integration backlog
allowed-tools: Bash(OMARCHY_AUTO_UPDATE=true bash *), Read, Write, Glob, Task(subagent_type:omarchy-release-researcher), Task(subagent_type:omarchy-plan-updater)
---

# Omarchy Release Tracker

Two-phase pipeline: per-release research docs → living integration backlog.

## Instructions

### Phase 1 — Fetch release data

Run the script:

!`OMARCHY_AUTO_UPDATE=true bash ~/.local/share/chezmoi/.claude/commands/omarchy-changes/script.sh 2>/dev/null`

If output contains "No new releases", stop and report that to the user.

### Phase 2 — Parse releases

Parse the script output. Each release is delimited by:
```
═══════════════════════════════════════════════════════════
Release: vX.Y.Z
═══════════════════════════════════════════════════════════
```

Extract for each release:
- `version` (e.g. `v3.2.3`)
- `prev_version` (the tag before it, from the `Previous Version:` field in the data block)
- `commit_count` (from `Commits Included:` field)
- `release_notes` (the `Release Notes:` block content)

### Phase 3 — Research (parallel)

For each release, spawn an `omarchy-release-researcher` task **in parallel**. Pass a prompt containing:

```
Version: vX.Y.Z
Previous Version: vA.B.C
Commits: N

Release Notes:
[raw notes here]

Write research doc to: /home/amaury/.local/share/chezmoi/_research/omarchy/OMARCHY_vX.Y.Z.md
```

Wait for all researcher tasks to complete before proceeding.

### Phase 4 — Plan update (sequential, after all researchers done)

Spawn one `omarchy-plan-updater` task. Pass:

```
New research docs created:
- /home/amaury/.local/share/chezmoi/_research/omarchy/OMARCHY_vX.Y.Z.md
[list all new docs]

Plan file: /home/amaury/.local/share/chezmoi/_plans/OMARCHY.md
```

### Phase 5 — Report to user

Summarize:
- N releases processed (list versions)
- Research docs created (or skipped if already existed)
- P1/P2/P3 item counts from updated plan
- Any breaking changes detected (highlight prominently)
- Point user to `_plans/OMARCHY.md` for the full backlog

## Notes

- Researcher agents are idempotent — they skip if the research doc already exists
- State resets: `echo "v0" > ~/.local/state/omarchy-tracker/last-tag` to reprocess all history
- Research docs land in `_research/omarchy/OMARCHY_vX.Y.Z.md`
- Plan updater does a full rewrite of `_plans/OMARCHY.md` (not append)
