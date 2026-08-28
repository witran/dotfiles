#!/bin/bash
# VERSION=2.8
set -e
VERSION=3.5a

case "$(uname -s)" in
Darwin)
  # Homebrew's tmux is newer than $VERSION, so build from source. Its formula
  # owns /usr/local/bin/tmux, so remove it before installing over that path.
  brew install libevent ncurses utf8proc pkgconf bison automake
  brew uninstall tmux 2>/dev/null || true
  export PKG_CONFIG_PATH="$(brew --prefix libevent)/lib/pkgconfig:$(brew --prefix ncurses)/lib/pkgconfig:$(brew --prefix utf8proc)/lib/pkgconfig"
  CONFIGURE_FLAGS="--prefix=/usr/local --enable-utf8proc"
  ;;
*)
  sudo apt-get -y remove tmux
  sudo apt-get -y install build-essential curl tar libevent-dev libncurses-dev bison byacc
  CONFIGURE_FLAGS=""
  ;;
esac

curl -fsSL -O https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz
tar xf tmux-${VERSION}.tar.gz
rm -f tmux-${VERSION}.tar.gz
cd tmux-${VERSION}
./configure ${CONFIGURE_FLAGS}
make
sudo make install
cd -
sudo mkdir -p /usr/local/src
sudo rm -rf /usr/local/src/tmux-*
sudo mv tmux-${VERSION} /usr/local/src
