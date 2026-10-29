# CLAUDE.md

- Small personal repo: edit and commit directly on `master`. No feature branches.
- Before writing install or config steps for a dependency (Homebrew packages, Tailscale, filebrowser, systemd, sshd, ufw, ...), check its current online docs with WebFetch instead of relying on memory. Flags, download URLs and defaults change between versions.
- Open tasks are tracked in `TODO.md`.
- Layout: config files at the top level (symlinked by `common/setup.sh`); scripts in `common/` (both platforms), `mac/` and `vps/`. Shared helpers are in `common/lib.sh`. `vps/setup-vps-root.sh` and `vps/setup-vps-user.sh` must stay self-contained (they run before the repo is cloned), and `vps/tailscale-cert-renew.cron` hardcodes the script's path.
