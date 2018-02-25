# Dotfiles

```
# [TODO] only for reference at the moment
ln -sf .tmux.conf.local ~/.tmux.conf.local
ln -sf .tmux.conf ~/.tmux.conf

# vi 8
sudo add-apt-repository ppa:jonathonf/vim
sudo apt-get update
sudo apt-get install vim

# tmux 2
# https://gist.github.com/P7h/91e14096374075f5316e 
# Steps to build and install tmux from source.
# Takes < 25 seconds on EC2 env [even on a low-end config instance].

VERSION=2.5
sudo yum -y remove tmux
sudo yum -y install wget tar libevent-devel ncurses-devel
wget https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz
tar xzf tmux-${VERSION}.tar.gz
rm -f tmux-${VERSION}.tar.gz
cd tmux-${VERSION}
./configure
sudo make install
cd -
sudo rm -rf /usr/local/src/tmux-*
sudo mv tmux-${VERSION} /usr/local/src

## Logout and login to the shell again and run.
## tmux -V
```
