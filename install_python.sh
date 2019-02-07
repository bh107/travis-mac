#!/bin/bash

set -e
set -x
unset PYTHONPATH

export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CFLAGS="-I/usr/local/opt/openssl/include"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"

wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tar.xz
tar -xf Python-3.7.0.tar.xz
cd Python-3.7.0
./configure --prefix=/opt/py3.7
make -j 2
sudo make install
cd ..

wget https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tar.xz
tar -xf Python-2.7.15.tar.xz
cd Python-2.7.15
./configure --prefix=/opt/py2.7
make -j 2
sudo make install
cd ..

wget https://www.python.org/ftp/python/3.6.8/Python-3.6.8.tar.xz
tar -xf Python-3.6.8.tar.xz
cd Python-3.6.8
./configure --prefix=/opt/py3.6
make -j 2
sudo make install
cd ..
