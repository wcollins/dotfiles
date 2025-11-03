#!/usr/bin/env bash
# GitHub CLI installation and configuration script

set -euo pipefail

# colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # no color

# logging functions
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# github cli helper functions
check_gh_installed() {
    if command -v gh >/dev/null 2>&1; then
        local version=$(gh --version | head -1)
        info "GitHub CLI is already installed: $version"
        return 0
    else
        return 1
    fi
}

install_gh_cli() {
    log "Installing GitHub CLI..."

    # check if running on supported OS
    if [[ ! "$(uname -s)" == "Linux" ]]; then
        error "GitHub CLI installation is only supported on Linux"
        return 1
    fi

    # detect distribution
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot detect Linux distribution"
        return 1
    fi

    source /etc/os-release

    if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then
        error "GitHub CLI installation is only supported on Debian/Ubuntu"
        return 1
    fi

    # add github's gpg key
    log "Adding GitHub's GPG key..."
    sudo mkdir -p /usr/share/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

    # add github cli repository
    log "Adding GitHub CLI repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

    # update package list and install
    log "Updating package list..."
    sudo apt-get update >/dev/null 2>&1

    log "Installing gh..."
    if sudo apt-get install -y gh; then
        log "GitHub CLI installed successfully"
        gh --version
        return 0
    else
        error "Failed to install GitHub CLI"
        return 1
    fi
}

configure_gh_auth() {
    log "Configuring GitHub authentication..."
    echo
    info "You will now be prompted to authenticate with GitHub"
    info "Choose your preferred authentication method (HTTPS or SSH)"
    echo
    read -p "Press Enter to continue..." -r
    echo

    if gh auth login; then
        log "GitHub authentication successful"
        echo
        gh auth status
        return 0
    else
        error "GitHub authentication failed"
        return 1
    fi
}

setup_gh_cli() {
    log "GitHub CLI Setup"
    echo "================"
    echo

    # check if already installed
    if check_gh_installed; then
        read -p "Do you want to reinstall GitHub CLI? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Using existing GitHub CLI installation"

            # check if authenticated
            if gh auth status >/dev/null 2>&1; then
                info "Already authenticated with GitHub"
                gh auth status
            else
                read -p "Do you want to authenticate with GitHub now? (Y/n): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    configure_gh_auth
                fi
            fi
            return 0
        fi
    fi

    # install gh cli
    if install_gh_cli; then
        # configure authentication
        read -p "Do you want to authenticate with GitHub now? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            configure_gh_auth
        else
            info "You can authenticate later with: gh auth login"
        fi
    else
        error "GitHub CLI installation failed"
        return 1
    fi
}

# main execution
setup_gh_cli

echo
log "GitHub CLI setup complete!"
echo

if command -v gh >/dev/null 2>&1; then
    info "GitHub CLI version: $(gh --version | head -1 | awk '{print $3}')"
    if gh auth status >/dev/null 2>&1; then
        info "Authentication status: authenticated"
    else
        info "Authentication status: not authenticated (run 'gh auth login')"
    fi
else
    error "GitHub CLI is not installed"
fi
