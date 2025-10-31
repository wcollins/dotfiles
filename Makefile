# dotfiles makefile
# dotfiles management

.PHONY: help install uninstall update backup clean test

# default target
help:
	@echo "Modern Dotfiles Management"
	@echo ""
	@echo "Available commands:"
	@echo "  install    - Install dotfiles configuration"
	@echo "  uninstall  - Remove dotfiles symlinks"
	@echo "  update     - Update dotfiles and dependencies"
	@echo "  backup     - Create backup of current configurations"
	@echo "  clean      - Clean temporary files and caches"
	@echo "  test       - Test configuration validity"
	@echo "  help       - Show this help message"

# install dotfiles
install:
	@echo "Installing dotfiles..."
	@./install.sh

# force install (with backup)
install-force:
	@echo "Force installing dotfiles with backup..."
	@./install.sh --force

# uninstall dotfiles (remove symlinks)
uninstall:
	@echo "Uninstalling dotfiles..."
	@if command -v stow >/dev/null 2>&1; then \
		cd $(PWD)/config && stow -D -t $(HOME)/.config . 2>/dev/null || true; \
		[ -d $(PWD)/bin ] && cd $(PWD) && stow -D -t $(HOME)/.local bin 2>/dev/null || true; \
		echo "Symlinks removed with stow"; \
	else \
		echo "Manual removal required - check ~/.bashrc, ~/.config/nvim, etc."; \
	fi
	@if [ -L $(HOME)/.claude/CLAUDE.md ]; then \
		rm $(HOME)/.claude/CLAUDE.md; \
		echo "Removed global CLAUDE.md symlink"; \
	fi

# update dotfiles from repository
update:
	@echo "Updating dotfiles..."
	@git pull origin main
	@if command -v nvim >/dev/null 2>&1; then \
		nvim --headless +PlugUpdate +qall; \
		echo "Neovim plugins updated"; \
	fi

# create backup of current configurations
backup:
	@echo "Creating backup..."
	@backup_dir="$(HOME)/.dotfiles-backup-$$(date +%Y%m%d_%H%M%S)"; \
	mkdir -p "$$backup_dir"; \
	for config in .bashrc .zshrc .vimrc .config/nvim .gitconfig .tmux.conf .claude/CLAUDE.md; do \
		if [ -e "$(HOME)/$$config" ] && [ ! -L "$(HOME)/$$config" ]; then \
			mkdir -p "$$backup_dir/$$(dirname $$config)"; \
			cp -r "$(HOME)/$$config" "$$backup_dir/$$config"; \
			echo "Backed up: $$config"; \
		fi; \
	done; \
	echo "Backup created at: $$backup_dir"

# clean temporary files and caches
clean:
	@echo "Cleaning temporary files..."
	@rm -rf $(HOME)/.cache/nvim/{backup,swap,undo}/*
	@echo "Neovim caches cleaned"

# test configuration files
test:
	@echo "Testing configuration files..."
	@echo "Checking shell syntax..."
	@bash -n config/shell/profile config/shell/functions config/shell/aliases config/shell/exports
	@if command -v nvim >/dev/null 2>&1; then \
		echo "Checking Neovim configuration..."; \
		nvim --headless -c "checkhealth" -c "qa" 2>/dev/null || echo "Neovim config test completed"; \
	fi
	@echo "Configuration tests completed"

# development targets
dev-setup:
	@echo "Setting up development environment..."
	@./install.sh
	@echo "Development environment ready"

# show system information
info:
	@echo "System Information:"
	@echo "OS: $$(uname -s)"
	@echo "Shell: $$SHELL"
	@echo "Git: $$(git --version 2>/dev/null || echo 'Not installed')"
	@echo "Neovim: $$(nvim --version 2>/dev/null | head -1 || echo 'Not installed')"
	@echo "Stow: $$(stow --version 2>/dev/null | head -1 || echo 'Not installed')"
