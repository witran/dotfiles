#!/usr/bin/env bash
# Symlink dotfiles into $HOME. Safe to re-run; works on macOS and Linux.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
source "$DOTFILES/common/lib.sh"

# Symlink $1 (relative to the repo) to $2. An existing regular file at the
# target is moved aside to <target>.bak rather than silently overwritten.
link() {
  local src="$DOTFILES/$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.bak"
    echo "Backed up existing $dest to $dest.bak"
  fi
  ln -sfn "$src" "$dest"
}

link tmux.conf            "$HOME/.tmux.conf"
link vimrc                "$HOME/.vimrc"
link aliases.sh           "$HOME/.aliases.sh"
link ps.sh                "$HOME/.ps.sh"
link gitconfig            "$HOME/.gitconfig"
link claude-settings.json "$HOME/.claude/settings.json"
link ghostty.config       "$HOME/.config/ghostty/config"
link zed-settings.json    "$HOME/.config/zed/settings.json"
link zed-keymap.json      "$HOME/.config/zed/keymap.json"

# Install/upgrade tmux, vim and Claude Code. Each script skips when already up
# to date; a failure (e.g. no Homebrew on macOS) is reported but doesn't stop setup.
for script in get-tmux.sh get-vim.sh get-claude.sh; do
  "$DOTFILES/common/$script" || echo "Warning: $script failed; continuing." >&2
done

# Install Tailscale HTTPS cert auto-renewal cron job (Linux only; needs root).
# Installed name has no ".cron" extension — cron ignores files containing a dot.
if [ "$(uname -s)" = "Linux" ] && [ -d /etc/cron.d ] && command -v sudo >/dev/null 2>&1; then
  sudo install -m 0644 -o root -g root \
    "$DOTFILES/vps/tailscale-cert-renew.cron" /etc/cron.d/tailscale-cert-renew \
    && echo "Installed /etc/cron.d/tailscale-cert-renew (weekly cert renewal)."
fi

# Source aliases and prompt from the shell rc files (zsh is the macOS default;
# bash on most Linux boxes).
add_to_shell_rcs "source ~/.aliases.sh && source ~/.ps.sh"
