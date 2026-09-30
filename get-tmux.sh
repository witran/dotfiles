#!/usr/bin/env bash
# Install tmux $VERSION from source. macOS: build against Homebrew deps. Linux (Debian/Ubuntu): apt deps.
# Idempotent: skips when an up-to-date tmux is already installed.
set -euo pipefail
VERSION=3.7c

# tmux.conf loads plugins through TPM; without it `run -b tpm` exits 127.
install_tpm() {
  local dir="$HOME/.tmux/plugins/tpm"
  if [ -d "$dir/.git" ]; then
    echo "tpm is already installed."
  else
    git clone https://github.com/tmux-plugins/tpm "$dir"
  fi
  # install_plugins needs a running server; otherwise press prefix + I in tmux.
  if tmux list-sessions >/dev/null 2>&1; then
    "$dir/bin/install_plugins"
  fi
}

# True if version $1 >= version $2.
version_ge() {
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

if command -v tmux >/dev/null 2>&1; then
  INSTALLED=$(tmux -V | awk '{print $2}')
  if version_ge "$INSTALLED" "$VERSION"; then
    echo "tmux $INSTALLED is already installed (>= $VERSION)."
    install_tpm
    exit 0
  fi
fi

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
hash -r
tmux -V
install_tpm
