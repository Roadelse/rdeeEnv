#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "Error: This script must be run as root or with sudo." >&2
   exit 1
fi

if [[ ! -e /etc/apt/sources.list.ori ]]; then
    cp -f /etc/apt/sources.list /etc/apt/sources.list.ori
fi

cat << EOF > /etc/apt/sources.list
#添加阿里源
deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
# #中科大源
# deb https://mirrors.ustc.edu.cn/ubuntu/ jammy main restricted universe multiverse
# deb https://mirrors.ustc.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
# deb https://mirrors.ustc.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
# deb https://mirrors.ustc.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
# deb https://mirrors.ustc.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
# #163源
# deb http://mirrors.163.com/ubuntu/ jammy main restricted universe multiverse
# deb http://mirrors.163.com/ubuntu/ jammy-security main restricted universe multiverse
# deb http://mirrors.163.com/ubuntu/ jammy-updates main restricted universe multiverse
# deb http://mirrors.163.com/ubuntu/ jammy-proposed main restricted universe multiverse
# deb http://mirrors.163.com/ubuntu/ jammy-backports main restricted universe multiverse
# #清华源
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
EOF

sudo apt update