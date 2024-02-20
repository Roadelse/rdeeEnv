#!/bin/bash

wget https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init
RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup ./rustup-init  # use domestic mirror to speed up downloading process

cat << EOF > ~/.cargo/config
# 指定镜像
#replace-with = 'sjtu'
replace-with = 'ustc'

# 源码地址
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"

# 清华大学
[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"

# 中国科学技术大学
[source.ustc]
registry = "https://mirrors.ustc.edu.cn/crates.io-index"
#registry = "git://mirrors.ustc.edu.cn/crates.io-index"

# 上海交通大学
[source.sjtu]
registry = "https://mirrors.sjtug.sjtu.edu.cn/git/crates.io-index"

# rustcc社区
[source.rustcc]
registry = "git://crates.rustcc.cn/crates.io-index"

[source.aliyun]
registry = "https://code.aliyun.com/rustcc/crates.io-index"
[net]
git-fetch-with-cli=true
[http]
check-revoke = false
EOF