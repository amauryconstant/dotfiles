# Package Supply-Chain Security Research

**Date:** 2026-06-15
**Scope:** Arch/AUR supply-chain threat landscape evaluated against this repo's package install/update pipeline.
**Method:** Parallel research — external incident review (web) + internal read-only audit of the package-manager pipeline. All internal claims verified against source (`file:line` cited).

---

## 1. Executive Summary

Our package pipeline is **convenience-optimized and fully unattended end-to-end**. Every `paru`
invocation passes `--noconfirm`, which means **PKGBUILDs are built and executed without ever being
shown or diffed** — on first install *and* on every update. There is no AUR allowlist, no
commit/checksum pinning, no managed signature policy, and no mechanism to detect a malicious
PKGBUILD change.

This matters because the exact attack class that has hit Arch hardest in the last year —
**hijacked/adopted AUR packages shipping rootkits and infostealers** — executes its payload *at
build time, as the building user, with sudo escalation available*. Our pipeline would build and
install such a package silently on the next `sync`/`update`. **We carry ~24 AUR / `-git` /
Chaotic-AUR packages**, each an independent trust root with zero review gate.

**Risk rating: HIGH likelihood-of-exposure-path, HIGH impact, currently MITIGATED only by rollback
(Timeshift), not by prevention.**

---

## 2. Threat Landscape (confirmed incidents)

| Incident | Date | Vector | Payload | Relevance to us |
|---|---|---|---|---|
| **"Atomic Arch"** mass AUR hijack (**2 waves**) | Jun 2026 | Attackers **adopted orphaned AUR packages** and rewrote PKGBUILDs to pull malicious npm deps (`atomic-lockfile`, `js-digest`, `lockfile-js`) executing via npm `preinstall` hooks. **Wave 1 (Jun 11): 408 pkgs** (Rust ELF `6144D4…`). **Wave 2 (Jun 12): total >1,500 pkgs** — new `js-digest` **bun** variant (ELF `7883BD…`). Arch **froze AUR signups Jun 15**. | Infostealer (SSH keys, GitHub/npm/Vault/Discord/Slack/M365 tokens, browser cookies) **+ root eBPF rootkit** hiding PIDs/files (pinned BPF maps `/sys/fs/bpf/hidden_*`), `temp.sh`/Tor C2 exfil, wave-2 `Restart=always` systemd persistence. Removal insufficient — required credential rotation + reinstall. | **Headline risk.** Orphan adoption silently flips a trusted package name to malicious; our unattended `paru -Syu --noconfirm` would build it. **Now mitigated**: payload rides the *rewritten PKGBUILD*, which our P1.2 tripwire hashes → blocks changed/new AUR build files + shows diff. Official `[core]/[extra]/[multilib]` NOT affected. |
| **CHAOS RAT** fake browsers | Jul 2025 | New typosquat AUR pkgs (`firefox-patch-bin`, `librewolf-fix-bin`, `zen-browser-patched-bin`); PKGBUILD `source=` pointed at attacker GitHub, ran at build. ~48h exposure. | Linux RAT — reverse shell, full remote control. Dropped `systemd-initd` in `/tmp`. C2 `130.162.225.47:8080`. | Shows the `-bin`/patched-name lure. We install several `-bin` packages by bare name. |
| **acroread / xeactor** | 2018 | Orphan adoption → PKGBUILD `curl`-runs remote script. | Recon + systemd persistence (~360s timer). | Establishes the orphan-adoption pattern reused in 2026. |
| **XZ Utils backdoor** (CVE-2024-3094, CVSS 10) | Mar 2024 | 2-year maintainer social-engineering ("Jia Tan") → backdoor in `liblzma` 5.6.0/5.6.1 in **official repos**. | Pre-auth sshd RCE. | Arch shipped it but wasn't exploitable (Arch sshd doesn't link liblzma). Proves even **official, signed repos** aren't immune to *upstream* compromise. |
| **Flatpak sandbox escapes** (CVE-2024-32462, CVE-2024-42472, CVE-2025-4870) | 2024–2025 | Portal/sandbox-escape flaws. | Host file access / code outside sandbox. Fixed in Flatpak ≥ 1.16.4. | We use Flathub (user scope). Sandbox is the *only* defense layer; keep it patched. No confirmed Flathub malware-distribution campaign found. |

