#!/usr/bin/env bash
# vhs installation script
# https://github.com/charmbracelet/vhs

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
    armv7*)     ARCH="armv7";;
    i386)       ARCH="386";;
    i686)       ARCH="386";;
    *)          error "unsupported architecture: $(uname -m)"; exit 1;;
esac

log "VHS Installation"
echo "================"
echo
info "detected system: ${OS} ${ARCH}"
echo

# check if vhs is already installed
if command -v vhs >/dev/null 2>&1; then
    current_version=$(vhs --version 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' | head -1 || echo "unknown")
    info "vhs is already installed (version: $current_version)"
    read -p "reinstall vhs? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "keeping existing installation"
        exit 0
    fi
fi

# install dependencies: ttyd and ffmpeg
install_dependencies() {
    log "checking dependencies..."

    # check for ttyd
    if ! command -v ttyd >/dev/null 2>&1; then
        warn "ttyd is not installed (required by vhs)"
        log "installing ttyd from github releases..."

        # get latest release version
        latest_version=$(curl -s https://api.github.com/repos/tsl0922/ttyd/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

        if [[ -z "$latest_version" ]]; then
            error "failed to determine latest ttyd version"
            exit 1
        fi

        log "latest ttyd version: $latest_version"

        # map arch to ttyd binary naming
        ttyd_arch="$ARCH"
        if [[ "$ARCH" == "amd64" ]]; then
            ttyd_arch="x86_64"
        elif [[ "$ARCH" == "arm64" ]]; then
            ttyd_arch="aarch64"
        fi

        # construct download url
        binary_name="ttyd.${ttyd_arch}"
        download_url="https://github.com/tsl0922/ttyd/releases/download/${latest_version}/${binary_name}"

        # download binary
        temp_binary="/tmp/ttyd"
        log "downloading $download_url..."
        if ! curl -Lo "$temp_binary" "$download_url"; then
            error "failed to download ttyd"
            exit 1
        fi

        # install to /usr/local/bin
        log "installing ttyd to /usr/local/bin..."
        sudo install -m 755 "$temp_binary" /usr/local/bin/ttyd
        rm "$temp_binary"

        log "ttyd installed successfully"
    else
        log "ttyd is already installed"
    fi

    # check for ffmpeg
    if ! command -v ffmpeg >/dev/null 2>&1; then
        warn "ffmpeg is not installed (required by vhs)"
        log "installing ffmpeg via apt..."
        sudo apt-get update
        sudo apt-get install -y ffmpeg
    else
        log "ffmpeg is already installed"
    fi
}

# install vhs
install_vhs() {
    log "installing vhs..."
    log "installing vhs from github releases..."

    # get latest release version
    latest_version=$(curl -s https://api.github.com/repos/charmbracelet/vhs/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

    if [[ -z "$latest_version" ]]; then
        error "failed to determine latest version"
        exit 1
    fi

    log "latest version: v$latest_version"

    # construct download url
    deb_url="https://github.com/charmbracelet/vhs/releases/download/v${latest_version}/vhs_${latest_version}_${ARCH}.deb"

    # download and install
    temp_deb="/tmp/vhs_${latest_version}_${ARCH}.deb"
    log "downloading $deb_url..."
    curl -Lo "$temp_deb" "$deb_url"

    log "installing deb package..."
    sudo dpkg -i "$temp_deb"
    sudo apt-get install -f -y

    rm "$temp_deb"
}

# install dependencies first
install_dependencies

echo

# install vhs
install_vhs

# verify installation
echo
if command -v vhs >/dev/null 2>&1; then
    vhs_version=$(vhs --version 2>/dev/null | head -1)
    log "vhs installed successfully!"
    echo
    info "installation details:"
    echo "  vhs: $vhs_version"
    echo "  ttyd: $(command -v ttyd >/dev/null 2>&1 && echo 'installed' || echo 'not found')"
    echo "  ffmpeg: $(command -v ffmpeg >/dev/null 2>&1 && echo 'installed' || echo 'not found')"
    echo
    info "to get started:"
    echo "  vhs --help"
    echo "  vhs new demo.tape"
    echo
else
    error "vhs installation verification failed"
    exit 1
fi

log "vhs setup complete!"
