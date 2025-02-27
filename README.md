# Installation

To install the environment run the commands

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin/
chezmoi init --apply git@gitlab.com:amoconst/dotfiles.git
```