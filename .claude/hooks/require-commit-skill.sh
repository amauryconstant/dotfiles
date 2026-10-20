#!/usr/bin/env bash
# Require the `commit` skill before `git commit`.
#
#   mark         PreToolUse(Skill)      record that skill "commit" ran in this session
#   mark-prompt  UserPromptSubmit       same, for a typed /commit (may not reach the Skill hook)
#   guard        PreToolUse(Bash)       block `git commit` until the session has a marker
#
# A guardrail, not security. It does not catch `command git commit`, `/usr/bin/git commit`,
# a script that commits, or git aliases, and it does not gate rebase/cherry-pick/revert/merge/am.
# The marker lasts the whole session; for a shorter life, test it with `find -mmin` in `guard`.
set -u

mode=${1:-}
input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
	# Fail closed for the gate so a missing jq cannot silently disable it.
	if [[ "$mode" == guard && "$input" == *"commit"* ]]; then
		echo "Blocked: require-commit-skill.sh needs jq to check for the commit skill. Install jq." >&2
		exit 2
	fi
	exit 0
fi

sid=$(jq -r '.session_id // empty' <<<"$input" 2>/dev/null)
sid=${sid//[^A-Za-z0-9_-]/}
dir=${TMPDIR:-/tmp}/claude-commit-skill
marker=$dir/${sid:-nosession}

mark() {
	mkdir -p "$dir" && touch "$marker"
}

case "$mode" in
mark)
	[[ "$(jq -r '.tool_input.skill // empty' <<<"$input")" == commit ]] && mark
	exit 0
	;;
mark-prompt)
	prompt=$(jq -r '.prompt // empty' <<<"$input")
	[[ "$prompt" =~ ^[[:space:]]*/commit([[:space:]]|$) ]] && mark
	exit 0
	;;
guard)
	cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
	# `git [-C p] [-c k=v] [--opt] commit` at a command boundary, optional VAR=x prefixes.
	re='(^|[;&|(]|[[:space:]]then|[[:space:]]do)[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--[a-z-]+(=[^[:space:]]+)?))*[[:space:]]+commit([[:space:]]|$)'
	[[ "$cmd" =~ $re ]] || exit 0
	[[ -e "$marker" ]] && exit 0
	echo "Blocked: invoke the commit skill (Skill tool, skill=commit) before git commit, then retry. This repo requires it for every commit." >&2
	exit 2
	;;
*)
	echo "require-commit-skill.sh: unknown mode '${mode}'" >&2
	exit 1
	;;
esac
