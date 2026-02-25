# Homebrew
if [[ "$(arch)" == arm64 ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"

# mise (runtime version manager)
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# Shared environment variables
source "$HOME/dotfiles/shared/environment.sh"

# Zsh config modules
. "$XDG_CONFIG_HOME/zsh/plugins.zsh"
. "$XDG_CONFIG_HOME/zsh/aliases.zsh"
. "$XDG_CONFIG_HOME/zsh/functions.zsh"

# Secrets-managed variables
[[ -f "$HOME/.vars" ]] && . "$HOME/.vars"

# Local overrides (not tracked in git)
[[ -f "$HOME/.zshrc.local" ]] && . "$HOME/.zshrc.local"

# History
export HISTSIZE=1000000000
export SAVEHIST=1000000000
export HISTFILE=~/.zsh_history

setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Homebrew completions
if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# Completion system with caching
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-${HOME}}"/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# De-dupe $PATH
typeset -U path

# Starship prompt
eval "$(starship init zsh)"

# zoxide (smarter cd)
eval "$(zoxide init zsh)"

# fzf key bindings and completion
[[ -f "${HOMEBREW_PREFIX}/opt/fzf/shell/key-bindings.zsh" ]] && source "${HOMEBREW_PREFIX}/opt/fzf/shell/key-bindings.zsh"
[[ -f "${HOMEBREW_PREFIX}/opt/fzf/shell/completion.zsh" ]] && source "${HOMEBREW_PREFIX}/opt/fzf/shell/completion.zsh"
