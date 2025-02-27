fpath+=( $HOME/.cache/antidote/getantidote/use-omz )
source $HOME/.cache/antidote/getantidote/use-omz/use-omz.plugin.zsh
fpath+=( $HOME/.cache/antidote/mattmc3/ez-compinit )
source $HOME/.cache/antidote/mattmc3/ez-compinit/ez-compinit.plugin.zsh
fpath+=( $HOME/.cache/antidote/zsh-users/zsh-completions/src )
fpath+=( $HOME/.cache/antidote/aloxaf/fzf-tab )
source $HOME/.cache/antidote/aloxaf/fzf-tab/fzf-tab.plugin.zsh
fpath+=( $HOME/.cache/antidote/belak/zsh-utils/completion/functions )
builtin autoload -Uz $fpath[-1]/*(N.:t)
compstyle_zshzoo_setup
fpath+=( $HOME/.cache/antidote/belak/zsh-utils/utility )
source $HOME/.cache/antidote/belak/zsh-utils/utility/utility.plugin.zsh
fpath+=( $HOME/.cache/antidote/belak/zsh-utils/history )
source $HOME/.cache/antidote/belak/zsh-utils/history/history.plugin.zsh
export PATH="$HOME/.cache/antidote/romkatv/zsh-bench:$PATH"
fpath+=( $HOME/.cache/antidote/ohmyzsh/ohmyzsh/plugins/extract )
source $HOME/.cache/antidote/ohmyzsh/ohmyzsh/plugins/extract/extract.plugin.zsh
fpath+=( $HOME/.cache/antidote/ohmyzsh/ohmyzsh/plugins/nvm )
source $HOME/.cache/antidote/ohmyzsh/ohmyzsh/plugins/nvm/nvm.plugin.zsh
fpath+=( $HOME/.cache/antidote/zsh-users/zsh-autosuggestions )
source $HOME/.cache/antidote/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( $HOME/.cache/antidote/zsh-users/zsh-history-substring-search )
source $HOME/.cache/antidote/zsh-users/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
fpath+=( $HOME/.cache/antidote/zdharma-continuum/fast-syntax-highlighting )
source $HOME/.cache/antidote/zdharma-continuum/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
