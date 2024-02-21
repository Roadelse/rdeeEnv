#!/bin/bash

DEPRECATED
@2024-02-19 17:24:05
发现不同linux下的这个.profile, .bash_profile啥的, 很不统一, 所以我最好不要碰这玩意儿
尽量都在.bashrc里做, 如果.bashrc也没做interactive判断, 那我自己加上去呗...
主要是别碰profile, 我也不希望加太多全局操作, 搞得scp都慢...


#@ <Introduction>
#@ This script aims to configure ~/.bash_profile & ~/.profile & ~/.profile.d for at least user-level rdee installation
#@ </Introduction>

#@ <prepare>
#@ <.global-setting>
set -e

#@ <.dependent>
curDir=$PWD
myDir=$(cd $(dirname "${BASH_SOURCE[0]}") && readlink -f .)

#@ <.pre-check>
#@ <..python/>
if [[ -z `which python3 2>/dev/null || true` ]]; then
	echo '\033[31m'"Error! Cannot find python interpreter"'\033[0m'
	exit 200
fi
#@ <..rdeeEnv>
if [[ -z "$reHome" ]]; then
    echo "\033[31m Error! \033[0m Must initialize rdeeEnv first."
    exit 200
fi


#@ <core>
#@ <.bash_profile> source ~/.profile in ~/.bash_profile
if [[ $reHome == $HOME ]]; then
    cat << EOF >> .temp
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [.profile]
if [ -f ~/.profile ]; then
   . ~/.profile
fi

EOF
    txtop.ra-nlines ~/.bash_profile .temp
    rm .temp
fi
#@ <.bash_profile/>


#@ <.profile> handle ~/.profile.d in ~/.profile
if [[ $reHome == $HOME ]]; then
    mkdir -p $HOME/.profile.d
    cat << EOF >> .temp
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [.profile.d]
if [ -d "$HOME/.profile.d" ]; then
  for profile_script in "$HOME/.profile.d/"*.sh; do
    if [ -x "\$profile_script" ]; then
      . "\$profile_script"
    fi
  done
fi

EOF
    txtop.ra-nlines ~/.profile .temp
    rm .temp
fi
#@ <.profile/>