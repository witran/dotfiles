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
