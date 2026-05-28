# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS and Debian dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow package that mirrors the target home directory structure. Stow creates symlinks from `~/dotfiles/<package>/...` into `$HOME/...`. `setup.sh` auto-detects the OS via `uname -s`.

## Setup

```bash
./setup.sh                       # macOS: symlink packages (auto-detected)
./setup.sh --profile desktop     # Debian daily-driver: CLI + Ghostty + fonts
./setup.sh --profile server      # Debian headless / CLI-only (default on Linux)
./setup.sh --profile wsl         # Windows Subsystem for Linux
./setup.sh --dry-run             # preview without changes (any profile)
```

On Linux, `setup.sh` invokes `scripts/install-packages.sh --profile <name>` automatically — installs apt packages plus alternative installers for Starship, mise, lazygit, eza, gh, 1Password CLI, and (for `desktop`) Ghostty via the [debian.griffo.io](https://debian.griffo.io/install-latest-ghostty-in-debian.html) apt repo and JetBrains Mono Nerd Font.

On Linux, setup also offers to make zsh your default login shell — an interactive `Make zsh your default shell? [Y/n]` prompt (default Yes) that runs `chsh`. Installing the `zsh` package alone does not change your login shell, so without this the zsh config never loads on a fresh Debian box. The prompt is skipped under `--dry-run` or when stdin is not a TTY, is idempotent (skips if the login shell is already zsh), and never aborts setup if `chsh` fails. After a switch, log out and back in (or open a new terminal) for zsh to take effect.

On macOS, install CLI tools and casks separately:
```bash
brew bundle install --file=~/dotfiles/brew/Brewfile
```

## Stow Packages

| Package | Target | What it configures |
|---------|--------|--------------------|
| `brew` | (not stowed, macOS only) | Brewfile with CLI tools, dev dependencies, fonts |
| `ghostty` | `~/.config/ghostty/` | Ghostty terminal (Everforest Dark Hard, cursor smear shader); stowed on `desktop` profile only on Linux |
| `git` | `~/.gitconfig`, `~/.gitignore_global`, `~/.gitmessage` | Git config with SSH signing, diff-so-fancy (identity via `scripts/git-setup.sh`) |
| `nvim` | `~/.config/nvim/` | Neovim with lazy.nvim plugin manager |
| `secrets` | `~/.local/bin/secrets` | 1Password CLI secrets loader (`secrets --load`, `--show`) |
| `starship` | `~/.config/starship.toml` | Starship prompt (Everforest palette) |
| `tmux` | `~/.config/tmux/` | Tmux with TPM, vim-tmux-navigator, tmux-yank, prefix `C-a` |
| `zsh` | `~/.zshrc`, `~/.config/zsh/` | Zsh with Zap plugin manager |

## Architecture

- **Stow convention**: Files inside each package directory are placed relative to `$HOME`. For example, `git/.gitconfig` becomes `~/.gitconfig`, and `nvim/.config/nvim/init.lua` becomes `~/.config/nvim/init.lua`.
- **OS detection**: `setup.sh` reads `uname -s` and branches between macOS and Linux. On Linux, `--profile {server|desktop|wsl}` selects which stow packages to apply (`server`/`wsl` skip `ghostty`); when omitted, defaults to `server` and prints a hint about `--profile desktop`. macOS-specific bits in shell config and `shared/environment.sh` are gated with `[[ "$(uname)" == "Darwin" ]]`.
- **`scripts/install-packages.sh`**: Debian package installer invoked by `setup.sh` on Linux. Installs apt packages (including `xclip` and `wl-clipboard` for tmux clipboard integration) and alternative installers for tools not in apt (Starship, mise, eza, gh, 1Password CLI, lazygit, shfmt, tealdeer, yq, fastfetch, JetBrains Mono Nerd Font, and Ghostty on `desktop`). `install_neovim()` requires Neovim >= 0.11 (mason-lspconfig 2.x depends on `vim.lsp.config` / `vim.lsp.enable`); when apt's Neovim is older it falls back to the upstream AppImage at `~/.local/bin/nvim`.
- **`.stow-local-ignore`**: Excludes repo-level files (setup.sh, shared/, README, etc.) from stow operations.
- **`shared/environment.sh`**: Shared env vars sourced by `.zshrc` (not stowed directly). Sets XDG dirs, editor, FZF config.
- **Local overrides**: `~/.zshrc.local` and `~/.gitconfig.local` are sourced but gitignored (`*.local` pattern). Machine-specific config goes there.
- **Git signing**: Commits are signed using SSH keys. Run `scripts/git-setup.sh` to configure identity and signing key (called automatically by `setup.sh`). The `[user]` section and signing key are stored in `~/.gitconfig.local` (gitignored). To reconfigure: `scripts/git-setup.sh`. To verify: `scripts/git-setup.sh --check`.
- **Default shell**: `setup.sh::switch_default_shell()` runs on Linux after stow/git-setup and before the "Next steps" block. It reads the current login shell from `getent passwd "$USER"` (field 7, not `$SHELL`); if it isn't zsh, it prompts `Make zsh your default shell? [Y/n]` (default Yes) and switches via `sudo chsh`. It is idempotent (skips when already zsh), treats non-TTY and `--dry-run` as No, ensures the resolved zsh path is in `/etc/shells` (appending via `sudo` as a safety net), and on failure `warn`s with the manual `chsh` command without aborting setup. A successful switch appends a re-login reminder to "Next steps"; the `wsl` profile additionally notes the Windows terminal may launch a different shell regardless of `chsh`.
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
