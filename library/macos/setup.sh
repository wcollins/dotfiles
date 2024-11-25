#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# status
print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

# errors
print_error() {
    echo -e "${RED}Error:${NC} $1"
}

# warnings
print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# install oh-my-zsh
install_oh_my_zsh() {
    print_status "Setting up Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_warning "Oh My Zsh is already installed"
    else
        print_status "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        # Backup existing .zshrc if it exists
        if [ -f "$HOME/.zshrc" ]; then
            print_status "Backing up existing .zshrc to .zshrc.backup"
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
        fi

        # Set Zsh as default shell
        if [ "$SHELL" != "/bin/zsh" ]; then
            print_status "Setting Zsh as default shell..."
            chsh -s $(which zsh)
        fi
    fi
}

# is homebrew installed?
if ! command -v brew &> /dev/null; then
    print_error "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ $? -ne 0 ]; then
        print_error "Failed to install Homebrew. Exiting..."
        exit 1
    fi
fi

# install homebrew cask
install_cask() {
    print_status "Installing $1..."
    if brew list --cask $1 &>/dev/null; then
        print_warning "$1 is already installed"
    else
        brew install --cask $1
        if [ $? -ne 0 ]; then
            print_error "Failed to install $1"
            return 1
        fi
    fi
}

# install homebrew packages
install_package() {
    print_status "Installing $1..."
    if brew list $1 &>/dev/null; then
        print_warning "$1 is already installed"
    else
        brew install $1
        if [ $? -ne 0 ]; then
            print_error "Failed to install $1"
            return 1
        fi
    fi
}

# update homebrew
print_status "Updating Homebrew..."
brew update

# install cask apps
CASKS=(
    "iterm2"
    "visual-studio-code"
    "microsoft-office"
    "slack"
    "camtasia"
    "discord"
    "postman"
)

for cask in "${CASKS[@]}"; do
    install_cask $cask
done

# install other homebrew packages
PACKAGES=(
    "hugo"
    "tfenv"
    "terraform-docs"
    "zsh-autosuggestions"
    "handbrake"
)

for package in "${PACKAGES[@]}"; do
    install_package $package
done

# install zsh-autosuggestions
print_status "Setting up zsh-autosuggestions..."
if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
else
    print_warning "zsh-autosuggestions is already installed"
fi

# install powerline fonts
print_status "Installing Powerline fonts..."
if [ ! -d "./fonts" ]; then
    git clone https://github.com/powerline/fonts.git --depth=1
    cd fonts
    ./install.sh
    cd ..
    rm -rf fonts
else
    print_warning "Fonts directory already exists"
fi

# install pip
print_status "Installing pip..."
if ! command -v pip3 &> /dev/null; then
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    /Library/Developer/CommandLineTools/usr/bin/python3 get-pip.py
    rm get-pip.py
else
    print_warning "pip3 is already installed"
fi

# upgrade pip
print_status "Upgrading pip..."
/Library/Developer/CommandLineTools/usr/bin/python3 -m pip install --upgrade pip

print_status "Installation complete!"

# manual steps
echo -e "\n${YELLOW}Post-installation steps:${NC}"
echo "1. Configure your shell to use zsh-autosuggestions by adding the following to your ~/.zshrc:"
echo "   plugins=(... zsh-autosuggestions)"
echo "2. Restart your terminal or run 'source ~/.zshrc' to apply changes"