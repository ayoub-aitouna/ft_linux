#!/bin/bash


echo "*** Init LFS USER ENVIREMENT ***"

SetupEnv() {
    bash_profile_content="exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$' /bin/bash"
    echo $bash_profile_content >~/.bash_profile
    cp -v ./config/bashrc ~/.bashrc
    if [ -e /etc/bash.bashrc ]; then
        mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
    fi
}
exec source ~/.bash_profile
exec source ~/.bashrc

# sudo sh ./scripts/prerequisites.sh
# sudo sh ./scripts/version-check.sh
SetupEnv
# sh ./compiling-cross-chain.sh
