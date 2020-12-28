#!/bin/bash

DIR=~/dotfiles
OLD_DIR=~/dotfiles_old
files="bashrc zshrc oh-my-zsh gitconfig"

ansi() { printf "\e[${1}m%s\e[0m\n" "$2"; }
bold() { ansi 1 "$1"; }
italic() { ansi 3 "$1"; }
underline() { ansi 4 "$1"; }
strikethrough() { ansi 9 "$1"; }

clearLine() {
  printf "\033[1K\r"
}

logSuccess() {
  echo -e "✔ $1"
}

logError() {
  echo -e "❌ $1"
  exit 1
}

logInstallStatus() {
  local RETURN_VALUE=$1
  local PACKAGE="$2"
  local INSTALLED_TEXT="$3"

  if [ -z "$INSTALLED_TEXT" ]; then
    local INSTALLED_TEXT="installed"
  fi

  clearLine
  if [ $RETURN_VALUE -eq 0 ]; then
    logSuccess "$PACKAGE $INSTALLED_TEXT"
  else
    logError "$PACKAGE not $INSTALLED_TEXT"
  fi
}

logWarning() {
  echo -e "⚠ $1"
}

install_zsh() {
  italic "ZSH installation"
  which zsh >/dev/null
  local WHICH_RETURN=$?
  if [ $WHICH_RETURN -ne 0 ]; then
    printf "ZSH is not installed, doing it now..."
    platform=$(uname)
    clearLine
    if [[ $platform == 'Linux' ]]; then
      sudo apt-get install -y zsh >/dev/null
      logSuccess "zsh installation done"
    elif [[ $platform == 'Darwin' ]]; then
      logError "Please install zsh, then re-run this script!"
      exit
    fi
  else
    logWarning "zsh is already installed, doing nothing"
  fi

  if [[ ! $(echo $SHELL) == $(which zsh) ]]; then
    chsh -s "$(which zsh)"
    logSuccess "✔ zsh is set as default shell"
  else
    logWarning "zsh is already set as default shell"
  fi
  echo ""
}

install_oh_my_zsh() {
  italic "Oh My ZSH installation"
  if [[ ! -d $DIR/oh-my-zsh/ ]]; then
    printf "Installing oh-my-zsh..."
    git clone http://github.com/robbyrussell/oh-my-zsh.git &>/dev/null
    local INSTALL_RETURN=$?
    clearLine
    if [ $INSTALL_RETURN -eq 0 ]; then
      ln -s $DIR/oh-my-zsh ~/.oh-my-zsh
      logSuccess "oh-my-zsh installed"
    else
      logError "oh-my-zsh not installed"
    fi
  else
    logWarning "Oh My ZSH is already installed"
  fi
  install_zsh-autosuggestions
  install_zsh-syntax-highlighting
  install_powerlevel10k
  echo ""
}

