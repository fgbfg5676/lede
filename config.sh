#!/bin/bash

# 定义函数：PATCH_DTS
PATCH_DTS() {
    local dts_file="target/linux/ipq40xx/files/arch/arm/boot/dts/qcom-ipq4019-cm520-79f.dts"

    # 检查文件是否存在
    if [ ! -f "$dts_file" ]; then
        echo "❌ 错误：DTS 文件未找到：$dts_file"
        echo "💡 提示：请确认源码已正确 checkout"
        exit 1
    fi

    # 应用补丁
    cat >> "$dts_file" << 'EOF'

/* ========== opboot + NAND 启动支持 ========== */
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

    echo "✅ DTS 补丁已成功应用到 $dts_file"
}

# ✅ 注意：不要在这里调用 PATCH_DTS
# ✅ 不要写：if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then PATCH_DTS; fi
