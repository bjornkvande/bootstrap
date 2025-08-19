# Ensure PATH includes user binaries before system ones
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# Load environment variables (if you have a global ~/.env)
[ -f "$HOME/.env" ] && source "$HOME/.env"