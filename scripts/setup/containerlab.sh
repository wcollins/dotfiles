#!/usr/bin/env bash
# containerlab installation script for Debian/Ubuntu
# https://containerlab.dev/install/

set -euo pipefail

# colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # no color

# logging functions
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

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

# check if Docker is installed and running
check_docker() {
    log "checking Docker installation..."

    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. containerlab requires Docker."
        error "please install Docker first using: ./scripts/setup/docker.sh"
        exit 1
    fi

    log "Docker is installed: $(docker --version)"

    # check if Docker daemon is running
    if ! docker ps &> /dev/null; then
        error "Docker daemon is not running or you don't have permissions."
        error "please ensure Docker is running and you have sudo privileges."
        exit 1
    fi

    log "Docker daemon is running"
}

# check if running with sufficient privileges
check_privileges() {
    if [ "$EUID" -eq 0 ]; then
        warn "running as root. this is not recommended."
        return
    fi

    if ! sudo -n true 2>/dev/null; then
        log "this script requires sudo privileges"
    fi
}

# add netdevops repository
add_repository() {
    log "setting up netdevops repository..."

    local repo_file="/etc/apt/sources.list.d/netdevops.list"
    local repo_line="deb [trusted=yes] https://netdevops.fury.site/apt/ /"

    # check if repository already exists
    if [ -f "$repo_file" ] && grep -q "netdevops.fury.site" "$repo_file"; then
        log "netdevops repository already configured"
        return
    fi

    # add repository
    echo "$repo_line" | sudo tee -a "$repo_file" > /dev/null
    log "netdevops repository added to $repo_file"
}

# install containerlab
install_containerlab() {
    log "updating package lists..."

    if ! sudo apt update; then
        error "failed to update package lists"
        exit 1
    fi

    log "installing containerlab..."

    if sudo apt install -y containerlab; then
        log "containerlab installed successfully"
    else
        error "failed to install containerlab"
        exit 1
    fi
}

# verify installation
verify_installation() {
    log "verifying containerlab installation..."

    if ! command -v clab &> /dev/null; then
        error "containerlab binary not found in PATH"
        exit 1
    fi

    local version=$(clab version | head -n1)
    log "containerlab version: $version"
}

# setup Docker group membership
setup_docker_group() {
    local current_user="${SUDO_USER:-$USER}"

    if groups "$current_user" | grep -q '\bdocker\b'; then
        log "user '$current_user' is already in docker group"
        return
    fi

    log "adding user '$current_user' to docker group..."

    if sudo usermod -aG docker "$current_user"; then
        log "user added to docker group"
        warn "you may need to log out and back in, or run: newgrp docker"
    else
        warn "failed to add user to docker group. you may need to run containerlab with sudo."
    fi
}

# main installation flow
main() {
    log "starting containerlab installation for Debian/Ubuntu"
    echo

    check_os
    check_privileges
    check_docker
    echo

    add_repository
    install_containerlab
    echo

    verify_installation
    setup_docker_group
    echo

    log "containerlab installation complete!"
    log "documentation: https://containerlab.dev/"
    log "quick start: clab deploy -t <topology-file>"
}

main
