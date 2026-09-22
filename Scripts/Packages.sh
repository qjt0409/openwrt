#!/bin/bash
# SPDX-License-Identifier: MIT
# 本脚本用于 LEDE (coolsnowwolf/lede) x86 云编译的插件拉取与冲突处理。
# 插件来源优先使用用户提供的仓库清单；缺失时由 luci feed / packages feed 内置包补齐。
# 执行目录：源码根目录（./feeds、./package 存在）

#====================================================
# 工具函数
#====================================================

# 删除 feeds 中与指定名称匹配的包目录（防止与外部克隆包重名导致包重复定义）
# 同时清理 feeds install 后指向它们的符号链接，避免悬空链接干扰包扫描
REMOVE_FEED_PACKAGES() {
	local NAME=$1
	local FOUND_DIRS=$(find ./feeds/luci/ ./feeds/packages/ -maxdepth 4 -type d -iname "*$NAME*" 2>/dev/null)
	if [ -n "$FOUND_DIRS" ]; then
		while read -r DIR; do
			[ -n "$DIR" ] && rm -rf "$DIR" && echo "deleted feed package: $DIR"
		done <<< "$FOUND_DIRS"
	fi
	if [ -d "./package/feeds" ]; then
		find ./package/feeds/ -maxdepth 3 -type l -iname "*$NAME*" -exec rm -f {} \; 2>/dev/null
	fi
}

# 通用克隆：删除同名包 -> 克隆仓库 -> 可选提取子包目录
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)
	local REPO_NAME=${PKG_REPO#*/}
	local REPO_PATH="./package/$REPO_NAME"

	echo " "

	# 删除 feeds 中可能存在的同名包
	for NAME in "${PKG_LIST[@]}"; do
		REMOVE_FEED_PACKAGES "$NAME"
	done

	# 克隆仓库
	git clone --depth=1 --single-branch --branch "$PKG_BRANCH" "https://github.com/$PKG_REPO.git" "$REPO_PATH" || {
		echo "ERROR: failed to clone $PKG_REPO"
		exit 1
	}

	# 若仓库是"集合仓库"（包在子目录中），提取目标包到 ./package
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find "$REPO_PATH"/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./package \;
		rm -rf "$REPO_PATH"
	fi
}

# 从集合仓库提取多个包目录到 ./package，然后删除仓库目录
EXTRACT_PACKAGES() {
	local SRC_DIR=$1
	shift
	for PKG in "$@"; do
		if [ -d "$SRC_DIR/$PKG" ]; then
			cp -rf "$SRC_DIR/$PKG" ./package/
			echo "extracted package: $PKG"
		else
			echo "WARNING: $SRC_DIR/$PKG not found"
		fi
	done
	rm -rf "$SRC_DIR"
}

#====================================================
# 插件拉取（按用户需求清单）
#====================================================

echo "====================================================="
echo "1. Argon 主题（luci-theme-argon）"
echo "====================================================="
# 来源：用户清单 jerrykuku/luci-theme-argon
# 注：luci-app-argon-config 使用 luci feed 内置版（依赖 luci-theme-argon）
UPDATE_PACKAGE "luci-theme-argon" "jerrykuku/luci-theme-argon" "master"

echo "====================================================="
echo "2. PassWall 科学上网（passwall + passwall2 + 依赖包）"
echo "====================================================="
# 来源：用户清单 Openwrt-Passwall/*（luci feed 内置版较旧，用官方仓库最新版覆盖）
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"

# passwall/passwall2 的二进制依赖包：先从 packages feed 删除同名包，避免包重复定义
REMOVE_FEED_PACKAGES "chinadns-ng"
REMOVE_FEED_PACKAGES "dns2socks"
REMOVE_FEED_PACKAGES "ipt2socks"
REMOVE_FEED_PACKAGES "microsocks"
REMOVE_FEED_PACKAGES "tcping"
REMOVE_FEED_PACKAGES "sing-box"
REMOVE_FEED_PACKAGES "xray-core"
REMOVE_FEED_PACKAGES "v2ray-geodata"

git clone --depth=1 --single-branch --branch "main" "https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git" "./package/openwrt-passwall-packages" || {
	echo "ERROR: failed to clone openwrt-passwall-packages"
	exit 1
}
EXTRACT_PACKAGES "./package/openwrt-passwall-packages" \
	chinadns-ng dns2socks geoview hysteria ipt2socks microsocks naiveproxy \
	shadowsocksr-libev shadowsocks-rust shadow-tls simple-obfs sing-box \
	tcping v2ray-geodata v2ray-plugin xray-core xray-plugin

