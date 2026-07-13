# dcli Integration Research

**Created**: July 2026
**Focus**: Evaluate replacing the in-tree `package-manager` with upstream `dcli` (vendored at `_ai/dcli/`) as the declarative package layer for this repo.
**Phase**: Investigation complete. **Verdict: do not replace.** Doors left open for selective feature adoption and a non-invasive shim prototype.
**Method**: Read-only audit of vendored dcli 0.2.2 Rust source + parallel read of the existing `package-manager` Bash pipeline. All claims cited with `file:line`.

---

## 1. Executive Summary

`dcli` is an attractive, mature-shaping Rust tool that brings a strong feature set (Lua/Nix dynamic configs, services management, MIME defaults, fzf TUI, JSON output, hardware detection) — several of which the current `package-manager` lacks. As a **generic** declarative package tool it is well-designed.

However, as a **replacement** for this repo's `package-manager`, it fails on two non-negotiable axes:

1. **No supply-chain tripwire equivalent.** dcli treats `paru -S` as an opaque install call (`_ai/dcli/src/backend/pacman.rs:20-30`) and never observes the AUR PKGBUILD before paru builds it. The repo's tripwire — the security control marked P0–P2 complete in `_plans/archive/PACKAGE_SUPPLY_CHAIN_HARDENING.md` and the most-defended part of the package pipeline — has **no insertion point** in dcli without either a `paru` binary shim or a Rust fork.
2. **Config-schema incompatibility with chezmoi.** dcli hardcodes `~/.config/arch-config/{hosts,modules}/` as its source of truth; the repo uses `.chezmoidata/packages.yaml` (chezmoi-templated, hash-triggered, GPU-driver-aware). Migration requires either relocating config (losing template variables and the `run_onchange` hash trigger) or building a bridge that produces a parallel copy — neither is a net win.

Secondary gaps (lockfile, version pinning, hybrid sync+update, flock protection) are **not currently exercised** by `.chezmoidata/packages.yaml` and would be acceptable losses — but they don't tip the balance.

**Recommendation**: keep `package-manager`. Treat dcli as a **source of ideas** for incremental improvements (JSON output, Lua-style hardware detection via Go templates, TUI search), not as a replacement. If a prototype is desired, build a `paru` shim (Option F below) as a side experiment that doesn't require a Rust fork or a config migration.

---

## 2. Subjects of Comparison

### 2.1 `package-manager` v3.0 (in-tree)

- **Location**: `private_dot_local/lib/scripts/system/package-manager/` (deployed to `~/.local/lib/scripts/system/package-manager/`)
- **Entry**: `private_dot_local/bin/executable_package-manager` → `executable_package-manager` in package-manager dir (4-layer modular: `core/`, `operations/`, `packages/`, `commands/`)
- **Language**: Bash (POSIX-shy: uses associative arrays, `[[`)
- **Config source**: `.chezmoidata/packages.yaml` — chezmoi-native, templated, hash-triggered
- **State**: `~/.local/state/package-manager/` (installed-records, lockfile, constraint-cache, tripwire DB, snapshots)
- **UI**: `gum` via `core/gum-ui.sh`
- **Reference**: `private_dot_local/lib/scripts/system/package-manager/CLAUDE.md`

### 2.2 `dcli` 0.2.2 (vendored, read-only)

- **Location**: `_ai/dcli/` (git subtree, repo-only, not deployed — see `_guides/VENDORED_SUBTREES.md`)
- **Upstream**: `gitlab.com/theblackdon/dcli`, AUR package `dcli-arch-git`
- **Language**: Rust 2021 edition, single static binary (`Cargo.toml` 72 lines, 22 dependencies)
- **Config source**: `~/.config/arch-config/{hosts,modules,scripts}/` — dcli-owned directory tree
- **Config formats**: YAML + Lua + Nix (hardware detection at eval time via `dcli.hardware.*`)
- **State**: `~/.config/arch-config/.state/` (dcli-managed, opaque)
- **UI**: Built-in TUI (ratatui + fzf), `colored` crate, optional `indicatif` progress
- **Distribution support**: pacman + APT + DNF (APT/DNF irrelevant on this Arch-only repo)
- **Reference**: `_ai/dcli/README.md` (1504 lines), `_ai/dcli/src/` (Rust source)

