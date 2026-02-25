# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow package that mirrors the target home directory structure. Stow creates symlinks from `~/dotfiles/<package>/...` into `$HOME/...`.

## Setup

```bash
./setup.sh            # symlink all packages via stow
./setup.sh --dry-run  # preview without changes
```

After setup, install dependencies:
```bash
brew bundle install --file=~/dotfiles/brew/Brewfile
```

## Stow Packages

| Package | Target | What it configures |
|---------|--------|--------------------|
| `brew` | (not stowed) | Brewfile with CLI tools, dev dependencies, fonts |
| `ghostty` | `~/.config/ghostty/` | Ghostty terminal (Everforest Dark Hard, cursor smear shader) |
| `git` | `~/.gitconfig`, `~/.gitignore_global`, `~/.gitmessage` | Git config with SSH signing, diff-so-fancy (identity via `scripts/git-setup.sh`) |
| `nvim` | `~/.config/nvim/` | Neovim with lazy.nvim plugin manager |
| `secrets` | `~/.local/bin/secrets` | 1Password CLI secrets loader (`secrets --load`, `--show`) |
| `starship` | `~/.config/starship.toml` | Starship prompt (Everforest palette) |
| `tmux` | `~/.config/tmux/` | Tmux with TPM, vim-tmux-navigator, tmux-yank, prefix `C-a` |
| `zsh` | `~/.zshrc`, `~/.config/zsh/` | Zsh with Zap plugin manager |

## Architecture

- **Stow convention**: Files inside each package directory are placed relative to `$HOME`. For example, `git/.gitconfig` becomes `~/.gitconfig`, and `nvim/.config/nvim/init.lua` becomes `~/.config/nvim/init.lua`.
- **`.stow-local-ignore`**: Excludes repo-level files (setup.sh, shared/, README, etc.) from stow operations.
- **`shared/environment.sh`**: Shared env vars sourced by `.zshrc` (not stowed directly). Sets XDG dirs, editor, FZF config.
- **Local overrides**: `~/.zshrc.local` and `~/.gitconfig.local` are sourced but gitignored (`*.local` pattern). Machine-specific config goes there.
- **Git signing**: Commits are signed using SSH keys. Run `scripts/git-setup.sh` to configure identity and signing key (called automatically by `setup.sh`). The `[user]` section and signing key are stored in `~/.gitconfig.local` (gitignored). To reconfigure: `scripts/git-setup.sh`. To verify: `scripts/git-setup.sh --check`.
- **mise**: Runtime version manager activated in `.zshrc` (guarded). Manages Go, Node, and other tool versions per-project. Installed via Brewfile.
- **secrets**: `secrets --load` reads `OP_SERVICE_ACCOUNT_TOKEN`, `VAULT`, and `ITEM` from `~/.secrets`, fetches env vars from 1Password, and writes exports to `~/.vars`. On first run, prompts for vault and item names and saves them. Use `--vault`/`--item` flags for one-time overrides. The `.zshrc` sources `~/.vars` automatically. Both `~/.secrets` and `~/.vars` are local-only (not committed).

## Linting

```bash
shellcheck setup.sh                    # lint shell scripts
shfmt -d setup.sh                      # check shell formatting
```

## Conventions

- Consistent Everforest color theme across ghostty, tmux, starship, and nvim
- EditorConfig: 2-space indent, UTF-8, LF line endings, final newline
- Shell scripts target bash (shellcheck configured with `shell=bash`)
- Tmux plugins managed by TPM (cloned into `tmux/.config/tmux/plugins/`, gitignored)
- Zsh plugins managed by Zap
