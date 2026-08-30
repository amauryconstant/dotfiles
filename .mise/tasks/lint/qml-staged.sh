#!/usr/bin/env bash
#MISE description="Lint the QML tree when any QML file is staged"
set -euo pipefail

# Whole-tree, not per-file: shell.qml references the Config singleton, which
# exists in source only as Config.qml.tmpl, so linting one staged file in
# isolation reports false unresolved-type errors. Any staged QML file therefore
# re-lints the rendered tree. Cheap — it is a handful of files.
staged_qml=$(git diff --cached --name-only --diff-filter=ACM |
	grep -E '^private_dot_config/quickshell/.*\.qml(\.tmpl)?$' || true)

if [[ -z "$staged_qml" ]]; then
	exit 0
fi

echo "🔍 Running qmllint + qmlformat check on the QML tree..."
echo "$staged_qml" | sed 's/^/  → /'

if ! mise run lint:qml; then
	echo ""
	echo "❌ QML validation failed!"
	echo ""
	echo "Fix issues above (mise run format:qml for formatting) or:"
	echo "  - Skip validation: git commit --no-verify"
	exit 1
fi

echo "✅ QML tree passed qmllint + qmlformat check"
