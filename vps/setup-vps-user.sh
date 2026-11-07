#!/usr/bin/env bash
# setup-vps-user.sh — second step after setup-vps-root.sh. Run as the dev user in
# an interactive ssh session (ssh-keygen asks for a passphrase):
#
#   bash setup-vps-user.sh
#
# Clones the dotfiles, runs common/setup.sh (configs, tmux, vim, Claude Code), and
# runs common/setup-github-ssh.sh: this box's GitHub SSH key with an ssh-agent
# that's shared by every shell and tmux pane.
#
# Self-contained (doesn't source common/lib.sh): it runs before the repo is cloned.
#
# Idempotent — safe to re-run.
set -euo pipefail

DOTFILES="$HOME/code/dotfiles"
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
  git -C "$DOTFILES" pull --rebase --autostash
else
  mkdir -p "$(dirname "$DOTFILES")"
  git clone https://github.com/witran/dotfiles "$DOTFILES"
fi
"$DOTFILES/common/setup.sh"   # also installs tmux, vim and Claude Code (common/get-*.sh)

# --- 3. GitHub SSH key --------------------------------------------------------
# Earlier setups made the GitHub key under another name (~/.ssh/id_ed25519 from
# older versions of this script, or a hand-made ~/.ssh/gh_witran) with their own
# agent snippet in ~/.bashrc. Rename the key to the name the shared script uses
# and drop the old snippet, so there's one agent setup on every machine.
# Without this, setup-github-ssh.sh would generate a new key GitHub doesn't know
# and point github.com at it, breaking git until the new key is added.
step "Migrate old GitHub key"
NEW_KEY="$HOME/.ssh/github_ed25519"
if [ ! -f "$NEW_KEY" ]; then
  if [ -f "$HOME/.ssh/id_ed25519" ] && grep -qF " github" "$HOME/.ssh/id_ed25519.pub" 2>/dev/null; then
    OLD_KEY="$HOME/.ssh/id_ed25519"
  elif [ -f "$HOME/.ssh/gh_witran" ]; then
    OLD_KEY="$HOME/.ssh/gh_witran"   # no .pub: setup-github-ssh.sh derives it
  else
    OLD_KEY=""
  fi
  if [ -n "$OLD_KEY" ]; then
    mv "$OLD_KEY" "$NEW_KEY"
    [ -f "$OLD_KEY.pub" ] && mv "$OLD_KEY.pub" "$NEW_KEY.pub"
    echo "renamed $OLD_KEY to $NEW_KEY"
  fi
fi
# Header with or without the "(setup-vps-user.sh)" suffix, depending on the version.
OLD_SNIPPET_START='^# --- SSH Agent Configuration( \(setup-vps-user\.sh\))? ---$'
if grep -qE "$OLD_SNIPPET_START" ~/.bashrc; then
  cp ~/.bashrc ~/.bashrc.bak
  sed -i -E "/$OLD_SNIPPET_START/,/^# --- End SSH Agent Configuration ---\$/d" ~/.bashrc
  rm -f "$HOME/.ssh/agent-environment"
  echo "removed the old ssh-agent snippet from ~/.bashrc (backup: ~/.bashrc.bak)"
fi

# Prints the public key at the end. Re-run once GitHub has it: that switches the
# dotfiles remote to SSH.
"$DOTFILES/common/setup-github-ssh.sh"
echo "Open a new shell (it loads the agent and puts ~/.local/bin on PATH), then run: claude"
