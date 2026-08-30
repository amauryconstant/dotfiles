#!/usr/bin/env bash
#MISE description="Lint the QML tree: render templates, qmllint, qmlformat check"
set -euo pipefail

# 🚨 /usr/bin/qmllint and /usr/bin/qmlformat are the *Qt5* tools
# (qt5-declarative): a syntax-only verifier that exits 0 on unknown types and
# unknown properties alike, and a qmlformat with no --check. The usable Qt6
# tools ship in qt6-declarative and are NOT on $PATH. Never use the bare names.
QMLLINT=/usr/lib/qt6/bin/qmllint
QMLFORMAT=/usr/lib/qt6/bin/qmlformat

src="private_dot_config/quickshell"
[[ -d "$src" ]] || exit 0

for bin in "$QMLLINT" "$QMLFORMAT"; do
	[[ -x "$bin" ]] || {
		echo "❌ $bin missing — install qt6-declarative" >&2
		exit 1
	}
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
worktree_root=$(git rev-parse --show-toplevel)

# Render the WHOLE tree before linting. A single file cannot be linted in
# isolation: shell.qml references the Config singleton, which exists in source
# only as Config.qml.tmpl, so a per-file pass would report it unresolved.
# Rendering to a temp tree also reproduces the deployed import graph exactly.
while IFS= read -r file; do
	rel="${file#"$src"/}"
	dest="$tmp/${rel%.tmpl}"
	mkdir -p "$(dirname "$dest")"
	case "$file" in
	*.tmpl) chezmoi execute-template --source "$worktree_root" <"$file" >"$dest" ;;
	*) cp "$file" "$dest" ;;
	esac
done < <(find "$src" \( -name '*.qml' -o -name '*.qml.tmpl' \) -type f)

mapfile -t rendered < <(find "$tmp" -name '*.qml' -type f | sort)
[[ ${#rendered[@]} -gt 0 ]] || exit 0

# -W 0 makes warnings fatal. qmllint's --max-warnings defaults to -1, so
# without it every diagnostic prints and the command still exits 0.
#
# --uncreatable-type is the ONLY exemption, and it is structural rather than a
# workaround: Quickshell exports PanelWindow from panelinterface.hpp as
# PanelWindowInterface with `isCreatable: false`, and substitutes the real
# layer-shell window at runtime from a QML file inside the binary's qrc that
# qmllint cannot see. Do NOT widen this list to silence unrelated noise — an
# over-broad exemption turns this whole task back into a no-op.
"$QMLLINT" -W 0 --uncreatable-type disable "${rendered[@]}"

# qmlformat 6.11 has no --check/--verify, so compare against its own output.
# Source *.qml only: a rendered template has no source to write back to, the
# same reason format:lua is *.lua only.
status=0
while IFS= read -r file; do
	if ! "$QMLFORMAT" "$file" | diff -q - "$file" >/dev/null; then
		echo "❌ $file is not qmlformat-clean" >&2
		"$QMLFORMAT" "$file" | diff -u "$file" - | head -30 >&2
		status=1
	fi
done < <(find "$src" -name '*.qml' -type f | sort)

[[ "$status" -eq 0 ]] || echo "Fix with: mise run format:qml" >&2
exit "$status"
