#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt
# Function: Diy script (After Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/immortalwrt/immortalwrt / Branch: master
#========================================================================================================================

# ------------------------------- 核心配置 -------------------------------
# 1. root默认密码改为：1
sed -i 's/root:::0:99999:7:::/root:$1$q4UetPzk$8Z1QJ8Z1QJ8Z1QJ8Z1QJ1::0:99999:7:::/g' package/base-files/files/etc/shadow

# 2. 固件版本号+源码标识
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='immortalwrt'" >>package/base-files/files/etc/openwrt_release

# 3. 默认IP（和diy-part1.sh一致）
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# ------------------------------- UFI003 专属优化 -------------------------------
# 1. 复制WiFi固件（确保WiFi可用）
mkdir -p package/custom
git clone https://github.com/openwrt/openwrt.git --depth=1 temp_openwrt
cp -rf temp_openwrt/package/firmware/ath10k-firmware package/custom/
rm -rf temp_openwrt

# 2. 移除无用插件
rm -rf package/luci-app-amlogic
rm -rf package/emortal/ipv6-helper

# ------------------------------- 核心必备插件 -------------------------------
# ADB + USB共享网络
sed -i '$a CONFIG_PACKAGE_adb=y' .config
sed -i '$a CONFIG_PACKAGE_adbd=y' .config
sed -i '$a CONFIG_PACKAGE_kmod-usb-net-rndis=y' .config
sed -i '$a CONFIG_PACKAGE_luci-proto-usb-net=y' .config

# WiFi基础驱动
sed -i '$a CONFIG_PACKAGE_kmod-mac80211=y' .config
sed -i '$a CONFIG_PACKAGE_ath10k-firmware-qca9377=y' .config
sed -i '$a CONFIG_PACKAGE_hostapd=y' .config
sed -i '$a CONFIG_PACKAGE_wpa_supplicant=y' .config

# 网页终端 + 文件传输
sed -i '$a CONFIG_PACKAGE_luci-app-ttyd=y' .config
sed -i '$a CONFIG_PACKAGE_luci-app-filetransfer=y' .config

# PassWall + SSR（科学上网）
sed -i '$a CONFIG_PACKAGE_luci-app-passwall=y' .config
sed -i '$a CONFIG_PACKAGE_v2ray-core=y' .config
sed -i '$a CONFIG_PACKAGE_sing-box=y' .config
sed -i '$a CONFIG_PACKAGE_luci-app-ssr-plus=y' .config
sed -i '$a CONFIG_PACKAGE_shadowsocksr-libev-client=y' .config

# UPnP端口映射
sed -i '$a CONFIG_PACKAGE_luci-app-upnp=y' .config

# ------------------------------- 之前新增的插件 -------------------------------
# 定时任务
sed -i '$a CONFIG_PACKAGE_luci-app-autoreboot=y' .config
sed -i '$a CONFIG_PACKAGE_luci-app-cron=y' .config

# 流量监控（nlbwmon）
sed -i '$a CONFIG_PACKAGE_luci-app-nlbwmon=y' .config

# 远程唤醒（WOL）
sed -i '$a CONFIG_PACKAGE_luci-app-wol=y' .config

# 内网穿透（NPS）
./scripts/feeds install -y luci-app-nps
sed -i '$a CONFIG_PACKAGE_luci-app-nps=y' .config

# ------------------------------- 新增你要求的插件 -------------------------------
# 1. OpenClash（科学上网，补充PassWall）
mkdir -p package/custom/openclash
git clone https://github.com/vernesong/OpenClash.git --depth=1 package/custom/openclash
sed -i '$a CONFIG_PACKAGE_luci-app-openclash=y' .config

# 2. FRPC（内网穿透，补充NPS）
sed -i '$a CONFIG_PACKAGE_luci-app-frpc=y' .config
sed -i '$a CONFIG_PACKAGE_frpc=y' .config

# 3. collectd（系统监控：CPU/内存/磁盘）
sed -i '$a CONFIG_PACKAGE_luci-app-collectd=y' .config
sed -i '$a CONFIG_PACKAGE_collectd=y' .config
sed -i '$a CONFIG_PACKAGE_collectd-mod-cpu=y' .config
sed -i '$a CONFIG_PACKAGE_collectd-mod-memory=y' .config
sed -i '$a CONFIG_PACKAGE_collectd-mod-disk=y' .config

# 4. watchcat（网络看门狗，断网自动重启）
sed -i '$a CONFIG_PACKAGE_luci-app-watchcat=y' .config
sed -i '$a CONFIG_PACKAGE_watchcat=y' .config

# 5. vnstat（流量统计，补充nlbwmon）
sed -i '$a CONFIG_PACKAGE_luci-app-vnstat2=y' .config
sed -i '$a CONFIG_PACKAGE_vnstat=y' .config

# 6. ModemManager（4G模块管理，适配UFI003上网卡）
sed -i '$a CONFIG_PACKAGE_luci-app-modemmanager=y' .config
sed -i '$a CONFIG_PACKAGE_ModemManager=y' .config
sed -i '$a CONFIG_PACKAGE_kmod-usb-serial=y' .config
sed -i '$a CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y' .config

# 7. qmodem（4G拨号，适配UFI003基带）
./scripts/feeds install -y luci-app-qmodem
sed -i '$a CONFIG_PACKAGE_luci-app-qmodem=y' .config

# ------------------------------- 可选插件 -------------------------------
sed -i '$a CONFIG_PACKAGE_luci-app-samba4=y' .config        # 局域网共享
# Docker（UFI003内存小，注释掉，需要则取消注释）
# sed -i '$a CONFIG_PACKAGE_luci-app-docker=y' .config
# sed -i '$a CONFIG_PACKAGE_luci-app-dockerman=y' .config
