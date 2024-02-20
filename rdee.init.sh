#!/bin/bash

###########################################################
# This script aims to deploy multiple rdee* repositories  #
# on a Linux system, including WSL.                       #
###########################################################

# 2024-01-11    init
# 2024-02-20    rebuild, based on three modals and more linux settings and software installation

#@ <prepare/>
#@ <.globalSetting/>
set -e
#@ <.keyVariables/>
myDir=$(cd $(dirname "${BASH_SOURCE[0]}") && readlink -f .)
[[ -n $WSL_DISTRO_NAME ]] && isWSL=1 || isWSL=0

if [[ $isWSL == 1 ]]; then
    winuser=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r')  #>- "| tr -d '\r'" is necessary or the username is followed by a ^M
fi

ANSI_RED='\033[31m'
ANSI_GREEN='\033[32m'
ANSI_YELLOW='\033[33m'
ANSI_NC='\033[0m'

#@ <.pre-check/>
set +e  #@ exp allow non-zero status during check process
#@ <..git/>
gitVer=`git --version 2>/dev/null`
if [[ -z $gitVer ]]; then
	echo '\033[31m'"Error! Cannot find git command"'\033[0m'
	exit 200
elif [[ `echo $gitVer | grep -Po '(?<= )\d'` != 2 ]]; then
	echo -e '\033[33m'"Warning! git version too old: $gitVer"'\033[0m'
fi
#@ <..python/>
if [[ -z `which python3 2>/dev/null` ]]; then
	echo '\033[31m'"Error! Cannot find python interpreter"'\033[0m'
	exit 200
fi
#@ <..git-protocol/>
git status >& /dev/null
if [[ $? == 0 ]]; then  #>- in git repo
	remoteAddr=`git remote -v | grep origin -m 1 | awk '{print $2}'`
	if [[ remoteAddr =~ ^git ]]; then
		git_clone_protocol=ssh
	else
		git_clone_protocol=https
	fi
else  #>- downloaded ZIP directly in website
	git_clone_protocol=https
fi
set -e  #@ exp Forbid non-zero status after


#@ <.arguments>  
#@ <..defaultArg>
profile=
echo_only=0
shop_help=0
#@ <..resolve>
ARGS=`getopt -o r:p:eh --long reHome:,echo_only,profile:,help -n "$0" -- "$@"`
eval set -- "$ARGS"
while true; do
    case "$1" in
        -r|--reHome)
            reHome_fromArg=$2
            shift 2
            ;;
        -e|--echo_only)
            echo_only=1
            shift 1
            ;;
        -p|--profile)
            profile=$2
            shift 2
            ;;
        -h|--help)
            show_help=1
            shift 1
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unknown option $1"
            exit 200
            ;;
    esac
done

#@ <..help>
if [[ $show_help == 1 ]]; then
    echo -e "
usage: ./rdee.init.sh [options]

