#!/bin/bash
set -e

echo "========================================"
echo "      开始执行批量安装与配置脚本"
echo "        支持：ss截图 + BDInfo蓝光检测"
echo "========================================"

# 1. 创建ISO挂载目录
echo -e "\n[1/5] 创建ISO挂载目录 /mnt/iso..."
sudo mkdir -p /mnt/iso

# 2. 下载 ss.sh 和 nconvert
echo -e "\n[2/5] 下载 ss.sh 和 nconvert 文件..."
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/ss.sh -o /usr/local/bin/ss.sh
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/nconvert -o /usr/local/bin/nconvert

# 3. 赋予执行权限
echo -e "\n[3/5] 赋予文件执行权限..."
sudo chmod +x /usr/local/bin/ss.sh
sudo chmod +x /usr/local/bin/nconvert

# 4. 下载并安装 BDInfoCLI-ng（zip版）
echo -e "\n[4/5] 下载并安装 BDInfoCLI-ng..."
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/BDInfoCLI-ng-main.zip -o /home/BDInfoCLI-ng-main.zip
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/bd.sh -o /usr/local/bin/bd.sh
sudo unzip -o /home/BDInfoCLI-ng-main.zip -d /home/
sudo rm -f /home/BDInfoCLI-ng-main.zip
sudo chmod +x /home/BDInfoCLI-ng-main/scripts/bdinfo
sudo cp /home/BDInfoCLI-ng-main/scripts/bdinfo /usr/local/bin/
sudo chmod +x /usr/local/bin/bdinfo
sudo chmod +x /usr/local/bin/bd.sh

# 5. 安装完成提示
echo -e "\n========================================"
echo "           所有操作执行完成！"
echo ""
echo " ✅ screenshot   全局命令：ss.sh"
echo " ✅ nconvert     全局命令：nconvert"
echo " ✅ bdinfo       全局命令：bd.sh"
echo ""
echo " 三个工具已全部安装成功！"
echo "========================================"
