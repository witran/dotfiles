ln -sf $(pwd)/tmux.conf $HOME/.tmux.conf
ln -sf $(pwd)/tmux.conf.local $HOME/.tmux.conf.local
ln -sf $(pwd)/vimrc $HOME/.vimrc
ln -sf $(pwd)/aliases.sh $HOME/.aliases.sh
ln -sf $(pwd)/ps.sh $HOME/.ps.sh
ln -sf $(pwd)/gitconfig $HOME/.gitconfig

source_cmd="source ~/.aliases.sh && source ~/.ps.sh"
bash_file_path="$HOME/.bashrc"
grep -qxF "$source_cmd" $bash_file_path || echo $source_cmd >> $bash_file_path