echo "====================================================="
echo "3. iStore 商店（luci-app-store）"
echo "====================================================="
# 来源：用户清单 linkease/istore
git clone --depth=1 --single-branch --branch "main" "https://github.com/linkease/istore.git" "./package/istore" || {
	echo "ERROR: failed to clone istore"
	exit 1
}
EXTRACT_PACKAGES "./package/istore/luci" luci-app-store luci-lib-taskd luci-lib-xterm taskd
rm -rf "./package/istore"

echo "====================================================="
echo "4. 易有云文件管理器（luci-app-linkease）"
echo "====================================================="
# 来源：用户清单 linkease/luci-app-linkease
UPDATE_PACKAGE "linkease" "linkease/luci-app-linkease" "master"

echo "====================================================="
echo "5. 微信推送（luci-app-wechatpush，原 luci-app-serverchan）"
echo "====================================================="
# 来源：用户清单 tty228/luci-app-serverchan
UPDATE_PACKAGE "wechatpush" "tty228/luci-app-serverchan" "master"

echo "====================================================="
echo "6. 全能推送（luci-app-pushbot）"
echo "====================================================="
# 来源：自找 zzsj0928/luci-app-pushbot（用户清单无此仓库）
UPDATE_PACKAGE "pushbot" "zzsj0928/luci-app-pushbot" "master"

echo "====================================================="
echo "7. alist 文件列表（luci-app-alist 前端）"
echo "====================================================="
# 来源：用户清单 sbwml/luci-app-alist（仅取前端；后端 alist 使用 packages feed 内置 net/alist）
git clone --depth=1 --single-branch --branch "main" "https://github.com/sbwml/luci-app-alist.git" "./package/luci-app-alist-src" || {
	echo "ERROR: failed to clone luci-app-alist"
	exit 1
}
EXTRACT_PACKAGES "./package/luci-app-alist-src" luci-app-alist

echo "====================================================="
echo "8. Docker 中文前端（lisaac 维护的 luci-app-dockerman）"
echo "====================================================="
# 来源：lisaac/luci-app-docker（dockerman 原作者维护，中文界面）
# 先删 feed 里的旧版 dockerman，再用 lisaac 新版替换
# dockerman 依赖 luci-lib-docker，必须一起拉
REMOVE_FEED_PACKAGES "luci-app-dockerman"
REMOVE_FEED_PACKAGES "luci-lib-docker"
# lisaac/luci-lib-docker 仓库结构是 collections/luci-lib-docker/Makefile，需提取
git clone --depth=1 --single-branch --branch "master" "https://github.com/lisaac/luci-lib-docker.git" "./package/luci-lib-docker-src" || {
	echo "ERROR: failed to clone lisaac/luci-lib-docker"
	exit 1
}
cp -rf "./package/luci-lib-docker-src/collections/luci-lib-docker" ./package/
rm -rf "./package/luci-lib-docker-src"
git clone --depth=1 --single-branch --branch "master" "https://github.com/lisaac/luci-app-docker.git" "./package/luci-app-docker-src" || {
	echo "ERROR: failed to clone lisaac/luci-app-docker"
	exit 1
}
cp -rf "./package/luci-app-docker-src/applications/luci-app-dockerman" ./package/
rm -rf "./package/luci-app-docker-src"
echo "extracted package: luci-app-dockerman + luci-lib-docker (lisaac Chinese fork)"

echo "====================================================="
echo "9. IP 限速（luci-app-eqosplus，替代 feed 内置 luci-app-eqos）"
echo "====================================================="
# 来源：用户清单 sirpdboy/luci-app-eqosplus
# luci feed 内置 luci-app-eqos 依赖高通 NSS 内核模块，x86 编译必失败，先删除
REMOVE_FEED_PACKAGES "luci-app-eqos"
UPDATE_PACKAGE "eqosplus" "sirpdboy/luci-app-eqosplus" "main"

#====================================================
# 以下插件由 luci feed / packages feed 内置，无需外克隆（已在 Config/GENERAL.txt 启用）：
#   luci-app-uhttpd / luci-app-mwan3 / luci-app-ttyd / luci-app-commands / luci-app-samba4
#   luci-app-statistics / docker(+dockerd/docker-compose) / luci-app-upnp
#   luci-app-autoreboot / luci-app-openlist / luci-app-lucky / luci-app-ddns-go / luci-app-diskman
#   luci-app-turboacc(+BBR) / luci-app-argon-config / luci-i18n-base-zh-cn
#====================================================

#====================================================
# 可选：私有扩展包（PRIVATE.txt 存在时启用）
#====================================================
if [ -e "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh" ]; then
	echo "====================================================="
	echo "10. 执行私有扩展脚本 PRIVATE.sh"
	echo "====================================================="
	source "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh"
fi