**Structural root cause — the AUR trust model:** AUR is unvetted, user-submitted **build scripts**.
`prepare()/build()/package()` (and `pkgver()`) run arbitrary code as the build user; `.install`
hooks run **as root** during `pacman -U`. No review, no signing, instant orphan adoption. Every
incident above is a direct consequence. AUR helpers (paru/yay) amplify this by automating
clone→build→install and hiding diffs unless configured otherwise.

**Confidence:** High (multi-source + official advisories) for all five incidents. The npm package
"shai-hulud" referenced during scoping could **not** be confirmed and is excluded. "Atomic Arch" is
**June 2026** per primary sources (Sonatype, archlinux.org); ignore derivative "December 2025"
framing.

### Sources
- CHAOS RAT: BleepingComputer "Arch Linux pulls AUR packages that installed CHAOS RAT malware";
  Arch `aur-general` advisory (Q. Michaud, 2025-07-18).
- Atomic Arch: Sonatype "Atomic Arch npm campaign" (Sonatype-2026-003775, CVSS 8.7);
  BleepingComputer "Over 400 Arch Linux packages compromised…"; archlinux.org news
  "Active AUR malicious packages incident" (2026-06-12); The Hacker News; StepSecurity; Phoronix.
- Atomic Arch (waves + signup freeze, added 2026-06-18): SecurityWeek "Atomic Arch Supply Chain
  Attack Hits 1,500 AUR Packages"; The Register "Arch Linux locks down AUR signups amid wave of
  malicious commits" (2026-06-15); StepSecurity "400+ AUR Packages Hijacked";
  community IoC tooling `github.com/lenucksi/aur-malware-check` (wave-2 `js-digest` bun variant,
  `Restart=always` persistence, `temp.sh`/Tor exfil, ELF `7883BD…`).
- acroread/xeactor: BleepingComputer (2018); LWN art. 759461.
- XZ: Datadog Security Labs; Qualys (CVE-2024-3094).
- Flatpak: stack.watch Flatpak CVEs; Flatpak 1.16.4 release notes.

---

## 3. Current Posture (internal audit)

**Install sources:** official Arch `[core]/[extra]/[multilib]`, **AUR (paru)**, **Chaotic-AUR**
(third-party prebuilt binaries), **Flathub** (user scope).

**Higher-risk packages in `.chezmoidata/packages.yaml`** (~24, bare names, no version pins):
`ventoy-bin`, `timeshift-systemd-timer`, `wayfreeze-git`, `gpu-screen-recorder-git` (chaotic),
`hyprdynamicmonitors-bin`, `hyprwhenthen-bin`, `hyprdrover`, `voxtype-bin`, `kanata-bin`,
`bluetui`, `spicetify-cli`, `awww`, `rage-encryption`, `llama.cpp-bin`, `solarized-sddm-theme`,
`chezmoi_modify_manager`, `rate-mirrors`, etc. `-git` packages build from upstream **HEAD**
(no pinned commit).

### Verified control gaps

