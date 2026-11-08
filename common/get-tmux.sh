#!/usr/bin/env bash
# Install tmux $VERSION from source. macOS: build against Homebrew deps. Linux (Debian/Ubuntu): apt deps.
# Idempotent: skips when an up-to-date tmux is already installed.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
VERSION=3.8

# tmux.conf loads plugins through TPM; without it `run -b tpm` exits 127.
install_tpm() {
  local dir="$HOME/.tmux/plugins/tpm"
  if [ -d "$dir/.git" ]; then
    echo "tpm is already installed."
  else
    git clone https://github.com/tmux-plugins/tpm "$dir"
  fi
  # tpm's install_plugins asks a running server where plugins go. Use the
  # running one if there is one (then reload it: prefix + r). Otherwise start a
  # throwaway server on its own socket dir, so continuum's restore-on-start
  # can't bring back sessions in a server that lingers after this script.
  if tmux list-sessions >/dev/null 2>&1; then
    "$dir/bin/install_plugins"
  else
    local tmpdir rc=0
    tmpdir="$(mktemp -d)"
    # Unset TMUX too: when set (e.g. a stale value), tmux uses it over TMUX_TMPDIR.
    on_tmp_server() { env -u TMUX TMUX_TMPDIR="$tmpdir" "$@"; }
    on_tmp_server tmux new-session -d -s tpm-install
    # tmux.conf starts tpm with `run -b`: wait until it has set the plugin path.
    for _ in $(seq 1 20); do
      on_tmp_server tmux show-environment -g TMUX_PLUGIN_MANAGER_PATH >/dev/null 2>&1 && break
      sleep 0.25
    done
    on_tmp_server "$dir/bin/install_plugins" || rc=$?
    on_tmp_server tmux kill-server 2>/dev/null || true
    rm -rf "$tmpdir"
    return "$rc"
  fi
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
  require_brew
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
