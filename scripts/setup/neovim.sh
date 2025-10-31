#!/usr/bin/env bash
# neovim installation script - installs latest stable neovim
# uses appimage for linux, homebrew for macos

set -euo pipefail

# colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# constants
INSTALL_DIR="$HOME/.local/bin"
NVIM_PATH="$INSTALL_DIR/nvim"
GITHUB_API_URL="https://api.github.com/repos/neovim/neovim/releases/latest"
MIN_VERSION_MAJOR=0
MIN_VERSION_MINOR=11

check_current_version() {
    if command -v nvim >/dev/null 2>&1; then
        local version
        version=$(nvim --version | head -n1 | grep -oP 'v?\K[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")
        echo "$version"
    else
        echo "0.0.0"
    fi
}

version_compare() {
    # compare two version strings (format: X.Y.Z)
    # returns 0 if $1 >= $2, 1 otherwise
    local ver1="$1"
    local ver2="$2"

    local IFS=.
    local ver1_arr=($ver1)
    local ver2_arr=($ver2)

    # compare major version
    if [[ ${ver1_arr[0]} -gt ${ver2_arr[0]} ]]; then
        return 0
    elif [[ ${ver1_arr[0]} -lt ${ver2_arr[0]} ]]; then
        return 1
    fi

    # compare minor version
    if [[ ${ver1_arr[1]} -gt ${ver2_arr[1]} ]]; then
        return 0
    elif [[ ${ver1_arr[1]} -lt ${ver2_arr[1]} ]]; then
        return 1
    fi

    # compare patch version
    if [[ ${ver1_arr[2]:-0} -ge ${ver2_arr[2]:-0} ]]; then
        return 0
    else
        return 1
    fi
}

check_if_upgrade_needed() {
    local current_version
    current_version=$(check_current_version)
    local required_version="${MIN_VERSION_MAJOR}.${MIN_VERSION_MINOR}.0"

    if [[ "$current_version" == "0.0.0" ]]; then
        log "neovim not found, installation needed"
        return 0
    fi

    if version_compare "$current_version" "$required_version"; then
        log "neovim $current_version is already up to date (>= $required_version)"
        return 1
    else
        log "neovim $current_version needs upgrade (requires >= $required_version)"
        return 0
    fi
}

get_latest_release_tag() {
    # fetch latest release tag from github api
    local release_info
    if command -v jq >/dev/null 2>&1; then
        release_info=$(curl -s "$GITHUB_API_URL" | jq -r '.tag_name')
    else
        # fallback to grep if jq not available
        release_info=$(curl -s "$GITHUB_API_URL" | grep -oP '"tag_name":\s*"\K[^"]+')
    fi

    if [[ -z "$release_info" ]] || [[ "$release_info" == "null" ]]; then
        return 1
    fi

    echo "$release_info"
}

detect_architecture() {
    # detect system architecture
    local arch
    arch=$(uname -m)

    case "$arch" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            error "unsupported architecture: $arch"
            return 1
            ;;
    esac
}

install_neovim_appimage() {
    log "installing neovim via appimage..."

    # ensure install directory exists
    mkdir -p "$INSTALL_DIR"

    # get latest release tag
    log "fetching latest neovim release version..."
    local release_tag
    release_tag=$(get_latest_release_tag)
    if [[ -z "$release_tag" ]]; then
        error "failed to determine latest release version"
        return 1
    fi

    log "latest neovim release: $release_tag"

    # detect architecture
    local arch
    arch=$(detect_architecture)
    if [[ -z "$arch" ]]; then
        return 1
    fi

    # construct download url
    local appimage_url="https://github.com/neovim/neovim/releases/download/${release_tag}/nvim-linux-${arch}.appimage"

    # download appimage
    log "downloading neovim appimage for $arch..."
    if ! curl -fLo "$NVIM_PATH.appimage" "$appimage_url"; then
        error "failed to download neovim appimage from $appimage_url"
        return 1
    fi

    # make executable
    chmod +x "$NVIM_PATH.appimage"

    # test if appimage runs (check for fuse support)
    log "testing appimage execution..."
    if "$NVIM_PATH.appimage" --version >/dev/null 2>&1; then
        # create wrapper script
        log "creating wrapper script at $NVIM_PATH..."
        cat > "$NVIM_PATH" << 'EOF'
#!/usr/bin/env bash
# neovim appimage wrapper
exec "$(dirname "$0")/nvim.appimage" "$@"
EOF
        chmod +x "$NVIM_PATH"
    else
        warn "appimage execution failed (possibly missing fuse). extracting appimage..."

        # extract appimage
        local extract_dir="$INSTALL_DIR/nvim-appimage"
        rm -rf "$extract_dir"
        mkdir -p "$extract_dir"

        cd "$INSTALL_DIR" && "$NVIM_PATH.appimage" --appimage-extract >/dev/null 2>&1
        mv squashfs-root "$extract_dir"

        # create wrapper script that uses extracted files
        log "creating wrapper script for extracted appimage..."
        cat > "$NVIM_PATH" << EOF
#!/usr/bin/env bash
# neovim extracted appimage wrapper
exec "$extract_dir/usr/bin/nvim" "\$@"
EOF
        chmod +x "$NVIM_PATH"

        # remove original appimage
        rm -f "$NVIM_PATH.appimage"
    fi

    log "neovim appimage installed successfully"
}


remove_old_neovim_apt() {
    # optionally remove old apt-installed neovim to avoid conflicts
    if command -v apt-get >/dev/null 2>&1; then
        if dpkg -l | grep -q "^ii.*neovim"; then
            warn "detected apt-installed neovim package"
            read -p "remove old apt package to avoid conflicts? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "removing old neovim apt package..."
                sudo apt-get remove -y neovim
                log "old neovim package removed"
            else
                warn "keeping old apt package. ensure $INSTALL_DIR is in PATH before /usr/bin"
            fi
        fi
    fi
}

verify_installation() {
    log "verifying neovim installation..."

    # check if nvim command is available
    if ! command -v nvim >/dev/null 2>&1; then
        error "nvim command not found in PATH"
        warn "please ensure $INSTALL_DIR is in your PATH"
        warn "add this to your shell profile:"
        warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        return 1
    fi

    # check version
    local version
    version=$(nvim --version | head -n1)
    log "neovim version: $version"

    # verify version meets minimum requirements
    local current_version
    current_version=$(check_current_version)
    local required_version="${MIN_VERSION_MAJOR}.${MIN_VERSION_MINOR}.0"

    if version_compare "$current_version" "$required_version"; then
        log "neovim version check passed (>= $required_version)"
    else
        error "neovim version $current_version does not meet minimum requirement (>= $required_version)"
        return 1
    fi

    log "neovim installation verified"
}

post_install_setup() {
    log "running post-installation setup..."

    # ensure vim-plug is installed
    local plug_vim="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
    if [ ! -f "$plug_vim" ]; then
        log "installing vim-plug..."
        curl -fLo "$plug_vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi

    # update plugins if neovim config exists
    if [ -d "$HOME/.config/nvim" ]; then
        log "updating neovim plugins..."
        nvim --headless "+PlugUpdate" "+PlugInstall" "+qall" 2>/dev/null || {
            warn "plugin update had issues. run ':PlugUpdate' manually in neovim"
        }

        # compile telescope-fzf-native if present
        local fzf_native_dir="$HOME/.local/share/nvim/plugged/telescope-fzf-native.nvim"
        if [ -d "$fzf_native_dir" ] && command -v make >/dev/null 2>&1; then
            log "compiling telescope-fzf-native..."
            (cd "$fzf_native_dir" && make) || warn "failed to compile telescope-fzf-native"
        fi
    fi

    log "post-installation setup complete"
}

main() {
    log "starting neovim installation..."

    # check if upgrade is needed
    if ! check_if_upgrade_needed; then
        log "neovim is already up to date. skipping installation."
        exit 0
    fi

    # detect os and install accordingly
    case "$(uname -s)" in
        Linux)
            log "detected linux"
            install_neovim_appimage

            # optionally remove old apt package
            remove_old_neovim_apt
            ;;
        *)
            error "unsupported operating system: $(uname -s). This script only supports Debian/Ubuntu Linux."
            exit 1
            ;;
    esac

    # verify installation
    verify_installation

    # post-install setup
    post_install_setup

    log "neovim installation complete!"
    log "next steps:"
    log "1. restart your shell or run: source ~/.bashrc (or equivalent)"
    log "2. run: nvim --version to verify"
    log "3. run: nvim to start editing"
}

main "$@"
