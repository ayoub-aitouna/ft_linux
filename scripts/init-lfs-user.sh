#!/bin/bash

echo "*** Init LFS USER ENVIREMENT ***"

SetupEnv() {
    bash_profile_content="exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$' /bin/bash"
    echo $bash_profile_content >~/.bash_profile
    cp -v /home/lfs/config/bashrc ~/.bashrc
    if [ -e /etc/bash.bashrc ]; then
        mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
    fi
}

SetupEnv

echo "To continue, run the following command:"
echo "RUN ./scripts/main.sh"

source ~/.bashrc
source ~/.bash_profile
