# Package Supply-Chain Hardening Roadmap

Remediation backlog for the exposure documented in
`_research/PACKAGE_SUPPLY_CHAIN_RESEARCH.md`.
Created: 2026-06-15.

**Legend**: `[ ]` pending · `[x]` done · `[SKIPPED]` out of scope

**Status (2026-06-15)**: PKGBUILD-diff **tripwire MVP implemented** — runtime tier detection +
hash gate wired into both pipelines (`package-manager` CLI: update/sync/install, and the
self-contained chezmoi sync script) + `package-manager approve [--seed|--all|<pkg>]`. This closes
**P1.2** and supplies the review gate that **P0.3** (and the AUR portion of P0.1/P0.2) needed,
via *detection* rather than mandatory interactive review — so topgrade stays unattended in steady
state. Module: `operations/pkgbuild-tripwire.sh`; docs: `package-manager/CLAUDE.md`. Remaining items
below are still open.

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

- [ ] Tag each package's source in `packages.yaml` (official / aur / chaotic) — or derive it
      (`paru -Si`/`pacman -Si` repo field) so the list need not be hand-maintained
- [ ] Install official-repo packages with `pacman -S --needed --noconfirm` (no PKGBUILD risk)
- [ ] Install AUR/`-git` packages **without** `--noconfirm` so paru shows the PKGBUILD/`.install`
      diff (or a dedicated reviewed pass — see P0.2)
- [ ] Decide provisioning behavior: first-install is necessarily less interactive — gate behind an
      explicit "I reviewed these" acknowledgement, or pin (P1.1) so first install is reproducible
- [ ] Verify Chaotic-AUR prebuilt `.pkg.tar.zst` path still works under the split

### P0.2 — Stop blanket `--noconfirm` on AUR builds
**What**: `--noconfirm` overrides paru's `SkipReview = false`, so the review prompt never fires.
Remove `--noconfirm` from AUR build call sites (keep for official/removals where safe).
**Target files**: `package-manager/packages/manager-interface.sh:162,164`,
`packages/batch-operations.sh:45`, `packages/package-operations.sh:79`,
`operations/sync-pacman.sh:165`, `commands/cmd-update.sh:57`,
`executable_package-manager:435`
**Effort**: Medium

- [ ] Audit each `--noconfirm` site; classify official vs AUR (depends on P0.1 tagging)
- [ ] Drop `--noconfirm` for AUR `paru -S` builds; keep paru's diff review on
- [ ] Confirm `paru.conf` `SkipReview = false` + diff viewing actually engages once `--noconfirm`
      is gone
- [ ] Keep non-interactive behavior for removals (`-R`) and official upgrades where no PKGBUILD runs

### P0.3 — Gate `update` on PKGBUILD diffs
**What**: `package-manager update` / topgrade run `paru -Syu --noconfirm` — unattended AUR
upgrades execute updated (possibly hijacked) build scripts. Make AUR upgrades show diffs.
**Target files**: `package-manager/commands/cmd-update.sh:57`,
`private_dot_config/topgrade.toml.tmpl` (`assume_yes`, pre-command)
**Effort**: Medium

- [ ] Route AUR upgrade through a reviewed path (paru diff review, or the P1.2 tripwire as a gate)
- [ ] Keep official `-Syu` unattended
- [ ] Reconcile with topgrade `assume_yes = true` — ensure AUR step isn't silently auto-confirmed

---

## P1 — Pinning & detection

### P1.1 — Pin `-git` packages to known-good commits
**What**: `-git` packages build from upstream HEAD — an unpinned trust hole (HEAD poisoning runs at
next build). Pin to reviewed commits, or migrate to trusted `-bin`/official where possible.
**Target files**: `.chezmoidata/packages.yaml`, install path
**Effort**: Medium

- [ ] Inventory `-git` packages: `wayfreeze-git`, `gpu-screen-recorder-git` (chaotic), and any
      others
- [ ] For each: pin a commit (custom PKGBUILD / `#commit=` source), move to `-bin`/official, or
      accept-and-document the risk
- [ ] Record chosen commit/version so first install is reproducible

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
- [ ] Hash `.install` hook + sources block too (MVP hashes PKGBUILD only)
- [ ] Fail-closed option for `paru -Gp` fetch failures (MVP fails open)

### P1.3 — Managed `pacman.conf` with explicit `SigLevel`
**What**: No `pacman.conf` template in repo → signature policy is host-default, not
version-controlled. Manage it with explicit `SigLevel`/`LocalFileSigLevel`.
**Target files**: new `private_dot_config/pacman/pacman.conf.tmpl` (or modify_manager-managed
`/etc/pacman.conf`), `run_once_before_002_install_package_manager.sh.tmpl` (repo append logic)
**Effort**: Medium

- [ ] Decide management approach (chezmoi-managed system file vs modify_manager merge — `/etc`
      needs root; check existing patterns)
- [ ] Set explicit `SigLevel = Required DatabaseOptional` (or stricter) and pin `[multilib]` +
      `[chaotic-aur]` repo definitions
- [ ] Reconcile with the script-002 `sudo tee` append flow so they don't fight

---

## P2 — Hardening & hygiene

### P2.1 — Reduce AUR surface
**What**: Every AUR package is an independent trust root. Drop non-essential ones; migrate any now
available in official repos.
**Target files**: `.chezmoidata/packages.yaml`
**Effort**: Low–Medium

- [ ] Re-check each AUR package against official repos (`pacman -Si`); migrate where possible
- [ ] Drop non-essential AUR packages
- [ ] Flag remaining Chaotic-AUR (third-party prebuilt binary trust) for extra scrutiny

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
