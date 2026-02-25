# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# ls replacements (eza)
if command -v eza &>/dev/null; then
  alias ll="eza -la --git"
  alias lt="eza -la --tree --level=2"
else
  alias ll="ls -la"
fi

# cat replacement (bat)
if command -v bat &>/dev/null; then
  alias cat="bat --paging=never --plain"
fi

# Git
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit -v"
alias gd="git diff"
alias gdc="git diff --cached"
alias gl="git log --oneline -20"
alias gp="git push"
alias gpl="git pull"
alias gco="git checkout"
alias gb="git branch"
alias gf="git fetch"

# Editor
alias v="nvim"
alias vi="nvim"
alias vim="nvim"

# Tmux
alias ta="tmux attach -t"
alias tn="tmux new -s"
alias tl="tmux list-sessions"
alias tk="tmux kill-session -t"
ts() {
  if [ -z "$1" ]; then
    tmux list-sessions 2>/dev/null || echo "No sessions"
    return
  fi
  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$1" 2>/dev/null || \
      { tmux new-session -d -s "$1" && tmux switch-client -t "$1"; }
  else
    tmux attach -t "$1" 2>/dev/null || \
      tmux new-session -s "$1"
  fi
}

# Misc
alias reload="source ~/.zshrc"
alias path='echo $PATH | tr ":" "\n"'
alias weather="curl wttr.in"

# Claude
alias crun="claude --dangerously-skip-permissions"
