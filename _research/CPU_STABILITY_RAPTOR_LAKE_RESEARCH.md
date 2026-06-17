# CPU Stability — Raptor Lake (i9-13900K) Machine Check Errors

**Created**: 2026-06-17
**Host**: amaury-dktp
**CPU**: 13th Gen Intel Core i9-13900K (Raptor Lake, `PROCESSOR 0:b0671`)
**Status**: ⚠️ Active hardware instability — suspected silicon degradation; RMA candidate

---

## Summary

While building `voxtype` from source (AUR), `rustc`/LLVM crashed with **SIGFPE** mid-compile. Investigation showed this was **not** a packaging bug but a **CPU hardware fault**: the kernel is logging recurring **Machine Check Exceptions (MCE)** on specific cores, and the compiler crash was the same fault manifesting fatally under heavy parallel AVX load.

This is the well-documented **Intel Raptor Lake (13th/14th-gen) instability/degradation defect**. Up-to-date mitigation microcode is already applied yet errors persist → the silicon has likely already degraded.

**Immediate workaround**: avoid source builds; use prebuilt binary packages (e.g. `voxtype-bin`, not `voxtype`). Source compiles (rust/LLVM/kernel) are the most likely to crash *and* to silently miscompile.

---

## Evidence

### The compiler crash (trigger)

```
error: could not compile `wayland-protocols` (lib)
  process didn't exit successfully: `rustc ... ` (signal: 8, SIGFPE: erroneous arithmetic operation)
```

Correlated kernel trap at the same time:

```
traps: opt cgu.5[84476] trap divide error ip:7f6546f0a710 ... in libLLVM.so.22.1
```

A compiler dying with SIGFPE / divide-error is a classic hardware-instability symptom, not a code bug.

### Machine Check Exceptions (the underlying fault)

Recurring across **multiple boots**, always **Bank 0**, concentrated on **CPUs 8 and 10** (APIC 20/28 — two P-core threads):

```
mce: [Hardware Error]: CPU 10: Machine Check: 0 Bank 0: 8000004000050005
mce: [Hardware Error]: CPU  8: Machine Check: 0 Bank 0: 8000004000050005
mce: [Hardware Error]: CPU 10: Machine Check: 0 Bank 0: 8000004000040005
mce: [Hardware Error]: PROCESSOR 0:b0671 ... microcode 133
```

Status word decode (`0x8000004000050005`):
- bit 63 `VAL` = 1 (valid record)
- bit 61 `UC` = 0 → these logged instances were **corrected** (reported via CMCI)
- Bank 0 = a core-internal unit; MCACOD `0x0005` = internal/parity-class error

The logged MCEs are corrected, but the **uncorrected** version of the same fault is what crashed LLVM. Corrected internal errors recurring on the *same* cores across reboots = degraded-core pattern, not random/cosmic-ray noise.

### Microcode

`microcode : 0x133` — newer than Intel's 0x12B mitigation (Sept 2024). **Mitigation present, errors persist** → microcode prevents further damage but does not reverse degradation that already occurred.

---

## Diagnosis

| Signal | Reading |
|--------|---------|
| Same cores (8/10) faulting across boots | Localized silicon degradation, not transient |
| Bank 0 internal/parity errors | Core execution unit affected |
| Fatal SIGFPE under AVX-heavy compile | Fault becomes uncorrectable under load |
| Recent microcode (0x133), still failing | Mitigation applied too late / damage done |
| i9-13900K | In the affected Raptor Lake range |

**Conclusion**: high-confidence Raptor Lake instability with probable permanent degradation.

---

## Action plan

1. **Monitor/decode** — install `rasdaemon` (modern replacement for mcelog):
   ```
   sudo pacman -S rasdaemon
   sudo systemctl enable --now rasdaemon
   sudo ras-mc-ctl --errors      # decoded error list
   sudo ras-mc-ctl --summary     # running tally (evidence for RMA)
   ```
2. **BIOS** — update to latest; load **"Intel Default Settings" / Intel Baseline** profile (caps PL1/PL2, IccMax, voltage). Disable any OC / "enhanced multicore" / MCE-Enhancement profile.
3. **Re-test at stock** — `y-cruncher` or `stress-ng --cpu 0 --timeout 5m` while watching `sudo ras-mc-ctl --errors`; verify cooling/temps (`watch -n1 sensors`).
4. **RMA if errors persist at Intel defaults** — Intel extended the 13th/14th-gen warranty to **5 years** specifically for this defect. Keep `dmesg` / `journalctl -k` MCE logs as evidence.

---

## Impact on this dotfiles repo

- **Prefer binary AUR packages over source builds** where a `-bin` exists (already the policy: `voxtype-bin`, `hyprdynamicmonitors-bin`, etc.). Source builds risk crashes and silent miscompilation until the CPU is resolved.
- Optional hardening: add `rasdaemon` to `.chezmoidata/packages.yaml` + enable its service in `.chezmoidata/services.yaml` so MCE monitoring is permanent. (Not yet applied — pending decision.)
- Unrelated to the concurrent voxtype 0.7.x work; that repaired the daemon/config and is independent of this hardware issue.

---

## References

- Intel Raptor Lake instability advisory / extended warranty (13th/14th-gen, Vmin Shift)
- `rasdaemon`: https://github.com/mchehab/rasdaemon
- Linux MCE decode: `ras-mc-ctl`, `/sys/devices/system/machinecheck/`
