#!/usr/bin/env bash
# Install vim. macOS: Homebrew. Linux (Debian/Ubuntu): build $VERSION from source.
set -euo pipefail
VERSION=9.2.1132

if [ "$(uname -s)" = "Darwin" ]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required: https://brew.sh" >&2
    exit 1
  fi
  brew install vim || brew upgrade vim
  exit 0
fi

sudo apt-get -y install build-essential wget tar libncurses-dev

BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT
cd "$BUILD_DIR"
wget -O "vim-${VERSION}.tar.gz" "https://github.com/vim/vim/archive/refs/tags/v${VERSION}.tar.gz"
tar xf "vim-${VERSION}.tar.gz"
cd "vim-${VERSION}"
./configure --with-features=huge
make
sudo make install
vim --version | head -2
