#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt
# Function: Diy script (Before Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/immortalwrt/immortalwrt / Branch: master
#========================================================================================================================

# ========== 核心修改：添加 PassWall/SSR 插件源（必须） ==========
# 添加 PassWall 依赖源
sed -i '$a src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main' feeds.conf.default
sed -i '$a src-git passwall2 https://github.com/xiaorouji/openwrt-passwall2.git;main' feeds.conf.default
# 添加 SSR-Plus 源（兼容 PassWall）
sed -i '$a src-git helloworld https://github.com/fw876/helloworld.git;master' feeds.conf.default

# ========== 可选优化：适配 UFI003 基础配置 ==========
# 修改默认IP（可选，改成你习惯的，比如 192.168.6.1）
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 修改主机名（可选，改成 UFI003）
sed -i 's/OpenWrt/UFI003/g' package/base-files/files/bin/config_generate

# 移除冗余插件（减少固件体积，适配 UFI003 小存储）
rm -rf package/emortal/{autosamba,ipv6-helper}

# ========== 保留原有注释（方便你后续修改） ==========
# Add a feed source
# sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default

# other
# rm -rf package/emortal/{autosamba,ipv6-helper}