options:
    ● \033[32m-h\033[0m
        show help information
    ● \033[32m-e\033[0m
        Do not do any operation rather than echo
    ● \033[32m-r\033[0m, default:\$HOME
        set reHome path
    ● \033[32m-p\033[0m, [optional]
        set target profile to be updated.
"
    exit 0
fi

#@ <..reHome>
if [[ -n ${reHome_fromArg+x} ]]; then  #@ branch set reHome in arguments manually
    reHome=$reHome_fromArg
elif [[ -z ${reHome} ]]; then #@ branch set default reHome
    reHome=${HOME}
fi #@ branch omit branch which set reHome in environment variables
echo -e "\033[32m reHome \033[0m = $reHome"

echo reHome=$reHome

#@ <.dependent>
reRec=$reHome/recRoot
reGit=$reRec/GitRepos
reSoft=$reHome/Software
reMANA=$reSoft/mana
reModel=$reHome/models
reTool=$reHome/Tool
reTemp=$reHome/temp
reTest=$reHome/test


installDir=$reSoft/rdee

#@ <core>
#@ <.org-file-dir>
#@ <.WSL-basics>
if [[ $isWSL ]]; then

    reDesktop=$reHome/Desktop
    reOnedrive=$reHome/Onedrive
    reBaidusync=$reHome/Baidusync
    reDownloads=$reHome/Downloads

    ln -Tsf /mnt/d/recRoot $reRec

    ln -Tsf /mnt/d/Baidusyncdisk $reBaidusync
    ln -Tsf /mnt/c/Users/${winuser}/OneDrive $reOnedrive
    ln -Tsf /mnt/c/Users/${winuser}/Desktop $reDesktop
    ln -Tsf /mnt/c/Users/${winuser}/Downloads $reDownloads

    mkdir -p $reHome/Software
    ln -Tsf /mnt/d/recRoot/DataVault/INSTALL $reHome/Software/src
fi

#@ <.rdee-installation>
rm -rf $installDir
mkdir -p $installDir && cd $_
mkdir -p bin
mkdir -p setenvfiles/.components
mkdir -p modulefiles/.components

#@ <.Basics>
#@ <..general-linux-settings>
cat << EOF > setenvfiles/.components/load.rdeeself.sh
#!/bin/bash

export reHome=${reHome}
export reRec=${reRec}
export reGit=${reGit}
export reSoft=${reSoft}
export reMANA=${reMANA}
export reModel=${reModel}
export reTool=${reTool}
export reTemp=${reTemp}
export reTest=${reTest}


alias cdR='cd $reRec'
alias cdG='cd $reGit'


export ANSI_RED='\033[31m'
export ANSI_GREEN='\033[32m'
export ANSI_YELLOW='\033[33m'
export ANSI_NC='\033[0m'

alias ..='cd ..'
alias ...='cd ../..'

alias rp='realpath'
alias ls='ls --color=auto'
alias ll='ls -alFh'
alias la='ls -A'


alias pso='ps -o ruser=userForLongName -e -o pid,ppid,c,stime,tty,time,cmd'
alias psu='ps -u \`whoami\` -o pid,tty,time,cmd'
alias du1='du --max-depth=1 -h'
alias dv='dirsv -v'
alias topu='top -u \`whoami\`'
alias cd0='cd \`readlink -f .\`'

alias gf='gfortran'


alias web='echo "plz copy : export http_proxy=127.0.0.1:port; export https_proxy=127.0.0.1:port"'
alias unweb='unset https_proxy; unset http_proxy'

EOF

cat << EOF > modulefiles/.components/rdeeself
setenv reHome ${reHome}
setenv reRec ${reRec}
setenv reGit ${reGit}
setenv reSoft ${reSoft}
setenv reMANA ${reMANA}
setenv reModel ${reModel}
setenv reTool ${reTool}
setenv reTemp ${reTemp}
setenv reTest ${reTest}


set-alias cdR {cd $reRec}
set-alias cdG {cd $reGit}


setenv ANSI_RED {\033[31m}
setenv ANSI_GREEN {\033[32m}
setenv ANSI_YELLOW {\033[33m}
setenv ANSI_NC {\033[0m}

set-alias .. {cd ..}
set-alias ... {cd ../..}


set-alias rp realpath

set-alias ll {ls -alF}
set-alias ls {ls --color=auto}
set-alias la {ls -A}


set-alias pso {ps -o ruser=userForLongName -e -o pid,ppid,c,stime,tty,time,cmd}
set-alias psu {ps -u \`whoami\` -o pid,tty,time,cmd}
set-alias grep {grep --color=auto}
set-alias du1 {du --max-depth=1 -h}
set-alias dv {dirs -v}
set-alias topu {top -u \`whoami\`}
set-alias cd0 {cd \`readlink -f .\`}

set-alias gf {gfortran}


set-alias web {echo "plz copy : export http_proxy=127.0.0.1:port; export https_proxy=127.0.0.1:port"}
set-alias unweb {unset https_proxy; unset http_proxy}

EOF
#@ <..WSL-only-settings>
if [[ $isWSL == 1 ]]; then
    cat << EOF >> setenvfiles/.components/load.rdeeself.sh
# >>>>>>>>>>>>>> WSL settings
export winuser=$winuser
export Onedrive=$reOnedrive
alias cdO='cd \$OneDrive/recRoot'
export Baidusync=$reBaidusync
alias cdB='cd \$Baidusync/recRoot'
export winHome=/mnt/c/Users/${winuser}
export Desktop=$reDesktop
alias cdU='cd \$winHome'
alias cdD='cd \$Desktop'

alias ii='explorer.exe'
EOF

    cat << EOF >> modulefiles/.components/rdeeself
setenv winuser $winuser
setenv Onedrive $reOnedrive
setenv Baidusync $reBaidusync
setenv winHome /mnt/c/Users/${winuser}
setenv Desktop $reDesktop

set-alias cdO "cd \$env(Onedrive)/recRoot"
set-alias cdB "cd \$env(Baidusync)/recRoot"
set-alias cdU "cd \$env(winHome)"
set-alias cdD "cd \$env(Desktop)"

set-alias ii {explorer.exe}
EOF

    if [[ `ls /mnt/d/DAPP/SumatraPDF/SumatraPDF*exe` != "" ]]; then
        echo 'alias pdf=/mnt/d/DAPP/SumatraPDF/SumatraPDF*exe' >> setenvfiles/.components/load.rdeeself.sh
	    echo 'set-alias pdf {/mnt/d/DAPP/SumatraPDF/SumatraPDF*exe}' >> modulefiles/.components/rdeeself
    fi

fi

#@ <.git-projs>
projs=(rdeeToolkit reSync dirdeck workFlowRec)


#@ <..loop-projs>
for p in "${projs[@]}"; do
	if [[ ! -e $reGit/$p ]]; then
		echo "No $p in $reGit, clone it"
		cd $reGit
		if [[ $echo_only == 0 ]]; then
			if [[ $git_clone_protocol == ssh ]]; then
				git clone --depth 1 git@github.com:Roadelse/$p.git  #>- ignore fingerprint check since it should have been confirmed in cloning rdeeEnv itself
			else
				git clone --depth 1 https://github.com/Roadelse/$p.git
			fi
		fi
	else
		echo -e "$p \033[33mdetected\033[0m in $reGit, use the existed one"
	fi

	# <...call-init> call init in this repo
	if [[ ! -e $reGit/$p/init/init.Linux.sh ]]; then
		echo '\033[31m'"Error! Unsupported project without init script"'\033[0m'
		exit 200
	fi

	cd $reGit/$p/init
	if [[ $echo_only == 0 ]]; then
		bash $reGit/$p/init/init.Linux.sh -b $installDir/bin -s $installDir/setenvfiles/.components/load.${p}.sh -m $installDir/modulefiles/.components/${p}
	fi
done


# <.union> union all init-scripts and modulefiles
echo "Union all load-script components into one"
cd $installDir
if [[ $echo_only == 0 ]]; then
	$reGit/rdeeToolkit/bin/io/txtop.union-setenv-modulefiles.py setenvfiles/load.rdee.sh setenvfiles/.components/*
fi
chmod +x setenvfiles/load.rdee.sh  #>- <imporve> force filename synchronization

echo "Union all modulefile components into one"
if [[ $echo_only == 0 ]]; then
	$reGit/rdeeToolkit/bin/io/txtop.union-setenv-modulefiles.py modulefiles/rdee modulefiles/.components/*
fi


#@ <post> 
#@ <.link-modulefiles> link generated modulefiles to $reSoft/modulefiles
mkdir -p $reSoft/modulefiles/rdee
ln -sf $installDir/modulefiles/rdee $reSoft/modulefiles/rdee

#@ <.modify-profile> init control & PS1 setting
if [[ -n $profile ]]; then
    echo -e "profile detected, which way to init rdee? [${ANSI_YELLOW}setenv${ANSI_NC}|${ANSI_GREEN}module${ANSI_NC}] default:${ANSI_GREEN}module${ANSI_NC} "
    read sm
    if [[ -z $sm ]]; then
        sm=module
    fi
    
    if [[ $sm == "module" ]]; then  #@ branch use module to init rdee
        cat << EOF > .temp
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [rdee] init
# <Wrong-Setting> export PS1='\033[01;32m\\u@\\h\033[0m:\033[01;34m\\W\033[0m$ '
export PS1='\\[\033[01;32m\\]\\u@\\h\\[\033[0m\\]:\\[\033[01;34m\\]\\W\\[\033[0m\\]$ '
module use $reSoft/modulefiles
module load rdee

EOF
        python3 $myDir/tools/txtop.ra-nlines.py $profile .temp '#!/bin/bash'
        rm -f .temp

    elif [[ $sm == "setenv" ]]; then  #@ branch use shell script to init rdee
        cat << EOF > .temp
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [rdee] init
# <Wrong-Setting> export PS1='\033[01;32m\\u@\\h\033[0m:\033[01;34m\\W\033[0m$ '
export PS1='\\[\033[01;32m\\]\\u@\\h\\[\033[0m\\]:\\[\033[01;34m\\]\\W\\[\033[0m\\]$ '
source $installDir/setenvfiles/load.rdee.sh

EOF
        python3 $myDir/tools/txtop.ra-nlines.py $profile .temp '#!/bin/bash'
        rm -f .temp
    else
        echo "Unknown input: $sm"
        exit 200
    fi
else
    echo -e "${ANSI_YELLOW}no profile detected${ANSI_NC}, use '-p ...' to add init statements"
    exit 0
fi
