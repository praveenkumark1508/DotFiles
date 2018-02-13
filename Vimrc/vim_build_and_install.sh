#!/bin/bash

sudo apt-get remove --purge vim vim-runtime vim-gnome vim-tiny vim-gui-common

sudo apt-get install liblua5.1-dev luajit libluajit-5.1 python-dev ruby-dev libperl-dev libncurses5-dev libatk1.0-dev libx11-dev libxpm-dev libxt-dev

#Optional: so vim can be uninstalled again via `dpkg -r vim`
sudo apt-get install checkinstall

sudo rm -rf /usr/local/share/vim /usr/bin/vim /usr/local/bin/vim

cd ~/GitHub/Vim/
git fetch
git pull

#In case Vim was already installed
cd src
make distclean
cd ..

./configure \
    --enable-multibyte \
    --enable-perlinterp=dynamic \
    --enable-rubyinterp=dynamic \
    --with-ruby-command=/usr/bin/ruby \
    --enable-python3interp \
    --with-python3-config-dir=/home/praveen/anaconda3/lib/python3.6/config-3.6m-i386-linux-gnu \
    --enable-luainterp \
    --with-luajit \
    --enable-cscope \
    --enable-gui=auto \
    --with-features=huge \
    --with-x \
    --enable-fontset \
    --enable-largefile \
    --disable-netbeans \
    --with-compiledby="Praveen Kumar K" \
    --enable-fail-if-missing

make && sudo make install

