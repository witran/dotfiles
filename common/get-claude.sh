#!/usr/bin/env bash
# Install Claude Code with the native installer (macOS and Linux). It goes to
# ~/.local/bin/claude and updates itself in the background, so this only has to
# install it once and put ~/.local/bin on PATH.
# Idempotent: skips the install when claude is already there.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CLAUDE="$HOME/.local/bin/claude"

if command -v claude >/dev/null 2>&1 || [ -x "$CLAUDE" ]; then
  echo "Claude Code is already installed ($("$(command -v claude || echo "$CLAUDE")" --version))."
else
  curl -fsSL https://claude.ai/install.sh | bash
fi

# Debian's ~/.profile adds ~/.local/bin, but bash skips ~/.profile once a
# ~/.bash_profile exists (setup-vps-user.sh creates one); macOS never adds it.
add_to_shell_rcs 'export PATH="$HOME/.local/bin:$PATH"' '.local/bin'
