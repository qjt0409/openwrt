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
echo "2. 移除 LEDE 默认 root 密码（恢复首次登录自行设置密码）"
echo "====================================================="
# LEDE 的 zzz-default-settings 会把 root 密码写死为 "password"（知名哈希含 V4UetPzk），
# 与需求"首次登录设置密码"冲突，删除对应行后 root 默认无密码，LuCI 首次登录会提示设置。
DEFAULT_SETTINGS="$PACKAGE_PATH/lean/default-settings/files/zzz-default-settings"
if [ -f "$DEFAULT_SETTINGS" ]; then
	sed -i '/V4UetPzk/d' "$DEFAULT_SETTINGS" \
		&& echo "LEDE default root password removed (first-login password setup restored)."
else
	echo "default-settings not found, skip."
fi

echo "====================================================="
echo "3. 修复 Rust 编译（老版本 ci-llvm 选项）"
echo "====================================================="
if [ -d "$FEEDS_PATH/packages/lang/rust" ]; then
	sed -i 's/ci-llvm=true/ci-llvm=false/g' "$FEEDS_PATH/packages/lang/rust/Makefile" \
		&& echo "rust Makefile fixed."
fi
