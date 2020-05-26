#! /usr/bin/env bash

# Vars
temp=~/hugo_dir

# Create working dir
mkdir -p $temp && cd $temp

# Get newest .deb
wget $(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep -oP '"browser_download_url": "\K(.*)hugo_extended(.*)Linux-64bit.deb')

# Install hugo
sudo dpkg -i hugo_extended*Linux-64bit.deb

# Clean
sudo rm -rf $temp