---

## 3. Feature Comparison

### 3.1 Capabilities matrix

| Capability | `package-manager` | `dcli` | Notes |
|---|---|---|---|
| Module-based declarative config | ✅ | ✅ | Both; dcli additionally supports conflicts + per-host overrides |
| YAML config | ✅ | ✅ | Schema differs (see §6) |
| Lua dynamic config | ❌ | ✅ | `dcli.hardware.*`, `dcli.system.*`, `dcli.package.*` APIs |
| Nix config | ❌ | ✅ | Via `nix-instantiate` evaluation |
| Hardware detection | Chezmoi template + yq-rewrite at sync | Native Lua API | dcli's approach is cleaner |
| Flatpak (user scope) | ✅ | ✅ | Both user-scope |
| Services management | ❌ (separate: `.chezmoidata/services.yaml`) | ✅ | dcli unifies |
| Default apps (XDG MIME) | ❌ | ✅ | Currently unmanaged |
| Dotfiles symlinking (Stow-like) | ❌ | ✅ | **Redundant** — we have chezmoi |
| Pre/post-install hooks | ✅ (basic) | ✅ (rich: `ask`/`always`/`once`/`skip`, run-as-user) | dcli richer |
| Sequential module processing | ❌ | ✅ | Useful for repo setup |
| Timeshift/Snapper backup | ✅ (Timeshift; Snapper auto-detect) | ✅ | Equivalent |
| fzf TUI | ❌ (gum menus only) | ✅ | Net win for dcli |
| JSON output | ❌ | ✅ (`--json` global flag) | Net win for dcli |
| Config backup/restore | ✅ (`state.sh`) | ✅ | Equivalent |
| Multi-host / multi-machine | ❌ | ✅ (`dcli repo init/clone/push/pull`) | **Redundant** — chezmoi already does this |
| Self-update | ❌ | ✅ (`dcli self-update`) | Adds supply-chain surface |
| Module upload/download (community repo) | ❌ | ✅ | Adds network surface; not aligned with security-first constraint |
| **Supply-chain tripwire** | ✅ (`package-manager approve`) | ❌ | **Hard blocker — see §4** |
| **Trust-tier install split** | ✅ (`_pkg_is_aur`) | ❌ | **Hard blocker — see §4** |
| Version pinning (`>=`, `<`, exact) | ✅ (code present, **unused**) | ❌ | No `version` field in `Package` struct (`src/package/mod.rs:9-12`) |
| Lockfile | ✅ (`locked-versions.yaml`, **unused**) | ❌ | dcli's "Update respects version constraints" docstring is misleading |
| Hybrid sync+update | ✅ (`update` = sync + upgrade) | ❌ (separate `sync`/`update`) | Minor |
| Concurrent sync protection (flock) | ✅ (`operations/sync-lock.sh`) | ❌ | Minor |
| chezmoi-native config | ✅ | ❌ | **See §6** |
| Gum UI library integration | ✅ | ❌ | dcli has its own TUI |
| Batch AUR validation (24x faster) | ✅ (`core/validation.sh`) | ❌ | Single-shot `paru -Si` per package |

### 3.2 Features dcli uniquely brings (net new)

- **Lua/Nix dynamic configs** — `dcli.hardware.has_nvidia()`, `dcli.system.distro()`, etc. evaluated at config-load time. Would replace the current `.chezmoi.yaml.tmpl`-detects-`nvidiaDriverType` → `run_onchange_before_sync_packages.sh.tmpl:19-34` rewrites module flags via yq pattern.
- **Declarative services** — systemd enable/disable inside the same config. Currently a separate concern (`.chezmoidata/services.yaml` + `run_once_after_002_configure_system_services.sh.tmpl`).
- **Default apps / XDG MIME** — `browser`, `text_editor`, `file_manager`, etc. Currently not declaratively managed.
- **JSON output** on all commands — would enable scripting/observability the current tool can't offer.
- **fzf-based TUI** for search, module enable, restore, edit.
- **`dcli merge --services/--defaults/--include-deps`** — richer bootstrap from current system state.

### 3.3 Features dcli uniquely lacks (current features with no equivalent)

