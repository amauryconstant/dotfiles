# Package Supply-Chain Hardening Roadmap

Remediation backlog for the exposure documented in
`_research/PACKAGE_SUPPLY_CHAIN_RESEARCH.md`.
Created: 2026-06-15.

**Legend**: `[ ]` pending · `[x]` done · `[SKIPPED]` out of scope

**Status (2026-06-16, P0 increment)**: **P0 complete in tripwire-centric form** — P0.1/P0.2/P0.3
done. Install pipeline now splits by trust tier (official/chaotic → `pacman -S`, true AUR → paru),
deriving tier at runtime via `_pkg_is_aur` (no `packages.yaml` tagging). The **TOFU gap is closed**:
a *bootstrap-aware* gate allows trust-on-first-use only while the hash DB is unseeded (fresh
machine), and **blocks new/unknown AUR packages once seeded** — same heuristic in lib
`_tripwire_check` (`_tripwire_is_bootstrap`) and the self-contained inline sync recipe. `--noconfirm`
was deliberately **kept** (interactive paru review rejected — would break unattended topgrade); the
tripwire block + `package-manager approve` is the review. No re-seed needed (hash recipe unchanged).
Files: `operations/pkgbuild-tripwire.sh`, `packages/batch-operations.sh`,
`run_onchange_before_sync_packages.sh.tmpl`. P0.3 was already satisfied by P1.2 (`cmd-update.sh`).

**Status (2026-06-16)**: Second increment landed (`38d78fa` P1.2 tripwire, `8bc2248` P1.3 SigLevel,
`ace8ee2` docs/findings) — **P1.2 gaps closed, P1.1 done, P1.3 done**.
- **P1.2**: tripwire now hashes **PKGBUILD + `.install` hooks** (cloned via `paru -G`; `.install`
  runs as root via `pacman -U`), is **fail-CLOSED** (failed fetch blocks), and gates the previously
  unprotected **AUR downgrade** path (`sync-pacman.sh`). Handles split packages (pkgbase-named clone
  dir). Inline chezmoi recipe mirrored byte-for-byte. **Requires `approve --seed` re-baseline** (hash
  recipe changed).
- **P1.1**: investigated and found **no action needed** — there are **no locally-built `-git`
  packages**. Both `-git` packages (`wayfreeze-git`, `gpu-screen-recorder-git`) are served by
  **chaotic-aur as signed prebuilt binaries** (`Validated By: Signature`), not built from upstream
  HEAD on this machine, so the tripwire's `_pkg_is_aur` correctly treats them as trusted (same as
  official). A pin would have *replaced a signed binary with a local build* — strictly worse. (An
  initial attempt to pin `wayfreeze-git` was reverted once its chaotic-aur provenance was confirmed.)
- **P1.3**: `run_once_before_002` now **idempotently pins `SigLevel = Required DatabaseOptional`** in
  `/etc/pacman.conf` `[options]` (detects/repairs drift; scoped so per-repo overrides untouched).
  `LocalFileSigLevel`/`DatabaseRequired` deliberately left default (would break chaotic bootstrap).
- **P2.1**: audit run — **no** AUR package is currently available in official repos (nothing to
  migrate); all 17 are AUR-by-nature (drivers, hypr* tooling, input tools). `!debug` already done.

**Status (2026-06-15)**: PKGBUILD-diff **tripwire MVP implemented & committed** (`af3d47a`) —
runtime tier detection + hash gate wired into both pipelines (`package-manager` CLI:
update/sync/install, and the self-contained chezmoi sync script) +
`package-manager approve [--seed|--all|<pkg>]`. Deployed; DB seeded with 17 installed AUR packages.
This closes **P1.2** and supplies the review gate that **P0.3** (and the AUR portion of P0.1/P0.2)
needed, via *detection* rather than mandatory interactive review — so topgrade stays unattended in
steady state. Module: `operations/pkgbuild-tripwire.sh`; docs: `package-manager/CLAUDE.md`.

