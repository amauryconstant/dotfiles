# Package Supply-Chain Security

User runbook for the package pipeline's trust model, review gates, and incident response.

- **Mechanism**: `private_dot_local/lib/scripts/system/package-manager/CLAUDE.md` → "Supply-Chain Tripwire"
- **Policy summary**: `private_dot_local/lib/scripts/system/CLAUDE.md` → "Package Security Policy"
- **Threat model**: `_research/archive/PACKAGE_SUPPLY_CHAIN_RESEARCH.md`
- **Roadmap (P0–P2 complete)**: `_plans/archive/PACKAGE_SUPPLY_CHAIN_HARDENING.md`

## Why this exists

The package pipeline is fully unattended (`--noconfirm`). A hijacked AUR/`-git` PKGBUILD would
otherwise build and run arbitrary code — as the build user, with sudo available — on the next
`sync`/`update`, with no diff shown. This happened in the wild: **Atomic Arch** (June 2026, two
waves, >1,500 AUR packages) adopted orphaned packages and rewrote PKGBUILDs to pull credential-
stealing npm/bun deps + an eBPF rootkit. Official `[core]/[extra]/[multilib]` were unaffected.

## Trust tiers

| Tier | Example | Why trusted | What gates it |
|------|---------|-------------|---------------|
| Official | `firefox`, `bluetui` | maintainer-reviewed + signed | nothing — installs via `pacman -S` |
| chaotic-aur | `wayfreeze-git`, `gpu-screen-recorder-git` | third-party **signed prebuilt binaries** (not built here) | nothing (treated as official) — but the known third-party trust set, watch for chaotic-aur compromise news |
| true AUR | `voxtype-bin`, `kanata-bin` | nothing — it's an unvetted build script run locally | **tripwire** (PKGBUILD/`​.install` hash gate) |
| Flatpak | `com.slack.Slack` | sandboxed | tightened permission overrides; prefer *verified* apps |

Tiers are derived at runtime (`_pkg_is_aur`: in a pacman sync repo → trusted; AUR-only → gated).
No hand-maintained tags.

## Reviewing an AUR build (the tripwire)

When you `package-manager sync`/`update` and an AUR package's build files changed (or a new AUR
package appears on a seeded host), the build is **held** and a diff is printed:

1. Read the diff. Look for added `source=` URLs, `npm`/`bun`/`curl`/`wget` in `prepare()/build()`,
   new dependencies, or `.install` hook changes (those run as **root**).
2. If legitimate (real upstream update): `package-manager approve <pkg>` then re-run sync.
3. If suspicious: do **not** approve. Investigate the package's AUR page / maintainer history first.

Bootstrap note: on a fresh machine (unseeded hash DB) AUR packages install trust-on-first-use so
provisioning isn't bricked. Run `package-manager approve --seed` **once after deploy** to record
current build files and switch to enforcing mode. Re-seed if the hash recipe (`_tripwire_fetch`)
ever changes.

## Signature policy

`run_once_before_002` idempotently enforces `SigLevel = Required DatabaseOptional` in
`/etc/pacman.conf` `[options]`. Stricter `LocalFileSigLevel`/`DatabaseRequired` is deliberately
avoided — it breaks the chaotic-aur `pacman -U` bootstrap (key not yet trusted) and unsigned
official DBs.

## `-git` pinning

`-git` packages build from upstream HEAD — an unpinned hole. There are currently **none** built
locally (both `-git` packages are chaotic-aur signed binaries). If a true local-build `-git`
package is ever added, pin it: vendor a reviewed `#commit=<sha>` in the PKGBUILD.

## Flatpak hardening

Broad sandbox permissions are tightened **declaratively** via chezmoi-managed override files at
`private_dot_local/share/flatpak/overrides/<app-id>` (these are authoritative):

| App | Tightened from | To |
|-----|----------------|-----|
| `org.qbittorrent.qBittorrent` | `filesystem=host` | `xdg-download` |
| `com.github.xournalpp.xournalpp` | `filesystem=host` | `xdg-documents` + `xdg-download` |
| `com.slack.Slack` | `devices=all` | none (camera via portal) |
| `com.github.IsmaelMartinez.teams_for_linux` | `devices=all` + `filesystem=home` | `xdg-download` |

Workflow to add/adjust an override:

```sh
flatpak override --user --nofilesystem=host --filesystem=xdg-download <app-id>
flatpak info --show-permissions <app-id>   # verify
chezmoi add ~/.local/share/flatpak/overrides/<app-id>   # capture declaratively
```

- **Test after tightening.** Dropping `devices=all` can break webcam in video calls if the client
  doesn't use the pipewire camera portal — start a call and confirm. If broken, revert with
  `flatpak override --user --reset <app-id>` and document it as an accepted exception.
- **Flatseal** (`com.github.tchx84.Flatseal`) is for inspecting/experimenting. It writes the same
  override files — re-capture any change with `chezmoi add`.
- Prefer **verified** Flathub apps (the blue checkmark on the app's flathub.org page = publisher-
  confirmed). Keep Flatpak ≥ 1.16.4 (sandbox-escape CVEs).

## Incident response (IoC sweep)

Run if AUR was updated during a known incident window (e.g. Atomic Arch: 2026-06-09 to 06-12).
Cross-check the date window in `/var/log/pacman.log` first — if no AUR builds ran, exposure path
was never taken.

```sh
# eBPF rootkit pinned maps
ls /sys/fs/bpf/hidden_* 2>/dev/null && echo "INFECTED"

# Malicious npm/bun packages (wave 1 + wave 2)
find ~/.npm ~/.cache/npm ~/.bun ~/.cache/bun /usr/lib/node_modules \
  -iname '*atomic-lockfile*' -o -iname '*js-digest*' -o -iname '*lockfile-js*' 2>/dev/null

# Persistence: wave-2 Restart=always units, CHAOS RAT artifact
grep -rl 'Restart=always' ~/.config/systemd/user/ 2>/dev/null
ls /tmp/systemd-initd 2>/dev/null && echo "CHAOS RAT artifact"
```

If **anything** is found, removal alone is insufficient:

1. Rotate all credentials — SSH keys (`rotate-ssh-key`), API tokens (`rotate-key api`),
   GitHub/npm/Vault tokens, browser sessions.
2. Reinstall from trusted media (the rootkit/infostealer survives package removal).

This host last swept **clean** on 2026-06-18 (no AUR builds in the incident window).
