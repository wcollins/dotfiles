#! /usr/bin/env bash
# ~/dotfiles/library/hugo/setup.sh
set -o pipefail

DEFAULT_BIN_DIR="/usr/local/bin" 

# Single optional argument is directory in which to install hugo
BIN_DIR=${1:-"$DEFAULT_BIN_DIR"}
BIN_PATH="$(which hugo)"
declare -A ARCHES
ARCHES=( ["arm64"]="ARM64" ["aarch64"]="ARM64"  ["x86_64"]="64bit" ["arm32"]="ARM"  ["armhf"]="ARM" )
ARCH=$(arch)

if [ -z "${ARCHES[$ARCH]}" ]; then
  echo  Your machine kernel architecture $ARCH is not supported by this script, aborting
  exit 1
fi


INSTALLED="$(hugo version 2>/dev/null | cut -d'v' -f2 | cut -c 3-5)"
CUR_VERSION=${INSTALLED:-"None"}
NEW_VERSION="$(curl -u $GITHUB_USER:$GITHUB_TOKEN -s https://api.github.com/repos/gohugoio/hugo/releases/latest  \
             | grep tag_name \
             | cut -d'.' -f2 | cut -d'"' -f1)"

echo "Hugo:  Current Version: $CUR_VERSION => New Version: $NEW_VERSION"

if [ -z "$NEW_VERSION" ]; then
  echo  Unable to retrieve new version number - Likely you have reached github anonymous limit
  echo  set environment variable `$GITHUB_USER` and `$GITHUB_TOKEN` and try again
  exit 1
fi

if ! [ $NEW_VERSION = $CUR_VERSION ]; then

  echo "Installing version $NEW_VERSION"
  echo "This machine's architecture is $ARCH"
  echo "Downloading Tarball Linux-${ARCHES[$ARCH]}"

  pushd /tmp/ > /dev/null

  curl -u $GITHUB_USER:$GITHUB_TOKEN -s https://api.github.com/repos/gohugoio/hugo/releases/latest \
  | grep "browser_download_url.*hugo_[^extended].*_Linux-${ARCHES[$ARCH]}\.tar\.gz" \
  | cut -d ":" -f 2,3 \
  | tr -d \" \
  | wget --user=-u $GITHUB_USER --password=$GITHUB_TOKEN -qi -

  TARBALL="$(find . -name "*Linux-${ARCHES[$ARCH]}.tar.gz" 2>/dev/null)"
  echo Expanding Tarball
  tar -xzf $TARBALL

  chmod +x hugo

if [ -w $BIN_DIR ]; then
  echo "Installing hugo to $BIN_DIR"
  mv hugo -f $BIN_DIR
else
    echo "sudo Installing hugo to $BIN_DIR"
    sudo mv -f hugo $BIN_DIR
fi

  popd > /dev/null

  BIN_PATH="$(which hugo)"
  if [ -z "$BIN_PATH" ]; then
  printf "WARNING: Installed Hugo Binary in $BIN_DIR is not in your environment path\nPATH=$PATH\n"
else
  if [ "$BIN_DIR/hugo" != "$BIN_PATH" ]; then
  echo "WARNING: Just installed Hugo binary, $BIN_DIR , conflicts with existing Hugo in $BIN_PATH"
  echo "add $BIN_DIR to path and delete $BIN_PATH"
else
  echo "--- Confirmation ---"
  printf "New Hugo binary version in $BIN_DIR is\n $($BIN_DIR/hugo version)\n"
  fi
fi

else
  echo Latest version already installed in $BIN_PATH
fi
