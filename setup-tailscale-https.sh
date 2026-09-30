#!/usr/bin/env bash
# Generate / renew Tailscale HTTPS certs for any local dev server (Vite, etc.).
# Certs stored in <target-user-home>/.tailscale-certs/<host>.{crt,key}
# Re-run to renew (idempotent) — tailscale only re-issues when near expiry.
#
# Usage:
#   ./setup-tailscale-https.sh           # for the current user (uses sudo)
#   ./setup-tailscale-https.sh <user>    # for <user>, e.g. when run as root from cron
#
# Renewal is automated via /etc/cron.d/tailscale-cert-renew (installed by
# setup.sh) which runs this weekly as root with the target user.
#
# Each project's dev-server config picks the cert up from ~/.tailscale-certs
# (see e.g. family-tree's vite.config.ts → tailscaleHttps()).
set -euo pipefail

if [ "$(uname -s)" != "Linux" ]; then
  echo "setup-tailscale-https.sh only supports Linux for now." >&2
  exit 1
fi

export PATH="/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

TARGET_USER="${1:-$(id -un)}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
if [ -z "$TARGET_HOME" ]; then
  echo "Error: could not resolve home directory for user '$TARGET_USER'." >&2
  exit 1
fi
CERT_DIR="$TARGET_HOME/.tailscale-certs"

# tailscale cert needs root; prepend sudo only when we aren't already root.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

HOST=$(tailscale status --json | python3 -c "import sys,json; print(json.load(sys.stdin)['Self']['DNSName'].rstrip('.'))")
if [ -z "$HOST" ]; then
  echo "Error: could not detect Tailscale hostname. Is Tailscale running?" >&2
  exit 1
fi

mkdir -p "$CERT_DIR"
$SUDO tailscale cert \
  --cert-file "$CERT_DIR/$HOST.crt" \
  --key-file "$CERT_DIR/$HOST.key" \
  "$HOST"
$SUDO chown "$TARGET_USER" "$CERT_DIR" "$CERT_DIR/$HOST".{crt,key}

echo "Certs written to $CERT_DIR/$HOST.{crt,key}"
echo "Vite will auto-detect them — just restart the dev server."
