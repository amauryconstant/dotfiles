#!/usr/bin/env bash

# Script: pacman-lock-cleanup.sh
# Purpose: Safely detect and remove stale pacman lock files before automated maintenance
# Requirements: Arch Linux, pacman
# Usage: Called by topgrade systemd service via ExecStartPre

set -euo pipefail

# Configuration
LOCK_FILE="/var/lib/pacman/db.lck"

# Exit successfully if no lock file exists
if [ ! -f "$LOCK_FILE" ]; then
    exit 0
fi

# Layer 1: Check for running package manager processes
if pgrep -x "pacman|yay|paru" >/dev/null 2>&1; then
    echo "ERROR: Package manager is running - lock is ACTIVE" >&2
    echo "Active processes:" >&2
    pgrep -xa "pacman|yay|paru" >&2
    exit 1
fi

# Layer 2: Check if lock file is being accessed (using fuser if available)
if command -v fuser >/dev/null 2>&1; then
    if fuser "$LOCK_FILE" >/dev/null 2>&1; then
        echo "ERROR: Lock file is being accessed - lock is ACTIVE" >&2
        exit 1
    fi
fi

# Layer 3: Check lock file age for safety warning
lock_age=$(($(date +%s) - $(stat -c %Y "$LOCK_FILE")))
if [ $lock_age -lt 60 ]; then
    echo "WARNING: Lock file is very recent (${lock_age}s old) - possibly active" >&2
    echo "Waiting 5 seconds before removal..." >&2
    sleep 5
    # Re-check for processes after wait
    if pgrep -x "pacman|yay|paru" >/dev/null 2>&1; then
        echo "ERROR: Package manager started during wait - aborting" >&2
        exit 1
    fi
fi

# All checks passed - lock is stale, safe to remove
echo "Stale pacman lock detected: $LOCK_FILE (age: $((lock_age/60)) minutes)"
echo "No active package manager processes found - removing stale lock..."

if rm -f "$LOCK_FILE"; then
    echo "Stale lock file removed successfully"
    exit 0
else
    echo "ERROR: Failed to remove lock file" >&2
    exit 1
fi
