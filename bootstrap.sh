#!/usr/bin/env bash

set -e

if [[ "$OSTYPE" == darwin* ]]; then
  echo "Detected macOS"

  # Install Homebrew if not already installed
  if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew already installed"
  fi

  # Add Homebrew to PATH for the current session
  if [[ -d "/opt/homebrew/bin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d "/usr/local/bin" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  echo "Updating Homebrew..."
  brew update

  # # Install developer essentials
  brew install tmux git direnv wget gnupg

  # nvm (node version manager)
  echo "Installing Node Version Manager..."
  if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
  else
    echo "Node Version Manager already installed"
  fi
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  # wr use node version 16 as default
  nvm install 16
  nvm alias default 16
  nvm use default

  # Install VS Code
  if ! command -v code &>/dev/null; then
    echo "Installing VS Code..."
    brew install --cask visual-studio-code
  else
    echo "VS Code already installed"
  fi

  # # Install VS Code extensions
  if [ -f "vscode-extensions.txt" ]; then
    echo "Installing VS Code extensions..."
    cat vscode-extensions.txt | xargs -n 1 code --install-extension
  else
    echo "No vscode-extensions.txt file found; skipping extensions."
  fi

  # create symlinks for the .dot files 
  echo "Creating symbolic links for dotfiles..."
  DOTFILES_DIR="$HOME/.dotfiles"
  FILES_TO_LINK=(
    ".gitconfig:$DOTFILES_DIR/.gitconfig"
    ".zprofile:$DOTFILES_DIR/.zprofile"
    ".zshrc:$DOTFILES_DIR/.zshrc"
    ".tmux.conf:$DOTFILES_DIR/config/tmux.conf"
  )

  for entry in "${FILES_TO_LINK[@]}"; do
      file="${entry%%:*}"     # left side before :
      target="${entry##*:}"   # right side after :
      link="$HOME/$file"
      if [ -e "$link" ] || [ -L "$link" ]; then
          echo "Backing up existing $link to $link.bak"
          mv "$link" "$link.bak"
      fi
      echo "Creating symlink: $link -> $target"
      ln -s "$target" "$link"
  done

  # # symlink the default Visual Studio Code settings file
  echo "Creating symbolic link for the default Visual Studio Code settings file..."
  VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
  mkdir -p "$VSCODE_USER_DIR"
  if [ -L "$VSCODE_USER_DIR/settings.json" ]; then
      mv "$VSCODE_USER_DIR/settings.json" "$VSCODE_USER_DIR/settings.json.bak"
  fi
  if [ -e "$VSCODE_USER_DIR/settings.json" ] || [ -L "$VSCODE_USER_DIR/settings.json" ]; then
      rm -f "$VSCODE_USER_DIR/settings.json"
  fi
  ln -s "$DOTFILES_DIR/config/Code/User/settings.json" "$VSCODE_USER_DIR/settings.json"

  # make sure our .ssh directory has correct permissions 
  echo "Setting permissions for .ssh directory..."
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_*
  chmod 644 ~/.ssh/id_*.pub
  chmod 644 ~/.ssh/known_hosts
  chmod 644 ~/.ssh/config

  # # Install MongoDB 4.4
  # echo "Installing MongoDB 4.4..."
  # brew install mongodb-community@4.4

elif [ "$OSTYPE" == "linux-gnu" ]; then
    echo "Detected Linux"

    # install developer essentials
    sudo apt update
    sudo apt install -y zsh tmux git curl build-essential direnv
    sudo apt install -y wget gpg apt-transport-https software-properties-common


    # nvm (node version manager) is used to install/use different versions of node
    if [ ! -d "$HOME/.nvm" ]; then
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


    # Install VS Code
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


    # create symlinks for the .dot files 
    echo "Creating symbolic links for dotfiles..."
    DOTFILES_DIR="$HOME/.dotfiles"
    declare -A FILES_TO_LINK=(
        [".gitconfig"]="$DOTFILES_DIR/.gitconfig"
        [".bashrc"]="$DOTFILES_DIR/.bashrc"
        [".profile"]="$DOTFILES_DIR/.profile"
        [".zprofile"]="$DOTFILES_DIR/.zprofile"
        [".zshrc"]="$DOTFILES_DIR/.zshrc"
        [".tmux.conf"]="$DOTFILES_DIR/config/tmux.conf"
    )
    for file in "${!FILES_TO_LINK[@]}"; do
        target="${FILES_TO_LINK[$file]}"
        link="$HOME/$file"
        # Backup existing file if it exists
        if [ -e "$link" ] || [ -L "$link" ]; then
            echo "Backing up existing $link to $link.bak"
            mv "$link" "$link.bak"
        fi
        echo "Creating symlink: $link -> $target"
        ln -s "$target" "$link"
    done


    # symlink the default Visual Studio Code settings file
    if [ -L "$HOME/.config/Code/User/settings.json" ]; then
        mv "$HOME/.config/Code/User/settings.json" "$HOME/.config/Code/User/settings.json.bak"
    fi
    ln -s "$DOTFILES_DIR/config/Code/User/settings.json" "$HOME/.config/Code/User/settings.json"


    # make zsh the default shell 
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Changing default shell to zsh..."
        chsh -s "$(which zsh)"
    else
        echo "Default shell is already zsh."
    fi


    # install mongodb 
    wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    sudo apt-get update
    sudo apt-get install -y mongodb-org


    # Enable and start MongoDB as a service
    sudo systemctl enable mongod
    sudo systemctl start mongod

    # make sure our .ssh directory has correct permissions 
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_*
    chmod 644 ~/.ssh/id_*.pub
    chmod 644 ~/.ssh/known_hosts
    chmod 644 ~/.ssh/config

else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