| Feature | Criticality | Status in current repo |
|---|---|---|
| **Supply-chain tripwire** | 🔴 Blocker | Active. `cmd-approve.sh` + `operations/pkgbuild-tripwire.sh` + inline implementation in `run_onchange_before_sync_packages.sh.tmpl:123-227`. Documented in `_guides/PACKAGE_SUPPLY_CHAIN_SECURITY.md`. |
| **Trust-tier install split** (official / chaotic-aur / true-AUR) | 🔴 Blocker | `_pkg_is_aur` routes only true-AUR through the gate. chaotic-aur signed binaries bypass. dcli treats all AUR uniformly via `paru`/`yay`. |
| **chezmoi-native config** | 🟠 Major | dcli wants `~/.config/arch-config/` as source of truth. Schema mismatch with `.chezmoidata/packages.yaml` is fundamental (see §6). |
| Lockfile | 🟡 Minor | Code exists; **not exercised** (grep of `packages.yaml` finds 0 `version:` constraints). |
| Version pinning (`pin`, constraints) | 🟡 Minor | Code exists; **not exercised**. dcli's `Package` struct has only `name` + `package_type`. |
| Hybrid sync+update | 🟡 Minor | Topgrade pre-command depends on it. |
| Concurrent sync protection | 🟡 Minor | flock in `operations/sync-lock.sh`. |
| gum UI integration | 🟡 Minor | dcli has its own TUI; would orphan `core/gum-ui.sh` for this surface. |

---

## 4. Structural Blocker #1: Supply-Chain Tripwire

This is the deciding factor. The repo's tripwire is documented as the **most-defended** part of the package pipeline — `_guides/PACKAGE_SUPPLY_CHAIN_SECURITY.md` is the user runbook, `_research/archive/PACKAGE_SUPPLY_CHAIN_RESEARCH.md` is the threat model, `_plans/archive/PACKAGE_SUPPLY_CHAIN_HARDENING.md` is the P0–P2 roadmap (complete). The repo's "Security-first" constraint explicitly covers supply-chain, not just age encryption.

### 4.1 How the current tripwire works

From `private_dot_local/lib/scripts/system/package-manager/CLAUDE.md:201-252`:

- **Mechanism**: hash gate between `packages.yaml` and the AUR build.
- **Tier detection** (`_pkg_is_aur`): AUR-built iff NOT in any pacman sync repo (`pacman -Si` fails) but resolvable via `paru -Si --aur`. Official + chaotic-aur (signed binary sync repos) are never gated — only true AUR (PKGBUILD runs locally).
- **Hash**: `paru -G` clones AUR repo to tempdir; blob = `PKGBUILD` + every `*.install` hook (sorted), `sha256sum`'d. `.install` hooks run as **root** via `pacman -U`, must be covered. Compared to approved-hash DB at `~/.local/state/package-manager/pkgbuild-hashes.yaml`.
- **Unchanged** → builds unattended (`--noconfirm` kept).
- **New/changed** → **held**, diff shown, requires `package-manager approve <pkg>`.
- **Fail-CLOSED**: clone/fetch failure blocks the package (cannot verify).
- **Bootstrap-aware**: trust-on-first-use while DB unseeded; new AUR packages blocked on provisioned hosts.
- **Wired into** both pipelines: `cmd-update.sh` Phase 2 (scans `paru -Qua`); `batch-operations.sh` + `package-operations.sh`; `sync-pacman.sh` `_sync_handle_downgrade`; and the self-contained `run_onchange_before_sync_packages.sh.tmpl` (inline gate sharing same DB). The inline blob recipe must stay **byte-identical** to `_tripwire_fetch` or hashes diverge.

### 4.2 dcli has no equivalent — confirmed by source audit

| Property | Evidence |
|---|---|
| `paru -S` is opaque to dcli | `_ai/dcli/src/backend/pacman.rs:20-30` — `Command::new(&self.aur_helper).args(&["-S", "--needed", "--noconfirm"]).args(packages)` |
| Backend trait has no "fetch PKGBUILD" method | `_ai/dcli/src/backend/mod.rs:13-73` — only install/remove/query methods |
| No hash DB, no `approve` workflow | grep of `tripwire\|pkgbuild.*hash\|approve` over `_ai/dcli/src/` returns only unrelated matches (git credential approve, nix version strings) |
| Backend trait has no per-package pre-install gate | Only `install_packages_batch(&[&str])` — one paru invocation for whole batch |
| `dcli source` (makepkg path) is for **custom module-local PKGBUILDs**, not AUR | `_ai/dcli/src/source/builder.rs:57-72` — PKGBUILD comes from module dir, not AUR |
| Full-system-update is also opaque | `_ai/dcli/src/backend/pacman.rs:91-104` — `aur_helper -Syu [--devel]` |

