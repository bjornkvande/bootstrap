PROMPT='%m:%~ %% '

# Set history options
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt append_history

# some ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Load global environment variables (optional)
[ -f ~/.env ] && source ~/.env