Also committed (`cf170a9`): `~/.config/pacman/makepkg.conf` now sets `OPTIONS+=('!debug')` to
suppress `*-debug` split packages from AUR builds — removes the `-debug` seed/scan noise the
tripwire had to skip (`pacman -Qmq` no longer accrues new `-debug` foreign packages). Build-hygiene
side-effect; see P2.1 note below. Remaining items below are still open.

**Core problem**: the package pipeline is fully unattended (`--noconfirm` everywhere), so any
hijacked AUR/`-git`/Chaotic-AUR package builds and runs arbitrary code — as the build user, with
sudo available — on the next `sync`/`update`, with no diff shown and no detection layer. Goal:
insert review + pinning + detection between `packages.yaml` and code execution, **without** losing
unattended convenience for trusted official-repo packages.

**Design principle**: split trust tiers. Official `[core]/[extra]/[multilib]` = auto/`--noconfirm`.
AUR / `-git` / Chaotic-AUR = reviewed and/or pinned and/or tripwired.

---

## P0 — Break the unattended-build-without-review loop

### P0.1 — Split install pipeline by trust tier
**What**: Separate package installs into "official → auto" vs "AUR/foreign → reviewed". Today a
single `paru -S --needed --noconfirm` over a flat list treats all sources identically.
**Target files**: `.chezmoiscripts/run_onchange_before_sync_packages.sh.tmpl`,
`private_dot_local/lib/scripts/system/package-manager/` (install paths),
`.chezmoidata/packages.yaml` (source tagging)
**Effort**: Medium–High

- [SKIPPED] Tag each package's source in `packages.yaml` — superseded by **runtime derivation**
      via the existing `_pkg_is_aur()` (`pacman -Si` vs `paru -Si --aur`); no hand-maintained tags.
- [x] Install official-repo packages with `pacman -S --needed --noconfirm` (no PKGBUILD risk) —
      inline recipe + `batch-operations.sh` now partition by tier and route official → pacman.
- [x] Install AUR packages via paru, **tripwire-gated** (kept `--noconfirm` per the tripwire-centric
      decision — review happens via the tripwire block + `package-manager approve`, not a paru diff
      prompt, so topgrade stays unattended; see P0.2).
- [x] Provisioning behavior decided: **bootstrap-aware gate** — unseeded DB (fresh machine) =
      trust-on-first-use so install isn't bricked; seeded DB = new AUR packages are BLOCKED until
      approved. Same heuristic in lib `_tripwire_check` and the inline recipe.
- [x] Chaotic-AUR prebuilt path verified: chaotic-aur is a pacman sync repo, so `pacman -Si` hits →
      lands in the official bucket (`pacman -S`), unchanged behavior.

### P0.2 — Stop blanket `--noconfirm` on AUR builds
**What**: `--noconfirm` overrides paru's `SkipReview = false`, so the review prompt never fires.
Remove `--noconfirm` from AUR build call sites (keep for official/removals where safe).
**Target files**: `package-manager/packages/manager-interface.sh:162,164`,
`packages/batch-operations.sh:45`, `packages/package-operations.sh:79`,
`operations/sync-pacman.sh:165`, `commands/cmd-update.sh:57`,
`executable_package-manager:435`
**Effort**: Medium

- [x] Audited each `--noconfirm` site; classified official vs AUR via runtime `_pkg_is_aur`.
- [SKIPPED] Drop `--noconfirm` for AUR `paru -S` (interactive paru diff) — **intentionally not
      adopted**: it would reintroduce prompts and break unattended topgrade (`assume_yes`). The P1.2
      tripwire supplies the review gate instead (block + `package-manager approve`), so AUR builds
      keep `--noconfirm` but cannot build a changed/new PKGBUILD unreviewed.
