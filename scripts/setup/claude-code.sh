#!/usr/bin/env bash
# claude-code installation script

set -euo pipefail

# colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_node_version() {
    log "checking node.js version..."
    
    if ! command -v node >/dev/null 2>&1; then
        error "node.js is not installed"
        return 1
    fi
    
    local node_version
    node_version=$(node --version | sed 's/v//')
    local major_version
    major_version=$(echo "$node_version" | cut -d. -f1)
    
    if [[ "$major_version" -lt 18 ]]; then
        error "node.js 18+ is required. current version: v$node_version"
        return 1
    fi
    
    log "node.js version: v$node_version (compatible)"
}

install_node_ubuntu() {
    log "installing node.js on ubuntu/debian..."
    
    # install nodejs 20 lts
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    log "node.js installed successfully"
}


install_dependencies() {
    log "installing system dependencies..."
    sudo apt-get update
    sudo apt-get install -y curl git ca-certificates
}

install_node_if_needed() {
    if ! check_node_version 2>/dev/null; then
        log "node.js 18+ not found, installing..."
        install_node_ubuntu
        
        # verify installation
        if ! check_node_version; then
            error "node.js installation failed"
            exit 1
        fi
    fi
}

install_claude_code_npm() {
    log "installing claude-code via npm..."
    
    # install globally without sudo (security best practice)
    if [[ "$EUID" -eq 0 ]]; then
        error "do not run this script as root/sudo for security reasons"
        exit 1
    fi
    
    # ensure npm prefix is set correctly for user installations
    npm config set prefix ~/.npm-global 2>/dev/null || true
    
    # add npm global bin to path if not already there
    if [[ ":$PATH:" != *":$HOME/.npm-global/bin:"* ]]; then
        export PATH="$HOME/.npm-global/bin:$PATH"
        warn "added ~/.npm-global/bin to PATH for this session"
        warn "consider adding 'export PATH=\"\$HOME/.npm-global/bin:\$PATH\"' to your shell profile"
    fi
    
    # install claude-code
    npm install -g @anthropic-ai/claude-code
    
    log "claude-code installed via npm"
}

install_claude_code_binary() {
    log "installing claude-code via official installer..."
    
    # use official installer as fallback
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL https://claude.ai/install.sh | bash
        log "claude-code installed via official installer"
    else
        error "curl is required for binary installation"
        return 1
    fi
}

verify_installation() {
    log "verifying claude-code installation..."
    
    # check if claude command is available
    if ! command -v claude >/dev/null 2>&1; then
        error "claude command not found in PATH"
        warn "you may need to restart your shell or add claude to your PATH"
        return 1
    fi
    
    # check version
    local version
    version=$(claude --version 2>/dev/null || echo "unknown")
    log "claude-code version: $version"
    
    # run doctor command if available
    if claude doctor >/dev/null 2>&1; then
        log "claude doctor check passed"
    else
        warn "claude doctor check failed - this may be normal for fresh installations"
    fi
    
    log "claude-code installation verified"
}

setup_authentication() {
    log "setting up claude-code authentication..."
    
    warn "authentication setup required:"
    warn "1. visit https://console.anthropic.com/ to get your api key"
    warn "2. ensure you have active billing configured"
    warn "3. run 'claude auth login' to authenticate"
    warn "4. a 'claude code' workspace will be automatically created for usage tracking"
    
    log "authentication setup instructions provided"
}

post_install_setup() {
    log "running post-installation setup..."

    # setup bash completion
    if command -v claude >/dev/null 2>&1; then
        log "setting up bash completion..."
        claude completion bash >/dev/null 2>&1 || warn "bash completion setup failed"
    fi

    log "post-installation setup complete"
}

main() {
    log "starting claude-code installation..."
    
    # check if running as root
    if [[ "$EUID" -eq 0 ]]; then
        error "do not run this script as root for security reasons"
        exit 1
    fi
    
    # install system dependencies
    install_dependencies
    
    # ensure node.js is available
    install_node_if_needed
    
    # install claude-code (try npm first, fallback to binary)
    if install_claude_code_npm; then
        log "claude-code installed successfully via npm"
    elif install_claude_code_binary; then
        log "claude-code installed successfully via binary installer"
    else
        error "failed to install claude-code via npm and binary methods"
        exit 1
    fi
    
    # verify installation
    verify_installation
    
    # post-install setup
    post_install_setup
    
    # setup authentication
    setup_authentication
    
    log "claude-code installation complete!"
    log "next steps:"
    log "1. restart your shell or run: source ~/.bashrc (or equivalent)"
    log "2. run: claude auth login"
    log "3. run: claude --help to get started"
}

main "$@"
