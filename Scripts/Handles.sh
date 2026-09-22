#!/bin/bash
# SPDX-License-Identifier: MIT
# 本脚本用于 LEDE (coolsnowwolf/lede) 源码微调。
# 执行目录：源码根目录（./feeds、./package 存在）

FEEDS_PATH="./feeds"
PACKAGE_PATH="./package"

echo "====================================================="
echo "1. Argon 主题默认配色调整"
echo "====================================================="
# 目标：luci-app-argon-config 的默认配置（luci feed 内置版或外部克隆版）
ARGON_CFG=$(find "$FEEDS_PATH/luci" "$PACKAGE_PATH" -maxdepth 5 -type f -path "*luci-app-argon-config/root/etc/config/argon" 2>/dev/null | head -n 1)
if [ -n "$ARGON_CFG" ]; then
	sed -i "s/primary '.*'/primary '#31a1a1'/g; s/'0.2'/'0.5'/g; s/'none'/'bing'/g; s/'600'/'normal'/g" "$ARGON_CFG" \
		&& echo "argon-config default adjusted: $ARGON_CFG"
else
	echo "argon-config not found, skip."
fi

echo "====================================================="
echo "2. root 默认密码保持 password（LEDE 默认设置，不做修改）"
echo "====================================================="
# LEDE 的 zzz-default-settings 会把 root 密码设为 "password"，按需求保留不改。
echo "root password: password (LEDE default, kept as-is)."

echo "====================================================="
echo "3. 修复 Rust 编译（老版本 ci-llvm 选项）"
echo "====================================================="
if [ -d "$FEEDS_PATH/packages/lang/rust" ]; then
	sed -i 's/ci-llvm=true/ci-llvm=false/g' "$FEEDS_PATH/packages/lang/rust/Makefile" \
		&& echo "rust Makefile fixed."
fi
