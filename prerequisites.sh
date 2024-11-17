#!/bin/bash

apt-get -y update
apt-get -y install build-essential
apt-get -y install bison
apt-get -y install gawk
apt-get -y install texinfo
ln -sf bash /bin/sh
