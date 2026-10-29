# TODO

## VPS dev box
- [x] Disable Tailscale key expiry for the VPS in the admin console. SSH is tailnet-only, so an expired key locks you out (provider console is the only way back in). Manual step, documented in README → Fresh VPS dev box → 1.
- [x] Enable `unattended-upgrades` in `vps/setup-vps-root.sh` for automatic security patches.
- [x] Install Claude Code in `vps/setup-vps-user.sh` (via `common/get-claude.sh`, run by `common/setup.sh`).
- [x] One GitHub key setup: `common/setup-github-ssh.sh` on both platforms, used by `vps/setup-vps-user.sh` (migrates the old `id_ed25519` key and agent snippet); switches the dotfiles remote to SSH once the key works.

## Mac
- [x] Set up filebrowser on the Mac too: `common/setup-filebrowser.sh` (launchd agent on macOS, systemd on Linux).
- [x] Install Claude Code from a mac script too: `common/get-claude.sh`, run by `common/setup.sh`.

## Deferred
- [ ] Test `common/setup-filebrowser.sh` on the VPS (moved from `vps/`; port changed from 5000 to 8090).
- [ ] Turn on provider snapshots/backups for the VPS (or make sure `~/code` is always pushed).
- [ ] Decide on passwordless sudo for the dev user: anything Claude Code runs (especially with permissions bypassed) can become root.
- [ ] File Browser was archived upstream on 2026-09-01 (no more security fixes): consider a maintained replacement.

## Repo structure
- [x] Refactor into `common/` (shared scripts + `lib.sh`), `mac/` and `vps/`; config files stay at the top level. README has a VPS section.
