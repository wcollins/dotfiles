```
  __| | ___ | |_ / _(_) | ___  ___
 / _` |/ _ \| __| |_| | |/ _ \/ __|
| (_| | (_) | |_|  _| | |  __/\__ \
 \__,_|\___/ \__|_| |_|_|\___||___/

```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-only-blue)](https://github.com/wcollins/dotfiles)
[![Shell: Zsh](https://img.shields.io/badge/shell-zsh-green)](https://github.com/wcollins/dotfiles)
[![Editor: Neovim](https://img.shields.io/badge/editor-neovim-57A143)](https://neovim.io)

> macOS dotfiles managed with GNU Stow. Everforest theme everywhere.

Ghostty + Neovim + Tmux + Zsh + Starship — consistent Everforest Dark palette across everything.

## Quick Start

Requires macOS, [Homebrew](https://brew.sh), and [GNU Stow](https://www.gnu.org/software/stow/) (`brew install stow`).

```bash
git clone https://github.com/wcollins/dotfiles.git ~/dotfiles
cd ~/dotfiles

./setup.sh            # symlink packages into ~
./setup.sh --dry-run  # preview first
```

Then install dependencies:

```bash
brew bundle install --file=~/dotfiles/brew/Brewfile
```

> [!NOTE]
> Install [Zap](https://www.zapzsh.com) for zsh plugin management. Tmux plugins install with `<prefix> + I` after first launch.

## What's Inside

Each directory is a [GNU Stow](https://www.gnu.org/software/stow/) package — files mirror their target location under `$HOME`.

| Package | What it configures |
|---------|--------------------|
| `brew` | Brewfile — fzf, ripgrep, eza, lazygit, bat, zoxide, and more |
| `ghostty` | Ghostty terminal — Everforest Dark Hard, MesloLGS Nerd Font, cursor smear shader |
| `git` | Git config with SSH commit signing, diff-so-fancy, aliases |
| `nvim` | Neovim with lazy.nvim |
| `secrets` | 1Password CLI secrets loader (configurable vault/item) |
| `starship` | Starship prompt with Everforest palette |
| `tmux` | Tmux (prefix `C-a`), vim-tmux-navigator, tmux-yank, TPM |
| `zsh` | Zsh with Zap, fzf + zoxide integration, aliases, functions |

## Local Overrides

Machine-specific config goes in these files (gitignored via `*.local`):

| File | Purpose |
|------|---------|
| `~/.zshrc.local` | Shell customizations |
| `~/.gitconfig.local` | Git settings (SSH signing key goes here) |

## Post-Install

- Set your SSH signing key in `~/.gitconfig.local`
- Create `~/.zshrc.local` for machine-specific shell config
- Install tmux plugins: open tmux, press `C-a` then `I`
- For 1Password secrets: create `~/.secrets` with `OP_SERVICE_ACCOUNT_TOKEN`, then run `secrets --load`

## License
MIT - Do whatever you want with it

## Acknowledgments
Standing on the shoulders of giants and inspired by countless dotfile repos across GitHub. Evolved from my original [archive-dotfiles](https://github.com/wcollins/archive-dotfiles) project that went through many years of iteration and taught many lessons in the _pre-AI_ world. Shoutout to [Alex Perkins](https://github.com/bumpsinthewire) for convincing me to try [Ghostty](https://ghostty.org/).

---

## 💡 Remember
```
"Perfection is achieved not when there is nothing more to add,
but when there is nothing left to take away."

                                 - Antoine de Saint-Exupéry
```
