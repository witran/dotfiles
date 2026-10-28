# dotfiles

## Fresh Mac setup

Prerequisites: [Homebrew](https://brew.sh) (it also installs the Xcode command line tools, which provide git), and the [Tailscale](https://tailscale.com/download/mac) app, signed in.

Run these in order. Each one is safe to re-run.

```sh
git clone https://github.com/witran/dotfiles.git ~/code/dotfiles   # HTTPS: no SSH key yet
cd ~/code/dotfiles

./setup.sh                  # symlink configs, install tmux + vim, hook aliases/prompt into ~/.zshrc
bash setup-github-ssh.sh    # GitHub SSH key + shared agent (asks for a passphrase)
bash setup-remote-dev.sh "ssh-ed25519 AAAA... phone"   # ssh/mosh from your phone over Tailscale, key-only
```

Then open a new terminal so `~/.zshrc` changes take effect.

- `setup-github-ssh.sh` prints the public key to add at https://github.com/settings/keys.
- For `setup-remote-dev.sh`, generate an ed25519 key in your phone's SSH app and pass its **public** key. Without the argument, the script leaves SSH password login on.
- `setup-tailscale-https.sh` is Linux-only and is not needed on a Mac.
