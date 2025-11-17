#!/usr/bin/env zsh
#
# aliases.zsh - Set whatever shell aliases you want.
#

alias http=xh

alias fdf='fd --type file'
alias fdd='fd --type directory'

alias tree='eza --tree'

alias jq='jaq'

# Tar
alias tarls="tar -tvf"
alias untar="tar -xf"

# PVMs
alias p=pnpm

# AI
alias claude='clear && mise exec node@24 -- claude'

# Symlink
alias lns='ln -sfn'