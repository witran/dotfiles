#!/usr/bin/env bash
# setup-vps-user.sh — second step after setup-vps-root.sh. Run as the dev user in
# an interactive ssh session (ssh-keygen asks for a passphrase):
#
#   bash setup-vps-user.sh
#
# Clones the dotfiles, runs common/setup.sh (configs, tmux, vim), and creates this box's
# GitHub SSH key with an ssh-agent that's shared by every shell and tmux pane.
#
# Self-contained (doesn't source common/lib.sh): it runs before the repo is cloned.
#
# Idempotent — safe to re-run.
set -euo pipefail

DOTFILES="$HOME/code/dotfiles"
KEY="$HOME/.ssh/id_ed25519"
step() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

# --- 1. Login shells read ~/.bashrc -------------------------------------------
# ssh starts a login shell, which reads ~/.bash_profile but not ~/.bashrc.
step "~/.bash_profile"
SOURCE_BASHRC='if [ -f ~/.bashrc ]; then . ~/.bashrc; fi'
touch ~/.bashrc ~/.bash_profile
if grep -qxF "$SOURCE_BASHRC" ~/.bash_profile; then
  echo "already sources ~/.bashrc"
else
  echo "$SOURCE_BASHRC" >> ~/.bash_profile
  echo "now sources ~/.bashrc"
fi

# --- 2. Dotfiles --------------------------------------------------------------
# HTTPS: the GitHub key doesn't exist yet on a first run.
step "Dotfiles"
if [ -d "$DOTFILES/.git" ]; then
  git -C "$DOTFILES" pull --rebase
else
  mkdir -p "$(dirname "$DOTFILES")"
  git clone https://github.com/witran/dotfiles "$DOTFILES"
fi
"$DOTFILES/common/setup.sh"   # also installs tmux (get-tmux.sh) and vim (get-vim.sh)

# --- 3. GitHub SSH key --------------------------------------------------------
step "SSH key"
if [ -f "$KEY" ]; then
  echo "already exists: $KEY"
else
  ssh-keygen -t ed25519 -f "$KEY" -C "$(whoami)@$(hostname -s) github"
fi

# --- 4. ssh-agent shared across shells ----------------------------------------
# The agent's environment is saved to a file, so every new shell (and tmux pane)
# reuses the running agent: one passphrase prompt per boot. Appended at the end of
# ~/.bashrc, after Debian's early return for non-interactive shells.
step "ssh-agent (~/.bashrc)"
if grep -qF "SSH Agent Configuration" ~/.bashrc; then
  echo "already configured"
else
  cat >> ~/.bashrc <<'EOF'

# --- SSH Agent Configuration (setup-vps-user.sh) ---
SSH_ENV="$HOME/.ssh/agent-environment"
start_agent() {
  echo "Initializing new SSH agent..."
  ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"
  chmod 600 "$SSH_ENV"
  . "$SSH_ENV" > /dev/null
  ssh-add
}
if [ -f "$SSH_ENV" ]; then
  . "$SSH_ENV" > /dev/null
  ps -p "$SSH_AGENT_PID" > /dev/null || start_agent
else
  start_agent
fi
if [[ $(ssh-add -l) == *"no identities"* ]]; then
  ssh-add "$HOME/.ssh/id_ed25519"
fi
# --- End SSH Agent Configuration ---
EOF
  echo "appended to ~/.bashrc"
fi

# --- 5. Summary ---------------------------------------------------------------
step "Done"
echo "Add this public key at https://github.com/settings/keys (and save the key pair in 1Password):"
echo
cat "$KEY.pub"
echo
echo "Then open a new shell (it loads the agent) and test: ssh -T git@github.com"
