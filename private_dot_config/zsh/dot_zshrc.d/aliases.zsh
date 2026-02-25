#!/usr/bin/env zsh
#
# aliases.zsh - Set whatever shell aliases you want.
#

# Modern drop-in replacemente
alias http=xh
alias ls='eza --group-directories-first'
alias ll='eza -la --group-directories-first'
alias la='eza -a'
alias tree='eza --tree'
alias jq='jaq'
alias cd='z'
alias du='dust'

# Tar
alias tarls="tar -tvf"
alias untar="tar -xf"

# PVMs
alias p=pnpm

# AI
alias cc='clear && claude'
alias opc='opencode'

# Shortcuts
alias lgit='lazygit'
alias ldck='lazydocker'

# Symlink
alias lns='ln -sfn'

# Twiggit
alias twg='twiggit'
