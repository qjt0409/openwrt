# OpenWRT-CI（LEDE x86_64 云编译）

本项目改造自 [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI)（MIT License），
使用 **Lean 大（coolsnowwolf）LEDE 源码**在 GitHub Actions 上云编译 **x86_64** 固件，
适配 **J1900 / J1800** 等 64 位 x86 软路由。

> 关于版本：LEDE 源码仓库只有 `master` 分支，无 `24.10.3` 分支。当前 master 对应的
> OpenWrt 版本为 **24.10.5**，内核 **6.18**（含最新 BBR）。如果你确实需要 24.10.3，
> 需改用 OpenWrt 官方源码的 `openwrt-24.10` 分支并自行 `git checkout` 到对应 tag，本配置不适用。

---

## 一、固件信息

| 项目 | 值 |
|---|---|
| 源码 | [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)（master = OpenWrt 24.10.5，内核 6.18） |
| 平台 | x86_64（兼容 J1900 / J1800 / 其他 64 位 x86） |
| 登录地址 | **http://10.0.1.1** |
| 用户名 | root |
| 密码 | **首次登录自行设置**（已移除 LEDE 默认密码 "password"，首次进 LuCI 会提示设置） |
| 镜像格式 | combined（BIOS 引导）、combined-efi（UEFI 引导）、vmdk（虚拟机），均为 gzip 压缩 |
| 无线 | 无（x86 软路由不涉及） |

## 二、已集成插件清单

| 需求 | 插件 | 来源 |
|---|---|---|
| 科学上网 | PassWall | Openwrt-Passwall/openwrt-passwall（用户清单） |
| 科学上网 | PassWall 2 | Openwrt-Passwall/openwrt-passwall2（用户清单） |
| 易有云文件管理器 | luci-app-linkease | linkease/luci-app-linkease（用户清单） |
| iStore 商店 | luci-app-store | linkease/istore（用户清单） |
| 全能推送 | luci-app-pushbot | zzsj0928/luci-app-pushbot（自找，用户清单无此仓库） |
| 微信推送 | luci-app-wechatpush（原 serverchan） | tty228/luci-app-serverchan（用户清单） |
| DDNS | ddns-go（luci-app-ddns-go） | luci feed 内置前端 + packages feed 后端 |
| 网络工具 | lucky（luci-app-lucky） | luci feed 内置前端 + packages feed 后端 |
| OAF 行为管理 | luci-app-oaf + appfilter + kmod-oaf | destan19/OpenAppFilter（用户清单） |
| Web 服务 | luci-app-uhttpd | luci feed 内置（官方） |
| 负载均衡 | luci-app-mwan3 | luci feed 内置前端 + packages feed 后端 |
| TTYD 终端 | luci-app-ttyd | luci feed 内置前端 + packages feed 后端 |
| 磁盘管理 | luci-app-diskman | luci feed 内置 |
| 主题 | luci-theme-argon | jerrykuku/luci-theme-argon（用户清单） |
| 主题设置 | luci-app-argon-config | luci feed 内置（依赖 argon 主题） |
| 自定义命令 | luci-app-commands | luci feed 内置 |
| Docker | luci-app-dockerman + docker + dockerd + docker-compose | luci feed + packages feed 内置 |
| 网络共享 | luci-app-samba4 | luci feed 内置前端 + packages feed 后端 |
| alist 文件列表 | luci-app-alist | sbwml/luci-app-alist 前端（用户清单）+ packages feed 后端 |
| openlist | luci-app-openlist | luci feed 内置前端 + packages feed 后端 |
| 流量统计 | luci-app-statistics | luci feed 内置前端 + packages feed 后端 |
| 网络加速 | TurboACC（Flow Offloading + BBR） | luci feed 内置（BBR 用内核 6.18 自带最新版，首次启动自动启用） |
| IP 限速 | luci-app-eqosplus | sirpdboy/luci-app-eqosplus（用户清单） |
| 1Panel | 无官方 luci 插件，以 Docker 容器部署 | 内置 `install-1panel` 脚本（见下） |

> 说明：luci feed 内置的 `luci-app-eqos`（IP 限速旧版）依赖高通 NSS 内核模块，x86 编译必失败，
> 已删除并用 `luci-app-eqosplus` 替代；`luci-app-openclash`、`homeproxy` 等也在 luci feed 中
> 可用，如需要可在 `Config/GENERAL.txt` 中自行加一行 `CONFIG_PACKAGE_luci-app-openclash=y`。

## 三、1Panel 部署说明

1Panel 官方没有 OpenWrt 专用 luci 插件（GitHub 全站检索 `luci-app-1panel` 无结果），
因此以 **Docker 容器**方式满足：固件已内置 Docker，登录路由器后 SSH 执行：

```bash
install-1panel
```

