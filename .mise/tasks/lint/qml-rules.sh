#!/usr/bin/env bash
#MISE description="Check the QML traps .claude/rules/quickshell-qml.md documents but no linter sees"
#MISE quiet=true
set -euo pipefail

# Every check here exists because qmllint passes the defect and the failure at
# runtime is silent or lands at the wrong file. Each cites the rule it enforces.
# Takes optional file arguments (the Claude edit hook passes one); with none it
# checks every tracked QML source.
src="private_dot_config/quickshell"

if [[ $# -gt 0 ]]; then
	files=("$@")
else
	mapfile -t files < <(git ls-files -- "$src/*.qml" "$src/*.qml.tmpl")
fi
[[ ${#files[@]} -gt 0 ]] || exit 0

status=0
fail() {
	echo "❌ $1:$2: $3" >&2
	status=1
}

for f in "${files[@]}"; do
	[[ -f "$f" ]] || continue

	# Imports → "Never import \"root:/\"": qmllint has no interceptor for it, so the
	# file lints clean while every type in it goes unchecked.
	while IFS=: read -r n _; do
		fail "$f" "$n" 'import "root:/" is invisible to qmllint — use a relative import'
	done < <(grep -nE '^[[:space:]]*import[[:space:]]+"root:/' "$f" || true)

	# Runtime behaviours → "`escape` is an ILLEGAL METHOD NAME": renders, formats and
	# lints clean, then the engine refuses the whole file at load.
	while IFS=: read -r n _; do
		fail "$f" "$n" 'function escape() is an illegal QML method name — use clearOrClose() style'
	done < <(grep -nE '^[[:space:]]*function[[:space:]]+escape[[:space:]]*\(' "$f" || true)

	# Runtime behaviours → "`execDetached` detaches the PROCESS, not the CGROUP": every
	# call needs Config.detach as its prefix. Calls span lines, so look ahead four.
	while IFS=: read -r n _; do
		fail "$f" "$n" 'execDetached without Config.detach — a unit restart would kill the app'
	done < <(awk '
		{ line[NR] = $0 }
		END {
			for (i = 1; i <= NR; i++) {
				if (line[i] ~ /^[[:space:]]*\/\//) continue
				if (line[i] !~ /execDetached[[:space:]]*\(/) continue
				ok = 0
				for (j = i; j <= i + 4 && j <= NR; j++) if (line[j] ~ /Config\.detach/) ok = 1
				if (!ok) print i ":"
			}
		}' "$f")

	# IPC → "An IPC function with no type annotations is never registered": the handler
	# is silently absent from `ipc show`, and `ipc call` exits 0 regardless.
	while IFS=: read -r n _; do
		fail "$f" "$n" 'IpcHandler function without a return type — it is never registered'
	done < <(awk '
		/IpcHandler[[:space:]]*\{/ { inipc = 1; depth = 0 }
		inipc {
			if ($0 ~ /^[[:space:]]*function[[:space:]]+[A-Za-z_]+[[:space:]]*\(/ && $0 !~ /\)[[:space:]]*:[[:space:]]*[A-Za-z]/)
				print NR ":"
			t = $0
			depth += gsub(/\{/, "{", t)
			t = $0
			depth -= gsub(/\}/, "}", t)
			if (depth <= 0) inipc = 0
		}' "$f")

	# Runtime behaviours → "A Nerd Font glyph literal can be authored as an empty
	# string, silently": an empty "" element in an array literal renders nothing.
	while IFS=: read -r n _; do
		fail "$f" "$n" 'empty "" in an array literal — a glyph pasted as an empty string? write chr(0x…)'
	done < <(grep -nE '(\[|,)[[:space:]]*""[[:space:]]*(,|\])|^[[:space:]]*"",?[[:space:]]*$' "$f" || true)
done

exit "$status"
