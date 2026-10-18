#!/usr/bin/env bash
# Sourced by lint/qml.sh, qml/smoke.sh and .claude/skills/desk/scripts/desk. Not a task.
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

# neutralise_qml_singletons <cfg-dir>: patch a RENDERED copy so a second shell can run
# beside the live one. Four things are singular per session: the notification bus
# name, the polkit agent, the session lock and the menu socket. Never run on source.
neutralise_qml_singletons() {
	local cfg=$1
	sed -i -E 's/(notificationsOwned|polkitOwned): true/\1: false/; s/(lockOwned): .*/\1: false/' "$cfg/Config.qml"
	sed -i 's/quickshell-menu\.sock/quickshell-menu-smoke.sock/' "$cfg/MenuServer.qml"
	grep -q 'notificationsOwned: false' "$cfg/Config.qml" || {
		echo "❌ could not neutralise Config ownership flags — Config.qml layout changed" >&2
		return 1
	}
}
