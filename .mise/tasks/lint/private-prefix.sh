#!/usr/bin/env bash
#MISE description="Reject nested private_ source prefixes (only top-level dirs and .ssh/.keys contents keep it)"
#MISE quiet=true
set -euo pipefail

# umask 0077 (private_dot_config/shell/env) makes every target 600/700 already, so a
# nested private_ is noise. `chezmoi add` brings it back on every 0600 file:
# fix with `chezmoi chattr -- noprivate <target>`.
status=0
while IFS= read -r -d '' path; do
	case "$path" in
	private_dot_ssh/* | private_dot_keys/* | _ai/*) continue ;;
	esac
	rest=${path#*/}
	[ "$rest" = "$path" ] && continue
	if [[ "/$rest" == *"/private_"* || "/$rest" == *"/encrypted_private_"* || "/$rest" == *"/create_private_"* ]]; then
		echo "❌ nested private_ prefix: $path"
		status=1
	fi
done < <(git ls-files -z)
[ "$status" -eq 0 ] || echo "   Fix: chezmoi chattr -- noprivate <target>"
exit "$status"
