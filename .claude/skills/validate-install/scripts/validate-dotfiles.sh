#!/usr/bin/env bash

# Script: validate-dotfiles.sh
# Purpose: Comprehensive pre-apply validation for chezmoi dotfiles
# Requirements: chezmoi, shellcheck, yq, jaq, package-manager

set -euo pipefail

# Configuration
REPO_ROOT="$HOME/.local/share/chezmoi"
RESULTS_JSON="$(mktemp)"
trap 'rm -f "$RESULTS_JSON"' EXIT

# Colors
_RED='\033[0;31m'  # Reserved for future use
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# JSON accumulator
JSON_CHECKS="[]"

# Helper: Add check result to JSON
add_check() {
    local name="$1"
    local status="$2"
    local message="$3"
    local files="${4:-[]}"
    local details="${5:-}"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [ "$status" = "pass" ]; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$status" = "fail" ]; then
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    elif [ "$status" = "warning" ]; then
        WARNINGS=$((WARNINGS + 1))
    fi

    # Truncate details if too long (max 5000 chars to avoid arg list too long)
    if [ ${#details} -gt 5000 ]; then
        details="${details:0:5000}... [truncated]"
    fi

    local check_json
    check_json=$(jaq -n \
        --arg name "$name" \
        --arg status "$status" \
        --arg message "$message" \
        --argjson files "$files" \
        --arg details "$details" \
        '{name: $name, status: $status, message: $message, files: $files, details: $details}')

    JSON_CHECKS=$(echo "$JSON_CHECKS" | jaq --argjson check "$check_json" '. += [$check]')
}

# Check 1: Merge conflicts
check_merge_conflicts() {
    echo -e "${YELLOW}→${NC} Checking for merge conflicts..." >&2

    local conflicts
    conflicts=$(chezmoi status 2>&1 | grep -c "^M" || true)

    if [ "$conflicts" -gt 0 ]; then
        local conflict_files
        conflict_files=$(chezmoi status | grep "^M" | awk '{print $2}' | jaq -R -s 'split("\n") | map(select(length > 0))')
        add_check "merge_conflicts" "fail" "Found $conflicts merge conflicts" "$conflict_files" "Run: chezmoi merge-all"
    else
        add_check "merge_conflicts" "pass" "No merge conflicts" "[]"
    fi
}

# Check 2: Template syntax
check_template_syntax() {
    echo -e "${YELLOW}→${NC} Validating template syntax..." >&2

    local templates
    templates=$(find "$REPO_ROOT" -name "*.tmpl" -not -path "*/\.git/*" -type f)

    local failed_templates="[]"
    local error_details=""

    while IFS= read -r tmpl; do
        if [ -z "$tmpl" ]; then continue; fi

        local rel_path="${tmpl#$REPO_ROOT/}"
        local output

        if ! output=$(chezmoi execute-template < "$tmpl" 2>&1); then
            failed_templates=$(echo "$failed_templates" | jaq --arg path "$rel_path" '. += [$path]')
            error_details+="$rel_path: $output\n"
        fi
    done <<< "$templates"

    local count
    count=$(echo "$failed_templates" | jaq 'length')

    if [ "$count" -gt 0 ]; then
        add_check "template_syntax" "fail" "$count template(s) failed to render" "$failed_templates" "$error_details"
    else
        add_check "template_syntax" "pass" "All templates valid" "[]"
    fi
}

# Check 3: Shellcheck validation
check_shellcheck() {
    echo -e "${YELLOW}→${NC} Running shellcheck on scripts..." >&2

    # Check if shellcheck is available
    if ! command -v shellcheck >/dev/null 2>&1; then
        add_check "shellcheck" "warning" "shellcheck not installed" "[]" "Install: paru -S shellcheck"
        return
    fi

    local scripts
    scripts=$(find "$REPO_ROOT/.chezmoiscripts" "$REPO_ROOT/private_dot_local/lib/scripts" -type f \( -name "*.sh" -o -name "*.sh.tmpl" \) 2>/dev/null || true)

    local failed_scripts="[]"
    local error_details=""

    while IFS= read -r script; do
        if [ -z "$script" ]; then continue; fi

        local rel_path="${script#$REPO_ROOT/}"
        local output

        # Render templates before shellcheck
        if [[ "$script" == *.tmpl ]]; then
            if ! output=$(chezmoi execute-template < "$script" 2>&1 | shellcheck - 2>&1); then
                failed_scripts=$(echo "$failed_scripts" | jaq --arg path "$rel_path" '. += [$path]')
                error_details+="$rel_path:\n$output\n\n"
            fi
        else
            if ! output=$(shellcheck "$script" 2>&1); then
                failed_scripts=$(echo "$failed_scripts" | jaq --arg path "$rel_path" '. += [$path]')
                error_details+="$rel_path:\n$output\n\n"
            fi
        fi
    done <<< "$scripts"

    local count
    count=$(echo "$failed_scripts" | jaq 'length')

    if [ "$count" -gt 0 ]; then
        add_check "shellcheck" "fail" "$count script(s) failed shellcheck" "$failed_scripts" "$error_details"
    else
        add_check "shellcheck" "pass" "All scripts passed shellcheck" "[]"
    fi
}

# Check 4: packages.yaml syntax
check_packages_yaml() {
    echo -e "${YELLOW}→${NC} Validating packages.yaml..." >&2

    local packages_file="$REPO_ROOT/.chezmoidata/packages.yaml"

    if [ ! -f "$packages_file" ]; then
        add_check "packages_yaml" "warning" "packages.yaml not found" "[]"
        return
    fi

    local output
    if ! output=$(yq eval '.' "$packages_file" 2>&1 >/dev/null); then
        add_check "packages_yaml" "fail" "Invalid YAML syntax" "[\"$packages_file\"]" "$output"
    else
        add_check "packages_yaml" "pass" "Valid YAML syntax" "[]"
    fi
}

# Check 5: Package module conflicts
check_package_conflicts() {
    echo -e "${YELLOW}→${NC} Checking package module conflicts..." >&2

    # Check if package-manager is available
    if ! command -v package-manager >/dev/null 2>&1; then
        add_check "package_conflicts" "warning" "package-manager not available" "[]" "System may not be fully initialized"
        return
    fi

    local output
    if ! output=$(package-manager validate 2>&1); then
        add_check "package_conflicts" "fail" "Package validation failed" "[]" "$output"
    else
        add_check "package_conflicts" "pass" "No package conflicts" "[]"
    fi
}

# Check 6: Hyprland config syntax (if changed)
check_hyprland_config() {
    echo -e "${YELLOW}→${NC} Validating Hyprland config..." >&2

    local hypr_config="$REPO_ROOT/private_dot_config/hypr/hyprland.conf.tmpl"

    if ! chezmoi status | grep -q "hypr/hyprland.conf"; then
        add_check "hyprland_config" "pass" "Hyprland config unchanged" "[]"
        return
    fi

    # Basic syntax check (Hyprland doesn't have a --check mode)
    # Check for common issues: unclosed braces, invalid sections
    local rendered
    if ! rendered=$(chezmoi execute-template < "$hypr_config" 2>&1); then
        add_check "hyprland_config" "fail" "Hyprland config template failed" "[\"$hypr_config\"]" "$rendered"
        return
    fi

    # Check for balanced braces
    local open_braces
    local close_braces
    open_braces=$(echo "$rendered" | grep -c "{" || true)
    close_braces=$(echo "$rendered" | grep -c "}" || true)

    if [ "$open_braces" -ne "$close_braces" ]; then
        add_check "hyprland_config" "fail" "Unbalanced braces in Hyprland config" "[\"$hypr_config\"]" "Open: $open_braces, Close: $close_braces"
    else
        add_check "hyprland_config" "pass" "Hyprland config syntax valid" "[]"
    fi
}

# Check 7: NVIDIA driver compatibility (if changed)
check_nvidia_driver() {
    echo -e "${YELLOW}→${NC} Checking NVIDIA driver compatibility..." >&2

    if ! chezmoi status | grep -q "packages.yaml"; then
        add_check "nvidia_driver" "pass" "Package config unchanged" "[]"
        return
    fi

    local detected_type
    detected_type=$(chezmoi data 2>/dev/null | jaq -r '.nvidiaDriverType // "unknown"')

    if [ "$detected_type" = "unknown" ]; then
        add_check "nvidia_driver" "pass" "No NVIDIA GPU detected" "[]"
        return
    fi

    # Check if correct driver module enabled
    local expected_module="graphics_drivers_$detected_type"
    local module_enabled
    module_enabled=$(yq eval ".packages.modules.$expected_module.enabled // false" "$REPO_ROOT/.chezmoidata/packages.yaml")

    if [ "$module_enabled" != "true" ]; then
        add_check "nvidia_driver" "warning" "Driver mismatch detected" "[]" "Expected: $detected_type driver\nRun: export NVIDIA_DRIVER_OVERRIDE=$detected_type && chezmoi apply"
    else
        add_check "nvidia_driver" "pass" "Correct NVIDIA driver configured" "[]"
    fi
}

# Check 8: Dry-run chezmoi apply
check_dry_run() {
    echo -e "${YELLOW}→${NC} Running chezmoi apply dry-run..." >&2

    local output
    if ! output=$(chezmoi apply --dry-run 2>&1); then
        add_check "dry_run" "fail" "Dry-run failed" "[]" "$output"
    else
        add_check "dry_run" "pass" "Dry-run succeeded" "[]"
    fi
}

# Main execution
main() {
    echo -e "${GREEN}🔍 Running dotfiles validation...${NC}\n" >&2

    cd "$REPO_ROOT"

    check_merge_conflicts
    check_template_syntax
    check_shellcheck
    check_packages_yaml
    check_package_conflicts
    check_hyprland_config
    check_nvidia_driver
    check_dry_run

    # Build final JSON
    local summary
    summary=$(jaq -n \
        --argjson total "$TOTAL_CHECKS" \
        --argjson passed "$PASSED_CHECKS" \
        --argjson failed "$FAILED_CHECKS" \
        --argjson warnings "$WARNINGS" \
        '{total: $total, passed: $passed, failed: $failed, warnings: $warnings}')

    jaq -n \
        --argjson summary "$summary" \
        --argjson checks "$JSON_CHECKS" \
        '{summary: $summary, checks: $checks}' > "$RESULTS_JSON"

    # Output JSON to stdout
    cat "$RESULTS_JSON"

    # Exit code
    if [ "$FAILED_CHECKS" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

main "$@"
