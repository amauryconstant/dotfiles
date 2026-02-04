#!/usr/bin/env bash
set -euo pipefail

# Get all staged shell scripts (both .sh and .sh.tmpl)
staged_scripts=$(git diff --cached --name-only --diff-filter=ACM | \
  grep -E '\.(sh|bash|sh\.tmpl|bash\.tmpl)$' || true)

if [ -z "$staged_scripts" ]; then
  exit 0
fi

echo "🔍 Running shellcheck validation on staged scripts..."

validation_failed=0
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

# Process each staged script
while IFS= read -r script; do
  if [ -z "$script" ]; then
    continue
  fi

  # Check if file is a template
  if [[ "$script" == *.tmpl ]]; then
    echo "  → Validating template: $script"

    # Pre-render template with chezmoi
    rendered_file="$temp_dir/$(basename "$script" .tmpl)"
    if ! chezmoi execute-template < "$script" > "$rendered_file" 2>/dev/null; then
      echo "    ❌ Template rendering failed: $script"
      echo "       Run: chezmoi execute-template < $script"
      validation_failed=1
      continue
    fi

    # Run shellcheck on rendered output
    shellcheck_output=$(shellcheck --severity=warning "$rendered_file" 2>&1 | sed "s|$rendered_file|$script|g" || true)
    if [ -n "$shellcheck_output" ]; then
      echo "$shellcheck_output"
      validation_failed=1
    fi
  else
    # Non-template: shellcheck directly
    echo "  → Validating script: $script"
    shellcheck_output=$(shellcheck --severity=warning "$script" 2>&1 || true)
    if [ -n "$shellcheck_output" ]; then
      echo "$shellcheck_output"
      validation_failed=1
    fi
  fi
done <<< "$staged_scripts"

# Report results
if [ $validation_failed -ne 0 ]; then
  echo ""
  echo "❌ Shellcheck validation failed!"
  echo ""
  echo "Fix issues above or:"
  echo "  - Skip validation: git commit --no-verify"
  echo "  - View issues: shellcheck <file>"
  echo "  - View rendered template: chezmoi cat <file>"
  exit 1
fi

echo "✅ All shell scripts passed shellcheck validation"
