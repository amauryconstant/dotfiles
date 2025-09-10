#!/bin/zsh
#
# .aliases - Set whatever shell aliases you want.
#

# Basic commands replacement
alias cd=z
alias cdi=zi

alias http=xh

alias fdf='fd --type file'
alias fdd='fd --type directory'

alias grep=rg

alias cat=bat

alias jq=jaq

# Tar
alias tarls="tar -tvf"
alias untar="tar -xf"

# PVMs
alias p=pnpm

# AI
alias claude='clear && claude'

# Git Worktree Management
alias wt='worktree-status'
alias wtc='worktree-create'
alias wts='worktree-switch'
alias wtx='worktree-cleanup'