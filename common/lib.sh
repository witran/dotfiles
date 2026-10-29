# lib.sh — helpers shared by the setup scripts. Source it, don't run it:
#
#   source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"            # from common/
#   source "$(dirname "${BASH_SOURCE[0]}")/../common/lib.sh"  # from mac/ or vps/
#
# vps/setup-vps-root.sh and vps/setup-vps-user.sh don't use it: they run before
# the repo is cloned, so they have to stay self-contained.

# Print a bold section header.
step() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

# True if version $1 >= version $2.
version_ge() {
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

# Exit unless Homebrew is installed.
require_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required: https://brew.sh" >&2
    exit 1
  fi
}

# Shell rc files to add lines to: ~/.zshrc on macOS, ~/.bashrc on Linux, plus
# the other one if it already exists.
shell_rcs() {
  local rc
  for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    case "$rc" in
      */.zshrc)  [ "$(uname -s)" = "Darwin" ] || [ -e "$rc" ] || continue ;;
      */.bashrc) [ "$(uname -s)" = "Linux" ]  || [ -e "$rc" ] || continue ;;
    esac
    echo "$rc"
  done
}

# Append text $1 to every shell rc file that doesn't contain marker $2 yet
# (default: the text itself, which must then be a single line).
add_to_shell_rcs() {
  local text="$1" marker="${2:-$1}" rc
  for rc in $(shell_rcs); do
    touch "$rc"
    if grep -qF -- "$marker" "$rc"; then
      echo "already in $rc: $marker"
    else
      printf '%s\n' "$text" >> "$rc"
      echo "added to $rc: $marker"
    fi
  done
}

# Path of the tailscale CLI. On macOS the app bundles it; TAILSCALE_BE_CLI keeps
# the bundled binary acting as the CLI instead of opening the app (exported here,
# not in the function, because callers run it in a $(...) subshell).
export TAILSCALE_BE_CLI=1
tailscale_bin() {
  if command -v tailscale >/dev/null 2>&1; then
    command -v tailscale
  elif [ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]; then
    echo /Applications/Tailscale.app/Contents/MacOS/Tailscale
  else
    echo "Tailscale not found: install it and sign in." >&2
    return 1
  fi
}

# This machine's tailnet DNS name, e.g. box.tail1234.ts.net.
tailscale_dns_name() {
  "$(tailscale_bin)" status --json \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['Self']['DNSName'].rstrip('.'))"
}