| Control | Status | Evidence |
|---|---|---|
| PKGBUILD review/diff before build | ❌ Disabled in practice | `--noconfirm` on every call site; provisioning uses `paru -S --needed --noconfirm` (`.chezmoiscripts/run_onchange_before_sync_packages.sh.tmpl:140`). `SkipReview = false` in `paru.conf` is **dead** — `--noconfirm` overrides interactive review. |
| Unattended updates | ⚠️ Yes, fully | `package-manager/commands/cmd-update.sh:57` `paru -Syu --noconfirm`; `topgrade.toml.tmpl` `assume_yes = true` delegates to `package-manager update`. |
| AUR allowlist / maintainer verification | ❌ None | Any name in `packages.yaml` is built. |
| Commit/revision pinning, vendoring | ❌ None | `-git` builds from HEAD; lockfile (`locked-versions.yaml`) records versions only and is a **fast-path skip** (`operations/sync-pacman.sh:47-51`) — actual install `paru -S --noconfirm --needed <name>` never passes `=version`, always latest. No hashes. |
| Signature policy beyond stock pacman | ❌ None managed | No `pacman.conf`/`SigLevel` template in repo (only `private_dot_config/pacman/makepkg.conf` present). `paru.conf` `PgpFetch` auto-trusts PKGBUILD-referenced keys. Chaotic-AUR `.pkg.tar.zst` installed via `sudo pacman -U` from CDN URL (`run_once_before_002_install_package_manager.sh.tmpl`). |
| Malicious-PKGBUILD-change detection | ❌ None | No diff-on-change, no hash DB. Compromised package builds silently on next sync. |
| Root exposure | ⚠️ | paru `SudoLoop`; lifecycle scripts `sudo tee` into `/etc/pacman.conf` + mirrorlist, run `sudo pacman -U`. |
| Documented package security policy | ❌ Absent | Repo "Security-first" constraint covers **only age encryption**. No supply-chain/PKGBUILD/SigLevel guidance in any CLAUDE.md or `_guides/`. |
| Rollback safety net | ✅ Partial | Timeshift pre-sync snapshots = recovery, **not prevention** (won't undo credential theft or a rootkit). |

**`--noconfirm` call sites (verified):** `manager-interface.sh:162,164,172`,
`batch-operations.sh:45`, `package-operations.sh:79,191`, `sync-pacman.sh:165`, `cmd-update.sh:57`,
`executable_package-manager:435`, `run_onchange_before_sync_packages.sh.tmpl:140`.

**Key files:** `.chezmoidata/packages.yaml`,
`.chezmoiscripts/run_onchange_before_sync_packages.sh.tmpl`,
`.chezmoiscripts/run_once_before_002_install_package_manager.sh.tmpl`,
`private_dot_config/paru/paru.conf.tmpl`, `private_dot_config/topgrade.toml.tmpl`,
`private_dot_local/lib/scripts/system/package-manager/`.

---

## 4. Exposure Assessment

- **If any one** of our AUR/`-git`/Chaotic packages is hijacked (orphan adoption, maintainer
  compromise, upstream HEAD poisoning), the malicious build script **runs automatically on the next
  unattended `sync`/`update`**, as the build user, with sudo available, **no human in the loop, no
  diff shown**. This is the Atomic Arch / CHAOS RAT execution model exactly; we have no layer
  between `packages.yaml` and code execution.
- Timeshift rolls back *files*, but an infostealer exfiltrates SSH keys / tokens / browser sessions
  instantly, and an eBPF rootkit survives package removal — rollback ≠ prevention.
- **Mitigating factors:** small curated package set; `--needed` avoids needless rebuilds;
  official-repo packages remain maintainer-gated and signed; single-user/single-host blast radius.

---

## 5. Recommendations (prioritized)

**P0 — break the unattended-build-without-review loop:**
1. **Stop using `--noconfirm` for AUR builds.** Split the pipeline: keep `--noconfirm` for
   official-repo packages, require **review for AUR/`-git`/chaotic** (drop `--noconfirm` so paru
   shows the PKGBUILD/`.install` diff, or run a separate reviewed pass). Highest-leverage change.
2. **Gate updates on PKGBUILD diffs** instead of `paru -Syu --noconfirm`.

**P1 — pinning & detection:**
3. **Pin `-git` packages to known-good commits** (or move to trusted `-bin`/official). HEAD-tracking
   is an unpinned trust hole.
4. **Add a PKGBUILD hash/diff tripwire**: store a hash of each AUR PKGBUILD; alert on change at
   `sync` time so an adopted/hijacked package can't slip through silently.
5. **Add a managed `pacman.conf` template with explicit `SigLevel`** (version-controlled, not
   host-default).

**P2 — hardening & hygiene:**
6. **Reduce AUR surface**: re-check whether any AUR package is now in official repos; drop
   non-essential ones. Treat Chaotic-AUR (prebuilt, third-party trust) with extra scrutiny.
7. **Keep Flatpak ≥ 1.16.4**; prefer *verified* Flathub apps; tighten broad permissions (Flatseal).
8. **Document a package supply-chain security policy** in
   `private_dot_local/lib/scripts/system/CLAUDE.md` — current "Security-first" claim is contradicted
   by the unattended pipeline.
9. **IoC hygiene** (June 2026 Atomic Arch window): if AUR was updated recently, check for
   `/sys/fs/bpf/hidden_*`, npm pkgs `atomic-lockfile`/`js-digest`/`lockfile-js` (incl. **bun** cache —
   wave-2 variant), wave-2 `Restart=always` systemd persistence, `temp.sh`/Tor exfil, and
   `/tmp/systemd-initd` (CHAOS RAT). If found: rotate all credentials, reinstall.
   **Ran 2026-06-18 on this host — CLEAN; no AUR builds in the Jun 9–12 window per `pacman.log`.**

---

## 6. Key Tension

The repo's headline value is **"Security-first,"** yet the package pipeline is the most automated,
least-reviewed path in it. Closing the P0 gap (review for AUR/`-git` builds) resolves most exposure
without sacrificing unattended convenience for trusted official-repo packages.
