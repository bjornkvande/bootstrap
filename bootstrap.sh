#!/usr/bin/env bash

######################################################################################
# This script will attempt to bootstrap a new developer machine by installing all the 
# tools needed for development, mount the secret part of the USB stick containing my 
# secret keys and passwords, configuring the software, and clone and configure the 
# repositories under development. This script and the related files can be found in the 
# kvande/bootstrap repository. It should work for both linux and mac.

#####################################
# Steps taken:
#  1) Have the USB stick plugged in and mounted
#  2) (linux) Install zsh and developer tool essentials (git, tmux, wget, direnv etc)
#  2) (mac) Install homebrew and developer tool essentials (git, tmux, direnv, wget, etc)
#  3) Install the node version manager so we can use different versions of node
#  4) Install VS Code and the extensions I use 
#  5) Set up dot files for bash, zsh, git, and tmux 
#  6) Configure VS Code the way I want
#  7) (linux) Make zsh the default shell
#  8) Install and start mongodb

# TODO:
# 20) (linux) Install veracrypt and mount the secret part of the USB stick
# 21) create, populate, and configure user rights for the .ssh directory

set -e

DOTFILES_DIR="$HOME/.dotfiles"

configureDotFiles() {
  # the files to copy into the directory and link from the home directory
  FILES=(
    ".bashrc"
    ".profile"
    ".zprofile"
    ".zshrc"
    ".gitconfig"
    ".tmux.conf"
  )

  # make sure the .dotfiles directory exists
  if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Creating $DOTFILES_DIR"
    mkdir -p "$DOTFILES_DIR"
  fi

  # copy the files into the .dotfiles directory
  for file in "${FILES[@]}"; do
    src="$PWD/$file"
    dest="$DOTFILES_DIR/$file"
    echo "Copying $src to $dest"
    cp "$src" "$dest"
  done

  # make symbolic links for the files in my home directory
  for file in "${FILES[@]}"; do
    link="$HOME/$file"
    target="$DOTFILES_DIR/$file"
    # Remove existing file or symlink if it exists
    [ -e "$link" ] || [ -L "$link" ] && rm -f "$link"
    echo "Creating symlink: $link -> $target"
    ln -s "$target" "$link"
  done
}

installNode() {
  # nvm (node version manager) is used to install/use different versions of node
  if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing the Node Version Manager"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
  fi

  # Load NVM (for current shell + script)
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  # currently we use node 16 as our default version globally 
  nvm install 16
  nvm alias default 16
  nvm use default

  # make sure we can run trailguide on https 
  sudo setcap 'cap_net_bind_service=+ep' $(which node)
}

installAndConfigureVSCode() {
  # install VS Code
  echo "Adding Microsoft repository for VS Code..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
  sudo sh -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  sudo apt update -y
  echo "Installing VS Code..."
  sudo apt install -y code

  # Install VS Code extensions
  if [ -f "vscode-extensions.txt" ]; then
    echo "Installing VS Code extensions..."
    # Clean the file: remove empty lines and trim spaces
    sed -i '/^$/d;s/^[ \t]*//;s/[ \t]*$//' vscode-extensions.txt
    # Install each extension
    cat vscode-extensions.txt | xargs -n 1 code --install-extension
  else
    echo "No vscode-extensions.txt file found; skipping extensions."
  fi

  # set our default VS Code settings
  cp "vscode_settings.json" "$DOTFILES_DIR"

  # symlink the default Visual Studio Code settings file to the copied file
  echo "Setting default configuration for VS Code..."
  VSCODE_USER_DIR="$HOME/.config/Code/User"
  mkdir -p "$VSCODE_USER_DIR"
  if [ -e "$VSCODE_USER_DIR/settings.json" ] || [ -L "$VSCODE_USER_DIR/settings.json" ]; then
    rm -f "$VSCODE_USER_DIR/settings.json"
  fi
  ln -s "$DOTFILES_DIR/vscode_settings.json" "$VSCODE_USER_DIR/settings.json"
}

installAndStartMongoDB() {
  wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
  echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
  sudo apt-get update
  sudo apt-get install -y mongodb-org
  sudo systemctl enable mongod
  sudo systemctl start mongod
}

mountSecretDrive() {
  # the folder where this script is located (your USB stick)
  USB_BASE_DIR="$(cd "$(dirname "$PWD")" && pwd)"
  DEB_FILE="veracrypt-1.26.24-Ubuntu-20.04-amd64.deb"
  SECRET_FILE="$USB_BASE_DIR/secret"
  MOUNT_POINT="/media/veracrypt1"

  # Cleanup on exit
  cleanup() {
    if mount | grep -q "$MOUNT_POINT"; then
      echo "Unmounting VeraCrypt container..."
      veracrypt -d "$MOUNT_POINT" >/dev/null 2>&1 || true
    fi
  }
  trap cleanup EXIT

  # install veracrypt
  INSTALL_FILE="$USB_BASE_DIR/$DEB_FILE"
  if ! command -v veracrypt &> /dev/null; then
    echo "Installing VeraCrypt..."
    sudo dpkg -i "$INSTALL_FILE" || sudo apt-get -f install -y
  else
    echo "VeraCrypt already installed."
  fi

  # create the mount point - use the same mount point VeraCrypt GUI would use
  if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
    sudo chown "$USER":"$USER" "$MOUNT_POINT"
  fi

  # mount the secret drive 
  if mount | grep -q "$MOUNT_POINT"; then
    echo "Secret container already mounted at $MOUNT_POINT."
  else
    echo "Mounting secret container..."
    veracrypt --text --pim=0 --keyfiles="" --protect-hidden=no --mount "$SECRET_FILE" "$MOUNT_POINT"
  fi
}

