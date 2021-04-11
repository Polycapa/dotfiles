export ZSH=~/.oh-my-zsh
export ZSH_THEME="powerlevel10k/powerlevel10k"
export EDITOR="code --wait"
export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).

# Output a random arrow for new line
get_start_line() {
  local STARTS=("\uf460" "\uf432" "\ufa33" "\uf9d7")
  local rand=$(($RANDOM % ${#STARTS[@]}))
  echo -ne "${STARTS[$rand + 1]} "
}

# Display running containers
prompt_docker() {
  local POWERLEVEL9K_DOCKER_ICON=$'\uf308' #
  local DOCKER_BACKGROUND_COLOR="032"
  local DOCKER_FOREGROUND_COLOR="black"

  if docker info &> /dev/null; then
    local COUNT=0
    while read -r container
    do
      COUNT=$((COUNT + 1))
      local TEXT="${container}"
      local STATE="${container}_RUNNING"
      p10k segment -s "$STATE" -i "$POWERLEVEL9K_DOCKER_ICON" -t "$TEXT" -b "$DOCKER_BACKGROUND_COLOR" -f "$DOCKER_FOREGROUND_COLOR"
    done < <(docker ps --format "{{.Names}}")

    if [ $COUNT -eq 0 ]; then
      local TEXT="No containers running"
      p10k segment -s "${container}_NOT_RUNNING" -i "$POWERLEVEL9K_DOCKER_ICON" -t "$TEXT" -b "$DOCKER_BACKGROUND_COLOR" -f "$DOCKER_FOREGROUND_COLOR"
    fi
  else
    local TEXT="Docker not running"
    p10k segment -s "${container}_NOT_RUNNING" -i "$POWERLEVEL9K_DOCKER_ICON" -t "$TEXT" -b "$DOCKER_BACKGROUND_COLOR" -f "$DOCKER_FOREGROUND_COLOR"
  fi
}

# Powerlevel9K setup
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0
POWERLEVEL9K_STATUS_CROSS="true"
POWERLEVEL9K_ALWAYS_SHOW_USER="false"
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=""
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=$(get_start_line)

# Powerlevel9K colors
POWERLEVEL9K_DIR_BACKGROUND='white'
POWERLEVEL9K_OS_ICON_BACKGROUND='white'
POWERLEVEL9K_OS_ICON_FOREGROUND='black'
POWERLEVEL9K_TIME_BACKGROUND='117'
POWERLEVEL9K_TIME_FOREGROUND='black'
POWERLEVEL9K_VCS_CLEAN_BACKGROUND='076'
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='grey7'
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='white'
POWERLEVEL9K_DATE_BACKGROUND="$POWERLEVEL9K_TIME_BACKGROUND"
POWERLEVEL9K_DATE_FOREGROUND="$POWERLEVEL9K_TIME_FOREGROUND"
POWERLEVEL9K_NVM_BACKGROUND='076'
POWERLEVEL9K_TRANSIENT_PROMPT=always

# Powerlevel9K display
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon time date_joined dir command_execution_time status
  newline
  vcs ram background_jobs
  newline
  docker
  newline
)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

# ZSH plugins
plugins=(
  aws
  colored-man-pages
  command-not-found
  cp
  docker
  docker-compose
  extract
  fzf
  git
  ng
  node
  npm
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Source bash scripts from dotfiles
for script in ~/dotfiles/bash/*.sh; do
  if ! echo "$script" | grep -q "sources.sh"; then
    source "$script"
  fi
done


# Source private config
if [ -f ~/.private ]; then
  source ~/.private
fi

# Start Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# Fixes for zsh auto suggestions
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}

zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# Setup zsh-syntax-highlighting
source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Start fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh