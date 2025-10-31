```
  __| | ___ | |_ / _(_) | ___  ___ 
 / _` |/ _ \| __| |_| | |/ _ \/ __|
| (_| | (_) | |_|  _| | |  __/\__ \
 \__,_|\___/ \__|_| |_|_|\___||___/
                                    
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash](https://img.shields.io/badge/shell-bash-green)](https://github.com/wcollins/dotfiles)
[![Editor: Neovim](https://img.shields.io/badge/editor-neovim-blue)](https://neovim.io)

> _Crafted configuration for the modern developer's workspace_

## ⚡️ Philosophy
Clean. Minimal. Functional. No bloat, no fluff—just carefully curated configurations that get out of your way and let you work.

## 📦 What's Inside
```
dotfiles/
├── config/          # XDG-compliant configurations
│   ├── git/         # Git config with GPG signing
│   ├── nvim/        # Neovim + LSP + Treesitter
│   ├── shell/       # Bash shell configuration
│   └── rg/          # Ripgrep configuration
├── bin/             # Custom tools & scripts
├── scripts/         # Setup & maintenance automation
│   └── setup/       # Modular installation scripts
└── install.sh       # Main installation script
```

## 📒 Quick Start
```bash
# clone the magic
git clone https://github.com/wcollins/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# one command to rule them all
./install.sh
```

That's it. The installer handles everything—dependencies, symlinks, fonts, the works.

## 🚀 Features
- Automatic dependency installation via apt
- GNU Stow for clean symlink management
- Backup existing configs before overwriting
- Modern Lua/Vimscript hybrid Neovim config
- Bash shell configuration with modular design

## Installation Options
```bash
# standard install
./install.sh

# force install (backs up existing configs)
./install.sh --force

# verbose mode for debugging
./install.sh --verbose
```

## Makefile Commands
```bash
make help          # show available commands
make install       # install dotfiles
make update        # pull latest changes & update plugins
make backup        # backup current configs
make clean         # clean caches
make test          # validate configurations
make info          # show system information
```

## Customization

### Local Overrides
Drop your machine-specific configs in:
- `~/.config/shell/local` - Shell customizations
- `~/.config/nvim/local.vim` - Neovim customizations
- `~/.gitconfig.local` - Git settings

These won't be tracked by Git.

### Extending
1. Add new configs to `config/`
2. Scripts go in `scripts/setup/`
3. Utilities belong in `bin/`
4. Run `make install` to apply changes

## Requirements
- Git 2.0+
- Bash 4.0+
- GNU Stow (auto-installed)
- curl/wget for downloads

## Supported Systems
- **Ubuntu** (20.04+)
- **Debian** (11+)

## Troubleshooting

### Symlinks Already Exist
```bash
make backup        # backup existing configs
make install-force # force reinstall
```

### Neovim Plugins Not Loading
```bash
nvim +PlugInstall +qall  # install plugins
nvim +PlugUpdate +qall   # update plugins
```

### Fonts Not Displaying Correctly
The installer includes Nerd Fonts. Set your terminal to use:
- FiraCode Nerd Font
- JetBrains Mono Nerd Font
- Source Code Pro Nerd Font
- Consolas Nerd Font

### Shell Not Sourcing Configs
```bash
# for bash
echo 'source ~/.config/shell/profile' >> ~/.bashrc
source ~/.bashrc
```

## Philosophy behind decisions
- **XDG compliance**: configs live in `~/.config` where they belong
- **GNU Stow**: declarative symlink management beats custom scripts
- **Modular shell**: clean, modular bash configuration
- **Native tools first**: leverage apt package manager
- **Minimal dependencies**: only what's essential
- **Version control friendly**: Everything in Git, no generated files

## License
MIT - Do whatever you want with it

## Acknowledgments
Standing on the shoulders of giants and inspired by countless dotfile repos across GitHub. Evolved from my original [archive-dotfiles](https://github.com/wcollins/archive-dotfiles) project that went through many years of iteration and taught many lessons in the _pre-AI_ world.

---

## 💡 Remember
```
"Perfection is achieved not when there is nothing more to add,
but when there is nothing left to take away."

                                 - Antoine de Saint-Exupéry
```
