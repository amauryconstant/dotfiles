#!/usr/bin/env bash
set -euo pipefail

# Mirrors lint:yaml's repo-wide scope (.chezmoidata only).
staged_yaml=$(git diff --cached --name-only --diff-filter=ACM |
	grep -E '^\.chezmoidata/.*\.yaml$' || true)

if [ -z "$staged_yaml" ]; then
	exit 0
fi

echo "🔍 Running yamllint on staged data files..."

validation_failed=0
while IFS= read -r file; do
	[ -z "$file" ] && continue
	echo "  → $file"
	if ! mise run lint:yaml-file -- "$file"; then
		validation_failed=1
	fi
done <<<"$staged_yaml"

if [ $validation_failed -ne 0 ]; then
	echo ""
	echo "❌ YAML validation failed!"
	echo ""
	echo "Fix issues above or:"
	echo "  - Skip validation: git commit --no-verify"
	exit 1
fi

echo "✅ All staged YAML data files passed yamllint"
