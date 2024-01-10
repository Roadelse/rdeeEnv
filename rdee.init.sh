#!/bin/bash

###########################################################
# This script aims to deploy multiple rdee* repositories  #
# on a Linux system, including WSL.                       #
###########################################################


myDir=$(cd $(dirname "${BASH_SOURCE[0]}") && readlink -f .)
cd $myDir


# <L1> pre-check
gitVer=`git --version 2>/dev/null`
if [[ -z $gitVer ]]; then
	echo '\033[31m'"Error! Cannot find git command"'\033[0m'
	exit 200
elif [[ `echo $gitVer | grep -Po '(?<= )\d'` != 2 ]]; then
	echo '\033[33m'"Warning! git version too old: $gitVer"'\033[0m'
fi

if [[ -z `which python3 2>/dev/null` ]]; then
	echo '\033[31m'"Error! Cannot find python interpreter"'\033[0m'
	exit 200
fi




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



# <L1> resolve arguments
reHome=~
reRec=$reHome/recRoot
reGit=$reRec/GitRepos
reSoft=$reHome/Software
reMANA=$reSoft/mana
reModel=$reHome/models
reTool=$reHome/Tool
reTemp=$reHome/temp
reTest=$reHome/test


profile=~/.user
installDir=$reHome/Software/rdee
GitReposDir=$reHome/recRoot/GitRepos
echo_only=0

projs=(rdeeToolkit reSync)


# <L1> general
mkdir -p $installDir && cd $_
mkdir -p bin modulefiles/.components setenvfiles/.components


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

	# <L2> call init in this repo
	if [[ ! -e $GitReposDir/$p/init/init.Linux.sh ]]; then
		echo '\033[31m'"Error! Unsupported project without init script"'\033[0m'
		exit 200
	fi

	cd $GitReposDir/$p/init
	if [[ $echo_only == 0 ]]; then
		./init.Linux.sh -b $installDir/bin -s $installDir/setenvfiles/.components/load.${p}.sh -m $installDir/modulefiles/.components/${p} -p $profile
	fi
done


# <L0> union all init-scripts and modulefiles
cd $installDir

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
set-alias cdG {cd $reRec/GitRepos}

EOF



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