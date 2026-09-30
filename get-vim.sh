#!/usr/bin/env bash
# Install vim. macOS: Homebrew. Linux (Debian/Ubuntu): build $VERSION from source.
# Idempotent: skips when an up-to-date vim is already installed.
set -euo pipefail
VERSION=9.2.1132

if [ "$(uname -s)" = "Darwin" ]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required: https://brew.sh" >&2
    exit 1
  fi
  if ! brew list --versions vim >/dev/null; then
    brew install vim
  elif [ -n "$(brew outdated --quiet vim)" ]; then
    brew upgrade vim
  else
    echo "vim is up to date ($(brew list --versions vim))."
  fi
  exit 0
fi

# True if version $1 >= version $2.
version_ge() {
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

# Installed version as <major>.<minor>.<patch>, e.g. 9.2.1132.
installed_version() {
  vim --version | awk '
    NR == 1 { for (i = 1; i <= NF; i++) if ($i == "IMproved") mm = $(i + 1) }
    /^Included patches:/ { split($3, r, "-"); p = r[2] + 0 }
    END { print mm "." p }'
}

if command -v vim >/dev/null 2>&1; then
  INSTALLED=$(installed_version)
  if version_ge "$INSTALLED" "$VERSION"; then
    echo "vim $INSTALLED is already installed (>= $VERSION)."
    exit 0
  fi
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
hash -r
vim --version | head -2
