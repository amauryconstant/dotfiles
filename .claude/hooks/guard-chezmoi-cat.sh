#!/usr/bin/env bash
# PreToolUse(Bash): refuse an unredirected `chezmoi cat` of a secret-bearing target.
#
# `chezmoi cat` on opencode.jsonc renders a decrypted API key, and a transcript is a log
# (.claude/rules/chezmoi-modify-entries.md). Validation form `chezmoi cat <t> >/dev/null`
# is allowed; so is any target that is neither opencode nor an encrypted source.
set -u

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[[ "$cmd" == *"chezmoi cat"* ]] || exit 0
[[ "$cmd" =~ (\>|\&\>)[[:space:]]*/dev/null ]] && exit 0

# Targets: every word after "chezmoi cat" up to a shell separator.
rest=${cmd#*chezmoi cat}
rest=${rest%%[|;&>]*}
for arg in $rest; do
	[[ "$arg" == -* ]] && continue
	target=${arg//[\"\']/}
	target=${target/#\~/$HOME}
	secret=
	[[ "$target" == *opencode* ]] && secret="opencode renders a decrypted API key"
	if [[ -z "$secret" ]] && src=$(chezmoi source-path "$target" 2>/dev/null); then
		[[ "$(basename "$src")" == encrypted_* || "$src" == *.age ]] && secret="source is encrypted"
	fi
	if [[ -n "$secret" ]]; then
		echo "Blocked: 'chezmoi cat $arg' would print secrets ($secret). Validate with '>/dev/null' instead." >&2
		exit 2
	fi
done
exit 0
