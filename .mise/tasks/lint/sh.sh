#!/usr/bin/env bash
#MISE description="Lint shell scripts"
set -euo pipefail
echo "🔍 Running shellcheck on all scripts..."
find . -name "*.sh" -o -name "*.bash" | while read -r script; do
	echo "  → $script"
	shellcheck --severity=warning "$script"
done
echo "✅ All scripts passed shellcheck"
