#!/bin/bash
# VERSION=2.8
VERSION=3.5a
sudo apt-get -y remove tmux
sudo apt-get -y install build-essential wget tar libevent-dev libncurses-dev bison byacc
wget https://github.com/tmux/tmux/releases/download/${VERSION}/tmux-${VERSION}.tar.gz
tar xf tmux-${VERSION}.tar.gz
rm -f tmux-${VERSION}.tar.gz
cd tmux-${VERSION}
./configure
make
sudo make install
cd -
sudo rm -rf /usr/local/src/tmux-*
sudo mv tmux-${VERSION} /usr/local/src
