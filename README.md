# dotfiles

## Fresh Mac setup

Every device gets its own SSH key. 1Password keeps a copy of each key, so you can move key files around and restore one if it's lost.
The commands below use the vault `Private`. Replace it with your vault's name (often `Personal`).

### 0. Prerequisites (new Mac)

- [Homebrew](https://brew.sh) (also installs the Xcode command line tools, which provide git)
- [Tailscale](https://tailscale.com/download/mac), signed in
- 1Password app, signed in, plus its CLI:
  ```sh
  brew install 1password-cli
  ```
  Then in the 1Password app: Settings → Developer → turn on **Integrate with 1Password CLI**.

### 1. Clone and link configs (new Mac)

```sh
git clone https://github.com/witran/dotfiles.git ~/code/dotfiles   # HTTPS: no SSH key yet
cd ~/code/dotfiles
./setup.sh                  # symlink configs, install tmux + vim, hook aliases/prompt into ~/.zshrc
```

### 2. GitHub key: generate in 1Password → export to this Mac

```sh
ITEM="GitHub SSH - $(scutil --get LocalHostName)"
op item create --vault=Private --category=ssh --title="$ITEM" --ssh-generate-key=ed25519

mkdir -m 700 -p ~/.ssh
(umask 077
 op read "op://Private/$ITEM/private key?ssh-format=openssh" > ~/.ssh/github_ed25519
 op read "op://Private/$ITEM/public key" > ~/.ssh/github_ed25519.pub)
ssh-keygen -p -f ~/.ssh/github_ed25519   # set a passphrase on the local copy
```

Add the public key at https://github.com/settings/keys (`pbcopy < ~/.ssh/github_ed25519.pub`), then:

```sh
bash setup-github-ssh.sh    # uses the existing key; sets up ~/.ssh/config + the shared agent
ssh -T git@github.com       # check
```

The key is exported to a file instead of being served by the 1Password SSH agent. That agent needs a GUI approval, so git would hang inside ssh/mosh sessions.
If the file is ever lost, re-run the export lines above.

### 3. Phone key: generate in 1Password → export to Termux on Android

Once per phone. Skip it on later Macs: the phone already has its key.

On the Mac:

```sh
op item create --vault=Private --category=ssh --title="Phone SSH - <phone name>" --ssh-generate-key=ed25519
```

On the phone, install Tailscale and sign in. In the 1Password Android app, open the item and export the private key (to a file or to the clipboard; pick OpenSSH format if asked). Then in Termux:

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

Pass the phone's public key straight from 1Password:

```sh
bash setup-remote-dev.sh "$(op read 'op://Private/Phone SSH - <phone name>/public key')"
```

This turns on sshd and mosh, makes SSH key-only, and prints the Tailscale IP. Test from Termux: `mosh <user>@<tailscale-ip>`.

Open a new terminal on the Mac afterwards so `~/.zshrc` changes take effect.

`setup-tailscale-https.sh` is Linux-only and isn't needed on a Mac.
