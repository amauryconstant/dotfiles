#!/usr/bin/env bash
set -euo pipefail

# Mirrors lint:lua's repo-wide scope (private_dot_config/hypr only).
staged_lua=$(git diff --cached --name-only --diff-filter=ACM |
	grep -E '^private_dot_config/hypr/.*\.lua$' || true)

if [ -z "$staged_lua" ]; then
	exit 0
fi

echo "🔍 Running stylua --check on staged Lua files..."

validation_failed=0
while IFS= read -r file; do
	[ -z "$file" ] && continue
	echo "  → $file"
	if ! mise run lint:lua-file -- "$file"; then
		validation_failed=1
	fi
done <<<"$staged_lua"

if [ $validation_failed -ne 0 ]; then
	echo ""
	echo "❌ Lua formatting validation failed!"
	echo ""
	echo "Fix issues above (stylua --write <file>) or:"
	echo "  - Skip validation: git commit --no-verify"
	exit 1
fi

echo "✅ All staged Lua files passed stylua --check"
