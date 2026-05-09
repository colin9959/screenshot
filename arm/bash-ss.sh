#!/bin/bash
set -e
#
echo "========================================"
echo "      开始执行批量安装与配置脚本-arm版本"
echo "        支持：ss截图 + BDInfo蓝光检测"
echo "========================================"
#
# 1. 创建ISO挂载目录
echo -e "\n[1/5] 创建ISO挂载目录 /mnt/iso..."
sudo mkdir -p /mnt/iso
# 2. 下载 ss.sh 和 nconvert
echo -e "\n[2/5] 下载 ss.sh文件..."
# 先删除旧版本（如果存在）
sudo rm -f /usr/local/bin/ss.sh
sudo rm -f /usr/local/bin/bd.sh
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/arm/ss.sh -o /usr/local/bin/ss.sh
# 3. 赋予执行权限
echo -e "\n[3/5] 赋予文件执行权限..."
sudo chmod +x /usr/local/bin/ss.sh
# 4. 下载 bd.sh文件（arm版）
echo -e "\n[4/5] 下载并安装 BDInfo..."
sudo curl -fsSL https://raw.githubusercontent.com/colin9959/screenshot/main/arm/bd.sh -o /usr/local/bin/bd.sh
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
