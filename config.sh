#!/bin/bash

# ========================================================
# OpenWrt 自定义配置脚本 for Mobipromo CM520-79F
# 适配 opboot + NAND Flash 启动
# 2025年8月1日 - Qwen 修正版（严谨一致）
# ========================================================

# === 源码配置 ===
REPO_URL="https://github.com/coolsnowwolf/lede"
REPO_BRANCH="master"

# === 编译配置 ===
CONFIG_FILE="config.cm520"
IMG_SUFFIX="openwrt-cm520-79f-opboot"
LAN_IP="192.168.10.1"
TZ="Asia/Shanghai"
ENABLE_IPV6=1
ENABLE_USB=1

# === DTS 补丁函数（适配 opboot + NAND Flash）===
PATCH_DTS() {
    local dts_path="target/linux/ipq40xx/files/arch/arm/boot/dts/qcom-ipq4019-cm520-79f.dts"

    # 检查 DTS 文件是否存在
    if [ ! -f "$dts_path" ]; then
        echo "⚠️ DTS 文件未找到: $dts_path"
        echo "💡 提示：请确认源码分支是否包含该设备支持"
        return 1
    fi

    # 备份原始文件（可选）
    cp "$dts_path" "$dts_path.bak" && echo "✅ 已备份原始 DTS 到 ${dts_path}.bak"

    # 应用 opboot 兼容补丁
    cat >> "$dts_path" << 'EOF'

/* ========== opboot 启动适配补丁 ========== */

/* 1. 添加 bootargs-append：指定 UBI 块作为根文件系统 */
&chosen {
    bootargs-append = " ubi.block=0,1 root=/dev/ubiblock0_1";
};

/* 2. 配置 NAND 分区表（适配 opboot 要求） */
&nand {
    pinctrl-0 = <&nand_pins>;
    pinctrl-names = "default";
    status = "okay";

    nand@0 {
        partitions {
            compatible = "fixed-partitions";
            #address-cells = <1>;
            #size-cells = <1>;

            partition@0 {
                label = "Bootloader";
                reg = <0x0 0xb00000>;  /* 11.25MB */
                read-only;
            };

            art: partition@b00000 {
                label = "ART";
                reg = <0xb00000 0x80000>;  /* 0.5MB */
                read-only;
            };

            partition@b80000 {
                label = "rootfs";
                reg = <0xb80000 0x7480000>;  /* ~114.5MB */
            };
        };
    };
};

EOF

    # 确保以换行结束
    echo "" >> "$dts_path"

    echo "✅ DTS 补丁已成功应用到 $dts_path"
    echo "💡 提示：已适配 opboot + NAND Flash 启动"
    return 0
}

# ✅ 不再自动执行函数
# 删除或注释掉以下代码：
# if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
#     PATCH_DTS
# fi
