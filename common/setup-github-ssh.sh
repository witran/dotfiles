#!/usr/bin/env bash
# setup-github-ssh.sh — dedicated passphrase-protected SSH key for github.com,
# served by a shared ssh-agent on a fixed socket (~/.ssh/agent.sock). macOS and
# Linux; vps/setup-vps-user.sh runs it on the VPS.
#
# Why: the 1Password SSH agent needs a GUI authorization prompt, so git
# push/pull hangs inside ssh/mosh sessions. This routes github.com around
# 1Password entirely. The fixed socket means one `ssh-add` per boot covers
# every shell, tmux pane, remote session, and non-interactive git caller.
#
# Uses ~/.ssh/github_ed25519 if it exists (e.g. exported from 1Password),
# otherwise generates it. Once GitHub accepts the key, switches the dotfiles
# remote from HTTPS to SSH.
#
# Idempotent — safe to re-run. Interactive: asks for the key's passphrase.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY="$HOME/.ssh/github_ed25519"
SOCK="$HOME/.ssh/agent.sock"
CONFIG="$HOME/.ssh/config"

# --- 1. Key -------------------------------------------------------------------
step "SSH key"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ -f "$KEY" ]; then
  echo "already exists: $KEY"
else
  ssh-keygen -t ed25519 -f "$KEY" -C "$(whoami)@$(hostname -s) github"
fi
if [ ! -f "$KEY.pub" ]; then
  ssh-keygen -y -f "$KEY" > "$KEY.pub"   # asks for the passphrase
  echo "wrote $KEY.pub"
fi

# --- 2. ~/.ssh/config ---------------------------------------------------------
# Prepended, not appended: ssh_config is first-match-wins, so this block must
# come before any `Host *` that points IdentityAgent at 1Password.
step "~/.ssh/config"
touch "$CONFIG" && chmod 600 "$CONFIG"
if grep -qF "github_ed25519" "$CONFIG"; then
  echo "github.com block already present"
  # Upgrade blocks written before AddKeysToAgent was added: without it, ssh
  # prompts for the passphrase on every git call until a manual ssh-add.
  if ! grep -qF "AddKeysToAgent" "$CONFIG"; then
    TMP="$(mktemp)"
    awk '{ print } /IdentityFile ~\/\.ssh\/github_ed25519/ { print "  AddKeysToAgent yes" }' "$CONFIG" > "$TMP"
    mv "$TMP" "$CONFIG" && chmod 600 "$CONFIG"
    echo "added AddKeysToAgent yes"
  fi
else
  TMP="$(mktemp)"
  cat > "$TMP" <<'EOF'
Host github.com
  StrictHostKeyChecking accept-new
  IdentityAgent "~/.ssh/agent.sock"
  IdentityFile ~/.ssh/github_ed25519
  IdentitiesOnly yes
  AddKeysToAgent yes

EOF
  cat "$CONFIG" >> "$TMP"
  mv "$TMP" "$CONFIG" && chmod 600 "$CONFIG"
  echo "prepended github.com block"
fi

# --- 3. Shell rc: shared agent on a fixed socket ------------------------------
# Works in zsh and bash. On Debian it lands after ~/.bashrc's early return for
# non-interactive shells; those still reach the agent through IdentityAgent.
step "Shell rc"
add_to_shell_rcs '
# Shared ssh-agent on a fixed socket — one ssh-add per boot covers every shell,
# tmux pane, and non-interactive git (see dotfiles/common/setup-github-ssh.sh)
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
ssh-add -l >/dev/null 2>&1
if [ $? -eq 2 ]; then
  rm -f "$SSH_AUTH_SOCK"
  eval "$(ssh-agent -a "$SSH_AUTH_SOCK")" >/dev/null
fi' "agent.sock"

# --- 4. Start the agent and load the key --------------------------------------
step "ssh-agent"
export SSH_AUTH_SOCK="$SOCK"
rc=0; ssh-add -l >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 2 ]; then
  rm -f "$SOCK"
  eval "$(ssh-agent -a "$SOCK")" >/dev/null
  echo "started agent at $SOCK"
fi
if ssh-add -l 2>/dev/null | grep -qF "$(ssh-keygen -lf "$KEY.pub" | awk '{print $2}')"; then
  echo "key already loaded"
else
  ssh-add "$KEY"   # prompts for the passphrase
fi

# --- 5. Dotfiles remote over SSH ----------------------------------------------
# Cloned over HTTPS (no key yet); switch once GitHub accepts the key.
step "dotfiles remote"
URL="$(git -C "$DOTFILES" remote get-url origin)"
case "$URL" in
  git@github.com:*)
    echo "already SSH: $URL" ;;
  https://github.com/*)
    # ssh -T exits 1 even on success, so match its greeting instead.
    GREETING="$(ssh -T -o BatchMode=yes git@github.com 2>&1 || true)"
    if [[ "$GREETING" == *"successfully authenticated"* ]]; then
      git -C "$DOTFILES" remote set-url origin "git@github.com:${URL#https://github.com/}"
      echo "switched to $(git -C "$DOTFILES" remote get-url origin)"
    else
      echo "GitHub doesn't accept the key yet: add it (below), then re-run to switch $URL to SSH."
    fi ;;
  *)
    echo "left as is: $URL" ;;
esac

# --- 6. Summary ---------------------------------------------------------------
step "Done"
echo "Public key — add it at https://github.com/settings/keys (and keep a copy in 1Password):"
echo
cat "$KEY.pub"
echo
echo "After every reboot, the first git/ssh call to github.com asks for the passphrase once"
echo "Test with: ssh -T git@github.com"
