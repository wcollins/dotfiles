#!/usr/bin/env bash

set -e

################################################################################
# setup.sh
#
# Symlinks dotfiles into place using GNU Stow.
# Idempotent - safe to run multiple times.
#
# Usage: ./setup.sh [OPTIONS]
#
# Options:
#   --dry-run    Show what would be done without making changes
#   --help       Show this help message
################################################################################

DRY_RUN=false
DOTFILES="${HOME}/dotfiles"

show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Sets up dotfiles using GNU Stow for symlink management.
Safe to run multiple times.

Options:
  --dry-run    Preview changes without applying them
  --help       Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --help) show_help; exit 0 ;;
    *) echo "Unknown option: $1"; show_help; exit 1 ;;
  esac
done

info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1" >&2; }
error() { printf "[ERROR] %s\n" "$1" >&2; }

run_cmd() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    info "[DRY RUN] Would run: $1"
  else
    info "Running: $1"
    eval "$1"
  fi
}

backup_conflict() {
  local path="$1"
  local backup="${path}_$(date +%Y-%m-%d)_$(date +%s)"
  if [[ "${DRY_RUN}" == "true" ]]; then
    info "[DRY RUN] Would backup $path to $backup"
  else
    warn "Conflict: $path -> backing up to $backup"
    mv -v "$path" "$backup"
  fi
}

main() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    printf "\n[DOTFILES] DRY RUN MODE - No changes will be made\n\n"
  fi

  printf "\n[DOTFILES] Initializing dotfiles setup...\n\n"

  # Prerequisites
  local osname
  osname=$(uname)
  if [ "${osname}" != "Darwin" ]; then
    error "This script only supports macOS (got: ${osname})"
    exit 1
  fi

  if ! command -v stow >/dev/null; then
    error "GNU Stow required. Install with: brew install stow"
    exit 1
  fi

  info "Prerequisites OK"

  # Create directories
  for dir in "${HOME}/.config" "${HOME}/.local/bin" "${HOME}/.ssh/keys"; do
    if [ ! -d "$dir" ]; then
      run_cmd "mkdir -p '$dir'"
    fi
  done

  # Handle conflicts
  printf "\n[DOTFILES] Checking for stow conflicts...\n\n"

  local stow_conflicts=(
    ".config/ghostty"
    ".config/nvim"
    ".config/starship.toml"
    ".config/tmux"
    ".config/zsh"
    ".gitconfig"
    ".gitignore_global"
    ".local/bin/secrets"
    ".gitmessage"
    ".zshrc"
  )

  local conflicts_found=0
  for item in "${stow_conflicts[@]}"; do
    local target="${HOME}/${item}"
    if [ -L "${target}" ]; then
      # Remove stale symlinks not managed by stow
      local link_dest
      link_dest=$(readlink "${target}")
      if [[ "${link_dest}" != *"dotfiles/${item%%/*}"* ]] && [[ "${link_dest}" != "../dotfiles/"* ]] && [[ "${link_dest}" != "dotfiles/"* ]]; then
        conflicts_found=$((conflicts_found + 1))
        backup_conflict "${target}"
      fi
    elif [ -e "${target}" ]; then
      conflicts_found=$((conflicts_found + 1))
      backup_conflict "${target}"
    fi
  done

  if [[ ${conflicts_found} -eq 0 ]]; then
    info "No conflicts detected"
  else
    info "Handled ${conflicts_found} conflicts"
  fi

  # Stow packages
  printf "\n[DOTFILES] Setting up symlinks with GNU Stow...\n\n"

  if [[ "${DRY_RUN}" == "false" ]]; then
    cd "${DOTFILES}"
  fi

  local packages=0
  local failed=0
  for item in ghostty git nvim secrets starship tmux zsh; do
    if [ -d "${DOTFILES}/${item}" ]; then
      packages=$((packages + 1))
      if [[ "${DRY_RUN}" == "true" ]]; then
        info "[DRY RUN] Would stow: ${item}"
      else
        if ! stow "${item}" 2>&1; then
          warn "Failed to stow: ${item}"
          failed=$((failed + 1))
        else
          info "Stowed: ${item}"
        fi
      fi
    fi
  done

  info "Processed ${packages} stow packages"
  if [[ ${failed} -gt 0 ]]; then
    warn "${failed} package(s) failed to stow - check conflicts above"
  fi

  # Git identity and SSH signing
  printf "\n[DOTFILES] Configuring git identity...\n\n"

  if [[ "${DRY_RUN}" == "true" ]]; then
    info "[DRY RUN] Would run: scripts/git-setup.sh"
  else
    if [[ -f "${DOTFILES}/scripts/git-setup.sh" ]]; then
      bash "${DOTFILES}/scripts/git-setup.sh"
    else
      warn "scripts/git-setup.sh not found, skipping git setup"
    fi
  fi

  # Tmux Plugin Manager
  if command -v tmux &>/dev/null; then
    if [ ! -d "${DOTFILES}/tmux/.config/tmux/plugins/tpm" ]; then
      printf "\n[DOTFILES] Installing Tmux Plugin Manager...\n\n"
      run_cmd "git clone https://github.com/tmux-plugins/tpm '${DOTFILES}/tmux/.config/tmux/plugins/tpm'"
    else
      info "TPM already installed"
    fi
  fi

  printf "\n[DOTFILES] Setup complete!\n\n"

  echo "Next steps:"
  echo "  -> Install Zap: https://www.zapzsh.com"
  echo "  -> Install packages: brew bundle install --file=${DOTFILES}/brew/Brewfile"
  echo "  -> Install Tmux plugins: <prefix> + I"
  echo "  -> Create ~/.zshrc.local for machine-specific overrides"
  echo "  -> Create ~/.secrets with OP_SERVICE_ACCOUNT_TOKEN for 1Password"
  echo "  -> Run 'secrets --load' to configure vault/item and populate ~/.vars"
  echo ""
}

trap 'error "Script failed at line $LINENO"' ERR
main "$@"
