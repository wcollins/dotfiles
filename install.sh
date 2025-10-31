#!/usr/bin/env bash
# dotfiles installation script

set -euo pipefail

# configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_REMOTE="https://github.com/wcollins/dotfiles.git"

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

# detect operating system
detect_os() {
    case "$(uname -s)" in
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                echo "debian"
            else
                echo "unsupported"
            fi
            ;;
        *) echo "unsupported" ;;
    esac
}

# install dependencies
install_dependencies() {
    local os="$1"

    log "Installing dependencies for $os..."

    case "$os" in
        debian)
            log "Updating package lists..."
            sudo apt-get update

            # install essential packages (neovim installed separately via setup script)
            local packages="git curl wget bash tmux fzf ripgrep fd-find bat stow build-essential jq fastfetch"
            log "Installing packages via apt..."
            sudo apt-get install -y $packages
            ;;
        *)
            error "Unsupported OS: $os. This installer only supports Debian/Ubuntu systems."
            exit 1
            ;;
    esac
}

# create directories
create_directories() {
    log "Creating necessary directories..."

    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.cache/nvim"/{backup,swap,undo}
    mkdir -p "$HOME/.ssh/keys"
    mkdir -p "$HOME/.claude"
}

# create symlinks
setup_symlinks() {
    log "Setting up configuration symlinks..."
    
    if command -v stow >/dev/null 2>&1; then
        log "Using GNU Stow for symlinks..."
        cd "$DOTFILES_DIR"
        
        # stow configuration files to ~/.config
        stow -d config -t "$HOME/.config" . 2>/dev/null || {
            warn "Some conflicts detected. Backing up existing files..."
            backup_existing_configs
            stow -d config -t "$HOME/.config" .
        }
        
        # stow bin files to ~/.local/bin
        if [ -d "bin" ]; then
            log "Symlinking bin directory to ~/.local/bin..."
            stow -t "$HOME/.local" bin 2>/dev/null || {
                warn "Stow failed for bin directory. Using manual symlink creation..."
                setup_bin_manual
            }
        fi
    else
        log "GNU Stow not found. Using manual symlink setup..."
        setup_symlinks_manual
    fi
}

# backup existing configuration files
backup_existing_configs() {
    local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    local configs=(
        ".bashrc"
        ".vimrc"
        ".config/nvim"
        ".gitconfig"
        ".tmux.conf"
        ".claude/CLAUDE.md"
    )

    for config in "${configs[@]}"; do
        if [ -e "$HOME/$config" ] && [ ! -L "$HOME/$config" ]; then
            log "Backing up $config to $backup_dir/"
            mkdir -p "$backup_dir/$(dirname "$config")"
            mv "$HOME/$config" "$backup_dir/$config"
        fi
    done

    log "Backup created at: $backup_dir"
}

# manual symlink setup (fallback)
setup_symlinks_manual() {

    # shell configuration
    ln -sf "$DOTFILES_DIR/config/shell/profile" "$HOME/.profile"
    
    # create bashrc that sources our configuration
    cat > "$HOME/.bashrc" << 'EOF'
# source shell profile if it exists
if [ -f "$HOME/.config/shell/profile" ]; then
    . "$HOME/.config/shell/profile"
fi

# source system bashrc if it exists
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi
EOF
    
    # neovim configuration
    ln -sf "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
    
    # legacy vim support
    ln -sf "$DOTFILES_DIR/config/nvim/init.vim" "$HOME/.vimrc"
    
    # setup bin directory manually
    setup_bin_manual
}

# manual bin directory setup (fallback)
setup_bin_manual() {
    if [ -d "$DOTFILES_DIR/bin" ]; then
        log "Setting up bin directory manually..."
        
        # ensure .local/bin exists
        mkdir -p "$HOME/.local/bin"
        
        # create symlinks for all files in bin directory
        find "$DOTFILES_DIR/bin" -type f -executable | while read -r bin_file; do
            local filename=$(basename "$bin_file")
            local target="$HOME/.local/bin/$filename"
            
            log "Creating symlink for $filename"
            ln -sf "$bin_file" "$target"
        done
    fi
}

