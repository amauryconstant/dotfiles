#!/usr/bin/env sh

# Script: menu-helpers.sh
# Purpose: Shared utilities for menu system
# Requirements: Arch Linux, quickshell-menu (falls back to wofi on its own)

# 🚨 THE choke point. Sixteen menu-* scripts reach the user only through these
# two functions, so the picker is swapped here and nowhere else. quickshell-menu
# speaks the same contract Wofi did -- items on stdin, the choice on stdout,
# exit 1 and no output when cancelled -- and falls back to Wofi itself whenever
# the shell is not reachable, which is why nothing below has to care.
MENU_PICKER="${SCRIPTS_DIR:-$HOME/.local/lib/scripts}/desktop/quickshell-menu"

# Show menu
# Usage: show_menu "Prompt text" "option1|option2|option3" [breadcrumb] [back]
#
# breadcrumb and back are design page 10's navigation model: the trail drawn
# before the prompt, and what to answer when the user presses Left or Backspace
# on an empty query. `back` is a payload, so pass the SAME string the script's
# 󰁍 Back case arm already matches and nothing else has to change. Both are
# ignored on the Wofi fallback path, which is why the Back rows stay.
show_menu() {
	prompt="$1"
	options="$2"
	breadcrumb="${3:-}"
	back="${4:-}"

	# Convert pipe-separated options to newline-separated
	echo "$options" | tr '|' '\n' |
		"$MENU_PICKER" --prompt "$prompt" --breadcrumb "$breadcrumb" --back "$back"
}

# Show confirmation dialog
# Usage: confirm "Question text"
# Returns: 0 if Yes, 1 if No/Cancel
confirm() {
	question="$1"
	result=$(echo "Yes|No" | tr '|' '\n' | "$MENU_PICKER" --prompt "$question")

	[ "$result" = "Yes" ]
}

# Send notification
# Usage: notify "Title" "Message" [timeout_ms]
notify() {
	title="$1"
	message="$2"
	timeout="${3:-3000}"

	notify-send "$title" "$message" -t "$timeout"
}
