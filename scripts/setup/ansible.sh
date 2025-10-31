#!/usr/bin/env bash
# ansible installation script using uv package manager

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

log "Ansible Installation via UV"
echo "============================"
echo
info "detected system: ${OS} ${ARCH}"
echo

# check if uv is installed
install_uv() {
    log "installing uv package manager..."
    
    # check if uv install script exists in current directory
    if [[ -f "./uv.sh" ]]; then
        log "found uv.sh in current directory, running it..."
        bash ./uv.sh
    else
        # fallback to direct installation
        log "downloading and installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    
    # source shell configuration to get uv in path
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    fi
    
    # verify installation
    if ! command -v uv >/dev/null 2>&1; then
        error "uv installation failed or not in PATH"
        error "please add $HOME/.cargo/bin to your PATH and run this script again"
        exit 1
    fi
    
    log "uv installed successfully"
}

# check if uv is available
if ! command -v uv >/dev/null 2>&1; then
    warn "uv is not installed"
    read -p "install uv now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        install_uv
    else
        error "uv is required to install ansible with this script"
        exit 1
    fi
else
    current_version=$(uv --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
    log "uv is already installed (version: $current_version)"
fi

# check for existing ansible venv
DEFAULT_VENV_NAME="ansible"
VENV_NAME=""

# prompt for venv name
echo
info "ansible will be installed in a uv virtual environment"
echo -n "enter venv name (default: $DEFAULT_VENV_NAME): "
read user_venv_name

if [[ -z "$user_venv_name" ]]; then
    VENV_NAME="$DEFAULT_VENV_NAME"
else
    VENV_NAME="$user_venv_name"
fi

# check if venv already exists
if [[ -d "$VENV_NAME" ]]; then
    warn "virtual environment '$VENV_NAME' already exists"
    read -p "recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "removing existing venv..."
        rm -rf "$VENV_NAME"
    else
        log "using existing virtual environment"
    fi
fi

# create venv if it doesn't exist
if [[ ! -d "$VENV_NAME" ]]; then
    log "creating virtual environment '$VENV_NAME'..."
    uv venv "$VENV_NAME"
fi

# install ansible
log "installing ansible in virtual environment..."
uv pip install --python "$VENV_NAME" ansible

# verify installation
if "$VENV_NAME/bin/ansible" --version >/dev/null 2>&1; then
    ansible_version=$("$VENV_NAME/bin/ansible" --version | head -1)
    log "ansible installed successfully!"
    echo
    info "installation details:"
    echo "  venv path: $(pwd)/$VENV_NAME"
    echo "  ansible: $ansible_version"
    echo
    info "to use ansible, activate the virtual environment:"
    echo "  source $VENV_NAME/bin/activate"
    echo
    info "or run ansible directly:"
    echo "  $VENV_NAME/bin/ansible"
    echo "  $VENV_NAME/bin/ansible-playbook"
    echo "  $VENV_NAME/bin/ansible-galaxy"
    echo
else
    error "ansible installation verification failed"
    exit 1
fi

# optional: install additional ansible packages
echo
read -p "install additional ansible packages? (ansible-lint, molecule, etc.) (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "installing additional ansible packages..."
    
    # common ansible development tools
    packages=(
        "ansible-lint"
        "molecule"
        "yamllint"
        "jmespath"
    )
    
    for package in "${packages[@]}"; do
        log "installing $package..."
        uv pip install --python "$VENV_NAME" "$package" || warn "failed to install $package"
    done
    
    log "additional packages installation complete"
fi

echo
log "ansible setup complete!"