#!/usr/bin/env bash
# AWS CLI v2 installation script for Debian/Ubuntu
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

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

# detect architecture
ARCH=""
case "$(uname -m)" in
    x86_64)     ARCH="x86_64";;
    aarch64)    ARCH="aarch64";;
    *)          error "unsupported architecture: $(uname -m). AWS CLI v2 supports x86_64 and aarch64 only."; exit 1;;
esac

# check if running on Debian/Ubuntu
check_os() {
    log "checking OS compatibility..."

    if [ ! -f /etc/os-release ]; then
        error "cannot determine OS. /etc/os-release not found."
        exit 1
    fi

    . /etc/os-release

    if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then
        error "this script supports Debian and Ubuntu only. detected: $ID"
        exit 1
    fi

    log "OS check passed: $PRETTY_NAME"
}

# check if AWS CLI is already installed
check_existing_installation() {
    if command -v aws >/dev/null 2>&1; then
        local version=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
        warn "AWS CLI is already installed (version: $version)"
        read -p "do you want to reinstall/update? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "keeping existing installation"
            exit 0
        fi
        return 0
    fi
    return 1
}

# install dependencies
install_dependencies() {
    log "installing dependencies..."

    local deps=("curl" "unzip" "groff" "less")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -eq 0 ]; then
        log "all dependencies already installed"
        return 0
    fi

    info "installing missing dependencies: ${missing_deps[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y "${missing_deps[@]}"
    log "dependencies installed"
}

# download and install AWS CLI v2
install_aws_cli() {
    log "downloading AWS CLI v2 for ${ARCH}..."

    local tmp_dir=$(mktemp -d)
    local download_url="https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip"
    local zip_file="${tmp_dir}/awscliv2.zip"

    if ! curl -fsSL "$download_url" -o "$zip_file"; then
        error "failed to download AWS CLI"
        rm -rf "$tmp_dir"
        exit 1
    fi

    log "extracting AWS CLI installer..."
    if ! unzip -q "$zip_file" -d "$tmp_dir"; then
        error "failed to extract AWS CLI installer"
        rm -rf "$tmp_dir"
        exit 1
    fi

    log "installing AWS CLI v2..."
    if check_existing_installation >/dev/null 2>&1; then

        # update existing installation
        if sudo "${tmp_dir}/aws/install" --update; then
            log "AWS CLI updated successfully"
        else
            error "failed to update AWS CLI"
            rm -rf "$tmp_dir"
            exit 1
        fi
    else

        # fresh install
        if sudo "${tmp_dir}/aws/install"; then
            log "AWS CLI installed successfully"
        else
            error "failed to install AWS CLI"
            rm -rf "$tmp_dir"
            exit 1
        fi
    fi

    # clean
    rm -rf "$tmp_dir"
    log "cleaned up temporary files"
}

# verify install
verify_installation() {
    log "verifying AWS CLI installation..."

    if ! command -v aws >/dev/null 2>&1; then
        error "AWS CLI binary not found in PATH"
        exit 1
    fi

    local version=$(aws --version 2>&1)
    log "AWS CLI installed: $version"
}

# display post-install info
show_usage_info() {
    echo
    info "AWS CLI installation complete!"
    echo
    info "to get started:"
    echo "  1. configure credentials: aws configure"
    echo "  2. or set up SSO: aws configure sso"
    echo "  3. verify configuration: aws sts get-caller-identity"
    echo
    info "configuration files location:"
    echo "  - credentials: ~/.aws/credentials"
    echo "  - config: ~/.aws/config"
    echo
    info "for more information, visit:"
    echo "  https://docs.aws.amazon.com/cli/latest/userguide/"
}

# main logic
main() {
    log "AWS CLI v2 Installation"
    echo "======================="
    echo
    info "detected architecture: ${ARCH}"
    echo

    check_os
    echo

    check_existing_installation || true

    install_dependencies
    echo

    install_aws_cli
    echo

    verify_installation
    show_usage_info
}

main
