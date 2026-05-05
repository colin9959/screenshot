#!/bin/bash
set -e

echo "========================================"
echo "      开始执行批量安装与配置脚本"
echo "        支持：ss截图 + BDInfo蓝光检测"
echo "========================================"

echo -e "\n[1/7] 安装解压工具 unzip..."
sudo apt update -y && sudo apt install -y unzip

echo -e "\n[2/7] 更新系统并安装依赖包..."
sudo apt install -y \
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

echo -e "\n[3/7] 创建ISO挂载目录 /mnt/iso..."
sudo mkdir -p /mnt/iso

echo -e "\n[4/7] 下载 ss.sh 和 nconvert..."
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/ss.sh -o /usr/local/bin/ss.sh
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/nconvert -o /usr/local/bin/nconvert

echo -e "\n[5/7] 赋予执行权限..."
sudo chmod +x /usr/local/bin/ss.sh
sudo chmod +x /usr/local/bin/nconvert

echo -e "\n[6/7] 下载并安装 BDInfoCLI-ng..."
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/BDInfoCLI-ng-main.zip -o /home/BDInfoCLI-ng-main.zip
sudo unzip -o /home/BDInfoCLI-ng-main.zip -d /home/
sudo rm -f /home/BDInfoCLI-ng-main.zip

sudo chmod +x /home/BDInfoCLI-ng-main/scripts/bdinfo
cd /home/BDInfoCLI-ng-main/scripts
sudo ./bdinfo --help

sudo cp /home/BDInfoCLI-ng-main/scripts/bdinfo /usr/local/bin/
sudo chmod +x /usr/local/bin/bdinfo

echo -e "\n[7/7] 配置完成！"
echo -e "\n========================================"
echo "           所有操作执行完成！"
echo ""
echo " ✅ ss.sh        全局命令：ss.sh"
echo " ✅ nconvert     全局命令：nconvert"
echo " ✅ bdinfo       全局命令：bdinfo"
echo ""
echo " 三个工具已全部安装成功！"
echo "========================================"
