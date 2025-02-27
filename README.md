# Installation

To install the software run the command 

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin/
chezmoi init --apply git@gitlab.com:amoconst/dotfiles.git
```