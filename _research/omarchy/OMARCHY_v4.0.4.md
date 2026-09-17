# Omarchy v4.0.4 — Release Research

**Date researched**: 2026-09-17
**Previous version**: v4.0.3
**Commits**: 6
**Source**: Commit log fallback

---

## Summary

Single-theme release: Omarchy replaces the stock Arch `linux` kernel with its own `linux-omarchy`
kernel package on every x86_64 machine except T2 Macs, and retires the Dell XPS Panther Lake
(`linux-ptl`) special case. A second, follow-up change makes "matching kernel headers for the
running kernel" a base-system guarantee, so individual DKMS hardware installers no longer install
`linux-headers` themselves. Two migrations ship (`1789325478`, `1789444024`) plus three new shell
tests and a new acceptance check.

## Breaking Changes

- **Stock `linux` kernel is no longer the Omarchy kernel**: `linux` and `linux-headers` are removed
  from `install/omarchy-other.packages` and replaced with `linux-omarchy` / `linux-omarchy-headers`.
  Migration `1789325478.sh` installs the new kernel and rewrites Limine `BOOT_ORDER` so
  `linux-omarchy` boots first. The previously running kernel is deliberately left installed as a
  fallback, so the updater cannot detect a kernel replacement and the migration explicitly sets
  `reboot-required`. A reboot is required after this release; systems that do not get a Limine
  entry for `linux-omarchy` leave the migration pending and must rerun `omarchy-migrate`.
- **`linux-ptl` kernel support removed**: `install/hardware/intel/ptl-kernel.sh` is deleted and its
  `run_logged` call removed from `install/hardware/all.sh`. The `zz-dell-xps-panther-lake.conf`
  Limine drop-in it wrote is no longer produced. Dell XPS Panther Lake machines move to
  `linux-omarchy` like everything else.
- **DKMS installers no longer install kernel headers**: any downstream script that relied on an
  Omarchy hardware installer pulling in `linux-headers` must now rely on the base system providing
  `<kernel>-headers`.

## Features

- **`linux-omarchy` kernel migration**: New migration installs `linux-omarchy` +
  `linux-omarchy-headers`, deletes every existing `BOOT_ORDER=` line from `/etc/default/limine`,
  appends `BOOT_ORDER="linux-omarchy, linux-omarchy-*, *, *fallback, Snapshots"`, runs
  `sudo limine-mkinitcpio linux-omarchy`, then verifies the kernel actually appears in
  `limine-entry-tool --tree` before writing its completion marker. Omarchy path:
  `migrations/1789325478.sh`
- **T2 Mac exemption**: The migration exits early when `uname -m` is not `x86_64`, when
  `omarchy-pkg-present linux-t2` succeeds, or when the running kernel release matches `*-t2*`.
  T2 Macs keep `linux-t2`. Omarchy path: `migrations/1789325478.sh`
- **Header repair migration**: Installs `<kernel>-headers` for whichever of `linux-omarchy` /
  `linux-t2` is present, covering fresh ISO installs that mark earlier migrations complete and so
  never run the kernel migration. Idempotent; propagates install failure so the migration stays
  pending. Omarchy path: `migrations/1789444024.sh`
- **Kernel-header acceptance check**: New `verify_kernel_headers` in the acceptance suite asserts
  `/usr/lib/modules/$(uname -r)/pkgbase` equals the supported kernel, that `<kernel>-headers` is
  installed, and that `.../build/include/config/kernel.release` matches the running release.
  Omarchy path: `test/acceptance.d/system-test.sh`

## Improvements

- **Machine-wide migration marker**: Migrations run per user, but the kernel rebuild is machine-wide.
  A marker file at `/var/lib/omarchy/migrations/1789325478` (overridable via
  `OMARCHY_KERNEL_REBUILD_MARKER`) makes the expensive part run once per machine.
- **Explicit-kernel-first boot order**: `BOOT_ORDER` lists `linux-omarchy` before
  `linux-omarchy-*` because the glob only matches variant kernels, not the base package.
- **New shell tests**: `omarchy-kernel-migration-test.sh` (248 lines, stubs `pacman`, `sudo`,
  `limine-mkinitcpio`, `limine-entry-tool`, `omarchy-state`), `kernel-headers-migration-test.sh`,
  and `limine-defaults-test.sh` assertions on the packaged `BOOT_ORDER` string.
  The older `test/shell.d/kernel-headers-test.sh` was removed.
- **Agent skill documentation**: `agents/skills/install-scripts.md` gains the rule that the base
  install supplies matching kernel headers before hardware setup, so DKMS installers should install
  only their driver packages.

## Configuration Changes

- **Limine default boot order**: `BOOT_ORDER="*, *fallback, Snapshots"` →
  `BOOT_ORDER="linux-t2, linux-omarchy, linux-omarchy-*, *, *fallback, Snapshots"`.
  Omarchy path: `etc/limine-entry-tool.d/omarchy-defaults.conf`
- **Migration-time `/etc/default/limine` rewrite**: The migration writes `BOOT_ORDER` into
  `/etc/default/limine` (which outranks every drop-in, including `.pacnew`-shadowed customized
  package files), deleting prior `BOOT_ORDER=` lines while preserving unrelated settings such as
  the root filesystem kernel cmdline. Overridable in tests via `OMARCHY_KERNEL_LIMINE_CONF`.
  Omarchy path: `migrations/1789325478.sh`
- **NVIDIA installer header detection removed**: The `pacman -Qqs '^linux(-zen|-lts|-hardened|-t2|-ptl)?$'`
  probe plus `omarchy-pkg-add "$KERNEL_PACKAGE-headers"` was deleted; the script now only selects
  the NVIDIA driver package set. Omarchy path: `install/hardware/nvidia.sh`
- **`linux-headers` dropped from DKMS installers**: `omarchy-pkg-add linux-headers <driver>` →
  `omarchy-pkg-add <driver>`. Omarchy paths: `bin/omarchy-install-gaming-xbox-controllers`,
  `install/hardware/fix-bcm43xx.sh`, `install/hardware/fix-tuxedo-backlight.sh`,
  `install/hardware/fix-yt6801-ethernet-adapter.sh`

## Package Changes

| Action | Package | Purpose |
|--------|---------|---------|
| Added | `linux-omarchy` | Omarchy's own kernel, now the default on x86_64 non-T2 systems |
| Added | `linux-omarchy-headers` | Matching headers, now a base-system guarantee for DKMS builds |
| Removed | `linux` | Replaced by `linux-omarchy` in `install/omarchy-other.packages` (left installed on migrated machines as a boot fallback) |
| Removed | `linux-headers` | Superseded by `linux-omarchy-headers`; no longer pulled in per DKMS installer |
| Removed | `linux-ptl` | Panther Lake kernel special case retired |
| Removed | `linux-ptl-headers` | Panther Lake kernel special case retired |
