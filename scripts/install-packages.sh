#!/usr/bin/env bash
#
# install-packages.sh - install CLI tools on Debian/Ubuntu
#
# Called by setup.sh on Linux. Installs apt packages and tools that need
# alternative installation methods (AppImage, installer scripts, etc.).
#
# Usage: install-packages.sh --profile <server|desktop|wsl>

set -euo pipefail

info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1" >&2; }
error() { printf "[ERROR] %s\n" "$1" >&2; }

PROFILE=""
ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)

# Normalize architecture names for GitHub releases
case "${ARCH}" in
  amd64|x86_64)  ARCH_GO="amd64"; ARCH_RUST="x86_64"; ARCH_GH="x86_64" ;;
  arm64|aarch64) ARCH_GO="arm64"; ARCH_RUST="aarch64"; ARCH_GH="arm64" ;;
  *) warn "Unsupported architecture: ${ARCH}"; ARCH_GO="${ARCH}"; ARCH_RUST="${ARCH}"; ARCH_GH="${ARCH}" ;;
esac

while [[ $# -gt 0 ]]; do
  case $1 in
    --profile) PROFILE="${2:-}"; shift 2 ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "${PROFILE}" ]]; then
  error "Usage: install-packages.sh --profile <server|desktop|wsl>"
  exit 1
fi

# Fetch latest GitHub release tag (strips leading 'v')
github_latest_version() {
  local repo="$1"
  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | grep '"tag_name"' | head -1 | sed -E 's/.*"v?([^"]+)".*/\1/'
}

# --- apt packages -----------------------------------------------------------

install_apt_packages() {
  info "Updating apt package lists..."
  sudo apt update -qq

  local packages=(
    bash
    bat
    btop
    cmake
    curl
    fd-find
    fzf
    gcc
    git
    htop
    jq
    less
    ripgrep
    shellcheck
    stow
    tmux
    tree
    wget
    zsh
    zoxide
  )

  info "Installing apt packages..."
  sudo apt install -y "${packages[@]}"
}

# --- Binary name symlinks ----------------------------------------------------

install_symlinks() {
  local bin_dir="${HOME}/.local/bin"
  mkdir -p "${bin_dir}"

  # batcat -> bat
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    ln -sf "$(command -v batcat)" "${bin_dir}/bat"
    info "Symlinked batcat -> bat"
  fi

  # fdfind -> fd
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    ln -sf "$(command -v fdfind)" "${bin_dir}/fd"
    info "Symlinked fdfind -> fd"
  fi
}

# --- Neovim (AppImage) ------------------------------------------------------

install_neovim() {
  if command -v nvim &>/dev/null; then
    local ver
    ver=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    local major minor
    major="${ver%%.*}"
    minor="${ver#*.}"
    if [[ "${major}" -gt 0 ]] || [[ "${minor}" -ge 9 ]]; then
      info "Neovim already installed (v${ver})"
      return
    fi
    warn "Neovim too old (v${ver}), upgrading via AppImage..."
  fi

  info "Installing Neovim AppImage..."
  local tmp
  tmp=$(mktemp -d)
  curl -fsSL -o "${tmp}/nvim.appimage" \
    "https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
  chmod +x "${tmp}/nvim.appimage"
  mv "${tmp}/nvim.appimage" "${HOME}/.local/bin/nvim"
  rm -rf "${tmp}"
  info "Neovim installed to ~/.local/bin/nvim"
}

# --- Starship ----------------------------------------------------------------

install_starship() {
  if command -v starship &>/dev/null; then
    info "Starship already installed"
    return
  fi
  info "Installing Starship..."
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "${HOME}/.local/bin"
}

# --- mise (runtime version manager) -----------------------------------------

install_mise() {
  if command -v mise &>/dev/null; then
    info "mise already installed"
    return
  fi
  info "Installing mise..."
  curl -fsSL https://mise.jdx.dev/install.sh | sh
}

# --- eza ---------------------------------------------------------------------

install_eza() {
  if command -v eza &>/dev/null; then
    info "eza already installed"
    return
  fi
  info "Installing eza..."
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
  sudo apt update -qq
  sudo apt install -y eza
}

# --- GitHub CLI --------------------------------------------------------------

install_gh() {
  if command -v gh &>/dev/null; then
    info "GitHub CLI already installed"
    return
  fi
  info "Installing GitHub CLI..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt update -qq
  sudo apt install -y gh
}

# --- 1Password CLI -----------------------------------------------------------

install_op() {
  if command -v op &>/dev/null; then
    info "1Password CLI already installed"
    return
  fi
  info "Installing 1Password CLI..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/1password.gpg
  echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/1password.gpg] https://downloads.1password.com/linux/debian/${ARCH} stable main" \
    | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
  sudo apt update -qq
  sudo apt install -y 1password-cli
}

# --- diff-so-fancy -----------------------------------------------------------

install_diff_so_fancy() {
  if command -v diff-so-fancy &>/dev/null; then
    info "diff-so-fancy already installed"
    return
  fi
  if ! command -v npm &>/dev/null; then
    warn "npm not found, skipping diff-so-fancy (install Node.js first via mise)"
    return
  fi
  info "Installing diff-so-fancy..."
  npm install -g diff-so-fancy
}

# --- lazygit -----------------------------------------------------------------

