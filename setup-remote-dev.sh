#!/bin/bash
# setup-remote-dev.sh — set up this Mac for phone → Tailscale → mosh/ssh, key-only auth.
#
# Usage:
#   bash setup-remote-dev.sh "ssh-ed25519 AAAA...your phone's public key... phone"
#   bash setup-remote-dev.sh          # without a key: sets everything up but leaves
#                                     # password auth ON so you can't lock yourself out
#
# SSH becomes key-only. GUI login at the Mac itself is untouched — password
# keeps working on the login screen (sshd config has no effect on loginwindow).
set -euo pipefail

PUBKEY="${1:-}"
step() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

# --- 1. Enable Remote Login (sshd) ------------------------------------------
step "Remote Login (sshd)"
if sudo systemsetup -getremotelogin 2>/dev/null | grep -q ": On"; then
  echo "already on"
else
  sudo systemsetup -setremotelogin on 2>/dev/null || true
  if sudo systemsetup -getremotelogin 2>/dev/null | grep -q ": On"; then
    echo "enabled"
  else
    echo "!! systemsetup could not enable it (newer macOS wants Full Disk Access for your terminal)."
    echo "   Enable it manually: System Settings → General → Sharing → Remote Login, then re-run this script."
    exit 1
  fi
fi

# --- 2. mosh -----------------------------------------------------------------
step "mosh"
if ! command -v brew >/dev/null 2>&1; then
  echo "!! Homebrew not found — install it from https://brew.sh first"; exit 1
fi
BREW_PREFIX="$(brew --prefix)"
MOSH_SERVER="$BREW_PREFIX/bin/mosh-server"
if [ -x "$MOSH_SERVER" ]; then
  echo "already installed: $MOSH_SERVER"
else
  brew install mosh
fi

# --- 3. Make mosh-server findable over bare ssh ------------------------------
# The mosh client starts mosh-server through a NON-interactive ssh command.
# That shell reads only ~/.zshenv (not .zshrc/.zprofile) and sshd's default
# PATH does not include Homebrew's bin, so without this line mosh fails with
# "mosh-server: command not found".
step "PATH for non-interactive ssh (~/.zshenv)"
ZSHENV="$HOME/.zshenv"
PATH_LINE="export PATH=\"$BREW_PREFIX/bin:\$PATH\""
if [ -f "$ZSHENV" ] && grep -qF "$BREW_PREFIX/bin" "$ZSHENV"; then
  echo "~/.zshenv already covers $BREW_PREFIX/bin"
else
  printf '%s\n' "$PATH_LINE" >> "$ZSHENV"
  echo "appended to ~/.zshenv: $PATH_LINE"
fi

# --- 4. authorized_keys ------------------------------------------------------
step "SSH key"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
AK="$HOME/.ssh/authorized_keys"
touch "$AK" && chmod 600 "$AK"
if [ -n "$PUBKEY" ]; then
  if grep -qF "$PUBKEY" "$AK"; then
    echo "key already in authorized_keys"
  else
    printf '%s\n' "$PUBKEY" >> "$AK"
    echo "key added to authorized_keys"
  fi
fi

# --- 5. sshd: key-only auth (only once a key actually exists) ----------------
step "sshd hardening"
if grep -qEv '^[[:space:]]*(#|$)' "$AK"; then
  # macOS ships "Include /etc/ssh/sshd_config.d/*" in sshd_config; make sure.
  if ! grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*' /etc/ssh/sshd_config; then
    sudo sed -i '' '1i\
Include /etc/ssh/sshd_config.d/*
' /etc/ssh/sshd_config
    echo "added Include line to /etc/ssh/sshd_config"
  fi
  sudo mkdir -p /etc/ssh/sshd_config.d
  sudo tee /etc/ssh/sshd_config.d/100-remote-dev.conf >/dev/null <<'EOF'
# setup-remote-dev.sh: SSH is key-only. GUI/console login is unaffected.
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
EOF
  sudo /usr/sbin/sshd -t
  echo "password auth over SSH disabled (macOS spawns sshd per connection — new connections pick it up immediately)"
else
  echo "!! ~/.ssh/authorized_keys is empty — leaving password auth ON so you don't lock yourself out."
  echo "   Generate a key on your phone (Blink/Termius: ssh-keygen -t ed25519), then re-run:"
  echo "   bash $0 \"ssh-ed25519 AAAA... phone\""
fi

# --- 6. Application firewall: allow mosh's UDP ports -------------------------
step "Application firewall"
SFW=/usr/libexec/ApplicationFirewall/socketfilterfw
if "$SFW" --getglobalstate 2>/dev/null | grep -qi "enabled"; then
  sudo "$SFW" --add "$MOSH_SERVER" >/dev/null 2>&1 || true
  sudo "$SFW" --unblockapp "$MOSH_SERVER" >/dev/null 2>&1 || true
  echo "mosh-server allowed through the firewall (UDP 60000-61000)"
else
  echo "firewall is off — nothing to allow"
fi

# --- 7. Summary --------------------------------------------------------------
step "Done"
TS="$(command -v tailscale || true)"
[ -z "$TS" ] && [ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ] \
  && TS="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
if [ -n "$TS" ]; then
  TS_IP="$("$TS" ip -4 2>/dev/null | head -1 || true)"
  echo "Tailscale IP: ${TS_IP:-<not connected — open the Tailscale app>}"
else
  echo "!! Tailscale not found — install it and sign in"
  TS_IP=""
fi
echo
echo "From your phone:"
echo "  mosh $(whoami)@${TS_IP:-<tailscale-ip>}"
echo "  ssh  $(whoami)@${TS_IP:-<tailscale-ip>}      # plain ssh also works"
echo
echo "If the client says mosh-server not found, point it at the binary:"
echo "  mosh --server=$MOSH_SERVER $(whoami)@${TS_IP:-<tailscale-ip>}"
echo "  (Blink: set 'mosh server path' on the host; Termius: use the ssh fallback)"
