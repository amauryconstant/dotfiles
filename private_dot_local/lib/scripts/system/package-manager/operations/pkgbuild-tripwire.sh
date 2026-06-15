#!/usr/bin/env bash

# Script: pkgbuild-tripwire.sh
# Purpose: Supply-chain tripwire — detect changed/unapproved AUR PKGBUILDs before build
# Requirements: pacman, paru, yq, sha256sum
#
# Trust model (see _research/PACKAGE_SUPPLY_CHAIN_RESEARCH.md):
#   official [core]/[extra]/[multilib] + chaotic-aur (signed binary sync repos) → trusted, NOT gated
#   true AUR (PKGBUILD executes locally at build time)                          → gated by this tripwire
# A package is "AUR-built" iff it is NOT in any pacman sync repo but IS resolvable via paru AUR.
#
# On-disk contract (shared with the self-contained chezmoi sync script):
#   $STATE_DIR/pkgbuild-hashes.yaml   approved.<name>.hash (sha256) + approved.<name>.at (ISO ts)
#   $STATE_DIR/pkgbuilds/<name>.PKGBUILD   last-approved PKGBUILD text (for diffing on change)
#
# Known MVP limitations (tracked in _plans/PACKAGE_SUPPLY_CHAIN_HARDENING.md):
#   - `.install` hooks (run as root by pacman -U) are not captured by `paru -Gp`
#   - TOCTOU: paru -S re-fetches at build time; AUR HEAD could change between check and build
#   - Transient fetch failures fail OPEN (paru -S would fetch the same source anyway)

# =============================================================================
# PATHS
# =============================================================================

TRIPWIRE_DB="${STATE_DIR:-.}/pkgbuild-hashes.yaml"
TRIPWIRE_SNAP_DIR="${STATE_DIR:-.}/pkgbuilds"

# =============================================================================
# TIER DETECTION
# =============================================================================

# Return 0 if package is AUR-built (PKGBUILD runs locally), 1 otherwise.
_pkg_is_aur() {
    local name="$1"

    # In a pacman sync repo (official or chaotic-aur prebuilt binary) → not AUR-built
    if pacman -Si "$name" &>/dev/null; then
        return 1
    fi

    # Resolvable via paru AUR → AUR-built
    if command -v paru >/dev/null 2>&1 && timeout 15 paru -Si --aur "$name" &>/dev/null; then
        return 0
    fi

    return 1
}

# =============================================================================
# HASHING
# =============================================================================

# Print the merged PKGBUILD for an AUR package (no build). Empty on failure.
_tripwire_fetch() {
    local name="$1"
    timeout 30 paru -Gp "$name" 2>/dev/null
}

# Hash stdin (PKGBUILD text) → sha256 hex.
_tripwire_hash() {
    sha256sum | awk '{print $1}'
}

# Read the approved hash for a package from the DB. Returns 1 if absent.
_tripwire_db_hash() {
    local name="$1"
    [[ -f "$TRIPWIRE_DB" ]] || return 1
    local h
    h=$(NAME="$name" yq eval '.approved[env(NAME)].hash // ""' "$TRIPWIRE_DB" 2>/dev/null)
    [[ -n "$h" && "$h" != "null" ]] || return 1
    printf '%s' "$h"
}

# Record approved hash + snapshot for a package.
# Usage: _tripwire_record <name> [pkgbuild_text]
_tripwire_record() {
    local name="$1"
    local text="${2:-}"

    [[ -z "$text" ]] && text=$(_tripwire_fetch "$name")
    if [[ -z "$text" ]]; then
        ui_error "Could not fetch PKGBUILD for '$name'" >&2
        return 1
    fi

    local hash ts
    hash=$(printf '%s' "$text" | _tripwire_hash)
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    mkdir -p "$TRIPWIRE_SNAP_DIR"
    printf '%s\n' "$text" > "$TRIPWIRE_SNAP_DIR/$name.PKGBUILD"

    [[ -f "$TRIPWIRE_DB" ]] || echo "approved: {}" > "$TRIPWIRE_DB"
    NAME="$name" HASH="$hash" TS="$ts" yq eval -i \
        '.approved[env(NAME)].hash = env(HASH) | .approved[env(NAME)].at = env(TS)' \
        "$TRIPWIRE_DB"
}

# =============================================================================
# GATE
# =============================================================================

# Check one AUR package. Returns 0 if clean, 1 if blocked (new or changed).
# On block, prints reason + diff to stderr. Caller must have confirmed AUR tier.
_tripwire_check() {
    local name="$1"

    local current_text current_hash db_hash
    current_text=$(_tripwire_fetch "$name")
    if [[ -z "$current_text" ]]; then
        # Fail open: paru -S would fetch the same source at build time anyway.
        ui_warning "Tripwire: could not fetch PKGBUILD for '$name' (network?) — allowing" >&2
        return 0
    fi
    current_hash=$(printf '%s' "$current_text" | _tripwire_hash)

    if ! db_hash=$(_tripwire_db_hash "$name"); then
        ui_warning "$ICON_WARNING Tripwire: '$name' is a NEW AUR package (not yet approved)" >&2
        return 1
    fi

    if [[ "$current_hash" == "$db_hash" ]]; then
        return 0
    fi

    ui_warning "$ICON_WARNING Tripwire: PKGBUILD for '$name' CHANGED since approval" >&2
    if [[ -f "$TRIPWIRE_SNAP_DIR/$name.PKGBUILD" ]]; then
        diff -u "$TRIPWIRE_SNAP_DIR/$name.PKGBUILD" <(printf '%s\n' "$current_text") >&2 || true
    fi
    return 1
}

# Scan a list of package names. Filters to the AUR subset, checks each.
# Prints blocked package names to stdout (one per line). Returns 1 if any blocked.
_tripwire_scan() {
    local -a names=("$@")
    local blocked=0
    local name

    for name in "${names[@]}"; do
        [[ -z "$name" ]] && continue
        _pkg_is_aur "$name" || continue
        if ! _tripwire_check "$name"; then
            echo "$name"
            blocked=1
        fi
    done

    return "$blocked"
}

# =============================================================================
# SEED
# =============================================================================

# Record current hashes for all installed AUR packages (no prompt).
# `pacman -Qmq` = foreign packages = installed-and-not-in-any-sync-repo = true AUR.
_tripwire_seed() {
    local -a installed=()
    mapfile -t installed < <(pacman -Qmq 2>/dev/null)

    if [[ ${#installed[@]} -eq 0 ]]; then
        ui_info "No installed AUR packages to seed" >&2
        return 0
    fi

    local name recorded=0
    for name in "${installed[@]}"; do
        [[ -z "$name" ]] && continue
        # Skip *-debug split packages — not independent AUR packages (covered by base PKGBUILD)
        [[ "$name" == *-debug ]] && continue
        if _tripwire_record "$name"; then
            ui_success "Seeded $name" >&2
            ((recorded++))
        else
            ui_warning "Skipped $name (fetch failed)" >&2
        fi
    done

    ui_info "Seeded $recorded/${#installed[@]} AUR packages into $TRIPWIRE_DB" >&2
    return 0
}
