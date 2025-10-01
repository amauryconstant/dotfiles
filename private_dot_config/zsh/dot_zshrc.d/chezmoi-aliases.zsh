#!/usr/bin/env zsh
#
# chezmoi-aliases.zsh - Aliases for chezmoi
#

alias cminit='chezmoi init --force'
alias cmapply='chezmoi apply -v'
alias cmedit='chezmoi edit'
alias cmadd='chezmoi add'

alias cmmmadd='chezmoi_modify_manager -a'
alias cmmmadd-tmpl='chezmoi_modify_manager -s -t=path-tmpl'