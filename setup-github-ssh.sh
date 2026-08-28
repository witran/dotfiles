#!/bin/bash
# setup-github-ssh.sh — dedicated passphrase-protected SSH key for github.com,
# served by a shared ssh-agent on a fixed socket (~/.ssh/agent.sock).
#
# Why: the 1Password SSH agent needs a GUI authorization prompt, so git
# push/pull hangs inside ssh/mosh sessions. This routes github.com around
# 1Password entirely. The fixed socket means one `ssh-add` per boot covers
# every shell, tmux pane, remote session, and non-interactive git caller.
#
# Idempotent — safe to re-run. Interactive: ssh-keygen asks for a passphrase.
set -euo pipefail

step() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

KEY="$HOME/.ssh/github_ed25519"
SOCK="$HOME/.ssh/agent.sock"
CONFIG="$HOME/.ssh/config"
ZSHRC="$HOME/.zshrc"

# --- 1. Key -------------------------------------------------------------------
step "SSH key"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ -f "$KEY" ]; then
  echo "already exists: $KEY"
else
  ssh-keygen -t ed25519 -f "$KEY" -C "$(whoami)@$(hostname -s) github"
fi

# --- 2. ~/.ssh/config ---------------------------------------------------------
# Prepended, not appended: ssh_config is first-match-wins, so this block must
# come before any `Host *` that points IdentityAgent at 1Password.
step "~/.ssh/config"
touch "$CONFIG" && chmod 600 "$CONFIG"
if grep -qF "github_ed25519" "$CONFIG"; then
  echo "github.com block already present"
else
  TMP="$(mktemp)"
  cat > "$TMP" <<'EOF'
Host github.com
  StrictHostKeyChecking no
  IdentityAgent "~/.ssh/agent.sock"
  IdentityFile ~/.ssh/github_ed25519
  IdentitiesOnly yes

EOF
  cat "$CONFIG" >> "$TMP"
  mv "$TMP" "$CONFIG" && chmod 600 "$CONFIG"
  echo "prepended github.com block"
fi

# --- 3. ~/.zshrc: shared agent on a fixed socket ------------------------------
step "~/.zshrc"
if grep -qF "agent.sock" "$ZSHRC" 2>/dev/null; then
  echo "agent snippet already present"
else
  cat >> "$ZSHRC" <<'EOF'

# Shared ssh-agent on a fixed socket — one ssh-add per boot covers every shell,
# tmux pane, and non-interactive git (see dotfiles/setup-github-ssh.sh)
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
ssh-add -l >/dev/null 2>&1
if [ $? -eq 2 ]; then
  rm -f "$SSH_AUTH_SOCK"
  eval "$(ssh-agent -a "$SSH_AUTH_SOCK")" >/dev/null
fi
EOF
  echo "appended agent snippet"
fi

# --- 4. Start the agent and load the key --------------------------------------
step "ssh-agent"
export SSH_AUTH_SOCK="$SOCK"
rc=0; ssh-add -l >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 2 ]; then
  rm -f "$SOCK"
  eval "$(ssh-agent -a "$SOCK")" >/dev/null
  echo "started agent at $SOCK"
fi
if ssh-add -l 2>/dev/null | grep -qF "$KEY"; then
  echo "key already loaded"
else
  ssh-add "$KEY"   # prompts for the passphrase
fi

# --- 5. Summary ---------------------------------------------------------------
step "Done"
echo "Public key — add it at https://github.com/settings/keys :"
echo
cat "$KEY.pub"
echo
echo "After every reboot: ssh-add ~/.ssh/github_ed25519 (any one shell unlocks all)"
echo "Test with: ssh -T git@github.com"
