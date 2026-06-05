#!/usr/bin/env bash
# Generate Tailscale HTTPS certs for any local dev server (Vite, etc.).
# Run once per machine. Certs stored in ~/.tailscale-certs/<host>.{crt,key}
# Re-run to renew (idempotent).
#
# Each project's dev-server config can pick the cert up from ~/.tailscale-certs
# (see e.g. family-tree's vite.config.ts → tailscaleHttps()).
set -euo pipefail

CERT_DIR="$HOME/.tailscale-certs"
HOST=$(tailscale status --json | python3 -c "import sys,json; print(json.load(sys.stdin)['Self']['DNSName'].rstrip('.'))")

if [ -z "$HOST" ]; then
  echo "Error: could not detect Tailscale hostname. Is Tailscale running?" >&2
  exit 1
fi

mkdir -p "$CERT_DIR"
sudo tailscale cert \
  --cert-file "$CERT_DIR/$HOST.crt" \
  --key-file "$CERT_DIR/$HOST.key" \
  "$HOST"
sudo chown "$USER" "$CERT_DIR/$HOST".{crt,key}

echo "Certs written to $CERT_DIR/$HOST.{crt,key}"
echo "Vite will auto-detect them — just restart the dev server."
