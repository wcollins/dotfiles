#!/usr/bin/env bash
#
# Shared environment variables
#
# Usage: source ~/dotfiles/shared/environment.sh

# BSD ls colors
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Editor
export EDITOR="nvim"
export GIT_EDITOR="nvim"
export BUNDLER_EDITOR="${EDITOR}"

# Manual pages
export MANPAGER="less -X"

# Homebrew
export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# XDG Base Directory
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_STATE_HOME="${HOME}/.local/state"

# Dotfiles
export DOTFILES="${HOME}/dotfiles"


# FZF
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --no-ignore-vcs"
export FZF_DEFAULT_OPTS="--height 75% --layout=reverse --border"
export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
export FZF_ALT_C_COMMAND="fd --type d . --color=never"
