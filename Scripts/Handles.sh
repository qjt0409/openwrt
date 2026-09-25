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

echo "====================================================="
echo "4. 升级 dnsmasq 到 2.93（passwall 需要 >= 2.92）"
echo "====================================================="
DNSMASQ_MK="./package/network/services/dnsmasq/Makefile"
if [ -f "$DNSMASQ_MK" ]; then
	# 备份原 Makefile
	cp "$DNSMASQ_MK" "${DNSMASQ_MK}.orig"
	# 更新版本号和 hash
	sed -i 's/PKG_UPSTREAM_VERSION:=2.91/PKG_UPSTREAM_VERSION:=2.93/' "$DNSMASQ_MK"
	sed -i 's/PKG_HASH:=.*/PKG_HASH:=0c00d4e5c97c8306e5fb932b348b34269c9c29a0e7df0e8e82958b407092bc19/' "$DNSMASQ_MK"
	# 用 openwrt 官方的 patches 替换
	DNSMASQ_PATCHDIR="./package/network/services/dnsmasq/patches"
	if [ -d "$DNSMASQ_PATCHDIR" ]; then
		rm -rf "$DNSMASQ_PATCHDIR"
	fi
	mkdir -p "$DNSMASQ_PATCHDIR"
	# 下载 openwrt 官方 patches
	curl -sL "https://raw.githubusercontent.com/openwrt/openwrt/master/package/network/services/dnsmasq/patches/100-remove-old-runtime-kernel-support.patch" -o "$DNSMASQ_PATCHDIR/100-remove-old-runtime-kernel-support.patch"
	curl -sL "https://raw.githubusercontent.com/openwrt/openwrt/master/package/network/services/dnsmasq/patches/200-ubus_dns.patch" -o "$DNSMASQ_PATCHDIR/200-ubus_dns.patch"
	echo "dnsmasq upgraded to 2.93."
else
	echo "dnsmasq Makefile not found, skip."
fi

echo "====================================================="
echo "5. iStore 中文翻译路径修正（po 在 src/po/，luci.mk 只认 po/）"
echo "====================================================="
STORE_DIR="./package/luci-app-store"
if [ -d "$STORE_DIR/src/po" ] && [ ! -d "$STORE_DIR/po" ]; then
	cp -r "$STORE_DIR/src/po" "$STORE_DIR/po"
	echo "iStore po files copied from src/po to po/."
else
	echo "iStore po path already fixed or not found, skip."
fi

echo "====================================================="
echo "6. 修复易有云 linkease.lua 依赖已删除的 luci.model.ipkg"
echo "====================================================="
LINKEASE_CBI=$(find "$PACKAGE_PATH" -path "*luci-app-linkease*" -name "linkease.lua" 2>/dev/null | head -n 1)
if [ -n "$LINKEASE_CBI" ]; then
	sed -i 's/^require("luci.model.ipkg")/-- removed: require("luci.model.ipkg") (module dropped in 24.10, unused)/' "$LINKEASE_CBI"
	echo "linkease.lua fixed: $LINKEASE_CBI"
else
	echo "linkease.lua not found, skip."
fi

# 修复 init 脚本里二进制名不匹配：luci 前端调用 link-ease，实际二进制是 linkease
LINKEASE_INIT=$(find "$PACKAGE_PATH" -path "*luci-app-linkease*" -name "linkeaseinitd" 2>/dev/null | head -n 1)
if [ -n "$LINKEASE_INIT" ]; then
	sed -i 's/command link-ease/command linkease/g' "$LINKEASE_INIT"
	echo "linkease init fixed: $LINKEASE_INIT"
fi

# 修复 linkease 配置文件冲突（luci-app-linkease 和 linkease 主程序都提供 /etc/config/linkease）
if [ -f "./package/luci-app-linkease/root/etc/config/linkease" ]; then
	rm -f ./package/luci-app-linkease/root/etc/config/linkease
	echo "removed conflicting luci-app-linkease config"
fi

# 强制刷新 naiveproxy（旧版本下载链接404，用最新Makefile重新下载）
rm -rf ./build_dir/target-*/naiveproxy-* ./dl/naiveproxy-* 2>/dev/null
echo "naiveproxy cache cleared"
