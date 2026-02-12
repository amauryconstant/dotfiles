# Hibernation Research - February 2026
**Focus**: Btrfs hibernation setup via Omarchy reference implementation

---

## Executive Summary

**Recommendation**: Add basic hibernation (swap subvolume + resume hook) — skip suspend-then-hibernate

**Rationale**:
- Omarchy removed suspend-then-hibernate on 2026-02-10 due to "suspend-wake-up loop failures across laptops"
- Basic hibernation (manual) is solid and non-conflicting
- No conflicts with existing chezmoi boot config (different mkinitcpio hook area)
- Suspend-then-hibernate automation is unreliable on Linux across hardware

---

## Omarchy Implementation (as of v3.3.0)

**Script**: `~/Projects/omarchy/bin/omarchy-hibernation-setup`

### What It Does

**1. Swap Subvolume Creation**

```bash
SWAP_SUBVOLUME="/swap"
SWAP_FILE="$SWAP_SUBVOLUME/swapfile"

sudo btrfs subvolume create "$SWAP_SUBVOLUME"
sudo chattr +C "$SWAP_SUBVOLUME"   # Disable Copy-on-Write (critical for swap)
```

- Creates `/swap` Btrfs subvolume at filesystem root
- `chattr +C` disables CoW — required for swap correctness on Btrfs

**2. Swapfile Sizing**

```bash
MEM_TOTAL_KB="$(awk '/MemTotal/ {print $2}' /proc/meminfo)k"
sudo btrfs filesystem mkswapfile -s "$MEM_TOTAL_KB" "$SWAP_FILE"
```

- Reads exact RAM size from `/proc/meminfo`
- Uses `btrfs filesystem mkswapfile` (Btrfs-native, handles offset metadata automatically)
- No manual `resume=` kernel parameter needed — Btrfs swapfile embeds offset

**3. Mkinitcpio Resume Hook**

```bash
echo "HOOKS+=(resume)" | sudo tee /etc/mkinitcpio.conf.d/omarchy_resume.conf
```

- Drop-in file, no conflict with existing `nvidia.conf` or `plymouth.conf`

**4. s2idle RTC Alarm (conditional)**

```bash
if grep -q "\[s2idle\]" /sys/power/mem_sleep 2>/dev/null; then
  echo 'KERNEL_CMDLINE[default]+="rtc_cmos.use_acpi_alarm=1"' \
    | sudo tee /etc/limine-entry-tool.d/rtc-alarm.conf
fi
```

- Only applies if system uses s2idle (modern suspend method)
- Required for reliable RTC wakeup from s2idle
- Uses Limine drop-in system (compatible with existing dotfiles Limine setup)

**5. Keyboard Backlight Hook**

```bash
# /usr/lib/systemd/system-sleep/keyboard-backlight
if [[ $1 == "pre" && $2 == "hibernate" ]]; then
  brightnessctl -d "*kbd_backlight*" set 0
fi
```

- Prevents ASUS keyboard hang during hibernate
- Only triggers on `pre hibernate` — no effect on normal suspend

---

## What Was Removed (Feb 10, 2026)

Omarchy originally configured suspend-then-hibernate via:

```ini
# /etc/systemd/logind.conf.d/lid.conf
[Login]
HandleLidSwitch=suspend-then-hibernate

# /etc/systemd/sleep.conf.d/hibernate.conf
[Sleep]
HibernateDelaySec=90min
SuspendEstimationSec=0
```

**Removed** because: "Cannot get suspend to hibernate to work consistently across different laptops — Too many failures where it's stuck in a suspend-wake-up loop"

---

## Conflict Analysis with Existing Chezmoi Boot Config

**Existing** (`run_once_after_006_configure_boot_system.sh.tmpl`):
- Adds `HOOKS+=(nvidia ...)` via `/etc/mkinitcpio.conf.d/nvidia.conf`
- Adds `HOOKS+=(plymouth ...)` via plymouth config
- Enables `nvidia-suspend.service`, `nvidia-hibernate.service`, `nvidia-resume.service`

**Hibernation addition** would add:
- `/etc/mkinitcpio.conf.d/omarchy_resume.conf` → `HOOKS+=(resume)`
- `/etc/limine-entry-tool.d/rtc-alarm.conf` (conditional, s2idle only)
- `/usr/lib/systemd/system-sleep/keyboard-backlight`

**No conflicts** — separate drop-in files, separate hook names, separate service area.

**Note**: NVIDIA services (`nvidia-hibernate.service`) already handle GPU suspend/resume. The `resume` mkinitcpio hook handles swapfile resume, orthogonal concerns.

---

## Recommended Integration

Add `run_once_after_010_setup_hibernation.sh.tmpl`:

1. Guard: check if swapfile exists (idempotent)
2. Create `/swap` Btrfs subvolume + `chattr +C`
3. Size swapfile to RAM via `btrfs filesystem mkswapfile`
4. Enable swapfile + add to `/etc/fstab`
5. Add `resume` hook to mkinitcpio drop-in
6. Conditional s2idle RTC alarm
7. Single `mkinitcpio -P` rebuild
8. Use `gum confirm` guard — destructive-adjacent operation

**Skip**: suspend-then-hibernate systemd config (proven unreliable)

---

## References

- Omarchy implementation: `~/Projects/omarchy/bin/omarchy-hibernation-setup`
- Omarchy removal commit: `e4b73726` ("Cannot get suspend to hibernate to work consistently")
- Arch Wiki: [Power management/Suspend and hibernate](https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate)
- Btrfs swapfile: `btrfs filesystem mkswapfile` embeds resume offset automatically
