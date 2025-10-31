#!/usr/bin/env bash
# git configuration setup script

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
    echo
    read -p "Do you want to install and configure GitHub CLI (gh)? (Y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log "Skipping GitHub CLI setup"
        return 0
    fi

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

# get current git config values
current_name=$(git config --global user.name 2>/dev/null || echo "")
current_email=$(git config --global user.email 2>/dev/null || echo "")

log "Git Configuration Setup"
echo "========================"
echo

# check if already configured
if [[ -n "$current_name" && -n "$current_email" && "$current_name" != "Your Name" ]]; then
    info "Current git configuration:"
    echo "  Name:  $current_name"
    echo "  Email: $current_email"
    echo
    read -p "Do you want to update these settings? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Keeping existing configuration"
        exit 0
    fi
fi

# get user input for name
echo -n "Enter your full name for Git commits: "
read git_name
while [[ -z "$git_name" ]]; do
    warn "Name cannot be empty"
    echo -n "Enter your full name for Git commits: "
    read git_name
done

# get user input for email
echo -n "Enter your email address for Git commits: "
read git_email
while [[ -z "$git_email" ]] || [[ ! "$git_email" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; do
    warn "Please enter a valid email address"
    echo -n "Enter your email address for Git commits: "
    read git_email
done

# set global git configuration
log "Setting git configuration..."
git config --global user.name "$git_name"
git config --global user.email "$git_email"

# additional optional configurations
echo
read -p "Configure additional recommended settings? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    # set default editor
    if command -v nvim >/dev/null 2>&1; then
        git config --global core.editor "nvim"
        log "Set Neovim as default editor"
    elif command -v vim >/dev/null 2>&1; then
        git config --global core.editor "vim"
        log "Set Vim as default editor"
    fi
    
    # set up credential helper for Linux
    case "$(uname -s)" in
        Linux)
            # check if we're in wsl
            if grep -qi microsoft /proc/version 2>/dev/null; then
                git config --global credential.helper "/mnt/c/Program\\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
                log "Configured Windows credential manager for WSL"
            else
                git config --global credential.helper "cache --timeout=3600"
                log "Configured credential caching (1 hour)"
            fi
            ;;
    esac
    
    # set default branch name
    git config --global init.defaultBranch main
    log "Set default branch name to 'main'"
    
    # set pull strategy
    git config --global pull.rebase false
    log "Set pull strategy to merge (not rebase)"
    
    # enable auto setup remote for push
    git config --global push.autoSetupRemote true
    log "Enabled automatic upstream tracking"
fi

# set up gpg key for signed commits
echo
read -p "Configure GPG key for signed commits? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    log "Setting up GPG key for signed commits..."
    
    # check if gnupg is installed
    if ! command -v gpg >/dev/null 2>&1; then
        log "Installing GnuPG..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y gnupg
        elif command -v brew >/dev/null 2>&1; then
            brew install gnupg
        else
            error "Could not install GnuPG. Please install it manually."
            exit 1
        fi
    fi
    
    # check if there's already a signing key configured
    current_signing_key=$(git config --global user.signingkey 2>/dev/null || echo "")
    
    if [[ -n "$current_signing_key" ]]; then

        # verify the key exists in gpg
        if gpg --list-secret-keys --keyid-format=long | grep -q "$current_signing_key"; then
            info "GPG signing key already configured: $current_signing_key"
            read -p "Generate new key? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "Using existing GPG key"

                # show the public key anyway
                echo
                info "Your public GPG key (for GitHub):"
                echo "=================================="
                gpg --armor --export "$current_signing_key"
                echo "=================================="
                echo
                info "To add to GitHub:"
                echo "  1. Go to GitHub Settings > SSH and GPG keys"
                echo "  2. Click 'New GPG key'"
                echo "  3. Paste the above public key (including BEGIN/END lines)"
                echo
                continue_setup=false
            else
                continue_setup=true
            fi
        else
            warn "Configured signing key $current_signing_key not found in GPG keyring"
            continue_setup=true
        fi
    else
        continue_setup=true
    fi
    
    if [[ "$continue_setup" == "true" ]]; then

        # get name and email from git config or current values
        git_name="${git_name:-$(git config --global user.name 2>/dev/null || echo "")}"
        git_email="${git_email:-$(git config --global user.email 2>/dev/null || echo "")}"
        
        if [[ -z "$git_name" || -z "$git_email" ]]; then
            error "Git name and email must be configured first"
            exit 1
        fi
        
        log "Generating GPG key for $git_name <$git_email>..."
        
        # generate gpg key non-interactively
        cat >gpg_batch <<EOF
%echo Generating GPG key for Git signing
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $git_name
Name-Email: $git_email
Expire-Date: 0
%no-protection
%commit
%echo done
EOF
        
        gpg --batch --generate-key gpg_batch
        rm gpg_batch
        
        log "GPG key generated successfully"
        
        # get the key id
        key_id=$(gpg --list-secret-keys --keyid-format=long "$git_email" | grep "sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
        
        if [[ -z "$key_id" ]]; then
            error "Could not find generated GPG key"
            exit 1
        fi
        
        # configure git to use gpg for signing
        git config --global user.signingkey "$key_id"
        git config --global commit.gpgsign true
        git config --global tag.gpgsign true
        
        log "Configured git to use GPG key $key_id for signing"
        
        # show public key for github
        echo
        info "Your public GPG key (for GitHub):"
        echo "=================================="
        gpg --armor --export "$key_id"
        echo "=================================="
        echo
        info "To add to GitHub:"
        echo "  1. Go to GitHub Settings > SSH and GPG keys"
        echo "  2. Click 'New GPG key'"
        echo "  3. Paste the above public key (including BEGIN/END lines)"
        echo
    fi
fi

# set up global gitignore if it exists
if [[ -f "$HOME/.config/git/gitignore_global" ]]; then
    git config --global core.excludesfile "$HOME/.config/git/gitignore_global"
    log "Set global gitignore file"
elif [[ -f "$HOME/.gitignore_global" ]]; then
    git config --global core.excludesfile "$HOME/.gitignore_global"
    log "Set global gitignore file"
fi

# set up github cli
setup_gh_cli

echo
log "Git configuration complete!"
echo
info "Current configuration:"
echo "  Name:  $(git config --global user.name)"
echo "  Email: $(git config --global user.email)"
echo "  Editor: $(git config --global core.editor || echo 'default')"
echo "  Default branch: $(git config --global init.defaultBranch || echo 'master')"
if command -v gh >/dev/null 2>&1; then
    echo "  GitHub CLI: $(gh --version | head -1 | awk '{print $3}')"
    if gh auth status >/dev/null 2>&1; then
        echo "  GitHub Auth: authenticated"
    else
        echo "  GitHub Auth: not authenticated (run 'gh auth login')"
    fi
else
    echo "  GitHub CLI: not installed"
fi
echo

# show all aliases
if git config --get-regexp alias >/dev/null 2>&1; then
    info "Available git aliases:"
    git config --get-regexp alias | sed 's/alias\./ /' | sed 's/=/ = /'
fi