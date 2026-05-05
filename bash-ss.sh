#!/bin/bash
set -e  # 脚本出错自动停止，更安全

echo "========================================"
echo "      开始执行批量安装与配置脚本"
echo "========================================"

# 1. 更新并安装所有依赖软件包
echo -e "\n[1/5] 更新系统并安装依赖包..."
sudo apt update -y && sudo apt install -y \
jq \
python3 \
python3-pip \
python3-dev \
build-essential \
libssl-dev \
libffi-dev \
ffmpeg \
libmediainfo0v5 \
mediainfo \
curl \
mono-complete

# 2. 创建ISO挂载目录
echo -e "\n[2/5] 创建ISO挂载目录 /mnt/iso..."
sudo mkdir -p /mnt/iso

# 3. 下载脚本和工具文件
echo -e "\n[3/5] 下载 ss.sh 和 nconvert 文件..."
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/ss.sh -o /usr/local/bin/ss.sh
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/nconvert -o /usr/local/bin/nconvert

# 4. 已在上一步直接下载到 /usr/local/bin 目录

# 5. 赋予执行权限
echo -e "\n[4/5] 赋予文件执行权限..."
sudo chmod +x /usr/local/bin/ss.sh
sudo chmod +x /usr/local/bin/nconvert

echo -e "\n========================================"
echo "           所有操作执行完成！"
echo " ss.sh 和 nconvert 已全局可用，直接输入命令即可运行"
echo "========================================"