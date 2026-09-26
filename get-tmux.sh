#!/usr/bin/env bash
# Install tmux $VERSION from source. macOS: build against Homebrew deps. Linux (Debian/Ubuntu): apt deps.
set -euo pipefail
VERSION=3.7c

case "$(uname -s)" in
Darwin)
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required: https://brew.sh" >&2
    exit 1
  fi
  # Homebrew's tmux formula owns /usr/local/bin/tmux, so remove it before installing over that path.
  brew install libevent ncurses utf8proc pkgconf bison automake
  brew uninstall tmux 2>/dev/null || true
  export PKG_CONFIG_PATH="$(brew --prefix libevent)/lib/pkgconfig:$(brew --prefix ncurses)/lib/pkgconfig:$(brew --prefix utf8proc)/lib/pkgconfig"
  CONFIGURE_FLAGS="--prefix=/usr/local --enable-utf8proc"
  ;;
*)
  sudo apt-get -y remove tmux || true
  sudo apt-get -y install build-essential curl tar pkg-config libevent-dev libncurses-dev bison byacc
  CONFIGURE_FLAGS=""
  ;;
esac

BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT
cd "$BUILD_DIR"
curl -fsSL -O "https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz"
tar xf "tmux-${VERSION}.tar.gz"
cd "tmux-${VERSION}"
./configure ${CONFIGURE_FLAGS}
make
sudo make install
tmux -V
