#!/usr/bin/env sh

# Script: terminal-cwd.sh
# Purpose: Detect current terminal's working directory for spawning new terminals
# Requirements: Arch Linux, hyprctl, /proc filesystem
# Adapted from: Omarchy's omarchy-cmd-terminal-cwd

# Get the active window's PID from Hyprland
active_window=$(hyprctl activewindow -j)
window_pid=$(echo "$active_window" | jaq -r '.pid')

# If we couldn't get a PID, fallback to $HOME
if [ -z "$window_pid" ] || [ "$window_pid" = "null" ]; then
    echo "$HOME"
    exit 0
fi

# Try to find the shell process (child of terminal)
# Common terminal emulators spawn shell as child process
shell_pid=$(pgrep -P "$window_pid" | head -n 1)

# If no child process found, use the window PID itself
if [ -z "$shell_pid" ]; then
    shell_pid="$window_pid"
fi

# Read the current working directory from /proc
cwd=$(readlink "/proc/$shell_pid/cwd" 2>/dev/null)

# Fallback to $HOME if we couldn't read the CWD
if [ -z "$cwd" ] || [ ! -d "$cwd" ]; then
    echo "$HOME"
else
    echo "$cwd"
fi
