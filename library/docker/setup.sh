#! /usr/bin/env bash

function install_depend() {

  # +-------------------------+
  # | Install native tooling  |
  # +-------------------------+

  packages=$PWD/library/docker/packages

  # Update
  sudo apt-get update

  # Install
  sudo apt-get install -y $(cat $packages)

}

function install_docker() {

  # +--------------------+
  # | Install docker CE  |
  # +--------------------+

  local_user=$USER

  # Install GPG key
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

  # Setup stable repo
  sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

  # Update
  sudo apt-get update

  # Install docker CE
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  # Run as local user
  sudo usermod -aG docker $local_user

}

function install_docker_compose() {

  # +-------------------------+
  # | Install docker compose  |
  # +-------------------------+

  # Install docker compose
  sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

  # Update permissions
  sudo chmod +x /usr/local/bin/docker-compose


}

function main() {

  install_docker
  install_docker_compose

}

main "$@"
