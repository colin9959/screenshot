#!/bin/bash
set -e  # 脚本出错自动停止，更安全

echo "========================================"
echo "      开始执行批量安装与配置脚本"
echo "        支持：ss截图 + BDInfo蓝光检测"
echo "========================================"

# 1. 更新并安装所有依赖软件包
echo -e "\n[1/6] 更新系统并安装依赖包..."
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
echo -e "\n[2/6] 创建ISO挂载目录 /mnt/iso..."
sudo mkdir -p /mnt/iso

# 3. 下载 ss.sh 和 nconvert
echo -e "\n[3/6] 下载 ss.sh 和 nconvert 文件..."
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/ss.sh -o /usr/local/bin/ss.sh
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/nconvert -o /usr/local/bin/nconvert

# 4. 赋予执行权限
echo -e "\n[4/6] 赋予文件执行权限..."
sudo chmod +x /usr/local/bin/ss.sh
sudo chmod +x /usr/local/bin/nconvert

# ===================== 修正版 BDInfo 安装（确保在 /home 下） =====================
echo -e "\n[5/6] 下载并安装 BDInfoCLI-ng 到 /home 目录..."

# 绝对路径下载到 /home
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/BDInfoCLI-ng-main.tar.gz -o /home/BDInfoCLI-ng-main.tar.gz

# 解压到 /home 目录（绝对路径，确保正确）
sudo tar -zxf /home/BDInfoCLI-ng-main.tar.gz -C /home/

# 删除压缩包
sudo rm -f /home/BDInfoCLI-ng-main.tar.gz

# 赋权
sudo chmod +x /home/BDInfoCLI-ng-main/scripts/bdinfo

# 执行 --help 初始化
cd /home/BDInfoCLI-ng-main/scripts
sudo ./bdinfo --help

# 复制到全局命令目录
sudo cp /home/BDInfoCLI-ng-main/scripts/bdinfo /usr/local/bin/
sudo chmod +x /usr/local/bin/bdinfo
# ================================================================================

echo -e "\n========================================"
echo "           所有操作执行完成！"
echo ""
echo " ✅ ss.sh        全局命令：ss.sh"
echo " ✅ nconvert     全局命令：nconvert"
echo " ✅ bdinfo       全局命令：bdinfo"
echo ""
echo " 三个工具已全部安装成功！"
echo "========================================"