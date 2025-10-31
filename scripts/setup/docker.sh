#!/usr/bin/env bash
# docker-ce and docker compose installation script

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

log "Docker CE & Docker Compose Installation"
echo "======================================="
echo
info "detected system: ${OS} ${ARCH}"
echo

# check if already installed
if command -v docker >/dev/null 2>&1; then
    current_version=$(docker --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
    warn "docker is already installed (version: $current_version)"
    read -p "do you want to reinstall/update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "keeping existing docker installation"
        
        # check docker compose
        if command -v docker-compose >/dev/null 2>&1 || docker compose version >/dev/null 2>&1; then
            log "docker compose is already installed"
        else
            log "installing docker compose plugin..."
            install_compose_plugin
        fi
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
        ubuntu|debian|pop|linuxmint|elementary|raspbian)
            install_linux_apt
            ;;
        *)
            error "distribution $DISTRO is not supported. This script only supports Debian/Ubuntu."
            exit 1
            ;;
    esac
}

install_linux_apt() {
    log "installing docker ce via apt package manager..."
    
    # remove old versions
    log "removing old docker versions if present..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # update package index
    sudo apt-get update
    
    # install prerequisites
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # add docker's official gpg key
    log "adding docker gpg key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # set up repository
    log "setting up docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO \
        $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # update apt package index
    sudo apt-get update
    
    # install docker engine, cli and containerd
    log "installing docker ce, cli and containerd..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    log "docker ce installed via apt"
}


install_compose_plugin() {
    log "installing docker compose plugin..."
    
    # determine compose version
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [[ -z "$COMPOSE_VERSION" ]]; then
        COMPOSE_VERSION="2.24.0"  # fallback version
        warn "could not fetch latest compose version, using $COMPOSE_VERSION"
    fi
    
    # install docker compose plugin based on architecture
    case "$OS" in
        linux)
            # create cli plugins directory
            DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
            mkdir -p $DOCKER_CONFIG/cli-plugins
            
            # download compose plugin
            curl -SL "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
                -o $DOCKER_CONFIG/cli-plugins/docker-compose
            
            # make it executable
            chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
            
            # also install system-wide if running as root or with sudo
            if [[ "$EUID" -eq 0 ]] || sudo -n true 2>/dev/null; then
                sudo mkdir -p /usr/local/lib/docker/cli-plugins
                sudo curl -SL "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
                    -o /usr/local/lib/docker/cli-plugins/docker-compose
                sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
            fi
            ;;
    esac
    
    log "docker compose plugin installed (version: $COMPOSE_VERSION)"
}


post_install_linux() {
    log "performing post-installation setup..."
    
    # add current user to docker group if not root
    if [[ "$EUID" -ne 0 ]]; then
        if ! groups $USER | grep -q docker; then
            log "adding current user to docker group..."
            sudo usermod -aG docker $USER
            warn "you need to log out and back in for group changes to take effect"
            warn "or run: newgrp docker"
        fi
    fi
    
    # start docker service if systemctl is available
    if command -v systemctl >/dev/null 2>&1; then
        if ! sudo systemctl is-active docker >/dev/null 2>&1; then
            log "starting docker service..."
            sudo systemctl start docker
        fi
        
        if ! sudo systemctl is-enabled docker >/dev/null 2>&1; then
            log "enabling docker service to start on boot..."
            sudo systemctl enable docker
        fi
    fi
    
    # verify docker is working
    log "verifying docker installation..."
    if sudo docker run --rm hello-world >/dev/null 2>&1; then
        log "docker is working correctly"
    else
        warn "docker test failed - you may need to restart the service or system"
    fi
}

verify_installation() {
    echo
    log "verifying installation..."
    
    # check docker
    if command -v docker >/dev/null 2>&1; then
        docker_version=$(docker --version | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
        info "docker version: $docker_version"
    else
        error "docker command not found"
        return 1
    fi
    
    # check docker compose
    if docker compose version >/dev/null 2>&1; then
        compose_version=$(docker compose version | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
        info "docker compose version: $compose_version"
    elif command -v docker-compose >/dev/null 2>&1; then
        compose_version=$(docker-compose --version | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
        info "docker-compose version: $compose_version"
    else
        warn "docker compose not found"
    fi
    
    return 0
}

# main installation
main() {
    case "$OS" in
        linux)
            install_linux
            post_install_linux
            ;;
        *)
            error "unsupported operating system: $OS. This script only supports Debian/Ubuntu Linux."
            exit 1
            ;;
    esac

    # verify installation
    if verify_installation; then
        echo
        log "installation complete!"
        echo
        info "to get started:"
        echo "  1. log out and back in (or run: newgrp docker)"
        echo "  2. verify with: docker run hello-world"
        echo "  3. check compose: docker compose version"
        echo
        info "for more information, visit:"
        echo "  - docker: https://docs.docker.com/"
        echo "  - compose: https://docs.docker.com/compose/"
    else
        error "installation verification failed"
        exit 1
    fi
}

# run main function
main