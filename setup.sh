#!/usr/bin/env bash

set -euo pipefail

################################################################################
# setup.sh
#
# Symlinks dotfiles into place using GNU Stow.
# Idempotent - safe to run multiple times.
#
# Usage: ./setup.sh [OPTIONS]
#
# Options:
#   --profile PROFILE  Linux profile: server (default), desktop, wsl
#   --dry-run          Show what would be done without making changes
#   --help             Show this help message
################################################################################

DRY_RUN=false
DOTFILES="${HOME}/dotfiles"
OS=$(uname -s)
PROFILE=""

show_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Sets up dotfiles using GNU Stow for symlink management.
Safe to run multiple times. Supports macOS and Debian Linux.

Options:
  --profile PROFILE  Linux profile: server (default), desktop, wsl
  --dry-run          Preview changes without applying them
  --help             Show this help message

Profiles:
  macos    Auto-detected on macOS (do not set manually)
  server   Headless Linux — CLI tools only (default on Linux)
  desktop  Linux with GUI — includes Ghostty config and fonts
  wsl      Windows Subsystem for Linux — same as server

Examples:
  ./setup.sh                       # macOS (auto-detected)
  ./setup.sh --profile server      # Debian headless
  ./setup.sh --profile desktop     # Debian with GUI
  ./setup.sh --dry-run --profile server
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --profile) PROFILE="$2"; shift 2 ;;
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

# Resolve profile from OS and flags
resolve_profile() {
  if [[ "${OS}" == "Darwin" ]]; then
    if [[ -n "${PROFILE}" && "${PROFILE}" != "macos" ]]; then
      error "--profile is not supported on macOS"
      exit 1
    fi
    PROFILE="macos"
  elif [[ -z "${PROFILE}" ]]; then
    PROFILE="server"
  fi

  case "${PROFILE}" in
    macos|server|desktop|wsl) ;;
    *) error "Invalid profile: ${PROFILE}. Must be: server, desktop, or wsl"; exit 1 ;;
  esac
}

main() {
  resolve_profile

  if [[ "${DRY_RUN}" == "true" ]]; then
    printf "\n[DOTFILES] DRY RUN MODE - No changes will be made\n\n"
  fi

  printf "\n[DOTFILES] Initializing dotfiles setup (os=%s, profile=%s)...\n\n" "${OS}" "${PROFILE}"

  # Prerequisites
  if ! command -v stow >/dev/null; then
    if [[ "${OS}" == "Darwin" ]]; then
      error "GNU Stow required. Install with: brew install stow"
    else
      error "GNU Stow required. Install with: sudo apt install stow"
    fi
    exit 1
  fi

  info "Prerequisites OK"

  # Install packages on Debian
  if [[ "${OS}" == "Linux" && "${PROFILE}" != "macos" ]]; then
    printf "\n[DOTFILES] Installing packages for Debian (%s)...\n\n" "${PROFILE}"
    if [[ -f "${DOTFILES}/scripts/install-packages.sh" ]]; then
      if [[ "${DRY_RUN}" == "true" ]]; then
        info "[DRY RUN] Would run: scripts/install-packages.sh --profile ${PROFILE}"
      else
        bash "${DOTFILES}/scripts/install-packages.sh" --profile "${PROFILE}"
      fi
    else
      warn "scripts/install-packages.sh not found, skipping package installation"
    fi
  fi

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

  # Stow packages (profile-based selection)
  printf "\n[DOTFILES] Setting up symlinks with GNU Stow...\n\n"

  if [[ "${DRY_RUN}" == "false" ]]; then
    cd "${DOTFILES}"
  fi

  local core_packages=(git nvim secrets starship tmux zsh)
  local gui_packages=(ghostty)
  local stow_packages=()

  case "${PROFILE}" in
    macos|desktop) stow_packages=("${core_packages[@]}" "${gui_packages[@]}") ;;
    server|wsl)    stow_packages=("${core_packages[@]}") ;;
  esac

  local packages=0
  local failed=0
  for item in "${stow_packages[@]}"; do
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

  # Platform-aware next steps
  printf "\n[DOTFILES] Setup complete!\n\n"

  echo "Next steps:"
  echo "  -> Install Zap: https://www.zapzsh.com"
  if [[ "${PROFILE}" == "macos" ]]; then
    echo "  -> Install packages: brew bundle install --file=${DOTFILES}/brew/Brewfile"
  fi
  echo "  -> Install Tmux plugins: <prefix> + I"
  echo "  -> Create ~/.zshrc.local for machine-specific overrides"
  echo "  -> Create ~/.secrets with OP_SERVICE_ACCOUNT_TOKEN for 1Password"
  echo "  -> Run 'secrets --load' to configure vault/item and populate ~/.vars"
  if [[ "${PROFILE}" == "desktop" ]]; then
    echo "  -> Build Ghostty from source: https://github.com/ghostty-org/ghostty"
  fi
  echo ""
}

trap 'error "Script failed at line $LINENO"' ERR
main "$@"
