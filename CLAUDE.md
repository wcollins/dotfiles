# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages development environment configurations using GNU Stow for declarative symlink management. The repository follows XDG Base Directory Specification principles and supports Debian and Ubuntu Linux systems.

## Key Architecture Principles

**Symlink Management with GNU Stow**: The installation system uses GNU Stow to create symlinks from `config/` to `~/.config/`. This is the core mechanism - understand that files in `config/` get stowed to the corresponding location in the user's home directory.

**Shell Configuration**: The shell configuration in `config/shell/` is designed for bash, the default shell on Debian/Ubuntu systems.

**Bash Configuration Order**: The `~/.bashrc` file sources configurations in this specific order to ensure custom settings take precedence:
1. System bashrc (`/etc/bash.bashrc`) - sourced first
2. Custom shell profile (`~/.config/shell/profile`) - sourced second to override system defaults

The `profile` file then sources other modular files in this order:
1. `exports` - environment variables (including XDG paths, EDITOR, ripgrep config)
2. `functions` - shell functions
3. `aliases` - command aliases
4. `prompt` - prompt configuration (colored bash prompt with git branch)
5. `linux` - Linux-specific configs (package manager aliases, ls colors, system tools)
6. `local` - machine-specific overrides (not tracked in git)

**Neovim Plugin System**: Uses vim-plug with a Lua/Vimscript hybrid configuration:
- `init.vim` - Entry point, loads vim-plug and sources other configs
- `settings.vim` - Editor settings
- `theme.vim` - Color scheme configuration
- `keymaps.vim` - Key mappings
- `plugins.vim` - Plugin configurations (mostly Lua code)

The plugin configuration heavily uses Lua for modern Neovim features (LSP, Treesitter, completion).

## Installation and Management Commands

### Standard Installation
```bash
./install.sh                # Interactive installation
./install.sh --force        # Force install with backup of existing configs
./install.sh --verbose      # Debug mode
make install                # Same as ./install.sh
make install-force          # Force install via Makefile
```

**Shell Configuration:**
- **Debian/Ubuntu**: Bash (default shell)

### Testing and Validation
```bash
make test                   # Test configuration file syntax
```

This checks shell scripts with `bash -n` and runs Neovim's `:checkhealth`.

### Updating
```bash
make update                 # Pull latest changes from git and update Neovim plugins
```

This runs `git pull origin main` and `nvim --headless +PlugUpdate +qall`.

### Backup and Cleanup
```bash
make backup                 # Backup existing configs to timestamped directory
make clean                  # Clean Neovim caches
make uninstall              # Remove symlinks created by Stow
```

### Development Information
```bash
make info                   # Show system info (OS, shell, git, nvim, stow versions)
```

## Directory Structure

```
dotfiles/
├── .claude/            # Global Claude Code preferences (symlinked to ~/.claude/)
│   └── CLAUDE.md       # Universal coding style and preferences
├── config/             # XDG-compliant configurations (stowed to ~/.config)
│   ├── git/            # Git configuration templates
│   ├── nvim/           # Neovim configuration
│   ├── rg/             # Ripgrep configuration
│   └── shell/          # Shell configuration
│       ├── profile     # Main shell profile (sources other files)
│       ├── exports     # Environment variables
│       ├── functions   # Shell functions
│       ├── aliases     # Command aliases
│       ├── prompt      # Bash prompt configuration
│       └── linux       # Linux-specific configuration
├── bin/                # Custom tools/scripts (stowed to ~/.local/bin)
├── scripts/            # Installation and setup scripts
│   └── setup/          # Modular setup scripts for specific tools
├── install.sh          # Main installation script
├── Makefile            # Convenience commands
└── CLAUDE.md           # Project-specific instructions (this file)
```

## Important Installation Details

**Dependency Installation**: The `install.sh` script detects the OS and installs packages using apt. Core dependencies include: git, curl, wget, bash, neovim, tmux, fzf, ripgrep, fd-find, bat, stow, build-essential, jq, fastfetch.