# setup bash configuration
setup_bash() {
    if command -v bash >/dev/null 2>&1; then
        log "Setting up Bash configuration..."

        # create bashrc
        cat > "$HOME/.bashrc" << 'EOF'
# source system bashrc first (so custom config can override)
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

# source shell profile (custom prompt and config)
if [ -f "$HOME/.config/shell/profile" ]; then
    . "$HOME/.config/shell/profile"
fi

# history configuration
HISTFILE=~/.bash_history
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups

# append to history instead of overwriting
shopt -s histappend

# check window size after each command
shopt -s checkwinsize

# enable programmable completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi
EOF

        # make bash the default shell if not already
        if [ "$SHELL" != "$(which bash)" ]; then
            log "Changing default shell to Bash..."
            chsh -s "$(which bash)"
        fi
    fi
}

# setup claude code configuration
setup_claude() {
    log "Setting up Claude Code configuration..."

    # symlink CLAUDE.md if it exists in repo
    if [ -f "$DOTFILES_DIR/.claude/CLAUDE.md" ]; then
        local claude_md="$HOME/.claude/CLAUDE.md"

        # backup existing file if it's not a symlink
        if [ -f "$claude_md" ] && [ ! -L "$claude_md" ]; then
            local backup_file="$claude_md.backup-$(date +%Y%m%d_%H%M%S)"
            log "Backing up existing CLAUDE.md to $backup_file"
            mv "$claude_md" "$backup_file"
        fi

        # create symlink
        log "Creating symlink for global CLAUDE.md..."
        ln -sf "$DOTFILES_DIR/.claude/CLAUDE.md" "$claude_md"
    else
        warn "Global CLAUDE.md not found in repository at $DOTFILES_DIR/.claude/CLAUDE.md"
    fi
}


# setup git configuration
setup_git() {
    log "Setting up Git configuration..."
    
    # check if git is installed
    if ! command -v git >/dev/null 2>&1; then
        warn "Git is not installed. Skipping git configuration."
        return
    fi
    
    # run the git setup script
    if [ -f "$DOTFILES_DIR/scripts/setup/git.sh" ]; then
        log "Running git configuration setup..."
        bash "$DOTFILES_DIR/scripts/setup/git.sh"
    else

        # fallback: just set up the gitconfig template
        if [ ! -f "$HOME/.gitconfig" ] && [ -f "$DOTFILES_DIR/config/git/gitconfig" ]; then
            warn "Git config template contains placeholder values."
            warn "Please update your git configuration with:"
            warn "  git config --global user.name \"Your Name\""
            warn "  git config --global user.email \"your.email@example.com\""
            ln -sf "$DOTFILES_DIR/config/git/gitconfig" "$HOME/.gitconfig"
        fi
    fi
}

# make custom tools executable
setup_custom_tools() {
    if [ -d "$DOTFILES_DIR/bin" ]; then
        log "Setting up custom tools..."
        find "$DOTFILES_DIR/bin" -type f -exec chmod +x {} \;
    fi
}

# install nerd fonts
install_nerd_fonts() {
    local os="$1"

    log "Installing Nerd Fonts..."

    case "$os" in
        debian)
            # create fonts directory
            local fonts_dir="$HOME/.local/share/fonts"
            mkdir -p "$fonts_dir"

            # download nerd fonts
            local fonts=(
                "FiraCode/Regular/FiraCodeNerdFont-Regular.ttf"
                "FiraCode/Bold/FiraCodeNerdFont-Bold.ttf"
                "JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf"
                "JetBrainsMono/Ligatures/Bold/JetBrainsMonoNerdFont-Bold.ttf"
                "SourceCodePro/SauceCodeProNerdFont-Regular.ttf"
                "SourceCodePro/SauceCodeProNerdFont-Bold.ttf"
                "Terminus/TerminessNerdFont-Regular.ttf"
                "Terminus/TerminessNerdFont-Bold.ttf"
            )

            local base_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts"

            # download consolas nerd font from third-party
            local consolas_fonts=(
                "ConsolasNerdFontMono-Regular.ttf"
                "ConsolasNerdFontMono-Bold.ttf"
                "ConsolasNerdFontMono-Italic.ttf"
                "ConsolasNerdFontMono-BoldItalic.ttf"
            )

            local consolas_url="https://github.com/ongyx/consolas-nf/raw/master"

            # download official nerd fonts
            for font_path in "${fonts[@]}"; do
                local font_name=$(basename "$font_path")
                local font_file="$fonts_dir/$font_name"

                if [ ! -f "$font_file" ]; then
                    log "Downloading $font_name..."
                    curl -fLo "$font_file" --create-dirs "$base_url/$font_path" || {
                        warn "Failed to download $font_name"
                    }
                fi
            done

            # download consolas nerd font
            for font_name in "${consolas_fonts[@]}"; do
                local font_file="$fonts_dir/$font_name"

                if [ ! -f "$font_file" ]; then
                    log "Downloading Consolas $font_name..."
                    curl -fLo "$font_file" --create-dirs "$consolas_url/$font_name" || {
                        warn "Failed to download Consolas $font_name"
                    }
                fi
            done

            # refresh font cache
            if command -v fc-cache >/dev/null 2>&1; then
                log "Refreshing font cache..."
                fc-cache -fv "$fonts_dir" >/dev/null 2>&1
            fi
            ;;
        *)
            error "Unsupported OS: $os. This installer only supports Debian/Ubuntu systems."
            exit 1
            ;;
    esac
}