configureSecrets() {
  # mount our secret drive and copy the keys into the .ssh directory
  mountSecretDrive

  # make sure we have our .ssh directory
  if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
    echo "Created $HOME/.ssh directory."
  else
    echo "$HOME/.ssh directory already exists."
  fi

  # configure our .ssh directory with the secrets from the USB stick
  cp "$MOUNT_POINT"/secrets/ssh/* ~/.ssh/
  echo "Copied SSH secrets to ~/.ssh/"
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_*
  chmod 644 ~/.ssh/id_*.pub
  chmod 644 ~/.ssh/known_hosts
  chmod 644 ~/.ssh/config
}

# bootstrap a linux machine
bootstrapLinux() {
  # install developer essentials
  sudo apt update
  sudo apt install -y zsh tmux git curl build-essential direnv
  sudo apt install -y wget gpg apt-transport-https software-properties-common

  echo "Install and configure Node..."
  installNode

  echo "Setting up home directory dot files..."
  configureDotFiles

  echo "Install and configure VS Code..."
  installAndConfigureVSCode

  # make zsh the default shell 
  if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s "$(which zsh)"
  else
    echo "Default shell is already zsh."
  fi

  echo "Install and start the Mongo DB..."
  installAndStartMongoDB

  echo "Set up our secrets..."
  configureSecrets
}


# bootstrap a mac machine
bootstrapMac() {
  echo "Bootstrapping macOS is not implemented yet..."
  # # Install Homebrew if not already installed
  # if ! command -v brew &>/dev/null; then
  #   echo "Installing Homebrew..."
  #   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # else
  #   echo "Homebrew already installed"
  # fi

  # # Add Homebrew to PATH for the current session
  # if [[ -d "/opt/homebrew/bin" ]]; then
  #   eval "$(/opt/homebrew/bin/brew shellenv)"
  # elif [[ -d "/usr/local/bin" ]]; then
  #   eval "$(/usr/local/bin/brew shellenv)"
  # fi

  # echo "Updating Homebrew..."
  # brew update

  # # # Install developer essentials
  # brew install tmux git direnv wget gnupg

  # # nvm (node version manager)
  # echo "Installing Node Version Manager..."
  # if [ ! -d "$HOME/.nvm" ]; then
  #   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
  # else
  #   echo "Node Version Manager already installed"
  # fi
  # export NVM_DIR="$HOME/.nvm"
  # [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  # [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  # # wr use node version 16 as default
  # nvm install 16
  # nvm alias default 16
  # nvm use default

  # # Install VS Code
  # if ! command -v code &>/dev/null; then
  #   echo "Installing VS Code..."
  #   brew install --cask visual-studio-code
  # else
  #   echo "VS Code already installed"
  # fi

  # # create symlinks for the .dot files 
  # echo "Creating symbolic links for dotfiles..."
  # DOTFILES_DIR="$HOME/.dotfiles"
  # FILES_TO_LINK=(
  #   ".gitconfig:$DOTFILES_DIR/.gitconfig"
  #   ".zprofile:$DOTFILES_DIR/.zprofile"
  #   ".zshrc:$DOTFILES_DIR/.zshrc"
  #   ".tmux.conf:$DOTFILES_DIR/config/tmux.conf"
  # )

  # for entry in "${FILES_TO_LINK[@]}"; do
  #   file="${entry%%:*}"     # left side before :
  #   target="${entry##*:}"   # right side after :
  #   link="$HOME/$file"
  #   if [ -e "$link" ] || [ -L "$link" ]; then
  #       echo "Backing up existing $link to $link.bak"
  #       mv "$link" "$link.bak"
  #   fi
  #   echo "Creating symlink: $link -> $target"
  #   ln -s "$target" "$link"
  # done

  # # # Install VS Code extensions
  # if [ -f "vscode-extensions.txt" ]; then
  #   echo "Installing VS Code extensions..."
  #   cat vscode-extensions.txt | xargs -n 1 code --install-extension
  # else
  #   echo "No vscode-extensions.txt file found; skipping extensions."
  # fi


  # # # symlink the default Visual Studio Code settings file
  # echo "Creating symbolic link for the default Visual Studio Code settings file..."
  # VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
  # mkdir -p "$VSCODE_USER_DIR"
  # if [ -L "$VSCODE_USER_DIR/settings.json" ]; then
  #     mv "$VSCODE_USER_DIR/settings.json" "$VSCODE_USER_DIR/settings.json.bak"
  # fi
  # if [ -e "$VSCODE_USER_DIR/settings.json" ] || [ -L "$VSCODE_USER_DIR/settings.json" ]; then
  #     rm -f "$VSCODE_USER_DIR/settings.json"
  # fi
  # ln -s "$DOTFILES_DIR/config/Code/User/settings.json" "$VSCODE_USER_DIR/settings.json"

  # # # Install MongoDB 4.4
  # # echo "Installing MongoDB 4.4..."
  # # brew install mongodb-community@4.4

  # # make sure our .ssh directory has correct permissions 
  # echo "Setting permissions for .ssh directory..."
  # chmod 700 ~/.ssh
  # chmod 600 ~/.ssh/id_*
  # chmod 644 ~/.ssh/id_*.pub
  # chmod 644 ~/.ssh/known_hosts
  # chmod 644 ~/.ssh/config
}

# try to bootstrap our new machine
if [ "$OSTYPE" == "linux-gnu" ]; then
  echo "Detected Linux"
  bootstrapLinux
elif [[ "$OSTYPE" == darwin* ]]; then
  echo "Detected macOS"
  bootstrapMac
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

