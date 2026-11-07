# dotfiles

Config files (tmux, vim, zsh/bash aliases and prompt, git, Claude Code, Ghostty, Zed) live at the top level and are symlinked into `$HOME`. Scripts:

- `common/`: `setup.sh` (symlinks + tmux/vim/Claude Code), the installers it runs (`get-*.sh`), GitHub SSH key setup, File Browser, and `lib.sh` (shared helpers). Both platforms.
- `mac/`: phone remote-login setup
- `vps/`: Debian/Ubuntu dev box setup, Tailscale HTTPS certs

## Fresh Mac setup

Every device gets its own SSH key. 1Password keeps a copy of each key, so you can move key files around and restore one if it's lost.
Steps marked **Manual** are done by hand in the 1Password app; everything else is a command.

### 0. Prerequisites (new Mac)

- [Homebrew](https://brew.sh) (also installs the Xcode command line tools, which provide git)
- [Tailscale](https://tailscale.com/download/mac), signed in
- 1Password app, signed in

### 1. Clone and link configs (new Mac)

```sh
git clone https://github.com/witran/dotfiles.git ~/code/dotfiles   # HTTPS: no SSH key yet
cd ~/code/dotfiles
./common/setup.sh           # symlink configs, install tmux + vim + Claude Code, hook aliases/prompt into ~/.zshrc
```

### 2. GitHub key: generate in 1Password → export to this Mac

**Manual (1Password app):**
1. New Item → SSH Key → Add Private Key → Generate New Key → Ed25519.
   Title it after this Mac, e.g. `GitHub SSH - <mac name>`, and save.
2. Open the item and export the private key in **OpenSSH** format. Save it as `~/Downloads/github_ed25519`.

Then move it into place and set a passphrase on the local copy:

```sh
mkdir -m 700 -p ~/.ssh
mv ~/Downloads/github_ed25519 ~/.ssh/github_ed25519
chmod 600 ~/.ssh/github_ed25519
ssh-keygen -p -f ~/.ssh/github_ed25519                              # set a passphrase
ssh-keygen -y -f ~/.ssh/github_ed25519 > ~/.ssh/github_ed25519.pub  # public key from the private key
```

**Manual:** add the public key at https://github.com/settings/keys (`pbcopy < ~/.ssh/github_ed25519.pub`). Then:

```sh
bash common/setup-github-ssh.sh   # uses the existing key; sets up ~/.ssh/config + the shared agent, switches the remote to SSH
ssh -T git@github.com          # check
```

The key is exported to a file instead of being served by the 1Password SSH agent. That agent needs a GUI approval, so git would hang inside ssh/mosh sessions.
If the file is ever lost, export it from 1Password again.

### 3. Phone key: generate in 1Password → export to Termux on Android

Once per phone. Skip it on later Macs: the phone already has its key.

**Manual (1Password app, on any device):** New Item → SSH Key → Add Private Key → Generate New Key → Ed25519. Title it `Phone SSH - <phone name>` and save.

**Manual (phone):** install Tailscale and sign in. In the 1Password Android app, open the item and export the private key (to a file or to the clipboard; pick OpenSSH format if asked).

Then in Termux:

```sh
pkg install openssh mosh
mkdir -p ~/.ssh && chmod 700 ~/.ssh

# from the clipboard: paste the key, then press Ctrl-D
cat > ~/.ssh/id_ed25519
# or from a file: run termux-setup-storage once, then
#   cp ~/storage/downloads/<exported file> ~/.ssh/id_ed25519   (and delete the exported file)

chmod 600 ~/.ssh/id_ed25519
```

If the key file is ever lost, export it from 1Password again.

### 4. Remote login from the phone (new Mac)

**Manual (1Password app on the Mac):** open `Phone SSH - <phone name>` and copy its **public key**. Then:

```sh
bash mac/setup-remote-dev.sh "$(pbpaste)"
```

This turns on sshd and mosh, makes SSH key-only, and prints the Tailscale IP. Test from Termux: `mosh <user>@<tailscale-ip>`.

It also installs a LaunchDaemon that runs `caffeinate -i`, so the Mac doesn't idle-sleep (on AC or battery) while the lid is open. The display still turns off on its timer. Explicit sleep (Apple menu, Alfred `sleep`, closing the lid) still sleeps the Mac and drops the session. To check it over ssh:

```sh
pmset -g assertions | grep -A1 caffeinate        # PreventUserIdleSystemSleep, "asserting forever"
pmset -g | grep ' sleep '                         # "sleep prevented by caffeinate"
pmset -g log | grep -E 'Display is turned (on|off)' | tail -1   # current display state
pmset displaysleepnow                             # turn the display off now; the Mac stays awake
```

Open a new terminal on the Mac afterwards so `~/.zshrc` changes take effect.

### 5. Optional extras

```sh
bash common/setup-filebrowser.sh   # File Browser on https://<machine>.<tailnet>.ts.net (launchd agent)
```

## Fresh VPS dev box (Debian/Ubuntu)

### 1. Harden the server (as root)

```sh
curl -fsSLO https://raw.githubusercontent.com/witran/dotfiles/master/vps/setup-vps-root.sh
bash setup-vps-root.sh "<public key of the machine you'll ssh from>" [user]   # user defaults to will
```

**Manual:** open the login URL that `tailscale up` prints and approve the machine.
Before closing the root session, check `ssh <user>@<tailscale-ip>` from another terminal.
**Manual:** in the Tailscale admin console, disable key expiry for this machine (SSH is tailnet-only).

### 2. Dotfiles and GitHub key (as the user)

```sh
curl -fsSLO https://raw.githubusercontent.com/witran/dotfiles/master/vps/setup-vps-user.sh
bash setup-vps-user.sh      # clones to ~/code/dotfiles, runs common/setup.sh, then common/setup-github-ssh.sh
```

**Manual:** add the printed public key at https://github.com/settings/keys and save the key pair in 1Password.
Then re-run `bash ~/code/dotfiles/vps/setup-vps-user.sh` to switch the dotfiles remote to SSH.

### 3. Optional extras

```sh
bash ~/code/dotfiles/common/setup-filebrowser.sh   # File Browser on https://<machine>.<tailnet>.ts.net (systemd unit)
```

`common/setup.sh` also installs a weekly cron job that renews Tailscale HTTPS certs for local dev servers (`vps/setup-tailscale-https.sh`).

## Existing VPS (set up by an older version of these scripts)

Everything is idempotent, so updating is a re-run:

```sh
cd ~/code/dotfiles && git pull
./common/setup.sh                     # configs, tmux/vim/Claude Code upgrades, cert-renewal cron
bash common/setup-filebrowser.sh      # if File Browser isn't set up yet
```

- `common/setup.sh` rebuilds tmux when `VERSION` in `common/get-tmux.sh` is bumped. The tmux server that's already running keeps the old version, and the new client may refuse to attach to it ("protocol version mismatch"). Save your work, then `tmux kill-server`.
- `vps/setup-vps-user.sh` is only needed to move to the shared GitHub key setup. It renames an old `~/.ssh/id_ed25519` or `~/.ssh/gh_witran` key to `~/.ssh/github_ed25519` and removes the old agent snippet from `~/.bashrc` (backed up to `~/.bashrc.bak`). Run it in an interactive session: it asks for the key's passphrase.
- Older root scripts left ssh (22/tcp) and mosh (60000:61000/udp) open to the internet. Check with `sudo ufw status`. To make them tailnet-only, re-run `vps/setup-vps-root.sh` as root, or run:
  `sudo ufw allow in on tailscale0 && sudo ufw delete allow 22/tcp && sudo ufw delete allow 60000:61000/udp`
