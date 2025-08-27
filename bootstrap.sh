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
#  3) Set up dot files for bash, zsh, git, and tmux 
#  4) Install and configure VS Code
#  5) Populate the .ssh directory with my keys
#  6) Install the node version manager and node 16
#  7) Check out my projects and populate with the keys I need
#  8) Install and start mongodb
#  9) Make zsh the default shell

set -e

source "$(dirname "$0")/core.sh"

# Cleanup on exit
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  trap unmountDriveOnCleanup EXIT
fi


DOTFILES_DIR="$HOME/.dotfiles"

installDeveloperEssentialsTools() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt update
    sudo apt install -y zsh tmux git curl build-essential direnv
    sudo apt install -y wget gpg apt-transport-https software-properties-common
  elif [[ "$OSTYPE" == darwin* ]]; then
    # homebrew is the equivalent of apt on mac
    echo "Installing homebrew..."
    if ! command -v brew &>/dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      echo "Homebrew already installed"
    fi
    if [[ -d "/opt/homebrew/bin" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d "/usr/local/bin" ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi

    echo "Updating homebrew..."
    brew update

    echo "Installing tmux git direnv wget gnupg..."
    brew install tmux git direnv wget gnupg
  fi
}

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

installVSCode() {
  # install VS code
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Adding Microsoft repository for VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
    sudo sh -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo apt update -y
    echo "Installing VS Code..."
    sudo apt install -y code
  elif [[ "$OSTYPE" == darwin* ]]; then
    if ! command -v code &>/dev/null; then
      echo "Installing VS Code..."
      brew install --cask visual-studio-code
    else
      echo "VS Code already installed"
    fi
  fi

  # install extensions
  if [ -f "vscode-extensions.txt" ]; then
    echo "Installing VS Code extensions..."
    # Clean the file: remove empty lines and trim spaces
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      sed -i '/^$/d;s/^[ \t]*//;s/[ \t]*$//' vscode-extensions.txt
    fi
    # Install each extension
    cat vscode-extensions.txt | xargs -n 1 code --install-extension
  else
    echo "No vscode-extensions.txt file found; skipping extensions."
  fi

  # set default configuration
  echo "Setting default configuration for VS Code..."
  cp "vscode_settings.json" "$DOTFILES_DIR"
  VSCODE_USER_DIR="$HOME/.config/Code/User"
  if [[ "$OSTYPE" == darwin* ]]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
  fi
  mkdir -p "$VSCODE_USER_DIR"
  if [ -e "$VSCODE_USER_DIR/settings.json" ] || [ -L "$VSCODE_USER_DIR/settings.json" ]; then
    rm -f "$VSCODE_USER_DIR/settings.json"
  fi
  ln -s "$DOTFILES_DIR/vscode_settings.json" "$VSCODE_USER_DIR/settings.json"
}

configureSecrets() {
  # mount our secret drive with the keys
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    mountSecretDrive
  fi

  # make sure we have our .ssh directory
  if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
    echo "Created $HOME/.ssh directory."
  else
    echo "$HOME/.ssh directory already exists."
  fi

  # configure our .ssh directory with the secrets from the USB stick
  MOUNT_POINT="/media/veracrypt1"
  if [[ "$OSTYPE" == darwin* ]]; then
    MOUNT_POINT="/Volumes/BJORN_DEV_MAC"
  fi

  cp "$MOUNT_POINT"/secrets/ssh/* ~/.ssh/
  echo "Copied SSH secrets to ~/.ssh/"
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_*
  chmod 644 ~/.ssh/id_*.pub
  chmod 644 ~/.ssh/known_hosts
  chmod 644 ~/.ssh/config
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
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo setcap 'cap_net_bind_service=+ep' "$(which node)"
  fi
}

checkoutProjects() {
  echo "Cloning my projects..."

  PROJECTS=(
    "kvande"
    "trailguide"
    "sjogg"
    "skiguide"
    "trailguide.no"
    "kvande.com"
  ) 

  # make sure the projects directory exists 
  PROJECTS_DIR="$HOME/projects"
  if [ ! -d "$PROJECTS_DIR" ]; then
    echo "Creating $PROJECTS_DIR"
    mkdir -p "$PROJECTS_DIR"
  fi

  # check out the projects if not already checked out
  for project in "${PROJECTS[@]}"; do
    PROJECT_PATH="$PROJECTS_DIR/$project"
    if [ ! -d "$PROJECT_PATH" ]; then
      echo "Cloning $project..."
      git clone "git@github.com:bjornkvande/$project.git" "$PROJECT_PATH"
    else
      echo "$project is already checked out."
    fi

    # Check for submodules and init/update if present
    if [ -f "$PROJECT_PATH/.gitmodules" ]; then
      echo "Syncing and initializing submodules for $project..."
      (
        cd "$PROJECT_PATH"
        git submodule sync --recursive
        git submodule update --init --recursive
      )
    fi
  done

  # use the development branch and prepare keys and secrets for the trailguide project
  if [ -d "$PROJECTS_DIR/trailguide" ]; then
    echo "Checking out the development branch of trailguide..."
    (
      cd "$PROJECTS_DIR/trailguide"
      if git show-ref --verify --quiet refs/heads/development || git ls-remote --exit-code --heads origin development &>/dev/null; then
        echo "Checking out 'development' branch in trailguide..."
        git fetch origin development
        git checkout development
        git pull origin development
      else
        echo "'development' branch does not exist in trailguide."
      fi
    )

    # copy the secrets we need
    MOUNT_POINT="/media/veracrypt1"
    if [[ "$OSTYPE" == darwin* ]]; then
      MOUNT_POINT="/Volumes/BJORN_DEV_MAC"
    fi
    cp "$MOUNT_POINT"/secrets/trailguide/.envrc "$PROJECTS_DIR/trailguide/.envrc"
    cp "$MOUNT_POINT"/secrets/trailguide/google_credentials.json \
       "$PROJECTS_DIR/trailguide/source/server/google_credentials.json"
  fi
}

installAndStartMongoDB() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    sudo apt-get update
    sudo apt-get install -y mongodb-org
    sudo systemctl enable mongod
    sudo systemctl start mongod
  elif [[ "$OSTYPE" == darwin* ]]; then
    echo "Installing MongoDB on Mac is not implemented yet..."
    # # # Install MongoDB 4.4
    # # echo "Installing MongoDB 4.4..."
    # # brew install mongodb-community@4.4
  fi
}

bootstrap() {
  if [[ "$OSTYPE" == "linux-gnu" || "$OSTYPE" == "darwin"* ]]; then
    echo "Installing developer essentials..."
    installDeveloperEssentialsTools

    echo "Setting up home directory dot files..."
    configureDotFiles

    echo "Install and configure VS Code..."
    installVSCode

    echo "Set up our secrets..."
    configureSecrets

    echo "Install and configure Node..."
    installNode

    echo "Checkout my projects..."
    checkoutProjects

    echo "Install and start the Mongo DB..."
    installAndStartMongoDB

    # make zsh the default shell 
    if [ "$SHELL" != "$(which zsh)" ]; then
      echo "Changing default shell to zsh..."
      chsh -s "$(which zsh)"
    else
      echo "Default shell is already zsh."
    fi
  else
    echo "Unsupported OS: $OSTYPE"
    exit 1
  fi
}

# try to bootstrap our new machine
bootstrap