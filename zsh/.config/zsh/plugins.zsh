# Zsh plugins via Zap
# Install: https://www.zapzsh.com
# Usage: plug "author/plugin"

if [[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ]]; then
  source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

  plug "zsh-users/zsh-autosuggestions"
  plug "zsh-users/zsh-syntax-highlighting"
  plug "zsh-users/zsh-completions"
fi
