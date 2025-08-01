#!/bin/bash

# ========================================================
# OpenWrt 自定义配置脚本 for Mobipromo CM520-79F
# 2025年8月1日 - Qwen
# ========================================================

# === 配置变量 ===
CONFIG_FILE="config.cm520"
LAN_IP="192.168.10.1"
TZ="Asia/Shanghai"

# === 核心函数：应用 DTS 补丁 ===
PATCH_DTS() {
    local dts_path="target/linux/ipq40xx/files/arch/arm/boot/dts/qcom-ipq4019-cm520-79f.dts"

    if [ ! -f "$dts_path" ]; then
        echo "❌ 错误：DTS 文件未找到: $dts_path"
        echo "💡 提示：请确认源码是否已 checkout 并包含该设备"
        return 1
    fi

    # 备份（可选）
    [ ! -f "${dts_path}.bak" ] && cp "$dts_path" "${dts_path}.bak"

    # 追加补丁
    cat >> "$dts_path" << 'EOF'

/* ========== opboot + NAND 启动适配 ========== */
&chosen {
    bootargs-append = " ubi.block=0,1 root=/dev/ubiblock0_1";
};

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
                reg = <0x0 0xb00000>;
                read-only;
            };

            art: partition@b00000 {
                label = "ART";
                reg = <0xb00000 0x80000>;
                read-only;
            };

            partition@b80000 {
                label = "rootfs";
                reg = <0xb80000 0x7480000>;
            };
        };
    };
};
EOF

    echo "✅ DTS 补丁已成功应用到 $dts_path"
    return 0
}

# === 可选：如果直接运行脚本，执行函数 ===
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    PATCH_DTS
fi
