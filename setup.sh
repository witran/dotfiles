ln -sf $(pwd)/tmux.conf $HOME/.tmux.conf
ln -sf $(pwd)/tmux.conf.local $HOME/.tmux.conf.local
ln -sf $(pwd)/vimrc $HOME/.vimrc
ln -sf $(pwd)/aliases.sh $HOME/.aliases.sh
ln -sf $(pwd)/ps.sh $HOME/.ps.sh
ln -sf $(pwd)/gitconfig $HOME/.gitconfig
mkdir -p $HOME/.claude
ln -sf $(pwd)/claude-settings.json $HOME/.claude/settings.json
mkdir -p $HOME/.config/ghostty
ln -sf $(pwd)/ghostty.config $HOME/.config/ghostty/config

# Install Tailscale HTTPS cert auto-renewal cron job (needs root).
# Installed name has no ".cron" extension — cron ignores files containing a dot.
if command -v sudo >/dev/null 2>&1; then
  sudo install -m 0644 -o root -g root \
    "$(pwd)/tailscale-cert-renew.cron" /etc/cron.d/tailscale-cert-renew \
    && echo "Installed /etc/cron.d/tailscale-cert-renew (weekly cert renewal)."
fi

source_cmd="source ~/.aliases.sh && source ~/.ps.sh"
bash_file_path="$HOME/.bashrc"
grep -qxF "$source_cmd" $bash_file_path || echo $source_cmd >> $bash_file_path
