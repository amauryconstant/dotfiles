#!/usr/bin/env zsh
#
# chezmoi-aliases.zsh - Aliases for chezmoi
#

alias cminit='chezmoi init --force'
alias cmapply='chezmoi apply -v'
alias cmedit='chezmoi edit'
alias cmadd='chezmoi add'

# Re-add a file managed by chezmoi_modify_manager. NEVER use plain `chezmoi add`
# for these, and never `chezmoi merge`/`merge-all` (it overwrites the generator
# with rendered data). Edit ignore/add:remove directives BEFORE re-adding —
# ignored lines are not added back.
#   -a  add / convert plain chezmoi entry to a managed .src.ini
#   -s  smart-add: re-add as .src.ini if already managed, else plain chezmoi add
alias cmmmadd='chezmoi_modify_manager --add'
alias cmmmsmartadd='chezmoi_modify_manager --smart-add'
# --style only affects the script that --add GENERATES; it is inert on re-add.
alias cmmmadd-tmpl='chezmoi_modify_manager --add -t=path-tmpl'