- [SKIPPED] paru `SkipReview`/diff engagement — moot under the tripwire-centric model (gate is the
      tripwire, not paru's prompt).
- [x] Non-interactive behavior kept for removals (`-Rns`) and official installs/upgrades (pacman).

### P0.3 — Gate `update` on PKGBUILD diffs
**What**: `package-manager update` / topgrade run `paru -Syu --noconfirm` — unattended AUR
upgrades execute updated (possibly hijacked) build scripts. Make AUR upgrades show diffs.
**Target files**: `package-manager/commands/cmd-update.sh:57`,
`private_dot_config/topgrade.toml.tmpl` (`assume_yes`, pre-command)
**Effort**: Medium

- [x] AUR upgrades routed through the P1.2 tripwire gate (`cmd-update.sh:56-83`: scans `paru -Qua`,
      holds changed/unapproved AUR, prints `approve` hint).
- [x] Official `-Syu` kept unattended (runs `sudo pacman -Syu` when AUR is held).
- [x] Reconciled with topgrade `assume_yes` — topgrade only invokes `package-manager update`, which
      self-gates; `assume_yes` does not bypass the tripwire (held AUR is skipped, not auto-confirmed).

---

## P1 — Pinning & detection

### P1.1 — Pin `-git` packages to known-good commits
**What**: `-git` packages build from upstream HEAD — an unpinned trust hole (HEAD poisoning runs at
next build). Pin to reviewed commits, or migrate to trusted `-bin`/official where possible.
**Target files**: `.chezmoidata/packages.yaml`, install path
**Effort**: Medium

- [x] Inventory `-git` packages: `wayfreeze-git` + `gpu-screen-recorder-git`. **Both are chaotic-aur
      signed prebuilt binaries** (`pacman -Si` → `Repository: chaotic-aur`, `Validated By: Signature`),
      NOT built locally from HEAD → not tripwire blind spots, no pin needed.
- [SKIPPED] Pin a commit — would replace a signed chaotic-aur binary with a local build (worse). No
      true-AUR local-build `-git` package exists to pin.
- [x] Reproducibility: chaotic-aur ships a fixed versioned binary (`0.2.0.r0.g8f813ab-1`); upstream
      HEAD changes don't auto-flow to this machine without a chaotic-aur rebuild.

### P1.2 — PKGBUILD hash/diff tripwire
**What**: No detection when an AUR package's PKGBUILD changes. Store a hash of each AUR
PKGBUILD/`.install`; alert at `sync`/`update` when it changes so an adopted/hijacked package can't
slip through silently.
**Target files**: `package-manager/operations/` (new tripwire module), state file under
`~/.local/state/` (hash DB)
**Effort**: Medium–High

- [x] Fetch/inspect PKGBUILD before build (`paru -Gp <name>`)
- [x] Maintain a per-package hash DB (`~/.local/state/package-manager/pkgbuild-hashes.yaml`)
      — **PKGBUILD only**; `.install` + sources block still TODO (see limits below)
- [x] On change: block + show diff + require explicit ack (`package-manager approve`) before building
- [x] Seed the DB from current known-good state (`package-manager approve --seed`)
- [x] Hash `.install` hook too (clone via `paru -G`; blob = PKGBUILD + sorted `*.install`).
      Upstream `source=()` block stays out of scope (TOCTOU; the two `-git` packages are chaotic-aur
      signed prebuilt binaries — not local builds — so they aren't tripwire blind spots, see P1.1)
- [x] Fail-closed: failed clone/fetch now **blocks** the build everywhere (lib + inline)
- [x] Gate the AUR **downgrade** path (`sync-pacman.sh` `_sync_handle_downgrade`) — was unprotected

### P1.3 — Managed `pacman.conf` with explicit `SigLevel`
**What**: No `pacman.conf` template in repo → signature policy is host-default, not
version-controlled. Manage it with explicit `SigLevel`/`LocalFileSigLevel`.
**Target files**: new `private_dot_config/pacman/pacman.conf.tmpl` (or modify_manager-managed
`/etc/pacman.conf`), `run_once_before_002_install_package_manager.sh.tmpl` (repo append logic)
**Effort**: Medium

- [x] Management approach decided: user-scoped chezmoi can't own `/etc` cleanly → **idempotent
      enforcement in `run_once_before_002`** (matches the existing multilib/chaotic `sudo` edits)
- [x] Set explicit `SigLevel = Required DatabaseOptional` in `[options]` (awk-detect + sed-repair,
      scoped to `[options]` so per-repo overrides are untouched; detects/repairs drift)
- [SKIPPED] Stricter `LocalFileSigLevel`/`DatabaseRequired` — would break the Chaotic-AUR `pacman -U`
      bootstrap (key not yet trusted) and unsigned official DBs. Documented inline.
- [x] Reconciled with the script-002 `sudo tee` flow (same script, runs before the repo appends)

---

## P2 — Hardening & hygiene

### P2.1 — Reduce AUR surface
**What**: Every AUR package is an independent trust root. Drop non-essential ones; migrate any now
available in official repos.
**Target files**: `.chezmoidata/packages.yaml`
**Effort**: Low–Medium

- [x] Re-check each AUR package against official repos (`pacman -Si`) — audited all 17 foreign pkgs
      (2026-06-16): **none** available in official repos, so nothing to migrate
- [x] Drop non-essential AUR packages — none dropped: all are AUR-by-nature (samsung drivers, hypr*
      tooling, voxtype/kanata input, etc.). `wayfreeze-git` remains listed normally — it's a
      chaotic-aur signed prebuilt binary (see P1.1), not a local build, so no pin/removal applies
- [ ] Flag remaining Chaotic-AUR (third-party prebuilt binary trust) for extra scrutiny
- [x] Disable `*-debug` split packages from AUR builds (`makepkg.conf` `OPTIONS+=('!debug')`,
      commit `cf170a9`) — fewer build artifacts; keeps `pacman -Qmq` (tripwire seed/scan source)
      free of non-independent `-debug` entries

### P2.2 — Flatpak hygiene
**What**: Sandbox is the only Flatpak defense layer; recent CVEs (≤ 1.16.4) show it's not absolute.
**Target files**: package data / docs
**Effort**: Low

- [ ] Ensure Flatpak ≥ 1.16.4 (CVE-2025-4870)
- [ ] Prefer *verified* Flathub apps; document the preference
- [ ] Review broad permissions (`--filesystem=host` etc.) for installed apps (Flatseal)

### P2.3 — Document package supply-chain security policy
**What**: Repo's "Security-first" claim covers only age encryption; the package pipeline — its
riskiest path — has no documented policy. Contradiction worth closing.
**Target files**: `private_dot_local/lib/scripts/system/CLAUDE.md`,
`private_dot_local/lib/scripts/system/package-manager/CLAUDE.md`
**Effort**: Low

- [ ] Document trust tiers, review requirements, pinning policy, SigLevel
- [ ] Cross-reference `_research/PACKAGE_SUPPLY_CHAIN_RESEARCH.md`

### P2.4 — IoC hygiene check (one-time, time-sensitive)
**What**: June 2026 Atomic Arch / July 2025 CHAOS RAT window. If AUR was updated recently, scan for
known indicators.
**Target files**: n/a (operational, run manually)
**Effort**: Low

- [ ] Check `/sys/fs/bpf/hidden_*` (eBPF rootkit pinned maps)
- [ ] Check installed npm pkgs `atomic-lockfile` / `js-digest` / `lockfile-js`
- [ ] Check `/tmp/systemd-initd` (CHAOS RAT artifact)
- [ ] If any found: rotate all credentials (SSH keys, GitHub/npm/Vault tokens, browser sessions),
      reinstall — removal alone is insufficient

---

## Sequencing notes

- **P0 is the high-leverage block** — it alone closes most of the exposure (review gate between
  `packages.yaml` and code execution). P0.1 (tier split) is the prerequisite for P0.2/P0.3.
- **P1.1 + P1.2** make first-install/update reproducible *and* detectable; do after P0 so the
  reviewed path exists to hook into.
- **P1.3** is independent and can land anytime.
- **P2** is hygiene/docs — cheap, do alongside.
- Validate every change against the repo's mandatory checks (`chezmoi execute-template`,
  `bash -n`, `shellcheck`, `chezmoi diff`) — see root `CLAUDE.md`.
