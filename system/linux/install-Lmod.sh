#!/bin/bash

# probable pre-requisites:
#   ● 


set -e

if [[ -e $HOME/Software/idep/lmod/lmod ]]; then
    echo "lmod already installed"
else
    mkdir -p $HOME/Software/idep/lmod/src && cd $_

    zipfiles=(`ls *.tar.gz 2>/dev/null || true`)
    if [[ -z $zipfiles ]]; then
        wget https://github.com/TACC/Lmod/archive/refs/tags/8.7.34.tar.gz
        zf=8.7.34.tar.gz
    else
        zf=${zipfiles[0]}  #@ exp ?? maybe use the last one is better
    fi

    dn=`python3 -c "print(${zf}[:-7])"`  #@ dn -> directory name

    if [[ ! -e $dn ]]; then 
        tar -zxvf $zf
    fi

    cd $dn

    ./configure --prefix=$HOME/Software/idep
    make install
fi

sudo ln -sf $HOME/Software/idep/lmod/lmod/init/profile /etc/profile.d/lmod.sh