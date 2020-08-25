#! /usr/bin/env bash

function install_depend() {

  # +-------------------------+
  # | Install native tooling  |
  # +-------------------------+

  packages=$PWD/library/shell/packages

  # Update
  sudo apt-get update

  # Install
  sudo apt-get install -y $(cat $packages)

}

function backup_defaults() {

    # +------------------+
    # | Backup defaults  |
    # +------------------+

    defaults=".bashrc .bash_aliases .bash_functions .profile .vimrc .vim"

    mkdir -pv ~/dotfiles_default

    # Backup files if any should exist
    for file in $defaults
    do
        if [ -f ~/$file ]
        then
            mv -vf ~/$file ~/dotfiles_default
        fi
    done

}

function link_dotfiles() {

    # +-----------------+
    # | Link new files  |
    # +-----------------+

    dotfiles="bashrc bash_aliases bash_functions fonts profile vimrc vim"

    # Create sym links
    for file in $dotfiles
    do
        ln -s ~/dotfiles/$file ~/.$file
    done

    # Build font cache
    fc-cache -vf

}

function git_setup() {

    # +------------+
    # | Setup git  |
    # +------------+

    # Check for .gitconfig
    if [ ! -e ~/.gitconfig ]
    then

        # Get user / email
        read -p "git setup - User: " git_user
        read -p "git setup - Email: " git_email

        # Create .gitconfig
        git config --global user.name "$git_user"
        git config --global user.email "$git_email"
        git config --global pull.ff only

    else
        echo "~/.gitconfig already exists. Exiting"
        exit 1
    fi

}

function python_setup() {

    # +------------------------+
    # | Setup user python env  |
    # +------------------------+

    # upgrade pip globally
    sudo pip3 install --upgrade pip

    # install user pipenv
    pip install --user pipenv


}

function vundle_setup() {

    # +--------------------+
    # | Setup vim plugins  |
    # +--------------------+

    # Create bundle dir
    mkdir -pv ~/.vim/bundle

    # Clone vundle
    git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim

    # Install plugins
    vim +PluginInstall +qall

    # Setup YCM
    # ~/.vim/bundle/YouCompleteMe/install.py

}

function main() {

  install_depend
  backup_defaults
  link_dotfiles
  vundle_setup
  git_setup
  python_setup

}

main "$@"
