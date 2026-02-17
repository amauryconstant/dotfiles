#!/usr/bin/env zsh
#
# aliases.zsh - Set whatever shell aliases you want.
#

alias http=xh

alias fdf='fd --type file'
alias fdd='fd --type directory'

alias ls='eza --group-directories-first'
alias ll='eza -la --group-directories-first'
alias la='eza -a'
alias tree='eza --tree'

alias jq='jaq'

alias cd='z'

# Tar
alias tarls="tar -tvf"
alias untar="tar -xf"

# PVMs
alias p=pnpm

# AI
alias claude='clear && claude'

# Disk usage
alias du='dust'

# Shortcuts
alias lgit='lazygit'

# Symlink
alias lns='ln -sfn'

# Symlink
alias twg='twiggit'
