#!/bin/bash
set -e
#
echo "========================================"
echo "      开始执行批量安装与配置脚本-arm版本"
echo "        支持：ss截图 + BDInfo蓝光检测"
echo "========================================"
#
# 1. 创建ISO挂载目录
echo -e "\n[3/7] 创建ISO挂载目录 /mnt/iso..."
sudo mkdir -p /mnt/iso
# 2. 下载 ss.sh 和 nconvert
echo -e "\n[4/7] 下载 ss.sh文件..."
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/arm/ss.sh -o /usr/local/bin/ss.sh
# 3. 赋予执行权限
echo -e "\n[5/7] 赋予文件执行权限..."
sudo chmod +x /usr/local/bin/ss.sh
# 4. 下载并安装 BDInfo（arm版）
echo -e "\n[6/7] 下载并安装 BDInfo..."
sudo curl -fsSL https://github.com/colin9959/screenshot/releases/download/arm/bdinfo -o /usr/local/bin/bdinfo
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/arm/bd.sh -o /usr/local/bin/bd.sh
sudo chmod +x /usr/local/bin/bdinfo
sudo chmod +x /usr/local/bin/bd.sh
# 5. 安装完成提示
echo -e "\n========================================"
echo "           所有操作执行完成！"
echo ""
echo " ✅ screenshot   全局命令：ss.sh"
echo " ✅ bdinfo       全局命令：bd.sh"
echo ""
echo " 三个工具已全部安装成功！"
echo "========================================"