**Conclusion**: the architecture mismatch is total. dcli's data flow has no place where the PKGBUILD is visible to the application before paru builds it. The tripwire cannot be expressed in dcli config.

### 4.3 Install-path anatomy of dcli

The AUR build pipeline in dcli, end-to-end:

```
dcli sync
  └─ commands::sync::run                                       # src/commands/sync.rs:1429
       ├─ run_pre_install_hooks()                              # per-module, runs scripts/<hook>.sh
       │    └─ execute_module_hook()                           # sync.rs:218 → Err aborts sync
       └─ install_module_packages()                            # sync.rs:230
            └─ backend.install_packages_batch(&pkg_refs)       # sync.rs:254 — single call
                 └─ PacmanBackend::install_packages_batch
                      └─ paru -S --needed --noconfirm pkg1 pkg2 ...   # pacman.rs:20
                           └─ (inside paru: clone AUR → makepkg → sudo pacman -U)
```

Critical observations:

| Fact | Evidence |
|---|---|
| Install is **one batch per module**, not per-package | `sync.rs:254` — single `install_packages_batch(&pkg_refs)` call |
| Pre-install hook **can abort** the sync (non-zero exit → `Err`) | `sync.rs:218-225` |
| Hook runs **once per module**, **before** the batch | `sync.rs:517-566` |
| Hook receives **no package-list argument** — must re-parse module YAML | `sync.rs:553-561` (only `module_name`, `hook_script` passed) |
| `dcli update` calls `aur_helper -Syu` | `pacman.rs:91` — same opaqueness for updates |

The current tripwire's core mechanism (`paru -G` clone-without-build → hash PKGBUILD+`.install` → compare to approved DB → drop held packages from batch → install remainder → re-run `paru -S` only on approved) **has no correspondence in dcli's data flow**.

---

## 5. Extension Surface Audit (Options Ranked)

Since no first-class extension mechanism exists in dcli, the only paths to admission are bypass or fork.

### Option F — `aur_helper` binary shim ⭐ lowest effort

dcli lets you set `aur_helper: /path/to/binary` in host config (`src/config/mod.rs:103-106`, resolved at `src/backend/mod.rs:81`).

