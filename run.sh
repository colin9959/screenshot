#!/bin/bash

# 检测系统架构
ARCH=$(uname -m)

# 定义不同架构对应的远程脚本URL
ARM_SCRIPT_URL="https://github.com/colin9959/screenshot/blob/main/arm/bash-ss.sh"
X86_SCRIPT_URL="https://github.com/colin9959/screenshot/blob/main/bash-ss.sh"

# 注意：GitHub的blob页面不是直接可执行的脚本，需要替换为raw地址才能直接下载执行
# 修正后的RAW地址（关键！否则下载的是HTML页面而非脚本）
ARM_SCRIPT_RAW_URL="https://raw.githubusercontent.com/colin9959/screenshot/main/arm/bash-ss.sh"
X86_SCRIPT_RAW_URL="https://raw.githubusercontent.com/colin9959/screenshot/main/bash-ss.sh"

# 提示当前检测到的架构
echo "检测到系统架构：$ARCH"

# 根据架构执行对应脚本
case $ARCH in
    arm*|aarch64*)
        echo "正在执行ARM架构脚本..."
        # 下载并执行ARM脚本（使用bash执行，确保权限）
        if curl -sSL "$ARM_SCRIPT_RAW_URL" | bash; then
            echo "ARM脚本执行完成"
        else
            echo "ARM脚本执行失败"
            exit 1
        fi
        ;;
    x86_64*|i386*|i686*)
        echo "正在执行X86架构脚本..."
        # 下载并执行X86脚本
        if curl -sSL "$X86_SCRIPT_RAW_URL" | bash; then
            echo "X86脚本执行完成"
        else
            echo "X86脚本执行失败"
            exit 1
        fi
        ;;
    *)
        echo "不支持的系统架构：$ARCH"
        exit 1
        ;;
esac
