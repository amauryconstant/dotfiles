#!/usr/bin/env bash
# omarchy-changes.sh - Track changes from omarchy repository
# Purpose: Show new releases from omarchy since last check, with AI-powered semantic classification
# Usage: bash omarchy-changes.sh

set -euo pipefail

# Constants
OMARCHY_REPO="$HOME/Projects/omarchy"
STATE_DIR="$HOME/.local/state/omarchy-tracker"
STATE_FILE="$STATE_DIR/last-tag"
GITHUB_API="https://api.github.com/repos/basecamp/omarchy/releases/tags"

# Validate repository exists and is valid
validate_repository() {
    if [ ! -d "$OMARCHY_REPO" ]; then
        echo "Error: Omarchy repository not found at $OMARCHY_REPO" >&2
        echo "Clone it with: git clone https://github.com/basecamp/omarchy.git $OMARCHY_REPO" >&2
        exit 1
    fi

    if ! git -C "$OMARCHY_REPO" rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: Directory exists but is not a git repository" >&2
        exit 1
    fi
}

# Migrate from old commit-based state to tag-based
migrate_state() {
    local old_file="$STATE_DIR/last-commit"

    if [ -f "$old_file" ] && [ ! -f "$STATE_FILE" ]; then
        echo "Migrating from commit-based to tag-based tracking..."

        # Get tag for last commit
        local last_commit
        last_commit=$(grep '^COMMIT_HASH=' "$old_file" | cut -d'=' -f2)

        # Find corresponding tag
        local tag
        tag=$(git -C "$OMARCHY_REPO" describe --tags --exact-match "$last_commit" 2>/dev/null \
              || git -C "$OMARCHY_REPO" describe --tags --abbrev=0 "$last_commit" 2>/dev/null \
              || echo "")

        if [ -n "$tag" ]; then
            echo "$tag" > "$STATE_FILE"
            echo "Migrated to tag: $tag"
            mv "$old_file" "$old_file.backup"
        else
            echo "Warning: Could not find tag for commit $last_commit" >&2
            echo "Initializing with latest tag instead..."
            rm -f "$old_file"
        fi
    fi
}

# Get latest version tag from repository
get_latest_tag() {
    git -C "$OMARCHY_REPO" tag --list --sort=-version:refname \
      | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
      | head -1
}

# Initialize state tracking on first run
initialize_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "First run - initializing tag-based tracking..."
        mkdir -p "$STATE_DIR"

        # Get latest tag
        local latest_tag
        latest_tag=$(get_latest_tag)

        if [ -z "$latest_tag" ]; then
            echo "Error: No version tags found in repository" >&2
            exit 1
        fi

        # Create state file
        echo "$latest_tag" > "$STATE_FILE"

        echo "State initialized at version $latest_tag"
        echo "Run this command again to see new releases."
        exit 0
    fi
}

# Fetch updates from omarchy repository
fetch_updates() {
    echo "Fetching updates from omarchy repository..."
    if ! git -C "$OMARCHY_REPO" fetch --all --quiet 2>&1; then
        echo "Warning: Failed to fetch updates - using cached data" >&2
    fi
}

# Get release notes from GitHub API
fetch_release_notes() {
    local tag="$1"

    # Fetch with timeout
    local response
    response=$(curl -s --max-time 10 "${GITHUB_API}/${tag}" 2>/dev/null || echo "{}")

    # Extract body field (release notes) - support both jq and jaq
    local notes
    if command -v jaq >/dev/null 2>&1; then
        notes=$(echo "$response" | jaq -r '.body // empty' 2>/dev/null || echo "")
    elif command -v jq >/dev/null 2>&1; then
        notes=$(echo "$response" | jq -r '.body // empty' 2>/dev/null || echo "")
    else
        echo "Error: Neither jq nor jaq found. Install one of them." >&2
        exit 1
    fi

    echo "$notes"
}

# Generate commit summary as fallback
generate_commit_summary() {
    local prev_tag="$1"
    local curr_tag="$2"

    echo "## Commit Summary"
    echo ""
    git -C "$OMARCHY_REPO" log --pretty=format:'- %s' "${prev_tag}..${curr_tag}" 2>/dev/null
}

