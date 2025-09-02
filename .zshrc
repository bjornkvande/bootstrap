# configure the prompt
if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(starship init zsh)"
else
  PROMPT='%m:%~ %% '
fi

# Set block cursor (default)
echo -ne "\e[2 q"

# Set history options
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt append_history hist_ignore_dups

# Completion
autoload -Uz compinit
compinit

# mongodb alias for old version (v2.6.5)
alias mongodb='sudo /usr/local/mongo/bin/mongod --dbpath /Users/bjornjarle/data/db'

# direnv is used to set project-specific environment variables such as credentials
eval "$(direnv hook zsh)"

# Load global environment variables (optional)
[ -f ~/.env ] && source ~/.env

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Add Homebrew to PATH only on Mac Silicon (Apple M1/M2)
if [[ "$(uname)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
  export PATH="/opt/homebrew/bin:$PATH"
fi

# our old mongo 
if [[ "$(uname)" == "Darwin" ]]; then
  export PATH=/usr/local/mongo/bin:$PATH
fi

if [ -f "$HOME/.dotfiles/.aliases" ]; then
  source "$HOME/.dotfiles/.aliases"
fi