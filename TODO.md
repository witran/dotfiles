# TODO

## VPS dev box
- [ ] Disable Tailscale key expiry for the VPS in the admin console. SSH is tailnet-only, so an expired key locks you out (provider console is the only way back in).
- [ ] Enable `unattended-upgrades` in `vps/setup-vps-root.sh` for automatic security patches.
- [ ] Install Claude Code in `vps/setup-vps-user.sh`.
- [ ] Decide on passwordless sudo for the dev user: anything Claude Code runs (especially with permissions bypassed) can become root.
- [ ] One GitHub key setup: make `mac/setup-github-ssh.sh` work with bash (move it to `common/`), use it from `vps/setup-vps-user.sh` instead of the duplicate agent snippet; switch the dotfiles remote to SSH once the key works.
- [ ] Turn on provider snapshots/backups for the VPS (or make sure `~/code` is always pushed).
- [ ] Test `vps/setup-filebrowser.sh` on the VPS.

## Repo structure
- [x] Refactor into `common/` (shared scripts + `lib.sh`), `mac/` and `vps/`; config files stay at the top level. README has a VPS section.
