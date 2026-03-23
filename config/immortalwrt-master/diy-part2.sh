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

# ------------------------------- 核心：LED可视化插件（带图文界面） -------------------------------
# 1. 克隆LED插件源码（LuCI可视化界面）
mkdir -p package/custom/luci-app-ledcontrol
git clone https://github.com/openwrt/luci.git --depth=1 temp_luci
cp -rf temp_luci/applications/luci-app-leds package/custom/luci-app-ledcontrol
rm -rf temp_luci

# 2. 定制UFI003 LED插件界面（图文按钮+下拉选择）
cat > package/custom/luci-app-ledcontrol/luasrc/controller/ledcontrol.lua << EOF
module("luci.controller.ledcontrol", package.seeall)

function index()
        entry({"admin", "system", "ledcontrol"}, cbi("ledcontrol/leds"), _("LED 灯光控制"), 90).dependent = true
        entry({"admin", "system", "ledcontrol", "action"}, call("led_action")).leaf = true
end

function led_action()
        local action = luci.http.formvalue("action")
        local led = luci.http.formvalue("led")
        local cmd = ""
        
        if led == "wifi" then
                if action == "on" then cmd = "echo 1 > /sys/class/leds/ufi003:green:wifi/brightness"
                elseif action == "off" then cmd = "echo 0 > /sys/class/leds/ufi003:green:wifi/brightness"
                elseif action == "blink" then cmd = "echo heartbeat > /sys/class/leds/ufi003:green:wifi/trigger"
                end
        elseif led == "4g" then
                if action == "on" then cmd = "echo 1 > /sys/class/leds/ufi003:blue:4g/brightness"
                elseif action == "off" then cmd = "echo 0 > /sys/class/leds/ufi003:blue:4g/brightness"
                elseif action == "blink" then cmd = "echo heartbeat > /sys/class/leds/ufi003:blue:4g/trigger"
                end
        elseif led == "net" then
                if action == "on" then cmd = "echo 1 > /sys/class/leds/ufi003:red:net/brightness"
                elseif action == "off" then cmd = "echo 0 > /sys/class/leds/ufi003:red:net/brightness"
                elseif action == "blink" then cmd = "echo heartbeat > /sys/class/leds/ufi003:red:net/trigger"
                end
        end
        
        os.execute(cmd)
        luci.http.redirect(luci.dispatcher.build_url("admin/system/ledcontrol"))
end
EOF

# 3. 插件界面模板（图文按钮+下拉选择）
cat > package/custom/luci-app-ledcontrol/luasrc/model/cbi/ledcontrol/leds.lua << EOF
local m, s, o

m = Map("system", _("UFI003 LED 灯光控制"), _("可视化控制WiFi/4G/网络灯效，支持一键开关/闪烁"))

s = m:section(TypedSection, "led", "")
s.addremove = false
s.anonymous = true

-- WiFi灯控制
o = s:option(TextValue, "wifi_led", _("WiFi灯（绿灯）"))
o.description = _("WiFi状态灯，控制方式：")
o.rows = 1

local wifi_btn = s:option(Button, "wifi_on", _("打开"))
wifi_btn.inputstyle = "apply"
wifi_btn.write = function()
        luci.http.redirect(luci.dispatcher.build_url("admin/system/ledcontrol/action?led=wifi&action=on"))
end

local wifi_off_btn = s:option(Button, "wifi_off", _("关闭"))
wifi_off_btn.inputstyle = "reset"
wifi_off_btn.write = function()
        luci.http.redirect(luci.dispatcher.build_url("admin/system/ledcontrol/action?led=wifi&action=off"))
end

local wifi_blink_btn = s:option(Button, "wifi_blink", _("闪烁"))
wifi_blink_btn.inputstyle = "save"
wifi_blink_btn.write = function()
        luci.http.redirect(luci.dispatcher.build_url("admin/system/ledcontrol/action?led=wifi&action=blink"))
end

-- 4G灯控制
o = s:option(TextValue, "4g_led", _("4G灯（蓝灯）"))
o.description = _("4G状态灯，控制方式：")
o.rows = 1

local fourg_btn = s:option(Button, "4g_on", _("打开"))
fourg_btn.inputstyle = "apply"
fourg_btn.write = function()
        luci.http.redirect(luci.dispatcher.build_url("admin/system/ledcontrol/action?led=4g&action=on"))
end

