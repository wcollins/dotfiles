#!/usr/bin/env bash
# dive installation script (electron appimage version)
# https://github.com/OpenAgentPlatform/Dive

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

# constants
GITHUB_API_URL="https://api.github.com/repos/OpenAgentPlatform/Dive/releases/latest"
INSTALL_DIR="$HOME/.local/bin"
APPIMAGE_NAME="dive.AppImage"
DESKTOP_FILE="$HOME/.local/share/applications/dive.desktop"

# detect os type
OS=""
case "$(uname -s)" in
    Linux*)     OS="linux";;
    *)          error "unsupported operating system: $(uname -s). This script only supports Linux."; exit 1;;
esac

# detect architecture
ARCH=""
case "$(uname -m)" in
    x86_64)     ARCH="x86_64";;
    amd64)      ARCH="x86_64";;
    *)          error "unsupported architecture: $(uname -m). Dive Electron version only supports x86_64."; exit 1;;
esac

log "Dive Installation (Electron AppImage)"
echo "======================================"
echo
info "detected system: ${OS} ${ARCH}"
echo

# check if dive is already installed
if [[ -f "$INSTALL_DIR/$APPIMAGE_NAME" ]]; then
    info "dive is already installed at $INSTALL_DIR/$APPIMAGE_NAME"
    read -p "reinstall dive? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "keeping existing installation"
        exit 0
    fi
fi

get_latest_version() {
    local version
    if command -v jq >/dev/null 2>&1; then
        version=$(curl -s "$GITHUB_API_URL" | jq -r '.tag_name' | sed 's/^v//')
    else
        # fallback to grep if jq not available
        version=$(curl -s "$GITHUB_API_URL" | grep -oP '"tag_name":\s*"v?\K[^"]+')
    fi

    if [[ -z "$version" ]] || [[ "$version" == "null" ]]; then
        return 1
    fi

    echo "$version"
}

install_dive() {
    log "installing dive..."

    # ensure install directory exists
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$(dirname "$DESKTOP_FILE")"

    # get latest release version
    log "fetching latest dive release version..."
    local latest_version
    latest_version=$(get_latest_version)

    if [[ -z "$latest_version" ]]; then
        error "failed to determine latest version"
        exit 1
    fi

    log "latest version: v$latest_version"

    # construct download url for electron appimage
    local appimage_url="https://github.com/OpenAgentPlatform/Dive/releases/download/v${latest_version}/Dive-electron-${latest_version}-linux-${ARCH}.AppImage"

    # download appimage
    local appimage_path="$INSTALL_DIR/$APPIMAGE_NAME"
    log "downloading $appimage_url..."
    if ! curl -fLo "$appimage_path" "$appimage_url"; then
        error "failed to download dive appimage"
        exit 1
    fi

    # make executable
    chmod +x "$appimage_path"

    # create symlink for 'dive' command
    ln -sf "$appimage_path" "$INSTALL_DIR/dive"

    log "appimage installed to $appimage_path"
}

create_desktop_entry() {
    log "creating desktop entry..."

    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Dive
Comment=AI Chat Desktop Application
Exec=$INSTALL_DIR/$APPIMAGE_NAME
Icon=dive
Terminal=false
Type=Application
Categories=Development;Utility;
StartupWMClass=Dive
EOF

    # update desktop database if available
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi

    log "desktop entry created at $DESKTOP_FILE"
}

verify_installation() {
    log "verifying installation..."

    if [[ -x "$INSTALL_DIR/$APPIMAGE_NAME" ]]; then
        info "dive appimage installed at: $INSTALL_DIR/$APPIMAGE_NAME"
        info "dive command available at: $INSTALL_DIR/dive"
        return 0
    else
        error "dive appimage not found or not executable"
        return 1
    fi
}

# main installation
install_dive

# create desktop entry
create_desktop_entry

# verify installation
echo
if verify_installation; then
    echo
    log "dive installed successfully!"
    echo
    info "to run dive:"
    echo "  dive"
    echo "  # or launch from your application menu"
    echo
    info "note: ensure ~/.local/bin is in your PATH"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
    info "for more information, visit:"
    echo "  https://github.com/OpenAgentPlatform/Dive"
    echo
else
    error "dive installation verification failed"
    exit 1
fi

log "dive setup complete!"