**Shell Configuration**: The installer configures bash as the default shell, sourcing the shell profile from `~/.config/shell/profile`.

**Font Installation**: The installer downloads and installs Nerd Fonts (FiraCode, JetBrains Mono, Source Code Pro, Terminus, Consolas) to `~/.local/share/fonts` and refreshes the font cache.

**Git Configuration**: `scripts/setup/git.sh` handles interactive git configuration including user name/email, editor, credential helpers, and optional GPG signing key generation.

**Neovim Plugins**: After symlinking configs, the installer runs `nvim --headless +PlugInstall +qall` to install plugins and compiles telescope-fzf-native with make.

**Language Servers**: If npm is available, the installer installs bash-language-server and yaml-language-server globally.

**Claude Code Configuration**: The installer manages Claude Code configuration through a two-file approach:
- **Global CLAUDE.md** (`.claude/CLAUDE.md` → `~/.claude/CLAUDE.md`): Universal coding preferences, commit conventions, and style guidelines that apply to all projects. Symlinked to keep preferences synchronized across systems.
- **Project CLAUDE.md** (this file): Dotfiles-specific architecture, installation procedures, and repository workflows.

Both files work together - Claude Code automatically aggregates them based on your working directory, with project-specific instructions complementing global preferences.

## Configuration Customization

**Linux-Specific Shell Configuration**: The repository includes Linux-specific shell configurations that are automatically sourced:
- `config/shell/linux` - Linux-specific settings including:
  - GNU coreutils aliases (`ls --color=auto`, colored grep)
  - Package manager shortcuts (apt-based for Debian/Ubuntu)
  - systemd service management aliases
  - xdg-open and xclip clipboard integration

**Ripgrep Configuration**: `config/rg/config` provides sensible defaults:
- Smart case searching with hidden file support
- Exclusion patterns for common build/cache directories
- Color customization for search output

**Machine-Specific Overrides**: Users can create machine-specific overrides that won't be tracked in git:
- `~/.config/shell/local` - Shell customizations
- `~/.config/nvim/local.vim` - Neovim customizations
- `~/.gitconfig.local` - Git settings

## Neovim LSP Configuration

The Neovim setup uses Mason for LSP server management. The configuration in `config/nvim/plugins.vim` (lines 20-74) sets up:

- **Mason** for managing LSP servers
- **mason-lspconfig** with automatic installation of: pyright, ts_ls, lua_ls, rust_analyzer, bashls, jsonls, yamlls
- **nvim-cmp** for completion with LuaSnip integration
- **Treesitter** for syntax highlighting with auto-install for multiple languages

LSP servers are configured via handlers in `mason-lspconfig.setup()`, with lua_ls getting custom configuration to recognize the vim global.

## Setup Scripts

The `scripts/setup/` directory contains modular installation scripts for specific tools:
- `git.sh` - Interactive git configuration
- `docker.sh` - Docker installation
- `ansible.sh` - Ansible setup
- `claude-code.sh` - Claude Code installation
- `containerlab.sh` - Containerlab setup
- `uv.sh` - UV Python package manager
- `vhs.sh` - VHS terminal recorder
- `1password-cli.sh` - 1Password CLI

These can be run independently or are called by the main `install.sh` script.

## Common Modifications

When modifying configurations:

1. **Shell changes**: Edit files in `config/shell/` and run `source ~/.config/shell/profile` to reload
2. **Neovim changes**: Edit files in `config/nvim/` and restart Neovim or run `:source $MYVIMRC`
3. **Adding new configs**: Place in `config/` subdirectory, then run `make install` to restow
4. **Adding scripts/tools**: Place executable scripts in `bin/`, run `make install` to restow to `~/.local/bin`
5. **Test before committing**: Run `make test` to validate shell and Neovim configurations

## Git Workflow

This repository uses:
- **Main branch**: `main`
- **Development branch**: `develop`

When creating pull requests, typically target the `main` branch unless working on experimental features.