# Get commit count between tags
get_commit_count() {
    local prev_tag="$1"
    local curr_tag="$2"

    git -C "$OMARCHY_REPO" rev-list --count "${prev_tag}..${curr_tag}" 2>/dev/null || echo "0"
}

# Get all new tags since last check
get_new_tags() {
    local last_tag="$1"
    local latest_tag="$2"

    git -C "$OMARCHY_REPO" tag --list --sort=version:refname \
      | awk "/^${last_tag}$/,/^${latest_tag}$/" \
      | grep -v "^${last_tag}$"
}

# Process a single release
process_release() {
    local prev_tag="$1"
    local curr_tag="$2"

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "Release: $curr_tag"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # Fetch release notes from GitHub
    echo "Fetching release notes from GitHub..."
    local release_notes
    release_notes=$(fetch_release_notes "$curr_tag")

    # Get commit count
    local commit_count
    commit_count=$(get_commit_count "$prev_tag" "$curr_tag")

    # Fallback to commit summary if no release notes
    if [ -z "$release_notes" ]; then
        echo "No release notes found on GitHub. Generating commit summary..."
        release_notes=$(generate_commit_summary "$prev_tag" "$curr_tag")
    fi

    # Output formatted data for AI analysis
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "RELEASE DATA FOR AI CLASSIFICATION"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    cat <<EOF
Analyze this Omarchy release:

Version: $curr_tag
Previous Version: $prev_tag
Commits Included: $commit_count

Release Notes:
$release_notes

EOF
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}

# Check for new releases
check_releases() {
    # Read last tracked tag
    local last_tag
    last_tag=$(cat "$STATE_FILE")

    if [ -z "$last_tag" ]; then
        echo "Error: Could not read last tag from state file" >&2
        exit 1
    fi

    # Get latest tag
    local latest_tag
    latest_tag=$(get_latest_tag)

    if [ -z "$latest_tag" ]; then
        echo "Error: No version tags found in repository" >&2
        exit 1
    fi

    # Check if there are new releases
    if [ "$last_tag" = "$latest_tag" ]; then
        echo "No new releases since last check ($last_tag)"
        exit 0
    fi

    # Get all new tags
    local new_tags
    new_tags=$(get_new_tags "$last_tag" "$latest_tag")

    if [ -z "$new_tags" ]; then
        echo "No new releases since last check ($last_tag)"
        exit 0
    fi

    # Process each release
    local prev_tag="$last_tag"
    while IFS= read -r tag; do
        process_release "$prev_tag" "$tag"
        prev_tag="$tag"
    done <<< "$new_tags"

    # Offer to update state
    update_state "$latest_tag"
}

# Update state to latest tag
update_state() {
    local latest_tag="$1"

    # Auto-update if flag set OR non-interactive terminal
    if [[ "${OMARCHY_AUTO_UPDATE}" == "true" ]] || [[ ! -t 0 ]]; then
        echo "$latest_tag" > "$STATE_FILE"
        echo "State updated to $latest_tag"
        return 0
    fi

    # Interactive prompt (original behavior)
    echo ""
    read -p "Update tracking state to $latest_tag? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$latest_tag" > "$STATE_FILE"
        echo "State updated to $latest_tag"
    else
        echo "State not updated - next run will show the same releases"
    fi
}

# Main execution
main() {
    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                cat <<EOF
Usage: script.sh [--help]

Checks for new omarchy releases since last tracked version.
State tracked in: $STATE_DIR

Environment variables:
  OMARCHY_AUTO_UPDATE=true    Auto-update state without prompting

Options:
  --help, -h          Show this help message
EOF
                exit 0
                ;;
            *)
                echo "Error: Unknown option '$1'" >&2
                echo "Use --help for usage information" >&2
                exit 1
                ;;
        esac
    done

    # Common setup
    validate_repository
    migrate_state

    # Run incremental mode
    initialize_state
    fetch_updates
    check_releases
}

main "$@"
