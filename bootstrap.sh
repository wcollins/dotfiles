#! /usr/bin/env bash
set -o pipefail

function usage() {

  cat << EOF
    NAME
        dotfiles

    SYNOPSIS
        bootstrap [options]

    DESCRIPTION
        Dotfiles aim to minimize the time spent on redundant things like setting up a repeatable dev environment. 

    OPTIONS

        --docker
            Install docker and docker-compose stable release.

        --hugo
            Install Hugo static site generator.

        --shell
            Configure default shell environment for Debian or derivatives of Debian.

        --terraform
            Install latest version of Terraform locally at ~/bin.
              
EOF

}

case $1 in

    --docker) ./library/docker/setup.sh;;
    --hugo) ./library/hugo/setup.sh;;
    --shell) ./library/shell/setup.sh;;
    --terraform) ./library/terraform/setup.sh;;
    --usage) usage;;
    --help) usage;;
    *) usage; exit 1;;

esac