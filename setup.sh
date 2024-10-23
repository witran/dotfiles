ln -sf $(pwd)/tmux.conf $HOME/.tmux.conf
ln -sf $(pwd)/tmux.conf.local $HOME/.tmux.conf.local
ln -sf $(pwd)/vimrc $HOME/.vimrc
ln -sf $(pwd)/aliases $HOME/.aliases
ln -sf $(pwd)/ps $HOME/.ps
ln -sf $(pwd)/gitconfig $HOME/.gitconfig

source_cmd="source ~/.aliases && source ~/.ps"
bash_file_path="$HOME/.bashrc"
grep -qxF "$source_cmd" $bash_file_path || echo $source_cmd >> $bash_file_path
