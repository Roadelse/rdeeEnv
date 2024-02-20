#!/bin/bash

mkdir -p ~/Software/idep/miniconda3 && cd $_

shfiles=(`ls Miniconda3*.sh 2>/dev/null || true`)
if [[ -z $shfiles ]]; then
    wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh
    sf=Miniconda3-latest-Linux-x86_64.sh
else
    sf=${shfiles[0]}  #@ exp ?? maybe use the last one is better
fi

bash $sf -u  #@ <exp> use -u to install it in an existed directory

if [[ -w /etc/profile.d ]]; then
    read -p "w-authority detected! Do you want to add conda.sh in /etc/profile.d? [yes|no] default:yes" isGlobal
    if [[ -z $isGlobal ]]; then
        isGlobal=yes
    fi
    if [[ "$isGlobal" != "yes" && "$isGlobal" != "no" ]]; then
        echo -e "\033[31m Error! \033[0m Unknown input for isGlobal: ${isGlobal}, must be [yes|no]"
        exit 101
    fi
fi
if [[ $isGlobal == "yes" ]]; then
    ln -sf ~/Software/idep/miniconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh
else
    ln -sf ~/Software/idep/miniconda3/etc/profile.d/conda.sh $HOME/.profile.d/conda.sh
fi

cat << EOF > ~/Software/idep/miniconda3/automodfiles
#%Module1.0

set-alias iC {conda activate}
EOF