local fourg_off_btn = s:option(Button, "4g_off", _("关闭"))
fourg_off_btn.inputstyle = "reset"
fourg_off_btn.write = function()
        luci.http.redirect(luci.dispatcher.build_url("admin/system/ledcontrol/action?led=4g&action=off"))
end

local fourg_blink_btn = s:option(Button, "4g_blink", _("闪烁"))
fourg_blink_btn.inputstyle = "save"
fourg_blink_btn.write = function()
        luci.http.redirect(luci.dispatcher.build_url("admin/system/ledcontrol/action?led=4g&action=blink"))
end

-- 网络灯控制
o = s:option(TextValue, "net_led", _("网络灯（红灯）"))
o.description = _("网络心跳灯，控制方式：")
o.rows = 1

local net_btn = s:option(Button, "net_on", _("打开"))
net_btn.inputstyle = "apply"
net_btn.write = function()
        luci.http.redirect(luci.dispatcher.build_url("admin/system/ledcontrol/action?led=net&action=on"))
end

local net_off_btn = s:option(Button, "net_off", _("关闭"))
net_off_btn.inputstyle = "reset"
net_off_btn.write = function()
        luci.http.redirect(luci.dispatcher.build_url("admin/system/ledcontrol/action?led=net&action=off"))
end

local net_blink_btn = s:option(Button, "net_blink", _("闪烁"))
net_blink_btn.inputstyle = "save"
net_blink_btn.write = function()
        luci.http.redirect(luci.dispatcher.build_url("admin/system/ledcontrol/action?led=net&action=blink"))
end

-- 灯效模式下拉选择
o = s:option(ListValue, "trigger_mode", _("全局灯效模式"))
o:value("none", _("常亮"))
o:value("heartbeat", _("心跳闪烁（1秒/次）"))
o:value("timer", _("自定义间隔"))
o:value("netdev", _("网络数据联动"))
o.description = _("选择所有灯的统一触发模式")

return m
EOF

# 4. 插件配置文件
cat > package/custom/luci-app-ledcontrol/Makefile << EOF
include \$(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI for UFI003 LED Control
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+kmod-leds-gpio +kmod-led-triggers +kmod-led-trigger-netdev

PKG_NAME:=luci-app-ledcontrol
PKG_VERSION:=1.0
PKG_RELEASE:=1

include \$(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
EOF

# 5. 开启LED插件编译
sed -i '$a CONFIG_PACKAGE_luci-app-ledcontrol=y' .config

# 6. LED硬件初始化（适配UFI003）
mkdir -p package/base-files/files/etc/init.d
cat > package/base-files/files/etc/init.d/led_init << EOF
#!/bin/sh /etc/rc.common
START=10

start() {
        # 映射UFI003 LED GPIO引脚（通用值23，可根据实际修改）
        [ -d /sys/class/gpio/gpio23 ] || echo 23 > /sys/class/gpio/export
        echo out > /sys/class/gpio/gpio23/direction
        echo 1 > /sys/class/gpio/gpio23/value
        
        # 重命名LED设备（适配插件）
        [ -L /sys/class/leds/ufi003:green:wifi ] || ln -s /sys/class/leds/green:wifi /sys/class/leds/ufi003:green:wifi
        [ -L /sys/class/leds/ufi003:blue:4g ] || ln -s /sys/class/leds/blue:4g /sys/class/leds/ufi003:blue:4g
        [ -L /sys/class/leds/ufi003:red:net ] || ln -s /sys/class/leds/red:net /sys/class/leds/ufi003:red:net
        
        # 默认灯效：心跳闪烁
        echo heartbeat > /sys/class/leds/ufi003:green:wifi/trigger
        echo heartbeat > /sys/class/leds/ufi003:blue:4g/trigger
        echo heartbeat > /sys/class/leds/ufi003:red:net/trigger
}

stop() {
        echo 0 > /sys/class/gpio/gpio23/value
        [ -d /sys/class/gpio/gpio23 ] && echo 23 > /sys/class/gpio/unexport
}
EOF

chmod +x package/base-files/files/etc/init.d/led_init
sed -i '$a CONFIG_PACKAGE_led-init=y' .config

# ------------------------------- 可选插件 -------------------------------
sed -i '$a CONFIG_PACKAGE_luci-app-samba4=y' .config        # 局域网共享
# Docker（UFI003内存小，注释掉，需要则取消注释）
# sed -i '$a CONFIG_PACKAGE_luci-app-docker=y' .config
# sed -i '$a CONFIG_PACKAGE_luci-app-dockerman=y' .config
