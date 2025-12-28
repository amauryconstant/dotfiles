#!/usr/bin/env bash

# Script: sync-lock.sh
# Purpose: Sync operation locking to prevent concurrent sync operations
# Requirements: flock (util-linux)

SYNC_LOCK_FILE="${STATE_DIR}/.sync.lock"

# =============================================================================
# SYNC LOCK MANAGEMENT
# =============================================================================

_acquire_sync_lock() {
    # Acquire exclusive lock for sync operations
    # Uses flock on $STATE_DIR/.sync.lock
    # Returns: 0 on success, 1 if already locked

    local operation="${1:-sync}"

    # Check for stale locks before attempting to acquire
    _check_stale_lock

    mkdir -p "$STATE_DIR"

    # Try to acquire lock (non-blocking)
    # Uses file descriptor 200
    exec 200>"$SYNC_LOCK_FILE"
    if ! flock -n 200; then
        ui_error "Another $operation operation is in progress"
        ui_info "If this is incorrect, remove lock file: $SYNC_LOCK_FILE"
        return 1
    fi

    return 0
}

_release_sync_lock() {
    # Release sync lock
    # Uses file descriptor 200 (set by _acquire_sync_lock)

    # Check if file descriptor 200 is open
    if [[ -n "${200+x}" ]]; then
        flock -u 200 2>/dev/null || true
        exec 200>&- 2>/dev/null || true
    fi

    # Clean up lock file
    rm -f "$SYNC_LOCK_FILE" 2>/dev/null || true

    return 0
}

_check_stale_lock() {
    # Check for stale locks (>30 minutes old)
    # Offers to remove them if found
    # Returns: 0 always (non-blocking check)

    if [[ ! -f "$SYNC_LOCK_FILE" ]]; then
        return 0
    fi

    # Calculate lock age
    local current_time=$(date +%s)
    local lock_mtime=$(stat -c %Y "$SYNC_LOCK_FILE" 2>/dev/null || echo 0)
    local lock_age=$((current_time - lock_mtime))

    # 30 minutes = 1800 seconds
    if [[ $lock_age -gt 1800 ]]; then
        ui_warning "Stale lock file detected (${lock_age}s old, created $(date -d @${lock_mtime} '+%Y-%m-%d %H:%M:%S'))"

        if ui_confirm "Remove stale lock?"; then
            rm -f "$SYNC_LOCK_FILE"
            ui_success "Stale lock removed"
        fi
    fi

    return 0
}
