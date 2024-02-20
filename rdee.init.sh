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

#@ <.pre-check/>
set +e  #@ exp allow non-zero status during check process
#@ <..git/>
gitVer=`git --version 2>/dev/null`
if [[ -z $gitVer ]]; then
	echo '\033[31m'"Error! Cannot find git command"'\033[0m'
	exit 200
elif [[ `echo $gitVer | grep -Po '(?<= )\d'` != 2 ]]; then
	echo '\033[33m'"Warning! git version too old: $gitVer"'\033[0m'
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
#@ <..resolve>
ARGS=`getopt -o r:p:e --long reHome:,echo_only,profile: -n "$0" -- "$@"`
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

#@ <..reHome>
if [[ -n ${reHome_fromArg+x} ]]; then  #@ branch set reHome in arguments manually
    reHome=$reHome_fromArg
elif [[ -z ${reHome} ]]; then #@ branch set default reHome
    reHome=${HOME}
fi #@ branch omit branch which set reHome in environment variables



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
    winuser=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r')  #>- "| tr -d '\r'" is necessary or the username is followed by a ^M
    cat << EOF >> setenvfiles/.components/load.rdeeself.sh
# >>>>>>>>>>>>>> WSL settings
export winuser=$winuser
export Onedrive=/mnt/c/Users/${winuser}/OneDrive
alias cdO='cd \$OneDrive'
export Baidusync=/mnd/d/BaiduSyncdisk
alias cdB='cd \$Baidusync'
export winHome=/mnt/c/Users/${winuser}
export Desktop=\$winHome/Desktop
alias cdU='cd \$winHome'
alias cdD='cd \$Desktop'

alias ii='explorer.exe'
EOF

    cat << EOF >> modulefiles/.components/rdeeself
setenv winuser $winuser
setenv Onedrive /mnt/c/Users/${winuser}/OneDrive
setenv Baidusync /mnd/d/BaiduSyncdisk
setenv winHome /mnt/c/Users/${winuser}
setenv Desktop \$env(winHome)/Desktop

set-alias cdO "cd \$env(Onedrive)"
set-alias cdB "cd \$env(Baidusync)"
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
projs=(rdeeToolkit reSync)


#@ <..loop-projs>
for p in "${projs[@]}"; do
	if [[ ! -e $GitReposDir/$p ]]; then
		echo "No $p, clone it to $GitReposDir/$p"
		cd $GitReposDir
		if [[ $echo_only == 0 ]]; then
			if [[ $git_clone_protocol == ssh ]]; then
				git clone git@github.com:Roadelse/$p.git  #>- ignore fingerprint check since it should have been confirmed in cloning rdeeEnv itself
			else
				git clone https://github.com/Roadelse/$p.git
			fi
		fi
	else
		echo "$p detected in $GitReposDir, use the existed one"
	fi

	# <...call-init> call init in this repo
	if [[ ! -e $GitReposDir/$p/init/init.Linux.sh ]]; then
		echo '\033[31m'"Error! Unsupported project without init script"'\033[0m'
		exit 200
	fi

	cd $GitReposDir/$p/init
	if [[ $echo_only == 0 ]]; then
		$reGit/$p/init/init.Linux.sh -b $installDir/bin -s $installDir/setenvfiles/.components/load.${p}.sh -m $installDir/modulefiles/.components/${p}
	fi
done


# <.nion> union all init-scripts and modulefiles
echo "Union all load-script components into one"
cd setenvfiles
if [[ $echo_only == 0 ]]; then
	$myDir/tools/union.py .components/*
fi
chmod +x load.rdee.sh  #>- <imporve> force filename synchronization

echo "Union all modulefile components into one"
cd ../modulefiles
if [[ $echo_only == 0 ]]; then
	$myDir/tools/union.py .components/*
fi

# <L0> add in system
# to be deved
if [[ -n $profile ]]; then
    read -p "profile detected, which way to init rdee? [setenv|module] default: module" $sm
    if [[ -z $sm ]]; then
        sm=module
    fi
    if [[ $sm == "module" ]]; then
        if [[ -n `grep -P '# >>* \[rdee\] init' $profile 2>/dev/null` ]]; then
            sed -i '/^# >* \[rdee\] init/,/^$/c\
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [rdee] init\
export PS1='\''\\033[01;32m\\u@\\h\\033[0m:\\033[01;34m\\W\\033[0m$ '\'"\
module use $installDir/modulefiles\
module load rdee\
" $profile
        else
            if [[ ! -e $profile ]]; then   #>- added @2024-01-05 22:44:58
                echo -e "#!/bin/bash\n\n" > $profile
            fi
                
            cat << EOF >> $profile

# >>>>>>>>>>>>>>>>>>>>>>>>>>> [rdee] init
export PS1='\033[01;32m\\u@\\h\033[0m:\033[01;34m\\W\033[0m$ '
module use $installDir/modulefiles
module load rdee

EOF
        fi
    elif [[ $sm == "setenv" ]]; then
        if [[ -n `grep -P '# >>* \[rdee\] init' $profile 2>/dev/null` ]]; then
            sed -i '/^# >* \[rdee\] init/,/^$/c\
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [rdee] init\
export PS1='\''\\033[01;32m\\u@\\h\\033[0m:\\033[01;34m\\W\\033[0m$ '\'"\
source $installDir/setenvfiles/load.rdee.sh\
" $profile
        else
            if [[ ! -e $profile ]]; then   #>- added @2024-01-05 22:44:58
                echo -e "#!/bin/bash\n\n" > $profile
            fi
                
            cat << EOF >> $profile

# >>>>>>>>>>>>>>>>>>>>>>>>>>> [rdee] init
export PS1='\033[01;32m\\u@\\h\033[0m:\033[01;34m\\W\033[0m$ '
source $installDir/setenvfiles/load.rdee.sh

EOF
        fi
    else
        echo "Unknown input: $sm"
        exit 200
    fi
fi