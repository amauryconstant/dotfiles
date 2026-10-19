# Package-Manager - Claude Code Reference

**Location**: `private_dot_local/lib/scripts/system/package-manager/`
**Parent**: `../CLAUDE.md` (system scripts) · **Root**: `/CLAUDE.md` (core standards)

**CRITICAL**: Be concise. Sacrifice grammar for concision and token-efficiency.

## Quick Reference

- **Purpose**: install/remove the package set chezmoi declares; tripwire-gate AUR builds
- **Main consumer**: `run_onchange_before_sync_packages.sh.tmpl` — runs the tool **from the chezmoi source tree** (it runs before file application, so `~/.local/lib` may not exist yet)
- **Commands**: `sync <declared-file> [--dry-run]` · `update [--no-flatpak]` · `approve <pkg>…|--all|--seed`

```
package-manager/
├── executable_package-manager   # init (STATE_DIR, UI_LIB) + dispatch
└── lib/  sync.sh  update.sh  approve.sh  tripwire.sh
```

## sync

Input: a file of package names, one per line (`flatpak:` prefix for Flatpak). chezmoi renders it
from `packages.yaml` — enabled modules flattened, **NVIDIA module chosen by `.nvidiaDriverType`**,
not by the `enabled` flags of the two `graphics_drivers_*` modules. The tool knows nothing about
modules, `enabled` or GPUs.

Order: classify (`pacman -Si` hit = official/chaotic → pacman; else AUR → paru) → tripwire check
(any block → exit 1, nothing changes) → compute removals → mark retired `--asdeps` → install →
mark declared `--asexplicit` → seed tripwire if bootstrap → orphan pass (`paru -Qtdq` → `-Rns`) →
Flatpak install/uninstall → write state → fire `package-sync` hook.

**Removal = applied-set diff.** `~/.local/state/package-manager/applied.txt` holds *declared ∩
installed* after the last sync. Removals = `(applied − declared) ∩ installed`. So retiring a
package is just deleting its line from `packages.yaml`; packages the tool never declared (archinstall
base, hand installs) are never touched.

- Retired packages are marked `--asdeps` and left to the orphan pass, so one that is still a
  dependency (kitty's terminfo) stays instead of aborting the transaction.
- Removal runs **before** install so a driver swap's conflicting packages are gone first.
- **No `applied.txt`** (first sync on a host) → record only, remove nothing. Packages retired
  before that point are a one-time manual `paru -Rns`.
- Guard: more than 10 removals → refuse unless `PACKAGE_MANAGER_ALLOW_REMOVE=1`. Empty pacman
  list → refuse (a broken render must never mean "remove everything").
- State is written from what is *actually installed*, so a tripwire-blocked or failed package is
  not recorded as applied.

**Test safely**: `PACKAGE_MANAGER_STATE_DIR=<scratch> UI_LIB=<gum-ui.sh> bash executable_package-manager sync <file> --dry-run`
prints install/remove sets without sudo. Seed a fake `applied.txt` to see the diff; copy
`pkgbuild-hashes.yaml` + `pkgbuilds/` into the scratch dir to test an established tripwire.

**Hash trigger**: the template hashes `.packages` plus the dispatcher, `sync.sh` and `tripwire.sh`,
so tool edits re-run the sync. New lib file the sync depends on → add its hash line too.

## update

Topgrade pre-command. **No sync, no removal** (the declared set lives only in chezmoi). Scans
`paru -Qua` through the tripwire; any held AUR package → official `pacman -Syu` only. Then
`flatpak update --user`.

## State (`~/.local/state/package-manager/`)

| File | Purpose |
|------|---------|
| `applied.txt` | declared ∩ installed after the last sync (removal baseline) |
| `pkgbuild-hashes.yaml` | tripwire approved-hash DB |
| `pkgbuilds/<name>.snapshot` | approved PKGBUILD + `.install` blob, for diffs |

Stale from the old tool, safe to delete: `locked-versions.yaml`, `package-state.yaml`, `backups/`.

## Supply-chain tripwire

**Why**: the pipeline is unattended (`--noconfirm`); a hijacked AUR PKGBUILD would run arbitrary
code on the next sync/update. Threat model: `_research/archive/PACKAGE_SUPPLY_CHAIN_RESEARCH.md`.

- **Tiers**: official + chaotic-aur (signed binary sync repos) are never gated; only true AUR
  (not in any sync repo) is. `wayfreeze-git`, `gpu-screen-recorder-git` are chaotic prebuilt → trusted.
- **Hash** (`_tripwire_fetch`): `paru -G` clone; blob = `PKGBUILD` + sorted `*.install` (those run as
  root via `pacman -U`), `sha256sum`'d against `pkgbuild-hashes.yaml`. `paru -G` clones into the
  *pkgbase* dir (≠ pkgname for split packages) — the code takes the sole subdir. Changing the
  recipe stales every hash → `package-manager approve --seed`.
- **Fail-closed**: a failed fetch blocks the package.
- **Bootstrap-aware** (`_tripwire_is_bootstrap`): DB absent/empty → trust-on-first-use, then
  `sync` seeds it after the first successful install. Seeded DB → an AUR package not in it is NEW
  and **blocked** until `package-manager approve <pkg>`. Capture bootstrap once, before any install.
- **Review**: read the printed diff, `approve` only if legitimate. `--noconfirm` never bypasses the gate.
- **SigLevel**: `Required DatabaseOptional`, enforced by `run_once_before_002`. Don't add
  `LocalFileSigLevel`/`DatabaseRequired` — breaks the chaotic-aur bootstrap.
- **`-git` blind spot**: a locally-built `-git` package's PKGBUILD hash is stable while HEAD moves.
  None exist; if one is added, vendor a reviewed `#commit=`.
- **Residual**: TOCTOU — `paru -S` re-fetches `source=()` at build time.

Runbook: `_guides/PACKAGE_SUPPLY_CHAIN_SECURITY.md`. Trust-tier policy: `../CLAUDE.md`.

## Patterns

- `yq` always via `env()` (`NAME="$x" yq '.a[env(NAME)]'`) — never interpolate (injection vector).
- Never wrap `paru`/`pacman`/`flatpak` in `ui_spin` (breaks sudo/TTY prompts).
- Without a TTY gum-ui falls back to plain output, so the chezmoi run is safe unattended.