install_zsh-syntax-highlighting() {
  printf "Installing zsh-syntax-highlighting..."
  local PLUGIN_FOLDER=$DIR/oh-my-zsh/custom/plugins/zsh-syntax-highlighting
  if [ ! -d $PLUGIN_FOLDER ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $PLUGIN_FOLDER &>/dev/null
    local RETURN_VALUE=$?
    clearLine
    if [ $RETURN_VALUE -eq 0 ]; then
      logSuccess "zsh-syntax-highlighting installed"
    else
      logError "zsh-syntax-highlighting not installed"
    fi
  else
    clearLine
    logWarning "zsh-syntax-highlighting already installed"
  fi
}

install_zsh-autosuggestions() {
  printf "Installing zsh-autosuggestions..."
  local PLUGIN_FOLDER=$DIR/oh-my-zsh/custom/plugins/zsh-autosuggestions
  if [ ! -d $PLUGIN_FOLDER ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $PLUGIN_FOLDER &>/dev/null
    local RETURN_VALUE=$?
    clearLine
    if [ $RETURN_VALUE -eq 0 ]; then
      logSuccess "zsh-autosuggestions installed"
    else
      logError "zsh-autosuggestions not installed"
    fi
  else
    clearLine
    logWarning "zsh-autosuggestions already installed"
  fi
}

install_powerlevel10k() {
  printf "Installing powerlevel10k..."
  local THEME_FOLDER=$DIR/oh-my-zsh/custom/themes/powerlevel10k
  if [ ! -d "$THEME_FOLDER" ]; then
    git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git $THEME_FOLDER &>/dev/null
    local RETURN_VALUE=$?
    clearLine
    if [ $RETURN_VALUE -eq 0 ]; then
      logSuccess "powerlevel10k installed"
    else
      logError "powerlevel10k not installed"
    fi
  else
    clearLine
    logWarning "powerlevel10k already installed"
  fi
}

install_lsd() {
  italic "LSD installation"
  if ! which lsd >/dev/null; then
    local FILE=lsd-musl_0.19.0_amd64.deb
    platform=$(uname)
    if [[ $platform == 'Linux' ]]; then
      printf "Downloading lsd..."
      wget https://github.com/Peltoche/lsd/releases/download/0.19.0/$FILE &>/dev/null
      clearLine
      logSuccess "lsd downloaded"

      printf "Installing lsd..."
      sudo dpkg -i $FILE
      clearLine
      logSuccess "lsd installed"

      printf "Cleaning..."
      rm -f $FILE
      clearLine
      logSuccess "Cleaned"
    elif [[ $platform == 'Darwin' ]]; then
      printf "Installing lsd..."
      brew install lsd clearLine &>/dev/null
      logSuccess "lsd installed"
    fi

  else
    clearLine
    logWarning "lsd already installed"
  fi

  echo ""
}

install_nerd_fonts() {
  local fonts="JetBrainsMono"
  local FOLDER="./nerd-fonts"
  italic "Nerd Fonts installation"
  local fontsToInstall=""

  for font in $fonts; do
    if ! fc-list | grep -q "$font"; then
      fontsToInstall+=" $font"
    else
      logWarning "$font already installed"
    fi
  done

  if [ -n "$fontsToInstall" ]; then
    if [ ! -d "$FOLDER" ]; then
      printf "Cloning repo..."
      git clone --depth=1 git@github.com:ryanoasis/nerd-fonts.git $FOLDER &>/dev/null
      logInstallStatus $? "nerd fonts" "cloned"
    fi

    for font in $fonts; do
      printf "Installing %s" "$font"
      $FOLDER/install.sh -q "$font" &>/dev/null
      logInstallStatus $? "$font"
    done

    printf "Cleaning repo..."
    rm -rf nerd-fonts
    logInstallStatus $? "nerd fonts" "cleaned"
  fi
  echo ""
}

install_fzf() {
  italic "fzf installation"
  if ! which fzf >/dev/null; then
    printf "Downloading fzf..."
    rm -rf ~/.fzf
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf &>/dev/null
    logInstallStatus $? "fzf" "downloaded"

    printf "Installing fzf..."
    ~/.fzf/install --key-bindings --completion --no-update-rc &>/dev/null
    logInstallStatus $? "fzf"
  else
    clearLine
    logWarning "fzf is already installed"
  fi
  echo ""
}

install_n() {
  italic "n and NodeJS installation"
  if ! which n >/dev/null; then
    printf "Downloading n..."
    curl -sL https://git.io/n-install | bash -s -- -q -n
    logInstallStatus $? "n" "installed"
  else
    clearLine
    logWarning "n is already installed"
  fi
  echo ""
}

install_homebrew() {
  platform=$(uname)
  if [[ $platform == 'Darwin' ]]; then
    italic "Homebrew installation"
    if ! which brew &>/dev/null; then
      printf "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>/dev/null
      logInstallStatus "$?" "Homebrew" "installed"
    else
      logWarning "Homebrew is already installed"
    fi
    echo ""
  fi
}

install_terminator() {
  platform=$(uname)
  if [[ $platform == 'Linux' ]]; then
    italic "Terminator installation"
    if ! which terminator &>/dev/null; then
      printf "Installing Terminator..."
      sudo apt-get install terminator &>/dev/null
      logInstallStatus "$?" "Terminator" "installed"

      printf "Setting config"
      ln -s $DIR/terminator/config ~/.config/terminator/config
      logInstallStatus "$?" "Terminator config" "installed"
    else
      logWarning "Terminator is already installed"
    fi
    echo ""
  fi
}

backup_files() {
  italic "Backing up files in $OLD_DIR"
  printf "Creating backup folder %s..." $OLD_DIR
  mkdir -p $OLD_DIR
  clearLine
  logSuccess "Created backup folder $OLD_DIR"
  for file in $files; do
    if [ -f ~/.$file ]; then
      printf "Backing up ~/.%s" "$file"
      rm -rf $OLD_DIR/."$file"
      if mv -f ~/."$file" "$OLD_DIR"; then
        clearLine
        logSuccess "Backed up ~/.$file"
      else
        clearLine
        logError "Error when backing up ~/.$file"
      fi
    fi
  done
  echo ""
}

manual_todo() {
  platform=$(uname)
  if [[ $platform == 'Darwin' ]]; then
    italic "TODO for macOS"
    echo "Download iTerm2: https://iterm2.com"
    echo "Setup iTerm2 to load preferences from $DIR/iterm2 folder"
  elif [[ $platform == 'Linux' ]]; then
    italic "TODO for Linux"
  else
    italic "TODO"
  fi
  echo "Create ~/.private to have your own configuration"
  echo ""
}

create_symlinks() {
  italic "Installing dotfiles"
  for file in $files; do
    if [ -f "$DIR/$file" ]; then
      printf "Installing .%s..." "$file"
      ln -s $DIR/"$file" ~/."$file"
      clearLine
      logSuccess ".$file installed"
    fi
  done
  echo ""
}

cd $DIR || exit

backup_files
create_symlinks
install_zsh
install_oh_my_zsh
install_homebrew
install_lsd
install_nerd_fonts
install_fzf
install_n
install_terminator
manual_todo

logSuccess "Everything is done !"
