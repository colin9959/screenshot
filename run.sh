#!/bin/bash

# 检测系统架构
ARCH=$(uname -m)

# 提示当前检测到的架构
echo "检测到系统架构：$ARCH"

# 根据架构执行对应脚本
case $ARCH in
    arm*|aarch64*)
        echo "正在执行 ARM 架构专用脚本..."
        curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/arm/bash-ss.sh | tr -d '\r' | bash
        ;;
    x86_64|i386|i686*)
        echo "正在执行 X86 架构专用脚本..."
        curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/bash-ss.sh | tr -d '\r' | bash
        ;;
    *)
        echo "不支持的系统架构：$ARCH"
        exit 1
        ;;
esac
