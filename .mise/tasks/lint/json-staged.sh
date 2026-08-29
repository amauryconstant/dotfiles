#!/usr/bin/env bash
set -euo pipefail

# Exclude modify_* — these are Go-template generators (jq chokes on {{ }}),
# and chezmoi cat on the opencode target emits a decrypted API key. This task
# only ever touches the SOURCE file, but the exclusion stays absolute.
staged_json=$(git diff --cached --name-only --diff-filter=ACM |
	grep -E '\.(json|jsonc)$' |
	grep -v '/modify_' || true)

if [ -z "$staged_json" ]; then
	exit 0
fi

echo "🔍 Running jq empty on staged JSON/JSONC files..."

validation_failed=0
while IFS= read -r file; do
	[ -z "$file" ] && continue
	echo "  → $file"
	if ! mise run lint:json-file -- "$file"; then
		validation_failed=1
	fi
done <<<"$staged_json"

if [ $validation_failed -ne 0 ]; then
	echo ""
	echo "❌ JSON validation failed!"
	echo ""
	echo "Fix issues above (jq . <file> to see the parse error) or:"
	echo "  - Skip validation: git commit --no-verify"
	exit 1
fi

echo "✅ All staged JSON/JSONC files passed jq empty"
