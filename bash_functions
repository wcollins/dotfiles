#! /usr/bin/env bash
# ~/.bash_functions

function extract() {

    # +---------------------------------+
    # | Extract common archive formats  |
    # +---------------------------------+

    if [ -z "$1" ]
    then

        # Display usage if no parameters are given
        echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"

    else
        if [ -f "$1" ]
        then
            NAME=${1%.*}

            # mkdir $NAME && cd $NAME
            case "$1" in
                *.tar.bz2)   tar xvjf ./"$1"    ;;
                *.tar.gz)    tar xvzf ./"$1"    ;;
                *.tar.xz)    tar xvJf ./"$1"    ;;
                *.lzma)      unlzma ./"$1"      ;;
                *.bz2)       bunzip2 ./"$1"     ;;
                *.rar)       unrar x -ad ./"$1" ;;
                *.gz)        gunzip ./"$1"      ;;
                *.tar)       tar xvf ./"$1"     ;;
                *.tbz2)      tar xvjf ./"$1"    ;;
                *.tgz)       tar xvzf ./"$1"    ;;
                *.zip)       unzip ./"$1"       ;;
                *.Z)         uncompress ./"$1"  ;;
                *.7z)        7z x ./"$1"        ;;
                *.xz)        unxz ./"$1"        ;;
                *.exe)       cabextract ./"$1"  ;;
                *)           echo "extract: '$1' - unknown archive method" ;;
            esac

        else
            echo "'$1' - file does not exist"
        fi
    fi
}

function keygen() {

    # +----------------------------------------+
    # | Generates public/private RSA key pair  |
    # +----------------------------------------+

    # Args
    read -p "Comment: " comment
    read -p "Filename: " file_name
    read -p "Bit length: " bit_length
    key_path=$HOME/.ssh/keys/$file_name

    # Generate key pair
    ssh-keygen \
        -t rsa \
        -C $comment \
        -f $key_path \
        -b $bit_length

}

function update() {

    # +---------------------------+
    # | Install updates - Debian  |
    # +---------------------------+

    cmd_list="update upgrade dist-upgrade autoremove clean"

    # Run!
    for cmd in $cmd_list
    do
        sudo apt-get -y $cmd
    done

}

function clean() {

    # +---------------------------+
    # | Clean TF directory        |
    # +---------------------------+

    file_list=".terraform.lock.hcl terraform.tfstate terraform.tfstate.backup tfplan"

    rm -rf .terraform

    for file in $file_list
    do
        if [ -f $file ]
        then
            rm -rf $file
        fi
    done
}
