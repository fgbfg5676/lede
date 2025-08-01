#!/bin/bash

# ======================== 源码配置 ========================
# 推荐使用 coolsnowwolf/lede（稳定）
REPO_URL="https://github.com/coolsnowwolf/lede"
REPO_BRANCH="master"

# 可选：使用官方 OpenWrt 主线（功能新，但可能不稳定）
# REPO_URL="https://git.openwrt.org/openwrt/openwrt.git"
# REPO_BRANCH="master"


# ======================== 编译配置 ========================
# 使用 config.cm520 作为配置源
CONFIG_FILE="config.cm520"

# 固件输出文件名前缀
IMG_SUFFIX="openwrt-cm520-79f-opboot"

# 自定义 LAN IP（防止与 opboot 冲突）
LAN_IP="192.168.10.1"

# 时区设置
TZ="Asia/Shanghai"

# 是否启用 IPv6 支持
ENABLE_IPV6=1

# 是否启用 USB 支持（自动添加必要驱动）
ENABLE_USB=1

# 额外软件包（可选）
EXTRA_PACKAGES="luci-app-ttyd htop nano"


# ======================== DTS 修补（关键：opboot 兼容）========================
# 启用 DTS 补丁
CUSTOMIZE_DTS=1

# DTS 文件名（必须与源码中一致）
DTS_FILE="qcom-ipq4019-mobipromo-cm520-79f.dts"

# 自定义 DTS 补丁函数
PATCH_DTS() {
    local dts_path="target/linux/ipq40xx/dts/$DTS_FILE"
    
    # 检查文件是否存在
    if [ ! -f "$dts_path" ]; then
        echo "⚠️ DTS 文件未找到: $dts_path"
        return 1
    fi

    # 添加 opboot 兼容补丁
    cat >> "$dts_path" << 'EOF'

/* opboot 启动参数补丁 */
&chosen {
    bootargs = "console=ttyMSM0,115200n8 root=/dev/mtdblock5 rootfstype=squashfs,jffs2";
};

/* SPI Flash 分区表（32MB NOR Flash 示例） */
&spi {
    status = "okay";
    max-frequency = <25000000>;
};

&spi_flash {
    partitions {
        compatible = "fixed-partitions";
        #address-cells = <1>;
        #size-cells = <1>;

        partition@0 {
            label = "u-boot";
            reg = <0x000000 0x60000>;
            read-only;
        };

        partition@60000 {
            label = "u-boot-env";
            reg = <0x60000 0x20000>;
            read-only;
        };

        partition@80000 {
            label = "factory";
            reg = <0x80000 0x20000>;
            read-only;
        };

        partition@a0000 {
            label = "firmware";
            reg = <0xa0000 0x7f60000>;  /* ~126.375MB */
        };
    };
};
EOF

    echo "✅ DTS 补丁已应用到 $dts_path"
}
