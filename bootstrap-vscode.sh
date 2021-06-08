#!/bin/bash

chmod +x ~/dotfiles/bootstrap.sh
~/dotfiles/bootstrap.sh --no-zsh --no-homebrew --no-nerd-fonts --no-terminator --no-git-config --no-node
exec zsh
