#!/bin/bash


#@ <prepare>
#@ <.global-setting>
set -e

#@ <.dependent>
curDir=$PWD
myDir=$(cd $(dirname "${BASH_SOURCE[0]}") && readlink -f .)

#@ <.pre-check>
#@ <..python/>
if [[ -z `which python3 2>/dev/null` ]]; then
	echo '\033[31m'"Error! Cannot find python interpreter"'\033[0m'
	exit 200
fi

#@ <.argument>
#@ <..default>
srcdir=$curDir
infile=
profile=
dstdir=
force=0
show_help=0
with_rdee=0
echo_only=0
#@ <..resolve>
while getopts "rehfp:s:d:i:" arg; do
    case $arg in
    r)
        with_rdee=1;;
    e)
        echo_only=1;;
    h)
        show_help=1;;
    f)
        force=1;;
    p)
        profile=$OPTARG;;
    s)
        srcdir=$OPTARG;;
    d)
        dstdir=$OPTARG;;
    i)
        infile=$OPTARG;;
    ?)
        echo -e "\033[31m Error! \033[0m Unknown option: $arg"
        exit 200;;
    esac
done

#@ <..help>
if [[ $show_help -eq 1 ]]; then
    echo -e "
usage: ./install-miniconda.sh [options]

options:
    ● \033[32m-r\033[0m
        under rdee framework or not
    ● \033[32m-e\033[0m
        Do not do any operation rather than echo
    ● \033[32m-h\033[0m
        show help information
    ● \033[32m-f\033[0m
        force installation even it exists
    ● \033[32m-p\033[0m profile, [\033[34mrequired\033[0m]
        set target profile to be updated. If under rdee framework, it is \033[33mfixed\033[0m to $reHome/.user
    ● \033[32m-s\033[0m srcdir, [optional], [required one of s&i]
        set source directory. If under rdee framework, it is \033[33mfixed\033[0m to $reSoft/src
    ● \033[32m-d\033[0m dstdir, [\033[34mrequired\033[0m]
        set installation directory. If under rdee framework, it is \033[33mfixed\033[0m to $reSoft/idep/miniconda3
    ● \033[32m-i\033[0m infile, [optional], [required one of s&i]
        set abspath of installed bash script. If not set, it will use existed or default scripts.
"
    exit 0
fi

#@ <.handle-force>
if [[ $force == 1 ]]; then
    echo "Don't support force option by now, please do not set -f"
    exit 200
fi

#@ <.rdee>
if [[ $with_rdee -eq 1 ]]; then
    #@ <..check-rdee>
    if [[ -z "$reHome" ]]; then
        echo -e "\033[31m Error! -r requires rdeeEnv deployed! Now cannot find env:reHome"
        exit 200
    fi
    #@ <..overwrite-p:d:s:>
    srcdir=$reSoft/src
    dstdir=$reSoft/idep

    if [[ -w /etc ]]; then
        profile=/etc/profile.d
    elif [[ $reHome == $HOME ]]; then
        for f in ".bash_profile" ".bash_login" ".profile"; do
            if [[ -e $HOME/$f ]]; then
                profile=$reHome/$f
            fi
        done
    else
        profile=$reHome/.user
    fi
fi

#@ <.check-args>
if [[ -z $dstdir || -z $profile ]]; then
    echo -e "\033[31m Error! \033[0m \"-d\" and \"-p\" is required!"
    exit 200
fi

#@ <.organize-path>
echo -e "\033[35m run: \033[0m mkdir -p $dstdir && cd \$_"
if [[ $echo_only == 0 ]]; then
    mkdir -p $dstdir && cd $_
fi

#@ <.dependent>
dstname=`basename $dstdir`


#@ <core>
if [[ -e $dstdir/lmod/lmod ]]; then
    echo "lmod already installed"
else
    mkdir -p $dstdir/lmod/src && cd $_

    zipfiles=(`ls $srcdir/Lmod*.tar.gz -t 2>/dev/null || true`)
    if [[ -z $zipfiles ]]; then
        wget https://github.com/TACC/Lmod/archive/refs/tags/8.7.34.tar.gz  #@ future may change an always-latest URL
        mv 8.7.34.tar.gz $srcdir/Lmod.8.7.34.tar.gz
        zf=$srcdir/Lmod.8.7.34.tar.gz
    else
        zf=${zipfiles[0]}
    fi

    zfn=`basename $zf`
    dn=`python3 -c "print('${zfn}'[:-7])"`  #@ dn -> directory name

    if [[ ! -e $dn ]]; then 
        tar -zxvf $zf
    fi

    cd $dn

    ./configure --prefix=$dstdir
    make install
fi


#@ <post>
if [[ -d $profile ]]; then
    echo -e "\033[33m Linking \033[0m $dstdir/lmod/lmod/init/profile into $profile/lmod.sh"
    if [[ $echo_only == 0 ]]; then
        ln -sf $dstdir/lmod/lmod/init/profile $profile/lmod.sh
    fi
else
    echo -e "\033[33m Updating \033[0m $profile"
    if [[ $echo_only == 0 ]]; then
        cat << EOF > .temp
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [lmod]
source $dstdir/lmod/lmod/init/profile

EOF
        python3 $myDir/../../tools/txtop.ra-nlines.py $profile .temp "#!/bin/bash\n\n"
        rm -f .temp
    fi
fi