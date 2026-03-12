# 修改默认IP & 固件名称 & 编译署名和时间
sed -i 's/192.168.1.1/192.168.2.254/g' package/base-files/files/bin/config_generate
sed -i "s/hostname='.*'/hostname='RedmiAX6S'/g" package/base-files/files/bin/config_generate
sed -i "s#_('Firmware Version'), (L\.isObject(boardinfo\.release) ? boardinfo\.release\.description + ' / ' : '') + (luciversion || ''),# \
            _('Firmware Version'),\n \
            E('span', {}, [\n \
                (L.isObject(boardinfo.release)\n \
                ? boardinfo.release.description + ' / '\n \
                : '') + (luciversion || '') + ' / ',\n \
            E('a', {\n \
                href: 'https://github.com/dolphin738/openwrt-ci-roc/releases',\n \
                target: '_blank',\n \
                rel: 'noopener noreferrer'\n \
                }, [ 'Built by dolphin738 $(date "+%Y-%m-%d %H:%M:%S")' ])\n \
            ]),#" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
            
# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 更改默认 Shell 为 zsh
sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# 调整NSS驱动q6_region内存区域预留大小（ipq6018.dtsi默认预留85MB，ipq6018-512m.dtsi默认预留55MB，带WiFi必须至少预留54MB，以下分别是改成预留16MB、32MB、64MB和96MB）
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x01000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x02000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x04000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x06000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi

# 调节IPQ60XX的1.5GHz频率电压(从0.9375V提高到0.95V，过低可能导致不稳定，过高可能增加功耗和发热，具体数值需要根据实际情况调整)
#sed -i 's/opp-microvolt = <937500>;/opp-microvolt = <950000>;/' target/linux/qualcommax/patches-6.12/0038-v6.16-arm64-dts-qcom-ipq6018-add-1.5GHz-CPU-Frequency.patch

# 移除要替换的包
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf package/feeds/packages/onionshare-cli
#rm -rf feeds/luci/applications/luci-app-wechatpush #通知插件
#rm -rf feeds/luci/applications/luci-app-appfilter #家长控制插件
#rm -rf feeds/luci/applications/luci-app-frpc
#rm -rf feeds/luci/applications/luci-app-frps
#rm -rf feeds/packages/net/open-app-filter #家长控制插件
#rm -rf feeds/packages/net/ariang
#rm -rf feeds/packages/net/frp
#rm -rf feeds/packages/lang/golang

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# # 添加额外插件
git_sparse_clone main https://github.com/kiddin9/op-packages luci-app-adguardhome
git_sparse_clone main https://github.com/kiddin9/op-packages luci-app-wrtbwmon  wrtbwmon
git_sparse_clone main https://github.com/kiddin9/op-packages luci-app-netspeedtest
git_sparse_clone main https://github.com/kiddin9/op-packages homebox
git_sparse_clone main https://github.com/kiddin9/op-packages ookla-speedtest
git_sparse_clone main https://github.com/kiddin9/op-packages luci-app-turboacc
git_sparse_clone package https://github.com/chenmozhijin/turboacc  shortcut-fe/fast-classifier shortcut-fe/shortcut-fe
git_sparse_clone main https://github.com/kiddin9/op-packages luci-app-easytier easytier
git_sparse_clone main https://github.com/kiddin9/op-packages luci-app-taskplan
git_sparse_clone main https://github.com/kiddin9/op-packages luci-app-timedreboot

# 安装主题
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon feeds/luci/themes/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config feeds/luci/applications/luci-app-argon-config
git clone --depth=1 https://github.com/eamonxg/luci-theme-aurora feeds/luci/themes/luci-theme-aurora
git clone --depth=1 https://github.com/eamonxg/luci-app-aurora-config feeds/luci/applications/luci-app-aurora-config

### PassWall & OpenClash ###

# 移除 OpenWrt Feeds 自带的核心库 移除 OpenWrt Feeds 过时的LuCI版本
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf feeds/luci/applications/luci-app-passwall
#rm -rf feeds/luci/applications/luci-app-openclash


# 安装passwall
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages
git_sparse_clone main https://github.com/Openwrt-Passwall/openwrt-passwall luci-app-passwall
#git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall2 package/luci-app-passwall2
#git clone --depth=1 https://github.com/vernesong/OpenClash package/luci-app-openclash

# 清理 PassWall 的 chnlist 规则文件
echo "baidu.com"  > package/luci-app-passwall/luci-app-passwall/root/usr/share/passwall/rules/chnlist

./scripts/feeds update -a
./scripts/feeds install -a