**Approach**: ship a `dcli-tripwire-paru` wrapper (deployed via `private_dot_local/bin/executable_dcli-tripwire-paru`) that:
1. Intercepts `-S` / `-Syu` invocations from dcli.
2. For each package, runs `paru -G` to a tempdir, hashes PKGBUILD+`.install`, checks the approved-DB (reusing existing `~/.local/state/package-manager/pkgbuild-hashes.yaml`).
3. Splits the package list: approved → delegate to real `paru`; held → print diff + fail closed.
4. Passes through `-Si`, `-Slq`, `-Qua`, `-Gp`, etc. unchanged.
5. Calls `pacman -Si` itself to determine trust tier (dcli doesn't, so the shim must replicate `_pkg_is_aur`).

**Pros**:
- No Rust fork.
- Reuses existing hash DB and `package-manager approve` UI (the wrapper doesn't manage the DB — the existing tool does).
- Can ship as a chezmoi-managed wrapper, vetted and version-controlled.

**Cons / risks**:
- **Paru CLI surface is large**: `-S`, `-Syu`, `-Ss`, `-Si`, `-Sl`, `-Sw`, `-Su`, `-Sc`, `-Qua`, `-G`, `-Gp`, `-Gd`, combos with `-a`, `--needed`, `--noconfirm`, `--devel`, etc. The shim must handle every form dcli (and any manual user) invokes.
- **No trust-tier awareness in dcli**: the shim must itself call `pacman -Si` to detect tier — duplicating `_pkg_is_aur` logic.
- **Two sources of truth**: dcli's host config + chezmoi's `packages.yaml`. Still requires resolving the schema/location mismatch (§6).
- **`dcli update`**: calls `aur_helper -Syu` (`pacman.rs:91`) — shim must intercept full-system-update flows too, where the package list is implicit (everything paru wants to upgrade). The existing tool handles this via `cmd-update.sh` Phase 2 (scans `paru -Qua`); the shim would need the same logic.
- **Brittle to upstream paru changes**.
- **`dcli install <pkg>`**: bypasses the batch path, goes through `install_interactive` (`pacman.rs:32-42`, `aur_helper -S <pkg>` with no `--noconfirm`). The shim must intercept this too.

**Effort estimate**: 2-4 days for a robust shim + tests. Ongoing maintenance ~2h/quarter for paru CLI drift.

### Option G — Fork dcli: per-package pre-install gate

Add a new trait method + hook type to dcli's source:

```rust
// _ai/dcli/src/backend/mod.rs
pub trait PkgBackend {
    // ... existing ...
    fn pre_install_gate(&self, packages: &[String]) -> Result<Vec<String>> {
        Ok(packages.to_vec())  // default: pass-through
    }
}
```

Then in `sync.rs:254` and `pacman.rs:20`:

```rust
let approved = backend.pre_install_gate(&pkg_names)?;
let pkg_refs: Vec<&str> = approved.iter().map(|s| s.as_str()).collect();
backend.install_packages_batch(&pkg_refs)?
```

Plus a config field `pre_install_gate_script: ~/.local/bin/dcli-tripwire` that receives the package list on stdin and returns the approved subset.

**Pros**: clean, per-package granularity, lives in dcli's data model.

**Cons**:
- Fork maintenance: dcli is actively developed (recent chaotic-aur references, `dnf` backend added, Nix support). Rebases become real work.
- Upstream PR unlikely to land: it's a niche Arch-specific security concern, and the maintainer is explicit about AI assistance / beta status. README: *"⚠️ BETA SOFTWARE — Use at your own risk."*
- Requires Rust toolchain in CI.
- Defeats the "Rust-powered, zero-effort" appeal — you now own a fork.

**Effort estimate**: 1-2 weeks initial + ongoing rebase burden.

### Option H — Fork dcli: wrap `PacmanBackend`

Implement `TripwirePacmanBackend` that decorates `PacmanBackend`, fetches PKGBUILDs via `paru -Gddp` (source-only), hashes, filters, then delegates. Wire into `create_backend` when a config flag is set.

**Pros**: isolates changes to one new file + one match-arm in `create_backend`.

**Cons**: same fork-maintenance burden as G; no cleaner.

### Option I — External `dcli sync` precondition

Keep `package-manager approve` and its hash DB. Before running `dcli sync`, a wrapper runs `paru -Qua` + `paru -Gddp` over the host config's package list, blocks if any hash differs. **After** approval, `dcli sync` runs unattended.

**Pros**: zero dcli modification; uses only documented dcli commands.

**Cons**:
- **TOCTOU window**: between the wrapper's `paru -G` check and dcli's `paru -S`, upstream PKGBUILD could change. The existing tripwire has the same residual limit (`package-manager/CLAUDE.md:251-252`) so this is parity, not regression.
- Doesn't cover `dcli install <pkg>` or `dcli update` — would need to alias/wrap those too.
- Still requires resolving the chezmoi-schema mismatch.
- Adds a wrapper layer around every dcli invocation.

### Surfaces examined and dismissed

| Surface | Why not |
|---|---|
| `pre_install_hook` (per-module) | Granularity mismatch: blocks whole module batch; no pkg-list arg; can't surgically filter (sync.rs:517-566) |
| `post_install_hook` | Too late — build already happened |
| `dcli validate --check-packages` | Offline existence check, not content hash |
| Lua module scripting | Evaluates **package lists**, not build decisions; no PKGBUILD visibility |
| `dcli source` (makepkg) | For custom module-local PKGBUILDs, not AUR installs — different code path |
| `PkgBackend::install_interactive` (single-pkg path) | Used only by `dcli install <pkg>`, bypassed by `sync` batch path — would leave a hole |
| Module `conflicts` field | Static module-level mutual exclusion, not content gating |

---

## 6. Structural Blocker #2: Chezmoi Schema/Location Mismatch

Even if the tripwire integration is solved via Option F, the data-model incompatibility remains.

### 6.1 Source-of-truth differences

| Aspect | Current | dcli |
|---|---|---|
| Config location | `.chezmoidata/packages.yaml` (single file) | `~/.config/arch-config/{config.yaml,hosts/,modules/,scripts/}` (directory tree) |
| Config owner | chezmoi (version-controlled, templated) | dcli (version-controlled via `dcli repo`) |
| Module shape | `packages.modules.<name>.{enabled,packages,conflicts,post_install_hook}` flat in one file | One file/dir per module; host lists `enabled_modules: [...]` |
| GPU-driver dynamic select | `.chezmoi.yaml.tmpl` detects → rewrites module flags via yq in `run_onchange_before_sync_packages.sh.tmpl:19-34` | Lua `dcli.hardware.has_nvidia()` evaluated in-process (cleaner — net win for dcli) |
| Template variables (`.chezmoi.toml`) | Drives config (hostname, GPU detection, features) | Not accessible — dcli reads its own dir |
| Hash-triggered re-sync | `run_onchange_before_sync_packages.sh.tmpl:10` (`{{ .packages | toJson | sha256sum }}`) | None — dcli owns its own state |

### 6.2 Migration paths — both costly

**Path A: relocate config into dcli's directory**
- Move `.chezmoidata/packages.yaml` content into `~/.config/arch-config/` (templated via chezmoi to deploy there).
- Lose: `.chezmoi.toml`-driven template variables (hostname, GPU detection result) — must be re-implemented via dcli's Lua hardware API (doable but is a rewrite).
- Lose: `run_onchange` hash trigger — chezmoi no longer knows when to invoke dcli sync. Either invoke on every apply (slow) or skip automation.
- Re-implement: GPU-driver module toggle (becomes a Lua `hardware.lua` module — actually nicer).
- Re-implement: topgrade pre-command.
- Re-implement: all `menu-*` scripts' integration points.

**Path B: bridge `.chezmoidata/packages.yaml` → dcli directory format**
- A chezmoi script renders the YAML into dcli's directory tree on every apply.
- Two writeable copies → drift risk; dcli commands like `dcli install <pkg>` write to its own dir, not chezmoi's source.
- Re-sync direction ambiguous: who is authoritative when dcli modifies its config?
- The bridge itself becomes a substantial codebase.

Neither path offers net benefit over the status quo.

---

## 7. Distribution / Packaging Concerns

- **Beta status**: README warns *"⚠️ BETA SOFTWARE — Use at your own risk. I am not a full stack developer so I have utilized opensource AI models for help with areas I lack."* Single maintainer (theblackdon). Conflicts with this repo's security-first constraint and `_research/archive/PACKAGE_SUPPLY_CHAIN_RESEARCH.md` threat model.
- **AUR install irony**: `paru -S dcli-arch-git` would build dcli from source via the AUR — the exact unattended, untripwired path the existing tool exists to gate. Bootstrap would need to be `paru -S --needed --noconfirm dcli-arch-git` once, manually reviewed.
- **Network surface**: `dcli self-update` and `dcli module upload/download` reach out to gitlab.com / a community module repo. The current tool has no network surface beyond paru/pacman/flatpak themselves. This expands the attack surface.
- **Vendored source**: `_ai/dcli/` is git-subtree'd for read-only reference. Updating it requires `git subtree pull` per `_guides/VENDORED_SUBTREES.md`. If we ever shipped a fork, we'd lose the clean update path.

---

## 8. Selective Feature Adoption (Option A — Recommended)

Instead of replacing `package-manager`, port dcli's good ideas incrementally:

| dcli feature | How to port |
|---|---|
| **JSON output** (`--json`) | Add `--json` flag to existing `package-manager status/validate/outdated` commands; emit JSON via yq's `--to-json` or `jq -n` |
| **Lua-style hardware detection** | Already have `.chezmoi.yaml.tmpl` + `nvidiaDriverType`; extend with more detection (CPU vendor, chassis type) exposed as chezmoi data for templates |
| **fzf TUI for search** | Add `package-manager search` using fzf directly (paru + fzf pipeline); gum-ui already supports spinners |
| **Declarative services in same config** | Move `.chezmoidata/services.yaml` into `packages.yaml` schema; extend `package-manager sync` to manage services |
| **Default apps (XDG MIME)** | New `package-manager defaults` subcommand; backed by `xdg-mime` + `~/.config/mimeapps.list` template |
| **Sequential module processing** | Add `module_processing: sequential` to `packages.yaml`; orchestrator runs modules one-at-a-time with pre/post hooks |

Each of these is independently valuable, low-risk, and preserves the tripwire + chezmoi integration. Cumulative effort: less than a migration, with no security regression.

---

## 9. Adjacent Adoption (Option D — Fallback)

If a clean dcli surface is desired, restrict it to areas `package-manager` doesn't cover:

- **XDG MIME defaults** — adopt `dcli merge --defaults` for bootstrapping `mimeapps.list`, run once. No ongoing dcli dependency.
- **Service discovery** — adopt `dcli merge --services` to capture current state into `.chezmoidata/services.yaml`. Again, one-shot.

Leave package install + tripwire on the existing `package-manager`. This gets the bootstrap value of dcli's introspection without adopting it as a runtime dependency.

---

## 10. Verdict

| Question | Answer |
|---|---|
| Should we replace `package-manager` with `dcli`? | **No.** |
| Why? | (a) No supply-chain tripwire equivalent and no clean insertion point without a binary shim or Rust fork. (b) Chezmoi-schema mismatch makes the config migration a net loss. |
| What should we do instead? | Selectively adopt dcli's good ideas (JSON output, hardware detection, fzf search, services/MIME defaults) into the existing tool. |
| Is any further exploration warranted? | Only Option F (paru shim) as a side experiment, if the dcli UX is judged worth the integration cost. |
| What would change the verdict? | Either (a) dcli adds a per-package `pre_install_gate` upstream trait (currently absent), or (b) the tripwire requirement is downgraded (currently a written policy in `_guides/PACKAGE_SUPPLY_CHAIN_SECURITY.md`). Neither is likely. |

---

## 11. References

### Internal

- `private_dot_local/lib/scripts/system/package-manager/CLAUDE.md` — current tool architecture, tripwire mechanism
- `private_dot_local/lib/scripts/system/CLAUDE.md` — package security policy, trust tiers
- `.claude/rules/chezmoi-data.md` — `packages.yaml` schema
- `.claude/rules/chezmoi-scripts.md` — `run_onchange` lifecycle, hash triggers
- `.chezmoiscripts/run_onchange_before_sync_packages.sh.tmpl` — inline tripwire implementation (lines 123-227)
- `.chezmoiscripts/run_once_before_002_install_package_manager.sh.tmpl` — bootstrap (paru, chaotic-aur, yq, gum)
- `.chezmoidata/packages.yaml` — current package config (383 lines)
- `_research/archive/PACKAGE_SUPPLY_CHAIN_RESEARCH.md` — threat model
- `_plans/archive/PACKAGE_SUPPLY_CHAIN_HARDENING.md` — tripwire roadmap (P0–P2 complete)
- `_guides/PACKAGE_SUPPLY_CHAIN_SECURITY.md` — user runbook
- `_guides/VENDORED_SUBTREES.md` — git subtree update procedure

### Vendored upstream (read-only)

- `_ai/dcli/README.md` — dcli user docs (1504 lines)
- `_ai/dcli/Cargo.toml` — dependency manifest
- `_ai/dcli/src/main.rs` — CLI subcommand definitions (771 lines)
- `_ai/dcli/src/backend/pacman.rs` — Arch install path (251 lines) — **opaque `paru -S`, no PKGBUILD visibility**
- `_ai/dcli/src/backend/mod.rs` — `PkgBackend` trait (87 lines) — **no gate method**
- `_ai/dcli/src/commands/sync.rs` — install orchestration (2838 lines) — **batch install at line 254, hooks abort at 218-225**
- `_ai/dcli/src/source/builder.rs` — makepkg path (170 lines) — **for module-local PKGBUILDs only, not AUR**
- `_ai/dcli/src/package/mod.rs` — `Package` struct (300 lines) — **no version field**
- `_ai/dcli/src/config/mod.rs` — config schema (`aur_helper` at lines 103-106)

### Upstream

- dcli repo: `gitlab.com/theblackdon/dcli`
- AUR package: `aur.archlinux.org/packages/dcli-arch-git`
- License: 0BSD
