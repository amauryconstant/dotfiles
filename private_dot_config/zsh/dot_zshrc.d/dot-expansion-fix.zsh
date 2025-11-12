#!/usr/bin/env zsh
#
# dot-expansion-fix - Fix Zephyr's missing expand-dot-to-parent-directory-path widget
#

# Create compatibility wrapper for Zephyr's dot-expansion bug
expand-dot-to-parent-directory-path() {
  # Call Zephyr's dot-expansion function
  dot-expansion
}

# Register as ZLE widget
zle -N expand-dot-to-parent-directory-path