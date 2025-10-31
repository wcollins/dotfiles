#!/usr/bin/env bash
# 1password cli installation script

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
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# detect os type
OS=""
case "$(uname -s)" in
    Linux*)     OS="linux";;
    *)          error "unsupported operating system: $(uname -s). This script only supports Debian/Ubuntu Linux."; exit 1;;
esac

# detect architecture
ARCH=""
case "$(uname -m)" in
    x86_64)     ARCH="amd64";;
    amd64)      ARCH="amd64";;
    aarch64)    ARCH="arm64";;
    arm64)      ARCH="arm64";;
    armv7*)     ARCH="arm";;
    i386)       ARCH="386";;
    i686)       ARCH="386";;
    *)          error "unsupported architecture: $(uname -m)"; exit 1;;
esac

log "1Password CLI Installation"
echo "==========================="
echo
info "detected system: ${OS} ${ARCH}"
echo

# check if already installed
if command -v op >/dev/null 2>&1; then
    current_version=$(op --version 2>/dev/null || echo "unknown")
    warn "1password cli is already installed (version: $current_version)"
    read -p "do you want to reinstall/update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "keeping existing installation"
        exit 0
    fi
fi

# installation based on os
install_linux() {
    # detect linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION_ID=$VERSION_ID
    else
        error "cannot detect linux distribution"
        exit 1
    fi

    case "$DISTRO" in
        ubuntu|debian|pop|linuxmint|elementary)
            install_linux_apt
            ;;
        *)
            error "distribution $DISTRO is not supported. This script only supports Debian/Ubuntu."
            exit 1
            ;;
    esac
}

install_linux_apt() {
    log "installing via apt package manager..."
    
    # add 1password apt repository
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
        sudo tee /etc/apt/sources.list.d/1password.list
    
    # add debsig-verify policy
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
    
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
    
    # update and install
    sudo apt update && sudo apt install -y 1password-cli
    
    log "1password cli installed via apt"
}


# main installation
main() {
    case "$OS" in
        linux)
            install_linux
            ;;
        *)
            error "unsupported operating system: $OS. This script only supports Debian/Ubuntu Linux."
            exit 1
            ;;
    esac
    
    # verify installation
    if command -v op >/dev/null 2>&1; then
        echo
        log "installation complete!"
        info "1password cli version: $(op --version)"
        echo
        info "to get started:"
        echo "  1. sign in to your account: op signin"
        echo "  2. list your vaults: op vault list"
        echo "  3. get an item: op item get <item-name>"
        echo
        info "for more information, visit: https://developer.1password.com/docs/cli"
    else
        error "installation failed - op command not found"
        exit 1
    fi
}

# run main function
main