脚本默认参数：端口 `10086`、账号 `admin`、密码 `ChangeMe_123456`（登录后请立即修改）、
安全入口 `panelEntrance`、数据目录 `/opt`。可用环境变量覆盖：
`PANEL_PORT / PANEL_USERNAME / PANEL_PASSWORD / PANEL_ENTRANCE / PANEL_BASE_DIR / PANEL_IMAGE`。
启动后访问：`http://10.0.1.1:10086/panelEntrance`。

## 四、使用方法（GitHub 云编译）

1. **Fork 本仓库**到你的 GitHub 账号。
2. 进入仓库 **Actions** 页面，首次需点击 **"I understand my workflows, go ahead and enable them"** 启用。
3. 手动运行 **OWRT-ALL**（`Run workflow` → 绿色按钮；可选勾选 `TEST` 只验证配置不编译）。
   也可以什么都不做：每天 05:21（北京时间）会自动清理旧 Release 并触发编译。
4. 编译完成后，在仓库 **Releases** 页面下载固件：
   - `openwrt-x86-64-generic-...-combined.img.gz` —— 传统 BIOS（Legacy）引导
   - `openwrt-x86-64-generic-...-combined-efi.img.gz` —— UEFI 引导（J1900/J1800 多数主板推荐）
   - `openwrt-x86-64-generic-...-vmdk` 等 —— 虚拟机磁盘
5. 刷机：用 [balenaEtcher](https://etcher.balena.io/) 或 `dd` 写入 U 盘 / 硬盘 / 电子盘，设 BIOS 从对应介质启动。

> 提示：Release 附件中的 `Config-*.txt` 是该次编译的实际 `.config`，可下载留档。

## 五、自定义

- **改管理 IP / 主机名 / 主题**：编辑 `.github/workflows/OWRT-ALL.yml` 中
  `WRT_IP`（默认 `10.0.1.1`）、`WRT_NAME`（默认 `LEDE`）、`WRT_THEME`（默认 `argon`）。
- **加/减插件**：编辑 `Config/GENERAL.txt`，按 `CONFIG_PACKAGE_xxx=y` 格式增删行。
- **手动微调单次编译**：运行 OWRT-ALL 时在 `PACKAGE` 输入框填入如
  `CONFIG_PACKAGE_luci-app-openclash=y`（多行用换行分隔）。
- **加私有仓库/脚本**：放 `Scripts/PRIVATE.sh` 与 `Config/PRIVATE.txt`，会自动执行/追加。
- **加自定义文件**：放入 `files/` 目录（如 `files/etc/config/xxx`），会原样打包进固件。

## 六、文件结构

```
.github/workflows/
├── Auto-Clean.yml      # 每日清理旧 Release 与工作流，并触发 OWRT-ALL
├── Cache-Clean.yml     # 每周清理过期编译缓存
├── OWRT-ALL.yml        # 主入口：LEDE x86_64 云编译
├── WRT-CORE.yml        # 编译核心（克隆源码 → feeds → 插件 → 配置 → 编译 → 发布）
└── WRT-TEST.yml        # 配置预览（只验证 .config，不编译）
Config/
├── X86.txt             # 目标平台与镜像格式（x86_64，BIOS+UEFI+vmdk）
├── GENERAL.txt         # 插件与内核模块清单
└── TEST.txt            # 干跑用目标配置
Scripts/
├── Packages.sh         # 拉取外部插件并处理与 feeds 的重名冲突
├── Handles.sh          # LEDE 源码微调（移除默认密码、argon 配色、rust 修复）
└── Settings.sh         # 应用 WRT_IP/主题/主机名等编译参数
files/
└── etc/uci-defaults/zzz-turboacc-bbr   # 首次启动自动启用 BBR
└── usr/bin/install-1panel              # 1Panel 容器一键安装脚本
```

## 七、注意事项与排障

- **OAF 内核模块**：`kmod-oaf` 需要随内核 6.18 编译，上游 destan19/OpenAppFilter 持续适配中；
  若编译报错（一般是 oaf.ko 编译失败），临时做法：删除 `Config/GENERAL.txt` 中
  `CONFIG_PACKAGE_luci-app-oaf=y` 一行重跑，其余功能不受影响。
- **helloworld 源已禁用**：LEDE 自带 feeds 中的 helloworld（ssr-plus 全家桶）与
  passwall-packages 存在约 8 个同名包，会触发包重复定义错误；已从 `feeds.conf.default` 移除该行。
- **alist 与 openlist**：两者可同时启用、互不冲突。luci-app-openlist（luci feed 内置）通过
  `PKG_PROVIDES:=luci-app-alist` 声明了 luci-app-alist 虚拟包，仅用于满足依赖查找；
  本配置同时启用 sbwml 官方 luci-app-alist（独立前端）与 openlist 前端，LuCI 菜单各占一项。
- **缓存**：编译缓存按 `源码-分支-平台-commit` 存储，第二次编译会显著加速；Actions 中
  Cache-Clean 每周清理一次。
- **磁盘空间**：完整编译约需 20~30 GB 临时空间与 3~5 小时（视 GitHub Runner 负载），
  首次编译较慢属正常现象。
