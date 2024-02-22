#!/bin/bash

#@ <prepare>
#@ <.global-setting>
set -e

#@ <.dependent>
curDir=$PWD
myDir=$(cd $(dirname "${BASH_SOURCE[0]}") && readlink -f .)

#@ <.argument>
#@ <..default>
srcdir=$curDir
infile=
profile=
use_module=0
dstdir=
force=0
show_help=0
with_rdee=0
echo_only=0
#@ <..resolve>
while getopts "rehmfp:s:d:i:" arg; do
    case $arg in
    r)
        with_rdee=1;;
    e)
        echo_only=1;;
    h)
        show_help=1;;
    m)
        use_module=1;;
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
    ● \033[32m-m\033[0m
        use module to manage initialization, or it will use bash
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

#@ <.rdee>
if [[ $with_rdee -eq 1 ]]; then
    #@ <..check-rdee>
    if [[ -z "$reHome" ]]; then
        echo -e "\033[31m Error! -r requires rdeeEnv deployed! Now cannot find env:reHome"
        exit 200
    fi
    #@ <..overwrite-p:d:s:>
    srcdir=$reSoft/src
    profile=$reHome/.user
    dstdir=$reSoft/idep/miniconda3

fi

#@ <.check-args>
if [[ -z $dstdir ]]; then
    echo -e "\033[31m Error! \033[0m \"-d\" is required for non-rdee installation!"
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

if [[ -e $dstdir/bin && $force = 0 ]]; then  #@ branch skip existed miniconda installation
    echo -e "\033[33m Skip build process due to existed miniconda and force==0. \033[0m"
else
    #@ <.get-install-script> in $sf
    if [[ -n $infile ]]; then
        if [[ ! -e $infile ]]; then
            echo "\033[31mError!\033[0m Cannot find selected infile: $infile"
            exit 200
        fi
        sf=$infile
    else
        mkdir -p $srcdir  #@ exp ensurence operation
        shfiles=(`ls $srcdir/Miniconda3*.sh -t 2>/dev/null || true`)
        if [[ ! -d $srcdir ]]; then
            echo -e "\033[31m Error! \033[0m $srcdir is not an existed directory!"
            exit 200
        fi

        if [[ -z $shfiles ]]; then
            echo -e "\033[35m run: \033[0m wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh -P $srcdir"
            if [[ $echo_only == 0 ]]; then
                wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh -P $srcdir
            fi
            sf=$srcdir/Miniconda3-latest-Linux-x86_64.sh
        else
            sf=${shfiles[0]}
        fi
    fi

    #@ <.execute-install-script> need manual check
    echo -e "\033[35m run: \033[0m bash $sf -b -u -p $dstdir"
    if [[ $echo_only == 0 ]]; then
        bash $sf -b -u -p $dstdir  #@ <exp> use -u to install it in an existed directory
    fi
fi

#@ <post>
#@ <.update-condarc>
cat << EOF > $dstdir/condarc
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch-lts: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud

EOF


#@ <.manage-in-bash>
if [[ $use_module -eq 0 ]]; then  #@ branch use bash to control conda init, just update $profile
    cat << EOF > .temp
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [conda]
export CONDARC=$dstdir/condarc
function iC(){
    if [[ -z \${CONDA_EXE+x} ]]; then
        source $dstdir/etc/profile.d/conda.sh
    fi
    conda activate
}
function qC(){
    conda deactivate
    echo -e "\033[33m hint: \033[0m conda-relative functions still remained"
}

EOF
    echo -e "\033[35m run: \033[0m txtop.ra-nlines $profile .temp"
    if [[ $echo_only == 0 ]]; then
        txtop.ra-nlines $profile .temp
    fi
    rm .temp

else  #@ branch use module, need to organize modulefile and update $profile
    
    echo -e "\033[35m run: \033[0m Generating $dstdir/automodfiles/miniconda"
    if [[ $echo_only == 0 ]]; then
        mkdir -p $dstdir/automodfiles
        cat << EOF > $dstdir/automodfiles/$dstname
#%Module1.0

puts "source $reSoft/idep/miniconda3/etc/profile.d/conda.sh"
setenv CONDARC $dstdir/condarc
set-alias iC {conda activate}
set-alias qC {conda deactivate}
EOF
    fi

    if [[ $with_rdee = 0 ]]; then
        echo -e "\033[32m Succeed \033[0m to generate modulefile in $dstdir/automodfiles"
        echo -e "Now you \033[33m NEED \033[0m to organize the module control statement manually."
        exit 0
    fi

    echo -e "\033[35m run: \033[0m linking modulefiles"
    if [[ $echo_only == 0 ]]; then
        mkdir -p $reSoft/modulefiles/idep/$dstname
        ln -sf $dstdir/automodfiles/$dstname $reSoft/modulefiles/idep/$dstname
    fi

    cat << EOF > .temp
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [conda]
module load idep/$dstname

EOF

    echo -e "\033[35m run: \033[0m txtop.ra-nlines $profile .temp"
    if [[ $echo_only == 0 ]]; then
        txtop.ra-nlines $profile .temp
    fi
    
    rm .temp
    echo -e "\033[32m Succeed \033[0m to organize miniconda module"
fi