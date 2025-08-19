#!/usr/bin/env bash

# detect OS

if [ "$OSTYPE" == "darwin" ]; then
    echo "Detected macOS"

elif [ "$OSTYPE" == "linux-gnu" ]; then
    echo "Detected Linux"

    # install developer essentials
    sudo apt update
    sudo apt install -y git curl build-essential
    sudo apt install -y wget gpg apt-transport-https software-properties-common


    # nvm (node version manager) is used to install/use different versions of node
    if ! command -v nvm &>/dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    fi

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
    set -e

    echo "Creating symbolic links for dotfiles..."
    DOTFILES_DIR="$HOME/.dotfiles"
    declare -A FILES_TO_LINK=(
        [".gitconfig"]="$DOTFILES_DIR/.gitconfig"
        [".bashrc"]="$DOTFILES_DIR/.bashrc"
        [".profile"]="$DOTFILES_DIR/.profile"
        [".zprofile"]="$DOTFILES_DIR/.zprofile"
        [".zshrc"]="$DOTFILES_DIR/.zshrc"
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

else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