install_lazygit() {
  if command -v lazygit &>/dev/null; then
    info "lazygit already installed"
    return
  fi
  info "Installing lazygit..."
  local version
  version=$(github_latest_version "jesseduffield/lazygit")
  local tmp
  tmp=$(mktemp -d)
  curl -fsSL -o "${tmp}/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${ARCH_GH}.tar.gz"
  tar -xzf "${tmp}/lazygit.tar.gz" -C "${tmp}"
  mv "${tmp}/lazygit" "${HOME}/.local/bin/lazygit"
  rm -rf "${tmp}"
  info "lazygit installed to ~/.local/bin/lazygit"
}

# --- git-quick-stats ---------------------------------------------------------

install_git_quick_stats() {
  if command -v git-quick-stats &>/dev/null; then
    info "git-quick-stats already installed"
    return
  fi
  info "Installing git-quick-stats..."
  local tmp
  tmp=$(mktemp -d)
  git clone --depth 1 https://github.com/arzzen/git-quick-stats.git "${tmp}/gqs"
  cp "${tmp}/gqs/git-quick-stats" "${HOME}/.local/bin/git-quick-stats"
  chmod +x "${HOME}/.local/bin/git-quick-stats"
  rm -rf "${tmp}"
  info "git-quick-stats installed to ~/.local/bin/git-quick-stats"
}

# --- shfmt -------------------------------------------------------------------

install_shfmt() {
  if command -v shfmt &>/dev/null; then
    info "shfmt already installed"
    return
  fi
  info "Installing shfmt..."
  local version
  version=$(github_latest_version "mvdan/sh")
  curl -fsSL -o "${HOME}/.local/bin/shfmt" \
    "https://github.com/mvdan/sh/releases/download/v${version}/shfmt_v${version}_linux_${ARCH_GO}"
  chmod +x "${HOME}/.local/bin/shfmt"
  info "shfmt installed to ~/.local/bin/shfmt"
}

# --- tealdeer ----------------------------------------------------------------

install_tealdeer() {
  if command -v tldr &>/dev/null; then
    info "tealdeer already installed"
    return
  fi
  info "Installing tealdeer..."
  local version
  version=$(github_latest_version "tealdeer-rs/tealdeer")
  curl -fsSL -o "${HOME}/.local/bin/tldr" \
    "https://github.com/tealdeer-rs/tealdeer/releases/download/v${version}/tealdeer-linux-${ARCH_RUST}-musl"
  chmod +x "${HOME}/.local/bin/tldr"
  info "tealdeer installed to ~/.local/bin/tldr"
}

# --- yq ----------------------------------------------------------------------

install_yq() {
  if command -v yq &>/dev/null; then
    info "yq already installed"
    return
  fi
  info "Installing yq..."
  local version
  version=$(github_latest_version "mikefarah/yq")
  curl -fsSL -o "${HOME}/.local/bin/yq" \
    "https://github.com/mikefarah/yq/releases/download/v${version}/yq_linux_${ARCH_GO}"
  chmod +x "${HOME}/.local/bin/yq"
  info "yq installed to ~/.local/bin/yq"
}

# --- fastfetch ---------------------------------------------------------------

install_fastfetch() {
  if command -v fastfetch &>/dev/null; then
    info "fastfetch already installed"
    return
  fi
  info "Installing fastfetch..."
  local version
  version=$(github_latest_version "fastfetch-cli/fastfetch")
  local tmp
  tmp=$(mktemp -d)
  curl -fsSL -o "${tmp}/fastfetch.deb" \
    "https://github.com/fastfetch-cli/fastfetch/releases/download/${version}/fastfetch-linux-${ARCH_GO}.deb"
  sudo dpkg -i "${tmp}/fastfetch.deb" || sudo apt install -f -y
  rm -rf "${tmp}"
}

# --- Nerd Fonts (desktop only) -----------------------------------------------

install_fonts() {
  local font_dir="${HOME}/.local/share/fonts"
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    info "Nerd Fonts already installed"
    return
  fi

  info "Installing JetBrains Mono Nerd Font..."
  mkdir -p "${font_dir}"
  local tmp
  tmp=$(mktemp -d)

  # JetBrains Mono
  curl -fsSL -o "${tmp}/JetBrainsMono.tar.xz" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
  tar -xf "${tmp}/JetBrainsMono.tar.xz" -C "${font_dir}"

  # Symbols Only
  if curl -fsSL -o "${tmp}/NerdFontsSymbolsOnly.tar.xz" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz" 2>/dev/null; then
    tar -xf "${tmp}/NerdFontsSymbolsOnly.tar.xz" -C "${font_dir}" 2>/dev/null || true
  fi

  rm -rf "${tmp}"
  fc-cache -f "${font_dir}" 2>/dev/null || true
  info "Nerd Fonts installed to ${font_dir}"
}

# --- Main --------------------------------------------------------------------

main() {
  info "Installing packages for Debian (profile=${PROFILE})..."

  # Core apt packages
  install_apt_packages

  # Binary name symlinks (bat, fd)
  install_symlinks

  # Tools needing alternative install methods
  install_neovim
  install_starship
  install_mise
  install_eza
  install_gh
  install_op
  install_diff_so_fancy
  install_lazygit
  install_git_quick_stats
  install_shfmt
  install_tealdeer
  install_yq
  install_fastfetch

  # Desktop-only packages
  if [[ "${PROFILE}" == "desktop" ]]; then
    install_fonts
  fi

  info "Package installation complete"
}

main
