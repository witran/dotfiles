#!/usr/bin/env bash
# setup-vps-root.sh — harden a fresh Debian/Ubuntu VPS for use as a remote dev box
# (tmux + Claude Code over ssh/mosh). Run as root from the provider's root login:
#
#   bash setup-vps-root.sh "ssh-ed25519 AAAA... laptop" [user]     # user defaults to will
#
# Creates a sudo user that logs in with that key, turns off root and password SSH
# login, adds swap, enables fail2ban and the firewall, and joins Tailscale. Once
# Tailscale is up, ssh and mosh are reachable only over the tailnet.
#
# Idempotent — safe to re-run. Before closing the root session, check from another
# terminal that `ssh <user>@<tailscale-ip>` works.
set -euo pipefail

PUBKEY="${1:-}"
USERNAME="${2:-will}"
SWAP_SIZE=8G
step() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2; exit 1
fi
# Root and password login are turned off below; without a key nobody could log in.
if [ -z "$PUBKEY" ]; then
  echo "Usage: bash $0 \"ssh-ed25519 AAAA... laptop\" [user]" >&2; exit 1
fi

# --- 1. Packages --------------------------------------------------------------
step "Packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get install -y curl git build-essential mosh net-tools ufw fail2ban python3-systemd

# --- 2. User ------------------------------------------------------------------
step "User $USERNAME"
if id "$USERNAME" >/dev/null 2>&1; then
  echo "already exists"
else
  useradd -m -s /bin/bash "$USERNAME"
  echo "created"
fi
USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"
install -d -m 700 -o "$USERNAME" -g "$USERNAME" "$USER_HOME/.ssh"
AK="$USER_HOME/.ssh/authorized_keys"
touch "$AK"
grep -qxF "$PUBKEY" "$AK" || printf '%s\n' "$PUBKEY" >> "$AK"
chown "$USERNAME:$USERNAME" "$AK" && chmod 600 "$AK"

# Passwordless sudo. Convenient, but anything running as this user (a coding
# agent included) can become root. Validated before install: a broken sudoers
# file locks out sudo entirely.
SUDOERS="/etc/sudoers.d/90-$USERNAME"
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS.tmp"
visudo -cf "$SUDOERS.tmp" >/dev/null
chmod 440 "$SUDOERS.tmp" && mv "$SUDOERS.tmp" "$SUDOERS"

# --- 3. sshd: key-only, no root -----------------------------------------------
# sshd_config includes sshd_config.d/*.conf at the top and the first value wins,
# so a 00- file beats both sshd_config and cloud-init's 50-cloud-init.conf (which
# often sets PasswordAuthentication yes). Editing sshd_config alone would not.
step "sshd"
if ! grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/' /etc/ssh/sshd_config; then
  echo "!! /etc/ssh/sshd_config has no Include for sshd_config.d — add one at the top, then re-run." >&2
  exit 1
fi
cat > /etc/ssh/sshd_config.d/00-hardening.conf <<'EOF'
# setup-vps-root.sh: key-only SSH, no root login.
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
EOF
sshd -t
# try-: Ubuntu 24.04 socket-activates sshd, so the service may not be running;
# it then reads the new config on its next start.
systemctl try-reload-or-restart ssh
echo "root and password login disabled"

# --- 4. Swap ------------------------------------------------------------------
step "Swap ($SWAP_SIZE)"
if swapon --show=NAME --noheadings | grep -qx /swapfile; then
  echo "already on"
else
  if [ ! -f /swapfile ]; then
    fallocate -l "$SWAP_SIZE" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
  fi
  swapon /swapfile
fi
grep -qE '^/swapfile[[:space:]]' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab

# --- 5. fail2ban --------------------------------------------------------------
# Read sshd failures from the journal: Debian 12+ has no /var/log/auth.log, and
# fail2ban's default file backend won't start without it.
step "fail2ban"
cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
backend = systemd
EOF
systemctl enable fail2ban >/dev/null 2>&1
systemctl restart fail2ban
echo "sshd jail on"

# --- 6. Journal size ----------------------------------------------------------
# Cap the journal so service logs (filebrowser etc.) can't fill the disk;
# journald rotates within the cap on its own.
step "Journal size"
mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nSystemMaxUse=500M\n' > /etc/systemd/journald.conf.d/size.conf
systemctl restart systemd-journald

# --- 7. Tailscale -------------------------------------------------------------
step "Tailscale"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
# `tailscale up` prints a login URL and waits until this machine is approved.
tailscale ip -4 >/dev/null 2>&1 || tailscale up
TS_IP="$(tailscale ip -4 2>/dev/null | head -1 || true)"
echo "Tailscale IP: ${TS_IP:-<not connected>}"

# --- 8. Firewall --------------------------------------------------------------
# Everything on the tailnet is trusted (ssh, mosh, dev servers, filebrowser...);
# nothing else gets in. Until Tailscale is up, ssh and mosh stay open publicly so
# this run can't lock you out.
step "Firewall (ufw)"
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null
# Tailscale's WireGuard port. Optional (outbound alone works), but lets peers
# behind strict NATs reach this server directly instead of through a relay.
ufw allow 41641/udp >/dev/null
if [ -n "$TS_IP" ]; then
  ufw allow in on tailscale0 >/dev/null
  # Drop public rules left by an earlier run (or by the old version of this script).
  for rule in 22/tcp ssh 60000:61000/udp; do
    ufw delete allow "$rule" >/dev/null 2>&1 || true
  done
  echo "ssh and mosh reachable only over Tailscale"
else
  ufw allow 22/tcp >/dev/null
  ufw allow 60000:61000/udp >/dev/null
  echo "!! Tailscale is not up — ssh and mosh are open publicly. Re-run after 'tailscale up'."
fi
ufw --force enable >/dev/null

# --- 9. Summary ---------------------------------------------------------------
step "Done"
echo "From another terminal, before closing this one:"
echo "  ssh $USERNAME@${TS_IP:-<server-ip>}"
echo "Then, as $USERNAME, run setup-vps-user.sh."
