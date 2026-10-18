#!/usr/bin/env bash
# Sourced by lint/qml.sh and qml/smoke.sh. Not a task.
#
# render_qml_tree <dest-dir>: render the WHOLE Quickshell tree into <dest-dir>.
# A single file cannot be linted or run in isolation: shell.qml references the
# Config singleton, which exists in source only as Config.qml.tmpl. Rendering to
# a temp tree also reproduces the deployed import graph exactly. qmldir rides
# along: without it qmllint cannot see `pragma Singleton` types.
render_qml_tree() {
	local dest_root=$1 src="private_dot_config/quickshell" worktree_root file rel dest
	worktree_root=$(git rev-parse --show-toplevel)
	while IFS= read -r file; do
		rel="${file#"$src"/}"
		dest="$dest_root/${rel%.tmpl}"
		mkdir -p "$(dirname "$dest")"
		case "$file" in
		*.tmpl) chezmoi execute-template --source "$worktree_root" <"$file" >"$dest" ;;
		*) cp "$file" "$dest" ;;
		esac
	done < <(git ls-files -- "$src/*.qml" "$src/*.qml.tmpl" "$src/*qmldir")
}