# install vim-plug for neovim
setup_vim_plug() {
    local nvim_autoload_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload"
    local plug_vim="$nvim_autoload_dir/plug.vim"
    
    if [ ! -f "$plug_vim" ]; then
        log "Installing vim-plug for Neovim..."
        mkdir -p "$nvim_autoload_dir"
        curl -fLo "$plug_vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
}

# install node.js packages for language servers
setup_language_servers() {
    if command -v npm >/dev/null 2>&1; then
        log "Installing language servers..."

        # install bash language server
        npm install -g bash-language-server 2>/dev/null || {
            warn "Failed to install bash-language-server. LSP support for shell scripts may not work."
        }

        # install YAML language server
        npm install -g yaml-language-server 2>/dev/null || {
            warn "Failed to install yaml-language-server. LSP support for YAML files may not work."
        }
    else
        warn "npm not found. Language servers will not be installed."
        warn "Install Node.js and run:"
        warn "  npm install -g bash-language-server yaml-language-server"
    fi
}

# setup neovim using the dedicated setup script
setup_neovim() {
    if [ -f "$DOTFILES_DIR/scripts/setup/neovim.sh" ]; then
        log "Setting up Neovim..."
        bash "$DOTFILES_DIR/scripts/setup/neovim.sh"
    else
        warn "Neovim setup script not found. Skipping Neovim installation."
        warn "Please install Neovim manually or run:"
        warn "  bash $DOTFILES_DIR/scripts/setup/neovim.sh"
    fi
}

# main installation function
main() {
    log "Starting modern dotfiles installation..."
    
    # detect operating system
    local os
    os="$(detect_os)"
    log "Detected OS: $os"
    
    # create necessary directories
    create_directories
    
    # install system dependencies
    install_dependencies "$os"
    
    # install nerd fonts
    install_nerd_fonts "$os"

    # setup neovim (before vim-plug and language servers)
    setup_neovim

    # setup vim-plug
    setup_vim_plug

    # setup language servers
    setup_language_servers "$os"

    # setup custom tools (must run before setup_symlinks)
    setup_custom_tools

    # setup configuration symlinks
    setup_symlinks

    # setup claude code configuration
    setup_claude

    # setup git configuration
    setup_git

    # setup bash shell
    setup_bash

    log "Dotfiles installation complete!"
    log "Please restart your shell or run: source ~/.bashrc"
    
    # install neovim plugins
    if command -v nvim >/dev/null 2>&1; then
        log "Installing Neovim plugins..."
        nvim --headless +PlugInstall +qall 2>/dev/null || warn "Plugin installation failed. Run ':PlugInstall' manually in Neovim."
        
        # compile telescope-fzf-native
        local fzf_native_dir="$HOME/.local/share/nvim/plugged/telescope-fzf-native.nvim"
        if [ -d "$fzf_native_dir" ] && command -v make >/dev/null 2>&1; then
            log "Compiling telescope-fzf-native..."
            (cd "$fzf_native_dir" && make) || warn "Failed to compile telescope-fzf-native."
        fi
    fi
}

# show usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Install modern dotfiles configuration for Debian/Ubuntu systems.

Options:
    -h, --help      Show this help message
    -f, --force     Force installation (backup existing configs)
    -v, --verbose   Enable verbose output

Supported Systems:
    Debian/Ubuntu   (with bash shell)

Examples:
    $0              # Standard installation
    $0 --force      # Force installation with backup
    $0 --verbose    # Installation with debug output
EOF
}

# parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -f|--force)
            FORCE=1
            shift
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# run main function
main "$@"
