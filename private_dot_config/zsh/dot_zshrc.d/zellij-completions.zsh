#!/usr/bin/env zsh
#
# zellij-completions.zsh - Zellij completions with dynamic session name support
#

(( $+commands[zellij] )) || return

# Lists active (and resurrectable) session names for completion
_zellij_sessions_list() {
  local -a sessions
  sessions=(${(f)"$(zellij list-sessions 2>/dev/null)"})
  sessions=(${sessions%%[[:space:]]*})
  _describe 'sessions' sessions
}

# Generate completions in the background, patching in dynamic session name completion
# for all subcommands that accept a session name (attach, kill-session, delete-session, etc.)
{
  mkdir -p "$ZSH_CACHE_DIR/completions"
  zellij setup --generate-completion zsh 2>/dev/null \
    | sed -E "s/'(::session-name[^']*):'/'\\1:_zellij_sessions_list'/g" \
    >| "$ZSH_CACHE_DIR/completions/_zellij"
} &|

# On first run (no cache yet), bind manually so completions aren't silently absent
if [[ ! -f "$ZSH_CACHE_DIR/completions/_zellij" ]]; then
  typeset -g -A _comps
  _comps[zellij]=_zellij
fi
