#!/bin/sh

# Script: .template-merge-driver.sh  
# Purpose: Custom git merge driver for .tmpl files that preserves template syntax
# Requirements: Arch Linux, git
# Usage: Called by git during merge operations on .tmpl files
# Args: %O (ancestor) %A (current) %B (other) %L (conflict-marker-size) %P (pathname)

set -euo pipefail

# Arguments from git
ancestor="$1"    # %O - common ancestor version
current="$2"     # %A - current branch version  
other="$3"       # %B - other branch version
# marker_size="$4" # %L - conflict marker size (unused)
pathname="$5"    # %P - pathname being merged

echo "🔧 Processing template file merge: $pathname"

# Check if current version has template syntax
current_has_templates=$(grep -c '{{.*}}' "$current" 2>/dev/null || echo "0")
other_has_templates=$(grep -c '{{.*}}' "$other" 2>/dev/null || echo "0")

# Strategy 1: If current has templates but other doesn't, preserve current
if [ "$current_has_templates" -gt 0 ] && [ "$other_has_templates" -eq 0 ]; then
    echo "✅ Current version has templates, other doesn't - preserving current"
    # Current already contains the right content
    exit 0
fi

# Strategy 2: If other has templates but current doesn't, use other  
if [ "$other_has_templates" -gt 0 ] && [ "$current_has_templates" -eq 0 ]; then
    echo "✅ Other version has templates, current doesn't - using other"
    cp "$other" "$current"
    exit 0
fi

# Strategy 3: Both have templates or neither has templates - use standard merge
echo "🔄 Both versions compatible - using standard merge"
if git merge-file "$current" "$ancestor" "$other" 2>/dev/null; then
    echo "✅ Standard merge successful"
    exit 0
else
    # Merge conflict - let user resolve manually but warn about templates
    echo "⚠️  Merge conflict in template file"
    echo "ℹ️  IMPORTANT: Ensure template variables ({{ .var }}) are preserved during resolution"
    exit 1
fi