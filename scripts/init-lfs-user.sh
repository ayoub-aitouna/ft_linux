#!/bin/bash

SetupEnv() {
    bash_profile_content=$(exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$' /bin/bash)
    echo $bash_profile_content >~/.bash_profile
    cp -v ./config/bashrc ~/.bashrc
    source ~/.bash_profile

    if [ -e /etc/bash.bashrc ]; then
        mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
    fi
}

sudo sh ./scripts/prerequisites.sh
sh ./scripts/version-check.sh
SetupEnv
