#!/bin/bash
# Default aliases

# ls
alias ls='ls --color=auto -G'
lsd &>/dev/null && alias ls='lsd --group-dirs first'
alias ll='ls -alF'
alias la='ls -a'
alias l='ls -CF'

# grep
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Console aliases
alias c='clear'
alias ..=../
alias ...=../../

if which xdg-open &>/dev/null; then
  alias open=xdg-open
else
  alias open=wsl-open
fi
